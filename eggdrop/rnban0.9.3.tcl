# rnban.tcl v0.9.3 (beta) - by FireEgl@EFNet <FireEgl@EMail.Com> (FireEgl.cjb.Net) - June 30, 2001

### Description:
# Allows you to ban users by their real names.  (The real names you see in a /whois)
# It then bans people by their hostmask if their real name matches one of the real name bans.

### DCC/telnet Commands:
# Add a real name ban:
#    .+rnban <mask> [channel] <reason>
# Remove a real name ban:
#    .-rnban <mask> [channel]
# List the real name bans:
#    .rnbans [channel] <mask>

### Notes:
# 1. The mask must be quoted if it has spaces in it.
# 2. The mask is CaSe SeNsItIvE.
# 3. +omn users are exempt from being banned.


### Written at the request of XtreM@EFNet,DALNet <Xtr@Xtrc.Net>
### and also for Killer90@EFNet,DALNet <Michel.Bel@Sympatico.CA>



### Begin Script:

# Does a "WHO $nick" when someone joins:
bind join - * join:rnban
proc join:rnban {nick host hand chan} {
   # FixMe: Reorder this if for speed:
   if {((![matchattr $hand fomn|fomn $chan]) && (![matchban $nick!$host $chan]) && ([botisop $chan]) && (![isban "*!*@[lindex [split $host @] end]" $chan]))} { puthelp "WHO $nick" }
}
set double-help [set double-server [set double-mode 1]]

# WHO bind to check real name bans:  (Note, Eggdrop does a "WHO #channel" automatically when the bot joins a channel.)
bind raw - "352" raw:352:rnban
proc raw:352:rnban {from key arg} { raw:rnban [join [lrange [split $arg] 8 end]] [lindex [split $arg] 5] }

# WHOIS bind to check real name bans:  (Note, this script won't send WHOIS's, but it'll check 'em if it gets 'em.  =)
bind raw - "311" raw:311:rnban
proc raw:311:rnban {from key arg} { raw:rnban [string trimleft [join [lrange [split $arg] 5 end]] :] [lindex [split $arg] 1] }

# common proc used by the above two procs:
proc raw:rnban {realname nick} { if {(("$realname" != {}) && ([llength [split $nick]]) && (![isbotnick $nick]))} { foreach {chan} "[nickschans $nick]" { matchrnban $realname $chan $nick } } }

