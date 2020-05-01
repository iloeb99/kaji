### Build the Kaji compiler

```
make
```

### Run the Kaji compiler and generate llvm code
```
./kaji.native -l example.kaji
```

### Run the llvm code
```
./a.out
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
- `kaji.ml`: top-level file to test and run kaji compiler
- `Makefile`: the file to build the kaji compiler
- `example.kaji`: a sample kaji source code
- `example.out`: a sample compiled code of example.kaji
