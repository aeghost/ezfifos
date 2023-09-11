# EZFifos

## Objectives

Simply read Linux Fifos as much as you want

EZ to do, so EZ to use.

## Usage

Read:

```ocaml
let do_something = print_endline

let read () =
  Ezfifos.listen
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
    Ezfifos.write ~path:"/path/to/fifo" "datas"

let () =
    Lwt_main.run (write ())
```

## Notes

It scales (tested with millions of R/W in CrossinG® main workload with 2 parrallels FIFOs)

BUT I assumed you won't bind hundred thousands of FIFOs so Fifos_database is just a simple List,

You may prefer to rewrite Db module with Hmap of Hashtabl if you need to manage a lot of fifos,
less memory efficiant but scales

## Quickdemo

```sh
$ dune exec bin/demo.exe ~/Documents/test_files/test_fifo
```