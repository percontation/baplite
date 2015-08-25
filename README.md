Exposes [BAP](https://github.com/BinaryAnalysisPlatform/bap) lifting as a Python library.

The build product is a ~20mb python library that does not depend on having bap or ocaml installed.
(It does depend on the small BAP python library, `pip install git+git://github.com/BinaryAnalysisPlatform/bap.git`).

This library currently exposes a single function, `baplite.lift(arch, addr, code)`,
that returns a list of `bap.bil.Stmt`. For example:

```python
>>> import baplite
>>> baplite.lift("i386", 0, "\xb8\x37\x13\x00\x00")
[Move(Var("EAX", Imm(0x20)), Int(0x1337, 0x20))]
```

Compilation requires the ocaml runtime libraries with PIC, and the BAP ocaml libraries.
Compatible with `opam switch 4.02.1+PIC; opam install bap=0.9.9`.

src/adt.ml and src/adt.mli are copied from the BAP Toolkit
(Copyright (c) 2014 Carnegie Mellon University) under the MIT Licence.
