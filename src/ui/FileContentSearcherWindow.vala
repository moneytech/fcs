[GtkTemplate (ui = "/org/fcs/ui/FileContentSearcherWindow.ui")]
public class FileContentSearcherWindow : Gtk.ApplicationWindow {

    // Fields (ui)
    private Gtk.FileChooserDialog fcd_browse;

    [GtkChild]
    private Gtk.Entry entry_search;

    [GtkChild]
    private Gtk.Entry entry_file_types;

    [GtkChild]
    private Gtk.Entry entry_folder;

    [GtkChild]
    private Gtk.Entry entry_max_size;

    [GtkChild]
    private Gtk.Entry entry_buffer_size;

    [GtkChild]
    private Gtk.Entry entry_threads;

    [GtkChild]
    private Gtk.Button btn_search;

    [GtkChild]
    private Gtk.Button btn_cancel;

    [GtkChild]
    private Gtk.Button btn_browse;

    [GtkChild]
    private Gtk.TextView txt_out;

    [GtkChild]
    private Gtk.CheckButton cb_update_list;

    [GtkChild]
    private Gtk.CheckButton cb_case_sensitive;

    [GtkChild]
    private Gtk.CheckButton cb_subfolders;

    [GtkChild]
    private Gtk.Spinner spn_in_progress;

    [GtkChild]
    private Gtk.ProgressBar pgb_progress;

    // Fields (non-ui)
    FileContentSearcher file_searcher;
    FCSSettings settings;
    ulong ? handlerid_new_file_found;

    // Constructor
    public FileContentSearcherWindow (string? path) {
        file_searcher = new FileContentSearcher ();
        settings = new FCSSettings ();
        btn_cancel.sensitive = false;
        cb_update_list.active = true;
        file_searcher.status_changed.connect (searcher_status_changed);
        file_searcher.progress_changed.connect (searcher_progress_changed);
        file_searcher.search_completed.connect (searcher_search_completed);
        if (settings.load_settings ()) {
            apply_settings ();
            if (path != null) {
                entry_folder.text = path;
            }
        }
    }

    // Signal handlers
    [GtkCallback]
    private bool fcsw_delete_event (Gdk.EventAny e) {
        settings.save_settings (entry_folder.text,
                                entry_search.text,
                                entry_file_types.text.split (";"),
                                cb_update_list.active,
                                cb_subfolders.active,
                                int.parse (entry_max_size.text),
                                cb_case_sensitive.active,
                                int.parse (entry_buffer_size.text),
                                int.parse (entry_threads.text));

        return false;
    }

    [GtkCallback]
    private void btn_browse_clicked (Gtk.Button btn) {
        fcd_browse = new BrowseFolderDialog ();
        fcd_browse.set_current_folder (entry_folder.text);
        if (fcd_browse.run () == Gtk.ResponseType.ACCEPT) {
            entry_folder.text = fcd_browse.get_filename ();
        }
        fcd_browse.close ();
    }

    [GtkCallback]
    private void btn_cancel_clicked (Gtk.Button btn) {
        file_searcher.cancel_search ();
    }

    [GtkCallback]
    private async void btn_search_clicked (Gtk.Button btn) {
        toggle_buttons ();
        txt_out.buffer.text = "";
        pgb_progress.fraction = 0;
        string[] filters = entry_file_types.text.split (";");

        yield file_searcher.search_for_files (entry_folder.text,
                                              filters,
                                              entry_search.text,
                                              cb_case_sensitive.active,
                                              cb_subfolders.active,
                                              int.parse (entry_max_size.text),
                                              int.parse (entry_threads.text),
                                              int.parse (entry_buffer_size.text));
    }

    [GtkCallback]
    private void cb_update_list_toggled () {
        if (cb_update_list.active) {
            handlerid_new_file_found = file_searcher.new_file_found.connect (searcher_new_file_found);
        } else if (handlerid_new_file_found != null) {
            file_searcher.disconnect (handlerid_new_file_found);
        }
    }

    private void searcher_new_file_found (string path) {
        insert_text_and_scroll (path);
    }

    private async void searcher_search_completed (bool canceled) {
        toggle_buttons ();
        if (canceled) {
            insert_text_and_scroll ("\nSearching canceled!\n");
            return;
        }
        if (!cb_update_list.active) {
            yield fill_output_list ();
        }
        insert_text_and_scroll ("\nSearching completed!\n");
    }

    private void searcher_status_changed (string message) {
        insert_text_and_scroll (message);
    }

    private void searcher_progress_changed (int current_number, int total_number) {
        pgb_progress.fraction = ((double) current_number) / ((double) total_number);
    }

    // private methods
    private void toggle_buttons () {
        btn_search.sensitive = !btn_search.sensitive;
        btn_cancel.sensitive = !btn_cancel.sensitive;
        btn_browse.sensitive = !btn_browse.sensitive;
        cb_update_list.sensitive = !cb_update_list.sensitive;
        cb_case_sensitive.sensitive = !cb_case_sensitive.sensitive;
        cb_subfolders.sensitive = !cb_subfolders.sensitive;
        spn_in_progress.active = !spn_in_progress.active;
        entry_max_size.sensitive = !entry_max_size.sensitive;
        entry_buffer_size.sensitive = !entry_buffer_size.sensitive;
        entry_threads.sensitive = !entry_threads.sensitive;
        entry_folder.sensitive = !entry_folder.sensitive;
        entry_file_types.sensitive = !entry_file_types.sensitive;
        entry_search.sensitive = !entry_search.sensitive;
    }

    private async void fill_output_list () {
        foreach (string file in file_searcher.files_found) {
            insert_text_and_scroll (file);
        }
    }

    private void scroll_to_end () {
        Gtk.TextIter iter;
        txt_out.buffer.get_end_iter (out iter);
        txt_out.scroll_to_iter (iter, 0, false, 0, 0);
    }

    private void apply_settings () {
        entry_folder.text = settings.folder;
        entry_search.text = settings.search_string;
        var extensions = "";
        foreach (var ft in settings.file_extensions) {
            if (ft != "") {
                extensions += ft + ";";
            }
        }
        entry_file_types.text = extensions;
        cb_update_list.active = settings.immediate_update;
        cb_case_sensitive.active = settings.case_sensitive;
        cb_subfolders.active = settings.search_subfolders;
        entry_max_size.text = settings.max_file_size.to_string ();
        entry_buffer_size.text = settings.buffer_size.to_string ();
        entry_threads.text = settings.threads.to_string ();
    }

    private void insert_text_and_scroll (string text) {
        Gtk.TextIter iter;
        txt_out.buffer.get_end_iter (out iter);
        txt_out.buffer.insert (ref iter, text + "\n", -1);
        scroll_to_end ();
    }
}
