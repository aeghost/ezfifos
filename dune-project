(lang dune 2.8)

(generate_opam_files true)

(name ezfifos-lwt)

(package
 (name ezfifos-lwt)
 (version 0.1.2)
 (synopsis "A simple way to read Linux's FIFOs")
 (description "Read Linux FIFOs, Write in Linux FIFOs")
 (license "MIT")
 (authors "Matthieu GOSSET matthieu.gosset.dev@outlook.com")
 (maintainers "Matthieu GOSSET matthieu.gosset.dev@outlook.com")
 (homepage "https://github.com/aeghost/ezfifos-lwt")
 (source
  (github "aeghost/ezfifos-lwt"))
 (bug_reports "https://github.com/aeghost/ezfifos-lwt/issues")
 (depends
  (lwt
   (>= 4.0.0))
  (fileutils
   (>= 0.6.0))))
