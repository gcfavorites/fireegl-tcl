# keeptopic.tcl v1.5 - by FireEgl@EFNet <FireEgl@LinuxFan.com> - May 2004

### Description:
# Load this script on all your bots and you'll never have an empty topic again.
#   ..well..almost never. =P
# It saves the topic when it's changed, and sets it back if it's ever empty.

### Notes:
# Only one random bot will set it back (if it's empty) within 99-239 seconds
# of someone joining.. This delay is to help prevent any topic setting floods
# by the bots after a split.. =)
# This script tries to be as unannoying as possible and still keep the topic set..
# There's much easier and more reliable ways to keep the topic set though..
# ..they're just more annoying.  (See below.)

### Alternatives to using this script:
# If you want a keep topic type script that's more reliable, but also very annoying...
# (it resets the topic every 60 mins without any checking)
# then get:
# ftp://ftp.EggHeads.org/pub/eggdrop/scripts1.3/topic-resynch1b9.tcl.gz

### History:
# 1.5 - Fixed a small bug in dotopic. (Apr 2004)
# 1.4 - Added some options, cleaned up the code. (Oct 2001)
# 1.3 - More small stuff not worth mentioning.
# 1.2 - Changed the bind join to bind rejn. (because it's net rejoins when the topic is lost)
#     - Few other small stuff.
# 1.1 - No more -user -bot -bot -bot sorta things in the topics. ;P
# 1.0 - Released.

### Options:
## Append who set the topic to the end?
# (1 = yes, 0 = no)
set keeptopic(append-who) 1

## Min delay (in seconds) after a net-rejoin before the bot will put the topic back (if needed):
set keeptopic(min-delay) 99

## Max delay (in seconds) after a net-rejoin before the bot will put the topic back (if needed):
set keeptopic(max-delay) 237



### Begin Script:

# Saves the topic, unless somebody just cleared it.
bind topc o|o * topic:savetopic
proc topic:savetopic {nick host hand chan topic} {
	if {"$topic" != {}} { global lasttopic keeptopic lasttopicnick 
		set lasttopic([set chan [string tolower $chan]]) "$topic"
		if {$keeptopic(append-who)} {
			if {[matchattr $hand b]} {
				set lasttopicnick($chan) "$hand"
			} else {
				if {"[string tolower $hand]" == "[string tolower $nick]"} { set lasttopicnick($chan) "$nick!$host" } else { set lasttopicnick($chan) "$nick!$host ($hand)" }
			}
		}
	}
}

# This one makes it check the topic after a netsplit:
bind rejn - * rejn:checktopic
proc rejn:checktopic {nick host hand chan} { global lasttopic keeptopic
	if {(([topic [set chan [string tolower $chan]]] == {}) && ([info exists lasttopic($chan)]))} {
		foreach t "[utimers]" { if {[string match [string tolower "dotopic $chan"] "[string tolower [lindex $t 1]]"]} { killutimer "[lindex $t 2]" } }
		utimer [expr $keeptopic(min-delay) + [rand $keeptopic(max-delay)]] [list dotopic $chan]
	}
}

# Sets the topic back, unless someone else or another bot has already done it:
proc dotopic {chan} {
	if {"[topic $chan]" == {}} { global keeptopic lasttopicnick lasttopic
		if {$keeptopic(append-who) || [matchattr [lindex $lasttopicnick($chan) 0] b]} {
			set topic "$lasttopic($chan)"
		} elseif {[info exists lasttopicnick($chan)]} {
			set topic "$lasttopic($chan) -$lasttopicnick($chan)"
		}
		puthelp "TOPIC $chan :$topic"
	}
}

putlog "keeptopic.tcl v[set keeptopic(ver) {1.5}] by FireEgl@EFNet <FireEgl@EMail.Com> (www.FireEgl.cjb.Net) - Loaded."
