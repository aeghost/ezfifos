# EZ-FIFOs with LWT

## Objectives

Read FileDescr FIFOs efficiantly.

Asynchronous programming needs Async, LWT or EIO.

And LWT is compatible with EIO through Lwt_eio lib, and Async.

EZ to do, so it should stay EZ to use.

## Usage

Read:

```ocaml
let do_something = print_endline

let read () =
  Ezfifos_lwt.listen
    ~callback:(fun s ->
        let () = do_something s in
        Lwt.return_unit)
    "/path/to/fifo"

  |> Lwt.return

let () =
    Lwt_main.run Lwt.(join [ read () ])
```

Write:

```ocaml
let write () =
    Ezfifos_lwt.write ~path:"/path/to/fifo" "datas"

let () =
    Lwt_main.run (write ())
```

## Notes

It scales (tested with millions of R/W in [CrossinG®](https://www.chapsvision.com/softwares-data/cybersecurity-crossing/) main workload)

BUT I assumed you won't bind hundred thousands of FIFOs so Fifos_database is just a simple List,

You may prefer to rewrite Db module with Hmap of Hashtabl if you need to manage a lot of fifos,
less memory efficiant but scales

## Quickdemo

```sh
$ dune exec bin/demo.exe ~/Documents/test_files/test_fifo
```