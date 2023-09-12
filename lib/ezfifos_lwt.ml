(** EZFIFOS-LWT
    @copyright 2023 MIT -- NO RIGHTS RESERVED. Deal with it !
    @author Matthieu GOSSET
    @maintainers
      Matthieu GOSSET <matthieu.gosset.dev@outlook.com>
    @purpose
      Manage Simple FIFOs lecture
*)

module type DB = sig
  type t
  type elt
  type discriminator
  val db : t ref
  val add : elt -> unit
  val remove : callback:(elt -> unit) -> discriminator -> unit
  val clear :  callback:(elt -> unit) -> unit -> unit Lwt.t
end

type listener = {
  path: string;
  thread: unit Lwt.t;
}

module List_db : DB
  with type elt = listener
   and type discriminator = string = struct
  type t = listener list
  type elt = listener
  type discriminator = string

  let db : t ref = ref []

  let add (t: elt) =
    db := t :: !db
  let remove ~callback discriminator =
    db := List.filter
        (fun t ->
           if t.path = discriminator then
             callback t;
           t.path <> discriminator) !db

  let clear ~callback () =
    let%lwt () = Lwt_list.iter_p (fun t ->
        callback t;
        Lwt.return_unit) !db in
    Lwt.return_unit
end

module Driver (Db : DB
               with type elt = listener
                and type discriminator = string) = struct
  exception Fifo_read_error of exn
  exception Fifo_write_error of exn

  let master_switch = ref true

  let add_listener ~path f = Db.add { path; thread = f }

  (** [initialize ?(soft = false) ~path ()] initialize the fifo at [~path],
      - creates the file if it does not exist
      - rm and creates it correctly if it exists, except if you set [?soft] at [true]
  *)
  let initialize ?(soft = false) ~path () =
    let create_fifo () =
      Unix.mkfifo path 0o666;
      Unix.chmod path 0o666
    in
    match Sys.file_exists path with
    | true when soft -> ()
    | true -> FileUtil.(rm  ~recurse:true ~force:Force [ path ] ); create_fifo ()
    | false -> create_fifo ()

  let terminate (t: listener) =
    Lwt.cancel t.thread;
    if Sys.file_exists t.path then
      FileUtil.(rm ~recurse:true ~force:Force [ t.path ])
    else ()

  let close path =
    Db.remove ~callback:terminate path

  let read ~path () : string Lwt.t =
    let rec loop () =
      let buffer_size = 1024 in
      let buffer = Bytes.create buffer_size in
      try%lwt
        let%lwt file_descr = Lwt_unix.openfile path [ O_RDONLY; O_CREAT ] 0 in
        let%lwt size = Lwt_unix.read file_descr buffer 0 buffer_size in
        Lwt_unix.close file_descr;%lwt
        match size with
        | 0 -> loop ()
        | n ->
          Bytes.sub_string buffer 0 n
          |> Lwt.return
      with e -> Lwt.fail (Fifo_read_error e)
    in
    loop ()

  let background_read ~(callback: string -> unit Lwt.t) path =
    let () = initialize ~path () in
    let waiter, wakener = Lwt.task () in
    let rec thread () =
      let%lwt data = read ~path () in
      let%lwt () = callback data in
      thread ()
    in
    add_listener ~path (let%lwt () = waiter in thread ());
    Lwt.wakeup wakener ()

  let read_once ~(callback: string -> unit Lwt.t) path =
    let () = close path in
    let callback s =
      let%lwt () = callback s in
      let%lwt () = Lwt.pause () in
      let () = close path in
      Lwt.return_unit
    in
    let () = background_read ~callback path in
    let%lwt () = Lwt.pause () in
    Lwt.return_unit

  let listen ?(stop = ref false) ~(callback: string -> unit Lwt.t) path =
    let () = background_read ~callback path in
    let () = if not !master_switch then master_switch := true in
    let%lwt () =
      while%lwt not !stop && !master_switch do
        Lwt.pause ()
      done
    in
    let () = close path in
    Lwt.pause ()

  let write ~path datas =
    try
      Lwt_io.with_file ~flags:Unix.[ O_CREAT; O_WRONLY; O_NONBLOCK ] ~mode:(Lwt_io.Output) path (fun oc -> Lwt_io.fprint oc datas)
    with e -> Lwt.fail (Fifo_write_error e)

  let stop_all () =
    master_switch := false;
    Db.clear ~callback:terminate ()

end

module Ezfifos = Driver(List_db)
include Ezfifos

let () =
  Lwt_main.at_exit stop_all