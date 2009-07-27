# chanredir.tcl v0.2-beta by FireEgl

## Description:
# This script was intended to redirect people from #EggTcl to #Tcl on EFNet.
# And also to redirect people from #Xubuntu/#Kubuntu/#Edubuntu to #Ubuntu.

## Notes:
# Edit the settings below, and set your channel(s) +chanredir

## Settings:
namespace eval ::chanredir {	variable settings
	# channel names (the ones you're redirecting from anyway) should be lowercase!
		# redirchan is the channel you want to tell people to join.
		# delay is the time in seconds to wait before telling them to join the other channel.
		# invite (optional) should be 1 to send them an INVITE to join the other channel, 0 otherwise.
		# topic (optional) should be the TOPIC to set on the channel.
		# msg (optional) should be the PRIVMSG to send to the nick.
		# notice (optional) should be the NOTICE to send to the nick.
		# chanmsg (optional) should be the PRIVMSG to send to the channel.
		# channotice (optional) should be the NOTICE to send to the channel.
	array set settings {
		{#eggtcl} {
			redirchan #Tcl
			delay 999
			invite 1
		}
		{#tcl/tk} {
			redirchan #Tcl
			delay 7
			invite 1
			topic {/join #Tcl instead for Tcl/Tk help.}
			channotice {Please join #Tcl instead if you need Tcl/Tk help.}
		}
		{#tclhelp} {
			redirchan #Tcl
			delay 7
			invite 1
			topic {/join #Tcl instead for Tcl help.}
			channotice {Please join #Tcl instead if you need Tcl help.}
		}
		{#kubuntu} {
			redirchan #Ubuntu
			delay 9
			invite 1
			topic {/join #Ubuntu instead, this channel is closed.}
			channotice {Please join #Ubuntu instead, it covers all variants.}
		}
		{#xubuntu} {
			redirchan #Ubuntu
			delay 9
			invite 1
			topic {/join #Ubuntu instead, this channel is closed.}
			channotice {Please join #Ubuntu instead, it covers all variants.}
		}
		{#edubuntu} {
			redirchan #Ubuntu
			delay 7
			invite 1
			topic {/join #Ubuntu instead, this channel is closed.}
			channotice {Please join #Ubuntu instead, it covers all variants.}
		}
		{#gobuntu} {
			redirchan #Ubuntu
			delay 7
			invite 1
			topic {/join #Ubuntu instead, this channel is closed.}
			channotice {Please join #Ubuntu instead, it covers all variants.}
		}
		{#fluxbuntu} {
			redirchan #Ubuntu
			delay 9
			invite 1
			topic {/join #Ubuntu instead, this channel is closed.}
			channotice {Please join #Ubuntu instead, it covers all variants.}
		}
		{#ubuntunorge} {
			redirchan #Ubuntu
			delay 9
			invite 1
			topic {/join #Ubuntu instead, this channel is inactive.}
			channotice {Please join #Ubuntu instead.}
		}
		{#noobuntu} {
			redirchan #Ubuntu
			delay 11
			invite 1
			topic {/join #Ubuntu instead..noob. =P}
			channotice {Please join #Ubuntu instead.}
		}
		{#ubuntuhelp} {
			redirchan #Ubuntu
			delay 9
			invite 1
			topic {/join #Ubuntu instead, this channel is inactive.}
			channotice {Please join #Ubuntu instead if you need help.}
		}
		{#freespire} {
			redirchan #Ubuntu
			delay 3
			invite 1
		}
		{#gnewsense} {
			redirchan #Ubuntu
			delay 7
			invite 1
			topic {/join #Ubuntu instead, this channel is inactive.}
			channotice {Please join #Ubuntu instead if you need help.}
		}
		{#ubuntustudio} {
			redirchan #Ubuntu
			delay 8
			invite 1
			topic {/join #Ubuntu instead, this channel is inactive.}
			channotice {Please join #Ubuntu instead if you need help.}
		}
		{#colinux} {
			delay 7
			topic {Go to #coLinux on IRC.OFTC.Net instead.}
		}
		{#zipit} {
			delay 7
			topic {ZipIt! - http://WWW.eLinux.Org/ZipIt}
			channotice {Go to #eDev on IRC.FreeNode.Net instead, there's lots of ZipIt modders there.}
		}
		{#atlantica.us} {
			delay 7
			topic {Official Channel: #Atlantica.US on IRC.Atlantica.US}
			channotice {Go to #Atlantica.US on IRC.Atlantica.US instead.}
		}
	}
}

proc ::chanredir::Join {nick uhost hand chan} {	variable settings
	variable Nicks
	variable Hosts
	if {$hand eq {*} && ${::strict-host} == 1} {
		set ::strict-host 0
		set hand [nick2hand $nick $chan]
		set ::strict-host 1
	}
	if {[info exists settings([set chan [string tolower $chan]])] && $hand eq {*} && [channel get $chan chanredir] && ![info exists Nicks($chan,$nick)] && ![info exists Hosts($chan,[lindex [split $uhost @] end])] && ![matchban "$nick!$uhost" $chan] && ![matchexempt "$nick!$uhost" $chan] && ![matchinvite "$nick!$uhost" $chan] && ![validuser $nick]} {
		array set chaninfo $settings($chan)
		set Nicks($chan,$nick) [clock seconds]
		set Hosts($chan,[lindex [split $uhost @] end]) [clock seconds]
		if {![info exists chaninfo(redirchan)] || ([validchan $chaninfo(redirchan)] && ![onchan $nick $chaninfo(redirchan)])} { utimer $chaninfo(delay) [list ::chanredir::RedirUser $nick $uhost $hand $chan] }
	}
}

proc ::chanredir::RedirUser {nick uhost hand chan} {	variable settings
	array set chaninfo $settings($chan)
	if {[onchan $nick $chan] && ![isop $nick $chan] && ![isvoice $nick $chan] && ![ishalfop $nick $chan] && (![info exists chaninfo(redirchan)] || ![onchan $nick $chaninfo(redirchan)])} {
		if {[info exists chaninfo(topic)] && [string trim $chaninfo(topic)] ne {} && [rand 2] && [string trim [topic $chan]] eq {}} { puthelp "TOPIC $chan :$chaninfo(topic)" }
		if {[info exists chaninfo(msg)] && [string trim $chaninfo(msg)] ne {}} { puthelp "PRIVMSG $nick :$chaninfo(msg)" }
		if {[info exists chaninfo(notice)] && [string trim $chaninfo(notice)] ne {}} { puthelp "NOTICE $nick :$chaninfo(notice)" }
		if {[info exists chaninfo(chanmsg)] && [string trim $chaninfo(chanmsg)] ne {}} { puthelp "PRIVMSG $chan :$chaninfo(chanmsg)" }
		if {[info exists chaninfo(channotice)] && [string trim $chaninfo(channotice)] ne {}} { puthelp "PRIVMSG $chan :$chaninfo(channotice)" }
		if {[info exists chaninfo(redirchan)]} {
			if {([info exists chaninfo(invite)] && $chaninfo(invite)) && ([botisop $chaninfo(redirchan)] || [botishalfop $chaninfo(redirchan)])} { puthelp "INVITE $nick $chaninfo(redirchan)" }
			putlog "ChanRedir: Told $nick!$uhost on $chan to go to $chaninfo(redirchan)."
		} else {
			putlog "ChanRedir: Told $nick!$uhost on $chan to go elsewhere."
		}
	}
}

namespace eval ::chanredir {
	variable Nicks
	array set Nicks {}
	variable Hosts
	array set Hosts {}
	# FixMe: Clean out old entries from Nicks and Hosts periodically.
	bind join - {* *!*@*} ::chanredir::Join
	setudef flag chanredir
	variable version {0.2}
	putlog "chanredir.tcl v$version - Loaded."
}
