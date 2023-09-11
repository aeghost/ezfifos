(lang dune 2.8)

(generate_opam_files true)

(name ezfifos)

(package
 (name ezfifos)
 (version 0.1.0)
 (synopsis "A simple way to read Linux's FIFOs")
 (description "Read Linux FIFOs, Write in Linux FIFOs")
 (license "MIT")
 (authors "Matthieu GOSSET matthieu.gosset.dev@outlook.com")
 (maintainers "Matthieu GOSSET matthieu.gosset.dev@outlook.com")
 (homepage "https://github.com/aeghost/ezfifos")
 (source
  (github "aeghost/ezfifos"))
 (bug_reports "https://github.com/aeghost/ezfifos/issues")
 (depends
  (lwt
   (>= 4.0.0))
  (fileutils
   (>= 0.6.0))))
