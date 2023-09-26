(** DEMO
    @copyright None
    @author Matthieu GOSSET
    @maintainers
      Matthieu GOSSET <matthieu.gosset.dev@chapsvision.com>
    @purpose
      Quick exemple
      Demo will follow some good practices
        of abstrating communication protocols through typing
*)
let fifo_path = try Array.get Sys.argv 1
  with _ -> failwith "Enter a path to bind a fifo"

let stop = ref false

module Bandwidth = struct
  let read = ref 0
  let samples = ref []

  let mean () =
    let denom = List.(length !samples) + 1 |> float_of_int in
    let numer = List.fold_left (+) 0 !samples |> float_of_int in
    let mean = numer /. denom  in
    mean

  let get_max () =
    let max = List.fold_left (fun acc e -> if acc < e then e else acc) 0 !samples in
    max

  let pp_samples ppf () =
    Fmt.pf ppf "@.----- SAMPLES: %a -----@."

  let pp_result ppf () =
    let mean = mean () in
    let max = get_max () in
    Fmt.pf ppf {|
    ----- SAMPLES: %a -----
    ----- Mean bandwidth : %f -----
    ----- Max bandwidth : %i -----@.|}
      Fmt.(list ~sep:(any ", ") int) !samples
      mean
      max

  let report () =
    Fmt.pr "@.%a@." pp_result ()

  let calc_thread () =
    while%lwt not !stop do
      (* let () = Fmt.pr "%a@." pp_result () in *)
      let () =
        samples := !read :: !samples;
        read := 0;
      in
      Lwt_unix.sleep 1.
    done
end


let i = ref 0
let incr () = i := !i + 1
let print (s: string) =
  incr ();
  print_endline ((string_of_int !i) ^ ". " ^ s)

(* Defining a type protocol will let you do the management and the parsing at different places.
   - It will assure you a complete cover of the protocol
   - It will reduce side effects
*)
module Protocol = struct
  type t = [
      `Any of string
    | `Stop
  ]

  let of_string : string -> t = function
    | s when Str.string_match (Str.regexp "stop") s 0 -> `Stop
    | s -> `Any s

  let manage : t -> _ = function
    | `Stop ->
      stop := true;
      Lwt.pause ()
    | `Any s ->
      (* print s; *)
      Bandwidth.(read := !read + String.(length s));
      Lwt.return_unit
end

let callback s = Protocol.(of_string s |> manage)

let main () =
  let () = print "Demo starting" in
  let%lwt () = Lwt.join [ Ezfifos_lwt.(listen ~seq:false ~stop ~callback fifo_path); Bandwidth.calc_thread () ] in
  let () = print "Demo stopping" in
  let () = Bandwidth.report () in
  Lwt.return_unit

let () = main () |> Lwt_main.run
