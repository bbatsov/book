(** Handling of coq source files *)
open! Dune_engine

open Stdune
open Coq_stanza

type t

val empty : t

(** Coq modules of library [name] is the Coq library name. *)
val library : t -> name:Coq_lib_name.t -> Coq_module.t list

val directories : t -> name:Coq_lib_name.t -> Path.Build.t list

val extract : t -> Extraction.t -> Coq_module.t

val of_dir :
     Stanza.t list Dir_with_dune.t
  -> include_subdirs:Loc.t * Dune_file.Include_subdirs.t
  -> dirs:(Path.Build.t * string list * String.Set.t) list
  -> t

(** [find_module ~source t] finds a Coq library name and module corresponding to
    file [source], if there is one. *)
val find_module :
  source:Path.Build.t -> t -> (Coq_lib_name.t * Coq_module.t) option

val lookup_module :
     t
  -> Coq_module.t
  -> [ `Theory of Theory.t | `Extraction of Extraction.t ] option
