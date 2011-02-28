# winident2.tcl v2.0 - by FireEgl <Winident@FireEgl.Com> - February 27, 2011

# Implementation of an ident server meant to be used on Windrop (Eggdrop) or Tcldrop running on Windows.

namespace eval winident2 {
	proc Response {line} {
		if {[regexp -- {^(\d+)\s*,\s*(\d+)} [set line [string range $line 0 12]] -> lport rport]} {
			if {$lport > 0 && $lport < 65535 && $rport > 0 && $rport < 65535} {
				return "$lport, $rport : USERID : UNIX : $::username"
			} else {
				return "$lport, $rport : ERROR : INVALID-PORT"
			}
		} else {
			return "$line : ERROR : UNKNOWN-ERROR"
		}
	}
	proc sockRead {sock} {
		if {[gets $sock line] != -1} {
			puts $sock [set response [Response $line]]
			putlog "Identd: Replied: $response"
		}
		catch { close $sock }
	}
	proc sockConnect {sock address clientport} {
		fconfigure $sock -buffering line -blocking 0
		fileevent $sock readable [list ::winident2::sockRead $sock]
		putlog "Identd: Connect from $address $clientport"
		utimer 30 [list ::winident2::sockClose $sock]
		Disable
	}
	proc sockListen {} {
		variable Sock
		# If Tcl supports IPv6 this uses Tcl's socket -server for everything, 
		# otherwise it just handles IPv4..
		if {![catch { set Sock [socket -server ::winident2::sockConnect 113] } ]} {
			fconfigure $Sock -buffering line -blocking 0
			putloglev d - "Identd: Listening on port 113 (Tcl socket ${Sock})"
		} else {
			putlog {Identd: Can't listen on port 113.  (In Use?)}
		}
	}
	proc sockListenoff {} {
		variable Sock
		if {$Sock in [file channels]} {
			if {![catch { close $Sock }]} {
				putloglev d - "Identd: No longer listening on port 113 (Tcl socket ${Sock})"
			}
		}
	}
	proc sockClose {sock} { if {$sock in [file channels]} { catch { close $sock } } }
	if {[info tclversion] < 8.6 && $::numversion >= 1080000} {
		# Support for Tcl v8.5 on Eggdrop v1.8 here.
		proc idxListen {} {
			# If Tcl only supports IPv4 this uses Eggdrop for IPv6..
			set listenaddr ${::listen-addr}
			set ::listen-addr {::}
			set preferipv6 ${::prefer-ipv6}
			set ::prefer-ipv6 1
			if {![catch { listen 113 script ::winident2::idxConnect pub }]} {
				putloglev d - "Identd: Listening on IPv6 port 113 (Eggdrop socket)"
			}
			set ::listen-addr $listenaddr
			set ::prefer-ipv6 $preferipv6
		}
		proc idxListenoff {} {
			if {![catch { listen 113 off }]} {
				putloglev d - "Identd: No longer listening on IPv6 port 113 (Eggdrop socket)"
			}
		}
		proc idxControl {idx line} {
			if {$line ne {}} {
				putdcc $idx [set response [Response $line]]
				putlog "Identd: Replied: $response"
			}
			return 1
		}
		proc idxConnect {idx} {
			control $idx ::winident2::idxControl
			Disable
		}
		proc Enable {args} {
			variable Enabled
			if {!$Enabled} {
				sockListen
				idxListen
				variable Enabled 1
			}
		}
		proc Disable {args} {
			variable Enabled
			if {$Enabled} {
				sockListenoff
				idxListenoff
				variable Enabled 0
			}
		}
	} else {
		# Tcl socks only.
		proc Enable {args} {
			variable Enabled
			if {!$Enabled} {
				sockListen
				variable Enabled 1
			}
		}
		proc Disable {args} {
			variable Enabled
			if {$Enabled} {
				sockListenoff
				variable Enabled 0
			}
		}
	}
	variable Enabled
	if {![info exists Enabled]} { variable Enabled 0 }
	variable Sock
	if {![info exists Sock]} { variable Sock {} }
	bind evnt - connect-server ::winident2::Enable
	bind evnt - init-server ::winident2::Disable
	bind evnt - sigterm ::winident2::Disable
	bind evnt - sigquit ::winident2::Disable
	bind evnt - sigill ::winident2::Disable
	bind evnt - sighup ::winident2::Disable
	bind evnt - prerehash ::winident2::Disable
	bind evnt - prerestart ::winident2::Disable
	putlog {winident2.tcl v2.0 by FireEgl - Loaded.}
}

# http://tools.ietf.org/html/rfc1413
