h# 400 constant /regs


: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( l offset -- )  my-space +  " config-l!" $call-parent  ;


: my-map-in  ( len -- adr )
   >r
   0 0 my-space h# 01000020 +  r>  " map-in" $call-parent  ( adr )
   4 my-w@  h# 17 or  4 my-w!                               ( adr )
;
: my-map-out  ( adr len -- )
   4 my-w@  7 invert and  4 my-w!   ( adr len )
   " map-out" $call-parent          ( )
;

: ?disable-smis  ( -- )
   0 my-l@ h# 27c88086 =  if   h# af00 h# 80 my-w!  then
;
