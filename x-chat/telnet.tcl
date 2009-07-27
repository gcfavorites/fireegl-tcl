# This is a /telnet for X-Chat.

# Usage:
# /telnet host port challenge1 response1 challenge2 response2
# (The challenge/response's are optional)

# Thanks to whoever made the telnet.tcl in pluginscripts.tar.gz, it made a good example.

namespace eval ::telnet {
	# Will contain infos about the ids:
	variable Telnets
	array set Telnets {}
	# Counter for the ids:
	variable Count
	if {![info exists Count]} { variable Count 0 }
	# Checks for EOF (when the socket is open but we haven't yet received anything) and prints something informative in case it is:
	proc Write {id sock} {
		# We only need to call this proc once, so stop the writable fileevent:
		fileevent $sock writable {}
		if {[eof $sock]} {
			variable Telnets
			print $Telnets($id,context) "EOF  [fconfigure $sock -error]"
			Cleanup $id $sock
		} else {
			#ResetTimeout $id $sock
		}
	}
	# Handles reading from the socket:
	proc Read {id sock} {
		variable Telnets
		set context $Telnets($id,context)
		if {[catch { read -nonewline $sock } lines]} {
			print $context $lines
			Cleanup $id $sock
		} else {
			print $context $lines
			if {[catch { eof $sock } eof]} {
				print $context "$eof"
				Cleanup $id $sock
			} elseif {$eof} {
				print $context "Connection Closed  [fconfigure $sock -error]"
				Cleanup $id $sock
			} else {
				# Do challenge/response stuff:
				if {[info exists Telnets($id,responses)] && $Telnets($id,responses) ne {}} {
					foreach l [split $lines \n] {
						foreach {c r} $Telnets($id,responses) {
							if {[string trim $c] eq [string trim $l]} {
								if {[catch { puts $sock $r } error]} {
									print $context "Challenge/Response Error: $error"
									Cleanup $id $sock
								}
							}
						}
					}
				}
				#ResetTimeout $id $sock
			}
		}
	}
	# Stops the timeout timer, cleans up the Telnets id info, removes the close tab handler, and closes the socket (if it's still open):
	proc Cleanup {id sock} {
		variable Telnets
		#after cancel $Telnets($id,timeout-timer)
		array unset Telnets $id,*
		Off XC_TABCLOSE "telnet_$id"
		catch { close $sock }
	}
	# This crap needs to be done from the global namespace:
	proc Alias {name script} { namespace eval :: [list alias $name $script] }
	proc On {token label script} { namespace eval :: [list on $token $label $script] }
	proc Off {token {label {}}} { namespace eval :: [list off $token $label] }
	# Handles telnet tab/window input:
	proc Window {id sock} {
		upvar 1 _rest line
		if {[catch { puts $sock "$line" } error]} {
			print "$error"
			Cleanup $id $sock
		} else {
			print "> $line"
			#ResetTimeout $id $sock
		}
		complete
	}
	# Saves the context for the tab/window we just created:
	proc TabOpen {id} {
		variable Telnets
		set Telnets($id,context) [getcontext]
		Off XC_TABOPEN "telnet_$id"
		complete
	}
	# Handles tab closes:
	proc TabClose {id sock args} {
		variable Telnets
		# Make sure the tab closing is the tab associated with the id:
		if {[info exists Telnets($id,context)] && $Telnets($id,context) == [getcontext]} {
			Cleanup $id $sock
		}
		complete
	}
	# At the end of the idle period, we try to send a backspace character to keep the connection active:
	#proc Timeout {id sock} {
	#	variable Telnets
	#	if {[catch { puts -nonewline $sock "\x1B" } error]} {
	#		print $Telnets($id,context) "$error"
	#		Cleanup $id $sock
	#	} else {
	#		#print $Telnets($id,context) "Sent NOOP"
	#		# Start a new timer that'll send a NUL character at the end of 600 seconds of no activity on the socket:
	#		set Telnets($id,timeout-timer) [after 590000 [list ::telnet::Timeout $id $sock]]
	#	}
	#}
	# This proc should be called whenever there's activity on the socket:
	#proc ResetTimeout {id sock} {
	#	variable Telnets
	#	# Cancel the old timer so it doesn't run:
	#	after cancel $Telnets($id,timeout-timer)
	#	# Start a new timer that'll send a NUL character at the end of 600 seconds of no activity on the socket:
	#	set Telnets($id,timeout-timer) [after 590000 [list ::telnet::Timeout $id $sock]]
	#}
	proc Connect {rest} {
		if {[set host [lindex $rest 0]] eq {}} { set host {127.0.0.1} }
		if {[set port [lindex $rest 1]] eq {}} { set port {23} }
		if {![catch { socket -async $host $port } sock]} {
			fconfigure $sock -buffering line -blocking 0
			variable Count
			# Make up a new id for this socket/context, and give a name for the tab/window:
			set window "[set id [incr Count]]_$host:$port"
			variable Telnets
			# Tab open handler, so can can find out the context of the new tab/window:
			On XC_TABOPEN "telnet_$id" [list ::telnet::TabOpen $id]
			# The remaining arguments are the challenge/response combinations:
			set Telnets($id,responses) [lrange $rest 2 end]
			# You NEED TWO /query commands, the first one creates the window, and the second makes sure it's active.
			/query $window
			# This handles the input to the new window/tab:
			Alias @$window [list ::telnet::Window $id $sock]
			fileevent $sock writable [list ::telnet::Write $id $sock]
			/query $window
			fileevent $sock readable [list ::telnet::Read $id $sock]
			# Setup the handler for when the window/tab gets closed:
			On XC_TABCLOSE "telnet_$id" [list ::telnet::TabClose $id $sock]
			# Initializes the Telnets($id,timeout-timer) variable, so we don't have to always check for its existence later:
			#set Telnets($id,timeout-timer) [after 590000 [list ::telnet::Timeout $id $sock]]
		} else {
			# This usually happens when the hostname doesn't resolve.
			print "Failed to connect: $sock"
		}
		complete
	}
}
# Must be defined from the global namespace:
alias telnet { ::telnet::Connect $_rest }
# Useful for debugging:
if {[info commands bgerror] eq {}} {
	proc bgerror {args} {
		#print "bgerror: [join $args \n]"
		print "errorInfo: $::errorInfo"
	}
}
