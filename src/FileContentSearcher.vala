
public class FileContentSearcher : Object {

    // delegates
    delegate void ThreadMessage (int thread, SearchMessageType message_type, string ? message);

    delegate string ? GetWork ();

    // enums
    enum SearchMessageType {
        ERROR_OCCURED,
        FILE_FOUND,
        NO_MORE_WORK,
        PROGRESS_CHANGED
    }

    // fields
    Gee.LinkedList<string> files_search;
    Gee.LinkedList<SearchThread> thread_list;
    int num_threads;
    int threads_active;
    int files_processed;
    int files_to_process;

    // properties
    public Gee.LinkedList<string> files_found { get; private set; }
    public bool canceled { get; private set; }
    public bool completed { get; private set; }

    // signals
    public signal void new_file_found (string path);
    public signal void status_changed (string message);
    public signal void progress_changed (int current_number, int total_number);
    public signal void search_completed (bool canceled);

    // constructor
    public FileContentSearcher () {
        files_search = new Gee.LinkedList<string>();
        files_found = new Gee.LinkedList<string>();
        thread_list = new Gee.LinkedList<SearchThread>();
        canceled = false;
        threads_active = 0;
        num_threads = 1;
        files_processed = 0;
        files_to_process = 0;
    }

    // public methods
    public async void search_for_files (string directory,
                                        string[] filter,
                                        string search_string,
                                        bool case_sensitive = false,
                                        bool search_subfolders = true,
                                        int max_size,
                                        int num_threads,
                                        int buffer_mb) {
        this.num_threads = num_threads;
        files_found.clear ();
        files_search.clear ();
        thread_list.clear ();
        canceled = false;
        completed = false;
        threads_active = num_threads;
        files_processed = 0;

        status_changed ("Building list of files...");
        yield get_files (directory, filter, search_subfolders, max_size);

        files_to_process = files_search.size;

        if (!canceled) {
            status_changed ("\nSearching for string within files...\n");
        }

        for (int i = 0; i < num_threads; i++) {
            SearchThread st = new SearchThread (i, process_message_from_thread, give_work, search_string, case_sensitive, buffer_mb);
            thread_list.add (st);
            Thread<void *> t = new Thread<void *>("Thread: " + i.to_string (), st.run);
        }

        Timeout.add (500, progress_timer);
    }

    public void cancel_search () {
        canceled = true;
        status_changed ("Canceled. Stopping active threads...\n");
        foreach (var st in thread_list) {
            st.stop ();
        }
    }

    // private methods
    private void process_message_from_thread (int thread, SearchMessageType message_type, string ? message) {
        if (message_type == SearchMessageType.FILE_FOUND) {
            Idle.add (() => {
                new_file_found (message);
                files_found.add (message);
                return false;
            });
        } else if (message_type == SearchMessageType.ERROR_OCCURED) {
            Idle.add (() => {
                status_changed ("ERROR: " + message);
                return false;
            });
        } else if (message_type == SearchMessageType.NO_MORE_WORK) {
            lock (threads_active) {
                threads_active--;
                if (threads_active == 0) {
                    Idle.add (() => {
                        search_completed (canceled);
                        completed = true;
                        progress_timer ();
                        return false;
                    });
                }
            }
        } else if (message_type == SearchMessageType.PROGRESS_CHANGED) {
            lock (files_processed) {
                files_processed++;
            }
        }
    }

    private string ? give_work () {
        string ? work = null;
        if (canceled) {
            return null;
        }
        lock (files_search) {
            work = files_search.poll ();
        }
        return work;
    }

    private bool progress_timer () {
        lock (files_processed) {
            Idle.add (() => {
                progress_changed (files_processed, files_to_process);
                return false;
            });

            if (canceled || completed) {
                return false;
            } else {
                return true;
            }
        }
    }

    private async void get_files (string directory,
                                  string[] filter,
                                  bool search_subfolders,
                                  int max_size) {
        var dir = File.new_for_path (directory);
        try {
            var enumerator = yield dir.enumerate_children_async ("standard::size",
                                                                 FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                                                                 Priority.DEFAULT,
                                                                 null);

            List<FileInfo> fia;
            while ((fia = yield enumerator.next_files_async (100, Priority.DEFAULT, null)) != null && !canceled) {
                foreach (var fi in fia) {
                    var fname = fi.get_name ();
                    var size_mb = fi.get_size () / 1024 / 1024;
                    if (fi.get_file_type () == FileType.REGULAR) {
                        foreach (var f in filter) {
                            var fullpath = directory + "/" + fname;
                            if ((f == "*" || fname[fname.length - 4: fname.length] == "." + f) && size_mb < max_size) {
                                files_search.add (fullpath);
                                break;
                            }
                        }
                    } else if (fi.get_file_type () == FileType.DIRECTORY && search_subfolders) {
                        yield get_files (dir.get_path () + "/" + fname, filter, search_subfolders, max_size);
                    }
                }
            }
        } catch (Error err) {
            status_changed ("ERROR: " + err.message);
        }
    }

    // subclasses
    class SearchThread : Object {
        // fields
        int thread_number;
        unowned ThreadMessage thread_message;
        string search_string;
        bool case_sensitive;
        unowned GetWork get_work;
        bool canceled;
        int buffer_mb;

        // constructor
        public SearchThread (int thread_number,
                             ThreadMessage thread_message,
                             GetWork get_work,
                             string search_string,
                             bool case_sensitive,
                             int buffer_mb) {
            this.thread_number = thread_number;
            this.thread_message = thread_message;
            this.search_string = search_string;
            this.case_sensitive = case_sensitive;
            this.get_work = get_work;
            this.canceled = false;
            this.buffer_mb = buffer_mb;
        }

        // public methods
        public void * run () {
            string ? path;
            while ((path = get_work ()) != null) {
                if (contains_text (path)) {
                    thread_message (thread_number, SearchMessageType.FILE_FOUND, path);
                }
                thread_message (thread_number, SearchMessageType.PROGRESS_CHANGED, null);
            }
            thread_message (thread_number, SearchMessageType.NO_MORE_WORK, null);
            return null;
        }

        public void stop () {
            lock (canceled) {
                canceled = true;
            }
        }

        // private methods
        private bool contains_text (string path) {
            bool contains = false;
            var file = File.new_for_path (path);
            try {
                var dis = new DataInputStream (file.read ());
                uint8[] buffer = new uint8[buffer_mb * 1024 * 1024];
                size_t s = 0;
                while (!canceled) {
                    dis.read_all (buffer, out s);

                    for (int i = 0; i < s; i++) {
                        if (buffer[i] == 0) {
                            buffer[i] = 32;
                        }
                    }

                    unowned string txt = (string) buffer;

                    if (!case_sensitive) {
                        if (txt.up ().contains (search_string.up ())) {
                            contains = true;
                        }
                    } else {
                        if (txt.contains (search_string)) {
                            contains = true;
                        }
                    }

                    if (s == 0) {
                        break;
                    }
                }
            } catch (Error err) {
                thread_message (thread_number, SearchMessageType.ERROR_OCCURED, err.message);
                return false;
            }
            return contains;
        }
    }
}
