CC=gcc
CFlags= -g -Wall
LDFlags= -g

default: kaji.native libstr.a

kaji.native: kaji.ml ast.ml scanner.mll kajiparse.mly sast.ml semant.ml irgen.ml
	ocamlbuild -use-ocamlfind -pkgs llvm kaji.native

libstr.a: str.o
	ar -crs libstr.a str.o
	ranlib libstr.a

str.o: str.h str.c

.PHONY: clean
clean:
	ocamlbuild -clean 2>/dev/null
	rm -f *.native
	rm -rf _build
	rm -rf *.o *.s *.byte exe llvm.out a.out *.a

.PHONY: all
all: clean default