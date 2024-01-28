purpose: Functional interface to HCD driver provided for all usb children

\ All hub drivers must forward all the following methods for their children.
\ A device driver may include only a subset of the methods it needs.

: hcdcallfth 
hex
 " : dma-alloc    ( size -- virt ) "" dma-alloc"" $call-parent ;" eval
 " : dma-free     ( virt size -- ) "" dma-free"" $call-parent  ;" eval
 " : locked?  ( -- flag )   "" locked?"" $call-parent ;" eval

\ Probing support
 " : set-target  ( device -- )   "" set-target"" $call-parent ;" eval
 " : probe-hub-xt  ( -- adr )   "" probe-hub-xt"" $call-parent ;" eval
 " : reprobe-hub-xt  ( -- adr )   "" reprobe-hub-xt"" $call-parent ;" eval
 " : hub-selftest-xt  ( -- adr )   "" hub-selftest-xt"" $call-parent ;" eval
 " : set-pipe-maxpayload  ( size len -- )  "" set-pipe-maxpayload"" $call-parent ;" eval
s" : setup-new-node  ( port speed hub-port hub-dev -- false | port dev xt true )
 "    "" setup-new-node"" $call-parent ;
 " : get-initial-descriptors  ( dev -- )  "" get-initial-descriptors"" $call-parent ;" eval
 " : refresh-desc-bufs  ( dev -- )   "" refresh-desc-bufs"" $call-parent ;" eval
 " : get-cfg-desc  ( adr idx -- actual )   "" get-cfg-desc"" $call-parent ;" eval


\ Control pipe operations
s" : control-get" eval  ( adr len idx value rtype req -- actual usberr )
 "    "" control-get"" $call-parent ;" eval
s" : control-set" eval  ( adr len idx value rtype req -- usberr )
 "    "" control-set"" $call-parent ;" eval
s" : control-set-nostat" eval  ( adr len idx value rtype req -- usberr )
 "  "" control-set-nostat"" $call-parent ;" eval
s" : get-desc" eval  ( adr len lang didx dtype rtype -- actual usberr )
 "    "" get-desc"" $call-parent ;" eval
s" : get-status" eval  ( adr len intf/endp rtype -- actual usberr )
 "    "" get-status"" $call-parent ;" eval
s" : set-config" eval  ( cfg -- usberr )
 "    "" set-config"" $call-parent ;" eval


 " : set-interface  ( intf alt -- usberr )  "" set-interface"" $call-parent ;" eval
s" : clear-feature" eval  ( intf/endp feature rtype -- usberr )
 "    "" clear-feature"" $call-parent ;" eval

s" : set-feature" eval  ( intf/endp feature rtype -- usberr )
 "    "" set-feature"" $call-parent ;" eval

 " : unstall-pipe  ( pipe -- )  "" unstall-pipe"" $call-parent  ;" eval

\ alias unstall-pipe unstall-pipe 

s"  alias bulk-in bulk-in-m" eval
s"  alias bulk-out bulk-out-m" eval
;


\ Bulk pipe operations
: bulk-in-m  ( buf len pipe -- actual usberr )
   " bulk-in" $call-parent
;

: bulk-out-m  ( buf len pipe -- usberr )
   " bulk-out" $call-parent
;



: begin-bulk-in  ( buf len pipe -- )
   " begin-bulk-in" $call-parent
;
: bulk-in?  ( -- actual usberr )
   " bulk-in?" $call-parent
;
: restart-bulk-in  ( -- )
   " restart-bulk-in" $call-parent
;
: end-bulk-in  ( -- )
   " end-bulk-in" $call-parent
;
: set-bulk-in-timeout  ( t -- )
   " set-bulk-in-timeout" $call-parent
;
: bulk-in-ready?  ( -- false | error true | buf len 0 true )
   " bulk-in-ready?" $call-parent
;

: begin-in-ring  ( /buf #bufs pipe -- )
   " begin-in-ring" $call-parent
;
\ : end-in-ring     " end-in-ring" $call-parent  ;
: begin-out-ring  ( /buf #bufs pipe -- )
   " begin-out-ring" $call-parent
;
: end-out-ring   ( -- )
   " end-out-ring" $call-parent
;
: send-out  ( adr len -- qtd )
   " send-out" $call-parent
;
: wait-out  ( qtd -- error? )
   " wait-out" $call-parent
;

\ Interrupt pipe operations
: begin-intr-in  ( buf len pipe interval -- )
   " begin-intr-in" $call-parent
;
: intr-in?  ( -- actual usberr )
   " intr-in?" $call-parent
;
: restart-intr-in  ( -- )
   " restart-intr-in" $call-parent
;
: end-intr-in  ( -- )
   " end-intr-in" $call-parent
;
: reset-bulk-toggles  ( bulk-in-pipe bulk-out-pipe -- )
   " reset-bulk-toggles" $call-parent
;

: reset?  ( -- flag )
   " reset?" $call-parent
;

headers
