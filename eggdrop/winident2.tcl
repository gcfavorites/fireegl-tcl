# winident2.tcl v2.0 - by FireEgl@EFNet <Winident@FireEgl.Com> - February, 2011

### Description:
# Implementation of an ident server meant to be used on Windrop (Eggdrop) or Tcldrop running on Windows.

namespace eval winident2 {
	proc Control {idx line} {
		if {$line ne {}} {
			if {[regexp -- {^(\d+)\s*,\s*(\d+)} $line -> lport rport]} {
				if {$lport > 0 && $lport < 65535 && $rport > 0 && $rport < 65535 && $rport == [lindex [split $::server :] end]} {
					putdcc $idx "$lport,$rport : USERID : UNIX : $::username"
				} else {
					putdcc $idx "$lport,$rport : ERROR : INVALID-PORT"
				}
			} else {
				putdcc $idx "[string range $line 0 12] : ERROR : UNKNOWN-ERROR"
			}
			killdcc $idx
		}
		return 0
	}
	proc Connect {idx} { control $idx Control }
	proc Enable {} { catch { listen 113 script ::winident2::Connect } }
	proc Disable {} { catch { listen 113 off } }
	bind evnt - connect-server ::winident2::Enable
	bind evnt - init-server ::winident2::Disable
	bind evnt - sigterm ::winident2::Disable
	bind evnt - sigquit ::winident2::Disable
	bind evnt - sigill ::winident2::Disable
	bind evnt - sighup ::winident2::Disable
	bind evnt - prerehash ::winident2::Disable
	bind evnt - prerestart ::winident2::Disable
}