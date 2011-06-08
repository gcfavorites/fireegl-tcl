# tailf2channel.tcl -- by FireEgl

# Description:
# Watches a file (most likely a log file) for new lines and prints them to an IRC channel.
# This was mainly created as an example of "how to do tailf in Tcl".

# Notes:
# fileevents don't work well on normal files.  So this is the only reliable way I know to tail a file in Tcl...

namespace eval tailf2channel {
	proc tailf2channel {channel filename {seconds {9}}} {
		if {![catch { open $filename r } fid]} {
			fconfigure $fid -blocking 0 -buffering line
			variable Tails
			if {[info exists Tails([set channel [string tolower $channel]],$filename)]} {
				if {$Tails($channel,$filename) > [file size $filename]} {
					# File shrunk since we last read from it..(log got rotated?)..Set position to the start of the file:
					seek $fid 0 start
				} else {
					# Just read from where we left off at:
					seek $fid $Tails($channel,$filename) start
				}
				while {[gets $fid line] >= 0} {
					if {[string length $line] > 0} {
						# Uncomment to use pattern matching on the line:
						#if {[string match -nocase {*PATTERN HERE*} $line]} {
							puthelp "PRIVMSG $channel :$line"
						#}
					}
				}
			} else {
				# This will make it skip everything currently in the file and only show the newly added lines.. (We're probably starting this script long after the file has been growing)
				seek $fid 0 end
			}
			set Tails($channel,$filename) [tell $fid]
			close $fid
		}
		variable Timers
		set Timers($channel,$filename) [utimer $seconds [list [namespace current]::tailf2channel $channel $filename $seconds]]
	}

	# Kill the current timers so we can start new ones:
	variable Timers
	foreach t [array names Timers] { catch { killutimer $Timers($t) } }

	# Change the next line for your channel and file you want to tail, the time is in seconds:
	tailf2channel #Tcl /tmp/test.log 5
}

putlog {tailf2channel.tcl by FireEgl - Loaded.}
