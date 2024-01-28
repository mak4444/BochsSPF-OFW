purpose: ATAPI interface

: atapifth 
hex
s" d# 12 dup constant pkt-len" eval
s" buffer: pkt-buf" eval

\ ATAPI devices only accept 12 byte long commands
\ Fixup the SCSI commands before sending them out

s" : translate-atapi-command" eval  ( cmd-adr,len -- pkt-buf,len )
s"    pkt-buf dup >r pkt-len erase" eval			\ Zero pkt-buf
s"    r@ swap move" eval				\ Copy cmd$ to pkt-buf
s"    r@ c@ dup h# 15 = swap h# 1a = or  if" eval	\ Mode send or mode select command
s"       r@ c@ h# 40 or r@ c!" eval		\ Fix it
s"       r@ 4 + c@ r@ 8 + c!" eval
s"       0 r@ 4 + c!" eval
s"    else" eval
s"       r@ c@ dup 8 = swap h# a = or  if" eval		\ Read or write command
s"          r@ c@ h# 20 or r@ c!" eval			\ Fix it
s"          r@ 1+ c@ dup h# e0 and r@ 1+ c!" eval
s"          r@ 4 + c@ r@ 8 + c!" eval
s"          r@ 3 + c@ r@ 5 + c!" eval
s"          r@ 2 + c@ r@ 4 + c!" eval
s"          h# 1f and r@ 3 + c!" eval
s"          0 r@ 2 + c!" eval
s"       then" eval
s"    then" eval
s"    r> pkt-len ;" eval
s" : init-atapi-execute-command" eval  ( -- )
 "    "" is-atapi"" get-my-property 0=  if" eval
s"       2drop" eval
s"       ['] translate-atapi-command to execute-command-hook" eval
s"    then ;" eval
s" ' init-atapi-execute-command  to init-execute-command" eval
;
\