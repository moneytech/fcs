[GtkTemplate (ui = "/org/fcs/ui/BrowseFolderDialog.ui")]
public class BrowseFolderDialog : Gtk.FileChooserDialog {
    public BrowseFolderDialog () {
        //this.set_current_folder (Environment.get_home_dir ());
    }
    [GtkCallback]
    private void btn_select_folder_clicked (Gtk.Button btn) {
        response (Gtk.ResponseType.ACCEPT);
    }

}