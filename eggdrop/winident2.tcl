# winident2.tcl v2.0 - by FireEgl <Winident@FireEgl.Com> - February 26, 2011

# Implementation of an ident server meant to be used on Windrop (Eggdrop) or Tcldrop running on Windows.

namespace eval winident2 {
	proc Control {idx line} {
		if {$line ne {}} {
			if {[regexp -- {^(\d+)\s*,\s*(\d+)} [set line [string range $line 0 12]] -> lport rport]} {
				if {$lport > 0 && $lport < 65535 && $rport > 0 && $rport < 65535} {
					putdcc $idx "$lport, $rport : USERID : UNIX : $::username"
					putlog "Identd: Replied: $lport, $rport : USERID : UNIX : $::username"
				} else {
					putdcc $idx "$lport, $rport : ERROR : INVALID-PORT"
					putlog "Identd: Replied: $lport, $rport : ERROR : INVALID-PORT"
				}
			} else {
				putdcc $idx "$line : ERROR : UNKNOWN-ERROR"
				putlog "Identd: Replied: $line : ERROR : UNKNOWN-ERROR"
			}
		}
		return 1
	}
	proc Connect {idx} {
		control $idx ::winident2::Control
		Disable
	}
	proc Enable {args} {
		variable Enabled
		if {!$Enabled && ![catch { listen 113 script ::winident2::Connect pub }]} {
			variable Enabled 1
			putloglev d - {Identd: Enabled.}
		}
	}
	proc Disable {args} {
		variable Enabled
		if {$Enabled && ![catch { listen 113 off }]} {
			putloglev d - {Identd: Disabled.}
		}
		variable Enabled 0
	}
	variable Enabled
	if {![info exists Enabled]} { variable Enabled 0 }
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
