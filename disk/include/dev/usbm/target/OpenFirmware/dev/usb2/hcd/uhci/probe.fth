purpose: UHCI USB Controller probe
\ See license at end of file

hex

: probefth

s" : probe-root-hub-port" eval  ( port -- )
   \ Reset the port to perform connection status and speed detection
s"    dup reset-port" eval				( port )
s"    dup disable-old-nodes" eval			( port )
s"    dup portsc@ 1 and 0=  if  drop exit  then" eval	( port )  \ No device-connected

s"    dup portsc@ 100 and  if  speed-low  else  speed-full  then" eval	( port speed )

   \ hub-port and hub-speed are irrelevant for UHCI (USB 1.1)
s"    0 0" eval							( port speed hub-port hub-dev )

   \ Execute setup-new-node in root context and make-device-node in hub node context
s"    setup-new-node  if  execute  then	;" eval

s" : power-ports  ( -- )  ;" eval

s" : probe-root-hub" eval  ( -- )
   \ Set active-package so device nodes can be added and removed
s"    my-self ihandle>phandle push-package" eval

s"    alloc-pkt-buf" eval
s"    2 0  do" eval
s"       i portsc@ h# a and  if" eval
\        i rm-obsolete-children			\ Remove obsolete device nodes
s"         i ['] probe-root-hub-port catch  if" eval
"            drop ."" Failed to probe root port "" i .d cr" eval
s"         then" eval
s"         i portsc@ i portsc!" eval			\ Clear change bits
s"      else" eval
s"         i port-is-hub?  if" eval     ( phandle )     \ Already-connected hub?
s"            reprobe-hub-node" eval                    \ Check for changes on its ports
s"         then" eval
s"      then" eval
s"   loop" eval
s"   free-pkt-buf" eval

s"   pop-package ;" eval

s" : do-resume   init-struct   start-usb ;" eval

\ This is a sneaky way to determine if the hardware has been turned off without the software's knowledge
s" : suspended? ( -- flag )  flbaseadd@ 0=  framelist-phys 0<>  and  ;" eval

s" : open" eval  ( -- flag )
s"   parse-my-args" eval
s"   open-count 0=  if" eval
s"      map-regs" eval
s"      first-open?  if" eval
s"         false to first-open?" eval
s"         ?disable-smis" eval
s"         reset-usb" eval
s"         init-lists" eval
s"         do-resume" eval
s"      then" eval

s"      suspended?  if  do-resume  then" eval

s"      alloc-dma-buf" eval
s"   then" eval
s"   probe-root-hub" eval
s"   open-count 1+ to open-count" eval
s"   true ;" eval

s" : close" eval  ( -- )
s"   open-count 1- to open-count" eval
s"   end-extra" eval
s"   open-count 0=  if  free-dma-buf  then ;" eval \ Don't unmap
;