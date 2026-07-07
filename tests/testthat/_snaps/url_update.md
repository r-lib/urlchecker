# url_update() rewrites permanently moved URLs in the source

    Code
      url_update(root, results = res)
    Message
      v Updated: <http://{host}/moved> to <http://{host}/ok> in 'URLS.txt'
      v All URLs are correct!

# url_update() leaves plain errors untouched

    Code
      url_update(root, results = res)
    Message
      x Error: URLS.txt:1:1 404: Not Found
      http://{host}/notfound
      ^~~

