
\ High level versions of string utilities needed for sifting

only forth also hidden also definitions
decimal
forth definitions
\ True if str1 is a substring of str2
: substring?   ( adr1 len1  adr2 len2 -- flag )
   rot tuck     ( adr1 adr2 len1  len2 len1 )
   <  if  3drop false  else  tuck $=  then
;

headerless
: unpack-name ( anf where -- where) \ Strip funny chars from a name field
   swap name>string rot pack
;
\ hidden definitions
: 4dup   ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 n3 n4 )  2over 2over  ;

headers
\ forth definitions
: sindex  ( adr1 len1 adr2 len2 -- n )
   0 >r
   begin  ( adr1 len1 adr2' len2' )
      \ If string 1 is longer than string 2, it is not a substring
      2 pick over  >  if  r> 5drop  -1 exit   then
      4dup substring?  if  4drop r> exit  then
      \ Not found, so remove the first character from string 2 and try again
      swap 1+ swap 1-
      r> 1+ >r
   again
;

\ This version is faster (due to bscan being a code word) and arguably more convenient than sindex
: $sindex  ( small$ big$ -- rem$ )
   2 pick 0=  if  4drop 0  then  \ Null string is initial substring of anything
   3 pick c@  >r                 ( small$ big$  r: firstchar )
   begin  r@  bscan  dup while   ( small$ rem$  r: firstchar )
      4dup substring?  if        ( small$ rem$  r: firstchar )
         2swap r> 3drop  exit    ( -- rem$ )
      then                       ( small$ rem$  r: firstchar )
      1 /string                  ( small$ rem$'  r: firstchar )
   repeat                        ( small$ rem$  r: firstchar )
   2swap r> 3drop                ( rem$ )
;

only forth also definitions

