open Core
open Async

(* $MDX part-begin=1 *)

(* Generate a DuckDuckGo search URI from a query string *)
let query_uri ~server query =
  let base_uri =
    Uri.of_string
      (String.concat [ "http://"; server; "/?format=json" ])
  in
  Uri.add_query_param base_uri ("q", [ query ])

(* $MDX part-end *)

(* Extract the "Definition" or "Abstract" field from the DuckDuckGo
   results *)
let get_definition_from_json json =
  match Yojson.Safe.from_string json with
  | `Assoc kv_list ->
    let find key =
      match List.Assoc.find ~equal:String.equal kv_list key with
      | None | Some (`String "") -> None
      | Some s -> Some (Yojson.Safe.to_string s)
    in
    (match find "Abstract" with
    | Some _ as x -> x
    | None -> find "Definition")
  | _ -> None

(* Execute the DuckDuckGo search *)
let get_definition ~server word =
  let%bind _, body =
    Cohttp_async.Client.get (query_uri ~server word)
  in
  let%map string = Cohttp_async.Body.to_string body in
  word, get_definition_from_json string

(* Print out a word/definition pair *)
let print_result (word, definition) =
  printf
    "%s\n%s\n\n%s\n\n"
    word
    (String.init (String.length word) ~f:(fun _ -> '-'))
    (match definition with
    | None -> "No definition found"
    | Some def ->
      String.concat ~sep:"\n" (Wrapper.wrap (Wrapper.make 70) def))

(* $MDX part-begin=2 *)

(* Run many searches in parallel, printing out the results after
   they're all done. *)
let search_and_print ~servers words =
  let servers = Array.of_list servers in
  let%map results =
    Deferred.all
      (List.mapi words ~f:(fun i word ->
           let server = servers.(i mod Array.length servers) in
           get_definition ~server word))
  in
  List.iter results ~f:print_result

(* $MDX part-end *)

let () =
  Command.async
    ~summary:"Retrieve definitions from duckduckgo search engine"
    (let%map_open.Command words = anon (sequence ("word" %: string))
     and servers =
       let string_list =
         Command.Arg_type.create (String.split ~on:',')
       in
       flag
         "-servers"
         (optional_with_default [ "api.duckduckgo.com" ] string_list)
         ~doc:" Specify server to connect to"
     in
     fun () -> search_and_print ~servers words)
  |> Command.run
