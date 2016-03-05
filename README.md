Stacker ASM
===========

This was inspired by a combination of my asmc-blog/asmcc (my assembly compiler),
combined with http://beautifulracket.com/first-lang.html. I was curious how
difficult it would be to implement the basic stack language in raw assembly as a
compiler, with no libraries.

This compiler directly outputs an assembly program which will evaluate and print
the result of the stack operations.

USAGE
======

```bash
$ ./stacker < input_file > output_prog
$ chmod +x output_prog
$ ./output_prog # will print the result
```

LICENSE
=======

The MIT License (MIT)

Copyright (c) 2016 Michael Layzell

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