# dcc/telnet command to list the real name bans:
bind dcc omn|omn rnbans dcc:rnbans
bind dcc omn|omn bansrn dcc:rnbans
bind dcc omn|omn banrns dcc:rnbans
proc dcc:rnbans {hand idx arg} { set arg [split $arg]

   # Figure out if they want to list a channels bans, or global bans:
   if {![validchan [set wantchan "[string tolower [lindex $arg 0]]"]]} {
      # No channel specified, they want global.
      set wantchan {}
   }

   # Figure out the mask:
   # Note, this may be kinda quirky when trying to detect if they quoted the mask or not.. (Let me know if it causes problems or confusion when setting bans..and I'll make it require them to be quoted.)
   if {"$wantchan" == {} && [llength $arg] >= 2} {
      # They didn't specify a channel or quote the mask.
      set mask [join $arg]
   } elseif {"$wantchan" != {} && [llength $arg] >= 3} {
      # They specified a channel, but didn't quote the mask.
      set mask [join [lrange $arg 1 end]]
   } elseif {"$wantchan" != {} && [llength $arg] == 2} {
      # They specified a channel and quoted the mask.
      set mask [lindex [lrange $arg 1 end] 0]
   } elseif {"$wantchan" == {} && [llength $arg] == 1} {
      # They didn't specify a channel, but did quote the mask.
      set mask [lindex $arg 0]
   } else {
      return [putdcc $idx {Usage: .rnbans [channel] <wildcard/all>}]
   }

   # Figure out if we want to show them $wantchan, $consolechan, or global bans:
   if {[validchan $wantchan] && [matchattr $hand +omn|+omn $wantchan]} {
      # Let them list the bans for the channel they asked for.
      set matchchan $wantchan
   } elseif {![validchan $wantchan] && [matchattr $hand +omn]} {
      # Let them list the global bans.
      set matchchan {}
   } elseif {![validchan $wantchan] && [matchattr $hand +omn|+omn [set consolechan "[lindex [split [console $idx]] 0]"]]} {
      # Let them list their console channel bans.
      set matchchan "[string tolower $consolechan]"
   } else {
      # They can't see any bans.
      return [putdcc $idx {Can't show you any bans.}]
   }

   # Show 'em all the bans for $matchchan:  (If $matchchan == "", then show them global bans.)
   if {"$matchchan" == {}} { putdcc $idx {-=- Matching GLOBAL Real Name Bans:} } else { putdcc $idx "-=- Matching Real Name Bans on $matchchan:" }
   set found 0
   global rnbans
   foreach {{a} {d}} "[array get rnbans $mask]" {
      if {("[set channel [string tolower [lindex $d 2]]]" == "$matchchan")} {
         putdcc $idx "\[[lsearch -exact [array names rnbans] $a]\] $a\n        [lindex $d 0]: [lindex $d 1]\n        Created [duration [expr [clock seconds] - [lindex $d 3]]] ago."
         incr found
      }
   }

   if {"$matchchan" == {}} { putdcc $idx "-=- Found $found GLOBAL Real Name Bans Matching $mask" } else { putdcc $idx "-=- Found $found Real Name Bans on $matchchan Matching $mask" }
   set arg 1
}

# DCC/Telnet command to add a Real Name Ban:
bind dcc omn|omn +rnban dcc:+rnban
bind dcc omn|omn +banrn dcc:+rnban
proc dcc:+rnban {hand idx arg} { if {![islist "$arg"]} { set arg [split "$arg"] }

   if {"[set mask [lindex $arg 0]]" == {}} {
      putdcc $idx "Usage: .+rnban <mask> \[channel\] <reason>\nNote, Put the mask inside double quotes if it has spaces in it."
   } elseif {((![validchan [set chan [lindex "$arg" 1]]]) && ([matchattr $hand +omn]))} {
      # Add new global ban.
      if {"[set reason [lrange "$arg" 1 end]]" == {}} { set reason {Requested.} }
      putcmdlog "#$hand# (GLOBAL) +rnban $mask ($reason)"
      putdcc $idx "New GLOBAL rnban: $mask ($reason)"
      newrnban $mask $hand $reason
   } elseif {(([validchan $chan]) && ([matchattr $hand +omn|+omn $chan])) || ((![validchan $chan]) && ([validchan [set chan [lindex [split [console $idx]] 0]]]) && ([matchattr $hand +omn|+omn $chan]))} {
      # Add new channel ban.
      if {"[set reason [lrange "$arg" 2 end]]" == {}} { set reason {Requested.} }
      putcmdlog "#$hand# ($chan) +rnban $mask ($reason)"
      putdcc $idx "New $chan rnban: $mask ($reason)"
      newrnchanban $chan $mask $hand $reason
   } else {
      # They should never fall through to here, but if they do..
      putdcc $idx {Unable to comply.}
   }
}

# dcc/telnet command to remove a real name ban:
bind dcc omn|omn -rnban dcc:-rnban
bind dcc omn|omn -banrn dcc:-rnban
proc dcc:-rnban {hand idx arg} { if {![islist "$arg"]} { set arg [split "$arg"] }

   if {"[set mask [lindex $arg 0]]" == {}} {
      return [putdcc $idx "Usage: .-rnban <mask> \[channel\]\nNote, Put the mask inside double quotes if it has spaces in it."]
   } elseif {((![validchan [set chan [lindex "$arg" 1]]]) && ([matchattr $hand +omn]))} {
      # They want to remove a global ban.
      set chan {}
      putcmdlog "#$hand# (GLOBAL) -rnban $mask"
   } elseif {(([validchan $chan]) && ([matchattr $hand +omn|+omn $chan])) || ((![validchan $chan]) && ([validchan [set chan [lindex [split [console $idx]] 0]]]) && ([matchattr $hand +omn|+omn $chan]))} {
      # They want to remove a channel ban (or they didn't specify a channel, and only have the access to remove a ban on their console channel.)
      set chan [string tolower $chan]
      putcmdlog "#$hand# ($chan) -rnban $mask"
   } else {
      # They should never fall through to here, but if they do..
      return [putdcc $idx {Unable to comply.}]
   }
   global rnbans
   foreach {{a} {d}} "[array get rnbans $mask]" {
      if {[string match $mask $a]} {
         if {(("[set rnchan [string tolower [lindex $d 2]]]" == "$chan") && ("$chan" == {}) && ([killrnban $a]))} {
            putdcc $idx "Removed GLOBAL rnban: $a"
         } elseif {(("$chan" != {}) && ("$rnchan" == "$chan") && ([killrnchanban $chan $a]))} {
            putdcc $idx "Removed $chan rnban: $a"
         }
      }
   }
   if {![info exists a]} { putdcc $idx "No such Real Name Ban." }
}

### Support procs follow.. They're all modeled after Eggdrop's *ban* commands.

# Sees if a real name matches a real name ban (and bans them if you tell it both the channel and nick)
proc matchrnban {realname {channel {}} {nick {}}} { global rnbans
   set matched 0
   foreach {{b} {d}} "[array get rnbans]" {
      if {((("[set rnbanchan [string tolower [lindex $d 2]]]" == "[string tolower $channel]") || ("$rnbanchan" == {})) && ([string match $b $realname]))} { set matched 1
         # FixMe: Reorder this if for speed:
         if {(("$channel" != {}) && ("$nick" != {}) && ([validchan $channel]) && ([botisop $channel]) && ([onchan $nick $channel]) && ("[set chanhost [getchanhost $nick $channel]]" != {}) && (![matchattr [nick2hand $nick $channel] fomn|fomn $channel]) && (![matchban $nick!$chanhost $channel]) && (![isban [set chanban "*!*@[lindex [split $chanhost @] end]"] $channel]))} { putlog "RealName Ban: ${nick}'s Real Name \"$realname\" matched \"$b\" - Banning from ${channel}..."
            putkick $channel $nick "RNB\002:\002 [lindex $d 1]"
            pushmode $channel +b $chanban
         }
      }
   }
   set matched
}

# Removes a global or channel real name ban:
proc killrnban {mask {channel {}}} { global rnbans
   if {[isrnban $mask $channel]} { unset rnbans($mask)
      savernbans
      set mask 1
   } else {
      set mask 0
   }
}

# Removes a channel real name ban:
proc killrnchanban {channel mask} { global rnbans
   if {[isrnchanban $mask $channel]} { unset rnbans($mask)
      savernbans
      set mask 1
   } else {
      set mask 0
   }
}

# Check if a global and/or channel real name ban exists:
proc isrnban {mask {channel {}}} { global rnbans
   if {((([info exists rnbans($mask)])) && (("[string tolower [set rnchan [lindex $rnbans($mask) 2]]]" == "[string tolower $channel]") || ("$rnchan" == {})))} { set mask 1 } else { set mask 0 }
}

# Check if a channel real name ban exists:
proc isrnchanban {mask channel} { global rnbans
   # FixMe: Should this bother to see if $channel != "" ?  (Should it be allowed to remove global bans?)
   if {(([info exists rnbans($mask)]) && ("$channel" != {}) && ("[string tolower [lindex $rnbans($mask) 2]]" == "[string tolower $channel]"))} { set mask 1 } else { set mask 0 }
}

# Create a new global (or channel) real name ban:
proc newrnban {mask {creator {Unknown}} {comment {Banned.}} {channel {}}} { global rnbans
   set rnbans($mask) [list $creator $comment $channel [unixtime]]
   savernbans
}

# Create a new channel real name ban:
proc newrnchanban {channel mask {creator {Unknown}} {comment {Banned.}}} { global rnbans
   set rnbans($mask) [list $creator $comment $channel [unixtime]]
   savernbans
}

# Returns which channels that both $nick and the bot is on, or "" if none.
proc nickschans {nick} { set channels {}
   foreach {c} "[channels]" { if {[onchan $nick $c]} { lappend channels "$c" } }
   set channels
}

# Checks to see if a string is a list:
proc islist {s} {expr ![catch {llength $s}]}

# Saves real name bans to disk:
proc savernbans {} { global rnbans botnet-nick
   puts -nonewline [set fid [open ".${botnet-nick}.rnbans.dat" w]] [array get rnbans]
   close $fid
}

global botnet-nick
if {[file exists ".${botnet-nick}.rnbans.dat"]} {
   # Load the saved real name bans:
   array set rnbans [gets [set fid [open ".${botnet-nick}.rnbans.dat" r]]]
   close $fid
   unset fid
}

putlog {rnban.tcl v0.9.3 (beta) by FireEgl@EFNet <FireEgl@EMail.Com> (FireEgl.cjb.Net) - Loaded.}
