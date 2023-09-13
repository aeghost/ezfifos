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
  val remove : callback:(elt -> unit Lwt.t) -> discriminator -> unit Lwt.t
  val clear : unit -> unit Lwt.t
end

type listener = {
  path: string;
  thread: unit Lwt.t;
}

let remove_file p = try
    Sys.remove p
  with _ ->
    FileUtil.(rm ~force:Force) ~recurse:true [ p ]

module List_db : DB
  with type t = listener list
  with type elt = listener
   and type discriminator = string = struct

  type t = listener list
  type elt = listener
  type discriminator = string

  let db : t ref = ref []

  let add (t: elt) =
    db := t :: !db

  let remove ~callback discriminator =

    let remove_callback t =
      let%lwt () = if t.path = discriminator then
          let%lwt () = callback t in
          Lwt.return_unit
        else
          Lwt.return_unit
      in
      Lwt.return (t.path <> discriminator)
    in

    let%lwt l = Lwt_list.filter_s remove_callback !db in
    let () = db := l in
    Lwt.return_unit

  let clear () =
    let () = db := [] in
    Lwt.return_unit

end

module Driver (Db : DB
               with type t = listener list
                and type elt = listener
                and type discriminator = string) = struct
  exception Fifo_read_error of exn
  exception Fifo_write_error of exn

  let master_switch = ref true

  let add_listener ~path thread = Db.add { path; thread }

  (* let get_ic () = Lwt_io.(open_file ~mode:Input) ~flags:Unix.[ O_RDONLY; O_CREAT ] path
     let close_ic ic = Lwt_io.( ~mode:Input) ~flags:Unix.[ O_RDONLY; O_CREAT ] path  *)

  (** [initialize ?(soft = false) ~path ()] initialize the fifo at [~path],
      - creates the file if it does not exist
      - rm and creates it correctly if it exists, except if you set [?soft] at [true]
  *)
  let initialize ?(soft = false) ~path () =
    let create_fifo () =
      Unix.mkfifo path 0o666;
      Unix.chmod path 0o666
    in
    let%lwt () = match Sys.file_exists path with
      | true when soft ->
        Lwt.return_unit
      | true ->
        let () = remove_file path in
        let () = create_fifo () in
        Lwt.return_unit
      | false -> create_fifo ();
        Lwt.return_unit
    in
    Lwt.return_unit

  let close path =
    let callback t =
      let () = Lwt.cancel t.thread in
      let () = remove_file t.path in
      Lwt.return_unit
    in
    Db.remove ~callback path

  let read ?(seq = true) callback path =
    Lwt_io.(with_file ~mode:Input) ~flags:Unix.[ O_RDONLY; O_CREAT ] path
      (fun ic -> try
          Fmt.pr "ici@.";
          let res = Lwt_io.(read_lines ic) in
          let () = Lwt.async (fun () -> Lwt_stream.(if seq then iter_s else iter_p) (fun s -> callback s) res) in
          Lwt.return_unit
        with e -> raise (Fifo_read_error e))

  let background_read ?seq ~(callback: string -> unit Lwt.t) path =
    let%lwt () = initialize ~path () in
    let waiter, wakener = Lwt.task () in
    let rec thread () =
      let%lwt () = read ?seq callback path in
      thread ()
    in
    add_listener ~path (let%lwt () = waiter in thread ());
    Lwt.return @@ Lwt.wakeup wakener ()

  let read_once ?seq ~(callback: string -> unit Lwt.t) path =
    let%lwt () = close path in
    let callback s =
      let%lwt () = callback s in
      let%lwt () = Lwt.pause () in
      let%lwt () = close path in
      Lwt.return_unit
    in
    let%lwt () = background_read ?seq ~callback path in
    let%lwt () = Lwt.pause () in
    let%lwt () = close path in
    Lwt.return_unit

  let listen ?seq ?(stop = ref false) ~(callback: string -> unit Lwt.t) path =
    let%lwt () = background_read ?seq ~callback path in
    let () = if not !master_switch then master_switch := true in
    let%lwt () =
      while%lwt not !stop && !master_switch do
        Lwt.pause ()
      done
    in
    let%lwt () = close path in
    Lwt.pause ()

  let write ~path datas =
    try
      Lwt_io.(with_file ~mode:Output) ~flags:Unix.[ O_CREAT; O_WRONLY; O_NONBLOCK ] path (fun oc -> Fmt.pr "là@."; Lwt_io.fprint oc datas)
    with e -> Lwt.fail (Fifo_write_error e)

  let stop_all () =
    master_switch := false;
    let%lwt () = Lwt_list.iter_p (fun t -> close t.path) !Db.db in
    Db.clear ()

end

module Ezfifos = Driver(List_db)
include Ezfifos