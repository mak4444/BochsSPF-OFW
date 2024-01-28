purpose: Extract actual interrupt value from property

hex
external
: irq#  ( -- irq )
   " interrupts" get-my-property  if
      ." Missing interrupts property" cr
      0 exit
   then                ( adr len )
   get-encoded-int     ( irq )
;
headers
end-package
