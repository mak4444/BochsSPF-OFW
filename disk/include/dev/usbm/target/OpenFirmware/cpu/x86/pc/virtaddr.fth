purpose: Defines Open Firmware virtual address space

\ Low RAM
h#     580 constant gdt-pa   \ Above the BDA, below the MBR area at 600
h#      80 constant gdt-size

h#    1000 constant mem-info-pa
h#  9.fc00 constant 'ebda    \ Extended BIOS Data Area, which we co-opt for our

[ifdef] virtual-mode
h#    2000 constant pdir-pa
h#    3000 constant pt-pa
h# ff80.0000 value fw-virt-base
h# 0040.0000 value fw-virt-size
[else]
fw-pa value fw-virt-base
0 value fw-virt-size
[then]
