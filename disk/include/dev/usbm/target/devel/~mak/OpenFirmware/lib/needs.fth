
\ Implements needs and \needs.  These work as follows:
\
\ needs foo tools.fth
\
\ If foo is not defined, the file tools.fth will be loaded, which should
\ define foo.  If foo is already defined, nothing will happen.
\
\ \needs foo <arbitrary Forth commands>
\
\ If foo is not defined, the rest of the line is executed, else it is ignored

: NEEDS  \ wordname filename  ( -- )
  REQUIRE ;

: \NEEDS
    POSTPONE [UNDEFINED]
    0= IF POSTPONE \ THEN ;
