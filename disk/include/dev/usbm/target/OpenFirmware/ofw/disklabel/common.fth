purpose: Data that is common to all format recognizers

-1 instance value size-low
-1 instance value size-high
0 instance value partition-type
h# 81 constant minix-type
h# 83 constant ext2fs-type
h# a5 constant ufs-type
h# 96 constant iso-type
h# ee constant gpt-type

0 value ufs-partition
0 0 instance 2value partition-name$
0 instance value #part

0 instance value /sector  \ Set in open by calling parent's block-size method
0 instance value sector-buf

0 instance value sector-offset

: sector-alloc  ( -- )  /sector alloc-mem to sector-buf  ;
: sector-free  ( -- )  sector-buf /sector free-mem  ;

\ For ISO-9660 CD-ROMs, ISO-9660 flash or hard drives, and GPT
: read-hw-sector  ( sector# -- )
   sector-offset +  /sector um*  " seek" $call-parent  abort" Seek failed"
   sector-buf /sector  " read" $call-parent  /sector <> abort" Read failed"
;
\ For everything else
: read-sector  ( sector# -- )
   sector-offset +  h# 200 um*  " seek" $call-parent  abort" Seek failed"
   sector-buf h# 200  " read" $call-parent  h# 200 <> abort" Read failed"
;
