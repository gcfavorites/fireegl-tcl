# whatswhat.tcl - by FireEgl <FireEgl@GMail.Com> - May 2006.

# FixMe's/TODO's:

# [21:26:52] <+rodb> Some indication in partyline of received commands

# [21:26:52] <+rodb> Users using helpwhat receive only the items they have access to

# [21:26:52] <+rodb> No error message from users that have no access to script when using commands

# [21:26:53] <+rodb> No flag users getting full search through ??

# [21:26:53] <+rodb> Maybe one line limit, 10 or 12 limit, or a setting on maximum to return on a "not found" search

# [21:26:59] <+rodb> flood control

# [21:37:39] <+rodb> looks like i have a keyword stored with no defs

# [20:38:28] <+rodb> the ?? -h -a -h need a flag setting

# test test test! =P

# cleanup cleanup cleanup!!

namespace eval ::whatswhat {
	# Database filename:
	variable dbfile "whatswhat.dat"
	# Allow duplicate definitions to exist for a keyword? (1 = yes, 0 = no):
	variable duplicate 1
	# Max definitions to show on the channel when searching (unless the keyword is set -hide):
	variable maxshow 5
	## Global default to number definitions:
	# Set to 1 to default to numbering definitions, 0 to default to not, or -1 to let the script decide when to number or not.
	variable number 0
	# This means 3 lines in 10 seconds will trigger a flood: (FixMe..)
	variable flood "3:10"
	# How to send +hide'n keywords, and error messages (set to NOTICE or PRIVMSG):
	variable private-method "NOTICE"
	# This is the interval, in _hours_ that an email of the database will be sent (168 = 1 week):
	variable email-interval {168}
	# Email addresses to send the WhatsWhat.dat to (set to "" to disable):
	set email(to) "WhatsWhat@Atlantica.US"
	# Use this as the From: in the email:
	set email(from) "$::tcl_platform(user)@[info hostname]"
	# Subject of the email:
	set email(subject) "$dbfile backup."
	# Body of the email:
	set email(body) "Attached is the ${dbfile}."
	# These are words that separate keywords from definitions (so the script can know when a multi-word keyword ends and it's definition begins):
	variable separators {\=\=|\=\>|=|\>\>|\-\>|is a|are a}
	# Binds:
	variable binds {
		{pub msg} o|o .learn learn {
			{$bind keyword definition | Creates or adds a definition for a keyword.}
			{$bind keyword keyword == definition | Creates or adds a definition for a multi word keyword.}
		}
		{pub msg} o|o .+number +number {
			{$bind keyword | Restores the number prefix of each definition when displayed.}
		}
		{pub msg} o|o .-number -number {
			{$bind keyword | Deletes the number prefix of each definition when displayed.}
		}
		{pub msg} o|o .+hide +hide {
			{$bind keyword | Sets definitions for a keyword to be sent via Notice only.}
		}
		{pub msg} o|o .-hide -hide {
			{$bind keyword | Unsets definitions for a keyword to be sent via Notice only.}
		}
		{pub msg} o|o .delete delete {
			{$bind keyword # | Deletes definition number # of a keyword.}
			{$bind keyword 0 | Deletes a keyword and all it's definitions.}
		}
		{pub msg} o|o .forget delete {}
		{pub msg} o|o .remove delete {}
		{pub msg} o|o .insert insert {
			{$bind keyword # definition | Inserts a definition at position # for a keyword.}
		}
		{pub msg} o|o .replace replace {
			{$bind keyword # definition | Replace a definition at position # for a keyword.}
		}
		{pub msg} m|m .stats stats {
			{$bind | Statistics for the database.}
		}
		{pub msg} m|m .ssave save {
			{$bind | Sort and save database.}
		}
		{pub msg} m|m .email email {
			{$bind | Sort, save and email the database.}
		}
		{pub msg} vof|vof .send send {
			{$bind -n nick keyword | Sends the definition for a keyword to a nick via Notice.}
			{$bind -c nick keyword | Sends the definition for a keyword to a nick via #channel.}
			{$bind #channel keyword | Sends the definition for a keyword to a channel.}
		}
		{pub msg} -|- .helpwhat help {
			{$bind | You're looking at it.}
		}
		{pub msg} vof|vof .search search {
			{$bind word | Searches keywords, definitions and nicks for match.  Can use * and ? as wildcards.}
		}
		{pub msg} vof|vof \*\* search {}
		{pub msg} -|- \?\? whatis {
			{$bind keyword | Display definitions for a keyword.}
			{$bind -a keyword | Display definitions, date/time and author for a keyword.}
		}
		{pub msg} -|- .whatis whatis {}
		{pub msg} -|- .whatswhat whatis {}
	}
}

bind evnt - save ::whatswhat::EVNT_save
bind evnt - sighup ::whatswhat::EVNT_save
bind evnt - prerehash ::whatswhat::EVNT_save
bind evnt - prerestart ::whatswhat::EVNT_save
bind evnt - logfile ::whatswhat::EVNT_save
proc ::whatswhat::EVNT_save {event} {
	putlog "WhatsWhat: Saving the database... (Event: $event)"
	Save
}

# This is for people that mistakenly type "??keyword" instead of "?? keyword":
bind pubm - {% \?\?*} ::whatswhat::PUBM_whatis
proc ::whatswhat::PUBM_whatis {nick host hand chan text} { PUB_whatis $nick $host $hand $chan [string trimleft $text {*?	 }] }

proc ::whatswhat::PUB_help {nick host hand chan text args} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	variable flood
	if {[detectflood $flood $host]} { return 0 }
	array set options [list type pub]
	array set options $args
	variable private-method
	variable binds
	foreach {t f bind p h} $binds {
		if {[matchattr $hand $f $chan]} {
			foreach t $t {
				if {$t == $options(type)} {
					foreach h $h {
						if {$chan != {}} {
							putfast "${private-method} $nick :[subst -nocommands -nobackslashes $h]"
						} else {
							putfast "PRIVMSG $nick :[subst -nocommands -nobackslashes $h]"
						}
					}
				}
			}
		}
	}
}
proc ::whatswhat::MSG_help {nick host hand text} { PUB_help $nick $host $hand {} $text type msg }

proc ::whatswhat::PUB_email {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	Save
	if {[set text [string trim $text]] == {}} {
		Email
		set text "default address."
	} else {
		Email to $text
	}
	set message "Sent database to $text"
	if {$chan != {}} {
		putfast "PRIVMSG $chan :$message"
	} else {
		putfast "PRIVMSG $nick :$message"
	}
}
proc ::whatswhat::MSG_email {nick host hand text} { PUB_email $nick $host $hand {} $text }

proc ::whatswhat::PUB_learn {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	variable separators
	variable private-method
	if {[regexp -nocase "^(.*?) (${separators}) (.*)\$" [set text [string trim $text]] all keyword separator definition]} {
	} elseif {[regexp -nocase {^(.*?) (.*)$} $text all keyword definition]} {
		set separator {==}
	} else {
		if {$chan != {}} {
			putfast "${private-method} $nick :Usage: .learn keyword definition"
		} else {
			putfast "PRIVMSG $nick :Usage: .learn keyword definition"
		}
		return 0
	}
	if {[string is print -strict [string trim $keyword]]} {
		array set result [Set $keyword add separator $separator definition $definition author $hand]
		if {$chan == {}} {
			putfast "PRIVMSG $nick :$result(message)"
		} else {
			putfast "PRIVMSG $chan :$result(message)"
		}
	} else {
		if {$chan == {}} {
			putfast "PRIVMSG $nick :keywords must contain only printable characters."
		} else {
			putfast "${private-method} $nick :keywords must contain only printable characters."
		}
	}
}
proc ::whatswhat::MSG_learn {nick host hand text} { PUB_learn $nick $host $hand {} $text }

proc ::whatswhat::whatis {keywords opts} {
	variable private-method
	array set options [list globsearch 0 hide -1 number -1 show [list definitions] send-mode 0 from-method ${private-method} to-method ${private-method}]
	array set options $opts
	array set return [Get $keywords [array get options]]
	variable database
	switch -- [llength $return(keywords)] {
		{0} {
			# Zero matches.
			set message "No matches for $return(pattern)"
			if {!$options(send-mode)} {
					if {$options(from-chan) != {}} {
						putfast "$options(from-method) $options(from-chan) :$message"
					} elseif {$options(from-nick) != {}} {
						putfast "$options(from-method) $options(from-nick) :$message"
					} elseif {$options(to-chan) != {}} {
						putfast "$options(to-method) $options(to-chan) :$message"
					} elseif {$options(to-nick) != {}} {
						putfast "$options(to-method) $options(to-nick) :$message"
					} else {
						return -code error "You need to specify from-chan or from-nick."
					}
			} else {
				if {$options(from-chan) != {}} {
					putfast "$options(from-method) $options(from-chan) :$message"
				} elseif {$options(from-nick) != {}} {
					putfast "$options(from-method) $options(from-nick) :$message"
				} else {
					return -code error "You need to specify from-chan or from-nick."
				}
			}
		}
		{1} {
			if {$return(code)} {
				# 1 EXACT match, return it.
				if {![string equal -nocase [lindex $return(keywords) 0] $keywords] && [lsearch -glob $options(show) {key*}] == -1} { set options(show) [linsert $options(show) 0 keywords] }
				array set keyinfo $database([lindex $return(keywords) 0])
				if {$options(number) == -1} {
					if {[set options(number) $keyinfo(number)] == -1} {
						variable number
						set options(number) $number
					}
				}
				set count 0
				set lines [list]
				foreach d $keyinfo(definitions) {
					array set definfo $d
					if {([llength $keyinfo(definitions)] > 1 && $options(number)) || ($options(number) == 1)} { set num "|[incr count]|" } else { set num {} }
					set show {}
					foreach s $options(show) {
						switch -glob -- $s {
							{key*} { append show "$keyinfo(keyword) " }
							{def*} {
								if {$definfo(separator) == {==}} { set definfo(separator) {} }
								if {$options(to-nick) != {}} { set nick $options(to-nick) } else { set nick {y'all} }
								append show [string trim "$num [string trim "$definfo(separator) [string map [list {$nick} $nick {$time} [strftime {%H:%M} [clock seconds]] {$date} [strftime {%m-%d-%Y} [clock seconds]] {$uptime} [duration [expr {[clock seconds] - $::uptime}]] {\003} \003 {\002} \002 {\017} \017 {\037} \037 {\026} \026 {\017} \017 {\001} {}] $definfo(definition)]"]"]
							}
							{auth*} - {creat*} { append show " ([strftime {%m-%d-%Y@%I:%M%p} $definfo(created)]|$definfo(author))" }
						}
					}
					lappend lines $show
				}
				if {$options(send-mode)} {
					if {$options(to-chan) == {} && $options(to-nick) != {}} {
						# It's to a nick, and no channel.
						putfast "$options(to-method) $options(to-nick) :$options(from-nick) wanted to tell you about $keywords ..."
						foreach l $lines { putfast "$options(to-method) $options(to-nick) :$l" }
						putfast "$options(from-method) $options(from-nick) :Sent \"$keywords\" to $options(to-nick) via $options(to-method)."
					} elseif {$options(to-nick) != {} && $options(to-chan) != {}} {
						# It's to a nick on a channel.
						putfast "$options(to-method) $options(to-chan) :$options(to-nick): $options(from-nick) wanted to tell you about $keywords ..."
						foreach l $lines { putfast "$options(to-method) $options(to-chan) :$l" }
						#putfast "$options(from-method) $options(from-nick) :Sent \"$keywords\" to $options(to-nick) on $options(to-chan)."
					} elseif {$options(to-chan) != {} && $options(to-nick) == {}} {
						# It's to a channel, and no nick.
						#putfast "$options(to-method) $options(to-chan) :$options(from-nick) wanted to let you all know about $keywords ..."
						foreach l $lines { putfast "$options(to-method) $options(to-chan) :$l" }
						#putfast "$options(from-method) $options(from-nick) :Sent \"$keywords\" to $options(to-chan) via $options(to-method)."
					} else {
						return -code error "You need to specify to-chan and/or to-nick."
					}
				} else {
					variable maxshow
					# FixMe: Compress all these if's once the functionality is agreed upon:
					if {$options(to-chan) == {} && $options(to-nick) != {}} {
						# It's to a nick, and no channel.
						foreach l $lines { putfast "$options(to-method) $options(to-nick) :$l" }
					} elseif {($return(hide) == 1 || $options(hide) == 1) && $options(to-nick) != {}} {
						# Forced to nick.
						foreach l $lines { putfast "$options(to-method) $options(to-nick) :$l" }
					} elseif {($return(hide) == 0 || $options(hide) == 0) && $options(to-chan) != {}} {
						# Forced to channel.
						foreach l $lines { putfast "$options(to-method) $options(to-chan) :$l" }
					} elseif {$options(to-chan) != {} && [llength $lines] < $maxshow} {
						# Sent to a channel when it's less than $maxshow.
						foreach l $lines { putfast "$options(to-method) $options(to-chan) :$l" }
					} elseif {$options(to-nick) != {}} {
						# Fallback to sending to the nick.
						foreach l $lines { putfast "$options(to-method) $options(to-nick) :$l" }
					} elseif {$options(to-chan) != {}} {
						# Fallback to sending to the channel.
						foreach l $lines { putfast "$options(to-method) $options(to-chan) :$l" }
					} else {
						return -code error "You need to specify to-chan or to-nick."
					}
				}
			} else {
				# 1 non-exact match, tell them the match:
				# This will get the keywords in their original CaSe:
				array set keyinfo $database([lindex $return(keywords) 0])
				set message "One non-exact match for $keywords: $keyinfo(keyword)"
				# FixMe: Compress:
				if {!$options(send-mode)} {
					if {$options(from-chan) != {}} {
						putfast "$options(from-method) $options(from-chan) :$message"
					} elseif {$options(from-nick) != {}} {
						putfast "$options(from-method) $options(from-nick) :$message"
					} else {
						return -code error "You need to specify from-chan or from-nick."
					}
				} else {
					if {$options(from-chan) != {}} {
						putfast "$options(from-method) $options(from-chan) :$message"
					} elseif {$options(from-nick) != {}} {
						putfast "$options(from-method) $options(from-nick) :$message"
					} else {
						return -code error "You need to specify from-chan or from-nick."
					}
				}
			}
		}
		{default} {
			# Multiple matches, return the list of their keywords:
			# This will get the keywords in their original CaSe:
			set keys [list]
			foreach k $return(keywords) {
				array set keyinfo $database($k)
				lappend keys $keyinfo(keyword)
			}
			if {$options(globsearch)} {
				set message "$options(to-nick): Multiple matches for \"$return(pattern)\" ([llength $keys] total): [join $keys {, }]. "
			} else {
				set message "$options(to-nick): \"$keywords\" was not found, but the following keywords match \"$return(pattern)\" ([llength $keys] total): [join $keys {, }]."
			}
			# FixMe: Compress this when the functionality is settled:
			if {!$options(send-mode)} {
				if {$options(from-chan) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(from-chan) :$l" }
				} elseif {$options(to-chan) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(to-chan) :$l" }
				} elseif {$options(from-nick) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(from-nick) :$l" }
				} elseif {$options(to-nick) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(to-nick) :$l" }
				} else {
					return -code error "You need to specify from-chan or from-nick."
				}
			} else {
				if {$options(from-chan) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(from-chan) :$l" }
				} elseif {$options(to-chan) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(to-chan) :$l" }
				} elseif {$options(from-nick) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(from-nick) :$l" }
				} elseif {$options(to-nick) != {}} {
					foreach l [wrapstring $message] { putfast "$options(from-method) $options(to-nick) :$l" }
				} else {
					return -code error "You need to specify from-chan or from-nick."
				}
			}
		}
	}
}

proc ::whatswhat::PUB_whatis {nick host hand chan text args} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	variable flood
	if {[detectflood $flood $host]} { return 0 }
	variable private-method
	if {[set text [string trim $text]] == {}} {
		if {$chan == {}} {
			putfast "PRIVMSG $options(from-nick) :You must specify a keyword after ??"
		} else {
			putfast "${private-method} $options(from-nick) :You must specify a keyword after ??"
		}
		return 0
	}
	array set options [list show [list definitions] send-mode 0 from-method PRIVMSG from-nick $nick from-chan $chan to-method PRIVMSG to-nick $nick to-chan $chan]
	array set options $args
	if {![regexp {^(-.*?) (.*)$} [set text [string trim $text]] all options(options) keywords]} {
		set options(options) {}
		set keywords $text
	}
	foreach o [split $options(options) {}] {
		switch -- $o {
			{-} - {+} { }
			{n} { set options(number) 1 }
			{k} { if {[lsearch -glob $options(show) {key*}] == -1} { set options(show) [linsert $options(show) 0 keywords] } }
			{a} - {c} { if {[lsearch -glob $options(show) {auth*}] == -1} { lappend options(show) {authors} } }
			{h} {
				if {$chan != {}} {
					PUB_send $nick $host $hand $chan "$chan $keywords"
					return 0
				}
			}
			{default} {
				if {$chan == {}} {
					putfast "PRIVMSG $options(from-nick) :Unknown option: -$o"
				} else {
					putfast "${private-method} $options(from-nick) :Unknown option: -$o"
				}
			}
		}
	}
	whatis $keywords [array get options]
}
proc ::whatswhat::MSG_whatis {nick host hand text} {
	PUB_whatis $nick $host $hand {} $text send-mode 0 from-method PRIVMSG from-nick $nick from-chan {} to-method PRIVMSG to-nick $nick to-chan {}
}
proc ::whatswhat::PUB_search {nick host hand chan text} {
	PUB_whatis $nick $host $hand $chan $text globsearch 1 send-mode 0 from-method PRIVMSG from-nick $nick from-chan $chan to-method PRIVMSG to-nick $nick to-chan $chan
}
proc ::whatswhat::MSG_search {nick host hand text} {
	PUB_whatis $nick $host $hand {} $text globsearch 1 send-mode 0 from-method PRIVMSG from-nick $nick from-chan {} to-method PRIVMSG to-nick $nick to-chan {}
}

proc ::whatswhat::PUB_send {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	variable private-method
	if {[regexp {^(-.*?) (.*?) (.*)$} [set text [string trim $text]] all options nickchan keywords]} {
		foreach o [split $options {}] {
			switch -- $o {
				{-} - {+} - {} { }
				{n} {
					# Send to nick via ${private-method}.
					set to-method ${private-method}
					set to-nick $nickchan
					set to-chan {}
				}
				{c} {
					# Send to nick on channel via PRIVMSG.
					set to-method {PRIVMSG}
					set to-nick $nickchan
					set to-chan $chan
				}
				{default} {
					if {$chan != {}} {
						putfast "${private-method} $nick :Unknown option: -$o"
					} else {
						putfast "PRIVMSG $nick :Unknown option: -$o"
					}
				}
			}
		}
	} elseif {[regexp {^(.*?) (.*)$} $text all nickchan keywords]} {
		if {[validchan $nickchan]} {
			# Send to channel (NOT directed to a nick).
			set to-method {PRIVMSG}
			set to-nick {}
			set to-chan $nickchan
		} elseif {([validchan $chan] && [onchan $nickchan $chan]) || ([onchan $nickchan])} {
			# Send to nick via ${private-method}.
			set to-method ${private-method}
			set to-nick $nickchan
			set to-chan {}
		} else {
			putfast "${private-method} $nick :Invalid nick/channel: $nickchan"
		}
	} else {
		putfast "${private-method} $nick :Usage: .send -n|-c nick keyword  OR  .send #channel keyword"
	}
	whatis $keywords [list send-mode 1 from-method ${private-method} from-nick $nick from-chan $chan to-method ${to-method} to-nick ${to-nick} to-chan ${to-chan}]
}
proc ::whatswhat::MSG_send {nick host hand text} { PUB_send $nick $host $hand {} $text }

proc ::whatswhat::PUB_+number {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	array set result [Set [string trim $text] +number]
	if {$chan == {}} {
		variable private-method
		putfast "PRIVMSG $nick :$result(message)"
	} else {
		putfast "PRIVMSG $chan :$result(message)"
	}
}
proc ::whatswhat::MSG_+number {nick host hand text} { PUB_+number $nick $host $hand {} $text }

proc ::whatswhat::PUB_-number {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	array set result [Set [string trim $text] -number]
	if {$chan == {}} {
		variable private-method
		putfast "PRIVMSG $nick :$result(message)"
	} else {
		putfast "PRIVMSG $chan :$result(message)"
	}
}
proc ::whatswhat::MSG_-number {nick host hand text} { PUB_-number $nick $host $hand {} $text }

proc ::whatswhat::PUB_+hide {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	array set result [Set [string trim $text] +hide]
	if {$chan == {}} {
		variable private-method
		putfast "PRIVMSG $nick :$result(message)"
	} else {
		putfast "PRIVMSG $chan :$result(message)"
	}
}
proc ::whatswhat::MSG_+hide {nick host hand text} { PUB_+hide $nick $host $hand {} $text }

proc ::whatswhat::PUB_-hide {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	array set result [Set [string trim $text] -hide]
	if {$chan == {}} {
		variable private-method
		putfast "PRIVMSG $nick :$result(message)"
	} else {
		putfast "PRIVMSG $chan :$result(message)"
	}
}
proc ::whatswhat::MSG_-hide {nick host hand text} { PUB_-hide $nick $host $hand {} $text }

proc ::whatswhat::PUB_delete {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	if {![regexp {^(.*) ([0-9]*)$} [set text [string trim $text]] all text defnum]} { set defnum 0 }
	array set result [Set $text delete defnum $defnum]
	if {$chan == {}} {
		variable private-method
		putfast "PRIVMSG $nick :$result(message)"
	} else {
		putfast "PRIVMSG $chan :$result(message)"
	}
}
proc ::whatswhat::MSG_delete {nick host hand text} { PUB_delete $nick $host $hand {} $text }

proc ::whatswhat::PUB_insert {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	set separator {==}
	variable separators
	if {[regexp "^(.*?) (\[0-9\]*?) (${separators}?) (.*)\$" [set text [string trim $text]] all key defnum separator definition] || [regexp "^(.*?) (${separators}?) (\[0-9\]*?) (.*)\$" $text all key separator defnum definition] || [regexp {^(.*) ([0-9]*?) (.*)$} $text all key defnum definition] || [regexp {^(.*?) ([0-9]*?) (.*)$} $text all key defnum definition]} {
		array set result [Set $key insert defnum $defnum separator $separator definition $definition author $hand]
		if {$chan == {}} {
			variable private-method
			putfast "PRIVMSG $nick :$result(message)"
		} else {
			putfast "PRIVMSG $chan :$result(message)"
		}
	} else {
		if {$chan == {}} {
			variable private-method
			putfast "PRIVMSG $nick :Usage: .insert keyword # definition"
		} else {
			putfast "PRIVMSG $chan :Usage: .insert keyword # definition"
		}
	}
}
proc ::whatswhat::MSG_insert {nick host hand text} { PUB_insert $nick $host $hand {} $text }


proc ::whatswhat::PUB_replace {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	set separator {==}
	variable separators
	putlog "text: $text"
	if {[regexp "^(.*?) (\[0-9\]*?) (${separators}?) (.*)\$" [set text [string trim $text]] all key defnum separator definition] || [regexp "^(.*?) (${separators}?) (\[0-9\]*?) (.*)\$" $text all key separator defnum definition] || [regexp {^(.*) ([0-9]*?) (.*)$} $text all key defnum definition] || [regexp {^(.*?) ([0-9]*?) (.*)$} $text all key defnum definition]} {
		putlog "[list Set $key replace defnum $defnum separator $separator definition $definition author $hand]"
		array set result [Set $key replace defnum $defnum separator $separator definition $definition author $hand]
		if {$chan == {}} {
			variable private-method
			putfast "PRIVMSG $nick :$result(message)"
		} else {
			putfast "PRIVMSG $chan :$result(message)"
		}
	} else {
		if {$chan == {}} {
			variable private-method
			putfast "PRIVMSG $nick :Usage: .replace keyword # definition"
		} else {
			putfast "PRIVMSG $chan :Usage: .replace keyword # definition"
		}
	}
}
proc ::whatswhat::MSG_replace {nick host hand text} { PUB_replace $nick $host $hand {} $text }

proc ::whatswhat::PUB_stats {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	foreach l [Stats] {
		if {$chan == {}} {
			putfast "PRIVMSG $nick :$l"
		} else {
			putfast "PRIVMSG $chan :$l"
		}
	}
}
proc ::whatswhat::MSG_stats {nick host hand text} { PUB_stats $nick $host $hand {} $text }

proc ::whatswhat::PUB_save {nick host hand chan text} {
	if {$chan != {} && ![channel get $chan whatswhat]} { return 0 }
	if {$chan == {}} {
		variable private-method
		putfast "PRIVMSG $nick :[Save]"
	} else {
		putfast "PRIVMSG $chan :[Save]"
	}
}
proc ::whatswhat::MSG_save {nick host hand text} { PUB_save $nick $host $hand {} $text }

proc ::whatswhat::Stats {args} {
	variable version
	set return [list "whatswhat.tcl v$version by FireEgl"]
	variable database
	lappend return "There are [array size database] keywords in the database."
	set defcount 0
	array set authors {}
	set created [clock seconds]
	foreach k [array names database] {
		array set keyinfo $database($k)
		incr defcount [llength $keyinfo(definitions)]
		if {$keyinfo(created) < $created} { set created $keyinfo(created) }
		foreach d $keyinfo(definitions) {
			array set definfo $d
			if {![info exists authors($definfo(author))]} { set authors($definfo(author)) 0 } else { incr authors($definfo(author)) }
		}
	}
	lappend return "There are $defcount total definitions."
	lappend return "[array size authors] users have added to the database."
	lappend return "Database created on [ctime $created]."
	variable dbfile
	lappend return "Database last saved [duration [expr {[clock seconds] - [file mtime $dbfile]}]] ago."
	return $return
}

proc ::whatswhat::Set {keyword {function {unknown}} args} {
	variable number
	set keyword [string trim $keyword]
	array set options [list number -1 hide -1 defnum 9999 separator {==} keyword $keyword definition {} author {Unknown} created [clock seconds]]
	array set options $args
	set options(definition) [string trim $options(definition)]
	set options(keyword) [string trim $options(keyword)]
	array set return [list hide $options(hide) code 0 message {Error.}]
	variable database
	if {[info exists database([set lowerkeyword [string tolower $keyword]])]} {
		array set keyinfo $database($lowerkeyword)
		switch -glob -- $function {
			{del*} - {rem*} {
				if {!$options(defnum)} {
					# $options(defnum) is 0, which means to delete the keyword from the database.
					if {[catch { unset database($lowerkeyword) }]} { array unset database $lowerkeyword }
					return [list code 1 message "Deleted $options(keyword) and all its definitions."]
				} elseif {[incr options(defnum) -1] >= [llength $keyinfo(definitions)]} {
					array set return [list code 0 message "Can't delete definition #[incr options(defnum)]!  There's only [llength $keyinfo(definitions)] definition(s) for $options(keyword)"]
				} else {
					# $options(defnum) is > 0, which means to delete just one definition for the keyword.
					array set definfo [lindex $keyinfo(definitions) $options(defnum)]
					array set return [list code 1 message "Deleted $options(keyword) |[expr { $options(defnum) + 1 } ]| $definfo(definition)"]
					set keyinfo(definitions) [lreplace $keyinfo(definitions) $options(defnum) $options(defnum)]
				}
			}
			{add*} {
				# First, see if the definition already exists:
				variable duplicate
				if {!$duplicate} {
					foreach d $keyinfo(definitions) {
						array set definfo $d
						if {[string equal -nocase $definfo(definition) $options(definition)]} {
							return [list code 0 message {That definition already exists.}]
						}
					}
				}
				# It doesn't exist if we're still here.. So add it:
				set keyinfo(definitions) [linsert $keyinfo(definitions) [incr options(defnum) -1] [list definition $options(definition) separator $options(separator) author $options(author) created $options(created)]]
				set options(defnum) [llength $keyinfo(definitions)]
				array set return [list code 1 message "Added $options(keyword) |$options(defnum)| $options(definition)"]
			}
			{ins*} {
				# First, see if the definition already exists:
				variable duplicate
				if {!$duplicate} {
					foreach d $keyinfo(definitions) {
						array set definfo $d
						if {[string equal -nocase $definfo(definition) $options(definition)]} {
							return [list code 0 message {That definition already exists.}]
						}
					}
				}
				# It doesn't exist if we're still here.. So insert it:
				set keyinfo(definitions) [linsert $keyinfo(definitions) [incr options(defnum) -1] [list definition $options(definition) separator $options(separator) author $options(author) created $options(created)]]
				set options(defnum) [incr options(defnum)]
				array set return [list code 1 message "Inserted $options(keyword) |$options(defnum)| $options(definition)"]
			}
			{rep*} {
				# Replace
				# First, see if the definition already exists:
				variable duplicate
				if {!$duplicate} {
					foreach d $keyinfo(definitions) {
						array set definfo $d
						if {[string equal -nocase $definfo(definition) $options(definition)]} {
							return [list code 0 message {That definition already exists.}]
						}
					}
				}
				# It doesn't exist if we're still here.. So replace it:
				set keyinfo(definitions) [lreplace $keyinfo(definitions) [incr options(defnum) -1] $options(defnum) [list definition $options(definition) separator $options(separator) author $options(author) created $options(created)]]
				incr options(defnum)
				array set return [list code 1 message "Replaced $options(keyword) |$options(defnum)| $options(definition)"]
			}
			{+*} {
				set keyinfo([string trimleft $function {+}]) 1
				array set return [list code 1 message "Set $function on $options(keyword)"]
			}
			{-*} {
				set keyinfo([string trimleft $function {-}]) 0
				array set return [list code 1 message "Set $function on $options(keyword)"]
			}
			{unknown} { return -code error "You must specify a function." }
			{default} { return -code error "Unknown function: $function" }
		}
	} else {
		switch -glob -- $function {
			{add*} {
				# The keyword doesn't exist yet
				array set keyinfo [list keyword $options(keyword) number $options(number) hide $options(hide) created $options(created) author $options(author) definitions [list [list definition $options(definition) separator $options(separator) author $options(author) created $options(created)]]]
				array set return [list code 1 message "Added $options(keyword) |[llength $keyinfo(definitions)]| $options(definition)"]
			}
			{ins*} {
				# The keyword doesn't exist yet, give an error because we're supposed to be inserting, not adding.  (This is supposed to prevent people from inadvertantly creating new keywords)
				return [list code 0 message "Keyword \"$options(keyword)\" doesn't exist, can't do insert."]
			}
			{del*} - {rem*} { return [list code 0 message "Keyword \"$options(keyword)\" doesn't exist, can't delete."] }
			{+*} - {-*} { return [list code 0 message "Keyword \"$options(keyword)\" doesn't exist, can't set."] }
			{default} { return [list code 0 message "Unknown keyword: $options(keyword)"] }
		}
	}
	set database($lowerkeyword) [array get keyinfo]
	array get return
}

# Tries to find a specific keyword:
proc ::whatswhat::Get {pattern opts} {
	array set options [list globsearch 0 search [list keywords definitions authors] options {} maxmatches 9999 hide -1]
	array set options $opts
	array set return [list hide $options(hide) code 0 keywords [list]]
	## If $pattern contains * or ? then we force a glob pattern search (and skip the exact search).
	# switch -glob -- [set pattern [string trim $pattern]] { {*\**} - {*\?*} { set options(globsearch) 1 } }
	variable database
	# See if we can match an exact keyword..
	if {!$options(globsearch) && [lsearch -glob $options(search) {k*}] != -1 && [info exists database([string tolower $pattern])]} {
		# Found an exact keyword match.. (give up searching for more by setting code to 1)
		array set keyinfo $database([string tolower $pattern])
		array set return [list code 1 keywords [list [string tolower $pattern]] pattern $pattern hide $keyinfo(hide)]
	} else {
		# Find glob pattern matches..
		set return(pattern) [set pattern [string map {{**} {*}} "*[string trim $pattern {*}]*"]]
		foreach s $options(search) {
			switch -- $s {
				{keywords} - {keys} - {key} - {keyword} - {k} {
					if {[llength [set keywords [array names database [string tolower $pattern]]]]} {
						# Found 1 or more matches.
						set return(keywords) [lsort -unique $keywords]
						#array set return [list keywords $keywords]
					}
				}
				{definitions} - {definition} - {defs} - {def} - {d} {
					foreach k [array names database] {
						array set keyinfo $database($k)
						foreach d $keyinfo(definitions) {
							array set definfo $d
							if {[string match -nocase $pattern $definfo(definition)] && [lsearch -exact $return(keywords) $k] == -1} {
								if {[llength [lappend return(keywords) $k]] >= $options(maxmatches)} {
									#set return(code) 1
									#break
								}
							}
						}
						if {$return(code)} { break }
					}
				}
				{authors} - {author} - {auth} - {a} {
					foreach k [array names database] {
						array set keyinfo $database($k)
						foreach d $keyinfo(definitions) {
							array set definfo $d
							if {[string match -nocase $pattern $definfo(author)] && [lsearch -exact $return(keywords) $k] == -1} {
								if {[llength [lappend return(keywords) $k]] >= $options(maxmatches)} {
									#set return(code) 1
									#break
								}
							}
						}
						#if {$return(code)} { break }
					}
				}
				{-} - {+} - {} { }
				{default} { return -code error "Unknown search: $options(search)" }
			}
			# When $return(code) == 1, we give up searching.
			#if {$return(code)} { break }
		}
	}
	# Return matches:
	array get return
}

proc ::whatswhat::Load {args} {
	variable dbfile
	if {![file exists $dbfile]} {
		if {[file exists [string tolower $dbfile]]} {
			putlog "WhatsWhat: $dbfile wasn't found, but [set dbfile [string tolower $dbfile]] was..using it instead."
		} else {
			putlog "WhatsWhat: Starting new database (${dbfile})..."
			array set database {}
			return
		}
	}
	variable database
	if {![catch { array set database [read [set fid [open $dbfile r]]][close $fid] } error]} {
		putlog "WhatsWhat: Loaded database."
	} else {
		putlog "WhatsWhat: Error while loading database: $error"
	}
}

proc ::whatswhat::Save {args} {
	variable database
	if {![array size database]} { return }
	set starttime [clock clicks -milliseconds]
	set error 0
	variable dbfile
	if {![catch { open $dbfile w } fid]} {
		set defnum 0
		# We loop through the database and add extra whitespace and linefeeds, so the file will be more readable to humans:
		foreach keyword [lsort [array names database]] {
			if {[catch {
				# A previous bug added an empty keyword, this fixes it:
				if {[string trim $keyword] == {}} {
					unset database($keyword)
					continue
				}
				array set keyinfo $database($keyword)
				if {![string equal -nocase $keyinfo(keyword) $keyword]} {
					putlog "WhatsWhat: Problem in database: $keyword != $keyinfo(keyword)"
					set error 1
					continue
				}
				puts $fid "[list $keyword] \{ "
				foreach k [array names keyinfo] {
					switch -- $k {
						{definitions} { }
						{default} { puts $fid "	[list $k] [list $keyinfo($k)] " }
					}
				}
				puts $fid "	definitions \{ "
				incr defnum [llength $keyinfo(definitions)]
				foreach d $keyinfo(definitions) {
					array set definfo $d
					puts $fid "		\{ "
					foreach i [array names definfo] { puts $fid "			[list $i] [list $definfo($i)] " }
					puts $fid "		\} "
				}
				puts $fid "	\} \n\} "
			} err]} {
				putlog "WhatsWhat: Error in database: $err\nCorrupt keyword: $keyword\n[array get database($keyword)]"
				set error 1
				continue
			}
		}
		close $fid
	}
	if {$error} {
		array unset database *
		Load
	}
	set return "Saved [array size database] keywords and $defnum definitions to ${dbfile} in [expr {[clock clicks -milliseconds] - $starttime}] milliseconds."
	putlog "WhatsWhat: $return"
	catch { file copy -force $dbfile ${dbfile}.bak }
	# This'll send the database by email once every $email-interval hours:
	variable email-interval
	variable LastEmail
	if {[clock seconds] - $LastEmail > 60 * 60 * ${email-interval}} {
		set LastEmail [clock seconds]
		catch { Email }
	}
	return $return
}

# by Dossy@EFNet
# Contains bugs: 1. It cuts words longer than $maxlen.  2. It only supports maxlen's up to 255.
# But it's fast and simple! =)
proc ::whatswhat::wrapstring {string {maxlen {255}}} { regexp -all -inline "\\S.{0,$maxlen}(?!\\S)" $string }

# detectflood returns 1 if a flood was detected, or 0 if it wasn't.
# $maxsec is the lines:seconds.
# $args is a way to identify the person.
#
# Examples:
# if {[detectflood 10:60 chan #tcldrop adsl-17-145-128.bhm.bellsouth.net]} { flood detected! }
# if {[detectflood 5:60 dcc 5]} { flood detected! }
#
# (This was taken from my Tcldrop project)  =)
proc ::whatswhat::detectflood {maxsec args} {
	foreach {max sec} [set maxsec [split $maxsec {: }]] { if {$max == 0 || $sec == 0} { return 0 } }
	variable Flood
	set Flood(maxsec,$args) $maxsec
	if {![info exists Flood(seconds,$args)]} {
		# This is the first time we've seen $args, initialize the seconds list:
		set Flood(seconds,$args) [list [clock seconds]]
		# This basically starts a loop that checks every $sec and deletes old info
		# and eventually will delete the array that stores the info if it
		# doesn't get updated again within $sec seconds:
		after [expr {$sec * 1000 + 1001}] [list ::whatswhat::ClearFlood $args]
		return 0
	} else {
		# Detect flood:
		set ndx 0
		foreach s [set Flood(seconds,$args) [lrange [concat $Flood(seconds,$args) [list [set seconds [clock seconds]]]] end-$max end]] {
			if {$sec >= $seconds - $s} {
				set Flood(seconds,$args) [lrange $Flood(seconds,$args) $ndx end]
				break
			} else {
				incr ndx
			}
		}
		if {[llength $Flood(seconds,$args)] >= $max} { return 1 } else { return 0 }
	}
}

proc ::whatswhat::ClearFlood {id} {
	variable Flood
	if {[info exists Flood(maxsec,$id)]} {
		set seconds [clock seconds]
		foreach {max sec} $Flood(maxsec,$id) {}
		set ndx 0
		foreach s [set Flood(seconds,$id) [lrange $Flood(seconds,$id) end-$max end]] {
			if {[expr { $sec >= $seconds - $s }]} {
				set Flood(seconds,$id) [lrange $Flood(seconds,$id) $ndx end]
				set ndx -1
				break
			} else {
				incr ndx
			}
		}
		if {$ndx == -1} { after [expr {$sec * 1000 + 1001}] [list ::whatswhat::ClearFlood $id] } else { array unset Flood *,$id }
	}
}

proc ::whatswhat::putfast {text} { putdccraw 0 [string length $text\n] $text\n }

if {$::whatswhat::email(to) != {}} {
	if {[lsearch -exact $auto_path .] == -1} { lappend auto_path . }
	if {[lsearch -exact $auto_path [pwd]] == -1} { lappend auto_path [pwd] }
	if {[lsearch -exact $auto_path [file join [pwd] scripts]] == -1} { lappend auto_path [file join [pwd] scripts] }
	if {[catch { package require smtp ; package require mime ; package require base64 }] && ([catch { source [file join scripts md5.tcl] }] || [catch { source [file join scripts base64.tcl] }] || [catch { source [file join scripts mime.tcl] }] || [catch { source [file join scripts smtp.tcl] }])} {
		putlog "WhatsWhat: Attempting to download necessary files for sending email..."
		if {![file isdirectory scripts]} { catch { file mkdir scripts } }
		foreach f {http://cvs.sourceforge.net/viewcvs.py/*checkout*/tcllib/tcllib/modules/md5/md5.tcl http://cvs.sourceforge.net/viewcvs.py/*checkout*/tcllib/tcllib/modules/base64/base64.tcl http://cvs.sourceforge.net/viewcvs.py/*checkout*/tcllib/tcllib/modules/mime/mime.tcl http://cvs.sourceforge.net/viewcvs.py/*checkout*/tcllib/tcllib/modules/mime/smtp.tcl} {
			#if {[file exists [file tail $f]]} { continue }
			if {[catch {
				package require http
				set token [::http::geturl $f -channel [set out [open [file join scripts [file tail $f]] w]]]
				close $out
				::http::cleanup $token
			}]} {
				if {![catch { exec wget $f }]} { catch { file rename -force -- [file tail $f] [file join scripts [file tail $f]] } }
			}
		}
	}
	if {![catch { package require mime ; package require smtp ; package require base64 } error] || (![catch { source [file join scripts md5.tcl] }] && ![catch { source [file join scripts base64.tcl] } error] && ![catch { source [file join scripts mime.tcl] } error] && ![catch { source [file join scripts smtp.tcl] } error])} {
		proc ::whatswhat::Email {args} {
			variable dbfile
			variable email
			array set info [array get email]
			array set info $args
			putlog "WhatsWhat: Emailing $dbfile to $info(to) ..."
			if {[catch {
				::smtp::sendmessage [set multiT [::mime::initialize -canonical multipart/mixed -parts [list [::mime::initialize -canonical text/plain -string "$info(body)"] [::mime::initialize -canonical "application/octet-stream; name=\"$dbfile\"" -header [list Content-Disposition "attachment; filename=\"$dbfile\""] -file $dbfile]]]] -queue 1 -debug 0 -header [list From "$info(from)"] -header [list To "$info(to)"] -header [list Subject "$info(subject)"] -header [list X-Accept-Language {en}] -header [list Precedence {bulk}] -header [list X-Priority {9}] -header [list X-MSMail-Priority {Low}]
				::mime::finalize $multiT
			} error]} { putlog "WhatsWhat: Problem sending email: $error" }
		}
	} else {
		proc ::whatswhat::Email {args} {
			putlog "WhatsWhat: The smtp/mime/base64 packages aren't available.  Sending the database by email won't be possible."
			putlog "WhatsWhat: Error is: $error"
		}
	}
}

catch { package forget whatswhat }
namespace eval ::whatswhat {
	variable version {0.6.2}
	variable database
	array set database {}
	variable Flood
	array set Flood {}
	setudef flag whatswhat
	foreach {t f m p h} $binds { foreach t $t { bind $t $f $m "::whatswhat::[string toupper $t]_$p" } }
	unset t f m p h
	if {![array size database]} { Load }
	variable EmailTimer
	variable email-interval
	variable LastEmail
	if {![info exists LastEmail]} { set LastEmail [clock seconds] }
	package provide whatswhat $version
	putlog "whatswhat.tcl v$version by FireEgl <FireEgl@GMail.Com> - Loaded."
}
