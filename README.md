# EZ-FIFOs with LWT

## Objectives

Read FileDescr FIFOs efficiantly.

Asynchronous programming needs Async, LWT or EIO.

And LWT is compatible with EIO through Lwt_eio lib, and Async.

EZ to do, so it should stay EZ to use.

## Usage

### Background-read

```ocaml
let () =
  Ezfifos_lwt.background_read ~callback:(fun s -> print_endline s; Lwt.return_unit) "/path/to/fifo"
```

The `background_read` function will declare a passive thread that will `read` and bind `callback` to the read result.

It will be executed if the binary has nothing to do (`Lwt.pause ()`).

### Listen-passive server

```ocaml
let stop = ref false
let callback s = print_endline s; Lwt.return_unit

let server () = Ezfifos_lwt.listen ~stop ~callback "/path/to/fifo"

let () =
  Lwt_main.run Lwt.(join [ server (); ... ])
```

The `listen` function will declare a non-stopping, non-blockant server that will bind `callback` to read result.

It will run until FIFO is empty and then wait for more.

It will be closed `at_exit` or when calling `close path` or `stop_all ()`.

You can stop it by switching the `stop` ref to `true`

### Read once

```ocaml
let () =
  Lwt_main.run
    Ezfifos_lwt.(read_once ~callback:(fun s -> print_endline s; Lwt.return_unit) "/path/to/fifo")
```

It will empty FIFO once, bind result to `callback` then stop, similar as `Lwt_io.read` & `FileUtils.rm` but slower, but available.

### Write

```ocaml
let () =
  Lwt_main.run Ezfifos_lwt.(write ~path:"/path/to/fifo" "datas")
```

It will write `datas` to FIFO, similar to `Printf.fprintf`, doubted to add the fun, but at least it is using cool `Lwt_io`.

## Notes

It scales (tested with millions of R/W in [CrossinG®](https://www.chapsvision.com/softwares-data/cybersecurity-crossing/) main workload)

BUT I assumed you won't bind hundred thousands of FIFOs so Fifos_database is just a simple List of path/thread retainer,

You may prefer to rewrite Db module with Hmap of Hashtabl if you need to manage a lot of fifos,
less memory efficiant but scales

## Quickdemo

```sh
$ dune exec bin/demo.exe ~/Documents/test_files/test_fifo
```