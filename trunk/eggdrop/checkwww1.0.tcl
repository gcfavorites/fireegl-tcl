# checkwww.tcl v1.0 - by FireEgl@EFNet <FireEgl@EMail.Com> (FireEgl.cjb.Net) - May 2001

### Description:
# Checks a web page every so often and changes a channels topic when the web page is updated.

### Options:
## Check Every This Many Minutes:
set checkwww(interval) 9

## The Web Page to Check:
set checkwww(webpage) {http://FireEgl.On.OpenAve.Net}

## How to Announce the Change:
set checkwww(announce) {
 puthelp "TOPIC #MyChannel :$checkwww(webpage) was updated @ $date."
}

### Begin Script:
package require http
proc checkwww {} { global checkwww
   set meta [set [set tok [::http::geturl "$checkwww(webpage)"]](meta)]
   ::http::cleanup $tok
   if {[set ndx [lsearch $meta {Last-Modified}]] != -1 && "[set date [lindex $meta [expr $ndx + 1]]]" != "$checkwww(last)"} {
      set checkwww(last) $date
      eval $checkwww(announce)
   }
   foreach t [timers] { if {"[lindex $t 1]" == {checkwww}} { killtimer [lindex $t 2] } }
   timer $checkwww(interval) checkwww
}
if {![info exists checkwww(last)]} { set checkwww(last) {} }
timer $checkwww(interval) checkwww
putlog "[file tail [info script]] v1.0 by FireEgl@EFNet <FireEgl@EMail.Com> (FireEgl.cjb.Net) - Loaded."
