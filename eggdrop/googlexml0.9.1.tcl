# googlexml.tcl v0.9 - by FireEgl@EFNet <EggTcl @ Atlantica . US> (www.Tcl.Atlantica.US) - Sept. 21, 2002.

### Description:
## Queries Google using pub/msg/dcc/chat commands and returns the results.
# This script is different from other Google scripts in that it gets
# the results from Google in XML format, which makes it easy for me to
# process..

### Requirements:
# You'll need Tcl v8.4.0 or higher.
# You'll also need to create an account on Google:
# https://www.Google.com/accounts/NewAccount?continue=http://api.google.com/createkey&followup=http://api.google.com/createkey
# The account will provide you with a Key for use in this script.
# (Google requires this key to provide people with up to 1000 free Google queries per day)

package require http
namespace eval ::google {
	## Your Google Key:
	variable key {ptLa1vdQFHIIt1e691uE83svObfOQX70}
	## This is how many results you want to be returned:
	variable maxresults {1}
	## English-only speaking people should leave this alone:
	# Although, setting this to {} would (I think) get results in all languages.
	variable lang {en}
	# Note, I don't have an option to change the encoding type.. I will on request.
	proc config {options} { if {[llength $options]} { foreach {a d} $options { variable $a $d } } }
	proc search {search {options {}}} { config $options
		variable maxresults
		variable lang
		variable key
		set matches 0
		set results {}
		# If you're curious as to what XooMLe.DentedReality.Com.AU is doing here then visit http://www.DentedReality.Com.AU/xoomle/docs/
		foreach t [lsearch -all [set ldata [split [http::data [set token [http::geturl http://XooMLe.DentedReality.Com.AU/search/?key=$key&q=[query_encode $search]&maxResults=$maxresults&ie=ISO-8859-1&filter=1&safeSearch=1&num=$maxresults&hl=$lang&lr=lang_$lang&safe=active&as_qdr=all -timeout 9999]]] \n]] {*<title>*</title>}] { incr matches
			lappend results $matches
			regsub -all "<title>|</title>" [lindex $ldata $t] {} title
			regsub -all "<summary>|</summary>" [lindex $ldata [expr $t + 1]] {} summary
			regsub -all "<URL |</URL>" [lindex $ldata [expr $t + 2]] {} url
			regsub -all "<snippet>|</snippet>" [lindex $ldata [expr $t + 4]] {} snippet
			putlog $title
			lappend results [list title [string trim $title] summary [string trim $summary] url [lindex [split $url >] 1] snippet [string trim $snippet]]
		}
		::http::cleanup $token
		set results
	}
	proc google2irc {search} { set out {}
		foreach {a d} [::google::search $search] { array set results $d
			lappend out "$a. [html2mirc [uneschtml "$results(title) - $results(summary) - $results(url) - $results(snippet)"]]"
		}
		return $out
	}
	bind pub - !google ::google::pub
	bind pub - !g ::google::pub
	bind pub - google ::google::pub
	bind pub - g ::google::pub
	proc pub {nick host hand chan text} {
putlog "TESTIN!!!"
 foreach l [google2irc $text] { puthelp "PRIVMSG $chan :$nick: $l" } }
	bind msg - !google ::google::msg
	bind msg - !g ::google::msg
	proc msg {nick host hand text} { foreach l [google2irc $text] { puthelp "PRIVMSG $nick :$l" } }
	bind dcc - google ::google::dcc
	proc dcc {hand idx text} { foreach l [google2irc $text] { putdcc $idx $l } }
	bind chat - "!google *" ::google::chat
	bind chat - "!g *" ::google::chat
	proc chat {hand chan text} { foreach l [google2irc [join [lrange [split $text] 1 end]]] { dccputchan $chan "$hand: $l" } }
}
package provide google


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
	}

	## unhtml - Removes all HTML tags:
	proc unhtml {text} {
		regsub -all -nocase -- "<br>|<p>|</p>|<hr>|<h1>|</h1>|<h2>|</h2>|<h3>|</h3>|<h4>|</h4>|<h5>|</h5>|<h6>|</h6>" [set text [uneschtml $text]] { } text
		# FixMe: <pre> - ignore HTML tags - Deprecated: <xmp> <listing>
		set length [string length $text]
		set replace [set pos 0]
		while {$pos < $length} {
			if {[set char [string index $text $pos]] == {<}} {
				set replace 1
			} elseif {[string index $text $pos] == {>}} {
				set replace 0
			} elseif {!$replace} {
				append out $char
			}
			incr pos
		}
		set out
	}

	## html2irc - Converts HTML to IRC readable text:
	proc html2irc {text {eolchars "\n"}} {
		if {[string match "*<*>*" "$text"]} {
			# Bold:
			regsub -all -nocase -- "<strong>|</strong>|<b>|</b>" $text "\002" text
			# Underline:
			regsub -all -nocase -- "<title>|</title>|<i>|</i>|<u>|</u>|<cite>|</cite>|<def>|</def>" $text "\037" text
			# Inverse:
			regsub -all -nocase -- "<s>|</s>|<del>|</del>|<strike>|</strike>|<em>|</em>" $text "\026" text
			# Blink -> Beep
			regsub -all -nocase -- "<blink>|</blink>" $text "\a" text
			# Others:
			regsub -all -nocase -- "<q>|</q>" $text "\"" text
			if {"$eolchars" != "\n"} { regsub -all -- "\n" "[unhtml $text]" "$eolchars" text } else { set text "[unhtml $text]" }
			#regsub -all -- "\t" $text "   " text
			string trim $text
		} else {
			uneschtml $text
		}
	}

	## html2mirc - Converts HTML to mIRC readable text:
	proc html2mirc {text {eolchars "\n"}} {
		if {[string match "*<*>*" $text]} {
			# Reset formatting:
			regsub -all -nocase -- "</font>|<tt>|</tt>|<kbd>|</kbd>|<samp>|</samp>|<code>|</code>|<var>|</var>" $text "\00399" text
		}
		html2irc $text $eolchars
	}

	## Color names to mIRC color codes (currently not used anywhere):
	# Might should update to include some of the "web safe colors".
	array set mirchtml_map {0 white 8 yellow 1 black 9 lightgreen 2 blue 10 cyan 3 green 11 lightcyan 4 lightred 12 lightblue 5 brown 13 pink 6 purple 14 grey 7 orange 15 lightgrey}


	## Query encoding stuff:
	for {set i 1} {$i <= 256} {incr i} { if {![string match \[a-zA-Z0-9\] [set c [format %c $i]]]} { set query_map($c) %[format %.2X $i] } }
	array set query_map {" " +   \n %0D%0A}
	proc query_encode {string} { global query_map
		# 1. Leave alphanumerics characters alone.
		# 2. Convert every other character to an array lookup.
		# 3. Escape constructs that are "special" to the tcl parser. (different from using "split")
		# 4. "subst" the result, doing all the array substitutions.
		regsub -all \[^a-zA-Z0-9\] $string {$query_map(&)} string
		# This quotes cases like $map([) or $map($)
		regsub -all {[][{})\\]\)} $string {\\&} string
		subst -nocommands -nobackslashes $string
	}


putlog "googlexml.tcl - Loaded"
