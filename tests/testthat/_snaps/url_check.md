# url_check() errors on a tarball that is not a package

    Code
      url_check(tarball)
    Message
      i Tarball 'notpkg.tar.gz'
    Condition
      Error in `extract_package_tarball()`:
      ! Cannot determine package root in extracted tarball, no DESCRIPTION file found

