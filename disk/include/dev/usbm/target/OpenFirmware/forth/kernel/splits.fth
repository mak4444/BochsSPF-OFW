purpose: split and join operators

[ifndef] lowbyte
: lowbyte   h# ff and  ;
[then]

[ifndef] lwsplit
: lwsplit ( l -- w.low w.high )   dup n->w  swap  d# 16 rshift n->w  ;
[then]
[ifndef] wbsplit
: wbsplit ( w -- b.low b.high )   dup lowbyte  swap  d# 8 rshift lowbyte  ;
[then]
[ifndef] bwjoin
: bwjoin  ( b.low b.high -- w )   lowbyte d# 8 lshift swap lowbyte or  ;
[then]
[ifndef] wljoin
: wljoin  ( w.low w.high -- l )   n->w d# 16 lshift swap n->w or  ;
[then]

64\ : xlsplit ( x -- l.low l.high )   dup n->l  swap  d# 32 rshift n->l  ;
64\ : lxjoin  ( l.low l.high -- x )   n->l d# 32 lshift swap n->l or  ;

: lbsplit ( l -- b.low b.lowmid b.highmid b.high )
   lwsplit >r  wbsplit  r>  wbsplit  
;
: bljoin  ( b.low b.lowmid b.highmid b.high -- l )
   bwjoin >r  bwjoin  r>  wljoin
;

