(** DEMO
    @copyright None
    @author Matthieu GOSSET
    @maintainers
      Matthieu GOSSET <matthieu.gosset.dev@chapsvision.com>
    @purpose
      Quick testing the lib
*)
let test_datas = "data_test"
let fifo_path = try Array.get Sys.argv 1
  with _ -> failwith "Enter a path to bind a fifo"

(* Assert result *)
let test read_datas =
  assert (test_datas = read_datas)

(* Read $1 FIFO *)
let read () =
  let () = print_endline "1. Listen fifo" in
  Ezfifos.listen ~callback:(fun s ->
      let%lwt () =
        print_endline "3. Read data_test"
        |> Lwt.return in
      let () = test s in
      Lwt.return_unit) fifo_path;
  Lwt.return_unit

(* Write in $1 FIFO *)
let write () =
  let%lwt () = Lwt_unix.sleep 1. in
  let () = print_endline "2. Write data_test" in
  let%lwt () = Ezfifos.write ~path:fifo_path test_datas in
  Lwt.return_unit

(* Close all fifos when Done *)
let close () =
  let () = print_endline "5. Closing fifos" in
  Ezfifos.stop_all ()

let () = Lwt_main.at_exit close

let main () =
  let () = print_endline "0. Demo starting" in
  let%lwt () = Lwt.join [ read (); write () ] in
  let () = print_endline "4. Demo stopping" in
  Lwt.return_unit

let () =
  main ()
  |> Lwt_main.run