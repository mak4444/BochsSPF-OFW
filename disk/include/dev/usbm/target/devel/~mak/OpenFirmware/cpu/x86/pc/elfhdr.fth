purpose: Create an ELF format 

\ This handles several different loader cases

0 value #pheaders
0 value elf-entry
0 value file-offset
0 value elf-addr

\ For GRUB, we want to copy the stuff after the ELF headers and the Multiboot
\ header to the final RAM location (dropin-base), so OFW sees just the dropins.
\ The start address is just after the first dropin header.

dropin-base  h# 20 + to elf-entry   \ Skip OBMD header in RAM copy
1 to #pheaders                      \ The pheader causes the image to be copied to RAM
h# 54 h# 0c +  to file-offset       \ Copy start after pheader + multiboot header (0c)
dropin-base to elf-addr             \ Copy file image directly to dropin-base
[then]

  \ For coreboot running from ROM, we can leave everything in ROM, no need to copy,
  \ so there's no need for a pheader.


create elf-header
  h# 7f c,  char E c,  char L c,  char F c,
  1            c,  \ 4 
  1            c,  \ 5
  1            c,  \ 6
  0            c,  \ 7
  0            l,  \ 8
  0            l,  \ 0x0c
  2            w,  \ 0x10 object file type ET_EXEC
  3            w,  \ 0x12 architecture EM_386
  1            l,  \ 0x14 object file version EV_CURRENT
  elf-entry    l,  \ 0x18 entry point virtual address
  h# 34        l,  \ 0x1c program header file offset
  0            l,  \ 0x20 section header file offset
  0            l,  \ 0x24 flags
  h# 34        w,  \ 0x28 ELF header size
  h# 20        w,  \ 0x2a program header table entry size
  #pheaders    w,  \ 0x2c program header table entry count (one pheader)
  0            w,  \ 0x2e section header table entry size
  0            w,  \ 0x30 section header table entry count
  0            w,  \ 0x32 section header string table index

#pheaders [if]
  1             l,  \ 0x34 entry type PT_LOAD
  file-offset   l,  \ 0x38 file offset
  elf-addr      l,  \ 0x3c vaddr
  elf-addr      l,  \ 0x40 paddr - where to put the bits
  h# ffffffff   l,  \ 0x44 file size   - backpatched later
  h# ffffffff   l,  \ 0x48 memory size - backpatched later
  7             l,  \ 0x4c entry flags RWX
  0             l,  \ 0x50 alignment
                    \ 0x54 End of pheader
[else]
  here  h# 54 h# 34 -  dup allot  erase  \ Pad to make the size consistent
[then]

  \ "Multiboot" header that GRUB looks for
  h# 1BADB002 ,         \ 0x54 signature
  h#        0 ,         \ 0x58 flags
  h# 1BADB002 negate ,  \ 0x5c checksum: -(signature + flags)
                        \ 0x60 End 

\ The total size, including the dropin header, will be h# 80 
here elf-header -  constant /elf-header
