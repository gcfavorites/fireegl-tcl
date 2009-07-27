# jump4.0.tcl - by FireEgl@EFNet <FireEgl@EMail.com> (FireEgl.cjb.net) - 12/25/99

### Description:
# Keeps your bots on different IRC servers.

### History:
# 4.0 - Added encryption to critical bot communications.
#       (no longer compatible with v3.x)
#		- Lots of code cleanups.
# 3.3 - Fixed so it won't ask all the bots what server they're on several
#       times when it connects to the botnet.
#     - (!) Will now remove servers that other bots are on from it's $servers
#       list temporarily. (see below!)
# 3.2 - Will now check its server to the rest of the bots when it links to the botnet.
# 3.1 - Bots won't report that they're on a server when they're really not anymore.
#     - Made a few changes to the way it counts how many are on a server.
#     - Added a putlog to show the local bot/server with the others on a .checkserv
#     - Moved a lot of things around..
# 3.0 - Released.

# (!) Eggdrop doesn't keep the $servers list in such a way that makes it easy
# for scripters to modify it.. And in my tests, it usually won't remove/add back
# any servers that are only supposed to be removed temporarily. (Eggdrop seems
# to rewrite the servers list when you try to modify it and doesn't always keep
# your changes, or will corrupt your changes.)
# Also note, that servers using different names (like irc.cris.com is
# irc.concentric.net) may not be removed from the servers list at all,
# if you have irc.cris.com in the servers list while another bot is on
# irc.concentric.net.

### Comments? Suggestions? Bugs??
# Email me at FireEgl@EMail.com

### Installation:
# Load this script on all your bots.

### Options:
# Allow up to this many bots to be on the same IRC server:
set maxonserver "1"

# Max delay time after asking what server the other bots are on before jumping.
# It'll normally jump if it needs to immediately after all the bots reply,
# this setting is in case some bots don't reply, it'll still jump after
# this many seconds (if it needs to of course):
set jumpdelay "15"

# Only ask/respond to other bots that have all of these global flags:
set jumpflags "bof"

# Encrypt/Decrypt key for bot communications:
set jumpkey "Yippy"

# (!) Set this to 1 for it to temporarily disable (remove) a server from it's
# servers list when another bot tells it it's already on that server. (0 to disable)
# (Recommend leaving as 0 (disabled))
set jumpremserv "1"

### DCC/telnet Commands:
# .checkserv        - Asks all the bots what server they're on and jumps if necessary.
# .checkserv -all   - Asks all the bots to ask all the bots what server they're on, and they'll jump if necessary.
#
# (You'll probably never need to use this commamd,
# as it'll check on its own on connect to an IRC server.)

# Notes:
# You'll have to make the bots jump after
# loading this script for the first time..
# ..so that it can find the true name of the IRC server it's on..
# (Eggdrop's $server var doesn't keep up
# with the REAL name of the IRC server,
# so this script has to find out on its own.)



### Begin Main Script (don't change anything below here):

bind raw - "001" connect:servername
proc connect:servername {from key arg} { global my-server jumpdelay jumpkey
   jumpcleanup
   set my-server "[string tolower $from]"
   putlog "\[\002JUMP\002\] Asking what servers the other bots are on...."
   foreach b "[jumpbots]" {
		putlog "\[\002JUMP\002\] Asking what server $b is on..."
		putbot $b "getserv $from"
	}
   utimer $jumpdelay "checkserv"
}

bind link bo * link:checkserv
proc link:checkserv {bot via} { global jumpflags my-server jumpdelay jumpkey
   if {([matchattr $bot $jumpflags&]) || ([matchattr $via $jumpflags&])} {
      jumpcleanup
      putlog "\[\002JUMP\002\] Asking what server $bot is on..."
      putbot $bot "getserv ${my-server}"
      foreach t "[utimers]" { if {"[lindex $t 1]" == "checkserv"} { killutimer "[lindex $t 2]" } }
      utimer $jumpdelay "checkserv"
   }
}

