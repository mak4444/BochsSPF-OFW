
: my-map-in  ( len -- adr )
   >r  0 0 my-space h# 02000010 +  r>  " map-in" $call-parent
   4 my-w@  h# 16 or  4 my-w!
;
: my-map-out  ( adr len -- )
   4 my-w@  7 invert and  4 my-w!
   " map-out" $call-parent
;
