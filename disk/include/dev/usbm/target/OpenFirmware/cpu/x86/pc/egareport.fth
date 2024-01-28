: v-report  ( char -- )
   " # al mov  al h# b8000 #) mov  h# 1d # al mov  al h# b8001 #) mov" evaluate
;
: vr-report  ( char -- )  \ Real mode version
   " ds push  h# b000 # push ds pop" evaluate   
   " # al mov  al h# 8000 #) mov   h# 1d # al mov  al h# 8001 #) mov"  evaluate
   " ds pop" evaluate
;

\  mmo  from boot.fth 


label prom-cold-code  ( -- )

   \ We assume that the machine is already in protected mode, with a
   \ linear mapping.  DS = ES = SS = FS = GS.  The descriptor referenced
   \ by CS maps the same memory as the DS descriptor.
   \ Interrupts are off.

   cld

\ carret report
\ linefeed report
ascii c report

\ Get the origin address
   here 5 + #) call   here origin -  ( offset )
   bx  pop
   ( offset ) #  bx  sub	\ Origin in bx

\ Copy the initial User Area image to the RAM copy
   init-user-area #  si  mov	\ Init-up pointer in bx
   bx si add                    \ add origin
   prom-main-task #  di  mov	\ Destination of copy
   user-size #       cx  mov
   rep byte movs

ascii s report

   prom-main-task #      up  mov        \ Set User Area Pointer

\ The User Area is now initialized
   up        'user up0   mov	\ Set the up0 user variable

\ Set the value of flat? so later code knows that we are running
\ in a single address space, i.e. Forth is not in a private segment.

   true #  ax  mov   ax  'user flat?  mov

   prom-main-task #  rp  mov	\ Initialize the Return Stack Pointer
   rp        'user rp0   mov    \ Set the rp0 user variable
   rp        ax          mov
   rs-size # ax          sub

\ Establish the Parameter Stack
   ax        sp          mov
   sp        'user sp0   mov	\ Set the sp0 user variable

\   ps-size # ax          sub
\   ax  'user next-free-mem   mov        \ Set heap pointer

    'user dp-loc    ax    mov
    ax        'user dp    mov    \ Initialize the dictionary pointer

\ ascii s report
h# 20 report

\ Enter Forth
   make-odd
   'body cold fw-pa +  dup #  ip  mov
   -4 allot token,
c;

: patchboot  ( -- )
   prom-main-task ['] main-task >body !

   here origin -  RAMbase +  is dp-loc

   \ Set offset field of branch at origin
   prom-cold-code origin 5 + -  origin 1+ !
;
