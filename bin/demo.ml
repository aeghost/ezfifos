(** DEMO
    @copyright None
    @author Matthieu GOSSET
    @maintainers
      Matthieu GOSSET <matthieu.gosset.dev@chapsvision.com>
    @purpose
      Quick exemple
*)
let fifo_path = try Array.get Sys.argv 1
  with _ -> failwith "Enter a path to bind a fifo"

let i = ref 0
let incr () = i := !i + 1
let debug s =
  let () = incr () in
  print_endline (string_of_int !i ^ ". " ^ s)

let close () =
  let () = debug "<on_exit> Closing fifos" in
  Ezfifos_lwt.stop_all ()

let stop = ref false
let callback = function
    s when Str.string_match (Str.regexp "stop") s 0 ->
    Ezfifos_lwt.close fifo_path;%lwt
    stop := true;
    Lwt.pause ()
  | s ->
    debug s;
    Lwt.return_unit

let main () =
  let () = debug "Demo starting" in
  let%lwt () = Lwt.join [ Ezfifos_lwt.(listen ~seq:false ~stop ~callback fifo_path) ] in
  let () = debug "Demo stopping" in
  Lwt.return_unit

let () =
  main ()
  |> Lwt_main.run
