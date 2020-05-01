CC=gcc
CFlags= -g -Wall
LDFlags= -g

default: kaji.native libstr.a

kaji.native: ast.ml scanner.mll kajiparse.mly sast.ml semant.ml irgen.ml kaji.ml
	ocamlbuild -use-ocamlfind -pkgs llvm kaji.native

libstr.a: str.o
	ar -crs libstr.a str.o
	ranlib libstr.a

str.o: str.h str.c

.PHONY: clean
clean:
	ocamlbuild -clean
	rm -f *.native
	rm -f *.o *.a *.s a.out *.byte