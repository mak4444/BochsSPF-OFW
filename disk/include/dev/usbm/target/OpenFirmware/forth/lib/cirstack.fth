id: @(#)cirstack.fth 1.6 03/12/08 13:22:21
purpose: 

\ Circular stack defining words
\
\ 10 cirstack: foo    Create a new stack named foo with space for 10 numbers
\ 123 foo push        Push the number 123 on the stack foo
\ foo pop             Pop the top element from the stack foo onto the data stack
\
\ Advantages of a circular stack:
\    does not have to be cleared
\    cannot overflow or underflow
\
\ Disadvantages:
\    can silently lose data
\    implementation is cumbersome
\
\ Applications:
\    Useful for implementing user interfaces where you want to remember a
\    limited amount of "history", such as the last n commands, or the
\    last n directories "visited", but it is not necessary to guarantee
\    unlimited backtracking.

\ Implementation notes:
\    The circular stack data structure contains the following elements:
\        stack data   Space to store the stacked numbers
\        current      Offset into stack data of the next element to pop
\        limit        Size of stack data plus 1 cell
\
\    The elements are located as follows:
\        pfa:   user#   limit
\
\    user# is the offset of a user area location containing the address of
\    an allocated memory buffer.  That buffer contains "current" and "stack
\    data".
\
\    Note that this parameter field is intentionally the same as the parameter
\    field of word defined by "buffer:".  This allows us to automatically
\    allocate the necessary storage space using the buffer: mechanism.
\
\        user area location:  buffer-address
\        buffer-address:      current   stack-data ...

headerless
\ Implementation factor
: stack-params  ( stack -- adr limit current )
   dup  /user# + unaligned-@  /n -  ( stack limit )
   swap do-buffer                   ( limit adr )
   tuck @                           ( adr limit current )
;
headers

\ Creates a new stack
: circular-stack:  \ name  ( #entries -- )
   create
   here body> swap    ( acf #entries )
   1+ /n*             ( acf size )
   0 /n user#,  !     ( acf size )  ,   ( acf )
   buffer-link a@  a,  buffer-link a!
;

\ Adds a number to the stack
: push  ( n stack -- )
   stack-params  na1+       ( n adr limit next )
   tuck  <=  if             ( n adr next )
      drop 0                ( n adr next' )     \ Wrap around
   then                     ( n adr next' )
   2dup swap !              ( n adr next' )
   + na1+ !
;

\ Removes a number from the stack
: pop  ( stack -- n )
   stack-params             ( adr limit current )
   ?dup  if                 ( adr limit current )
      nip 2dup /n - swap !  ( adr current )     \ Decrement current
      +                     ( data-adr- )
   else                     ( adr limit )
      /n - over !           ( data-adr- )       \ Wrap around
   then
   na1+ @
;

\ Returns, without popping, the number on top of the stack
: top@  ( stack -- n )
   stack-params             ( adr limit current )
   dup  if                  ( adr limit current )
      nip  +                ( data-adr- )
   else                     ( adr limit current )
      2drop                 ( data-adr- )       \ Wrap around
   then
   na1+ @
;
