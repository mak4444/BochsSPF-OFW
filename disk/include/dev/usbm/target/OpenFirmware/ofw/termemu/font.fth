purpose: FCode interface to default font

decimal
headers
0 termemu-value font-base		\ Base address of font

0 termemu-value char-width		\ FCode character width in pixels
0 termemu-value char-height		\ FCode character height in pixels (scan lines)
0 termemu-value fontbytes		\ FCode distance in bytes from one scan line of
					\ a glyph to the next
0 termemu-value glyph-bytes		\ distance between glyphs
headerless
0 termemu-value min-char		\ The lowest character in the font
0 termemu-value #glyphs			\ The number of glyphs in the font

headers
defer font
' romfont is font

headerless
: decode-font  ( hdr-adr -- bits-adr width height advance min-char #glyphs )
   dup " font" comp 0=  if   ( hdr-adr )   \ OBF font format
      dup d# 24 +  swap              ( bit-adr hdr-adr )
      4 +  d# 20                     ( bit-adr hdr-adr' hdr-len )
      5 0 do  decode-int -rot  loop  ( bits-adr width height advance min #gl str )
      2drop                  ( bits-adr width height advance min-char #glyphs )
      exit
   then                      ( hdr-adr )

   \ http://www.win.tue.nl/~aeb/linux/kbd/font-formats-1.html
   dup le-l@ h# 864ab572 =  if  ( hdr-adr )   \ PSF2 format, little endian
      >r                        ( r: hdr-adr )
      r@  r@ 8 + le-l@ +        ( bits-adr r: hdr-adr )
      r@ h# 1c + le-l@          ( bits-adr width r: hdr-adr )
      r@ h# 18 + le-l@ negate   ( bits-adr width height r: hdr-adr )
      over 7 + 8 /              ( bits-adr width height advance r: hdr-adr )
      0                         ( bits-adr width height advance min r: hdr-adr )
      r@ h# 10 + le-l@          ( bits-adr width height advance #glyphs r: hdr-adr )
      r> drop                   ( bits-adr width height advance #glyphs )
      exit
   then                         ( hdr-adr )

   true abort" Not a font"
;
headers
also forth definitions
\ There are no glyphs for control characters, so the font bitmaps actually
\ begin with the glyph for the space (blank) character.

\ The 1- after char-height is due to the way that the PROM stores character
\ bitmaps.  Since the top and bottom scan lines of the character are both 0,
\ only  char-height 1-  scan-lines are actually stored, and the bottom zero
\ scan line of a glyph is overlapped with the top zero scan line of the
\ next glyph.  This is probably a bad idea in the long run.

: >font  ( char -- adr )					\ FCode
   min-char -  0 max  #glyphs min   ( char# )	\ Clip the glyph number
   glyph-bytes * font-base +
;

headerless
: character-set ( -- )
   " character-set"  2dup get-my-property  if  ( adr,len )
      " ISO8859-1" encode-string 2swap  property   (  )
   else                                         ( adr,len adr,len' )
      2drop 2drop                               (  )
   then                                         (  )
;
headers
: default-font  ( -- adr width height advance min-char #glyphs ) \ FCode
   character-set  font decode-font
;

: set-font  ( adr width +-height advance min-char #glyphs -- )	\ FCode
   is #glyphs  is min-char
   is fontbytes
   dup >r abs is char-height  is char-width  ( r: +-height )
   is font-base

   \ If +-height is positive, then we use the original packed font
   \ storage format in which the last scan line of one glyph overlaps
   \ the first scan line of the next.  If +-height is negative, we
   \ use an unpacked format in which each glyph is self-contained.
   r>  dup 0>  if  1-  else  negate  then  fontbytes *  to glyph-bytes
;
previous definitions
