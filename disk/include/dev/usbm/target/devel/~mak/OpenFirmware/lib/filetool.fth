REQUIRE [IF] ~mak/CompIF.f

\ Some convenience words for dealing with files.


\ linefeed constant newline

\ Handy file descriptor variables
VARIABLE MIFD
VARIABLE MOFD

: $READ-OPEN  ( name$ -- )
   2DUP R/O OPEN-FILE  IF      ( name$ x )
      DROP  ." Can't open " TYPE ."  for reading." CR ABORT
   THEN                        ( name$ fd )
   MIFD !                       ( name$ )
   2DROP
;
: READING  ( "filename" -- )  PARSE-NAME $READ-OPEN  ;

: $WRITE-OPEN  ( name$ -- )
  2DUP R/W OPEN-FILE  IF      ( name x )
      DROP  ." Can't open " TYPE ."  for writing." CR ABORT
   THEN                        ( name$ fd )
   MOFD !                       ( name$ )
   2DROP
;
: $NEW-FILE  ( name$ -- )
   2DUP + 0!   2DUP R/W CREATE-FILE  IF    ( name$ x )
      DROP  ." Can't create " TYPE  CR ABORT
   THEN                        ( name$ fd )
   MOFD !                       ( name$ )
   2DROP
;
: mWRITING  ( "filename" -- )
  PARSE-NAME $NEW-FILE  ;

0 [IF]
: $APPEND-OPEN  ( name$ -- )
   2DUP R/W OPEN-FILE  IF                               ( name$ ior )
      \ We have to make the file
      DROP $NEW-FILE                                    ( )
   ELSE  \ The file already exists, so seek to the end  ( name$ fd )
      MOFD !  2DROP                                      ( )
      0 MOFD @ FSEEK-FROM-END                            ( )
   THEN
;
: APPENDING  ( "filename" -- )  SAFE-PARSE-WORD $APPEND-OPEN  ;
[THEN]
: $FILE-EXISTS?  ( name$ -- flag ) \ True if the named file already exists
   R/O OPEN-FILE  IF  DROP FALSE  ELSE  CLOSE-FILE DROP TRUE  THEN
;
0 [IF]
: $FILE,  ( adr len -- )
   R/O ( BIN OR )  OPEN-FILE  ABORT" Can't open file"  MIFD !

   HERE   MIFD @ FSIZE DUP ALLOT                    ( adr len )
   2DUP   MIFD @ FGETS  OVER <> ABORT" Short read"  ( adr len )
   MIFD @ FCLOSE                                    ( adr len )
   NOTE-STRING  2DROP   \ Mark as a sequence of bytes
;
[THEN]

\ Backwards compatibility ...

: READ-OPEN     ( name-pstr -- )  COUNT $READ-OPEN    ;
: WRITE-OPEN    ( name-pstr -- )  COUNT $WRITE-OPEN   ;
: NEW-FILE      ( name-pstr -- )  COUNT $NEW-FILE     ;

: fsize ( fd -- size )    FILE-SIZE 2DROP ;
: dfseek  ( d.byte# fd -- )
   REPOSITION-FILE throw ;

: fseek  ( byte# fd -- )  0 swap dfseek  ;

\ : APPEND-OPEN   ( name-pstr -- )  COUNT $APPEND-OPEN  ;
\EOF
: FILE-EXISTS?  ( name-pstr -- flag ) \ True if the named file already exists
   READ FOPEN  ( fd )   DUP   IF  FCLOSE TRUE  THEN
;
