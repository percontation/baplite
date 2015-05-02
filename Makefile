PYTHONPREFIX ?= $(dir $(shell realpath "`which python2.7`"))/..

.PHONY: all clean
all: baplite

baplite: baplite/baplite_stubs.so baplite/__init__.py
	touch $@

baplite/baplite_stubs.so: src/adt.mli src/adt.ml src/bapstubs.ml src/baplite_stubs.c
	mkdir -p "`dirname $@`"
	cd src && ocamlfind ocamlopt -package re,core_kernel,bap,bap.plugins $(patsubst %,../%,$^) -linkpkg -output-obj -o ../$@
	strip -x $@

baplite/%.py: src/%.py
	mkdir -p "`dirname $@`"
	cp $< $@

clean:
	cd src && rm -f ./*.o ./*.cmi ./*.cmx
	rm -Rf baplite
