purpose: Generic HCD Driver

hex


d#  50 constant nodata-timeout
d# 500 constant data-timeout

: int-property  ( n name$ -- )     rot encode-int  2swap property  ;
: str-property  ( str$ name$ -- )  2swap encode-string 2swap  property  ;


\ ---------------------------------------------------------------------------
\ Common variables
\ ---------------------------------------------------------------------------

false value debug?

\ Setup and descriptor DMA data buffers
0 value setup-buf			\ SETUP packet buffer
0 value setup-buf-phys
0 value cfg-buf				\ Descriptor packet buffer
0 value cfg-buf-phys

: alloc-dma-buf  ( -- )
   setup-buf 0=  if
      /dr dma-alloc dup to setup-buf
      /dr true dma-map-in to setup-buf-phys
   then
   cfg-buf 0=  if
      /cfg dma-alloc dup to cfg-buf
      /cfg true dma-map-in to cfg-buf-phys
   then
;
: free-dma-buf  ( -- )
   setup-buf  if
      setup-buf setup-buf-phys /dr dma-map-out
      setup-buf /dr dma-free
      0 to setup-buf 0 to setup-buf-phys
   then
   cfg-buf  if
      cfg-buf cfg-buf-phys /cfg dma-map-out
      cfg-buf /cfg dma-free
      0 to cfg-buf 0 to cfg-buf-phys
   then
;



0 value locked?  \ Interrupt lockout for USB keyboard get-data?
: lock    ( -- )  true  to locked?  ;
: unlock  ( -- )  false to locked?  ;

\ ---------------------------------------------------------------------------
\ Common routines
\ ---------------------------------------------------------------------------

\ XXX Room for improvement: keep tab of hcd-map-in's to improve performance.
: hcd-map-in   ( virt size -- phys )  false dma-map-in  ;
: hcd-map-out  ( virt phys size -- )  dma-map-out  ;


: $=  ( adr len adr len -- =? )
   rot tuck <> if    
      3drop false exit 
   then  comp 0= 
; 

: log2  ( n -- log2-of-n )
   0  begin        ( n log )
      swap  2/     ( log n' )
   ?dup  while     ( log n' )
      swap 1+      ( n' log' )
   repeat          ( log )
;
: exp2  ( n -- 2**n )  1 swap 0 ?do  2*  loop  ;
: interval  ( interval -- interval' )  log2 exp2  ;

: 3dup   ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )  2 pick 2 pick 2 pick  ;
: 3drop  ( n1 n2 n3 -- )  2drop drop  ;

: 4dup   ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 n3 n4 )  2over 2over  ;
: 4drop  ( n1 n2 n3 n4 -- )  2drop 2drop  ;

: 5dup   ( n1 n2 n3 n4 n5 -- n1 n2 n3 n4 n5 n1 n2 n3 n4 n5 )
   4 pick 4 pick 4 pick 4 pick 4 pick
;
: 5drop  ( n1 n2 n3 n4 n5 -- )  2drop 3drop  ;

\ ---------------------------------------------------------------------------
\ Exported methods
\ ---------------------------------------------------------------------------

external


: debug-on  ( -- )  true to debug?  ;

: decode-unit-m  ( addr len -- interface port )  parse-2int  ;
: encode-unit-m  ( interface port -- adr len )
   >r <# u#s drop ascii , hold r> u#s u#>	\ " port,interface"
;


