(** TESTS
    @copyright None
    @author Matthieu GOSSET
    @maintainers
      Matthieu GOSSET <matthieu.gosset.dev@chapsvision.com>
    @purpose
      Quick testing the lib
*)
let test_datas = try Array.get Sys.argv 2
  with _ -> "data_test"
let fifo_path = try Array.get Sys.argv 1
  with _ -> failwith "Enter a path to bind a fifo"

let i = ref 0
let incr () = i := !i + 1
let debug s =
  let () = incr () in
  print_endline (string_of_int !i ^ ". " ^ s)

(* Assert result *)
let test read_datas =
  assert (test_datas = read_datas)

(* Read $1 FIFO *)
let read_callback s =
  let%lwt () =
    let () = debug @@ "Read " ^ s in
    Lwt.return_unit in
  let () = test s in
  Lwt.return_unit

let read () =
  let () = debug "MONO Read FIFO" in
  let%lwt () = Ezfifos_lwt.background_read ~callback:read_callback fifo_path in
  Lwt.return_unit

(* Write in $1 FIFO *)
let write s =
  let () = debug @@ "Write " ^ s in
  let%lwt () = Ezfifos_lwt.write ~path:fifo_path s in
  Lwt.return_unit

(* Close all fifos when Done *)
let close () =
  let () = debug "<on_exit> Closing fifos" in
  Ezfifos_lwt.stop_all ()

let () = Lwt_main.at_exit close

let stop = ref false
let callback = function
    s when Str.string_match Str.(regexp "stop") s 0 ->
    stop := true;
    Lwt.pause ()
  | s ->
    debug s;
    test s;
    Lwt.pause ()

let server () =
  Lwt.join [ Ezfifos_lwt.(listen ~stop ~callback fifo_path) ]

let test_bg_read () =
  let () = debug "TEST: Read - should read `test_data` and assert true" in
  let%lwt () = Lwt.join [
      read ();
      let%lwt () = Lwt.pause () in
      write test_datas
    ] in
  let%lwt () = Lwt.pause () in
  Lwt.return_unit

let test_server () =
  let () = debug "TEST: Server - should stop without error and assert true" in
  let () = debug "Server running" in
  let%lwt () = Lwt.join [
      server ();
      let%lwt () = Lwt_unix.sleep 1. in
      let%lwt () = write "stop" in
      Lwt.pause ()
    ] in
  let () = debug "Server stopping" in
  Lwt.return_unit

let test_read_once () =
  let () = debug "TEST: Read Once - should stop without error and assert true" in
  let%lwt () = Ezfifos_lwt.read_once ~callback:(fun s ->
      let%lwt () =
        let () = debug @@ "Read " ^ s in
        let () = test s in
        Lwt.return_unit in
      Lwt.return_unit) fifo_path in
  let%lwt () = Lwt.pause () in
  let%lwt () = write test_datas in
  let%lwt () = Lwt.pause () in
  Lwt.return_unit

let test_stop_all () =
  let () = debug "TEST: Close_all - Server should stop without reading anything, no assertion" in
  let () = debug "Server running" in
  let%lwt () = Lwt.join [
      server ();
      let%lwt () = Lwt.pause () in
      let%lwt () = Ezfifos_lwt.stop_all () in
      Lwt.pause ()
    ] in
  let () = debug "Server stopping" in
  Lwt.return_unit

let main () =
  let () = debug "Demo starting" in
  let%lwt () = test_bg_read () in
  let%lwt () = Lwt_unix.sleep 0.5 in
  let%lwt () = test_server () in
  let%lwt () = Lwt_unix.sleep 0.5 in
  let%lwt () = test_read_once () in
  let%lwt () = Lwt_unix.sleep 0.5 in
  let%lwt () = test_stop_all () in
  let () = debug "Demo stopping" in
  let () = FileUtil.rm ~force:Force [fifo_path] in
  Lwt.return_unit

let () =
  main ()
  |> Lwt_main.run
