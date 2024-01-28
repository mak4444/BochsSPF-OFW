~mak/CompIF1.f 
REQUIRE DEFINED? ~mak/lib/ifdef.f
REQUIRE CASE-INS	lib/ext/caseins.f
CASE-INS ON
REQUIRE CASE ~mak/case.f
REQUIRE FL> ~mak/fl.f 
[IFNDEF] IMAGE-BEGIN :  IMAGE-BEGIN ['] DUP 1000 - ; [THEN]
[IFNDEF] F7_ED : F7_ED ; [THEN]
[IFNDEF] DUP>R : DUP>R S" DUP >R" EVALUATE ; IMMEDIATE [THEN]
[IFNDEF] /STRING : /STRING DUP >R - SWAP R> + SWAP ; [THEN]


: f[ifndef] f7_ed
 postpone   [ifndef]
;
 
: M_@ @ ;
: M_! ! ;
: MOVER OVER ;
: M_- - ;

CASE-INS ON
VARIABLE caps

: >> RSHIFT ;
: << LSHIFT ;
$1A00280  constant forthusadr

: ALIAS         ( xt -<name>- ) \ make another 'name' for 'xt'
    HEADER
   PARSE-NAME SFIND DUP 0= THROW
  1 = IF IMMEDIATE THEN
    0xE9 C, HERE CELL+ - ,  ;

ALIAS (s        (
                 
ALIAS purpose:  \
ALIAS 64\       \
ALIAS id:       \
ALIAS copyright: \
ALIAS is        TO 
ALIAS DEFER     VECT 
ALIAS ]-H       ]
: >body-t 4 + ;

: wljoin (s w.low w.high -- l )  10 <<  swap  0xffff and  or  ;
: lwsplit (s l -- w.low w.high )  \ split a long into two words
   dup  0xffff and  swap 0x10 >>  
;

: octal 0x8 BASE ! ;


: >= < 0= ;
: <= > 0= ;

[IFNDEF] BETWEEN : BETWEEN 1+ WITHIN ;
[THEN]

C" UPPER" FIND NIP 0=
  [IF] : UPPER ( A L -- )
\        SWAP CharUpperBuff drop
         OVER + SWAP
         ?DO I C@ DUP [CHAR] Z U>
            IF  0xDF AND
            THEN  I C!
         LOOP ;
  [THEN]

' UPPER TO V_UPPER

: /N CELL ;

defer do-entercode
' noop is do-entercode

WARNING 0!
REQUIRE TH_H-	~mak/lib/THERE/RECOM.F

ALIAS @-t       @

~mak/OpenFirmware/lib/th.fth

: HH# 
  POSTPONE H# ; IMMEDIATE
OpenFirmware/forth/kernel/splits.fth 
OpenFirmware/forth/lib/split.fth 
0x1000000 VALUE CODE-SIZE 
0 VALUE DATA-SIZE

 CODE-SIZE  DATA-SIZE +
 VALUE IMG_SIZE
OpenFirmware/cpu/x86/assem.fth
REQUIRE INCLUDED_AL	~mak/lib/THERE/mlist.f

: extend-meta-assembler  ( -- )  also assembler  definitions  ;

: meta-asm[ ALSO assembler  ; IMMEDIATE
: ]meta-asm PREVIOUS  ; IMMEDIATE

4 VALUE #align
4 VALUE #acf-align

: align-t ( -- )
   begin   here #align  1- and   while   0 c,  repeat ;

: acf-align-t align-t ;

VARIABLE csp          \ for stack position error checking

IMG_SIZE ALLOCATE THROW
 VALUE RAMbase
0 VALUE T-ORG

~mak/MWF/tc.4

~mak/OpenFirmware/cpu/x86/pc/biosload/addrs.fth
~mak/OpenFirmware/cpu/x86/pc/elfhdr.fth 

 0x100000 ALLOCATE THROW DP !

~mak/OpenFirmware/cpu/x86/code.fth 

: meta FORTH ;

 ' NOOP TO <PRE> 
[DEFINED] DBG_STOP [IF]  DBG_STOP [THEN]

fw-pa TO T-ORG
T-ORG IMG_SIZE + TO  MAX_HERE
\ 0x100000 ALLOCATE THROW DP !
fw-pa RAMbase - TO TH_H- 

fw-pa T-DP M_!

  1 TO YDP_FL
  1 ALIGN-BYTES !

><DP

' MTHERE? TO THERE?

 0x4020 4 / 0,S

HEX \  ~mak/yyyy0.4 
 ' INTERPRET_TT &INTERPRET !
\ cr .( <) .s .( >) cr  abort


fw-pa forthusadr !
forthusadr FORTH-WORDLIST VOC_SET

0 is is_disable


[ifdef] #user-init
#user-init
[else]
0
[then]
    #user-t !


OpenFirmware/cpu/x86/kkkkk.f
0 to ttcc
 S" OpenFirmware/cpu/x86/kerncode.fth"  INCLUDED_AL
' (is) IS 'isvalue  dovalue IS vdovalue
' (is) IS 'isdefer  dodefer IS vdodefer
' isuser  IS 'isuser  douser IS vdouser


 S" OpenFirmware/forth/kernel/uservars.fth"  INCLUDED_AL
 S" OpenFirmware/forth/kernel/double.fth"  INCLUDED_AL
 S" OpenFirmware/cpu/x86/kernrel.fth"  INCLUDED_AL

 S" OpenFirmware/forth/kernel/kernel.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/struct.fth"  INCLUDED_AL
doestarget @ to dofield


' also #forward also
' previous #forward previous
' definitions #forward definitions
' only #forward only
root
' get-current #forward get-current
' get-order  #forward get-order
' previous #forward previous
' definitions #forward definitions
' also #forward also
' only #forward only
' forth #forward forth

only forth

: note-string  ( adr len -- adr len )  ;

 S" OpenFirmware/forth/kernel/sysio.fth"  INCLUDED_AL

 S" OpenFirmware/cpu/x86/syscall.fth"  INCLUDED_AL

 S" OpenFirmware/cpu/x86/boot.fth"  INCLUDED_AL

 OpenFirmware/cpu/x86/finish.fth

' DEFINED?-T  IS [DEFINED]
' isdefer IS 'isdefer 
' isvalue IS 'isvalue

create resident-packages
 ' isvalue IS 'isvalue

 S" OpenFirmware/forth/lib/brackif.fth"  INCLUDED_AL

true
value assembler?		\  5280 bytes
true  value forth-debug?	\  1064 bytes

' 0, TO VOC0,

0 TO VARISUS?

'BASE ' BASE TEXEC_SET 

 S" OpenFirmware/forth/lib/romable.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/hidden.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/th.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/ansiterm.fth"  INCLUDED_AL

 S" OpenFirmware/forth/kernel/splits.fth"  INCLUDED_AL

 S" OpenFirmware/forth/kernel/endian.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/strings.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/patch.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/cirstack.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/needs.fth"  INCLUDED_AL
-1 to VARISUS?
 S" OpenFirmware/forth/lib/suspend.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/util.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/format.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/stringar.fth"  INCLUDED_AL
 doestarget @ to  do-string-array
 S" OpenFirmware/forth/lib/substrin.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/strcase.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/parses1.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/dump.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/words.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/decomp.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/fileed.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/screened.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/editcmd.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/unixedit.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/cmdcpl.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/fcmdcpl.fth"  INCLUDED_AL
 S" OpenFirmware/forth/lib/sift.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/array.fth"  INCLUDED_AL
 doestarget @ to  do-array

 S" OpenFirmware/forth/lib/linklist.fth"  INCLUDED_AL
doestarget @ to donodetype
 S" OpenFirmware/forth/lib/lex.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/initsave.fth"  INCLUDED_AL

caps on

 S" OpenFirmware/cpu/x86/asmspec.fth"  INCLUDED_AL

 S" OpenFirmware/cpu/x86/decompm.fth"  INCLUDED_AL

: be-l,  ( l -- )  here DROP  here  4 allot  be-l!  ;

code cpuid@
 ax pop
 cpuid
 dx push
 cx push
 bx push
 ax push
c;

 S" OpenFirmware/cpu/x86/disassem.fth"  INCLUDED_AL
 S" OpenFirmware/cpu/x86/objsup.fth"  INCLUDED_AL

codetarget to action-name-target

 S" OpenFirmware/forth/lib/objects.fth"  INCLUDED_AL

 S" OpenFirmware/cpu/x86/cpustate.fth"  INCLUDED_AL
 S" OpenFirmware/cpu/x86/register.fth"  INCLUDED_AL

S" OpenFirmware/forth/lib/caller.fth"  INCLUDED_AL
S" OpenFirmware/forth/lib/rstrace.fth"  INCLUDED_AL

 S" OpenFirmware/cpu/x86/debugm.fth"  INCLUDED_AL

 S" OpenFirmware/forth/lib/debug.fth"  INCLUDED_AL

defer restart  ( -- )

false value standalone?

code call  ( address -- )   dx pop   dx call  c;

S" OpenFirmware/cpu/x86/occhksum.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/ofw/core/ofwcore.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/ofw/core/ofwfw.fth"  INCLUDED_AL ??4th

' stand-init  to 'stand-init0

 S" OpenFirmware/ofw/core/memops.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/ofw/core/mmuops.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/cpu/x86/segments.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/cpu/x86/dt.fth"  INCLUDED_AL ??4th

$40 TO flg-int

 S" OpenFirmware/ofw/termemu/datatype.fth"  INCLUDED_AL  ??4th
action-adr-t to dotermemu-array \ mmo

dev /packages
   new-device
      " terminal-emulator" device-name
      0 0  encode-bytes  " iso6429-1983-colors"  property
 S" OpenFirmware/ofw/termemu/framebuf.fth"  INCLUDED_AL \ ??4th
 S" OpenFirmware/ofw/termemu/font.fth"  INCLUDED_AL \ ??4th
 S" OpenFirmware/ofw/termemu/fwritstr.fth"  INCLUDED_AL \ ??4th
   finish-device
device-end

 S" OpenFirmware/ofw/termemu/install.fth"  INCLUDED_AL  ??4th

S" OpenFirmware/ofw/core/bootparm.fth"  INCLUDED_AL  ??4th

S" OpenFirmware/ofw/core/callback.fth"  INCLUDED_AL  ??4th

S" OpenFirmware/ofw/core/deblock.fth"  INCLUDED_AL  ??4th

S" OpenFirmware/ofw/core/instcons.fth"  INCLUDED_AL  ??4th

S" OpenFirmware/ofw/core/banner.fth"  INCLUDED_AL  ??4th

S" OpenFirmware/cpu/x86/regacc.fth"  INCLUDED_AL ??4th

: external ;

alias name device-name

: model  ( adr len -- ) 2drop ; \ " model"  string-property  ;
: reg    ( adr space size -- )  encode-reg  " reg"   property  ;


S" OpenFirmware/ofw/fs/fatfs/setup.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/leops.fth"  INCLUDED_AL \  ??4th

S" OpenFirmware/ofw/fs/fatfs/dosdate.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/bpb.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/diskio.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/dirent.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/device.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/rwclusts.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/fat.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/lookup.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/fh.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/read.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/write.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/create.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/makefs.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/sysdos.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/enumdir.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/methods.fth"  INCLUDED_AL \  ??4th
 end-support-package

S" OpenFirmware/ofw/disklabel/gpttools.fth"  INCLUDED_AL ??4th

\ 4 50 * ualloc drop \ mmo

support-package: disk-label

S" OpenFirmware/ofw/disklabel/common.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/fs/fatfs/partition.fth"  INCLUDED_AL \  ??4th
: ext2? 0 ; \ S" OpenFirmware/ofw/fs/ext2fs/partition.fth"  INCLUDED_AL \  ??4th

S" OpenFirmware/ofw/disklabel/gpt.fth"  INCLUDED_AL \  ??4th
S" OpenFirmware/ofw/disklabel/methods.fth"  INCLUDED_AL \  ??4th
end-support-package

S" OpenFirmware/forth/lib/pattern.fth"  INCLUDED_AL \  ??4th

 S" OpenFirmware/ofw/core/filecmds.fth"  INCLUDED_AL \  ??4th

 S" OpenFirmware/cpu/x86/pc/biosload/config.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/cpu/x86/pc/biosload/addrs.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/cpu/x86/pc/virtaddr.fth"  INCLUDED_AL ??4th

: headerless ;  : headers  ;  : headerless0 ;

' (quit) to quit

: RAMbase  ( -- adr )  fw-virt-base  ;
: RAMtop  ( -- adr )  RAMbase /fw-ram +  ;

h# 00.0000 value    dp-loc      \ Set in patchboot
: stacktop    ( -- adr )  RAMtop  ;
: dict-limit  ( -- adr )  RAMtop  h# 06.0000 -  ;

stacktop  user-size - ( fw-virt-base - ) constant prom-main-task        \ user a

0 value load-limit      \ Top address of area at load-base
' 2drop to sync-cache


[ifdef] serial-console
" com1" ' output-device set-config-string-default
" com1" ' input-device set-config-string-default
[then]


 h# 1000 to pagesize
 d# 12   to pageshift	

dev /
1 encode-int  " #address-cells"  property
1 encode-int  " #size-cells"     property

" PC" encode-string  " architecture" property

device-end

 S" OpenFirmware/ofw/core/memlist.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/ofw/core/allocph1.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/cpu/x86/pc/rootnode.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/cpu/x86/pc/biosload/probemem.fth"  INCLUDED_AL ??4th

: call32 ;

: release-load-area  ( boundary-adr -- )  drop  ;

: (initial-heap)  ( -- adr len )  heap-base heap-size  ;

' (initial-heap) is initial-heap

\ " /openprom" find-device
   " FirmWorks,3.0" encode-string " model" property
device-end

 S" OpenFirmware/cpu/x86/pc/isaio.fth"  INCLUDED_AL ??4th


 S" OpenFirmware/dev/pci/configm1.fth"  INCLUDED_AL ??4th

vocabulary usb_lib_o
vocabulary usb_lib_e
vocabulary usb_lib_u
vocabulary usb_storage

defer usbaliase

defer usbaevalu
defer usbaevale
defer usbaevalo

0 0  " "  " /" \ begin-package
   select-dev 
 new-device
  set-args
 current-device-t to pci-device
 S" OpenFirmware/cpu/x86/pc/mappci.fth"  INCLUDED_AL

 S" OpenFirmware/dev/pcibus.fth"  INCLUDED_AL

   0 0  " addresses-preassigned" property

 S" OpenFirmware/cpu/x86/pc/biosload/pcinode.fth"  INCLUDED_AL

end-package

stand-init: PCI host bridge
   " /pci" " init" execute-device-method drop
;

 S" OpenFirmware/dev/pciprobe.fth"  INCLUDED_AL  ??4th
 S" OpenFirmware/cpu/x86/tsc.fth"  INCLUDED_AL  ??4th

0 0 " " " /" begin-package
 S" OpenFirmware/dev/egatext.fth"  INCLUDED_AL
end-package
devalias screen /ega-text

 S" OpenFirmware/cpu/x86/pc/moveisa.fth"  INCLUDED_AL
 S" OpenFirmware/dev/pci/isa.fth"  INCLUDED_AL
current-device-t to isa-dev-t
' set-args1 >set-args

S" OpenFirmware/dev/pci/i8259.fth"  INCLUDED_AL

 ' set-args2 >set-args

S" OpenFirmware/dev/pci/i8254.fth"  INCLUDED_AL

 0 t-my-self ! 0 t-my-self $c + ! 

S" OpenFirmware/dev/i8254.fth"  INCLUDED_AL
finish-device

S" OpenFirmware/dev/pci/isamisc.fth"  INCLUDED_AL

S" OpenFirmware/cpu/x86/pc/isatick.fth"  INCLUDED_AL

S" OpenFirmware/dev/16550pkg/16550.fth"  INCLUDED_AL
isa-dev-t to current-device-t

S" OpenFirmware/dev/pci/isacom.fth"  INCLUDED_AL


 $3f8 t-my-self ! 1 t-my-self $c + ! 


S" OpenFirmware/dev/16550pkg/ns16550p.fth"  INCLUDED_AL
S" OpenFirmware/dev/16550pkg/isa-int.fth"  INCLUDED_AL

: com1  ( -- adr len )  " com1"  ;  ' com1 to fallback-device

: use-com1  ( -- )
   " com1" " input-device" $setenv
   " com1" " output-device" $setenv
;
isa-dev-t to current-device-t

[ifndef] no-com2-node
0 0  " i2f8"  " /isa"  begin-package
[ifdef] PREP
   3 encode-int                          " interrupts" property
[else]
   3 encode-int  3 encode-int encode+    " interrupts" property
[then]

   d# 1843200 encode-int " clock-frequency" property
\   fload ${BP}/dev/ns16550a.fth

 $2f8 t-my-self ! 1 t-my-self $c + ! 

S" OpenFirmware/dev/16550pkg/ns16550p.fth"  INCLUDED_AL
S" OpenFirmware/dev/16550pkg/isa-int.fth"  INCLUDED_AL

: com2  ( -- adr len )  " com2"  ;

isa-dev-t to current-device-t
 $60 t-my-self ! 1 t-my-self $c + ! 

' set-args3 >set-args

0 0  " i60"  " /isa"  begin-package
1 encode-int  3 encode-int encode+  d# 12 encode-int encode+  3 encode-int encode+  " interrupts" property

S" OpenFirmware/dev/i8042.fth"  INCLUDED_AL

   new-device

   " "  " 0" set-args
 $0 t-my-self ! 0 t-my-self $c + ! 
S" OpenFirmware/dev/pckbd.fth"  INCLUDED_AL

   finish-device
end-package
devalias keyboard /isa/8042/keyboard

' set-args0 >set-args

devalias seriala /isa/serial@i3f8
devalias com1 /isa/serial@i3f8:115200
devalias serialb /isa/serial@i2f8
devalias com2 /isa/serial@i2f8

S" OpenFirmware/cpu/x86/pc/tsccal1.fth"  INCLUDED_AL

0 0  " i1f0" " /isa" begin-package

 $1f0 t-my-self ! 1 t-my-self $c + ! 

  S" OpenFirmware/dev/ide/isaintf.fth"  INCLUDED_AL \ ??4th
  S" OpenFirmware/dev/ide/generic.fth"  INCLUDED_AL \ ??4th

  S" OpenFirmware/dev/ide/atapi.fth"  INCLUDED_AL \ ??4th
  S" OpenFirmware/dev/ide/generic2.fth"  INCLUDED_AL \ ??4th

 2 to max#drives

S" OpenFirmware/dev/ide/onelevel.fth"  INCLUDED_AL \ ??4th

S" OpenFirmware/dev/ide/idedisk.fth"  INCLUDED_AL \ ??4th


\ Create the alias unless it already exists
: $?devalias  ( alias$ value$ -- )
   2over  not-alias?  if  $devalias exit  then  ( alias$ value$ alias$ )
   2drop 4drop
;

: report-pci-fb  ( -- )
   " /pci/display" locate-device 0=  if  ( phandle )
      " open" rot find-method  if        ( xt )
         drop
         " screen" " /pci/display"  $devalias
      then
   then
;

: report-disk  ( -- )
   " /scsi" locate-device  0=  if
      drop
      " scsi" " /scsi"        $devalias
      " disk" " /scsi/disk@0" $devalias
      " c"    " /scsi/disk@0" $devalias
      " d"    " /scsi/disk@1" $devalias
      " e"    " /scsi/disk@2" $devalias
      " f"    " /scsi/disk@3" $devalias
      exit
   then
   " /pci-ide" locate-device  0=  if
      drop
      " disk" " /pci-ide/ide@0/disk@0" $devalias
      " c"    " /pci-ide/ide@0/disk@0" $devalias
      " d"    " /pci-ide/ide@0/disk@1" $devalias
      " e"    " /pci-ide/ide@1/disk@0" $devalias
      " f"    " /pci-ide/ide@1/disk@1" $devalias
      exit
   then
   " /ide" locate-device  0=  if
      drop
      " disk" " /ide@1f0/disk@0" $devalias
      " c"    " /ide@1f0/disk@0" $devalias
      " d"    " /ide@1f0/disk@1" $devalias
      " e"    " /ide@1f0/disk@2" $devalias
      " f"    " /ide@170/disk@0" $devalias
      " g"    " /ide@170/disk@1" $devalias
      " h"    " /ide@170/disk@2" $devalias
      exit
   then
;

S" OpenFirmware/dev/isa/diaguart.fth"  INCLUDED_AL \ ??4th

S" OpenFirmware/forth/lib/sysuart.fth"  INCLUDED_AL ??4th

0 value keyboard-ih
0 value screen-ih

S" OpenFirmware/ofw/core/muxdev.fth"  INCLUDED_AL ??4th

S" OpenFirmware/cpu/x86/pc/reset.fth"  INCLUDED_AL ??4th

\  S" OpenFirmware/cpu/x86/pc/mscal.fth"  INCLUDED_AL ??4th

S" OpenFirmware/cpu/x86/pc/boot.fth"  INCLUDED_AL ??4th

S" OpenFirmware/cpu/x86/pc/egareport.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/cpu/x86/pc/biosload/usb.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/dev/usb2/error.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/pkt-data.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/align.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/pkt-func.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/hcd/hcd.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/hcd/error.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/hcd/dev-info.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/hcd/hcd-call.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/dev/usb2/vendor.fth"  INCLUDED_AL ??4th


 S" OpenFirmware/dev/usb2/hcd/control.fth"  INCLUDED_AL ??4th
 S" OpenFirmware/dev/usb2/hcd/fcode.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/dev/usb2/hcd/device.fth"  INCLUDED_AL ??4th

 S" OpenFirmware/dev/usb2/hcd/probehub.fth"  INCLUDED_AL

S" OpenFirmware/dev/usb2/device/common.fth"  INCLUDED_AL

S" OpenFirmware/dev/usb2/device/storage/scsicom.fth"  INCLUDED_AL

S" OpenFirmware/dev/usb2/device/storage/scsi.fth"  INCLUDED_AL
S" OpenFirmware/dev/usb2/device/storage/atapi.fth"  INCLUDED_AL
S" OpenFirmware/dev/usb2/device/storage/hacom.fth"  INCLUDED_AL
S" OpenFirmware/dev/usb2/device/storage/scsidisk.fth"  INCLUDED_AL

usb_lib_u definitions

 S" OpenFirmware/dev/usb2/hcd/uhci/qhtd.fth"  INCLUDED_AL
 S" OpenFirmware/dev/usb2/hcd/uhci/pci.fth"  INCLUDED_AL
 S" OpenFirmware/dev/usb2/hcd/uhci/uhci.fth"  INCLUDED_AL
 S" OpenFirmware/dev/usb2/hcd/uhci/control.fth"  INCLUDED_AL

 S" OpenFirmware/dev/usb2/hcd/uhci/bulk.fth"  INCLUDED_AL

 S" OpenFirmware/dev/usb2/hcd/uhci/probe.fth"  INCLUDED_AL

: _usbaevalu bulkfth controlfth devicefth probefth probehubfth ;

' _usbaevalu is usbaevalu

usb_lib_o definitions

 S" OpenFirmware/dev/usb2/hcd/ohci/edtd.fth"  INCLUDED_AL
 S" OpenFirmware/dev/usb2/hcd/ohci/ohci.fth"  INCLUDED_AL
 S" OpenFirmware/dev/usb2/hcd/ohci/control.fth"  INCLUDED_AL

: _usbaevalo  controlfth devicefth probehubfth ;

' _usbaevalo is usbaevale

usb_lib_e definitions

 S" OpenFirmware/dev/usb2/hcd/ehci/pci.fth"  INCLUDED_AL

: _usbaliase
\ Configuration space registers
my-address my-space encode-phys
0 encode-int encode+  0 encode-int encode+

\ EHCI operational registers
0 0    my-space  02000010 + encode-phys encode+
0 encode-int encode+  /regs encode-int encode+
" reg" property

s" : set-normal-dev target dup to my-dev to my-real-dev ;" eval
s" ' set-normal-dev to set-my-dev" eval
;
' _usbaliase is usbaliase

S" OpenFirmware/dev/usb2/hcd/ehci/ehci.fth"  INCLUDED_AL
S" OpenFirmware/dev/usb2/hcd/ehci/qhtd.fth"  INCLUDED_AL
S" OpenFirmware/dev/usb2/hcd/ehci/control.fth"  INCLUDED_AL

S" OpenFirmware/dev/usb2/hcd/ehci/bulk.fth"  INCLUDED_AL

S" OpenFirmware/dev/usb2/hcd/ehci/probe.fth"  INCLUDED_AL
S" OpenFirmware/dev/usb2/hcd/ehci/probehub.fth"  INCLUDED_AL

: _usbaevale bulkfth controlfth devicefth probehubfthe probefth probehubfth ;

' _usbaevale is usbaevale

usb_storage definitions

forth definitions
 S" OpenFirmware/cpu/x86/pc/biosload/fw.fth"  INCLUDED_AL ??4th

prom-cold-code origin 5 + -  origin 1+ !

$20	$22 ORIGIN + C!
$FFAD	$20 ORIGIN + W!

#user-t @ #user !
' interpret-do-defined to do-defined
VBUFFER is buffer-link
##VOC	' voc-link	cell+ >user !
' stand-init-io is init-io
' startup is cold-hook
' init is do-init
' stand-init is init-environment

here to dp-loc \ 1A00C68  !


hex
' forth		' current	cell+ >user !
20		' >in		cell+ >user !
22		' #source	cell+ >user !
-1	to flat?

5            to action#
5            to #actions

' crash      to restart

9356818      ' package-name-buf cell+ >user cell+ !

also allocator

F55F ' dbuf-head cell+ >user !   \ >dbuf-flag

' crash is more-memory

previous

14 ' alarm-node cell+ >user cell+ !		\  1A00504 >time-remain
fw-pa  ' alarm-node cell+ >user cell+ cell+ !	\  1A00508 >acf

FFFF0000 1A00514 !


' (key IS key
0 is warning
' entercode is do-entercode

  ' interpret-do-defined    is do-defined
  ' $interpret-do-undefined is $do-undefined


0 is is_disable
hex

.( HEE=) HERE H.

here origin dp!
dp!
hex \ ~mak/yyyy.4
$20 $ADC ORIGIN + ! \ 8  OpenFirmware/dev/pci/i8259.fth:35:24
$D0 $60 ORIGIN + ! \
$20	$22 ORIGIN + C!
$FFAD	$20 ORIGIN + W!

\+ main-task  0x01BFC000 ' main-task CELL+ !

here origin-t dp!
 HEX
dp! 

CR .( HEE=) HERE H. $58  fw-pa + @ h.
.( Saving fw.img ...)
MWRITING  mfw.img

RAMbase HERE T> MOVER M_-
 MOFD M_@ WRITE-FILE THROW
 MOFD M_@ CLOSE-FILE drop
><DP
\ EOF
.( --- Saving as uuu.elf - GRUB multiboot format) cr
 mwriting uuu.elf
 elf-header /elf-header  MOFD @ fputs
   S" reset.di"              $add-file
   S" start.di"              $add-file
   S" mfw.img"	S" firmware" $add-dropin

   MOFD @ fsize h# 60 -  pad !      \ file size; store in memory for convenience below
   h# 44 MOFD @ fseek        \ Seek to file size field; see elfhdr.bth
   pad 4 MOFD @ fputs        \ Patch file size
   pad 4 MOFD @ fputs        \ Patch memory size

 MOFD M_@ CLOSE-FILE drop

