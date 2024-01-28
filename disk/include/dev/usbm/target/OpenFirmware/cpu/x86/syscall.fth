

\ True if we are running in a "flat" memory space with all segment
\ selectors referring to the same address range.  This is generally
\ the case when running under Win32 or Unix, but not when running
\ native or under DOS, VCPI, or DPMI.
false value flat?


\ Later, when Forth takes over interrupt vector 13, the following
\ defer words should be set to save and restore vector 13.
\ Typically, that would be done in catchexc.fth

defer wrapper-vectors  ' noop is wrapper-vectors
defer forth-vectors    ' noop is forth-vectors

