# run.tcl -- by FireEgl -- November 2008

# Provides a !run pub command for bot owners to execute shell commands.
# It's written to use fileevents, so commands can never block the bot.

namespace eval ::run {
	# Handles reading the lines in the buffer:
	proc Readable {fid command who where how utimerid} {
		switch -- $how {
			{pub} - {default} {
				while {[gets $fid line] != -1} { puthelp "PRIVMSG $where :$line" }
				if {[eof $fid]} {
					catch { killutimer $utimerid }
					# Set to blocking so we can see the error (if any):
					fconfigure $fid -blocking 1
					if {[catch { close $fid } error]} {
						foreach line [split $error \n] { puthelp "PRIVMSG $where :$line" }
					}
				}
			}
		}
	}
	# Handles timeouts:
	proc Timeout {fid command who where how timeout} {
		catch { close $fid }
		switch -- $how {
			{pub} - {default} {
				puthelp "PRIVMSG $where :${who}: Timed out after $timeout seconds while waiting for \"$command\" to complete."
			}
		}
	}
	proc Run {command who where {how {default}} {timeout {9}}} {
		# This errors if they gave a bad command:
		if {[catch { open "|$command" r } fid]} {
			switch -- $how {
				{pub} - {default} {
					puthelp "PRIVMSG $where :$fid"
				}
			}
		} else {
			fconfigure $fid -blocking 0 -buffering line
			fileevent $fid readable [list ::run::Readable $fid $command $who $where $how [utimer $timeout [list ::run::Timeout $fid $command $who $where $how $timeout]]]
		}
	}
	proc Pub {nick host hand chan text} { Run $text $nick $chan pub }
	bind pub n !run ::run::Pub
	# I might extend it to use a dcc command or something later..
	putlog {run.tcl by FireEgl - Loaded.}
}
