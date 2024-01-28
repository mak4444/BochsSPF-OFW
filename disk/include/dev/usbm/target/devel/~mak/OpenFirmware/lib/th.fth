\ Temporary hex, and temporary decimal.  "h#" interprets the next word
\ as though the base were hex, regardless of what the base happens to be.
\ "d#" interprets the next word as though the base were decimal.
\ "o#" interprets the next word as though the base were octal.
\ "b#" interprets the next word as though the base were binary.

\  Also, words to stash and set, and retrieve, the base during execution
\     of a word in which they're used.  The words of the form  push-<base>
\     (where <base> is hex, decimal, etcetera) does the equivalent of
\     base @ >r <base>     The word  pop-base  recovers the old base...

REQUIRE S>NUM ~nn/lib/s2num.f
REQUIRE SNUMBER ~mak/snumber.4 

0 VALUE DOUBLE?-T

: #:  \ name  ( base -- )  \ Define a temporary-numeric-mode word
   CREATE C, IMMEDIATE
   DOES> 0 TO DOUBLE?-T
   BASE @ >R  C@ BASE !
   PARSE-NAME
 2dup + 1- C@  [CHAR] . = TO DOUBLE?-T
 SNUMBER
     DOUBLE?-T 0= IF DROP \ ELSE  ABORT
		THEN
   STATE @ IF     DOUBLE?-T IF  DLIT, ELSE LIT, THEN
	   THEN
   R> BASE !
;


\ The old names; use h# and d# instead
10 #: TD
16 #: TH

 2 #: B#	\ BINARY NUMBER
 8 #: O#	\ OCTAL NUMBER
10 #: D#	\ DECIMAL NUMBER
16 #: H#	\ HEX NUMBER

: HH#
  POSTPONE H# ; IMMEDIATE \ ghfghfg

: PUSH-BASE:  \ name   ( base -- )  \  Define a base stash-and-set word
   CREATE C,
   DOES>  R> BASE @ >R >R C@ BASE !
;


\  Stash the old base on the return stack and set the base to ...
10 PUSH-BASE:  PUSH-DECIMAL
16 PUSH-BASE:  PUSH-HEX

 2 PUSH-BASE:  PUSH-BINARY
 8 PUSH-BASE:  PUSH-OCTAL

\  Retrieve the old base from the return stack

: POP-BASE ( -- )  R> R> BASE ! >R ;

: L, , ;
: fputs  ( adr count fd -- )
 WRITE-FILE THROW ;

: fputc  ( byte fd -- )
  SWAP >R RP@  1 ROT fputs
  RDROP ;

: fgets  ( adr count fd -- #read )
 READ-FILE THROW ;

: fclose  ( fd -- )
  CLOSE-FILE  THROW ;

: alloc-mem ( u -- a-addr )
  ALLOCATE THROW ;

: free-mem   ( adr #bytes -- )
  DROP FREE THROW
;
