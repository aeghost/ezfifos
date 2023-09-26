(** SERVER
    @author Matthieu GOSSET
    @purpose
      Minimalist server
*)

type c = {
  listen: string;
  write: string;
}

let get_path i = try Array.get Sys.argv i
  with _ -> failwith "Enter a path to bind a fifo"

let log = print_endline

let configuration: c = {
  listen = get_path 1;
  write = get_path 2;
}

let respond m =
  log "Responding";
  Ezfifos_lwt.write ~path:configuration.write
  @@ Protocol.to_string m

let on_message = function
  | `Message m ->
    respond `Ack;%lwt
    log ("Client has sent " ^ m);
    Lwt.return_unit
  | `Type `Dummy ->
    respond `Ack;%lwt
    log "Client has sent type `Dummy";
    Lwt.return_unit
  | `Stop ->
    respond `Stop;%lwt
    log "Server Stopping...";
    Ezfifos_lwt.stop_all ()
  | `Error ->
    respond `Error;%lwt
    log "Client send a bad formatted message...";
    Lwt.return_unit
  | _ ->
    respond `Ack;%lwt
    log "Got unkown message";
    Lwt.return_unit

let serve () =
  Ezfifos_lwt.listen ~callback:(fun s -> Protocol.of_string s |> on_message) configuration.listen

let main () =
  let () = log @@ "Server Starting with [listening: " ^ configuration.listen ^ "] and [writing: " ^ configuration.write ^ "]" in
  let%lwt () = Lwt.join [
      serve ()
    ] in
  let () = print_endline "Server Stopping" in
  Lwt.return_unit

let () = Lwt_main.run @@ main ()

