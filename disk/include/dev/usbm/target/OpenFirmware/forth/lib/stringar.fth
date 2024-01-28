
\ String-array
\ Creates an array of strings.
\ Used in the form:
\ string-array name
\   ," This is the first string in the table"
\   ," this is the second one"
\   ," and this is the third"
\ end-string-array
\
\ name is later executed as:
\
\ name ( index -- addr )
\   index is a number between 0 and one less than the number of strings in
\   the array.  addr is the address of the corresponding packed string.
\   if index is less than 0 or greater than or equal to the number of
\   strings in the array, name aborts with the message:
\        String array index out of range

decimal
headerless

: string-array  \ name ( -- )
   create
   0 ,    ( the number of strings )
   0 ,    ( the starting address of the pointer table )
   does>  ( index pfa )
   2dup @ ( index pfa  index #strings )
   0 swap within  0= abort" String array index out of range"    ( index pfa )
   tuck  dup na1+ @ +      ( pfa index table-address )
   swap na+  @ +           ( string-address )
;
: end-string-array ( -- )
   here                ( string-end-addr )
   lastacf >body       ( string-end-addr pfa )
   dup >r                 \ Remember pfa of word for use as the base address
   na1+ here r@ - over !  \ Store table address in the second word of the pf
   na1+                ( string-end-addr first-string-addr )
   begin               ( string-end-addr this-string-addr )
       2dup >          ( string-end-addr this-string-addr )
   while
       \ Store string address in table
       dup r@ - ,      ( string-end-addr this-string-addr )
       \ Find next string address
       +str            ( string-end-addr next-string-addr )
   repeat              ( string-end-addr next-string-addr )
   2drop               ( )
   \ Calculate and store number of strings
   lastacf >body       ( pfa )
   dup dup na1+ @ +    ( pfa table-addr )
   here swap - /n /    ( pfa #strings )
   swap !
   r> drop
;
headers

