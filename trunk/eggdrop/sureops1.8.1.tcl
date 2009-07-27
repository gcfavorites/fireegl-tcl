# sureops.tcl v1.8.1 - by FireEgl@EFNet <FireEgl@EMail.Com> (www.FireEgl.cjb.Net) - October 17, 2001

### Description:
# Enhances the OP /msg command, and adds a FOP /msg command:
#   When you /msg a bot to get ops that bot will forward the op request
# to all the bots with the right user flags, and those bots will op you
# (after a delay) if the bot you asked for ops didn't beat them to it. =)
#   The FOP command does the same thing as OP except it will force all
# the bots to op you with no delay and without the bot(s) checking to make
# sure it or you already have ops (good for when either of you are desynched).
# (1.7+) Now includes INVITE/FINVITE /msg commands.

### Requirements:
# This script should run on ANY 1.3.x or higher bot.. If it doesn't then tell me.

### Changes:
# 1.0 - Initial Release.
# 1.1 - Don't remember what I changed! =P
# 1.2 - Added FOP (force op/fast op..whatever you wanna call it) msg command. The SUREST way to get ops. =)
# 1.3 - Added a feature to automatically add a persons hostmask when they ask for ops.
#     - Fixed some bugs relating to asking for ops in only one channel.
#     - The flags for the FOP command are configurable now.
# 1.4 - Now checks the $network config variable so only bots on the same network will op you. (Suggested by \-\iTman)
#     - Restructured things to make it easier to keep backwards compatibility in the future.
#       (1.4 is no longer compatible with older versions, but should be compatible with any future versions.)
#     - Added some missing putcmdlog's for FOP's.
#     - Replaced return's with set's.  (Did you know TCL is slower if you use return?)
#     - Other minor stuff.
# 1.5 - Makes sure that the person requesting ops over the botnet is the same person that's on the channel.
#     - Can optionally check to make sure that the bot we're sending to and receiving from are on IRC and in a channel.
#     - Fixed a bug that kept it from passing what channel the person wants ops in to other bots when using the OP command. (It's actually an Eggdrop bug..I just worked around it.)
#     - Put all redundant poop into so:op:common and made lots of sanity checks there.
#     - Now gives the exact reason why an FOP/OP request failed.
#     - Added settings for min and max delay times when opping someone that another bot said to op.
#     - Says which bot an FOP/OP request is coming from.
#     - Added $so(allowforce), $so(use-next), $so(showqueue), and $so(built-inop) options.
# 1.6 - Minor putlog changes.
# 1.7 - Added INVITE/FINVITE commands/options.  (requested by \-\iTman)
#     - Cleaned up the code a lot and tabbified it. =)
#     - This version is no longer compatible with older versions of this script.
# 1.8 - Added $so(max-forcerelayrequests) setting.  (requested by \-\iTman)
#     - Renamed (and tweaked) the randomiser proc so it didn't conflict with the one in netbots.tcl.
# 1.8.1 - Removed $so(max-forcerelayrequests) setting... It didn't work, and couldn't be fixed without a lot of bloat.


### Suggestions?  Comments?  Problems?
# Email me at FireEgl@EMail.Com


### Options:
## Key for encrypting stuff sent between bots (CHANGE THIS!!!):
set so(key) "YourKey"

## Bot flags:
# Global flags other bots on the botnet must have to work together.
# Note: They must have ALL the flags you list here.
set so(botflags) "of"

## Flags needed to use the FOP/FINVITE commands:
set so(f_flags) "m|n"

## Default behavior for the OP/INVITE commands..
# You can have the OP/INVITE commands behave just like FOP/FINVITE if you say 1 here.
# Notes:
# If you set this to 1 then be sure so(f_flags) are set to "o|o"
#  otherwise normal +o users won't be able to get ops/invites.
# Leaving this as 0 will still be a fairly sure (and much less annoying) way that you'll get ops/invites.
set so(default_f) 0

## Automatically add a persons hostmask if the bot
## doesn't recognize them when they ask for ops/invite?
# Note:  For this to work, their nick must be the same as their handle and
# the password they use in the op command must match that handles password.
set so(addhost) 1

