purpose: USB Hub Probing Code

hex

: probehubfth

s" set-usb20-char" $find ?dup
if s" : set-usb20-char ( port dev -- ) 2drop  ;" eval then
2drop

s" 8 buffer: hub-buf" eval   \ For hub probing

 " : power-hub-port   ( port -- )  PORT_POWER  DR_PORT "" set-feature"" $call-parent drop  ;" eval
 " : reset-hub-port   ( port -- )  PORT_RESET  DR_PORT "" set-feature"" $call-parent drop  d# 20 ms  ;" eval
\ Test modes: 1:J 2:K 3:SE0_NAK 4:Packet 5:ForceEnable
 " : test-hub-port    ( port test-mode -- )  wljoin  PORT_TEST   DR_PORT "" set-feature"" $call-parent drop  ;" eval
 " : untest-hub-port  ( port -- )  PORT_TEST   DR_PORT "" clear-feature"" $call-parent drop  ;" eval
 " : clear-status-change  ( port -- )  C_PORT_CONNECTION  DR_PORT "" clear-feature"" $call-parent drop  ;" eval
 " : parent-set-target  ( dev -- )  "" set-target"" $call-parent  ;" eval
s" : hub-error?" eval  ( -- error? )
 "    hub-buf 4  0  DR_HUB "" get-status"" $call-parent" eval    ( actual usberror )
s"    nip  if" eval                                   ( )
 "       ."" Failed to get hub status"" cr" eval
s"       true" eval                                   ( true )
s"    else" eval                                      ( )
s"       hub-buf 2+ c@ 2 and  if" eval                ( )
 "          ."" USB Hub shut down due to over-current"" cr" eval
s"          true" eval                                ( true )
s"       else" eval                                   ( )
s"          false" eval                               ( false )
s"       then" eval                                   ( error? )
s"    then ;" eval                                     ( error? )


s" : get-port-status" eval  ( port -- error? )
 "    hub-buf 4  2 pick   DR_PORT "" get-status"" $call-parent" eval    ( port actual usberror )
s"    nip  if" eval                                   ( port )
 "       ."" Failed to get port status for port "" u. cr" eval
s"       true" eval                                   ( true )
s"    else" eval                                      ( port )
s"       drop false" eval                             ( false )
s"    then ;" eval

s" : port-status-changed?" eval  ( hub-dev port -- false | connected? true )
s"    swap parent-set-target" eval       ( port )
s"    dup get-port-status  if" eval      ( port )
s"       drop false exit" eval           ( -- false )
s"    then" eval                         ( port )
 
s"    hub-buf c@ 8 and  if" eval         ( port )
 "       ."" Hub port "" . ."" is over current"" cr" eval
s"       false  exit" eval               ( -- false )
s"   then" eval

s"    hub-buf 2+ c@  1 and  if" eval     ( port )
       \ Status changed
s"       clear-status-change" eval
s"       hub-buf c@ 1 and  0<>" eval     ( connected? )
s"       true" eval                      ( connected? true )
s"    else" eval                         ( port )
s"       drop false" eval                ( false )
s"    then ;" eval

s" : probe-hub-port" eval  ( hub-dev port -- )
    \ Reset the port to determine the speed
s"    swap parent-set-target" eval			( port )
s"    dup reset-hub-port" eval				( port )
 
    \ get-port-status fills hub-buf with connection status, speed, and other information
s"    dup get-port-status" eval  			( port error? )
s"    over clear-status-change" eval              	( port error? )
s"    if  drop exit  then" eval				( port )

s"    dup disable-old-nodes" eval			( port ) 
s"    hub-buf c@ 1 and 0=  if  drop exit  then" eval	( port )  \ No device connected
s"    hub-buf le-w@ h# 600 and 9 >>" eval  		( port speed )

   \ hub-port and hub-dev route USB 1.1 transactions through USB 2.0 hubs
