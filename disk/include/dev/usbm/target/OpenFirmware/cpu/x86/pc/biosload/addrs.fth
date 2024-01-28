purpose: Establish address and I/O configuration definitions

\ Dropin-base is where the set of dropin modules, the verbatim
\ image of what is stored in ROM or on disk, ends up in memory.
\ If OFW is in FLASH, dropin-base can just be the FLASH address.
\ If OFW is pulled in from disk, dropin-base is where the very
\ early startup code - the first few instructions in the image -
\ copies it to get it out of the way of things like OS load areas.

[ifdef] coreboot-loaded
  [ifdef] coreboot-qemu
    \ when running in qemu OFW is not in ROM but loaded to RAM by elfboot
    h# 198.0080 constant dropin-base  \ Location of payload in RAM
    dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in RAM
  [else]
    h# fff8.0000 constant dropin-base  \ Location of payload in FLASH
    dropin-base h# 80 + h# 20 +  constant ResetBase	\ Location of "reset" dropin in ROM
  [then]
  h#   08.0000 constant dropin-size
[then]

[ifdef] virtualbox-loaded
  h#   f0.0000 constant dropin-base  \ Location of payload in RAM
  h#   08.0000 constant dropin-size
  h#    1.0000 constant dma-base  \ DMA heap
  h#    8.0000 constant dma-size

[then]

[ifdef] preof-loaded
h# 2000.0000 constant ramsize
h# fff8.0020 constant dropin-base  \ Location of payload in ROM
h#   08.0000 constant dropin-size
[then]

[ifdef] via-demo
\ Don't assume a lot of memory (256M for most versions, 128M for a few)
\needs fw-pa      h#  e00.0000 constant fw-pa     \ OFW dictionary location
\needs /fw-ram    h#   20.0000 constant /fw-ram

\needs heap-base  h#  e20.0000 constant heap-base \ Dynamic allocation heap
\needs heap-size  h#   20.0000 constant heap-size

\needs dma-base   h#  e40.0000 constant dma-base  \ DMA heap
\needs dma-size   h#   20.0000 constant dma-size

                  h#  e60.0000 constant dropin-base  \ Location of payload in RAM
                  h#   08.0000 constant dropin-size
[then]

\needs dropin-base  h# 198.0000 constant dropin-base
\needs dropin-size  h#   8.0000 constant dropin-size
\needs ResetBase    dropin-base h# 20 +  constant ResetBase	\ Location of "reset" dropin in ROM

[ifdef] syslinux-loaded
\ This fits nicely with my VIA board that has "only" 256 MiB of memory
\needs fw-pa      h# 1d80.0000 constant fw-pa     \ OFW dictionary location
\needs /fw-ram    h#   20.0000 constant /fw-ram

\needs heap-base  h# 1da0.0000 constant heap-base \ Dynamic allocation heap
\needs heap-size  h#   20.0000 constant heap-size

\needs dma-base   h# 1dc0.0000 constant dma-base  \ DMA heap
\needs dma-size   h#   20.0000 constant dma-size
[then]

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

h# 100.0000 constant def-load-base      \ Convenient for initrd

