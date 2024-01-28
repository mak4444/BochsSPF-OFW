
[ifndef] omit-files
hex
\ Aligns to a 512-byte boundary; this is okay for most systems.
: _falign  ( l.byte# fd -- l.aligned )  drop  1ff invert and  ;
: _dfalign  ( d.byte# fd -- d.aligned )  drop  swap 1ff invert and swap	;
[then]


headers
\ Line terminators for various operating systems
create lf-pstr    1 c, linefeed c,               \ Unix
create cr-pstr    1 c, carret   c,               \ Macintosh, OS-9
create crlf-pstr  2 c, carret   c,  linefeed c,  \ DOS
[then]

