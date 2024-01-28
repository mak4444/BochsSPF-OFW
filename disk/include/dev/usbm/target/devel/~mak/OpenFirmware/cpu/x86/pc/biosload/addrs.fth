purpose: Establish address and I/O configuration definitions

\ Dropin-base is where the set of dropin modules, the verbatim
\ image of what is stored in ROM or on disk, ends up in memory.
\ If OFW is in FLASH, dropin-base can just be the FLASH address.
\ If OFW is pulled in from disk, dropin-base is where the very
\ early startup code - the first few instructions in the image -
\ copies it to get it out of the way of things like OS load areas.


\needs dropin-base  h# 1980000 constant dropin-base
\needs dropin-size  h#   80000 constant dropin-size
\needs ResetBase    dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in ROM

[ifndef] fw-pa
\ This is considerably more memory than Open Firmware needs
\ on platforms where you have a well bounded set of I/O devices.

\needs fw-pa      h# 1a0.0000 constant fw-pa     \ OFW dictionary location
\needs /fw-ram    h#  20.0000 constant /fw-ram

\needs heap-base  h# 1c0.0000 constant heap-base \ Dynamic allocation heap
\needs heap-size  h#  20.0000 constant heap-size

\needs dma-base   h# 1e0.0000 constant dma-base  \ DMA heap
\needs dma-size   h#  20.0000 constant dma-size
[then]

\ Where OFW initially loads an OS that is is going to boot

h# 1000000 constant def-load-base      \ Convenient for initrd

\ fload ${BP}/cpu/x86/pc/virtaddr.fth

h#        3 constant pte-control	\ Page table entry attributes
