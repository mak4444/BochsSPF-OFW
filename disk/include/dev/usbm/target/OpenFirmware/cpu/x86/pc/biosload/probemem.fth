purpose: Create memory node properties and lists

dev /memory

: cmos@   ( offset -- byte )  h# 70 pc!  h# 71 pc@  ;
: /ram  ( -- #bytes )
   mem-info-pa la1+ l@ 

\   \ The BIOS puts the number of kilobytes of extended memory in CMOS memory
\   \ locations 30,31. The total memory is that plus the low meg.
\   h# 30 cmos@  h# 31 cmos@  bwjoin    ( #kbytes-extended )
\   d# 1024 +                           ( #kbytes-total )
\   d# 1024 *                           ( #bytes )
;

: release-range  ( start-adr end-adr -- )  over - release  ;

: probe  ( -- )
   0 /ram  reg   \ Report extant memory

   \ Put h# 10.0000-1f.ffff and 28.0000-memsize in pool,
   \ reserving 0..10.0000 for the firmware
   \ and 20.0000-27.ffff for the "flash"

\   h#  0.0000  h# 02.0000  release   \ A little bit of DMA space, we hope
\   h# 10.0000  h# 0f.ffff  release
\   h# 28.0000  h# 80.0000 h# 28.0000 -  release

\ Release some of the first meg, between the page tables and the DOS hole,
\ for use as DMA memory.
   mem-info-pa 2 la+ l@   h# a.0000  release-range  \ Below DOS hole

[ifdef] virtual-mode
   h# 10.0000  dropin-base over -  release
   dropin-base dropin-size +  mem-info-pa la1+ l@  over -  release

[else]
   fw-pa h# 10.0000 u>  if
      h# 10.0000   fw-pa over -  release
      fw-pa /fw-ram +  heap-base heap-size +  umax  /ram  release
   then

\   dropin-base /ram u<  if
\      dropin-base dropin-size +  /ram over -  release
\   then
[then]
;

device-end

also forth definitions
stand-init: Probing memory
   " probe" memory-node @ $call-method  
;
previous definitions