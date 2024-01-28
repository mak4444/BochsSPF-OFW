purpose: Convert date and time to DOS packed format

: >hms  ( dos-packed-time -- secs mins hours )
   dup h#   1f and      2*   swap  ( secs packed )
   dup h# 07e0 and      5 >> swap  ( secs mins packed )
       h# f800 and  d# 11 >>       ( secs mins hours )
;  
: hms>  ( secs mins hours -- dos-packed-time )
   d# 11 << h# f800 and swap      ( secs packed mins )
       5 << h# 07e0 and + swap    ( packed secs )
         2/ h# 001f and +         ( packed )
;
: >dmy  ( dos-packed-date -- day month year )
   dup h#   1f and          swap   ( day packed )
   dup h# 01e0 and  5 >>    swap   ( day month packed )
       h# fe00 and  9 >> d# 1980 + ( day month year )
;  
: dmy>  ( day month year -- dos-packed-date )
   d# 1980 -
   9 << h# fe00 and   swap    ( day packed month )
   5 << h# 01e0 and + swap    ( packed day )
        h# 001f and +         ( packed )
;
