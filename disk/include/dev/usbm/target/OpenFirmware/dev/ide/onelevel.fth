purpose: IDE one-level - master,slave / primary,secondary on same level

" ide" device-name
" ide" device-type

\ The IDE device node defines an address space for its children.  That
\ address space is of the form "dummy, unit#".  Both are integers.

: decode-unit  ( addr len -- dummy unit# )  parse-2int  ;

new-device
