
\ Display the WORDS in the Context Vocabulary

decimal

only forth also definitions

: over-vocabulary  (s acf-of-word-to-execute voc-acf -- )
   follow  begin  another?  while   ( acf anf )
      n>link over execute           ( acf )
   repeat  ( acf )  drop
;
: +words   (s -- )
   0 lmargin !  td 64 rmargin !  td 14 tabstops !
   ??cr
   begin  another?  while      ( anf )
     dup name>string nip .tab  ( anf )
     .id                       ( )
     exit? if  exit  then      ( )
   repeat                      ( )
;
: follow-to  (s adr voc-acf -- error? )
   follow  begin  another?  while         ( adr anf )
      over u<  if  drop false exit  then  ( adr )
   repeat                                 ( adr )
   drop true
;
: prior-words  (s adr -- )
   context token@ follow-to  if
      ." There are no words prior to this address." cr
   else
      +words
   then
;

: words  (s -- )  context token@ follow  +words  ;

only definitions forth also
: words    words ;  \ Version for 'root' vocabulary
only forth also definitions
