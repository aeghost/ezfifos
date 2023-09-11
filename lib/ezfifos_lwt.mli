(** EZFIFOS-LWT
    @copyright None
    @author Matthieu GOSSET
    @maintainers
      Matthieu GOSSET <matthieu.gosset.dev@outlook.com>
    @purpose
      Declare EZFIFOS_LWT LIB interface
*)

(** [listen ~callback path] bind [~callback] to read datas at [path],
      it raised Fifo_read_error of exn if it fails *)
val listen : callback:(string -> unit Lwt.t) -> string -> unit

(** [write ~path datas] write [datas] in fifos at [path], used Lwt_io.with_file, so be warn it may raises exception *)
val write : path:string -> string -> unit Lwt.t

(** [stop path] stop binded fifo on [path] *)
val stop : string -> unit

(** [stop_all ()] stop all fifos *)
val stop_all : unit -> unit Lwt.t