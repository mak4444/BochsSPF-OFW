
\ Temporary hex, and temporary decimal.  "h#" interprets the next word
\ as though the base were hex, regardless of what the base happens to be.
\ "d#" interprets the next word as though the base were decimal.
\ "o#" interprets the next word as though the base were octal.
\ "b#" interprets the next word as though the base were binary.

\  Also, words to stash and set, and retrieve, the base during execution
\     of a word in which they're used.  The words of the form  push-<base>
\     (where <base> is hex, decimal, etcetera) does the equivalent of
\     base @ >r <base>     The word  pop-base  recovers the old base...

decimal
headerless 

: #:  \ name  ( base -- )  \ Define a temporary-numeric-mode word
   create c, immediate
   does>
   base @ >r  c@ base !
   parse-word
   2dup 2>r  $handle-literal?  0=  if
      2r@  $do-undefined
   then
   2r> 2drop
   r> base !
;

headerless

\ The old names; use h# and d# instead
10 #: td
16 #: th

headers 

 2 #: b#	\ Binary number
 8 #: o#	\ Octal number
10 #: d#	\ Decimal number
16 #: h#	\ Hex number

headerless 

: push-base:  \ name   ( base -- )  \  Define a base stash-and-set word
   create c,
   does>  r> base @ >r >r c@ base !
;

headers 

\  Stash the old base on the return stack and set the base to ...
10 push-base:  push-decimal
16 push-base:  push-hex

 2 push-base:  push-binary
 8 push-base:  push-octal

\  Retrieve the old base from the return stack

: pop-base ( -- )  r> r> base ! >r ;
