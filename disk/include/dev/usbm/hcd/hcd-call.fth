purpose: Functional interface to HCD driver provided for all usb children

\ All hub drivers must forward all the following methods for their children.
\ A device driver may include only a subset of the methods it needs.

hex
external

: dma-alloc    ( size -- virt )              " dma-alloc" $call-parent    ;
: dma-free     ( virt size -- )              " dma-free" $call-parent     ;

: locked?  ( -- flag )
   " locked?" $call-parent
;

\ Probing support
: set-target  ( device -- )
   " set-target" $call-parent
;
: probe-hub-xt  ( -- adr )
   " probe-hub-xt" $call-parent
;
: reprobe-hub-xt  ( -- adr )
   " reprobe-hub-xt" $call-parent
;
: hub-selftest-xt  ( -- adr )
   " hub-selftest-xt" $call-parent
;
: set-pipe-maxpayload  ( size len -- )
   " set-pipe-maxpayload" $call-parent
;
: setup-new-node  ( port speed hub-port hub-dev -- false | port dev xt true )
   " setup-new-node" $call-parent
;
: get-initial-descriptors  ( dev -- )
   " get-initial-descriptors" $call-parent
;
: refresh-desc-bufs  ( dev -- )
   " refresh-desc-bufs" $call-parent
;
: get-cfg-desc  ( adr idx -- actual )
   " get-cfg-desc" $call-parent
;


\ Control pipe operations
: control-get  ( adr len idx value rtype req -- actual usberr )
   " control-get" $call-parent  
;
: control-set  ( adr len idx value rtype req -- usberr )
   " control-set" $call-parent
;
: control-set-nostat  ( adr len idx value rtype req -- usberr )
   " control-set-nostat" $call-parent
;
: get-desc  ( adr len lang didx dtype rtype -- actual usberr )
   " get-desc" $call-parent
;
: get-status  ( adr len intf/endp rtype -- actual usberr )
   " get-status" $call-parent
;
: set-config  ( cfg -- usberr )
   " set-config" $call-parent
;


: set-interface  ( intf alt -- usberr )
   " set-interface" $call-parent
;
: clear-feature  ( intf/endp feature rtype -- usberr )
   " clear-feature" $call-parent
;

: set-feature  ( intf/endp feature rtype -- usberr )
   " set-feature" $call-parent
;

: unstall-pipe  ( pipe -- )  " unstall-pipe" $call-parent  ;

\ alias unstall-pipe unstall-pipe 

 alias bulk-in bulk-in-m
 alias bulk-out bulk-out-m

[ifdef] mmo

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
[then]
