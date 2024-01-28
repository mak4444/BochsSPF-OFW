id: @(#)framebuf.fth 3.4 01/04/06
purpose: Variables and defer words used by many frame buffers drivers

\ Variables that are useful for most kinds of frame buffers.
headers

\ The definition of frame-buffer-adr has been moved to devtree.fth, as
\ frame-buffer-adr is now a fixed instance value.  This was done as a
\ workaround for a problem with old FCode display drivers, some of which
\ use frame-buffer-adr for their selftest routines.  With multiple frame
\ buffers on the same machine, a "test" command directed to a frame buffer
\ can screw up the console device.
\ 0 termemu-value frame-buffer-adr

0 termemu-value column#			\ Cursor column number
0 termemu-value line#			\ Cursor line number

d# 1152 termemu-value screen-width
d#  900 termemu-value screen-height

0 termemu-value window-top		\ Pixel position of top of text area
0 termemu-value window-left		\ Pixel position of left of text area

0 termemu-value emu-bytes/line
0 termemu-value bytes/line		\ Framebuffer pitch

\ Interfaces to device-dependent graphics primitives:
d# 34 termemu-value #lines
d# 80 termemu-value #columns

\ Things that change for different pixel depths
termemu-defer pix*
termemu-defer fb-invert
termemu-defer fb-fill
termemu-defer fb-paint
termemu-defer fb-16map
termemu-defer fb-merge

termemu-defer draw-character
termemu-defer insert-characters
termemu-defer delete-characters
termemu-defer insert-lines
termemu-defer delete-lines
termemu-defer blink-screen
termemu-defer invert-screen
termemu-defer reset-screen
termemu-defer erase-screen
termemu-defer toggle-cursor

termemu-defer draw-logo

\ These values are available to the device-dependent routines.
\ The behavior of the device-dependent routines implicitly depends
\ on their values.

true  termemu-value showing-cursor?	\ True to display text cursor
false termemu-value inverse-screen?	\ True for overall black background
false termemu-value inverse?		\ True for white characters on black background
headerless
\  true value frame-buffer-busy?	\ If true, drivers must assume that the frame
\  				\ buffer is in use by another program, which
\  				\ may require extra action to ensure the
\  				\ visibility of the displayed text.
\  	\ For example, a frame buffer with an enable plane might require
\  	\ that the enable plane be written to expose the character.
\

termemu-defer ansi-emit
false termemu-value pending-newline?
\ True if the cursor is at the rightmost column but the next character
\ should be displayed on the next line

1 termemu-value #scroll-lines			\ Number of lines to scroll

\ These variables are used to accumulate the optional numeric
\ argument or arguments of the escape sequence.
4 termemu-array arg
0 termemu-value next-arg
0 termemu-value arginit		\ Remembers the "real" value of argument 0.
				\ If arg0 is 0, it is changed to 1.

    0 termemu-value foreground-color	\ Color index for foreground
d# 15 termemu-value background-color	\ Color index for background
false termemu-value 16-color?		\ True if 16-color text is enabled

