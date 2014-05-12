2D Map Generation Tools for Landes Eternelles
=============================================

This set of scripts is used to create overview maps for
the online game Landes Eternelles. The required base
images are downloaded separately, the URLs are in

  datafile.urls

To use these scripts you must have installed:

* bash, awk, sed, bc
* Perl
* ImageMagick

As well as several utility programs from the el-misc-tools
repository:

* elm2pov.pl
* elmhdr
* elm-draw-tiles
* elm-render-notes

If you intend to easily edit the input files, you may also
need:

* Gimp with python scripting support
* elm-annotate

Some scripts assume a certain directory layout, check
near the beginning for any paths that you may need to
change.
