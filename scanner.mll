(* Ocamllex scanner for MicroC *)

{ open Microcparse }

let digit = ['0'-'9']
let letter = ['a'-'z' 'A'-'Z']

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "//"     { singlecomment lexbuf }
| "/*"     { comment lexbuf }           (* Comments *)
| '('      { LPAREN }
| ')'      { RPAREN }
| '{'      { LBRACE }
| '}'      { RBRACE }
| ';'      { SEMI }
(* COMMA *)
| ','      { COMMA }
| '+'      { PLUS }
| '-'      { MINUS }
| '='      { ASSIGN }
| "=="     { EQ }
| "!="     { NEQ }
| '<'      { LT }
| "&&"     { AND }
| "||"     { OR }
| "in"     { IN }
| "if"     { IF }
| "else"   { ELSE }
| "while"  { WHILE }
| "for"    { FOR }
(* RETURN *)
| "return" { RETURN }
| "int"    { INT }
| "bool"   { BOOL }
| "void"   { VOID }
| "var"    { VARIABLE }
| "func"   { FUNCTION }
| "true"   { BLIT(true)  }
| "false"  { BLIT(false) }
| digit+ as lem  { LITERAL(int_of_string lem) }
| letter (digit | letter | '_')* as lem { ID(lem) }
| "None"   { VOIDLIT(None) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }

rule singlecomment = parse
  '\n' { token lexbuf }
| _    { singlecomment lexbuf }