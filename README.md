Exposes [BAP](https://github.com/BinaryAnalysisPlatform/bap) lifting as a Python library.

Compilation requires that the BAP ocaml and python libraries be installed, and that ocaml
be compiled with PIC (i.e. `opam switch 4.02.1+PIC`).

The build product is a ~20mb python library that does not depend on having ocaml installed,
just the small BAP python library.

Compatible with the v0.9.7 release of BAP, on at least Linux and OS X.

src/adt.ml and src/adt.mli are taken from BAP.