## Set to 1 if you want to DISABLE checking the $network variable:
set so(nonetworkcheck) 0

## Set to 1 to check to see if both the bots are on IRC and in a channel:
# (Suggest leaving as 0, since very little is gained in security at a cost of losing effectiveness of the script during net-splits/rejoins.)
set so(botsonirc) 0

## Minimum delay (in seconds) before we'll op/invite someone that another bot told us to op:
set so(mindelay) 9

## Maximum delay (in seconds) before we'll op/invite someone that another bot told us to op:
set so(maxdelay) 57

## Allow other bots to request a forced op for someone?
# (1 = Yes, 0 = The request is treated as a normal OP/INVITE request.)
set so(allowforce) 1

## Use -next when doing putquick? (1 = yes, 0 = no) (See eggdrop/doc/tcl-commands.doc)
# (Has no effect if your Eggdrop version doesn't support -next)
set so(use-next) 0

## Use *msg:op?  (1 = yes, 0 = no)
# (If 0 it will use checks done by this script to see if they deserve ops)
set so(built-inop) 0

## Use *msg:invite?  (1 = yes, 0 = no)
# (If 0 it will use checks done by this script to see if they deserve an invite)
set so(built-ininvite) 0


### End Options...Begin Script...
bind msg - fop msg:so:fop
proc msg:so:fop {nick host hand arg} { so:op:common $nick $host $hand FOP $arg 1 }
bind msg - op msg:so:op
proc msg:so:op {nick host hand arg} { so:op:common $nick $host $hand OP $arg }
bind msg - finvite msg:so:finvite
proc msg:so:finvite {nick host hand arg} { so:op:common $nick $host $hand FINVITE $arg 1 }
bind msg - invite msg:so:invite
proc msg:so:invite {nick host hand arg} { so:op:common $nick $host $hand INVITE $arg }
proc so:op:common {nick host hand cmd arg {force "$so(default_f)"} {frombot {}}} { global so ircnet server
	set pass "[lindex [split $arg] 0]"
	if {(($so(addhost)) && ("$hand" == {*}) && ([validuser $nick]) && ([passwdok $nick $pass]) && (![passwdok $nick {-}]))} {
		*msg:ident $nick $host $hand "$pass [set hand $nick]"
		after idle {save}
	}
	set force "[subst $force]"
	if {"$frombot" != {}} { set frombot "\002@\002$frombot" } else {
		foreach b "[so_randomise [userlist b$so(botflags)&]]" {
			if {(([islinked $b]) && ((!$so(botsonirc)) || ([handonanychan $b])))} {
				putbot $b "sureops [encrypt $so(key) [list key $so(key) net $ircnet force $force nick $nick host $host hand $hand cmd $cmd arg $arg]]"
			}
		}
	}
	if {($so(use-next)) || (!$so(showqueue)) || ([catch { set queue "Queue: [queuesize mode]" }]) || ([lindex "$queue" 1] == 0)} { set queue {} }
	if {"$server" == {}} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  (I'm Not On IRC)"
	} elseif {[isbotnick $nick]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  ($nick is MY Nick!)"
	} elseif {(([matchban "$nick!$host"]) && (([catch { set exempt [matchexempt "$nick!$host"] }]) || (!$exempt)))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan ($nick!$host is Global Banned)"
	} elseif {[isignore [set mask [maskhost "$nick!host"]]]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan ($mask is in the Ignore List)"
	} elseif {![validuser $hand]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  (Invalid User)"
	} elseif {[passwdok $hand "-"]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  (Password Not Set)"
	} elseif {![passwdok $hand "$pass"]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  (Invalid Password)"
	} elseif {((([llength "[set chan [lindex [split $arg] 1]]"] == 0)) && (("$cmd" == {OP}) | ("$cmd" == {FOP})) && (![handonanychan $hand]))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  ($hand Isn't On Any Channels)"
	} elseif {(("$host" != "[set chanhost [getchanhost $nick $chan]]") && ("$chanhost" != {}))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan (\"$host\" != \"$chanhost\")"
	} elseif {(("$cmd" == {OP}) || ("$cmd" == {FOP})) && ("$chanhost" == {})} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  ($nick Isn't On Any Channels)"
	} elseif {(("[nick2hand $nick $chan]" != {}) && ("[nick2hand $nick $chan]" != "$hand"))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  ($nick ([nick2hand $nick $chan]) Stole $hand's Nick!)"
	} elseif {([llength "$chan"] == 0) && ($force)} { set didop 0
		foreach c "[so_randomise [channels]]" {
			if {(([botonchan $c]) && (![matchattr $hand |d $c]) && ([matchattr $hand $so(f_flags) $c]) && (![matchban $nick!$host $c]))} {
				if {([onchan $nick $c]) && ([handonchan $hand $c]) && (("$cmd" == {FOP}) || ("$cmd" == {OP}))} {
					set didop [so:fop $nick $c]
				} elseif {("$cmd" == {INVITE}) || ("$cmd" == {FINVITE})} {
					set didop [so:finvite $nick $c]
				}
			}
		}
		if {!$didop} { putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd  (Insufficient Flags For the Channel(s) They're In)" } else { putcmdlog "($nick!$host) !$hand$frombot! $cmd  $queue" }
	} elseif {([llength "$chan"] == 0) && (!$force)} { set didop 0
		if {("$cmd" == {OP}) || ("$cmd" == {FOP})} {
			if {$so(built-inop)} { *msg:op $nick $host $hand $arg } else {
				foreach c "[channels]" {
					if {(([botonchan $c]) && (![matchattr $hand |d $c]) && ([matchattr $hand o|o $c]) && ([onchan $nick $c]) && ([handonchan $hand $c]) && (![matchban $nick!$host $c]))} { set didop 1
						pushmode $c +o $nick
					}
				}
			}
		} elseif {("$cmd" == {INVITE}) || ("$cmd" == {FINVITE})} {
			if {$so(built-ininvite)} { *msg:invite $nick $host $hand $arg } else {
				foreach c "[channels]" {
					if {(([botonchan $c]) && (![matchattr $hand |d $c]) && ([matchattr $hand o|o $c]) && (![onchan $nick $c]) && (![matchban $nick!$host $c]))} { set didop 1
						putserv "INVITE $nick $c"
					}
				}
			}
		}
		if {$didop} { putcmdlog "($nick!$host) !$hand$frombot! $cmd  $queue" }
	} elseif {![validchan $chan]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  (Invalid Channel)"
	} elseif {[lsearch "[channel info $chan]" "+inactive"] != -1} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  (Channel is +inactive)"
	} elseif {((![catch { set juped [ischanjuped $chan] }]) && ($juped))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($chan is Juped - I Can't Join)"
	} elseif {![botonchan $chan]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  (I'm Not On $chan)"
	} elseif {[matchban "$nick!$host" $chan]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($nick!$host is Banned From $chan)"
	} elseif {(([onchansplit $nick $chan]) && (![onchan $nick $chan]))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($nick is Net-Split)"
	} elseif {(([matchban "$nick!$host" $chan]) && (([catch { set exempt [matchexempt "$nick!$host" $chan] }]) || (!$exempt)))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($nick!$host Matches a Ban on $chan)"
	} elseif {(("$cmd" == {OP}) || ($cmd == {FOP})) && (![handonchan $hand $chan])} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($hand isn't on $chan)"
	} elseif {(("$cmd" == {OP}) || ($cmd == {FOP})) && (![onchan $nick $chan])} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($nick isn't on $chan)"
	} elseif {(($force) && (![matchattr $hand $so(f_flags) $chan]))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  (Insufficient Flags - Needs +$so(f_flags) $chan)"
	} elseif {($force) && (("$cmd" == {FOP}) || ("$cmd" == {OP}))} {
		putcmdlog "($nick!$host) !$hand$frombot! $cmd $chan  $queue"
		so:fop $nick $chan
	} elseif {(($force) && (("$cmd" == {FINVITE}) || ($cmd == {INVITE})))} {
		putcmdlog "($nick!$host) !$hand$frombot! $cmd $chan  $queue"
		so:finvite $nick $chan
	} elseif {![botisop $chan]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  (I'm Not Opped On $chan)"
	} elseif {[isop $nick $chan] && (("$cmd" == {OP}) || ("$cmd" == {FOP}))} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($nick Already Opped On $chan)"
	} elseif {[matchattr $hand |d $chan]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  ($hand Has +d (de-op) Flag For $chan)"
	} elseif {![matchattr $hand o|o $chan]} {
		putcmdlog "($nick!$host) !$hand$frombot! Failed $cmd $chan  (Insufficient Flags - Needs +o|+o $chan)"
	} elseif {("$cmd" == {OP}) || ("$cmd" == {FOP})} {
		if {$so(built-inop)} { *msg:op $nick $host $hand $arg } else {
			pushmode $chan +o $nick
			putcmdlog "($nick!$host) !$hand$frombot! $cmd $chan $queue"
		}
	} elseif {("$cmd" == {INVITE}) || ("$cmd" == {FINVITE})} {
		if {$so(built-ininvite)} { *msg:invite $nick $host $hand $arg } else {
			putserv "INVITE $nick $chan"
			putcmdlog "($nick!$host) !$hand$frombot! $cmd $chan $queue"
		}
	} else {
		# It can't fall through this far..but anyways..
		catch { *msg:[string tolower $cmd] $nick $host $hand $arg }
	}
}

proc so:fop {nick channel} { global so
	if {!$so(use-next) || [catch { putquick "MODE $channel +o $nick" -next }]} { putquick "MODE $channel +o $nick" }
	set channel 1
}

proc so:finvite {nick channel} { global so
	if {!$so(use-next) || [catch { putquick "INVITE $nick $channel" -next }]} { putquick "INVITE $nick $channel" }
	set channel 1
}

bind bot b$so(botflags) sureops bot:sureops
proc bot:sureops {from cmd arg} { global so ircnet server
	if {(([matchattr $from b$so(botflags)&]) && ("$server" != {}) && ((!$so(botsonirc)) || ([handonanychan $from])))} { set force "$so(default_f)"
		if {![islist [set d [decrypt $so(key) $arg]]]} {
			return [putlog "sureops.tcl: Error: Possible fake sureops command from bot $from - They didn't send a list."]
		} elseif {[lindex $d 1] != $so(key)} {
			return [putlog "sureops.tcl: Error: Bot $from didn't encrypt using the right password!"]
		} else {
			foreach {a b} "$d" { set $a $b }
		}
		if {($so(nonetworkcheck)) || ("[string tolower $ircnet]" == "[string tolower $net]")} {
			if {(($force) && ($so(allowforce)))} { so:op:common $nick $host $hand $cmd $arg $force $from } else {
				utimer [expr $so(mindelay) + [rand $so(maxdelay)]] [list so:op:common $nick $host $hand $cmd $arg $force $from]
			}
		}
	}
}

if {"[info commands islinked]" == {}} { proc islinked {bot} { if {[lsearch -exact [string tolower [bots]] [string tolower "$bot"]] == -1 } { set bot 0 } { set bot 1 } } }
if {"[info commands putquick]" == {}} { proc putquick {message {next {}}} { putserv "$message" } }
if {"[info commands botonchan]" == {}} {
	proc botonchan {channel} { global botnick
		if {[onchan $botnick $channel]} { set channel 1 } { set channel 0 }
	}
}

## My tweaked version of slennox's nb_randomise proc (from netbots.tcl):
proc so_randomise {list} { set randlist {}
	set length [llength $list]
	while {$length > 0} {
		lappend randlist [lindex $list [set random [rand $length]]]
		set list [lreplace $list $random $random]
		incr length -1
	}
	set randlist
}

# Any command (IMO) that doesn't require a channel to get the info shouldn't complain if you give it an invalid channel...
# getchanhost:
if {(([catch { getchanhost Nick }]) && ("[info commands getchanhost.orig]" == {}))} {
	rename getchanhost getchanhost.orig
	# Makes older Eggdrops no longer require a channel to be specified:
	# It also will search all channels if it doesn't find their host in the one specified.
	proc getchanhost {nick {channel {}}} { set out {}
		if {([llength "$channel"] == 0) || (![validchan "$channel"]) || ([set out "[getchanhost.orig $nick $channel]"] == {})} {
			foreach c "[channels]" {
				if {[onchan "$nick" "$c"]} {
					set out "[getchanhost.orig $nick $c]"
					break
				}
			}
		}
		set out
	}
} elseif {(([catch { getchanhost SomeNick "#IllegalChannel[rand 999]" }]) && ("[info commands getchanhost.orig]" == {}))} {
	rename getchanhost getchanhost.orig
	# Newer Eggdrops no longer complain when a channel is invalid:
	# It also will search all channels if it doesn't find their host in the one specified.
	proc getchanhost {nick {channel {}}} { set out {}
		if {([llength "$channel"] == 0) || (![validchan "$channel"]) || ([set out "[getchanhost.orig $nick $channel]"] == {})} { set out [getchanhost.orig "$nick"] }
		set out
	}
}
# hand2nick:
if {[catch { hand2nick {Handle} }]} {
	rename hand2nick hand2nick.orig
	# For Old Eggdrops to not require a channel and not complain if an invalid one was specified:
	proc hand2nick {handle {channel {}}} { set out {}
		if {([llength "$channel"] == 0) || (![validchan "$channel"])} {
			foreach c "[channels]" {
				if {[handonchan "$handle" "$c"]} { set out "[hand2nick.orig $handle $c]"
					break
				}
			}
		} else {
			set out "[hand2nick.orig $handle $channel]"
		}
		set out
	}
} elseif {[catch { hand2nick {Handle} "#IllegalChannel[rand 999]" }]} {
	rename hand2nick hand2nick.orig
	# For New Eggdrops to not complain if a channel is invalid:
	proc hand2nick {handle {channel {}}} {
		if {([llength "$channel"] == 0) || (![validchan "$channel"])} {
			hand2nick.orig "$handle"
		} else {
			hand2nick.orig "$handle" "$channel"
		}
	}
}
# nick2hand:
if {[catch { nick2hand {Nick} }]} {
	rename nick2hand nick2hand.orig
	# For Old Eggdrops to not require a channel and not complain if an invalid one was specified:
	proc nick2hand {nick {channel {}}} { set out {}
		if {([llength "$channel"] == 0) || (![validchan "$channel"])} {
			foreach c "[channels]" {
				if {[onchan "$nick" "$c"]} {
					set out "[nick2hand.orig $nick $c]"
					break
				}
			}
		} else {
			set out "[nick2hand.orig $nick $channel]"
		}
		set out
	}
} elseif {[catch { nick2hand {Nick} "#IllegalChannel[rand 999]" }]} {
	rename nick2hand nick2hand.orig
	# For New Eggdrops to not complain if a channel is invalid:
	proc nick2hand {nick {channel {}}} {
		if {([llength "$channel"] == 0) || (![validchan "$channel"])} {
			nick2hand.orig "$nick"
		} else {
			nick2hand.orig "$nick" "$channel"
		}
	}
}
# My handonanychan proc:
if {"[info commands handonanychan]" == {}} {
	proc handonanychan {handle} { set retval 0
		foreach c "[channels]" {
			if {[handonchan "$handle" "$c"]} {
				set retval 1
				break
			}
		}
		set retval
	}
}

# Determines if a string is also a list:
proc islist {s} {expr ![catch {llength $s}]}

## Show # of msgs in the mode queue when doing FOP/FINVITE?  (1 = yes, 0 = no)
# (See queuesize in doc/tcl-command.doc)
# Notes:
# If so(use-next) is enabled it won't show the queue.
# It also won't show the queue if the queue has 0 modes queued in it.
# Nor CAN it show the queue if your Eggdrop version doesn't support queuesize. =P
set so(showqueue) 1

if {(![info exists network]) || ([llength "$network"] == 0)} { set network {I.didnt.edit.my.config.file.net} }
# Tothwolf has a script that adds the current irc server to the $network var, but we only want the network name from it, so we do this and use $ircnet in the rest of the script:
set ircnet "[lindex [split $network] 0]"
putlog "[set so(longver) "[set so(ver) "sureops.tcl [set so(shortver) {1.8.1}]"] by FireEgl@EFNet <FireEgl@EMail.Com> (www.FireEgl.cjb.Net)"] - Loaded."
