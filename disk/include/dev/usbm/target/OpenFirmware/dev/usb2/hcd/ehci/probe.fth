purpose: EHCI USB Controller probe

hex
headers

: probefth

s" 0 value port-speed" eval

s" : make-root-hub-node" eval  ( port -- )
s"    0 set-target" eval	\ First address it as device 0	( port )
s"    port-speed 0 di-speed!" eval     \ Use high speed for getting the device descriptor

s"    dup reset-port" eval		( port )

s"    port-speed" eval			( port speed )

   \ hub-port and hub-dev route USB 1.1 transactions through USB 2.0 hubs
s"    over get-hub20-port  get-hub20-dev" eval		( port speed hub-port hub-dev )

   \ Execute setup-new-node in root context and make-device-node in hub node context
s"  setup-new-node  if  execute  then ;" eval

s" 0 instance value probe-error?" eval  \ Back channel to selftest

s" : make-port-node" eval  ( port -- )
s"    ['] make-root-hub-node catch  if" eval
 "       drop ."" Failed to make root hub node for port "" dup .d cr" eval
s"       true to probe-error?" eval
s"    then ;" eval

s" defer handle-ls-device  ' disown-port to handle-ls-device" eval
s" defer handle-fs-device  ' disown-port to handle-fs-device" eval

s" : probe-root-hub-port" eval  ( port -- )
s"    false to probe-error?" eval			( port )
s"    dup disable-old-nodes" eval			( port )
s"    dup portsc@ 1 and 0=  if  drop exit  then" eval	( port ) \ No device detected

s"    dup portsc@ h# c00 and h# 400 =  if" eval		\ A low speed device detected
s"       speed-low to port-speed" eval
s"       dup handle-ls-device" eval			\ Process low-speed device
s"    else" eval						\ Don't know what it is
s"       dup reset-port" eval				\ Reset to find out
s"       dup portsc@ 4 and  0=  if" eval			\ A full speed device detected
s"          speed-full to port-speed" eval
s" 	 dup handle-fs-device" eval			\ Process full-speed device
s"       else" eval					\ A high speed device detected
s"          speed-high to port-speed" eval
s"          dup make-port-node" eval			\ Process high-speed device
s"       then" eval
s"    then" eval                           ( port# )
s"    dup portsc@ swap portsc! ;" eval     ( )		\ Clear connection change bit


s" : #testable-ports" eval  ( -- n )
s"    #ports" eval                                            ( #hardware-ports )
 "    "" usb-test-ports"" get-inherited-property  0=  if" eval  ( #hardware-ports adr len )
s"       decode-int  nip nip  min" eval                       ( #testable-ports )
s"    then ; " eval                                              ( #testable-ports )


\ Port owned by usb 1.1 controller (2000) or device is present (1)
s" : port-connected?  ( port# -- flag )  portsc@ h# 2001 and  ;" eval
s" : wait-connect" eval  ( port# -- error? )
s"    begin" eval                            ( port# )
s"       dup port-connected?  0=" eval       ( port# unconnected? )
s"    while" eval                            ( port# )
s"       key?  if" eval                      ( port# )
s"          key h# 1b =  if" eval            ( port# )   \ ESC aborts
s"             drop true exit" eval          ( -- true )
s"          then" eval                       ( port# )
s"       then" eval                          ( port# )
s"    repeat" eval                           ( port# )
 "    ."" Device connected - probing ... "" " eval
s"    probe-setup" eval                      ( port# )
s"    probe-root-hub-port" eval              ( )
s"    probe-teardown" eval                   ( )
s"    probe-error?" eval                     ( error? )
 "    dup  if  ."" Failed"" else  ."" Done""  then  cr ;" eval ( error? )

s" : power-usb-ports  ( -- )  ;" eval

s" : port-changed?  ( port# -- flag )  portsc@ 2 and 0<>  ;" eval
s" : ports-changed?" eval  ( -- flag )
s"    #ports 0  ?do" eval
s"       i port-changed?  if  true unloop exit  then" eval
s"    loop" eval
s"    false ;" eval

s" : probe-root-hub" eval  ( -- )
s"    probe-setup" eval

s"    #ports 0  ?do" eval			        \ For each port
s"       i port-changed?  if" eval			\ Connection changed
\         i rm-obsolete-children			\ Remove obsolete device nodes
s"          i probe-root-hub-port" eval			\ Probe it
s"       else" eval
s"          i port-is-hub?  if" eval     ( phandle )     \ Already-connected hub?
s"             reprobe-hub-node" eval                    \ Check for changes on its ports
s"          then" eval
s"       then" eval
s"    loop" eval

s"    probe-teardown ;" eval

s" : do-resume" eval  ( -- )
s"    init-ehci-regs" eval
s"    start-usb" eval
s"    claim-ownership" eval
s"    init-struct" eval
s"    init-extra ;" eval

\ Some OTG controllers need to do something after reset-usb to go into host mode
s" defer set-host-mode  ' noop to set-host-mode" eval

\ This is a sneaky way to determine if the hardware has been turned off without the software's knowledge
s" : suspended?  ( -- flag )  asynclist@ 0=  qh-ptr 0<>  and  ;" eval

s" : open" eval  ( -- flag )
s"    parse-my-args" eval
s"    open-count 0=  if" eval
s"       map-regs" eval
s"       alloc-dma-buf" eval
s"       first-open?  if" eval
s"          false to first-open?" eval
s"          hccparams@ 8 rshift h# ff and  ?dup  if" eval  ( config-adr )
s"             grab-controller  if" eval
 "                ."" Can't take control of EHCI from underlying BIOS"" cr" eval
s"                free-dma-buf unmap-regs" eval
s"                false exit" eval
s"             then" eval
s"          then" eval
s"          0 ehci-reg@  h# ff and to op-reg-offset" eval
s"          reset-usb" eval
s"          set-host-mode" eval
s"          do-resume" eval
s"       then" eval
s"       suspended?  if  do-resume  then" eval
s"    then" eval
s"    probe-root-hub" eval
s"    open-count 1+ to open-count" eval
s"    true ;" eval

s" : close" eval  ( -- )
s"    open-count 1- to open-count" eval
s"    end-extra" eval
s"    open-count 0=  if  free-dma-buf unmap-regs  then ;" eval

s" : regs{  ( -- prev )  ehci-reg dup 0=  if  map-regs  then  ;" eval
s" : }regs  ( prev -- )  0=  if  unmap-regs  then  ;" eval

s" : selftest" eval  ( -- error? )
s"   open 0=  if  true exit  then" eval
s"   #testable-ports  0  ?do" eval
 "      ."" USB port "" i u. ."" : "" " eval
s"      i port-connected?  if" eval
"         ."" In use - "" " eval
s"         i .usb-device cr" eval
s"      else" eval
s"         diagnostic-mode?  if" eval
 "            ."" Please connect a device"" cr" eval
s"            i wait-connect  if  true unloop exit  then" eval
s"            i .usb-device cr" eval
s"         else" eval
s"            fisheye?  if" eval
 "               ."" Fisheye pattern"" cr" eval
s"               i test-port-begin" eval
s"               d# 2,000 ms" eval
s"               i test-port-end" eval
s"               0 i portsc!  i reset-port  i power-port" eval
s"            else" eval
 "               ."" Empty"" cr" eval
s"            then" eval
s"         then" eval
s"      then" eval
s"   loop" eval
s"   false" eval
s"   close ;" eval
;