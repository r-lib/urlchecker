# print() reports success when there are no problems

    Code
      print(res)
    Message
      v All URLs are correct!

# print() points at the offending line for a broken URL

    Code
      print(res)
    Message
      x Error: URLS.txt:2:6 404: Not Found
      url: http://{host}/notfound
           ^~~

# print() suggests a fix for a moved URL

    Code
      print(res)
    Message
      ! Warning: URLS.txt:2:4 Moved
         http://{host}/moved
         ^~~
         http://{host}/ok

# print() flags a non-canonical CRAN URL

    Code
      print(res)
    Message
      x Error: DESCRIPTION:2:1 Error: CRAN URL not in canonical form
      https://cran.r-project.org/package=foo
      ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

