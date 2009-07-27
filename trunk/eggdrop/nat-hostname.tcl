# nat-hostname.tcl by FireEgl@Atlantica.US

### Description:
## This script will automatically set nat-ip to your bots public (Internet) IP address when the bot connects to an IRC server.
# (This will fix the problem people have with "/ctcp <bot> CHAT" using the bots private (LAN) IP instead of the Internet IP.)

### Options:
## If you have a static HOSTNAME (such as myhost.dyndns.org) then set this to that hostname, otherwise
## leave it set to "" or commented out and the bot will use the hostname the bot connects to IRC with.
#set ::nat-hostname ""


### Script:
namespace eval ::nat-hostname {
proc ::nat-hostname::CheckVars {} { global my-ip my-hostname
	foreach m {my-ip my-hostname} {
		if {[info exists $m] && [set $m] ne {}} {
			putlog "nat-hostname: You can't use this script while $m is also set!"
			return 1
		}
	}
	return 0
}
if {[CheckVars]} {
	after idle [list namespace delete [namespace current]]
	return
}
proc ::nat-hostname::NATIP {{hostname {}}} {
	if {![CheckVars]} {
		if {$hostname eq {}} {
			# Set it to the hostname the bot connected to the server with:
			set hostname $::botname
		}
		if {[regexp {^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$} [set hostname [lindex [split $hostname @] end]]]} {
		# It's already an IP address..
			switch -glob -- $hostname {
				{127.*.*.*} - {192.168.*.*} - {10.*.*.*} {}
				{default} {
					if {${::nat-ip} ne $hostname} {
						set ::nat-ip $hostname
						putlog "nat-hostname: Automatically set nat-ip to: $hostname"
					}
				}
			}
		} elseif {[string match {*.*} $hostname]} {
			after idle [list after 0 [list dnslookup $hostname ::nat-hostname::DNSLookup]]
		}
	}
}
# Callback for NATIP:
proc ::nat-hostname::DNSLookup {ip host code} {
	if {$code} {
		if {${::nat-ip} ne $ip} {
			set ::nat-ip $ip
			putlog "nat-hostname: Automatically set nat-ip to: $ip  (Acquired by dnslookup of ${host})"
		}
	} else {
		# If the dnslookup didn't get the IP, we try using www.whatismyip.org to find the IP:
		after idle [list after 0 [list ::nat-hostname::GetWebIP]]
	}
}
proc ::nat-hostname::GetWebIP {} {
	if {![catch { socket -async www.whatismyip.org 80 } sock]} {
		fconfigure $sock -blocking 0 -buffering line
		fileevent $sock writable [list ::nat-hostname::GetWebIP_Writable $sock]
	}
}
proc ::nat-hostname::GetWebIP_Writable {sock} {
	if {![catch { puts $sock "GET / HTTP/1.0\nHost: www.whatismyip.org\nUser-Agent: Mozilla/5.0 (X11; U; Linux i686; en-US) Gecko/20061201 Firefox/2.0.0.5\n" }]} {
		fileevent $sock writable {}
		fileevent $sock readable [list ::nat-hostname::GetWebIP_Readable $sock]
	} else {
		catch { close $sock }
	}
}
proc ::nat-hostname::GetWebIP_Readable {sock} {
	while {![catch { gets $sock line } size]} {
		if {$size == -1} {
			if {[eof $sock]} { close $sock }
			break
		} elseif {[regexp {^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$} $line]} {
			if {${::nat-ip} ne $line} {
				set ::nat-ip $line
				putlog "nat-hostname: Automatically set nat-ip to: $line  (Acquired from www.whatismyip.org)"
			}
			catch { close $sock }
			break
		}
	}
}
# Calls NATIP after connecting to an IRC server:
proc ::nat-hostname::InitServerNATIP {event} {
	if {[info exists ::nat-hostname] && [string trim ${::nat-hostname}] ne {}} {
		utimer 3 [list ::nat-hostname::NATIP ${::nat-hostname}]
	} else {
		# The utimer is to make sure the bot has enough time to set $::botname:
		utimer 9 [list ::nat-hostname::NATIP]
	}
}
bind evnt - init-server ::nat-hostname::InitServerNATIP
# Update the nat-ip setting right now (during restart/rehash) if nat-hostname is set:
if {[info exists ::nat-hostname] && [string trim ${::nat-hostname}] ne {}} { after idle [list after 0 [list ::nat-hostname::NATIP ${::nat-hostname}]] }
putlog "[info script] by FireEgl - Loaded."
}
