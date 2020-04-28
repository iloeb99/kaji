### Build the Kaji compiler

```
ocamlbuild -pkgs llvm kaji.native
```

### Run the Kaji compiler and generate llvm code
```
./kaji.native -l example.kaji > example.out
```

### Run the llvm code
```
lli example.out
```

### Compiler files
-  `ast.ml`: abstract syntax tree (AST) definition
-  `scanner.mll`: scanner
-  `kajiparse.mly`: parser
-  `sast.ml`: definition of the semantically-checked AST
-  `semant.ml`: semantic checking
-  `irgen.ml`: LLVM IR code generator

### Other files

- `test1.ml`: the file to test the scanner and parser
- `test2.ml`: the file to test the semantic checker
- `kaji.ml`: top-level file to test and run microc compiler
- `example.kaji`: a sample microc source code
- `example.out`: a sample compiled code of example.mc
