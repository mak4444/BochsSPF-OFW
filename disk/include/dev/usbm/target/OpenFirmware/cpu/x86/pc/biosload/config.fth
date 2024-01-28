purpose: Establish configuration definitions

\ --- The environment that "boots" OFW ---
\ - Image Format - Example Media - previous stage bootloader

\ - ELF format w/ Multiboot signature - various media - GRUB
create grub-loaded

create debug-startup
\ create serial-console
create resident-packages
create addresses-assigned  \ Don't reassign PCI addresses
\ create virtual-mode
\ create use-root-isa
create use-timestamp-counter
create use-pci-isa
create use-isa-ide
create use-ega
create use-elf
\ create use-ne2000
create use-watch-all
create use-null-nvram
\ create no-floppy-node

