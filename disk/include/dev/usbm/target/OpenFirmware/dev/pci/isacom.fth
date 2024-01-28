purpose: Create COM port nodes

[ifndef] no-com1-node
0 0  " i3f8"  " /isa"  begin-package
[ifdef] PREP
   4 encode-int                          " interrupts" property
[else]
   4 encode-int  3 encode-int encode+    " interrupts" property
[then]

   \ XXX The SuperIO data sheet implies that the clock rate is 24MHz/13, which
   \ is 1,846,153, while the ARC config data says 1,843,200.  The difference
   \ accounts for the 0.2% (actually .16%) error mentioned in the data sheet.
   \ Until we can determine whether or not NT can handle the truth, we will
   \ fudge the data and say it's 1,843,200
   \ d# 1846153 encode-int " clock-frequency" property
   d# 1843200 encode-int " clock-frequency" property
\eof
\   fload ${BP}/dev/ns16550a.fth
S" OpenFirmware/dev/16550pkg/ns16550p.fth"  INCLUDED
S" OpenFirmware/dev/16550pkg/isa-int.fth"  INCLUDED
end-package

: com1  ( -- adr len )  " com1"  ;  ' com1 to fallback-device

: use-com1  ( -- )
   " com1" " input-device" $setenv
   " com1" " output-device" $setenv
;
[then]

[ifndef] no-com2-node
0 0  " i2f8"  " /isa"  begin-packagez
[ifdef] PREP
   3 encode-int                          " interrupts" property
[else]
   3 encode-int  3 encode-int encode+    " interrupts" property
[then]

   d# 1843200 encode-int " clock-frequency" property
\   fload ${BP}/dev/ns16550a.fth

S" OpenFirmware/dev/16550pkg/ns16550p.fth"  INCLUDED
S" OpenFirmware/dev/16550pkg/isa-int.fth"  INCLUDED

end-package

: com2  ( -- adr len )  " com2"  ;
[then]
