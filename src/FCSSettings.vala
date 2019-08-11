
public class FCSSettings : Object {

    // constants
    const string CONF_FILE_SUB_DIRECTORY = "/fcs/";
    const string CONF_FILE_NAME = "fcssettings.conf";

    // fields
    string config_file_full_path;
    string config_file_dir;

    // properties
    public string folder { get; set; default = "/home"; }
    public string search_string { get; set; default = "enter text"; }
    public string[] file_extensions { get; set; default = { "txt", "log" }; }
    public bool immediate_update { get; set; default = true; }
    public bool search_subfolders { get; set; default = true; }
    public int max_file_size { get; set; default = 50; }
    public bool case_sensitive { get; set; default = false; }
    public int buffer_size { get; set; default = 32; }
    public int threads { get; set; default = 4; }

    // constructor
    public FCSSettings () {
        config_file_dir = Environment.get_user_config_dir () + CONF_FILE_SUB_DIRECTORY;
        config_file_full_path = config_file_dir + CONF_FILE_NAME;
    }

    // public methods
    public bool load_settings () {
        var config_file = File.new_for_path (config_file_full_path);
        if (!config_file.query_exists ()) {
            print ("Config file not found. Creating config file with defaults...\n");

            try {
                save_to_file ();
            } catch (Error err) {
                print (err.message + "\n");
                return false;
            }
            return true;
        }
        try {
            var stream = new DataInputStream (config_file.read ());
            string line;

            while ((line = stream.read_line ()) != null) {
                if (line.length == 0 || line[0] == '#' || !line.contains ("=")) {
                    continue;
                }

                var k = line.split ("=")[0];
                var v = line.split ("=")[1];

                switch (k) {
                case "folder":
                    folder = v;
                    break;
                case "search_string":
                    search_string = v;
                    break;
                case "file_extensions":
                    file_extensions = v.split (";");
                    break;
                case "immediate_update":
                    immediate_update = (v == "true");
                    break;
                case "search_subfolders":
                    search_subfolders = (v == "true");
                    break;
                case "max_file_size":
                    max_file_size = int.parse (v);
                    break;
                case "case_sensitive":
                    case_sensitive = (v == "true");
                    break;
                case "buffer_size":
                    buffer_size = int.parse (v);
                    break;
                case "threads":
                    threads = int.parse (v);
                    break;
                }
            }
        } catch (Error err) {
            print (err.message);
            return false;
        }
        return true;
    }

    public bool save_settings (string folder,
                               string search_string,
                               string[] file_extensions,
                               bool immediate_update,
                               bool search_subfolders,
                               int max_file_size,
                               bool case_sensitive,
                               int buffer_size,
                               int threads) {
        try {
            this.folder = folder;
            this.search_string = search_string;
            this.file_extensions = file_extensions;
            this.immediate_update = immediate_update;
            this.search_subfolders = search_subfolders;
            this.max_file_size = max_file_size;
            this.case_sensitive = case_sensitive;
            this.buffer_size = buffer_size;
            this.threads = threads;

            save_to_file ();
        } catch (Error err) {
            print (err.message + "\n");
            return false;
        }
        return true;
    }

    // private methods
    private void save_to_file () throws Error {
        var config_file = File.new_for_path (config_file_full_path);
        var config_dir = File.new_for_path (config_file_dir);

        if (!config_dir.query_exists ()) {
            config_dir.make_directory ();
        }
        
        var file_stream = config_file.replace (null, true, FileCreateFlags.NONE);
        var data_stream = new DataOutputStream (file_stream);

        data_stream.put_string ("folder=" + this.folder + "\n");
        data_stream.put_string ("search_string=" + this.search_string + "\n");
        var exts = "";
        foreach (var ext in file_extensions) {
            if (ext != "") {
                exts += ext + ";";
            }
        }
        data_stream.put_string ("file_extensions=" + exts + "\n");
        data_stream.put_string ("immediate_update=" + this.immediate_update.to_string () + "\n");
        data_stream.put_string ("search_subfolders=" + this.search_subfolders.to_string () + "\n");
        data_stream.put_string ("max_file_size=" + this.max_file_size.to_string () + "\n");
        data_stream.put_string ("case_sensitive=" + this.case_sensitive.to_string () + "\n");
        data_stream.put_string ("buffer_size=" + this.buffer_size.to_string () + "\n");
        data_stream.put_string ("threads=" + this.threads.to_string ());
    }
}
