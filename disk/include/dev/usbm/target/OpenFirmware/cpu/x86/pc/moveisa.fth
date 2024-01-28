purpose: Set the ISA node's PCI configuration address

\ Find the ISA bridge and set the isa node's reg property to the
\ PCI device number of the actual hardware
: move-isa  ( -- )
   d# 32  0  do
      \ Look for a PCI header with the ISA bus class code
      i h# 800 *  8 +  config-l@  8 rshift  h# 60100  =  if
         \ Patch the "reg" property in the ISA node to that config address
         " /pci/isa" find-package  if
            " reg" rot get-package-property  0=  if  ( adr len )
               drop  i h# 800 *  swap be-l!
            then
         then
         leave
      then
   loop
;
stand-init:
   move-isa
;
