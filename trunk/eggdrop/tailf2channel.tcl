
namespace eval tailf2channel {
	proc tailf2channel {channel filename {seconds {9}}} {
		variable Tails
		if {![catch { open $filename r } fid]} {
			fconfigure $fid -buffering line
			if {[info exists Tails([set channel [string tolower $channel]],$filename)]} {
				if {$Tails(pos,$channel,$filename) >= [file size $filename]} {
					# File shrunk since we last read from it..(log got rotated?)..Set position to the start of the file:
					seek $fid 0 start
				} else {
					# Just read from where we left off at:
					seek $fid $Tails($channel,$filename) start
				}
				while {[gets $fid line] >= 0} { if {[string length $line] > 0} { puthelp "PRIVMSG $channel :$line" } }
			} else {
				# This will make it skip everything currently in the file and only show the newly added lines..
				seek $fid 0 end
			}
			set Tails($channel,$filename) [tell $fid]
			close $fid
		}
		utimer $seconds [list [namespace current]::tailf2channel $channel $filename $seconds]
	}

	# Change the next line for your channel and file you want to tail:
	tailf2channel #Tcl /tmp/test.log 5
}

putlog {tailf2channel.tcl by FireEgl - Loaded.}
