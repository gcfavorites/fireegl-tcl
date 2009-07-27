# rblcheck.tcl v0.9.7-beta - by FireEgl@EFNet - July 2007

## Description:
# When a user joins a channel this script will dnslookup their hostname to get their IP (if needed),
# it will then query a list of RBLs that track IPs that are known open proxy hosts,
# and if a match is found, the bot will set a channel ban on the users hostname/ip.

# Use .chanset #Channel +rblcheck to enable it on a channel.

## Notes:
# I recommend setting these bans:
# *!www-data@*.* *!cache@*.* *!nobody@*.* *!debian-tor@*.* *!proxy@*.* *!*@*smtp*.*.* *!*@tor.*.* *!*@*.tor.*.* 

namespace eval ::rblcheck {
	## A note will be sent to these people when a match has been found and a ban set:
	variable notes "$::owner"

	## Check users who have an ident (this leads to more false-positives!):
	# (Set this to 1 if you're using the script on freenode, because freenode doesn't use ~ to mean non-idented)
	variable checkidents 0

	## Ban weight (must be 2 or higher!):
	# Ban a person when the matching RBLs add up to this weight.
	# Note, people without an ident automatically get +1, so make sure you set this to 2 or higher.
	variable banweight 3

	## Warn weight:
	# If the IP check reaches this weight, just send a warning to the @'s on the channel:
	# (Note: Warnings won't get sent if the ban weight was reached, so this should be set lower than the banweight.)
	# Note, people without an ident automatically get +1, so make sure you set this to 2 or higher.
	variable warnweight 2

	## Abort weight:
	# Abort (stop checking RBLs) if the weight goes this low:
	variable abortweight -2

	## Lookup delay:
	# This is mainly to put less load on your nameservers, by spreading the dns lookups over a longer period of time:
	# Set this to 0 for the fastest lookups, or higher to delay lookups even more:
	variable delay 0

