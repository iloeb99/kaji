CC=gcc
CFlags= -g -Wall
LDFlags= -g

default: kaji.native libstd.a

kaji.native: kaji.ml ast.ml scanner.mll kajiparse.mly sast.ml semant.ml irgen.ml
	ocamlbuild -use-ocamlfind -pkgs llvm kaji.native

libstd.a: str.o kajilist.o
	ar -crs libstd.a str.o kajilist.o
	ranlib libstd.a

str.o: str.h str.c

kajilist.o: kajilist.h kajilist.c

.PHONY: clean
clean:
	ocamlbuild -clean 2>/dev/null
	rm -f *.native
	rm -rf _build
	rm -rf *.o *.s *.byte exe llvm.out a.out *.a

.PHONY: all
all: clean default