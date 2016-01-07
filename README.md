# index_page

A transformer which outputs an index.html file in each folder that doesn't
already have one. This file simply lists all the files/folder under that
directory. By default it will only run in debug mode.

Example usage which will only output links to html files in the web directory:

```
transformers:
- index_page:
   $include: web/**.html
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/index_page/issues
