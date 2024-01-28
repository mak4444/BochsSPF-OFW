
[ifndef] lbsplit
: lbsplit ( l -- b.lo b.1 b.2 b.hi )  lwsplit >r wbsplit r> wbsplit  ;
[then]
[ifndef] wbsplit
: wbsplit  ( l -- b.low b.high )
   dup  h# ff and  swap   8 >>
        h# ff and
;
[then]
[ifndef] bljoin
: bljoin  ( b.lo b.1 b.2 b.hi -- l )  bwjoin  >r bwjoin  r> wljoin   ;
[then]
[ifndef] bwjoin
: bwjoin  (  b.low b.high -- w )  8 << +  ;
[then]
[ifndef] xwsplit
64\ : xwsplit ( x -- w.lo w.2 w.3 w.hi )  xlsplit >r lwsplit r> lwsplit  ;
[then]
[ifndef] wxjoin
64\ : wxjoin  ( w.lo w.2 w.3 w.hi -- x )  wljoin  >r wljoin  r> lxjoin   ;
[then]
[ifndef] xbsplit
64\ : xbsplit ( x -- b.lo b.2 b.3 b.4 b.5 b.6 b.7 b.hi )
64\    xlsplit >r lbsplit r> lbsplit
64\ ;
[then]
[ifndef] bxjoin
64\ : bxjoin ( b.lo b.2 b.3 b.4 b.5 b.6 b.7 b.hi -- x )
64\    bljoin  >r bljoin  r> lxjoin
64\ ;
[then]
