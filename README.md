# EZ-FIFOs with LWT

## Objectives

Read FileDescr FIFOs efficiantly.

Asynchronous programming needs Async, LWT or EIO.

And LWT is compatible with EIO through Lwt_eio lib, and Async.

EZ to do, so it should stay EZ to use.

## Usage

Background-read:

The `background_read` function declare a passive thread that will `read` and bind `callback` to the read result.
It will be executed if the binary has nothing to do (`Lwt.pause ()`).

```ocaml
let do_something s =
  print_endline s;
  Lwt.return_unit

let declare_thread () =
  Lwt.join [ Ezfifos_lwt.(background_read ~callback:do_something "/path/to/fifo") ]
```

Listen-passive server:

The `listen` function declare a non-stopping, non-blockant server that will bind `callback` to read result.

It will run until FIFO is empty and then wait for more.

It will be closed `at_exit` or when calling close `path` or `stop_all`.

```ocaml
let should_stop = ref false
let do_something s = print_endline s; Lwt.return_unit

let server () =
  Lwt.join [ Ezfifos_lwt.(listen ~stop:should_stop ~callback:do_something "/path/to/fifo") ]
```

Read once:

It will empty FIFO once, bind result to `callback` then stop.

```ocaml
let do_something = print_endline

let read () =
  Ezfifos_lwt.read_once
    ~callback:(fun s ->
        let () = do_something s in
        Lwt.return_unit)
    "/path/to/fifo"

let () =
    Lwt_main.run (read ())
```

Write:

It will write `datas` to FIFO, similar to `Printf.fprintf`, doubted to add the fun, but at least it is using cool `Lwt_io`.

```ocaml
let write () =
    Ezfifos_lwt.write ~path:"/path/to/fifo" "datas"

let () =
    Lwt_main.run (write ())
```

## Notes

It scales (tested with millions of R/W in [CrossinG®](https://www.chapsvision.com/softwares-data/cybersecurity-crossing/) main workload)

BUT I assumed you won't bind hundred thousands of FIFOs so Fifos_database is just a simple List of path/thread retainer,

You may prefer to rewrite Db module with Hmap of Hashtabl if you need to manage a lot of fifos,
less memory efficiant but scales

## Quickdemo

```sh
$ dune exec bin/demo.exe ~/Documents/test_files/test_fifo
```