	## RBL settings:
	# priority = The order in which the RBLs are queried.  (Lower priority = Checked first)
	#            Note: You can have more than one RBL in the same priority and it'll be checked in parallel with the others in that same priority.
	# weight = 1 or higher for blacklists, -1 or lower for whitelists.
	# rbl = The base hostname used for queries.
	# desc = The description given to hosts in the RBL.
	# mainurl = The main URL to the RBL.
	# checkurl = The URL used to check an IP to see if it's in the RBL's database. (%s will automatically be replaced with the IP)
	# codes = A list of glob's that indicate a match.
	# NOTE: whitelists should generally come before blacklists, unless you trust the blacklist to not produce false-positives.
	variable rbls {
		{priority 10 weight 6 rbl IRCBL.AHBL.Org desc {Abusive Host / Open Proxy (if 127.0.0.3)} mainurl {http://www.AHBL.Org/} checkurl {http://AHBL.Org/tools/lookup.php?ip=%s} codes {{127.0.0.[3-9]} 127.0.0.10}}
		{priority 10 weight 5 rbl DNSBL.DroneBL.Org desc {Open Proxy or ...} mainurl {http://DroneBL.Org/} checkurl {http://DroneBL.Org/lookup_branded.do?ip=%s&network=Network} codes {{127.0.0.[3-9]} 127.0.0.10 127.0.0.255}}
		{priority 10 weight 4 rbl OPM.Tornevall.Org desc {Open Proxy} mainurl {http://DNSBL.Tornevall.Org/org/} checkurl {http://DNSBL.Tornevall.Org/org/scan.php} codes {{127.0.0.2}}}
		{priority 10 weight 4 rbl Tor.AHBL.Org desc {Tor Exit Node} mainurl {http://www.AHBL.Org/} checkurl {http://AHBL.Org/tools/lookup.php?ip=%s} codes {{127.0.0.[3-4]}}}
		{priority 30 weight -1 rbl no-more-funn.Moensted.DK desc {Dynamic IP Whitelist} mainurl {http://Moensted.DK/spam/no-more-funn/} checkurl {http://Moensted.DK/spam/no-more-funn/?addr=%s} codes {127.0.0.3}}
		{priority 30 weight -1 rbl DUL.DNSBL.SORBS.Net desc {Dynamic IP Whitelist} mainurl {http://WWW.SORBS.Net/} checkurl {http://WWW.AU.SORBS.Net/lookup.shtml?%s} codes {127.0.0.10}}
		{priority 30 weight -1 rbl DynaBlock.NJABL.Org desc {Dynamic IP Whitelist} mainurl {} checkurl {} codes {127.0.0.3}}
		{priority 30 weight -1 rbl DHCP.TQMcube.Com desc {Dynamic/DHCP IP Whitelist} mainurl {http://TQMcube.Com/} checkurl {http://TQMcube.Com/cgi-bin/checkbl?ip=%s} codes {127.0.0.2}}
		{priority 30 weight -2 rbl Dialups.Mail-Abuse.Org desc {Dial-up IP Whitelist} mainurl {http://www.mail-abuse.com/enduserinfo_dul.html} checkurl {http://www.mail-abuse.com/cgi-bin/lookup?ip_address=%s} codes {127.0.0.3}}
		{priority 30 weight -2 rbl Dialup.DRBL.Sandy.RU desc {Dialup IP Whitelist} mainurl {} checkurl {} codes {127.0.0.2}}
		{priority 50 weight 3 rbl RBL.EFNet.Org desc {Open Proxy or other badness} mainurl {http://RBL.EFNet.Org/} checkurl {http://RBL.EFNet.Org/?i=%s} codes {{127.0.0.[1-5]}}}
		{priority 50 weight 6 rbl ExitNodes.Tor.DNSBL.Sectoor.DE desc {Tor Exit Node} mainurl {http://WWW.Sectoor.DE/tor.php} checkurl {http://WWW.Sectoor.DE/tor.php?ip=%s} codes {{127.0.0.1}}}
		{priority 50 weight 6 rbl Tor.Kewlio.Net.UK desc {Tor Exit Node} mainurl {} checkurl {} codes {{127.0.0.100}}}
		{priority 70 weight 1 rbl No-More-Funn.Moensted.DK desc {Open Proxy} mainurl {http://Moensted.DK/spam/no-more-funn/} checkurl {http://Moensted.DK/spam/no-more-funn/?addr=%s} codes {127.0.0.10}}
		{priority 70 weight 6 rbl VirBL.DNSBL.Bit.NL desc {Virus Infected} mainurl {http://VirBL.Bit.NL/} checkurl {http://DNSBL.Net.AU/lookup/?%s} codes {127.0.0.1}}
		{priority 70 weight 6 rbl Probes.DNSBL.Net.AU desc {Probe (Server currently probing other networks)} mainurl {http://DNSBL.Net.AU/probes/} checkurl {http://DNSBL.Net.AU/lookup/?%s} codes {127.0.0.2}}
		{priority 70 weight 6 rbl RBL.Triumf.CA desc {Open Proxy} mainurl {http://Andrew.Triumf.CA/relaytest.html} checkurl {http://DNSStuff.com/tools/lookup.ch?name=%s&type=TXT} codes {127.0.0.4}}
		{priority 80 weight 1 rbl XBL.Spamhaus.Org desc {Open Proxy or Worm/Virus/Trojan Host} mainurl {http://www.Spamhaus.Org/XBL/} checkurl {http://www.Spamhaus.Org/query/bl?ip=%s} codes {127.0.0.*}}
		{priority 80 weight 1 rbl CBL.AbuseAt.Org desc {Open Proxy} mainurl {http://CBL.AbuseAt.Org/} checkurl {http://CBL.AbuseAt.Org/lookup.cgi?ip=%s} codes {127.0.0.2}}
		{priority 90 weight 1 rbl OSPS.DNSBL.Net.AU desc {Open Proxy} mainurl {http://DNSBL.Net.AU/osps/} checkurl {http://DNSBL.Net.AU/lookup/?%s} codes {127.0.0.2}}
		{priority 90 weight 1 rbl Socks.DNSBL.SORBS.Net desc {Open Proxy} mainurl {http://DNSBL.SORBS.Net/} checkurl {http://DNSBL.US.SORBS.Net/cgi-bin/lookup?IP=%s} codes {127.0.0.3}}
		{priority 90 weight 1 rbl OHPS.DNSBL.Net.AU desc {Open Proxy} mainurl {http://DNSBL.Net.AU/osps/} checkurl {http://DNSBL.Net.AU/lookup/?%s} codes {127.0.0.2}}
		{priority 90 weight 1 rbl Misc.DNSBL.SORBS.Net desc {Open Proxy} mainurl {http://DNSBL.SORBS.Net/} checkurl {http://DNSBL.US.SORBS.Net/cgi-bin/lookup?IP=%s} codes {127.0.0.4}}
		{priority 90 weight 1 rbl OWPS.DNSBL.Net.AU desc {Open Proxy} mainurl {http://DNSBL.Net.AU/osps/} checkurl {http://DNSBL.Net.AU/lookup/?%s} codes {127.0.0.2}}
		{priority 90 weight 1 rbl HTTP.DNSBL.SORBS.Net desc {Open Proxy} mainurl {http://DNSBL.SORBS.Net/} checkurl {http://DNSBL.US.SORBS.Net/cgi-bin/lookup?IP=%s} codes {127.0.0.2}}
	}
	# BTW, you can find more RBLs from this URL: http://www.moensted.dk/spam/
}

proc ::rblcheck::Join {nick uhost handle channel} {	variable checkidents
	if {$handle eq {*} && ${::strict-host} == 1} {
		set ::strict-host 0
		set handle [nick2hand $nick $channel]
		set ::strict-host 1
	}
	if {![channel get $channel rblcheck] || $handle ne {*} || (!$checkidents && ![string match {~*@*.*} $uhost]) || [matchban "$nick!$uhost" $channel] || [matchexempt "$nick!$uhost" $channel] || [matchinvite "$nick!$uhost" $channel]} {
		return 0
	} elseif {[regexp {^([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])$} [set newhost [lindex [split $uhost @] end]]]} {
		# It's already an IP address..
		switch -glob -- $newhost {
			{127.*.*.*} - {192.168.*.*} - {10.*.*.*} {}
			{default} { delay ::rblcheck::CheckIP $newhost $newhost 1 $nick $uhost $newhost $channel }
		}
	} elseif {[string match {*.*} $newhost]} {
		switch -glob -- $newhost {
			{*/*} - {Cloak*} - {cloak*} - {*.users.undernet.org} - {Oper*} - {oper*} - {*.?} {
				putloglev d $channel "RBLCheck: ($nick!$uhost $channel) Ignoring $newhost because it looks like a cloaked hostname."
				return 0
			}
			{*.local} - {*.lan} - {*.localnet} { return 0 }
			{*static*.*} - {*pppoe*.*} - {*cable*.*} - {*dsl*.*} - {*.sip.*} - {*fios*.*} - {????} - {?????} - {??????} - {???????} - {????????} - {?????????} - {??????????} {}
			{*dial*.*.*} - {*dyn*.*.*} - {*ppp*.*.*} - {*modem*.*.*} - {*slip*.*.*} - {*pool*.*.*} - {*dinamic*.*.*} - {*Dial*.*.*} - {*PPP*.*.*} - {*Dyn*.*.*} - {*.satgate.net} - {*.ipt.aol.com} - {*.neoplus.adsl.tpnet.pl} {
				putloglev d $channel "RBLCheck: ($nick!$uhost $channel) Ignoring $newhost because it looks like a dialup connection."
				return 0
			}
			{*ipv6*.*} - {*ip6.*} - {*IPv6*.*} - {*:*} {
				putloglev d $channel "RBLCheck: ($nick!$uhost $channel) Ignoring $newhost because it looks like it's an IPv6-only hostname."
				return 0
			}
		}
		putloglev d $channel "RBLCheck: ($nick!$uhost $channel) Doing DNS lookup on $newhost to get IP..."
		delay dnslookup $newhost ::rblcheck::CheckIP $nick $uhost $newhost $channel
	}
}

# Called from Join, calls CheckRBLs:
proc ::rblcheck::CheckIP {ip host status nick uhost orighost channel} {
	if {$status} {	variable IPs
		if {$ip ne $host && [matchban "*!*@$ip" $channel]} {
			# If the hosts IP matches a ban then we ban the host..
			if {[set bantime [expr { [channel get $channel ban-time] - 1 }]] <= 0 && [set bantime [expr { ${::global-ban-time} - 1 }]] <= 0} { set bantime 99 }
			newchanban $channel "*!*@$host" RBLCheck "${host}'s IP (${ip}) matched a ban." $bantime
		} elseif {![info exists IPs($ip)]} {	variable rbls
			foreach {a b c d} [split $ip .] {break}
			set IPs($ip) [list startms [clock clicks -milliseconds] reverseip "$d.$c.$b.$a" nick $nick ip $ip host $host uhost $uhost orighost $orighost channels [list [string tolower $channel]] priority [lindex [lindex $rbls 0] 1] weight [string match {~*@*.*} $uhost]]
			delay ::rblcheck::CheckRBLs $ip
		} else {
			# There's background lookups already for this IP, so we just update some of the info:
			array set ipinfo $IPs($ip)
			if {[lsearch -exact $ipinfo(channels) [set channel [string tolower $channel]]] == -1} { lappend ipinfo(channels) $channel }
			array set ipinfo [list nick $nick uhost $uhost]
			set IPs($ip) [array get ipinfo]
		}
	} else {
		putloglev d $channel "RBLCheck: ($nick!$uhost $channel) Couldn't resolve $host.  (No further action taken.)"
	}
}

# Called from CheckIP or CheckResult, calls CheckResult:
proc ::rblcheck::CheckRBLs {ip} {	variable IPs
	array set ipinfo $IPs($ip)
	# Check to see if there's any background dnslookups still running, return if there are..
	if {![llength [array names ipinfo rbl,*]]} {	variable rbls
		# Do dnslookups on the next priority level:
		foreach r $rbls {
			array set rblinfo $r
			if {$rblinfo(priority) == $ipinfo(priority)} {
				#putloglev d * "RBLCheck: ($ipinfo(priority)) Looking up $ipinfo(reverseip).$rblinfo(rbl)"
				set ipinfo(rbl,$rblinfo(rbl)) [concat [array get rblinfo] [list status -1]]
				set IPs($ip) [array get ipinfo]
				delay dnslookup "$ipinfo(reverseip).$rblinfo(rbl)" ::rblcheck::CheckResult $ip $rblinfo(rbl)
			} elseif {$rblinfo(priority) > $ipinfo(priority)} {
				# Set ipinfo(priority) to the next priority level and return:
				set ipinfo(priority) $rblinfo(priority)
				set IPs($ip) [array get ipinfo]
				return
			}
		}
		# There's no more RBLs left to query, do cleanup and exit:
		unset IPs($ip)
	}
}

# Called from CheckRBLs, calls CheckRBLs:
proc ::rblcheck::CheckResult {ip host status origip rbl} {	variable IPs
	if {[info exists IPs($origip)]} {
		array set ipinfo $IPs($origip)
		array set rblinfo $ipinfo(rbl,$rbl)
		if {$status == 1} {
			variable checkidents
			variable banweight
			variable abortweight
			set weight $ipinfo(weight)
			# status is 1, so maybe one of the code(s) matches the resolved IP:
			foreach code $rblinfo(codes) {
				if {[string match $code $ip] && [incr ipinfo(weight) $rblinfo(weight)] >= $banweight} {
					# A match was found!
					if {$rblinfo(checkurl) ne {}} { set checkurlinfo " See [format $rblinfo(checkurl) $ipinfo(ip)] " } else { set checkurlinfo {} }
					if {$rblinfo(mainurl) ne {}} { set mainurlinfo " See $rblinfo(mainurl) for more information. " } else { set mainurlinfo {} }
					if {!$checkidents && [string match {~*@*} $ipinfo(uhost)]} { set identinfo " Please note, that if you fix your ident you won't be banned again by this bot.  (People with idents are exempt from the RBL check) " } else { set identinfo {} }
					foreach channel $ipinfo(channels) {
						putloglev d $channel "RBLCheck ($rblinfo(rbl)): (weight: $ipinfo(weight)) $host => $ip - See: [format $rblinfo(checkurl) $ipinfo(ip)]"
						if {![matchban "$ipinfo(nick)!$ipinfo(uhost)" $channel] && ![isvoice $ipinfo(nick)] && ![isop $ipinfo(nick)] && ![ishalfop $ipinfo(nick)]} {
							if {[botisop $channel] || [botishalfop $channel]} {
								putkick $channel $ipinfo(nick) "$rblinfo(rbl) lists your IP as a $rblinfo(desc).$checkurlinfo"
								puthelp "NOTICE $ipinfo(nick) :Your IP address was listed by $rblinfo(rbl) as being an $rblinfo(desc). $checkurlinfo $mainurlinfo "
							} else {
								puthelp "NOTICE $channel :$ipinfo(nick)!$ipinfo(uhost)'s IP ($ipinfo(ip)), according to $rblinfo(rbl), is (or was) a known $rblinfo(desc). $checkurlinfo $mainurlinfo"
							}
							if {[set bantime [expr { [channel get $channel ban-time] - 1 }]] <= 0 && [set bantime [expr { ${::global-ban-time} - 1 }]] <= 0} { set bantime 99 }
							# Note, the ban needs to be set, even if the bot isn't currently opped..
							if {$checkidents || !${::strict-host}} {
								newchanban $channel "*!*@$ipinfo(orighost)" RBLCheck "$rblinfo(rbl) => $ip -$checkurlinfo" $bantime
							} else {
								newchanban $channel "*!~*@$ipinfo(orighost)" RBLCheck "$rblinfo(rbl) => $ip -$checkurlinfo" $bantime
							}
						}
					}
					# A match was found, so there's no need to continue checking any more, so do cleanup and exit:
					unset IPs($origip)
					# Send a note:
					variable notes
					if {[string trim $notes] ne {}} { foreach n [split $notes {, }] { if {[validuser $n]} { catch { sendnote RBLCheck $n "RBLCheck: Banned $ipinfo(nick)!$ipinfo(uhost) from [join $ipinfo(channels) {, }] - $rblinfo(rbl) says IP is an $rblinfo(desc) - $host => $ip - $checkurlinfo $mainurlinfo" } } } }
					return 0
				} elseif {$ipinfo(weight) < $abortweight} {
					unset IPs($origip)
					putloglev d * "RBLCheck: $rblinfo(rbl) - $ipinfo(nick)!$ipinfo(uhost) / $ipinfo(ip) - Aborting with weight: $ipinfo(weight)"
					return 0
				} else {
					# Prevent it increasing the weight for any other matching $rblinfo(codes):
					break
				}
			}
			if {$weight != $ipinfo(weight)} {
				set weight $ipinfo(weight)
				putloglev d * "RBLCheck: $rblinfo(rbl) - $ipinfo(nick)!$ipinfo(uhost) / $ipinfo(ip) - New weight: $weight"
			}
		}
		# If we didn't return above, it means there wasn't a match in that RBL.
		variable rbls
		if {$ipinfo(priority) >= [lindex [lindex $rbls end] 1]} {
			# If we've tried all the RBLs, do cleanup and exit:
			unset IPs($origip)
			# If it happens to hit the warn weight, send a warning to the @'s in the channel:
			variable warnweight
			if {$ipinfo(weight) >= $warnweight} {
				foreach channel $ipinfo(channels) {
					puthelp "PRIVMSG @$channel :$ipinfo(nick)!$ipinfo(uhost)'s IP ($ipinfo(ip)), according to $rblinfo(rbl), is (or was) a known $rblinfo(desc). $checkurlinfo $mainurlinfo"
				}
			}
			putloglev d * "RBLCheck: $origip took [expr { ([clock clicks -milliseconds] - $ipinfo(startms)) / 1000.0 }] seconds to lookup."
		} else {
			# Clear the info for this RBL:
			array unset ipinfo rbl,$rbl
			set IPs($origip) [array get ipinfo]
			# Try the next priority:
			delay ::rblcheck::CheckRBLs $origip
		}
	}
}

# Adds delays based on $delay, this should help spread the load further out on nameservers, and possibly make the bot slightly more responsive while doing lookups.
proc ::rblcheck::delay {args} {
	variable delay
	# If we're backlogging lookups, lower the delay to speed things up temporarily:
	variable IPs
	if {[set Delay $delay] > 0 && [set lookups [array size IPs]] > 1 && [incr Delay] && [incr Delay "-$lookups"] < 0} {
		set Delay 0 
		#putloglev d * "RBLCheck: $lookups lookups backlogged, lowering delay to $Delay temporarily.."
	}
	switch -- $Delay {
		{0} {
			# After Tcl hits the event-loop next (which is practically immediate):
			after idle $args
		}
		{1} {
			# After Tcl hits the event-loop the second time (which in Eggdrop is once per second):
			after idle [list after $Delay $args]
		}
		{default} {
			# After $delay seconds, and after Tcl hits the event-loop the second time:
			utimer $Delay [list after idle [list after $Delay $args]]
		}
	}
}

namespace eval ::rblcheck {	variable rbls
	# This sorts the rbls list by priority:
	variable rbls [lsort -integer -index 1 $rbls]
	setudef flag rblcheck
	variable checkidents
	variable IPs
	array unset IPs *
	array set IPs {}
	if {!${::strict-host} || $checkidents} {
		# strict-host is 0 or we're to check people with idents.
		catch { unbind join - {* *!~*@*.*} ::rblcheck::Join }
		bind join - {* *!*@*.*} ::rblcheck::Join
	} else {
		# strict-host is 1 and checkidents is 0.
		catch { unbind join - {* *!*@*.*} ::rblcheck::Join }
		bind join - {* *!~*@*.*} ::rblcheck::Join
	}
	variable version {0.9.7}
	variable delay
	if {[catch { checkmodule dns }] && $delay < 1} { variable delay 1 }
	putlog "rblcheck.tcl v$version by FireEgl - Loaded."
	set version
}
