open ExtensionOcamlComponent.Parsing
open ExtensionOcamlComponent.SpecSpec
open ExtensionOcamlComponent.TypeSystem
open ExtensionOcamlComponent.Typecheck
open ExtensionOcamlComponent.Unification
(* open ExtensionOcamlComponent.Util *)

let testSpecSpec (_ : unit) =
  print_endline "Test: ability to load a spec, and use that spec to check a second program.";
  let parserSpec = makeParser spec in
  
  (* The specification for the program *)
  let langSpec =
    {|
{
    C1,
    Bla1
    ------ "_ + _"
    C2
}
{
  ------ "f"
  ?any
}
{
    C4,
    ?x2
    ---- "_ -> _"
    C4 
}
    |};
  in

  let _langSpec = 
{|{{Test Bla} -"a" (fst (\x y.x, \x y.y)) } |}
  in

  (* The program to be checked *)
  let program = [
    {|
    f + f
    |};
  ] in

  (* log_time "start"; *)

  let topSort = (topLevel nilSort (MetaVar (freshId ()))) in
  (* log_time "parsing"; *)
  let parsed = doParse parserSpec (fun x -> x) show_term [langSpec]
    topSort
    (fun x y -> Option.is_some (unify [x, y])) in
  (* log_time "parsed"; *)
  match parsed with
  | Error msg -> print_endline ("Failed to parse spec: " ^ msg)
  | Ok t ->
    (* print_endline "parsed AST of spec:"; *)
    (* print_endline (show_tree show_ast_label_short t); *)
    (* log_time "checking"; *)
    let typeErrors = typecheck spec topSort t in
    (* log_time "checked"; *)
    if List.length typeErrors <> 0 then
      (print_endline "Typechecking errors while checking spec:";
      List.iter (fun err -> print_endline (show_errorMessasge err)) typeErrors)
    else (
      print_endline "Spec checked correctly, converting to inductive: ";
      (* log_time "start convert to inductive"; *)
      let lang = specAstToLang t in
      (* log_time "end convert to inductive"; *)
      print_endline ("Conclusion of first constructor: " ^ (show_term ((List.hd lang).constructor.conclusion)));

      let topSort = freshMetaVar () in
      let progParser = makeParser lang in (* TODO: This should take sub!*)
      (* log_time "start parsing prog"; *)
      let parsedProg = doParse progParser (fun x -> x) show_term program
        topSort
        (fun x y -> Option.is_some (unify [x, y]))
        (* (fun _x _y -> true) *)
      in
      (* log_time "end parsing prog"; *)
      match parsedProg with
      | Error msg -> print_endline ("Failed to parse program: " ^ msg)
      | Ok t ->
        print_endline "Program parsed successfully. parsed AST of program:";
        print_endline (show_tree show_ast_label_short t);
        (* log_time "start typechecking prog"; *)
        let typeErrors = typecheck lang topSort t in
        (* log_time "end typechecking prog"; *)
        if List.length typeErrors <> 0 then
          (print_endline "Typechecking errors while checking spec:";
          List.iter (fun err -> print_endline (show_errorMessasge err)) typeErrors)
        else
        print_endline "Program typechecked!";
        ()
    )



let _ =
    testSpecSpec ();
    (* log_time "done"; *)

  (* print_endline (string_of_bool (Option.is_some (unify [App (Const "a", MetaVar (freshId ())), App (Const "b", MetaVar (freshId ()))]))); *)

