purpose: PCI bus package

\ For the PVI-486AP4 board with the i82425/5 chipset
\ wrong for most hardware...
\ what should this be for a generic system?
\ h# 1800 encode-int  " slave-only" property
\ h# 1e00 encode-int			\ Mask of implemented add-in slots
\ " PCI-1"           encode-string encode+
\ " PCI-2"           encode-string encode+ 
\ " PCI-3"           encode-string encode+
\ " PCI-4"           encode-string encode+

\ For the PicoPower 550/560/570 motherboard
\ wrong for most hardware...
\ what should this be for a generic system?  No such thing
h# 1000 encode-int  " slave-only" property
h# 1800 encode-int			\ Mask of implemented add-in slots
" PCI-1"           encode-string encode+
" PCI-2"           encode-string encode+
" PCI-3"           encode-string encode+

" slot-names" property

also forth definitions


\ unknown hardware, so probe all low slots
\ note: could hang some systems
\ note: some systems might have devices 0..1f

previous definitions

h# 1000.0000 to first-mem		\ Avoid RAM at low addresses
h# 2000.0000 to mem-space-top
h# 0000.8000 to first-io		\ Avoid mappings established by BIOS

defer config-setup
defer config-done

\ Configuration mechanism #1 as defined in the PCI spec.
: config-setup1  ( config-adr -- vaddr )
   \ Bit 31 ("enable") must be 1, bits 30:24 ("reserved") must be 0,
   \ bits 1:0 must be 0.
   dup h# ff.fffc and  h# 8000.0000 or  h# cf8 pl!  ( config-adr )

   3 and  h# cfc +  \ Merge in the byte selector bits
;

\ These versions of config-x@/! are for "configuration mechanism #2"
\ as described in the PCI design guide.  That mechanism is not the
\ recommended one, but several PC PCI chipsets use it.

: config-setup2  ( bus#|dev#|function|reg# -- port-adr )
   \ XXX For now, we ignore the bus number
   \ Write function number and "access config space" key to the config
   \ space enable register
   dup 7 >> h# e and  h# 10 or  h# cf8 pc!  ( bus#|dev#|function#|reg#)
   dup h# ff and  swap d# 11 >> h# f and 8 <<  or  h# c000 or
;
: config-done2  ( -- )  0 h# cf8 pc!  ; 

: config-b@  ( config-adr -- b )  config-setup pc@ config-done  ;
: config-w@  ( config-adr -- w )  config-setup pw@ config-done  ;
: config-l@  ( config-adr -- l )  config-setup pl@ config-done  ;
: config-b!  ( b config-adr -- )  config-setup pc! config-done  ;
: config-w!  ( w config-adr -- )  config-setup pw! config-done  ;
: config-l!  ( l config-adr -- )  config-setup pl! config-done  ;

: mechanism1   ( -- )
   ['] config-setup1 to config-setup
   ['] noop          to config-done
;
mechanism1
: mechanism2   ( -- )
   ['] config-setup2 to config-setup
   ['] config-done2  to config-done
;

\ !!! assumes a device in either slot 0 or slot 1 !!!
\ and that failed reads return -1.
: init  ( -- )
   mechanism1
   0 config-l@  -1 =  h# 800 config-l@  -1 =  and  if
      mechanism2
\      h# 0000.5000  to first-io    \ Avoid on-board SCSI chip's BIOS mapping 
\      " 3,4,5" to pci-probe-list
   then
;

\ Determine the parent interrupt information (the "interrupt line" in PCI
\ parlance) from the child's "interrupt pin" and the child's address,
\ returning "int-line true" if the child's interrupt line register should
\ be set or "false" otherwise.
: assign-int-line  ( phys.hi.func INTx -- irq true )
   \ Reiterate the value that is already in the int line register,
   \ which was presumably placed there by the BIOS
   drop  h# 3c +  config-b@  true
;

\ XXX we should keep a table of already-mapped addresses so that
\ successive map/unmaps of the same address will succeed.


\ The io-base handling really ought to be in the root node, but
\ that would require more changes than I'm willing to do at present.
warning @ warning off
: map-out  ( vaddr size -- )
   over io-base u>=  if  2drop exit  then  ( vaddr size )
   map-out                                 ( )
;   
warning !
