#! /usr/bin/tclsh

# sysinfo.tcl - by FireEgl - April 2011

# pub command !sysinfo reads some files in /proc/ and /etc/ and returns some basic system info.

namespace eval ::sysinfo {
	variable pubcmd !sysinfo
	# Shows everything:
	variable format {Hostname: [hostname], Distribution: [distrib], OS: $::tcl_platform(os) $::tcl_platform(osVersion)/$::tcl_platform(machine), CPU: [cpu], Load Average: [loadavg], Processes: [processes], Memory Used: [memory], Uptime: [uptime], Users: [users].}
	# For grsecurity with proc restrictions enabled:
	#variable format {Hostname: [info hostname], Distribution: [distrib], OS: $::tcl_platform(os) $::tcl_platform(osVersion)/$::tcl_platform(machine), CPU: [cpu], Load Average: [loadavg], Processes: [processes], Memory Used: [memory], Uptime: [uptime].}
	# For Cygwin:
	#variable format {Hostname: [info hostname], OS: $::tcl_platform(os) $::tcl_platform(osVersion)/$::tcl_platform(machine), CPU: [cpu], Processes: [processes], Uptime: [uptime].}
}

proc ::sysinfo::sysinfo {{default {Problem getting sysinfo.}}} {
	variable format
	if {![catch { subst $format } out]} {
		return $out
	} else {
		return $default
	}
}
proc ::sysinfo::cpu {{default {Unknown}}} {
	if {[set cpuinfo [readfile /proc/cpuinfo]] ne {} && [regexp -line -- {model name\s*:\s*(.*)} $cpuinfo -> modelname] && [regexp -line -- {cpu MHz\s*:\s*(.*)} $cpuinfo -> cpumhz] && [set processors [regexp -all -line -- {processor\s*:.*} $cpuinfo]]} {
		return "${processors}x [string map [list {(R)} "\u00AE" {(TM)} "\u2122" {(C)} "\u00A9" {     } { } {  } { } {   } { } {    } { }] $modelname] ([format %.0f $cpumhz]MHz)"
	} else {
		return $default
	}
}
proc ::sysinfo::loadavg {{default {0}}} {
	if {[set loadavg [readfile /proc/loadavg]] ne {}} {
		lindex $loadavg 0
	} else {
		return $default
	}
}
proc ::sysinfo::uptime {{default {Unknown}}} { 
	if {[set uptime [readfile /proc/uptime]] ne {}} {
		secstodays [lindex $uptime 0]
	} else {
		return $default
	}
}
proc ::sysinfo::distrib {{default {Unknown}}} {
	if {[set lsbinfo [readfile /etc/lsb-release]] ne {}} {
		set lsbdesc $default
		regexp -line -- {DISTRIB_DESCRIPTION="(.*)"} $lsbinfo -> lsbdesc
		return $lsbdesc
	} elseif {[set lsbdesc [readfile /etc/debian_version]] ne {}} {
		return "Debian $lsbdesc"
	} else {
		return $default
	}
}
proc ::sysinfo::memory {{default {?}}} {
	if {[set meminfo [readfile /proc/meminfo]] ne {} && [regexp -line -- {MemTotal:\s*(\d+) kB} $meminfo -> memtotal] && [regexp -line -- {MemFree:\s*(\d+) kB} $meminfo -> memfree]} {
		set memused [expr { $memtotal - $memfree }]
		return "[format %.0f [expr { $memused / 1024.0 }]]MB/[format %.0f [expr { $memtotal / 1024.0 }]]MB"
	} else {
		return $default
	}
}
proc ::sysinfo::users {{default {?}}} {
	if {![catch { exec who -q } who] && [regexp {# users=(\d)} $who -> count]} {
		return $count
	} elseif {![catch { llength [split [exec w -h] \n] } count]} {
		return $count
	} elseif {[file exists /proc/consoles]} {
		# Note: I think /proc/consoles only shows local logins..
		llength [split [readfile /proc/consoles] \n]
	} else {
		return $default
	}
}
proc ::sysinfo::processes {{default {0}}} {
	if {[set processes [lindex [readfile /proc/loadavg] 3]] ne {}} {
		return "$processes (running/total)"
	} else {
		llength [glob -directory /proc/ -tails -nocomplain 1* 2* 3* 4* 5* 6* 7* 8* 9*] 
	}
}
proc ::sysinfo::hostname {{default {?}}} { info hostname }
proc ::sysinfo::os {{default {?}}} { return $::tcl_platform(os) }
proc ::sysinfo::osver {{default {?}}} { return $::tcl_platform(osVersion) }
proc ::sysinfo::machine {{default {?}}} { return $::tcl_platform(machine) }
proc ::sysinfo::readfile {file {default {}}} { 
	if {![catch { read -nonewline [set fid [open $file r]] } out]} {
		close $fid
		return $out
	} else {
		return $default
	}
}
proc ::sysinfo::secstodays {seconds args} { return "[expr { [format %.0f $seconds] / 86400 }] days" }

if {[info exists ::numversion] && [llength [info commands bind]] && ![catch { bind pub - $::sysinfo::pubcmd ::sysinfo::PUB }]} {
	# This part is for running on Eggdrop.
	proc ::sysinfo::PUB {nick host hand chan text} {
		if {[string trim $text] eq {} || [isbotnick $text]} {
			puthelp [encoding convertto utf-8 "PRIVMSG $chan :[sysinfo]"]
		}
	}
	putlog "sysinfo.tcl - Loaded."
} else {
	# This part is for running from the command-line.
	puts [::sysinfo::sysinfo]
}
