qemu-system-x86_64  -hda fdosmini.img -hdb fat:rw:./disk   \
 -drive if=none,id=usbstick,format=raw,file=./gfos.img  -usb  \
 -device usb-ehci,id=ehci                                 \
 -device usb-tablet,bus=usb-bus.0                         \
 -device usb-storage,bus=ehci.0,drive=usbstick