# Adds back whatever server the other bot was on to the servers list when it disconnects from the botnet:
bind disc bo * disc:servadd
proc disc:servadd {bot} { global servremd servers
	if {[info exists servremd($bot)]} {
      set serv $servremd($bot)
      if {[servadd $bot]} { putlog "\[\002JUMP\002\] $bot Disconnected.. Re-added $serv to my servers list." }
   }
}

bind bot bo getserv bot:getserv
proc bot:getserv {bot cmd arg} { global jumpflags jumpkey
   if {[matchattr $bot $jumpflags&]} {
      global my-server server-cycle-wait server-timeout servers nb_ver
      if {[botonserv]} {
         putbot $bot "tellserv [encrypt $jumpkey [list $jumpkey ${my-server}]]"
      } else {
         putbot $bot "tellserv [encrypt $jumpkey [list $jumpkey none]]"
         set my-server "none"
      }
		# Add back any removed servers from the list here. (after a delay)
      foreach t "[utimers]" { if {[string match [string tolower "servadd"] "[string tolower [lindex $t 1]]"]} { killutimer "[lindex $t 2]" } }
      utimer [expr [llength $servers] * (${server-cycle-wait} + ${server-timeout}) + 99] servadd
      catch {set nb_ver} 0
      if {![info exists nb_ver]} { putlog "\[\002JUMP\002\] $bot connected $arg - (I'm on ${my-server})" }
   }
}

bind bot bo tellserv bot:tellserv
proc bot:tellserv {bot cmd arg} { global jumpflags jumpkey jumpserv
	set decrypt "[decrypt $jumpkey $arg]"
	if {(("[lindex $decrypt 0]" == "$jumpkey") && ([matchattr $bot $jumpflags&]))} {
		set decrypt "[lrange $decrypt 1 end]"
      set jumpserv($bot) "$decrypt"
		servrem "$bot" "$decrypt"
      if {"[llength [array names jumpserv]]" >= "[llength [jumpbots]]"} { checkserv }
   }
}

proc checkserv {} { global my-server maxonserver jumpserv botnet-nick
   if {![botonserv]} {
 	   putlog "\[\002JUMP\002\] Not going to check, because I'm not on a server."
   } else {
      set numonserv 1
      set botsonserv "${botnet-nick}"
      putlog "\[\002JUMP\002\] ${botnet-nick} is on ${my-server}"
      foreach b "[array names jumpserv]" {
         if {$jumpserv($b) != "none"} { set say "is on $jumpserv($b)." } { set say "is not on a server." }
         putlog "\[\002JUMP\002\] $b $say"
         if {(("[string tolower $jumpserv($b)]" == "[string tolower ${my-server}]") && ("[string tolower $jumpserv($b)]" != "none"))} {
            incr numonserv
            lappend botsonserv "$b"
         }
         unset jumpserv($b)
      }
      if {"$numonserv" > "$maxonserver"} {
         putlog "\[\002JUMP\002\] $botsonserv ($numonserv bots) are on ${my-server} ...\002jumping\002... "
         jump
      } else {
         putlog "\[\002JUMP\002\] No need to jump. =)"
			servadd
      }
   }
   jumpcleanup
}

bind dcc n checkserv dcc:checkserv
proc dcc:checkserv {hand idx arg} { global my-server jumpdelay botnet-nick jumpkey
   jumpcleanup
   if {("[string tolower $arg]" == "all") || ("[string tolower $arg]" == "-all")} {
      putlog "\[\002JUMP\002\] Asking all bots to ask all bots what their server is..."
      putallbots "askservall"
   } 
   if {[botonserv]} {
      putlog "\[\002JUMP\002\] Asking all bots what their server is... please wait.."
      foreach b "[jumpbots]" {
		putlog "\[\002JUMP\002\] Asking what server $b is on..."
		putbot $b "getserv ${my-server}"
		}
      utimer $jumpdelay "checkserv"
   } else {
      putlog "\[\002JUMP\002\] Not going to check, because I'm not on a server."
   }
}

