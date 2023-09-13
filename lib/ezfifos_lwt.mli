(** EZFIFOS-LWT
    @copyright None
    @author Matthieu GOSSET
    @maintainers
      Matthieu GOSSET <matthieu.gosset.dev@outlook.com>
    @purpose
      Declare EZFIFOS_LWT LIB interface
*)

(** [background_read ?seq ~callback path] bind [~callback] to read datas at [path],
      on exception it raises [exn Fifo_read_error of exn], it will read every entry on [path] forever,
        but stopped as soon as the binary stopped, NON BLOCKANT!
        it apply [callback] to content sequentially (default) ([seq] = true) or in parallel ([seq] = false) *)
val background_read : ?seq:bool -> callback:(string -> unit Lwt.t) -> string -> unit Lwt.t

(** [read_once ~callback path] bind [~callback] to read datas at [path],
      on exception it raises [exn Fifo_read_error of exn],
        It will read FIFO/file content once, then stopped. *)
val read_once : ?seq:bool -> callback:(string -> unit Lwt.t) -> string -> unit Lwt.t

(** [listen ?stop ~callback path] bind [~callback] to read datas at [path],
      on exception it raises [exn Fifo_read_error of exn],
        It will read FIFO/file until stop return true, then stopped. *)
val listen : ?seq:bool -> ?stop:(bool ref) -> callback:(string -> unit Lwt.t) -> string -> unit Lwt.t

(** [write ~path datas] write [datas] in fifos at [path], it uses Lwt_io.with_file, exceptions are wrapped in [exn Fifo_write_error of exn] *)
val write : path:string -> string -> unit Lwt.t

(** [close path] stop binded fifo on [path] *)
val close : string -> unit Lwt.t

(** [stop_all ()] stop all fifos *)
val stop_all : unit -> unit Lwt.t