# headlines.tcl v1.6.1 - by FireEgl@EFNet <Headlines@FireEgl.CJB.Net> (www.FireEgl.CJB.Net) - 11-2004
namespace eval ::headlines {} ;# Don't touch this line.

### Description:
# Fetches headlines from sites and announces the new ones in specified channels at specified intervals.

### Thanks:
# Thank you devnu11 for giving me incentive to update this script.  =)

### Options:
## These are settings for each site that we get headlines from:
## Comment out the ones you don't want.
## Only change the channels, interval, and announce settings!

# If more than this many headlines are queued to send to the channel
# it'll dump more than one-per-minute to stay below this many:
# (Setting this low will ensure that you see the latest headlines ASAP, but may flood the channel in surges).
set 1minqueue_backlog 120

# CNN.Com:
array set ::headlines::headlines-CNN {
 host WWW.CNN.Com
 port 80
 get /desktop/content.html
 channels {#SafeTcl}
 interval 6
 announce {$desc: $headline - $url}
 name CNN
}

# FreshMeat.Net:
array set ::headlines::headlines-FreshMeat {
 host download.freshmeat.net
 port 80
 get /backend/recentnews.txt
 channels {#SafeTcl}
 interval 5
 announce {$desc: $headline - $url - $xtra}
 name FreshMeat
}

# Prognosisx:
array set ::headlines::headlines-Prognosisx {
 host WWW.Prognosisx.Com
 port 80
 get /infosyssec/announce.txt
 channels {#SafeTcl}
 interval 29
 announce {$desc: $headline - $url -=- $xtra}
 name Prognosisx
}

# CBS MarketWatch:
array set ::headlines::headlines-CBS {
 host cbs.marketwatch.com
 port 80
 get /news/newsfinder/default.asp?scid=1&siteid=mktw
 channels {#SafeTcl}
 interval 9
 announce {$desc: $headline - $url -=- $xtra}
 name CBS
}

# newzBin/Unknown:
array set ::headlines::headlines-newzBin-Unknown {
 host www.newzbin.com
 port 80
 get /browse/cat/p/unknown/?sort=post_date
 channels {#SafeTcl}
 interval 99
 announce {$desc: $headline - $url}
 name newzBin-Unknown
}

# newzBin/Anime:
array set ::headlines::headlines-newzBin-Anime {
 host www.newzbin.com
 port 80
 get /browse/cat/p/anime/?sort=post_date
 channels {#SafeTcl}
 interval 57
 announce {$desc: $headline - $url}
 name newzBin-Anime
}

# newzBin/Apps:
array set ::headlines::headlines-newzBin-Apps {
 host www.newzbin.com
 port 80
 get /browse/cat/p/apps/?sort=post_date
 channels {#SafeTcl}
 interval 17
 announce {$desc: $headline - $url}
 name newzBin-Apps
}

# newzBin/Books:
array set ::headlines::headlines-newzBin-Books {
 host www.newzbin.com
 port 80
 get /browse/cat/p/books/?sort=post_date
 channels {#SafeTcl}
 interval 19
 announce {$desc: $headline - $url}
 name newzBin-Books
}

# newzBin/Consoles:
array set ::headlines::headlines-newzBin-Consoles {
 host www.newzbin.com
 port 80
 get /browse/cat/p/consoles/?sort=post_date
 channels {#SafeTcl}
 interval 20
 announce {$desc: $headline - $url}
 name newzBin-Consoles
}

# newzBin/Emulation:
array set ::headlines::headlines-newzBin-Emulation {
 host www.newzbin.com
 port 80
 get /browse/cat/p/emulation/?sort=post_date
 channels {#SafeTcl}
 interval 47
 announce {$desc: $headline - $url}
 name newzBin-Emulation
}

# newzBin/Games:
array set ::headlines::headlines-newzBin-Games {
 host www.newzbin.com
 port 80
 get /browse/cat/p/games/?sort=post_date
 channels {#SafeTcl}
 interval 16
 announce {$desc: $headline - $url}
 name newzBin-Games
}

# newzBin/Misc:
array set ::headlines::headlines-newzBin-Misc {
 host www.newzbin.com
 port 80
 get /browse/cat/p/misc/?sort=post_date
 channels {#SafeTcl}
 interval 97
 announce {$desc: $headline - $url}
 name newzBin-Misc
}

# newzBin/Movies:
array set ::headlines::headlines-newzBin-Movies {
 host www.newzbin.com
 port 80
 get /browse/cat/p/movies/?sort=post_date
 channels {#SafeTcl}
 interval 15
 announce {$desc: $headline - $url}
 name newzBin-Movies
}

# newzBin/Music:
array set ::headlines::headlines-newzBin-Music {
 host www.newzbin.com
 port 80
 get /browse/cat/p/music/?sort=post_date
 channels {#SafeTcl}
 interval 21
 announce {$desc: $headline - $url}
 name newzBin-Music
}

# newzBin/PDA:
array set ::headlines::headlines-newzBin-PDA {
 host www.newzbin.com
 port 80
 get /browse/cat/p/pda/?sort=post_date
 channels {#SafeTcl}
 interval 49
 announce {$desc: $headline - $url}
 name newzBin-PDA
}

# newzBin/TV:
array set ::headlines::headlines-newzBin-TV {
 host www.newzbin.com
 port 80
 get /browse/cat/p/tv/?sort=post_date
 channels {#SafeTcl}
 interval 14
 announce {$desc: $headline - $url}
 name newzBin-TV
}

# newzBin/XXX:
array set ::headlines::headlines-newzBin-XXX {
 host www.newzbin.com
 port 80
 get /browse/cat/p/xxx/?sort=post_date
 channels {#SafeTcl}
 interval 22
 announce {$desc: $headline - $url}
 name newzBin-XXX
}



### Begin Script:
proc ::headlines::Get {desc} { Close $desc
	upvar 1 ::headlines::headlines-$desc info
	if {$::server != {} && ![catch { set info(sock) [socket -async $info(host) $info(port)] }]} {
		fconfigure $info(sock) -blocking 0 -buffering line
		fileevent $info(sock) writable [list ::headlines::Write $info(sock) $info(host) $info(port) $info(get)]
		fileevent $info(sock) readable [list ::headlines::Read $desc $info(sock) $info(host) $info(channels)]
	}
	timer $info(interval) [list ::headlines::Get $desc]
}

# Send a GETs request upon connect:
proc ::headlines::Write {sock host port get} {
	fileevent $sock writable {}
	puts $sock "GET $get HTTP/1.0\nHost: $host:$port\nConnection: Close\n"
}

# Process each line as it comes in:
proc ::headlines::Read {desc sock host channels} {
	if {[fconfigure $sock -error] != {}} {
		Close $desc
		return
	}
	upvar #0 ::headlines::headlines-$desc info
	set info(body) 0
	while {[gets $sock line] != -1} {
		set announce 0
		#putlog "$desc $sock $host $channels \"$line\""
		if {$line == {} && !$info(body)} {
			set info(body) 1
			continue
		} elseif {!$info(body)} {
			continue
		}
		switch -glob -- $desc {
			{CNN} {
				if {([regexp {<a target="opener" href="(.*)">(.*)</a>} $line {} url headline xtra]) && (![info exists info(seen)] || [lsearch -exact $info(seen) $url] == -1)} {
					lappend info(seen) $url
					set url "http://CNN.Com$url"
					set announce 1
					if {[llength $info(seen)] > 99} { set info(seen) [lrange $info(seen) 9 end] }
				}
			}
			{FreshMeat} {
				if {![info exists info(headline)]} {
					set info(headline) $line
				} elseif {![info exists info(xtra)]} {
					set info(xtra) $line
				} else {
					set headline $info(headline)
					unset info(headline)
					set url $line
					set xtra $info(xtra)
					unset info(xtra)
					if {![info exists info(seen)] || [lsearch -exact $info(seen) $url] == -1} {
						lappend info(seen) $url
						set announce 1
						if {[llength $info(seen)] > 30} { set info(seen) [lrange $info(seen) 3 end] }
					}
				}
			}
			{Prognosisx} {
				if {([regexp {<a href="http://www\.snpx\.com/cgi-bin/news5\.cgi\?target=(.*)" target="_blank">(.*)</a><br>(.*) <br><br>} $line {} url headline xtra]) && (![info exists info(seen)] || [lsearch -exact $info(seen) $url] == -1)} {
					lappend info(seen) $url
					set announce 1
					if {[llength $info(seen)] > 99} { set info(seen) [lrange $info(seen) 9 end] }
				}
			}
			{CBS} {
				if {([regexp {<td width="5"></td><td valign="top"><a class="lk01" href="(.*)&amp;siteID=mktw&amp;scid=1&amp;doctype=2008&amp;property=&amp;value=&amp;categories=&amp;">(.*)</a><span class="t05"> - (.*)</span></td></tr>} $line {} url headline xtra]) && (![info exists info(seen)] || [lsearch -exact $info(seen) $url] == -1)} {
					lappend info(seen) $url
					set url "http://CBS.MarketWatch.Com$url"
					set headline [uneschtml $headline]
					set announce 1
					if {[llength $info(seen)] > 99} { set info(seen) [lrange $info(seen) 9 end] }
				}
			}
			{newzBin-*} {
				if {[regexp -line {.*<a href="/browse/post/(.*)/">(.*)</a>} $line {} postnum headline]} {
					set url "www.newzBin.com/browse/post/$postnum/"
					if {![info exists info(seen)] || [lsearch -exact $info(seen) $url] == -1} {
						lappend info(seen) $url
						set headline [uneschtml $headline]
						set announce 1
						if {[llength $info(seen)] > 99} { set info(seen) [lrange $info(seen) 9 end] }
					}
				}
			}
		}
		if {$announce} {
			if {$channels == {*}} { set channels [channels] }
			foreach c $channels { put1minqueue $c [subst -nocommands $info(announce)] }
		}
		if {[info exists done]} {
			Close $desc
			return
		}
	}
	if {[eof $sock]} { Close $desc }
}

# Does socket and fileevent and variable clean-ups:
proc ::headlines::Close {desc} { upvar 1 ::headlines::headlines-$desc info
	catch {
		fileevent $info(sock) writable {}
		fileevent $info(sock) readable {}
		close $info(sock)
	}
	catch { unset info(body) }
}

proc put1minqueue {channel text} { global 1minqueue
	set channel [string tolower $channel]
	if {![info exists 1minqueue($channel)]} { set 1minqueue($channel) [list] }
	set 1minqueue($channel) [linsert $1minqueue($channel) 0 $text]
}

bind time - "* * * * *" time:1minqueue
proc time:1minqueue {min hour day month year} { global 1minqueue
	foreach channel [array names 1minqueue] {
		if {[llength $1minqueue($channel)]} {
			puthelp "PRIVMSG $channel :[lindex $1minqueue($channel) 0]"
			set 1minqueue($channel) [lrange $1minqueue($channel) 1 end]
			while {[llength $1minqueue($channel)] > $::1minqueue_backlog} {
				puthelp "PRIVMSG $channel :[lindex $1minqueue($channel) 0]"
				set 1minqueue($channel) [lrange $1minqueue($channel) 1 end]
			}
		}
	}
}

## Find and unescape HTML escape characters of the form &xxx;
proc uneschtml {text} {
   if {![regexp & $text]} { set text } else {
      regsub -all {([][$\\])} $text {\\\1} text
      regsub -all {&#([0-9][0-9]?[0-9]?);?} $text {[format %c [scan \1 %d tmp;set tmp]]} text
      regsub -all {&([a-zA-Z]+);?} $text {[uneschtml_map \1]} text
      subst -novariables $text
   }
}
## Convert an HTML escape sequence into character (used only by uneschtml):
proc uneschtml_map {text {unknown ?}} { global eschtml_map
   if {[info exists eschtml_map($text)]} { set eschtml_map($text) } else { set unknown }
}
## ISO Latin-1 escape characters/codes (used by uneschtml_map):
array set eschtml_map {
   lt <   gt >   amp &   quot \"   copy \xa9
   reg \xae   ob \x7b   cb \x7d   nbsp \xa0
	nbsp \xa0 iexcl \xa1 cent \xa2 pound \xa3 curren \xa4
	yen \xa5 brvbar \xa6 sect \xa7 uml \xa8 copy \xa9
	ordf \xaa laquo \xab not \xac shy \xad reg \xae
	hibar \xaf deg \xb0 plusmn \xb1 sup2 \xb2 sup3 \xb3
	acute \xb4 micro \xb5 para \xb6 middot \xb7 cedil \xb8
	sup1 \xb9 ordm \xba raquo \xbb frac14 \xbc frac12 \xbd
	frac34 \xbe iquest \xbf Agrave \xc0 Aacute \xc1 Acirc \xc2
	Atilde \xc3 Auml \xc4 Aring \xc5 AElig \xc6 Ccedil \xc7
	Egrave \xc8 Eacute \xc9 Ecirc \xca Euml \xcb Igrave \xcc
	Iacute \xcd Icirc \xce Iuml \xcf ETH \xd0 Ntilde \xd1
	Ograve \xd2 Oacute \xd3 Ocirc \xd4 Otilde \xd5 Ouml \xd6
	times \xd7 Oslash \xd8 Ugrave \xd9 Uacute \xda Ucirc \xdb
	Uuml \xdc Yacute \xdd THORN \xde szlig \xdf agrave \xe0
	aacute \xe1 acirc \xe2 atilde \xe3 auml \xe4 aring \xe5
	aelig \xe6 ccedil \xe7 egrave \xe8 eacute \xe9 ecirc \xea
	euml \xeb igrave \xec iacute \xed icirc \xee iuml \xef
	eth \xf0 ntilde \xf1 ograve \xf2 oacute \xf3 ocirc \xf4
	otilde \xf5 ouml \xf6 divide \xf7 oslash \xf8 ugrave \xf9
	uacute \xfa ucirc \xfb uuml \xfc yacute \xfd thorn \xfe
	yuml \xff
} ;#"

foreach t [timers] { if {[string match {::headlines::Get *} [lindex $t 1]]} { killtimer [lindex $t 2] } }
foreach v [info vars ::headlines::headlines-*] { timer [expr { 1 + [set $v\(interval)] + int(rand()*9) }] [list ::headlines::Get [set $v\(name)]] }
putlog {headlines.tcl v1.6.1 by FireEgl@EFNet <Headlines@FireEgl.CJB.Net> (www.FireEgl.CJB.Net) - Loaded.}
catch { unset t v }
