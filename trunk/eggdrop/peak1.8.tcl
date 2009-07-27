# peak1.8.tcl - FireEgl@EFNet <EggTcl @ Atlantica . US> (www.Tcl.Atlantica.US) - 6/25/04

### Description:
# Keeps up with the peak number of people in the
# channel and announces it when a new record is set.

### Usage:
# To enable peak tracking for a channel:
#   .chanset #channel +peak
# There's also a !peak public command.

# Note:
# This is an old script of mine, I only make bugfixes to it nowadays.
# Do not ask for feature requests.

### History:
# 1.8 - Fixed a bug.
# 1.7 - Fixed a bug relating to the case of the channel name.
# 1.6 - Added support for a +peak chanset. To enable, type: .chanset #channel +peak
#     - No longer counts bots.
# 1.5 - Oh no! The peak.*.txt files got reset when you restarted the bot..
#     - Also the thinger that's sposta clean-up unused peak.*.txt's was deleting used ones.
# 1.4 - Minor changes.
# 1.3 - Now loads peak data from file on demand (if it's not already in memory).
# 1.2 - Now uses a file to store peak data.
#     - Added !peak public command.
#     - Now says how long ago the last record was set.
#     - Removed mIRC colors. =P
# 1.1 - uhmmmmm...
# 1.0 - Released.


### Begin Script:
setudef flag peak

bind join - * join:peak
proc join:peak {nick host hand chan} {
	if {(([lsearch -exact [channel info $chan] {+peak}] != -1) && ([set curnum [llength [chanlist $chan -b]]] > [set lastmax [lindex [set peak [getpeak $chan]] 0]]))} {
		puthelp "PRIVMSG $chan :New channel user peak! (\002$curnum\002)  Last peak was [timeago [lindex $peak 1]] ago."
		setpeak $chan $curnum [clock seconds]
	}
}

# Loads the peak data from file if it's not already in memory and returns the data:
proc getpeak {chan} { global peak
	if {[info exists peak([set chan [string tolower $chan]])]} {
		set peak($chan)
	} elseif {[file readable "peak.$chan.txt"]} {
		if {[gets [set fid [open "peak.$chan.txt" {RDONLY}]] peak($chan)] < 9} { set peak($chan) [list 0 [clock seconds]] }
		close $fid
		set peak($chan)
	} else {
		set peak($chan) [list [llength [chanlist $chan -b]] [clock seconds]]
	}
}

# Sets peak data to file:
proc setpeak {chan curnum unixtime} { global peak
	set chan [string tolower $chan]
	puts [set fid [open "peak.$chan.txt" {WRONLY CREAT}]] [set peak($chan) [list $curnum $unixtime]]
	close $fid
}

# Provides the !peak public command:
bind pub fomn|fomn !peak pub:peak
proc pub:peak {nick host hand chan arg} {
	if {[lsearch -exact [channel info $chan] {+peak}] != -1} {
		puthelp "PRIVMSG $chan :Channel Peak Record: [lindex [set peak [getpeak $chan]] 0] ([timeago [lindex $peak 1]] ago)."
	} elseif {[matchattr $hand n|n $chan]} { channel set $chan +peak
		puthelp "PRIVMSG $chan :Peak is now enabled for this channel.  To disable again, use: .chanset $chan -peak"
		savechannels
	}
	return 1
}

# Thanks To slann@EFNet <slann@bigfoot.com> for the timeago proc, which is really from seen.tcl by Ernst, which is really by robey.
proc timeago {lasttime} {
	set totalyear [expr [clock seconds] - $lasttime]
	if {$totalyear >= 31536000} {
		set yearsfull [expr $totalyear/31536000]
		set years [expr int($yearsfull)]
		set yearssub [expr 31536000*$years]
		set totalday [expr $totalyear - $yearssub]
	}
	if {$totalyear < 31536000} {
		set totalday $totalyear
		set years 0
	}
	if {$totalday >= 86400} {
		set daysfull [expr $totalday/86400]
		set days [expr int($daysfull)]
		set dayssub [expr 86400*$days]
		set totalhour 0
	}
	if {$totalday < 86400} {
		set totalhour $totalday
		set days 0
	}
	if {$totalhour >= 3600} {
		set hoursfull [expr $totalhour/3600]
		set hours [expr int($hoursfull)]
		set hourssub [expr 3600*$hours]
		set totalmin [expr $totalhour - $hourssub]
		if {$totalhour >= 14400} { set totalmin 0 }
	}
	if {$totalhour < 3600} {
		set totalmin $totalhour
		set hours 0
	}
	if {$totalmin > 60} {
		set minsfull [expr $totalmin/60]
		set mins [expr int($minsfull)]
		set minssub [expr 60*$mins]
		set secs 0
	}
	if {$totalmin < 60} {
		set secs $totalmin
		set mins 0
	}
	if {$years < 1} {set yearstext ""} elseif {$years == 1} {set yearstext "$years year, "} {set yearstext "$years years, "}
	if {$days < 1} {set daystext ""} elseif {$days == 1} {set daystext "$days day, "} {set daystext "$days days, "}
	if {$hours < 1} {set hourstext ""} elseif {$hours == 1} {set hourstext "$hours hour, "} {set hourstext "$hours hours, "}
	if {$mins < 1} {set minstext ""} elseif {$mins == 1} {set minstext "$mins minute"} {set minstext "$mins minutes"}
	if {$secs < 1} {set secstext ""} elseif {$secs == 1} {set secstext "$secs second"} {set secstext "$secs seconds"}
	string trimright "$yearstext$daystext$hourstext$minstext$secstext" {, }
}

putlog "peak1.8.tcl by FireEgl@EFNet <EggTcl @ Atlantica . US> (www.Tcl.Atlantica.US) - Loaded."
