purpose: endian-specific operators

[ifndef] le-w@
: le-w@   ( a -- w )   dup    c@ swap ca1+    c@ bwjoin  ;
[then]
[ifndef] be-w@
: be-w@   ( a -- w )   dup ca1+    c@ swap    c@ bwjoin  ;
[then]
[ifndef] le-l@
: le-l@   ( a -- l )   dup le-w@ swap wa1+ le-w@ wljoin  ;
[then]
[ifndef] be-l@
: be-l@   ( a -- l )   dup wa1+ be-w@ swap be-w@ wljoin  ;
[then]

[ifndef] le-w!
: le-w!   ( w a -- )   >r wbsplit r@ ca1+    c! r>    c!  ;
[then]
[ifndef] be-w!
: be-w!   ( w a -- )   >r wbsplit r@    c! r> ca1+    c!  ;
[then]
[ifndef] le-l!
: le-l!   ( l a -- )   >r lwsplit r@ wa1+ le-w! r> le-w!  ;
[then]
[ifndef] be-l!
: be-l!   ( l a -- )   >r lwsplit r@ be-w! r> wa1+ be-w!  ;
[then]

: le-l,   ( l -- )     here /l allot le-l!  ;
: be-l,   ( l -- )     here /l allot be-l!  ;

[ifndef] /x
8 constant /x
[then]

32\ : le-x@  ( adr -- d )  dup le-l@  swap la1+ le-l@  ;
32\ : be-x@  ( adr -- d )  dup la1+ be-l@  swap be-l@  ;
32\ : le-x!  ( d adr -- )  tuck la1+ le-l!  le-l!  ;
32\ : be-x!  ( d adr -- )  tuck be-l!  la1+ be-l!  ;

64\ : le-x@   ( a -- l )   dup le-l@  swap la1+ le-l@ lxjoin  ;
64\ : be-x@   ( a -- l )   dup la1+ be-l@  swap be-l@ lxjoin  ;
64\ : le-x!   ( l a -- )   >r xlsplit r@ la1+ le-l! r> le-l!  ;
64\ : be-x!   ( l a -- )   >r xlsplit r@ be-l! r> la1+ be-l!  ;

: le-x,   ( x -- )  here /x allot le-x!  ;
: be-x,   ( x -- )  here /x allot be-x!  ;

32\ alias be-n@ be-l@
32\ alias be-n! be-l!
32\ alias be-n, be-l,

64\ alias be-n@ be-x@
64\ alias be-n! be-x!
64\ alias be-n, be-x,
