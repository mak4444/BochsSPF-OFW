h# 100 constant /regs

: my-b@  ( offset -- b )  my-space +  " config-b@" $call-parent  ;
: my-b!  ( b offset -- )  my-space +  " config-b!" $call-parent  ;

: my-w@  ( offset -- w )  my-space +  " config-w@" $call-parent  ;
: my-w!  ( w offset -- )  my-space +  " config-w!" $call-parent  ;

: my-l@  ( offset -- l )  my-space +  " config-l@" $call-parent  ;
: my-l!  ( l offset -- )  my-space +  " config-l!" $call-parent  ;

: my-map-in  ( len -- adr )
   >r  0 0 my-space h# 02000010 +  r>  " map-in" $call-parent
   4 my-w@  h# 16 or  4 my-w!  \ Set MWI, bus mastering, and mem enable
;
: my-map-out  ( adr len -- )
   \ Don't disable because somebody else might be using the controller.
   \ 4 my-w@  7 invert and  4 my-w!
   " map-out" $call-parent
;

: has-dbgp-regs?  ( -- false | offset bar true)
   h# 34 my-l@                   ( capability-ptr )
   begin  dup  while             ( cap-offset )
      dup my-b@ h# 0a =  if      ( cfg-adr )
         2+ my-w@                ( dbgp-ptr )
         dup h# 1fff and         ( offset )
         d# 13 rshift  7 and  1- /l* h# 10 +  ( offset bar )
         true                    ( offset bar true )
         exit
      then                       ( cfg-adr )
      1+ my-b@                   ( cap-offset' )
   repeat                        ( cap-offset )
   drop  false                   ( false )
;
: needs-dummy-qh?  ( -- flag )  0 my-w@ h# 1106 ( VIA ) =  ;
: grab-controller  ( config-adr -- error? )
   dup my-l@  h# 10001 =  if              ( config-adr )
      h# 1000000 over my-l!              ( config-adr )  \ Ask for it
      true                                ( config-adr error? )
      d# 100 0  do                        ( config-adr error? )
         over my-l@ h# 1010000 and  h# 1000000 =  if
            \ Turn off SMIs in Legacy Support Extended CSR
            h# e0000000 h# 6c my-l!      ( config-adr error? )
            0 my-l@ h# 27cc8086 =  if
               h# ffff0000  h# 70  my-l!  \ Clear EHCI Intel special SMIs
            then
            0= leave                      ( config-adr error?' )
         then                             ( config-adr error? )
         d# 10 ms                         ( config-adr error? )
      loop                                ( config-adr error? )
      nip exit
   then                                   ( config-adr )
   drop false                             ( false )
;
