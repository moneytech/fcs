project('File Content Searcher', 'vala', 'c')

deps = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gio-unix-2.0'),
    dependency('gee-0.8'),
    dependency('gtk+-3.0'),
]

src = files([
    'src/Main.vala',
    'src/ui/FileContentSearcherWindow.vala',
    'src/ui/BrowseFolderDialog.vala',
    'src/FileContentSearcher.vala',
    'src/FCSSettings.vala'
])

gnome = import('gnome')

resources = gnome.compile_resources('ui', 'resources/ui.gresource.xml', source_dir: 'resources')

executable('fcs',
           resources,
           dependencies: deps,
           sources: src,
           vala_args: ['--pkg=posix', '--enable-gobject-tracing'],
           install: true)