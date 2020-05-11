CC=gcc
CFlags= -g -Wall
LDFlags= -g
LDLIBS= -lcurl

default: kaji.native libstd.a

kaji.native: kaji.ml ast.ml scanner.mll kajiparse.mly sast.ml semant.ml irgen.ml
	ocamlbuild -use-ocamlfind -pkgs llvm kaji.native

libstd.a: str.o kajilist.o
	ar -crs libstd.a str.o kajilist.o
	ranlib libstd.a

http_test: http_test.c http.o str.o

http.o: http.c str.h

str.o: str.h str.c

kajilist.o: kajilist.h kajilist.c

.PHONY: clean
clean:
	ocamlbuild -clean 2>/dev/null
	rm -f *.native
	rm -rf _build
	rm -rf *.o *.s *.byte exe llvm.out a.out *.a http_test

.PHONY: all
all: clean default
