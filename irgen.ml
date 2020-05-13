(* IR generation: translate takes a semantically checked AST and
   produces LLVM IR
*)

module L = Llvm
module A = Ast
open Sast

module StringMap = Map.Make(String)

(* translate : Sast.program -> Llvm.module *)
let translate (globals, functions) =
  let context    = L.global_context () in

  (* Create the LLVM compilation module into which
     we will generate code *)
  let the_module = L.create_module context "Kaji" in

  (* Get types from the context *)
  let i32_t      = L.i32_type    context
  and i8_t       = L.i8_type     context
  and i1_t       = L.i1_type     context 
  and void_t     = L.void_type   context in

  (* Declare struct str *)
  let struct_str_t : L.lltype =
    L.named_struct_type context "str" in
    
  let _ =
    L.struct_set_body struct_str_t
    [| L.pointer_type i8_t ; i32_t |] false in

  (* Declare struct list *)
  let struct_list_t : L.lltype = 
    L.named_struct_type context "list" in

  let _ = 
    L.struct_set_body struct_list_t
    [| L.pointer_type i8_t ; i32_t ; i32_t |] false in

  (* Return the LLVM type for a Kaji type *)
  let ltype_of_typ = function
      A.Int  -> i32_t
    | A.Bool -> i1_t
    | A.Void -> void_t
    | A.Str  -> struct_str_t
    | A.List(_) -> struct_list_t
  in

  (* Create a map of global variables after creating each *)
  let global_vars : L.llvalue StringMap.t =
    let global_var m (t, n) =
      let init = L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in

  let printf_t : L.lltype =
    L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func : L.llvalue =
    L.declare_function "printf" printf_t the_module in

  (* Declare C functions *)
  let initStr_t : L.lltype = 
    L.function_type void_t [| L.pointer_type struct_str_t |] in
  let initStr : L.llvalue = L.declare_function "initStr" initStr_t the_module in

  let freeStr : L.llvalue = L.declare_function "freeStr" initStr_t the_module in

  let assignStr_t : L.lltype = L.function_type (L.pointer_type struct_str_t) 
    [| L.pointer_type struct_str_t ; L.pointer_type i8_t |] in
  let assignStr : L.llvalue = L.declare_function "assignStr" assignStr_t the_module in

  let copyStr_t : L.lltype = L.function_type void_t [| L.pointer_type struct_str_t ; L.pointer_type struct_str_t |] in
  let copyStr : L.llvalue = L.declare_function "copyStr" copyStr_t the_module in

  let strEq_t : L.lltype = L.function_type i32_t [| L.pointer_type struct_str_t ; L.pointer_type struct_str_t |] in
  let strEq : L.llvalue = L.declare_function "strEq" strEq_t the_module in

  let printStr_t : L.lltype = L.function_type i32_t [| L.pointer_type struct_str_t |] in
  let printStr : L.llvalue = L.declare_function "printStr" printStr_t the_module in

  let strLen : L.llvalue = L.declare_function "listLen" printStr_t the_module in

  let getData_t : L.lltype = L.function_type (L.pointer_type i8_t) [| L.pointer_type struct_str_t |] in
  let getData : L.llvalue = L.declare_function "getData" getData_t the_module in

  let subStr_t : L.lltype = L.function_type void_t [| i32_t; i32_t; L.pointer_type struct_str_t ; L.pointer_type struct_str_t |] in
  let subStr : L.llvalue = L.declare_function "subStr" subStr_t the_module in

  let initList_t : L.lltype =
    L.function_type void_t [| L.pointer_type struct_list_t |] in
  let initList : L.llvalue = L.declare_function "initList" initList_t the_module in

  let freeList : L.llvalue = L.declare_function "freeList" initList_t the_module in

  let assignList_t : L.lltype = L.function_type (L.pointer_type struct_list_t)
    [| L.pointer_type struct_list_t ; L.pointer_type i8_t ; i32_t |] in
  let assignList : L.llvalue = L.declare_function "assignList" assignList_t the_module in

  let listLen_t : L.lltype = L.function_type i32_t [| L.pointer_type struct_list_t |] in
  let listLen : L.llvalue = L.declare_function "listLen" listLen_t the_module in

  let appendList_t : L.lltype = L.function_type void_t
    [| L.pointer_type struct_list_t ; L.pointer_type i8_t |] in
  let appendList : L.llvalue = L.declare_function "appendList" appendList_t the_module in

  let indexList_t : L.lltype = L.function_type (L.pointer_type i8_t)
    [| L.pointer_type struct_list_t ; i32_t |] in
  let indexList : L.llvalue = L.declare_function "indexList" indexList_t the_module in


  (* Define each function (arguments and return type) so we can
     call it even before we've created its body *)
  let function_decls : (L.llvalue * sfunc_def) StringMap.t =
    let function_decl m fdecl =
      let name = fdecl.sfname
      and formal_types =
        Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.sformals)
      in let ftype = L.function_type (ltype_of_typ fdecl.srtyp) formal_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty functions in

  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let (the_function, _) = StringMap.find fdecl.sfname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in

    let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder in

    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    let local_vars =
      let add_formal m (t, n) p =
        L.set_value_name n p;
        let local = L.build_alloca (ltype_of_typ t) n builder in
        ignore (L.build_store p local builder);
        StringMap.add n local m

      (* Allocate space for any locally declared variables and add the
       * resulting registers to our map *)
      and add_local m (t, n) =
        let local_var = match t with
            A.Str | A.List(_) -> L.build_alloca (L.pointer_type (ltype_of_typ t)) n builder
          | _                 -> L.build_alloca (ltype_of_typ t) n builder
        in StringMap.add n local_var m
      in

      let formals = List.fold_left2 add_formal StringMap.empty fdecl.sformals
          (Array.to_list (L.params the_function)) in
      List.fold_left add_local formals fdecl.slocals
    in

    (* Return the value for a variable or formal argument.
       Check local names first, then global names *)
    let lookup n = try StringMap.find n local_vars
      with Not_found -> StringMap.find n global_vars
    in

    (* Construct code for an expression; return its value *)
    let rec build_expr builder ((_, e) : sexpr) = match e with
        SLiteral i  -> L.const_int i32_t i
      | SBoolLit b  -> L.const_int i1_t (if b then 1 else 0)
      | SStrLit s   -> let a = L.build_malloc struct_str_t "_tmpstr" builder in
                        let _ = L.build_call initStr [| a |] "" builder in
                        let s' = L.const_stringz context s in
                        let b = L.build_alloca (L.type_of s') "_tmpstr" builder in
                        let _ = L.build_store s' b builder in
                        let s'' = L.build_bitcast b (L.pointer_type i8_t) "" builder in
                        let _ = L.build_call assignStr [| a ; s'' |] "" builder in
                        a
      | SListLit ls -> let lp = L.build_malloc struct_list_t "_tmplst" builder in
                        let _ = L.build_call initList [| lp |] "" builder in
                        let _ = List.iter (fun s ->
                            let s' = match s with
                            | (A.Str, _) -> L.build_malloc (L.pointer_type struct_str_t) "_lstitem" builder
                            | (A.List(_), _) -> L.build_malloc (L.pointer_type struct_list_t) "_lstitem" builder
                            | _ -> L.build_malloc (ltype_of_typ (fst s)) "_lstitem" builder
                            in let _ = L.build_store (build_expr builder s) s' builder
                            in let s'' = L.build_bitcast s' (L.pointer_type i8_t) "" builder
                            in ignore(L.build_call appendList [| lp ; s'' |] "" builder);
                        ) ls in
                        lp
      | SId s       -> L.build_load (lookup s) s builder
      | SAssign (s, e) -> let e' = build_expr builder e in ignore(L.build_store e' (lookup s) builder); e'
      | SIndex(le, i) -> let ls = build_expr builder le in
                         let i' = build_expr builder i in
                         let ep' = L.build_call indexList [| ls ; i' |] "" builder in
                         let pt = match (fst le) with
                           | A.List(lt) -> begin match lt with
                             | A.List(_) | A.Str -> L.pointer_type (ltype_of_typ lt)
                             | _ -> ltype_of_typ lt
                             end
                           | _ -> i8_t in (*SHOULD NEVER HAPPEN*)
                         let ep = L.build_bitcast ep' (L.pointer_type pt) "" builder in
                         L.build_load ep "_ele" builder
      | SBinop (e1, op, e2) ->
        let e1' = build_expr builder e1
        and e2' = build_expr builder e2 in
        (match op with
           A.Add     -> L.build_add
         | A.Sub     -> L.build_sub
         | A.And     -> L.build_and
         | A.Or      -> L.build_or
         | A.Equal   -> L.build_icmp L.Icmp.Eq
         | A.Neq     -> L.build_icmp L.Icmp.Ne
         | A.Less    -> L.build_icmp L.Icmp.Slt
         | A.Great   -> L.build_icmp L.Icmp.Sgt
        ) e1' e2' "tmp" builder
      | SCall ("print", [e]) ->
        L.build_call printf_func [| int_format_str ; (build_expr builder e) |]
          "printf" builder
      | SCall ("printStr", [e]) ->
        L.build_call printStr [| (build_expr builder e) |] "_printstr" builder
      | SCall ("copyStr", [(_, SId(dest)) ; (_, SId(src))]) ->
         let d = L.build_malloc struct_str_t "" builder in
         let _ = L.build_call initStr [| d |] "" builder in
         let _ = L.build_store d (lookup dest) builder in
         let s = L.build_load (lookup src) "" builder in
         L.build_call copyStr [| d ; s |] "" builder
      | SCall ("strEq", [e1 ; e2]) ->
         let e1' = build_expr builder e1 in
         let e2' = build_expr builder e2 in
         let i = L.build_call strEq [| e1' ; e2' |] "" builder in
         L.build_icmp L.Icmp.Eq i (L.const_int i32_t 0) "" builder
      | SCall ("freeStr", [(_, SId(s))]) -> 
         let p = L.build_load (lookup s) "_str" builder in
         let r = L.build_call freeStr [| p |] "" builder in
         let _ = L.build_free p builder in r
      | SCall ("subStr", [SLiteral(start) ; SLiteral(end) ; (_, SId(src)) ; (_, SId(dest))]) ->
         let d = L.build_malloc struct_str_t "" builder in
         let _ = L.build_call initStr [| d |] "" builder in
         let _ = L.build_store d (lookup dest) builder in
         let s = L.build_load (lookup src) "" builder in
         L.build_call subStr [| start ; end ; d ; s |] "" builder
      | SCall ("freeList", [(_, SId(s))]) ->
        L.build_call freeList [| lookup s |] "" builder
      | SCall ("listLen", [lexpr]) ->
        let lp = build_expr builder lexpr in
        L.build_call listLen [| lp |] "" builder
      | SCall ("strLen", [exp]) ->
        let sp = build_expr builder exp in
        L.build_call strLen [| sp |] "" builder
      | SCall (f, args) ->
        let (fdef, fdecl) = StringMap.find f function_decls in
        let llargs = List.rev (List.map (build_expr builder) (List.rev args)) in
        let result = f ^ "_result" in
        L.build_call fdef (Array.of_list llargs) result builder
    in

    (* LLVM insists each basic block end with exactly one "terminator"
       instruction that transfers control.  This function runs "instr builder"
       if the current block does not already have a terminator.  Used,
       e.g., to handle the "fall off the end of the function" case. *)
    let add_terminal builder instr =
      match L.block_terminator (L.insertion_block builder) with
        Some _ -> ()
      | None -> ignore (instr builder) in

    (* Build the code for the given statement; return the builder for
       the statement's successor (i.e., the next instruction will be built
       after the one generated by this call) *)
    let rec build_stmt builder = function
        SBlock sl -> List.fold_left build_stmt builder sl
      | SExpr e -> ignore(build_expr builder e); builder
      | SReturn e -> ignore(L.build_ret (build_expr builder e) builder); builder
      | SIf (predicate, then_stmt, else_stmt) ->
        let bool_val = build_expr builder predicate in

        let then_bb = L.append_block context "then" the_function in
        ignore (build_stmt (L.builder_at_end context then_bb) then_stmt);
        let else_bb = L.append_block context "else" the_function in
        ignore (build_stmt (L.builder_at_end context else_bb) else_stmt);

        let end_bb = L.append_block context "if_end" the_function in
        let build_br_end = L.build_br end_bb in (* partial function *)
        add_terminal (L.builder_at_end context then_bb) build_br_end;
        add_terminal (L.builder_at_end context else_bb) build_br_end;

        ignore(L.build_cond_br bool_val then_bb else_bb builder);
        L.builder_at_end context end_bb

      | SWhile (predicate, body) ->
        let while_bb = L.append_block context "while" the_function in
        let build_br_while = L.build_br while_bb in (* partial function *)
        ignore (build_br_while builder);
        let while_builder = L.builder_at_end context while_bb in
        let bool_val = build_expr while_builder predicate in

        let body_bb = L.append_block context "while_body" the_function in
        add_terminal (build_stmt (L.builder_at_end context body_bb) body) build_br_while;

        let end_bb = L.append_block context "while_end" the_function in

        ignore(L.build_cond_br bool_val body_bb end_bb while_builder);
        L.builder_at_end context end_bb
      | SFor ((lt ,SId(var)), ls, body) ->
        let for_bb = L.append_block context "for" the_function in
        let _ = L.build_br for_bb builder in
        let for_builder = L.builder_at_end context for_bb in

        let lp = build_expr for_builder ls in
        let ip = L.build_alloca i32_t "index" for_builder in
        let _ = L.build_store (L.const_int i32_t 0) ip for_builder in
        let len = L.build_call listLen [| lp |] "len" for_builder in

        let for_cond_bb = L.append_block context "for_cond" the_function in
        let for_cond_builder = L.builder_at_end context for_cond_bb in
        let build_br_for_cond = L.build_br for_cond_bb in (* partial function *)
        ignore (build_br_for_cond for_builder);

        let for_body_bb = L.append_block context "for_body" the_function in
        let for_body_builder = L.builder_at_end context for_body_bb in 

        let end_bb = L.append_block context "for_end" the_function in
        let i_curr = L.build_load ip "i_curr" for_cond_builder in
        let bool_val = L.build_icmp L.Icmp.Eq i_curr len "for_bool" for_cond_builder in
        let _ = L.build_cond_br bool_val end_bb for_body_bb for_cond_builder in

        let ep' = L.build_call indexList [| lp ; i_curr |] "" for_body_builder in
        let pt = match lt with
            | A.List(_) | A.Str -> L.pointer_type (ltype_of_typ lt)
            | _ -> ltype_of_typ lt in
        let ep = L.build_bitcast ep' (L.pointer_type pt) "" for_body_builder in
        let ele_temp = L.build_load ep "_ele" for_body_builder in
        let _ = L.build_store ele_temp (lookup var) for_body_builder in

        let for_body_builder = build_stmt for_body_builder body in
        let i_inc = L.build_add i_curr (L.const_int i32_t 1) "i_inc" for_body_builder in
        let _ = L.build_store i_inc ip for_body_builder in
        ignore (build_br_for_cond for_body_builder);

        L.builder_at_end context end_bb

      | SFor (_,_,_) ->
        (* This should actually never be possible but I want
         * the warnings to go away *)
        builder

    in
    (* Build the code for each statement in the function *)
    let func_builder = build_stmt builder (SBlock fdecl.sbody) in

    (* Add a return if the last block falls off the end *)
    add_terminal func_builder (L.build_ret (L.const_int i32_t 0))

  in

  List.iter build_function_body functions;
  the_module
