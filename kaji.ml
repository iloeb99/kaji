(* Top-level of the Kaji compiler: scan & parse the input,
   check the resulting AST and generate an SAST from it, generate LLVM IR,
   and dump the module *)

open Sys
open Printf

type action = Ast | Sast | LLVM_IR | Exec

let () =
  let action = ref Exec in
  let set_action a () = action := a in
  let speclist = [
    ("-a", Arg.Unit (set_action Ast), "Print the AST");
    ("-s", Arg.Unit (set_action Sast), "Print the SAST");
    ("-l", Arg.Unit (set_action LLVM_IR), "Print the generated LLVM IR");
  ] in
  let usage_msg = "usage: ./kaji.native [-a|-s|-l] [file.kaji]" in
  let channel = ref stdin in
  Arg.parse speclist (fun filename -> channel := open_in filename) usage_msg;

  let lexbuf = Lexing.from_channel !channel in

  let ast = Kajiparse.program Scanner.token lexbuf in
  match !action with
    Ast -> print_string (Ast.string_of_program ast)
  | _ -> let sast = Semant.check ast in
    let llvm_module = Llvm.string_of_llmodule (Irgen.translate sast) in 
    match !action with
      Ast     -> ()
    | Sast    -> print_string (Sast.string_of_sprogram sast)
    | LLVM_IR -> print_string (Llvm.string_of_llmodule (Irgen.translate sast))
    | Exec -> let out = open_out "llvm.out" in
      fprintf out "%s\n" llvm_module; close_out out;
      if (command "llc -relocation-model=pic llvm.out" != 0)
      then raise (Failure "llc: non-zero exit code")
      else if ((command "gcc llvm.out.s -L./ -lstd -lcurl -o a.out" ) != 0)
      then raise (Failure "gcc: non-zero exit code")
      else ()
