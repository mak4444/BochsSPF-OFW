
: pack  (s str-addr len to -- to )
 DUP >R $! R> ;

: place-cstr  ( adr len cstr-adr -- cstr-adr )
   >r  tuck r@ swap cmove  ( len ) r@ +  0 swap c!  r>
;

: $save  ( adr1 len1 adr2 -- adr2 len1 )  pack count  ;

: m/mod  (s d# n1 -- rem quot )
   dup >r  2dup xor >r  >r dabs r@ abs  um/mod
   swap r>  0< if  negate  then
   swap r> 0< if
      negate over if  1- r@ rot - swap  then
   then
   r> drop
;

: u/mod  (s n1 n2 -- rem quot )   >r    0  r>  m/mod  ;

: >digit (s n -- char )  dup 9 >  if  39 +  then  48 +  ;

: u#     (s u1 -- u2 )
   base @ u/mod  ( nrem u2 )   swap  >digit  hold    ( u2 )
;
: u#s    (s u -- 0 )     begin  u#  dup   0=  until  ;

: u#>    (s u -- addr len )    drop  hld  @  PAD 1-  over  -  ;

: ascii  \ char (s -- n )
   char
 STATE @ IF LIT, THEN
; immediate

: round-up  ( adr granularity -- adr' )
  1-
  tuck
 + 
 swap
 invert
 and
  ;
: (align)  ( size granularity -- )
   1-  begin  dup here and  while  0 c,  repeat  drop
;
: aligned  (s adr -- adr' )  #align round-up  ;
: acf-aligned  (s adr -- adr' )
  #acf-align
 round-up
  ;

: 3drop drop 2drop ;

4 constant /link
VARIABLE 'lastacf
VARIABLE LAST-T

: acf-align  (s -- )  #acf-align (align)
   here 'lastacf !
;

\ Address conversion operators
: n>link   ( anf -- alf )  1+  ;
: l>name   ( alf -- anf )  1- ;
: n>flags  ( anf -- aff )  ;
: link>    ( alf -- acf )  /link +  ;
: >link    ( acf -- alf )  /link -  ;
: name>    ( anf -- acf )  n>link link>  ;
: name>string  ( anf -- adr len )  dup c@ h# 1f and  tuck - swap  ;

\ Find a potential name field address
: find-name  ( acf -- anf )  >link l>name  ;

[IFNDEF] BOUNDS : BOUNDS OVER + SWAP ;
[THEN]

: >name?  ( acf -- anf good-name? )
   dup  find-name                      ( acf anf )
   tuck name>string                    ( anf acf name-adr name-len )
   dup 0=  if  3drop false exit  then  ( anf acf name-adr name-len )
   + /link + acf-aligned               ( anf acf test-acf )
   <>  if  false exit  then            ( anf )

   \ Check for bogus (non-printable) characters in the name.
   dup name>string                     ( anf adr len )
   true -rot  bounds ?do               ( anf true )
      i c@  bl  h# 7f  between  0=  if  0= leave  then
   loop                                ( anf good-name? )
;
HERE 20 ALLOT
  value fake-name-buf

: fake-name  ( xt -- anf )
   base @ >r hex
   <#  0 hold ascii ) hold  u#s  ascii ( hold  u#>   ( adr len )
   fake-name-buf $save       ( adr len )
   tuck + 1- tuck            ( anf len adr+len )
   swap 1- h# 80 or swap c!  ( adr )
   r> base !
;

\ Returns the name field address, or if the word is headerless, the
\ address of a numeric string representing the xt in parentheses.
: >name  ( xt -- anf )
   dup >name?  if  nip  else  drop fake-name  then
;

: >flags   ( acf -- aff )  >name n>flags  ;
: l>beginning  ( alf -- adr )  l>name name>string drop  ;
: >threads  ( acf -- ath )
\ @ \  >body-T >user
  ;

: mlower  (s adr len -- )  bounds  ?do i dup c@
 dup [char] A [char] Z between  if bl or then swap c!  loop  ;

: $make-header  ( adr len voc-acf -- )
\  F7_ED
   -rot                        ( voc-acf adr,len )
   2dup mlower
   dup 1+ /link +              ( voc-acf adr,len hdr-len )
   here
 +                       ( voc-acf adr,len  addr' )
   dup
 acf-aligned
 swap
 - 
 allot ( voc-acf adr,len )
   tuck here over 1+    allot     ( voc-acf len adr,len anf )
   place-cstr                  ( voc-acf len anf )
   over + c!                   ( voc-acf )
   here 1- LAST-T !              ( voc-acf )
   >threads                    ( threads-adr )
   /link allot here            ( threads-adr acf )

   swap
 2dup
 @             ( acf threads-adr acf succ-acf )
   swap
 >link
 !
 !      (  )

   LAST-T @ c@  h# 80 or  LAST-T @ c!
;

\EOF
: >first  ( voc-acf -- first-alf )  >threads  ;

: $find-word  ( adr len voc-acf -- adr len   false | xt +-1 )
   >first  $find-next  find-fixup
;

headerless
: >ptr  ( alf voc-acf -- ptr )
   over  if  drop  else  nip >threads  then
;
: next-word  ( alf voc-acf -- false  |  alf' true )
   >ptr another-link?  if  >link  true  else  false  then
;
: insert-word  ( new-alf old-alf voc-ptr -- )
   >ptr              ( new-alf alf )
   swap link> swap   ( new-acf alf )
   2dup link@        ( new-acf alf  new-acf next-acf )
   swap >link link! link!
;

headers
: remove-word  ( new-alf voc-acf -- )
   >threads                                   ( new-alf prev-link )
   swap link> swap link>                      ( new-acf prev-link )
   begin                                      ( acf prev-link )
      >link
      2dup link@ =  if                        ( acf prev-link )
         swap >link link@ swap link!  exit    (  )
      then                                    ( acf prev-link )
      another-link? 0=                  ( acf [ next-link ] end? )
   until
   drop
;

\ Makes a sealed vocabulary with the top-of-voc pointer in user area
\ parameter field of vocabularies contains:
\ user-#-of-voc-pointer ,  voc-link ,

\ For navigating inside a vocabulary's data structure.
\ A vocabulary's parameter field contains:
\   user#  link
\ The threads are stored in the user area.

: voc>      (s voc-link-adr -- acf )
\   /user# -  body>
;

: >voc-link ( voc-acf -- voc-link-adr )  >body /user# +  ;

: (wordlist)  ( -- )
   create-cf
   /link user#,  !null-link   ( )
   voc-link,
   0 ,				\ Space for additional information
   does> body> context token!
; resolves <vocabulary>

headers
: \tagvoc ; immediate
: \nottagvoc [compile] \ ; immediate

\ From voccom.fth

\ Common routines for vocabularies, independent of name field
\ implementation details

headers
: wordlist  ( -- wid )  (wordlist) lastacf  ;
: vocabulary  ( "name" -- )  header (wordlist)  ;

defer $find-next
' ($find-next) is $find-next

\  : insert-after  ( new-node old-node -- )
\     dup link@        ( new-node old-node next-node )
\     2 pick link!     ( new-node old-node )
\     link!
\  ;
tuser hidden-voc   origin-t is hidden-voc

: not-hidden  ( -- )  hidden-voc !null-token  ;

: hide   (s -- )
   current-voc hidden-voc token!
   LAST-T @ n>link current-voc remove-word
;

: reveal  (s -- )
   hidden-voc get-token?  if             ( xt )
      LAST-T @ n>link 0  rot  insert-word  ( )
      not-hidden
   then
;

#threads-t constant #threads

auser voc-link     \ points to newest vocabulary

headerless

: voc-link,  (s -- )  \ links this vocabulary to the chain
   lastacf  voc-link link@  link,   voc-link link!
;

headers
: find-voc ( xt - voc-node|false )
   >r voc-link  			( voc-node )
   begin
      another-link? false = if          ( - | voc-node )
         false true			( false loop-flag )
      else				( voc-node )
	 dup voc> 			( voc-node voc-xt )
	 swap >voc-link swap            ( voc-node' voc-xt )
         r@ execute	     		( voc-node' flag )
      then				( voc-node'|false loop-flag )
   until				( voc-node' )
   r> drop				( voc-node|false )
;

headerless
hex


: immediate  (s -- )  LAST-T @  n>flags  dup c@  40 or  swap c!  ;
: immediate?  (s xt -- flag )  >flags c@  40 and  0<>  ;
: flagalias  (s -- )  LAST-T @  n>flags  dup c@  20 or  swap c!  ;
: .last  (s -- )  LAST-T @ .id  ;

: current-voc  ( -- voc-xt )  current token@  ;

0 value canonical-word
headerless
: init  ( -- )
   init
   d# 20 alloc-mem  is fake-name-buf
   d# 32 alloc-mem  is canonical-word
;
headers

: $canonical  ( adr len -- adr' len' )
   caps @  if  d# 31 min  canonical-word $save  2dup lower  then
;
: $create-word  ( adr len voc-xt -- )
   >r $canonical r>
   warning @  if
      3dup  $find-word  if   ( adr len voc-xt  xt )
         drop
	 >r 2dup type r> ."  isn't unique " cr
      else                   ( adr len voc-xt  adr len )
         2drop
      then
   then                      ( adr len voc-xt )
   $make-header
;

: ($header)  (s adr len -- )  current-voc $create-word  ;

' ($header) is $header

: (search-wordlist)  ( adr len vocabulary -- false | xt +-1 )
   $find-word  dup  0=  if  nip nip  then
;
: search-wordlist  ( adr len vocabulary -- false | xt +-1 )
   >r $canonical r> (search-wordlist)
;
: $vfind  ( adr len vocabulary -- adr len false | xt +-1 )
   >r $canonical r> $find-word
;

: find-fixup  ( adr len alf true  |  adr len false -- xt +-1  |  adr len 0 )
   dup  if                                        ( adr len alf true )
      drop nip nip                                ( alf )
      dup link> swap l>name n>flags c@            ( xt flags )
      dup  h# 20 and  if  swap token@ swap  then  ( xt' flags )  \ alias?
      h# 40 and  if  1  else  -1  then                           \ immediate?
   then
;

headerless
2 /n-t * ualloc-t user tbuf
headers
: follow  ( voc-acf -- )  tbuf token!  0 tbuf na1+ !  ;

: another?  ( -- false  |  anf true )
   tbuf na1+ @  tbuf token@  next-word  ( 0 | alf true )
   if  dup tbuf na1+ !  l>name  true  else  false  then
;

: another-word?  ( alf|0  voc-acf -- alf' voc-acf anf true  |  false )
   tuck next-word  if    ( voc-acf alf' )
      tuck l>name  true  ( alf' voc-acf anf true )
   else                  ( voc-acf )
      drop  false        ( false )
   then
;

\ Forget

headerless
: trim   (s alf voc-acf -- )
   >r 0                                       ( adr 0 )
   begin  r@ next-word   while                ( adr alf )
      2dup <=  if  dup r@ remove-word  then   ( adr alf )
   repeat                                     ( adr )
   r> 2drop
;

headers

auser fence        \ barrier for forgetting

: (forget)   (s adr -- )	\ reclaim dictionary space above "adr"

   dup fence a@ u< ( -15 ) abort" below fence"  ( adr )

   \ Forget any entire vocabularies defined after "adr"

   voc-link                          ( adr first-voc )
   begin                             ( adr voc )
      \ XXX this may not work with a mixed RAM/ROM system where
      \ RAM is at a lower address than ROM
      link@ 2dup  u<                 ( adr voc' more? )
   while                             ( adr voc )
      dup voc> current-voc =         ( adr voc error? )
      ( -15 ) abort" I can't forget the current vocabulary."
      \ Remove the voc from the search order
      dup voc> (except               ( adr voc )
      >voc-link                      ( adr voc-link )
   repeat                            ( adr voc )
   dup voc-link link!                ( adr voc )

   \ For all remaining vocabularies, unlink words defined after "adr"

   \ We assume that we haven't forgotten all the vocabularies;
   \ otherwise this will fail.  Forgetting all the vocabularies would
   \ crash the system anyway, so we don't worry about it.
   begin                             ( adr voc )
      2dup voc> trim                 ( adr voc )
      >voc-link                      ( adr voc-link-adr )
      another-link? 0=               ( adr voc' )
   until                             ( adr )
   l>beginning  here - allot     \ Reclaim dictionary space
;

: forget   (s -- )
   safe-parse-word   current-voc $vfind  $?missing  drop
   >link  (forget)
;

: marker  ( "name" -- )
   create  #user @ ,
   does> dup @  #user !  body> >link  (forget)
;
headerless
: init ( -- )  init  ['] ($find-next) is $find-next  ;
headers

\ From order.fth

\ Search order.  Maintains the list of vocabularies which are
\ searched while interpreting Forth code.

decimal
16 equ nvocs
nvocs constant #vocs	\ The # of vocabularies that can be in the search path

nvocs /token-t * ualloc-t user context   \ vocabulary searched first
tuser current      \ vocabulary which gets new definitions

#vocs /token * constant /context
: context-bounds  ( -- end start )  context /context bounds  ;

headerless
: shuffle-down  ( adr -- finished? )
   \ The loop goes from the next location after adr to the end of the
   \ context array.
   context-bounds drop  over /token +  ?do    ( adr )
       \ Look for a non-null entry, replace the current entry with that one,
       \ and replace that one with null
       i get-token?  if                       ( adr acf )
          over token!   i !null-token  leave  ( adr )
       then                                   ( adr )
   /token +loop
   drop
;
headers
: clear-context  ( -- )
   context-bounds  ?do  i !null-token  /token +loop
;
headerless
: compact-search-order  ( -- )
   context-bounds  ?do
      i get-token? 0=  if   i shuffle-down  else  drop  then
   /token +loop
;
headers
: (except  ( voc-acf -- )   \ Remove a vocabulary from the search order
   context-bounds  ?do
      dup  i token@  =  if  i  !null-token  then
   /token +loop
   drop compact-search-order
;

nuser prior        \ used for dictionary searches
: $find   (s adr len -- xt +-1 | adr len 0 )
   2dup 2>r
   $canonical        ( adr' len' )
   prior off         ( adr len )
   false             ( adr len found? )
   context-bounds  ?do
      drop
      i get-token?  if                    ( adr len voc )

         \ Don't search the vocabulary again if we just searched it.
         dup prior @ over prior !  =  if  ( adr len voc )
            drop false                    ( adr len false )
         else                             ( adr len voc )
	    $find-word  dup ?leave        ( adr len false )
         then                             ( adr len false )

      else                                ( adr len voc )
         false                            ( adr len false )
      then                                ( adr len false )
   /token +loop                           ( adr len false  |  xt +-1 )
   ?dup  if
      2r> 2drop
   else
      2drop  2r> false
   then
;
: find  ( pstr -- pstr false  |  xt +-1 )
   dup >r count $find  dup  0=  if  nip nip  r> swap  else  r> drop  then
;

\ The also/only vocabulary search order scheme

decimal
: >voc  ( n -- adr )  /token *  context +  ;

vocabulary root   root definitions-t

: also  (s -- )  context  1 >voc   #vocs 2- /token *  cmove>  ;

: (min-search)  root also  ;
defer minimum-search-order  ' (min-search) is minimum-search-order
: forth-wordlist  ( -- wid )  ['] forth  ;
: get-current  ( -- )  current token@  ;
: set-current  ( -- )  current token!  ;

: get-order  ( -- vocn .. voc1 n )
   0  0  #vocs 1-  do
      i >voc token@ non-null?  if  swap 1+  then
   -1 +loop
;
: set-order  ( vocn .. voc1 n -- )
   dup #vocs >  abort" Too many vocabularies in requested search order"
   clear-context
   0  ?do  i >voc token!  loop
;

: only  (s -- )
   clear-context
\   ['] root  #vocs 1- >voc  token!
   minimum-search-order
;

: except  \ vocabulary-name  ( -- )
   ' (except
;
: seal  (s -- )  ['] root (except  ;
: previous   (s -- )
   1 >voc  context  #vocs 2- /token *  cmove
   #vocs 2- >voc  !null-token
;

: definitions  ( -- )  context token@ set-current  ;

: order   (s -- )
   ." context: "
   get-order  0  ?do  .name  loop
   4 spaces  ." current: "  get-current .name
;
: vocs   (s -- )
   voc-link  begin  another-link?  while  ( link )
      #out @ 64 >  if  cr  then
      dup  voc>  .name
      >voc-link
   repeat
;

vocabulary forth   forth definitions-t

\ only forth also definitions
\ : (cold-hook   ( -- )   (cold-hook  only forth also definitions  ;
\ headers

headerless
: init  ( -- )  init  only forth also definitions  ;
headers

\ From is.fth

\ Prefix word for setting the value of variables, constants, user variables,
\ values, and deferred words.  State-smart so it is used the same way whether
\ interpreting or compiling.  Don't use IS in place of ! where speed matters,
\ because IS is much slower than ! .
\
\ Examples:
\
\ 3 constant foo
\ 4 is foo
\
\ defer money
\ ' dollars is money
\ : german ['] marks is money ;

\ Is is a "generic store".
\ Is figures out where the data for a word is stored, and replaces that
\ data.  In this implementation, it is not particularly fast.

\ This is loaded before "order.fth"
\ only forth also hidden also definitions

variable isvar
0 value isval

headerless

[ifdef] run-time
: is-error  ( data acf -- )  true ( -32 ) abort" inappropriate use of `is'"  ;
[else]
: is-error  ( data acf -- )  ." Can't use is with " .name cr ( -32 ) abort  ;
[then]

headers

defer to-hook
' is-error is to-hook

headerless

: >bu  ( acf -- data-adr )  >body >user  ;

create word-types
   ' key    token,-t	\ defer
   ' #user  token,-t	\ user variable
   ' isval  token,-t	\ value
   ' bl     token,-t	\ constant
   ' isvar  token,-t	\ variable
   origin   token,-t	\ END   \ origin should be null

create data-locs
   ' >bu    token,-t	\ defer
   ' >bu    token,-t	\ user variable
   ' >bu    token,-t	\ value
   ' >body  token,-t	\ constant
   ' >body  token,-t	\ variable

create !ops
   ' token! token,-t	\ defer
   ' !      token,-t	\ user variable
   ' !      token,-t	\ value
   ' !      token,-t	\ constant
   ' !      token,-t	\ variable

: associate  ( acf -- true  |  index false )
   word-type  ( n )
   word-types  begin              ( n adr )
      2dup get-token?             ( n adr n  false | acf true )
   while                          ( n adr n acf )
      word-type  = if             ( n adr )
         word-types -  /token /   ( n index )
	 nip false  exit          ( index false )
      then                        ( n adr )
      ta1+                        ( n adr' )
   repeat                         ( n adr n )
   3drop true                     ( true )
;

: +execute  ( index table -- )
   swap ta+ token@ execute        ( )
;

: kerntype?  ( acf -- flag )
   associate  if  false  else  drop true  then  ( flag )
;

headers
: behavior  ( defer-acf -- acf2 )  >bu token@  ;

: (is  ( data acf -- )
   dup  associate  if  is-error  then   ( data acf index )
   tuck data-locs +execute              ( data index data-adr )
   swap !ops +execute                   ( )
;

: >data  ( acf -- data-adr )
   dup associate  if        ( acf )
      >body                 ( data-adr )
   else                     ( acf index )
      data-locs +execute    ( data-adr )
   then                     ( data-adr )
;

\ (is) is a run-time word that is compiled into definitions
: (is)  ( acf -- )  ip> dup ta1+ >ip  token@ (is  ;

[ifndef] run-time

: do-is  ( data acf -- )
   dup kerntype?  if     ( [data] acf )
      state @  if   compile (is)  token,  else  (is   then
   else                    ( [data] acf )
      to-hook
   then
;
\ is is the word that is actually used by applications
: is  \ name  ( data -- )
   ' do-is
; immediate
\ only forth also definitions

[then]

\ From filecomm.fth

decimal

\ buffered i/o  constants
-1 constant eof

nuser delimiter  \ delimiter actually found at end of word
nuser file

\ field creates words which return their address within the structure
\ pointed-to by the contents of file

\ The file descriptor structure describes an open file.
\ There is a pool of several of these structures.  When a file is opened,
\ a structure is allocated and initialized.  While performing an io
\ operation, the user variable "file" contains a pointer to the file
\ on which the operation is being performed.

: bfbase    file @  0 na+  ;   \ starting address of the buffer for this file
: bflimit   file @  1 na+  ;   \ ending address of the buffer for this file
headerless
: bftop     file @  2 na+  ;   \ address past LAST-T valid character in the buffer
: bfend     file @  3 na+  ;   \ address past LAST-T place to write in the buffer
: bfcurrent file @  4 na+  ;   \ address of the current character in the buffer
: bfdirty   file @  5 na+  ;   \ contains true if the buffer has been modified
: fmode     file @  6 na+  ;   \ not-open, read, write, or modify
: fstart    file @  7 na+  ;   \ Position in file of the first byte in buffer
: fid       file @  9 na+  ;   \ File handle for underlying operating system
: seekop    file @ 10 na+  ;   \ Points to system routine to set the file position
: readop    file @ 11 na+  ;   \ Points to system routine to read blocks
: writeop   file @ 12 na+  ;   \ Points to system routine to write blocks
: closeop   file @ 13 na+  ;   \ Points to system routine to close file
: alignop   file @ 14 na+  ;   \ Points to system routine to align to block boundary
: sizeop    file @ 15 na+  ;   \ Points to system routine to return the file size
: (file-line)    file @ 16 na+  ;   \ Number of line delims that read-line has consumed
: line-delimiter file @ 17 na+  ;   \ The LAST-T delimiter at the end of each line
: pre-delimiter  file @ 18 na+  ;   \ The first line delimiter (if any)
: (file-name)    file @ 19 na+  ;   \ The name of the file
/n round-up
headers
20 /n-t * d# 68 +  constant /fd

: set-name  ( adr len -- )
   \ If the name is too long, cut off initial characters (because the
   \ latter ones are more likely to be interesting), and replace the
   \ first character with "?".
   dup d# 64 -  0 max  dup >r  /string  (file-name) place
   r>  if  ascii ? (file-name) 1+ c!  then
;
: file-name  ( fd -- adr len )
   file @ >r  file !  (file-name) count  r> file !
;
: file-line  ( fd -- n )  file @ >r  file !  (file-line) @  r> file !  ;
: setupfd  ( fid fmode sizeop alignop closeop seekop writeop readop -- )
   readop !  writeop !  seekop !  closeop !  alignop !  sizeop !
   fmode !  fid !  0 (file-line) !  0 0 set-name
;

headerless
\ values for mode field
-1  constant not-open
headers
 0  constant read
 1  constant write
 2  constant modify
headerless
modify constant read-write  ( for old programs )

\ Stub routines for readop and writeop
headers
\ These return 0 for the number of bytes actually transferred.
: nullwrite  ( adr count fd -- 0 )  3drop 0  ;
: fakewrite  ( adr count fd -- count )  drop nip  ;
: nullalign  ( d.position fd -- d.position' )  drop  ;
: nullread  ( adr count fd -- 0 )  3drop 0  ;
: nullseek  ( d.byte# fd -- )  3drop  ;
headerless
\ This one pretends to have transferred the requested number of bytes
: fakeread  ( adr count fd -- count )  drop nip  ;

headers
\ Initializes the current descriptor to use the buffer "bufstart,buflen"
: initbuf  ( bufstart buflen -- )
   0 0 fstart 2!   over + bflimit !  ( bufstart )
   dup bfbase ! dup bfcurrent ! dup bfend !  bftop !
   bfdirty off
;

\ "unallocate" a file descriptor
: release-fd  ( fd -- )  file @ >r  file !  not-open fmode !  r> file !  ;
headerless

\ An implementation factor which returns true if the file descriptor fd
\ is not currently in use
: fdavail?  ( fd -- f )  file @ >r  file !  fmode @ not-open =  r> file !  ;

\ These are the words that a program uses to read and write to/from a file.

\ An implementation factor which
\ ensures that the bftop is >= the bfcurrent variable.  bfcurrent
\ can temporarily advance beyond bftop while a file is being extended.

: sync  ( -- )  \ if current > top, move up top
   bftop @ bfcurrent @ u<   if    bfcurrent @  bftop !    then
;

\ If the current file's buffer is modified, write it out
\ Need to better handle the case where the file can't be extended,
\ for instance if the file is a memory array
: ?flushbuf  ( -- )
   bfdirty @   if
      sync
      fstart 2@  fid @  seekop @ execute  ( )
      bftop @ bfbase @  -                 ( #bytes-to-write)
      bfbase @  over                      ( #bytes adr #bytes )
      fid @ writeop @ execute             ( #bytes-to-write #bytes-written )
      u>  ( -37 ) abort" Flushbuf error"
      bfdirty off
      bfbase @   dup bftop !  bfcurrent !
   then
;

\ An implementation factor which
\ fills the buffer with a block from the current file.  The block will
\ be chosen so that the file address "d.byte#" is somewhere within that
\ block.

: fillbuf  ( d.byte# -- )
   fid @ alignop @ execute  ( d.byte# ) \ Aligns position to a buffer boundary
   2dup fstart 2!           ( d.byte# )
   fid @ seekop @ execute               ( )
   bfbase @   bflimit @ over -          ( adr #bytes-to-read )
   fid @ readop @ execute               ( #bytes-read )
   bfbase @ +   bftop !
   bflimit @  bfend !
;

\ An implementation factor which
\ returns the address within the buffer corresponding to the
\ selected position "d.byte#" within the current file.

: >bufaddr  ( d.byte# -- bufaddr )  fstart 2@ d- drop  bfbase @ +  ;

\ An implementation factor which
\ advances to the next block in the file.  This is used when accesses
\ to the file are sequential (the most common case).

\ Assumes the byte is not already in the buffer!
: shortseek  ( bufaddr -- )
   ?flushbuf                             ( bufaddr )
   bfbase @ - s>d  fstart 2@  d+         ( d.byte# )
   2dup fillbuf                          ( d.byte# )
   >bufaddr  bftop @  umin  bfcurrent !
;

\ Buffer boundaries are transparant
\ end-of-file conditions work correctly
\ The actual delimiter encountered in stored in delimiter.

headers
\ input-file contains the file descriptor which defines the input stream.
nuser input-file

headerless

\ ?fillbuf is called by the string scanning routines after skipbl, scanbl,
\ skipto, or scanto has returned.  ?fillbuf determines whether or not
\ the end of a buffer has been reached.  If so, the buffer is refilled and
\ end? is set to false so that the skip/scan routine will be called again,
\ (unless the end of the file is reached).

: ?fillbuf  ( endaddr [ adr ]  delimiter -- endaddr' addr' end? )
    dup delimiter !  eof =  if ( endaddr )
       shortseek
       bftop @  bfcurrent @    ( endaddr'  addr' )
       2dup u<=                ( endaddr'  addr' end-of-file? )
    else                       ( endaddr addr )
       true            \ True so we'll exit the loop
    then
;

headers
\ Closes the file.
: fclose  ( fd -- )
   file @ >r  file !
   file @  fdavail?  0=  if
      ?flushbuf  fid @ closeop @ execute
      file @  release-fd
   then
   r> file !
;
: close-file  ( fd -- ior )  fclose 0  ;

\ A place to put the LAST-T word returned by blword
0 value 'word

headerless
\ File descriptor allocation


32         constant #fds
#fds /fd * constant /fds

nuser fds

headerless
\ Initialize pool of file descriptors
: init  ( -- )
   init
   /stringbuf alloc-mem is 'word
   /fds alloc-mem  ( base-address )  fds !
   fds @  /fds   bounds   do   i release-fd   /fd +loop
;

headers
\ Allocates a file descriptor if possible
: (get-fd  ( -- fd | 0 )
   0
   fds @  /fds  bounds  ?do               ( 0 )
      i fdavail?  if  drop i leave  then  ( 0 )
   /fd +loop                              ( fd | 0 )
;

: string-sizeop  ( fhandle -- d.length )  drop  bflimit @  bfbase @ -  0  ;
: hold$  ( adr len -- )
   dup  if
      1- bounds swap  do  i c@ hold  -1 +loop
   else
      2drop
   then
;

: init-delims   ( -- )
   \ initialize the delimiters to the default values for the
   \ underlying operating system, in case the file is initially empty.
   newline-string  case
      1 of  c@         0        endof
      2 of  dup 1+ c@  swap c@  endof
      ( default )  linefeed carret rot
   endcase   pre-delimiter c!  line-delimiter c!
;

: open-buffer  ( adr len -- fd ior )
   2 ?enough
   \ XXX we need a "throw" code for "no more fds"
   (get-fd  ?dup 0=  if  0 true exit  then	( adr len fd )
   file !
   2dup						( adr len )
   initbuf  init-delims				( adr len )
   bflimit @  dup bfend !  bftop !		( adr len )

   0  modify
   ['] string-sizeop  ['] drop  ['] drop
   ['] nullseek  ['] fakewrite  ['] nullread   setupfd  ( adr len )
   $set-line-delimiter

   \ Set the file name field to "<buffer@ADDRESS>"
   base @ >r hex
   bfbase @ <#  ascii > hold  u#s " <buffer@" hold$ u#> set-name
   r> base !

   file @  false
;

headerless
\ A version that knows about multi-segment dictionaries can be installed
\ if such dictionaries exist.
: (in-dictionary?  ( adr -- )  origin here between  ;
headers
defer in-dictionary? ' (in-dictionary? is in-dictionary?

defer .error#
: (.error#)  ( error# -- )
   dup d# -38  =  if
      ." The file '"  opened-filename 2@ type  ." ' cannot be opened."
   else  ." Error " .  then
;

: .abort  ( -- )
   show-error
   drop abort-message type
;

' (.error#) is .error#

defer .error
: (.error)  ( error# -- )
   dup  -13  =  if
      .abort  ."  ?"  cr
   else  dup  -2 =  if
      .abort  cr
   else  dup -1 =  if
      drop
   else
      show-error
      dup in-dictionary?  if  count type  else  .error#  then cr
   then
   then
   then
;
' (.error) is .error

: guarded  ( acf -- )  catch  ?dup  if  .error  then  ;

\ From cold.fth

\ Some hooks for multitasking
\ Main task points to the initial task.  This usage is currently not ROM-able
\ since the user area address has to be later stored in the parameter field
\ of main-task.  It could be made ROM-able by allocating the user area
\ at a fixed location and storing that address in main-task at compile time.

defer pause  \ for multitasking
' noop  is pause

defer init-io    ( -- )
defer do-init    ( -- )
defer cold-hook  ( -- )
defer init-environment  ( -- )

[ifndef] run-time
: (cold-hook  (s -- )
   [compile] [
;

' (cold-hook  is cold-hook
[then]

defer title  ' noop is title

: cold  (s -- )
   decimal
   init-io			  \ Memory allocator and character I/O
   do-init			  \ Kernel
   ['] init-environment guarded	  \ Environmental dependencies
   ['] cold-hook        guarded	  \ Last-minute stuff

   process-command-line

   \ interactive? won't work because the fd hasn't been initialized yet
   (interactive?  if  title  then

   quit
;

[ifndef] run-time
headerless
: single  (s -- )  \ Turns off multitasking
   ['] noop ['] pause (is
;
headers
: warm   (s -- )  single  sp0 @ sp!  quit  ;
[then]

\ From disk.fth

\ High level interface to disk files.

headerless

\ If the underlying operating system requires that files be accessed
\ in fixed-length records, then /fbuf must be a multiple of that length.
\ Even if the system allows arbitrary length file accesses, there is probably
\ a length that is particularly efficient, and /fbuf should be a multiple
\ of that length for best performance.  1K works well for many systems.

td 1024 constant /fbuf

headerless

\ An implementation factor which gets a file descriptor and attaches a
\ file buffer to it
headerless
: get-fd  ( -- )
   (get-fd  dup 0= ( ?? ) abort" all fds used "  ( fd )
   file !
   /fbuf alloc-mem  /fbuf initbuf     ( )
;
headers
\ Amount of space needed:
\   #fds * /fd     for automatically allocated file descriptors
\   1 * /fd        for "accept" descriptor
\   tib            for "accept" buffer
\
\ #fds = 8, so total of 9 * /fd  = 9 * 56 = 486 for fds
\ 8 * 1024 +  3 * 128  +  tib
\ Total is ~9K

\ Returns the current position within the current file

: dftell  ( fd -- d.byte# )
   file @ >r  file !  fstart 2@  bfcurrent @ bfbase @ -  0 d+  r> file !
;
: ftell  ( fd -- byte# )  dftell drop  ;

\ Updates the disk copy of the file to match the buffer
headerless
: fflush  ( fd -- )  file @ >r  file !  ?flushbuf  r> file !  ;
headers
\ Starting here, some stuff doesn't have to be in the kernel

\ Sets the position within the current file to "d.byte#".
: dfseek  ( d.byte# fd -- )
   file @ >r  file !
   sync

   \ See if the desired byte is in the buffer
   \ The byte is in the buffer iff offset.high is 0 and offset.low
   \ is less than the number of bytes in the buffer
   2dup fstart 2@ d-                   ( d.byte# offset.low offset.high )
   over bfend @ bfbase @ -  u>= or  if ( d.byte# offset )
      \ Not in buffer
      \ Flush the buffer and get the one containing the desired byte.
      drop ?flushbuf 2dup fillbuf      ( d.byte# )
      >bufaddr                         ( bufaddr )
   else
      \ The desired byte is already in the buffer.
      nip nip  bfbase @ +           ( bufaddr )
   then

   \ Seeking past end of file actually goes to the end of the file
   bftop @  umin   bfcurrent !
   r> file !
;
: fseek  ( byte# fd -- )  0 swap dfseek  ;

\ Returns true if the current file has reached the end.
\ XXX This may only be valid after fseek or shortseek
headerless
: (feof?  ( -- f )   bfcurrent @  bftop @  u>=  ;

headers
\ Gets the next byte from the current file
: fgetc  ( fd -- byte )
   file @ >r  file !   bfcurrent @  bftop @  u<
   if   \ desired character is in the buffer
      bfcurrent @c@++
   else \ end of buffer has been reached
      bfcurrent @ shortseek
      (feof?  if  eof  else  bfcurrent @c@++  then
   then
   r> file !
;

\ Stores a byte into the current file at the next position
: fputc  ( byte fd -- )
   file @ >r  file !
   bfcurrent @   bfend @ u>=     ( byte flag )  \ Is the buffer full?
   if  bfcurrent @ shortseek  then     ( byte ) \ If so advance to next buffer
   bfcurrent @c!++  bfdirty on
   r> file !
;

\ An implementation factor
\ Copyin copies bytes starting at current into the file buffer at
\ bfcurrent.  The number of bytes copied is either all the bytes from
\ current to end, if the buffer has enough room, or all the bytes the
\ buffer will hold, if not.
\ newcurrent is left pointing to the first byte not copied.
headerless
: copyin  ( end current -- end newcurrent )
   2dup -                      ( end current remaining )
   bfend @  bfcurrent @  -     ( end current remaining bfremaining )
   min                         ( end current #bytes-to-copy )
   dup if  bfdirty on  then    ( end current #bytes-to-copy )
   2dup  bfcurrent @ swap      ( end current #bytes  current bfcurrent #bytes)
   move                        ( end current #bytes )
   dup bfcurrent +!            ( end current #bytes )
   +                           ( end newcurrent)
;

\ Copyout copies bytes from the file buffer into memory starting at current.
\ The number of bytes copied is either enough to fill memory up to end,
\ if the buffer has enough characters, or all the bytes the
\ buffer has left, if not.
\ newcurrent is left pointing to the first byte not filled.
headerless
: copyout  ( end current -- end newcurrent )
   2dup -                      ( end current remaining )
   bftop @  bfcurrent @  -     ( end current remaining bfrem )
   min                         ( end current #bytes-to-copy)
   2dup bfcurrent @ rot rot    ( end current #bytes  current bfcurrent #bytes)
   move                        ( end current #bytes)
   dup  bfcurrent +!           ( end current #bytes)
   +                           ( end newcurrent )
;
headers
\ Writes count bytes from memory starting at "adr" to the current file
: fputs  ( adr count fd -- )
   file @ >r  file !
   over + swap  ( endaddr startaddr )
   begin  copyin  2dup u>
   while
      \ Here there should be some code to see if there are enough remaining
      \ bytes in the request to justify bypassing the file buffer and writing
      \ directly from the user's buffer.  'Enough' = more than one file buffer
      sync  bfcurrent @ shortseek ( endaddr curraddr )
   repeat
   2drop
   r> file !
;

\ Reads up to count characters from the file into memory starting
\ at "adr"

: fgets  ( adr count fd -- #read )
   file @ >r  file !
   sync
   over + over  ( startaddr endaddr startaddr )
   begin  copyout  2dup u>
   while
      \ Here there should be some code to see if there are enough remaining
      \ bytes in the request to justify bypassing the file buffer and reading
      \ directly to the user's buffer.  'Enough' = more than one file buffer
      bfcurrent @ shortseek ( startaddr endaddr curraddr )
      (feof?  if  nip swap -  r> file !  exit then
   repeat
   nip swap -
   r> file !
;

\ Returns the current length of the file
: dfsize  ( fd -- d.size )
   file @ >r  file !
   sync
   fstart 2@  bftop @  bfbase @  -  0 d+  ( buffered-position )
   fid @  sizeop @  execute               ( buffered-position file-size )
   dmax
   r> file !
;
: fsize  ( fd -- size )  dfsize drop  ;


\ End of stuff that doesn't have to be in the kernel

defer do-fopen

\ Prepares a file for later access, returning "fd" which is subsequently
\ used to refer to the file.

: fopen  ( name mode -- fd )
   2 ?enough
   get-fd   ( name mode )  over >r  ( name mode )
   dup fmode !          \ Make descriptor busy now, in case of re-entry
   do-fopen  if
      setupfd  file @  r> count set-name
   else
      not-open fmode !  0  r> drop
   then
;

headers

\ Closes all the open files and reclaims their file descriptors.
\ Use this if you see an "all fds used" message.

: close-files ( -- )  fds @  /fds  bounds   do   i fclose   /fd +loop  ;

: create-file  ( name$ mode -- fileid ior )  8 or  open-file  ;

: make  ( name-pstr -- flag )	\ Creates an empty file
   count  r/w  create-file  if  drop false  else  close-file drop true  then
;

\ From readline.fth

headers
0 constant r/o
1 constant w/o
2 constant r/w
4 constant bin
8 constant create-flag

headerless
2 /n-t * ualloc-t user opened-filename
headers

: open-file  ( adr len mode -- fd ior )
   file @ >r		\ Guard against re-entrancy

   >r 2dup opened-filename 2! cstrbuf pack r@ fopen   ( fd )  ( r: mode )

   \ Bail out now if the open failed
   dup  0=  if  d# -38  r> drop  r> file !  exit  then

   \ First initialize the delimiters to the default values for the
   \ underlying operating system, in case the file is initially empty.
   init-delims

   \ If the mode is neither "w/o" nor "binary", and the file isn't
   \ being newly created, establish the line delimiter(s) by looking
   \ for the first carriage return or line feed

   dup  r@ bin create-flag or  and 0=  and  r> w/o <> and  if
      dup set-line-delimiter
   then                                           ( fd )
   0                                              ( fd ior )
   r> file !
;
: close-file  ( fd -- ior )
   ?dup  0=  if  0  exit  then
   dup -1 =  if  drop 0  exit  then
   ['] fclose catch  ?dup  if  nip  else  0  then
;

: left-parse-string  ( adr len delim -- tail$ head$ )
   split-string  dup if  1 /string  then  2swap
;

headerless
: remaining$  ( -- adr len )  bfcurrent @  bftop @ over -  ;

: $set-line-delimiter  ( adr len -- )
   carret split-string  dup  if           ( head-adr,len tail-adr,len )
      carret line-delimiter c!            ( head-adr,len tail-adr,len )
      1 >  if                             ( head-adr,len tail-adr )
         dup 1+ c@ linefeed  =  if        ( head-adr,len tail-adr )
            carret pre-delimiter c!       ( head-adr,len tail-adr )
            linefeed line-delimiter c!    ( head-adr,len tail-adr )
         then                             ( head-adr,len tail-adr )
      then                                ( head-adr,len tail-adr )
   else                                   ( adr,len tail-adr,0 )
      2drop  linefeed split-string  if    ( head-adr,len tail-adr )
         0 pre-delimiter c!               ( head-adr,len tail-adr )
         linefeed line-delimiter c!       ( head-adr,len tail-adr )
      then                                ( head-adr,len tail-adr )
   then                                   ( head-adr,len tail-adr )
   3drop                                  ( )
;
: set-line-delimiter  ( fd -- )
   file @ >r  file !  0 0 fillbuf  remaining$  $set-line-delimiter  r> file !
;
: -pre-delimiter  ( adr len -- adr' len' )
   pre-delimiter c@  if
      dup  if
         2dup + 1- c@  pre-delimiter c@  =  if
            1-
         then
      then
   then
;

: parse-line-piece  ( adr len #so-far -- actual retry? )
   >r  2>r  ( r: #so-far adr len )

   remaining$                          ( fbuf$ )
   line-delimiter c@ split-string      ( head$ tail$ )  ( r: # adr len )

   2swap -pre-delimiter                ( tail$ head$')  ( r: # adr len )

   dup r@  u>=  if                     ( tail$ head$ )  ( r: # adr len )
      \ The parsed line doesn't fit into the buffer, so we consume
      \ from the file buffer only the portion that we copy into the
      \ buffer.
      over r@ +  bfcurrent !           ( tail$ head$ )
      drop nip nip                     ( head-adr )  ( r: # adr len )
      2r> dup >r  move                 ( )           ( r: # len )
      2r> + false                      ( actual don't-retry )
      exit
   then                                ( tail$ head$ )  ( r: # adr len )

   \ The parsed line fits into the buffer, so we copy it all in
   tuck  2r> drop  swap  move          ( tail$ head-len )  ( r: # )
   r> +  -rot                          ( actual tail$ )

   \ Consume the parsed line from the file buffer, including the
   \ delimiter if one was found (as indicated by nonzero tail-len)
   tuck  if  1+  then  bfcurrent !     ( actual tail-len )

   \ If a delimiter was found, increment the line number the next time.
   dup if  1 (file-line) +!  then

   \ If a delimiter was found, we need not retry.
   0=                                  ( actual retry? )
;

headers
: read-line  ( adr len fd -- actual not-eof? error? )
   file @ >r  file !
   0
   begin  >r 2dup r>  parse-line-piece  while   ( adr len actual )

      \ The end of the file buffer was reached without filling the
      \ argument buffer, so we refill the file buffer and try again.

      bftop @  ['] shortseek catch  ?dup  if  ( adr len actual x error-code )
         \ A file read error (more serious than end-of-file) occurred
         drop 2swap 2drop  false swap         ( actual false ior )
	 r> file !  exit
      then                                    ( adr len actual )
      remaining$  nip 0=  if                  ( adr len actual )

         \ Shortseek did not put any more characters into the file buffer,
         \ so we return the number of characters that were copied into the
	 \ argument buffer before shortseek was called and a flag.
         \ If no characters were copied into the argument buffer, the
         \ flag is false, indicating end-of-file

         nip  nip  dup 0<>  0                ( #copied not-eof? 0 )
         r> file !  exit
      then                                   ( adr len #copied )
      \ There are more characters in the file buffer, so we update
      \ adr len to reflect the portion of the buffer that has
      \ already been filled.
      dup >r /string r>                     ( adr' len' actual' )
   repeat                                   ( adr len actual )
   nip nip true 0                           ( actual true 0 )
   r> file !
;
\ Some more ANS Forth versions of file operations
: reposition-file  ( d.position fd -- ior )
   ['] dfseek catch  dup  if  nip nip nip  then
;
: file-size  ( fd -- d.size ior )
   ['] dfsize catch  dup if  0 0 rot  then
;
: read-file  ( adr len fd -- actual ior )
   ['] fgets catch  dup  if  >r 3drop 0 r>  then
;
: write-file  ( adr len fd -- actual ior )
   over >r  ['] fputs catch  dup  if   ( x x x ior )  ( r: len )
      r> drop  >r 3drop 0 r>           ( 0 ior )
   else                                ( ior )        ( r: len )
      r> swap                          ( len ior )
   then                                ( actual ior )
;
: flush-file  ( fd -- ior )  ['] fflush  catch  dup  if  nip  then  ;
: write-line  ( adr len fd -- ior )
   dup >r ['] fputs catch  ?dup  if  nip nip nip  r> drop exit  then  ( )
   pre-delimiter c@  if
      pre-delimiter c@  r@  ['] fputc catch  ?dup  if  ( x x ior )
         nip nip  r> drop exit
      then                                             ( )
   then
   line-delimiter c@  r>  ['] fputc catch  dup  if     ( x x ior )
      nip nip exit
   then                                                ( ior )
;
\ Missing: file-status, create-file, delete-file, resize-file, rename-file

\ From cstrings.fth

\ Conversion between Forth-style strings and C-style null-terminated strings.
\ cstrlen and cscount are defined in cmdline.fth

decimal

headerless
0 value cstrbuf		\ Initialized in
: init  ( -- )  init  102 alloc-mem is cstrbuf  ;

headers
\ Convert an unpacked string to a C string
: $cstr  ( adr len -- c-string-adr )
   \ If, as is usually the case, there is already a null byte at the end,
   \ we can avoid the copy.
   2dup +  c@  0=  if  drop exit  then
   >r   cstrbuf r@  cmove  0 cstrbuf r> + c!  cstrbuf
;

\ Convert a packed string to a C string
: cstr  ( forth-pstring -- c-string-adr )  count $cstr  ;

\ Find the length of a C string, not counting the null byte
: cstrlen  ( c-string -- length )
   dup  begin  dup c@  while  ca1+  repeat  swap -
;
\ Convert a null-terminated C string to an unpacked string
: cscount  ( cstr -- adr len )  dup cstrlen  ;

headers

\ From alias.fth

\ Alias makes a new word which behaves exactly like an existing
\ word.  This works whether the new word is encountered during
\ compilation or interpretation, and does the right thing even
\  if the old word is immediate.

decimal

: setalias  ( xt +-1 -- )
   0> if  immediate  then                ( acf )
   flagalias
   lastacf  here - allot   token,
;
: alias  \ new-name old-name  ( -- )
   create  hide  'i  reveal  setalias
;

\ From ansio.fth

headers
: allocate  ( size -- adr ior )  alloc-mem  dup 0=  ;

\ Assumes free-mem doesn't really need the size parameter; usually true
: free  ( adr -- ior )  0 free-mem 0  ;

headerless
nuser insane

headers
0 value exit-interact?

headerless
\ XXX check for EOF on keyboard stream
: more-input?  ( -- flag )  insane off  true  ;

headers
d# 1024 constant /tib

variable blk

headerless
defer ?block-valid  ( -- flag )  ' false is ?block-valid

headers
variable >in
variable #tib
nuser 'source-id
: source-id  ( -- fid )  'source-id @  ;

nuser 'source
nuser #source
: source-adr  ( -- adr )  'source @  ;
: source      ( -- adr len )  source-adr  #source @  ;
: set-source  ( adr len -- )  #source !  'source !  ;

: save-input  ( -- source-adr source-len source-id >in blk 5 )
   source  source-id  >in @  blk @  5
;
: restore-input  ( source-adr source-len source-id >in blk 5 -- flag )
   drop
   blk !  >in !  'source-id !  set-source
   false
;
: set-input  ( source-adr source-len source-id -- )
   0 0 5 restore-input drop
;
headerless
: skipwhite  ( adr1 len1 -- adr2 len2  )
   begin  dup 0>  while       ( adr len )
      over c@  bl >  if  exit  then
      1 /string
   repeat                     ( adr' 0 )
;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
: scantowhite  ( adr1 len1 -- adr1 adr2 adr3 )
   over swap                       ( adr1 adr1 len1 )
   begin  dup 0>  while            ( adr1 adr len )
      over c@  bl <=  if  drop dup 1+  exit  then
      1 /string                    ( adr1 adr' len' )
   repeat                          ( adr1 adr2 0 )
   drop dup                        ( adr1 adr2 adr2 )
;

: skipchar  ( adr1 len1 delim -- adr2 len2 )
   >r                         ( adr1 len1 )  ( r: delim )
   begin  dup 0>  while       ( adr len )
      over c@  r@ <>  if      ( adr len )
         r> drop exit         ( adr2 len2 )
      then                    ( adr len )
      1 /string               ( adr' len' )
   repeat                     ( adr' 0 )
   r> drop                    ( adr2 0 )
;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
: scantochar  ( adr1 len1 char -- adr1 adr2 adr3 )
   >r                              ( adr1 len1 )   ( r: delim )
   over swap                       ( adr1 adr1 len1 )
   begin  dup 0>  while            ( adr1 adr len )
      over c@  r@ =  if            ( adr1 adr len )
         r> 2drop dup 1+  exit     ( adr1 adr2 adr3 )
      then                         ( adr1 adr len )
      1 /string                    ( adr1 adr' len' )
   repeat                          ( adr1 adr2 0 )
   r> 2drop dup                    ( adr1 adr2 adr2 )
;
headers
: parse-word  ( -- adr len )
   source >in @ /string  over >r   ( adr1 len1 )  ( r: adr1 )
   skipwhite                       ( adr2 len2 )
   scantowhite                     ( adr2 adr3 adr4 )
   r> - >in +!                     ( adr2 adr3 ) ( r: )
   over -                          ( adr1 len )
;
: parse  ( delim -- adr len )
   source >in @ /string  over >r   ( delim adr1 len1 )  ( r: adr1 )
   rot scantochar                  ( adr1 adr2 adr3 )  ( r: adr1 )
   r> - >in +!                     ( adr1 adr2 ) ( r: )
   over -                          ( adr1 len )
;
: word  ( delim -- pstr )
   source >in @ /string  over >r   ( delim adr1 len1 )  ( r: adr1 )
   rot >r r@ skipchar              ( adr2 len2 )        ( r: adr1 delim )
   r> scantochar                   ( adr2 adr3 adr4 )   ( r: adr1 )
   r> - >in +!                     ( adr2 adr3 ) ( r: )
   over -                          ( adr1 len )
   dup d# 255 >  ( -18 ) abort" Parsed string overflow"
   'word pack                      ( pstr )
;

: refill  ( -- more? )
   blk @  if  1 blk +!  ?block-valid  exit  then

   source-id  -1 =  if  false exit  then
   source-adr					     ( adr )
   source-id  if                                     ( adr )
      /tib source-id read-line
      ( -37 ) abort" Read error in refill"  ( cnt more? )
      over /tib = ( -18 ) abort" line too long in input file"  ( cnt more? )
   else                                              ( adr )
      \ The ANS Forth standard does not mention the possibility
      \ that ACCEPT might not be able to deliver any more input,
      \ but in this implementation, the `keyboard' can be redirected
      \ to a file via the command line, so it is indeed possible for
      \ ACCEPT to have no more characters to deliver.  Furthermore,
      \ we also provide a "finished" flag that can be set to force an
      \ exit from the interpreter loop.
      /tib accept  insane off                        ( cnt )
      dup  if  true  else  more-input?  then         ( cnt more? )
   then                                              ( cnt more? )
   swap  #source !  0 >in !                          ( more? )
;

: (prompt)  ( -- )
   interactive?  if	\ Suppress prompt if input is redirected to a file
      ??cr status
      state @  if
         level @  ?dup if  1 .r  else  ."  "  then  ." ] "
      else
         (ok)
      then
      mark-output
   then
;

: (interact)  ( -- )
   tib /tib 0 set-input
   [compile] [
   begin
      depth 0<  if  ." Stack Underflow" cr  clear  then
      sp@  sp0 @  ps-size -  u<  if  ." Stack Overflow" cr  clear  then
      do-prompt
   refill  while
      ['] interpret catch  ??cr  ?dup if
         [compile] [  .error
	 \ ANS Forth sort of requires the following "clear", but it's a
	 \ real pain and doesn't affect programs, so we don't do it
\        clear
      then
   exit-interact? until then
   false is exit-interact?
;
: interact  ( -- )
   save-input  2>r 2>r 2>r
   (interact)
   2r> 2r> 2r> restore-input  throw
;
: (quit)  ( -- )
   \ XXX We really should clean up any open input files here...
   0 level !  ]
   rp0 @ rp!
   interact
   bye
;

: interpret-lines  ( -- )  begin  refill  while  interpret  repeat  ;

: (evaluate)  ( adr len -- )
   begin  dup  while         ( adr len )
      parse-line  2>r        ( head$ )    ( r: tail$ )
      -1 set-input           ( )          ( r: tail$ )
      interpret              ( )          ( r: tail$ )
      2r>                    ( adr len )
   repeat                    ( adr len )
   2drop
;

: evaluate  ( adr len -- )
   save-input  2>r 2>r 2>r   ( adr len )
   ['] (evaluate) catch  dup  if  nip nip  then   ( error# )
   2r> 2r> 2r> restore-input  throw               ( error# )
   throw
;

: include-file  ( fid -- )
   /tib 4 + allocate throw	( fid adr )
   save-input 2>r 2>r 2>r       ( fid adr )

   /tib rot set-input

   ['] interpret-lines catch    ( error# )
   source-id close-file drop    ( error# )

   source-adr free drop         ( error# )

   2r> 2r> 2r> restore-input  throw  ( error# )
   throw
;
defer $open-error        ' noop is $open-error
defer include-hook       ' noop is include-hook
defer include-exit-hook  ' noop is include-exit-hook

: include-buffer  ( adr len -- )
   open-buffer  ?dup  if  " <buffer>" $open-error  then  include-file
;

: $abort-include  ( error# filename$ -- )  2drop  throw  ;
' $abort-include is $open-error

: included  ( adr len -- )
   include-hook
   r/o open-file  ?dup  if
      opened-filename 2@ $open-error
   then                 ( fid )
   include-file
   include-exit-hook
;
: including  ( "name" -- )  safe-parse-word included  ;
: fl  ( "name" -- )  including  ;

0 value error-file
: init  ( -- )  init  d# 128 alloc-mem  is error-file  ;
nuser error-line#
nuser error-source-id
nuser error-source-adr
nuser error-#source
: (mark-error)  ( -- )
   \ Suppress message if input is interactive or from "evaluate"
   source-id  error-source-id !
   source-id  0<>  if
      source-id  -1 =  if
         source error-#source !  error-source-adr !
      else
         source-id file-name error-file place
         source-id file-line error-line# !
      then
   then
;
' (mark-error) is mark-error
: (show-error)  ( -- )
   ??cr
   error-source-id @  if
      error-source-id @ -1  =  if
         ." Evaluating: " error-source-adr @ error-#source @  type cr
      else
         error-file count type  ." :"
         base @ >r decimal  error-line# @ (.) type  r> base !
         ." : "
      then
   then
;
' (show-error) is show-error

\ Environment?

defer environment?
: null-environment?  ( c-addr u -- false | i*x true )  2drop false  ;
' null-environment? is environment?

defer prompt  ( -- )   ' (prompt) is prompt

defer quit  ' (quit) is quit

: fload fl ;

: $report-name  ( name$ -- name$ )
   ." Loading " 2dup type cr
;
: fexit ( -- )  source-id close-file drop -1 'source-id !  ;

\ From copyright.fth

: id: [compile] \ ;
: copyright: [compile] \ ;
: purpose: [compile] \ ;
: build-now ;
: command: [compile] \ ;
: in: [compile] \ ;
: dictionary: [compile] \ ;

\ From cmdline.fth

\ Get the arguments passed from the program

\ Returns the command line argument indexed by arg#, as a string.
\ In most systems, the 0'th argument is the name of the program file.
\ If the arg#'th argument doesn't exist, returns 0.
: >arg  ( arg# -- false | arg-adr arg-len true )
   dup #args >=  if  ( arg# )
      drop false
   else              ( arg# )
      args swap na+ @  cscount true
   then
;

variable arg#

\ Get the next argument from the command line.
\ Returns 0 when there are no more arguments.
\ arg# should be set to 1 before the first call.
\ argument number 0 is usually the name of the program file.
: next-arg  ( -- false  | arg-adr arg-len true )
   arg# @  >arg  dup  if  1 arg# +!  then
;

: process-argument  ( adr len -- )
   2dup  " -s"  $=  if       ( adr len )
      2drop next-arg  0= ( ?? ) abort" Missing argument after '-s'"
      evaluate               ( ?? )
   else                      ( adr len )
   2dup  " -"  $=  if        ( adr len )      
      2drop
      interact
   else                      ( adr len )
      included
\     "temp pack  "load      ( ?? )
   then then
;

: process-command-line  ( -- )
   #args  1 <=  if  exit  then
   1 arg# !
   begin  next-arg  while  ( adr len )
      ['] process-argument  catch  ?dup  if  .error  error-exit  then
   repeat
   bye
;

