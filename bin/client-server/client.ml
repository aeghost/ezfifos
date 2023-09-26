(** CLIENT
    @author Matthieu GOSSET
    @purpose
      Minimalist client
*)
let messages = [
  `Message "text";
  `Type (`Dummy);
  `Stop
]

type c = {
  listen: string;
  write: string;
}

let stop = ref false

let get_path i = try Array.get Sys.argv i
  with _ -> failwith "Enter a path to bind a fifo"

let log = print_endline

let configuration: c = {
  listen = get_path 1;
  write = get_path 2;
}

let send_messages () =
  Lwt_list.iteri_s (fun i m ->
      log ("Sending : " ^ string_of_int i);
      m
      |> Protocol.to_string
      |> Ezfifos_lwt.write ~path:configuration.write
    ) messages

let on_message = function
  | `Ack ->
    log "Server Ack";
    Lwt.pause ()
  | `Stop ->
    log "Stopping...";
    stop := true;
    Lwt.pause ()
  | _ ->
    log "Unkown Message";
    Lwt.pause ()

let ack_server_messages () =
  Ezfifos_lwt.listen ~stop ~callback:(fun s -> Protocol.of_string s |> on_message) configuration.listen

let main () =
  let () = log @@ "Client Starting with [listening: " ^ configuration.listen ^ "] and [writing: " ^ configuration.write ^ "]" in
  let%lwt () = Lwt.join [
      ack_server_messages ();
      let%lwt () = Lwt.pause () in send_messages ()
    ] in
  let () = log "Client Stopping" in
  let%lwt () = Ezfifos_lwt.stop_all () in
  Lwt.return_unit

let () = Lwt_main.run @@ main ()

