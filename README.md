## File content searcher / fcs

Small tool which allows you to search through file contents.

Actually started developing this tool to learn the vala programming language, so don't expect perfect code :)

![pic removed](https://github.com/moson-mo/fcs/raw/master/screenshots/main.png?inline=true)

The app was written in vala using gtk+3, gee, gio libs.

#### Setup / build

- `git clone https://github.com/moson-mo/fcs.git && cd fcs` (clone repo)
- `meson build` (create build dir with meson)
- `ninja -C build` (build project)
###
- Run with: `./build/fcs`


#### Planned features

- ~~Add config file to store settings~~ => Implemented
- ~~Multi threading support? (currently only one cpu core is used)~~ => Implemented
- Use other control for file output (currently GtkTextView) so that files can be opened from the tool