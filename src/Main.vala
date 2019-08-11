
int main (string[] args) {
    if (args.length > 1 && args[1] == "--no-gui") {
        if (args.length < 3) {
            print ("\nInvalid number of arguments\n\n");
            print ("Usage: fcs --no-gui \"search path\" \"search for\"\n\n");
        } else {
            var fcs = new FileContentSearcher ();
            var loop = new MainLoop ();

            fcs.new_file_found.connect ((file) => {
                print (file + "\n");
            });
            fcs.search_completed.connect ((canceled) => {
                print ("\nCompleted!\n");
                loop.quit ();
            });

            var settings = new FCSSettings ();
            settings.load_settings ();
            fcs.search_for_files.begin (args[2],
                                        settings.file_extensions,
                                        args[3],
                                        settings.case_sensitive,
                                        settings.search_subfolders,
                                        settings.max_file_size,
                                        settings.threads,
                                        settings.buffer_size);
            loop.run ();
        }
    } else {
        Gtk.init (ref args);

        string? path = null;
        if (args.length > 1) {
            path = args[1];
        }

        var window = new FileContentSearcherWindow (path);
        window.title = "File content searcher";
        window.destroy.connect (Gtk.main_quit);
        window.show_all ();

        Gtk.main ();
    }
    return 0;
}
