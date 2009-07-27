# findservers.tcl v0.2 - by FireEgl@EFNet <EggTcl @ Atlantica . US> - (www.Tcl.Atlantica.US) - May 2005.

### Description:
# Does a /links once per day to find new IRC servers, which it adds to the $servers list.

### Notes:
# Servers are saved locally and will be reloaded when the bot restarts.

### History:
# 0.2 - Added support for excluding servers. (For excluding the servers that don't allow bots)
# 0.1 - Split from efnetservers.tcl, removed all EFNet-specific code.

namespace eval ::findservers { variable findservers
	### Options:
	## Store all known servers locally in this file:
	set findservers(file) "servers.${::botnet-nick}.txt"

	## Set this to 1 for the bot to do a /links once a day.
	set findservers(links) 1

	## Set this to 1 to accept servers other bots tell us about.
	set findservers(bots) 1

	## Servers you want to exclude:
	set findservers(exclude) {
		irc.prison.net
		irc.servercentral.net
		irc.mindspring.com
	}
}

if {$::findservers::findservers(links)} {
	if {[info procs ::findservers::Connect] == {}} { bind time - "[expr { int(rand()*60) + 1 }] [expr { int(rand()*24) + 1 }] * * *" ::findservers::Connect }
	proc ::findservers::Connect {args} { variable findservers
		if {$findservers(links)} { puthelp {LINKS} }
	}
	bind raw - 364 ::findservers::RAW_Links
	proc ::findservers::RAW_Links {from key arg} { variable findservers
		if {[lsearch -glob [string tolower $findservers(list)] "[string tolower [set s [lindex [split $arg] 1]]]*"] == -1 && [lsearch -glob [string tolower $findservers(exclude)] "[string tolower $s]*"] == -1} {
			putlog "findservers/links: Adding $s to servers list.."
			lappend findservers(list) $s
			set ::servers $findservers(list)
			puts [set fid [open $findservers(file) w]] $findservers(list)
			close $fid
			putallbots "newserver $s"
		}
	}
}

if {$::findservers::findservers(bots)} {
	bind bot b newserver ::findservers::BOT_NewServer
	proc ::findservers::BOT_NewServer {from cmd s} { variable findservers
		if {$findservers(bots) && [matchattr $from b&o&f]} {
			if {[lsearch -glob [string tolower $findservers(list)] "[string tolower $s]*"] == -1 && [lsearch -glob [string tolower $findservers(exclude)] "[string tolower $s]*"] == -1} {
				putlog "findservers/bots: Adding $s to servers list.."
				lappend findservers(list) $s
				set ::servers $findservers(list)
				puts [set fid [open $findservers(file) w]] $findservers(list)
				close $fid
			}
		}
	}
}

proc ::findservers::LoadSaved {} { variable findservers
	foreach s [set findservers(list) [gets [set fid [open $findservers(file) r]]][close $fid]] {
		if {[lsearch -glob [string tolower $::servers] "[string tolower $s]*"] == -1 && [lsearch -glob [string tolower $findservers(exclude)] "[string tolower $s]*"] == -1} { lappend ::servers $s }
	}
}
namespace eval ::findservers { if {![info exists findservers(list)] && [catch { LoadSaved }]} { set findservers(list) [list] } }
putlog "findservers.tcl v0.2 - by FireEgl@EFNet - Loaded."