bind bot bo askservall bot:askservall
proc bot:askservall {bot cmd arg} { global my-server
   putlog "\[\002JUMP\002\] $bot requested all bots to check their servers."
   if {![botonserv]} {
      putlog "\[\002JUMP\002\] Not going to check though, because I'm not on a server."
   } else { 
      global jumpflags jumpdelay jumpkey
      if {[matchattr $bot $jumpflags&]} {
         jumpcleanup
         putlog "\[\002JUMP\002\] Asking all bots to ask all bots what their server is..."
         foreach b "[jumpbots]" {
			putlog "\[\002JUMP\002\] Asking what server $b is on..."
			putbot $b "getserv ${my-server}"
			}
         utimer $jumpdelay "checkserv"
      }
   }
}

proc jumpbots {} { global jumpflags
   set thebots ""
   foreach b "[bots]" { if {[matchattr $b $jumpflags&]} { lappend thebots "$b" } }
   return "$thebots"
}

proc botonserv {} { global server my-server
   if {($server == "") || (${my-server} == "none")} { return 0 } else { return 1 }
}

proc jumpcleanup {} { global my-server jumpserv
   foreach b "[array names jumpserv]" { unset jumpserv($b) }
   foreach t "[utimers]" { if {"[lindex $t 1]" == "checkserv"} { killutimer "[lindex $t 2]" } }
}

# This adds back all servers that were removed from the servers list:
proc servadd {{bot ""}} { global servers servremd
 	if {(([info exists servremd($bot)]) && ([lindex [split $servremd($bot) :] 0] != ""))} {
		set serv "$servremd($bot)"
		unset servremd($bot)
     	lappend servers "$serv"
		if {[lsearch -glob [string tolower "$servers"] [string tolower "*[lindex $serv 0]*"]] != -1} {
         # putlog "\[\002JUMP\002\] Re-Added $serv to servers list."
     		return 1
		} else {
			return 0
		}
   }
	set retval 0
	foreach a "[array names servremd]" {
		if {(([lsearch -glob [string tolower "$servers"] [string tolower "*[lindex $servremd($a) 0]*"]] == -1) && ([lindex [split $servremd($a) :] 0] != ""))} {
			set serv "$servremd($a)"
  			unset servremd($a)
  			lappend servers "$serv"
			if {[lsearch -glob [string tolower "$servers"] [string tolower "*[lindex $serv 0]*"]] != -1} {
            # putlog "\[\002JUMP\002\] Re-Added $serv to servers list."
    			set retval 1
			} else {
    			set retval 0
			}
		}
   }
   return $retval
}

# This removes the specified server from the servers list:
proc servrem {bot serv} { global jumpremserv
	if {(("$serv" != "") && ("$serv" != "none") && ($jumpremserv))} {
   	global servers server my-server servremd
		set place [lsearch -glob [string tolower "$servers"] [string tolower "*$serv*"]]
   	if {(($place != -1) && ([lindex [split [lindex $servers $place] :] 0] != ""))} {
			set servers [lreplace "$servers" $place $place]
       	set servremd($bot) "[lindex $servers $place]"
         # putlog "\[\002JUMP\002\] Removed $servremd($bot)"
			return 1
		}
		return 0
	}
	return 0
}

global server my-server server-cycle-wait server-timeout jumpver jumpdelay jumpkey
if {![info exists my-server]} { set my-server "[string tolower [lindex [split $server :] 0]]" }
if {![info exists server-cycle-wait]} { set server-cycle-wait "[expr 1 + [rand 3]]" }
if {![info exists server-timeout]} { set server-timeout "[expr 20 + [rand 9]]" }
set jumpver "4.0"
putlog "jump$jumpver.tcl by FireEgl@EFNet <FireEgl@EMail.com> - Loaded."
servadd
jumpcleanup
putlog "\[\002JUMP\002\] Asking what servers the other bots are on..."
foreach b "[jumpbots]" { putbot $b "getserv ${my-server}" }
utimer $jumpdelay "checkserv"
if {[info exists b]} { unset b }
