CC=gcc
CFlags= -g -Wall
LDFlags= -g

default: kaji.native

kaji.native: ast.ml scanner.mll kajiparse.mly sast.ml semant.ml irgen.ml kaji.ml
	ocamlbuild -use-ocamlfind -pkgs llvm kaji.native

.PHONY: clean
clean:
	ocamlbuild -clean
	rm -f *.native
	rm -f *.o *.a *.s a.out *.byte