# pubtcl.tcl by FireEgl
#
# Provides a simple public Tcl interpreter..
# It's NOT a safe interpreter, so only bot owners should use it!
#
# If you want a safe one, that untrusted people can use
# see my pubsafetcl project..  http://Tcldrop.US/SafeTcl/ 
# 
# To use this script, source it, and then .chanset #YourChannel +pubtcl
# Then you can do Tcl commands from the channel, like:
# ;set somevar "This is a test."

namespace eval ::pubtcl {
	bind pubm n {* *} ::pubtcl::PUBM
	proc PUBM {nick host hand chan text} {
		if {[channel get $chan pubtcl]} {
			switch -glob -- [string trimleft $text] {
				{;*} {
					if {[catch { uplevel #0 $text } output]} { set msg "Tcl error: $output" } else { set msg "Tcl: $output" }
					puthelp "PRIVMSG $chan :$nick: $msg"
				}
			}
		}
	}
	setudef flag pubtcl
	putlog {pubtcl.tcl by FireEgl - Loaded.}
}
