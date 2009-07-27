# afk.tcl v0.9 - by FireEgl@EFNet <EggTcl@Atlantica.US> - http://Tcl.Atlantica.US/ - November 2004

### Description:
# Allows the bot to keep track of who's away, and tells people that
# they're away when they say the away persons nick on the channel.
# Will also print a list of away nicks along with how long they've
# been away and why when "afk?" is typed on the channel.

### Usage:
# afk <reason>   - Sets you as afk.
# afk?           - NOTICE's you a list of the people afk.

### Begin script:

# Initializes the namespace and AFKs variable:
namespace eval ::afk {
	variable AFKs
	array set AFKs [list]
}

# Announces the return of an AFK person, or tells somebody saying their nick that they're away:
bind pubm - * ::afk::Pubm
proc ::afk::Pubm {nick host hand chan text} {
	variable AFKs
	foreach afknick [array names AFKs] {
		if {[string equal -nocase $afknick $nick]} {
			array set nickinfo $AFKs($afknick)
			puthelp "PRIVMSG $chan :$nickinfo(nick) has returned from: $nickinfo(reason)"
			puthelp "PRIVMSG $chan :$nickinfo(nick) was away for: [duration [expr { [clock seconds] - $nickinfo(stamp) }]]."
			unset AFKs($afknick)
		} elseif {![string match -nocase {afk?*} $text] && [string match -nocase "*$afknick*" $text] && [onchan $afknick $chan]} {
			array set nickinfo $AFKs($afknick)
			puthelp "PRIVMSG $chan :${nick}: $nickinfo(nick)'s currently away. Reason: $nickinfo(reason)"
			puthelp "PRIVMSG $chan :${nick}: $nickinfo(nick) has been away for: [duration [expr { [clock seconds] - $nickinfo(stamp) }]]."
		}
	}
}

# Sets a person as AFK:
bind pub - afk ::afk::PubSetAFK
bind pub - !afk ::afk::PubSetAFK
proc ::afk::PubSetAFK {nick host hand chan reason} {
	variable AFKs
	if {$reason == {}} { set reason {AFK!} }
	set AFKs([string tolower $nick]) [list nick $nick host $host hand $hand reason $reason stamp [clock seconds]]
	puthelp "PRIVMSG $chan :$nick is now AFK. Reason: \[$reason\]"
}

# Lists people who are afk on a channel:
bind pub - afk? ::afk::PubListAFKs
bind pub - afklist ::afk::PubListAFKs
bind pub - afklist? ::afk::PubListAFKs
bind pub - !afklist ::afk::PubListAFKs
bind pub - afks ::afk::PubListAFKs
bind pub - afks? ::afk::PubListAFKs
bind pub - !afks ::afk::PubListAFKs
proc ::afk::PubListAFKs {nick host hand chan text} {
	variable AFKs
	foreach afknick [array names AFKs] {
		if {[onchan $afknick $chan]} {
			array set nickinfo $AFKs($afknick)
			puthelp "NOTICE $nick :$nickinfo(nick) has been AFK for [duration [expr { [clock seconds] - $nickinfo(stamp) }]] doing: \"$nickinfo(reason)\""
		}
	}
	if {![info exists nickinfo]} { puthelp "NOTICE $nick :Nobody is AFK on ${chan}." }
}

# Allows keeping track of people who change nicks while afk:
bind nick - * ::afk::Nick
proc ::afk::Nick {nick host hand chan newnick} {
	variable AFKs
	if {[info exists AFKs([set lowernick [string tolower $nick]])]} {
		set AFKs([string tolower $newnick]) $AFKs($lowernick)
		unset AFKs($lowernick)
	}
}

# Clears the away info for someone when they part ALL the channels the bot is in:
bind part - * ::afk::Part
proc ::afk::Part {nick host hand chan {msg {}}} {
	variable AFKs
	if {![onchan $nick] && [info exists AFKs([set lowernick [string tolower $nick]])]} { unset AFKs($lowernick) }
}

# Clears the away info for someone when they sign off irc:
bind part - * ::afk::Sign
proc ::afk::Sign {nick host hand chan {msg {}}} {
	variable AFKs
	if {[info exists AFKs([set lowernick [string tolower $nick]])]} { unset AFKs($lowernick) }
}

# Clears the away info for someone when they're kicked and aren't in any other channels:
bind kick - * ::afk::Kick
proc ::afk::Kick {nick host hand chan target reason} {
	variable AFKs
	if {![onchan $target] && [info exists AFKs([set lowertarget [string tolower $target]])]} { unset AFKs($lowertarget) }
}

# When the bot itself disconnects, clear all the AFKs:
bind evnt - disconnect-server ::afk::Evnt
proc ::afk::Evnt {event} {
	variable AFKs
	array unset AFKs *
}

# duration, based on http://wiki.tcl.tk/789, modified by fedex to support years and weeks, added features from http://inferno.slug.org/wiki/Duration with speed tweaks by me (FireEgl).
proc ::afk::duration {seconds args} {
	# avoid OCTAL interpretation, deal with negatives, split floats, handle things like .3
	foreach {seconds fraction} [split [string trimleft $seconds {-0}] {.}] {break}
	if {![string length $seconds]} { set seconds 0 }
	set timeatoms [list]
	if {![catch {
		foreach div {31449600 604800 86400 3600 60 1} mod {0 52 7 24 60 60} name {year week day hour minute second} {
			if {[lsearch -glob $args "-no${name}*"] != -1} { break }
			set n [expr {$seconds / $div}]
			if {$mod > 0} { set n [expr {$n % $mod}] }
			if {$n > 1} { lappend timeatoms "$n ${name}s" } elseif {$n == 1} { lappend timeatoms "$n $name" }
		}
	}]} {
		if {[info exists fraction] && [string length $fraction]} { if {!$n} { lappend timeatoms "0.$fraction seconds" } else { set timeatoms [lreplace $timeatoms end end "$n.$fraction seconds"] } }
		if {[llength $timeatoms]} { join $timeatoms {, } } else { return {0 seconds} }
	}
}

putlog "afk.tcl v0.9 by FireEgl@EFNet (www.Tcl.Atlantica.US) - Loaded."
