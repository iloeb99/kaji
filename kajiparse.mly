/* Ocamlyacc parser for Kaji */

%{
open Ast
%}

%token SEMI LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK PLUS MINUS ASSIGN
%token EQ NEQ LT GT AND OR IN
%token IF ELSE WHILE FOR INT BOOL VOID FUNCTION STR LIST
/* return, COMMA token */
%token RETURN COMMA
%token <int> LITERAL
%token <bool> BLIT
%token <string> ID
%token <string> STRLIT
%token EOF

%start program
%type <Ast.program> program

%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT
%left PLUS MINUS
%left LBRACK

%%

/* add function declarations*/
program:
  decls EOF { $1}

decls:
   /* nothing */    { ([], [])                 }
 | vdecl SEMI decls { (($1 :: fst $3), snd $3) }
 | fdecl decls      { (fst $2, ($1 :: snd $2)) }

vdecl_list:
    /*nothing*/            { []       }
  | vdecl SEMI vdecl_list  { $1 :: $3 }

/* int x */
vdecl:
  typ ID { ($1, $2) }

typ:
    INT            { Int      }
  | BOOL           { Bool     }
  | VOID           { Void     }
  | LIST LT typ GT { List($3) }
  | STR            { Str      }

/* fdecl */
fdecl:
  FUNCTION vdecl LPAREN formals_opt RPAREN LBRACE vdecl_list stmt_list RBRACE
  {
    {
      rtyp=fst $2;
      fname=snd $2;
      formals=$4;
      locals=$7;
      body=$8
    }
  }

/* formals_opt */
formals_opt:
    /*nothing*/  { [] }
  | formals_list { $1 }

formals_list:
    vdecl                    { [$1]   }
  | vdecl COMMA formals_list { $1::$3 }

stmt_list:
    /* nothing */   { []     }
  | stmt stmt_list  { $1::$2 }

stmt:
    expr SEMI                            { Expr $1          }
  | LBRACE stmt_list RBRACE              { Block $2         }
  | IF LPAREN expr RPAREN stmt ELSE stmt { If($3, $5, $7)       }
  | WHILE LPAREN expr RPAREN stmt        { While ($3, $5)       }
  | FOR LPAREN ID IN expr RPAREN stmt    { For (Id($3), $5, $7) }
  | RETURN expr SEMI                     { Return $2            }

expr:
    LITERAL                    { Literal($1)          }
  | BLIT                       { BoolLit($1)          }
  | ID                         { Id($1)               }
  | STRLIT                     { StrLit($1)           }
  | LBRACK args_opt RBRACK     { ListLit($2)          }
  | expr PLUS   expr           { Binop($1, Add, $3)   }
  | expr MINUS  expr           { Binop($1, Sub, $3)   }
  | expr EQ     expr           { Binop($1, Equal, $3) }
  | expr NEQ    expr           { Binop($1, Neq, $3)   }
  | expr LT     expr           { Binop($1, Less, $3)  }
  | expr GT     expr           { Binop($1, Great, $3) }
  | expr AND    expr           { Binop($1, And, $3)   }
  | expr OR     expr           { Binop($1, Or, $3)    }
  | expr LBRACK expr RBRACK    { Index($1, $3)        }
  | ID ASSIGN expr             { Assign($1, $3)       }
  | LPAREN expr RPAREN         { $2                   }
  | ID LPAREN args_opt RPAREN  { Call($1, $3)         }

/* args_opt*/
args_opt:
    /*nothing*/ { [] }
  | args        { $1 }

args:
    expr            { [$1]   }
  | expr COMMA args { $1::$3 }
