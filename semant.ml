(* Semantic checking for the Kaji compiler *)

open Ast
open Sast

module StringMap = Map.Make(String)

(* Semantic checking of the AST. Returns an SAST if successful,
   throws an exception if something is wrong.

   Check each global variable, then check each function *)

let check (globals, functions) =

  (* Verify a list of bindings has no duplicate names or voids *)
  let check_binds (kind : string) (binds : (typ * string) list) =
    let rec dups = function
        [] -> ()
      |	((_,n1) :: (_,n2) :: _) when n1 = n2 ->
        raise (Failure ("duplicate " ^ kind ^ " " ^ n1))
      | (t, n) :: tl -> if t = Void
        then raise (Failure ("variable " ^ n ^ " cannot be of type Void"))
        else dups tl
    in dups (List.sort (fun (_,a) (_,b) -> compare a b) binds)
  in

  (* Make sure no globals duplicate *)
  check_binds "global" globals;

  (* Collect function declarations for built-in functions: no bodies *)
  let built_in_decls =
    StringMap.add "printStr" {
      rtyp = Int;
      fname = "printStr";
      formals = [(Str, "s")];
      locals = []; body = [] } StringMap.empty
  in let built_in_decls =
       StringMap.add "fprintStr" {
         rtyp = Int;
         fname = "fprintStr";
         formals = [(Str, "f") ; (Str, "s") ; (Int, "a")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "print" {
         rtyp = Int;
         fname = "print";
         formals = [(Int, "x")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "freeStr" {
         rtyp = Void;
         fname = "freeStr";
         formals = [(Str, "s")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "strLen" {
         rtyp = Int;
         fname = "strLen";
         formals = [(Str, "s")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "listLen" {
         rtyp = Int;
         fname = "listLen";
         formals = [(List(Void), "ls")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "freeList" {
         rtyp = Void;
         fname = "freeList";
         formals = [(List(Void), "ls")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "initList" {
         rtyp = Void;
         fname = "initList";
         formals = [(List(Void), "ls")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "strEq" {
         rtyp = Bool;
         fname = "strEq";
         formals = [(Str, "s") ; (Str, "t")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "concatStr" {
         rtyp = Str;
         fname = "concatStr";
         formals = [(Str, "s") ; (Str, "t")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "subStr" {
         rtyp = Str;
         fname = "subStr";
         formals = [(Int, "start") ; (Int, "stop") ; (Str, "src")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "scrape" {
         rtyp = Str;
         fname = "scrape";
         formals = [(Str, "url")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "appendList" {
         rtyp = Void;
         fname = "appendList";
         (* these formals are dummy values
          * there's a special case in check_func *)
         formals = [(Int, "i") ; (Int, "j")];
         locals = []; body = [] } built_in_decls
  in let built_in_decls =
       StringMap.add "setElem" {
         rtyp = Void;
         fname = "setElem";
         (* these formals are dummy values
          * there's a special case in check_func *)
         formals = [(Int, "i") ; (Int, "j") ; (Int, "k")];
         locals = []; body = [] } built_in_decls
  in


  (* Add function name to symbol table *)
  let add_func map fd =
    let built_in_err = "function " ^ fd.fname ^ " may not be defined"
    and dup_err = "duplicate function " ^ fd.fname
    and make_err er = raise (Failure er)
    and n = fd.fname (* Name of the function *)
    in match fd with (* No duplicate functions or redefinitions of built-ins *)
      _ when StringMap.mem n built_in_decls -> make_err built_in_err
    | _ when StringMap.mem n map -> make_err dup_err
    | _ ->  StringMap.add n fd map
  in

  (* Collect all function names into one symbol table *)
  let function_decls = List.fold_left add_func built_in_decls functions
  in

  (* Return a function from our symbol table *)
  let find_func s =
    try StringMap.find s function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = find_func "main" in (* Ensure "main" is defined *)

  let check_func func =
    (* Make sure no formals or locals are void or duplicates *)
    check_binds "formal" func.formals;
    check_binds "local" func.locals;

    (* Raise an exception if the given rvalue type cannot be assigned to
       the given lvalue type *)
    let rec check_assign lvaluet rvaluet err =
      match lvaluet with
        List(t) -> begin match rvaluet with
          | Void -> lvaluet
          | List(t') -> if t = Void then rvaluet else check_assign t t' err
          | _  -> raise (Failure err) end
      | _ -> if rvaluet = Void || lvaluet = rvaluet then lvaluet else raise (Failure err)
    in

    (* Build local symbol table of variables for this function *)
    let symbols = List.fold_left (fun m (ty, name) -> StringMap.add name ty m)
        StringMap.empty (globals @ func.formals @ func.locals )
    in

    (* Return a variable from our local symbol table *)
    let type_of_identifier s =
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in

    (* Return a semantically-checked expression, i.e., with a type *)
    let rec check_expr = function
        Literal l -> (Int, SLiteral l)
      | BoolLit l -> (Bool, SBoolLit l)
      | StrLit l -> (Str, SStrLit l)
      | ListLit l ->
        let check' t1 t2 = match (t1, t2) with
            (List(t1'), List(t2')) -> t1' = Void || t2' = Void || t1' = t2'
          | _ -> t1 = t2

        in let rec check = function
              (t1, _) :: (t2, e2) :: tail ->
              if (check' t1 t2) then
                check ((t2, e2)::tail)
              else raise (Failure "list contains inconsistent types")
            | (t, _) :: tail -> List(t)
            | _ -> List(Void)
        in
        let sl = List.map check_expr l in (check sl, SListLit sl)

      | Id var -> (type_of_identifier var, SId var)
      | Index(e, i) ->
        let dex = check_expr i in
        if fst dex <> Int then
          raise (Failure "index must be of type Int")
        else
          let (t, e') = check_expr e in
          let st = match t with
              List(t') -> t'
            | _ -> raise (Failure ("cannot index non list type"))
          in (st, SIndex((t, e'), dex))
      | Assign(var, e) as ex ->
        let lt = type_of_identifier var
        and (rt, e') = check_expr e in
        let err = "illegal assignment " ^ string_of_typ lt ^ " = " ^
                  string_of_typ rt ^ " in " ^ string_of_expr ex
        in
        (check_assign lt rt err, SAssign(var, (rt, e')))

      | Binop(e1, op, e2) as e ->
        let (t1, e1') = check_expr e1
        and (t2, e2') = check_expr e2 in
        let err = "illegal binary operator " ^
                  string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                  string_of_typ t2 ^ " in " ^ string_of_expr e
        in
        (* All binary operators require operands of the same type*)
        if t1 = t2 then
          (* Determine expression type based on operator and operand types *)
          let t = match op with
              Add | Sub when t1 = Int -> Int
            | Equal | Neq -> Bool
            | Less | Great when t1 = Int -> Bool
            | And | Or when t1 = Bool -> Bool
            | _ -> raise (Failure err)
          in
          (t, SBinop((t1, e1'), op, (t2, e2')))
        else raise (Failure err)
      | Call(fname, args) as call ->
        let fd = find_func fname in
        let param_length = List.length fd.formals in
        if List.length args != param_length then
          raise (Failure ("expecting " ^ string_of_int param_length ^
                          " arguments in " ^ string_of_expr call))
        else begin match fname with
          | "appendList" -> let args' = List.map check_expr args in
            begin match args' with
                [(List(t), _) ; (t2, _)] when t = t2 -> (Void, SCall(fname, args'))
              | _ -> raise (Failure ("appendList() argument types do not match")) end
          | "setElem" -> let args' = List.map check_expr args in
            begin match args' with
                [(List(t), _) ; (Int, _) ; (t2, _)] when t = t2 -> (Void, SCall(fname, args'))
              | _ -> raise (Failure ("setElem() argument types do not match")) end
          | _ -> let check_call (ft, _) e =
                   let (et, e') = check_expr e in
                   let err = "illegal argument found " ^ string_of_typ et ^
                             " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e
                   in (check_assign ft et err, e')
            in
            let args' = List.map2 check_call fd.formals args
            in (fd.rtyp, SCall(fname, args')) end
    in

    let check_bool_expr e =
      let (t, e') = check_expr e in
      match t with
      | Bool -> (t, e')
      |  _ -> raise (Failure ("expected Boolean expression in " ^ string_of_expr e))
    in

    let rec check_stmt_list =function
        [] -> []
      | Block sl :: sl'  -> check_stmt_list (sl @ sl') (* Flatten blocks *)
      | s :: sl -> check_stmt s :: check_stmt_list sl
    (* Return a semantically-checked statement i.e. containing sexprs *)
    and check_stmt =function
      (* A block is correct if each statement is correct and nothing
         follows any Return statement.  Nested blocks are flattened. *)
        Block sl -> SBlock (check_stmt_list sl)
      | Expr e -> SExpr (check_expr e)
      | If(e, st1, st2) ->
        SIf(check_bool_expr e, check_stmt st1, check_stmt st2)
      | While(e, st) ->
        SWhile(check_bool_expr e, check_stmt st)
      | For(lv, e, st) -> begin match lv with
          | Id(n) -> let se = check_expr e in
            let slv = check_expr lv in
            begin match se with
              | (List(Void), _) -> SFor(slv, se, check_stmt st)
              | (List(t'), _) -> if fst slv = t' then SFor(slv, se, check_stmt st) else raise(Failure "list type does not match iterator type")
              | _ -> raise(Failure "cannot iterate through non-list type") end
          | _     -> raise(Failure "For loop must contain iterator variable") end
      | Return e ->
        let (t, e') = check_expr e in
        if t = func.rtyp then SReturn (t, e')
        else raise (
            Failure ("return gives " ^ string_of_typ t ^ " expected " ^
                     string_of_typ func.rtyp ^ " in " ^ string_of_expr e))
    in (* body of check_func *)
    { srtyp = func.rtyp;
      sfname = func.fname;
      sformals = func.formals;
      slocals  = func.locals;
      sbody = check_stmt_list func.body
    }
  in
  (globals, List.map check_func functions)
