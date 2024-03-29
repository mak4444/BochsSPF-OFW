
also hidden
only forth also hidden also definitions
decimal
headerless

variable sift-vocabulary

headers

\ Leave a "hook" for showing the name of the vocabulary
\ only once, the first time a matching name is found.
\ Showing the name of a device can be plugged in here also...
defer .voc     ' noop is .voc

: .in  ( -- )  ??cr tabstops @ spaces  ." In "  ;

headerless
: .vocab  ( -- )
   .in ['] vocabulary .name space
   sift-vocabulary @ .name cr
   ['] noop is .voc
;

\ Show the "sifted" name, preceded by its  cfa  in parentheses.
\ Show the name of the vocabulary only the first time.
\ Control the display with  exit?
: .sift?  ( nfa -- exit? )
   .voc
   exit? tuck  if  drop exit  then 		( exit? nfa )
   dup  name>				 	( exit? nfa cfa )
   over n>flags c@  h# 20 and  if  token@  then	  \ Handle aliases
   fake-name			 		( nfa fstr )
   over name>string nip
   over name>string nip + 3 + .tab
  .id .id 2 spaces
;

headers
forth definitions

\ Sift through the given vocabulary, using the sift-string given.
\ Control the display with  exit?
: vsift?  ( adr len voc-acf -- adr len exit? )
   dup sift-vocabulary !  follow
   begin  another?  while			( adr len nfa )
      3dup name>string sindex			( adr len nfa indx|-1 )
      1+ if  .sift? ?dup if exit then
	else   drop
	then
   repeat	   false
;

\ Sift through all the vocabularies for the string given
\ on the stack as  addr,len
: $sift ( addr len -- )
   voc-link  begin  another-link?  while	( addr len v-link )
      ['] .vocab is .voc
      voc> >r r@ vsift? r> swap  if  3drop exit  then
      >voc-link		
   repeat  2drop
;

\  Same thing, only the string is given on the stack in packed format
: sift  ( str -- )  count $sift  ;

\  Same thing, only the string is given in the input stream.
: sifting  \ name  ( -- )
   safe-parse-word $sift
;

only forth also definitions
