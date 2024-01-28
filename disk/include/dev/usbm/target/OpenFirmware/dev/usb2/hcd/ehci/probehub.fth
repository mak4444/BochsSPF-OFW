purpose: USB hub probing code to support USB 1.1 devices downstream

hex

\ There are two properties to support 1.1 hubs and devices:
\      hub20-dev
\      hub20-port
\
\ hub20-dev   is an integer property containing the assigned-address of
\             a USB 2.0 hub.
\ hub20-port  is an integer property containing the downstream port# (based 1)
\             of a USB 2.0 hub if the device attached to it is a 1.1 device.
\
\ For example, if we have the following physical topology:
\     USB 2.0 hub:   port 1:  2.0 disk
\                    port 2:  1.1 hub       port 1: disk
\                                           port 2: disk
\                    port 3:  1.1 mouse
\                    port 4:  none
\
\ Then /usb/hub has the "hub20-dev" property.
\      /usb/hub/hub has the "hub20-port" property of value 2.
\      /usb/hub/mouse has the "hub20-port" property of value 3.
\
\ In order to correctly communicate with the 1.1 hub and all the devices behind
\ it, the /usb/hub hub20-dev value and the /usb/hub/hub hub20-port value are
\ used in the Transaction Descriptor (qTD).
\
\ Likewise, to correctly communicate with the mouse, the /usb/hub hub20-dev
\ value and the /usb/hub/mouse hub20-port value are used in the qTD.
: probehubfthe
s" : ?set-hub20-port" eval  ( speed dev port -- )
 "    "" hub20-dev"" my-parent ihandle>phandle get-package-property 0=  if" eval  ( speed dev port value$ )
s"       2drop" eval                                     ( speed dev port )
s"       nip swap speed-high <>  if" eval                ( port )
 "          encode-int "" hub20-port"" property" eval      ( )
s"       else" eval                                      ( speed )
s"          drop" eval                                   ( )
s"       then" eval                                      ( )
s"    else" eval                                         ( speed dev port )
s"       3drop" eval                                     ( )
s"    then ;" eval                                        ( )

s" ' ?set-hub20-port to make-dev-property-hook" eval
;
headers