s"    over get-hub20-port  get-hub20-dev" eval		( port speed hub-port hub-dev )

 \ Execute setup-new-node in root context and make-device-node in hub node context
 "   "" setup-new-node"" $call-parent  if  execute  then ;" eval

s" : hub-#ports" eval  ( -- #ports )
 "    hub-buf 8 0 0 HUB DR_HUB "" get-desc"" $call-parent nip  if" eval
 "       ."" Failed to get hub descriptor"" cr" eval
s"       0 exit" eval
s"    then" eval
s"    hub-buf 2 + c@ ;" eval 		( #ports )

s" : hub-delay  ( -- #2ms )  hub-buf 5 + c@  ;" eval

s" : power-hub-ports" eval  ( #ports -- )
s"    1+  1  ?do  i power-hub-port  loop" eval

s"    hub-delay 2* ms" eval

 "    "" usb-delay"" ['] evaluate catch  if" eval      ( )
s"       2drop  d# 100" eval                         ( ms )
s"    then" eval                                     ( ms )
s"    ms ;" eval

s" : safe-probe-hub-port" eval  ( hub-dev port -- )
s"    tuck ['] probe-hub-port catch  if" eval    ( port x x )
 "       2drop  ."" Failed to probe hub port "" . cr" eval
s"    else" eval                                 ( port )
s"       drop" eval
s"    then ;" eval

s" : probe-hub" eval  ( dev -- )
s"    dup parent-set-target" eval		( hub-dev )
s"    hub-#ports  dup  0=  if" eval		( hub-dev #ports )
s"       2drop exit" eval			( -- )
s"    then" eval					( hub-dev #ports )

 "    "" configuration#"" get-int-property" eval	( hub-dev #ports config# )
 "    "" set-config"" $call-parent" eval           ( hub-dev #ports usberr )
 "    if  drop  ."" Failed to set config for hub at "" u. cr exit  then" eval  ( hub-dev #ports )

s"    dup power-hub-ports" eval			( hub-dev #ports )

s"   hub-error?  if  2drop exit  then" eval	( hub-dev #ports )

s"    1+ 1  ?do" eval				( hub-dev )
s"       dup i safe-probe-hub-port" eval		( hub-dev )
s"    loop" eval					( hub-dev )
s"    drop ;" eval

s" : probe-hub-xt  ( -- adr )  ['] probe-hub  ;" eval

s" : do-reprobe-hub" eval  ( dev -- )
s"    dup parent-set-target" eval			( hub-dev )
   
s"    hub-#ports  dup 0=  if" eval                       ( hub-dev #ports )
s"       2drop exit" eval                                ( -- )
s"    then" eval                                         ( hub-dev #ports )

s"    hub-error?  if  2drop exit  then" eval		( hub-dev #ports )

s"    1+  1  ?do" eval                                   ( hub-dev )
s"       dup i port-status-changed?  if" eval            ( hub-dev connected? )
s"          i disable-old-nodes" eval                    ( hub-dev connected? )
s"          if" eval                                     ( hub-dev )
s"             d# 100 ms" eval                           ( hub-dev )  \ Time for device to wake up
s"             dup i safe-probe-hub-port" eval           ( hub-dev )
s"          then" eval                                   ( hub-dev )
s"       else" eval                                      ( hub-dev )
s"          i port-is-hub?  if" eval                     ( hub-dev phandle )
s"             reprobe-hub-node" eval                    ( hub-dev )
s"          then" eval                                   ( hub-dev )
s"       then" eval                                      ( hub-dev )
s"    loop" eval                                         ( hub-dev )
s"    drop ;" eval                                        ( )


s" : reprobe-hub-xt  ( -- adr )  ['] do-reprobe-hub  ;" eval

s" : hub-port-connected?" eval  ( port# -- flag )
s"    get-port-status  if  false exit  then" eval
s"    hub-buf c@ 1 and  0<> ;" eval
s" 0 value hub-dev" eval
s" : wait-hub-connect" eval  ( port# -- error? )
s"    begin" eval                            ( port# )
s"       dup hub-port-connected?  0=" eval   ( port# unconnected? )
s"    while" eval                            ( port# )
s"       key?  if" eval                      ( port# )
s"          key h# 1b =  if" eval            ( port# )   \ ESC aborts
s"             drop true exit" eval          ( -- true )
s"          then" eval                       ( port# )
s"       then" eval                          ( port# )
s"    repeat" eval                           ( port# )
 "    ."" Device connected - probing ... "" " eval
s"    d# 150 ms" eval                        ( port# )   \ Wakeup time
s"    probe-setup" eval                      ( port# )
s"    hub-dev swap ['] probe-hub-port  catch  if" eval  ( x x  )
s"       2drop" eval                         ( )
 "      ."" Failed"" cr" eval                 ( )
s"      true" eval                          ( true )
s"   else" eval                             ( )
 "      ."" Done"" cr" eval                   ( )
s"      false" eval                         ( false )
s"   then" eval                             ( error? )
s"   probe-teardown ;" eval                  ( error? )

s" : (hub-selftest)" eval  ( port -- stop? )
s"    >r" eval
s"    hub-dev parent-set-target" eval              ( )
s"    r@ get-port-status  if" eval                 ( )
 "       ."" Get-port-status failed for hub port "" r@ u. cr" eval
s"       r> drop true exit" eval                   ( -- true )
s"    then" eval                                   ( )
 "    ."" Hub port "" r@ u. ."" : "" " eval            ( )
s"    hub-buf c@ 8 and  if" eval   \ Connected     ( )
 "       ."" In over current"" cr" eval              ( )
s"       r> drop true exit" eval                   ( -- true )
s"    then" eval                                   ( )
s"    hub-buf c@ 1 and  if" eval   \ Connected     ( )
 "       ."" In use - "" " eval                      ( )
s"       r@ .usb-device cr" eval                   ( )
s"    else" eval                                   ( )
s"       diagnostic-mode?  if" eval                ( )
 "          ."" Please connect a device""  cr" eval  ( )
s"          r@ wait-hub-connect  if  r> drop true exit  then" eval   ( )
s"          r@ .usb-device cr" eval                                  ( )
s"       else" eval                                                  ( )
 "          "" fisheye?"" $call-parent  if" eval                       ( )
 "             ."" Fisheye pattern"" cr" eval                          ( )
s"             r@ 4 test-hub-port" eval                              ( )
s"             d# 2,000 ms" eval                                     ( )
s"             r@ untest-hub-port" eval                              ( )
s"             r@ reset-hub-port  r@ power-hub-port" eval            ( )
s"          else" eval                                               ( )
 "             ."" Empty"" cr" eval                                 ( )
s"          then" eval                                               ( )
s"       then" eval                                                  ( )
s"    then" eval                                                     ( )
s"    r> drop false ;" eval

s" : hub-selftest" eval  ( hub-dev -- error? )
s"    to hub-dev" eval                                           ( )

 "    "" usb-hub-test-list"" get-inherited-property  if" eval      ( )
s"       hub-#ports 1+  1  ?do" eval                             ( )
s"          i (hub-selftest)  if  true unloop exit  then" eval   ( )
s"       loop" eval                                              ( )
s"    else" eval                                                 ( propval$ )
s"       decode-string 2swap 2drop" eval                         ( list$ )
s"       begin  dup  while" eval                                 ( list$ )
s"          ascii , left-parse-string" eval                      ( list$' dev#$ )
s"          base @ >r decimal" eval                              ( list$' dev#$ )
s"          $number  if  0  then" eval                           ( list$' port# )
s"          r> base !" eval                                      ( list$ port# )
s"          (hub-selftest)  if  2drop true exit  then" eval      ( list$ )
s"       repeat" eval                                            ( list$ )
s"       2drop" eval                                             ( )
s"    then" eval                                                 ( )

    \ Maybe need to reset the entire hub here
s"    false ;" eval                                               ( false )
s" : hub-selftest-xt  ( -- xt )  ['] hub-selftest  ;" eval
;
