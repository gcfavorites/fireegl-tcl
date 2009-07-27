# swatch.tcl - by FireEgl@EFNet <FireEgl@LinuxFan.com> - 12/31/99

# Description:
# Displays the Swatch internet time when someone types !swatch on the channel.
# But it's mainly for other scripters to use the swatch proc in their own scripts. =)

# Notes:
# Based on Tiny Beat Watch 0.1.3 (Copyright (C) 1999 Niels Ott)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as 
# published by the Free Software Foundation; either version 2 of
# the License, or (at your opinion) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# You can get a copy of the GNU Genereal Public License from 
# http://www.gnu.org. 
# 
# Please contact niels.ott@usa.net for feedback, bug reports and
# suggestions.

proc swatch {} {
   regsub "^0" "[clock format [clock seconds] -gmt 1 -format %H ]" "" zeit(h)
   regsub "^0" "[clock format [clock seconds] -gmt 1 -format %M ]" "" zeit(m)
   regsub "^0" "[clock format [clock seconds] -gmt 1 -format %S ]" "" zeit(s)
   # Get seconds since midnight:
   set zeit(s_since_mn) [expr (($zeit(h) * 60 + $zeit(m)) * 60) + ($zeit(s))]
   # Add 60s to be in MET, then add offset:
   set zeit(s_since_mn) [expr $zeit(s_since_mn) + 60*60]
   # Check if we've reached the next day:
   if {$zeit(s_since_mn) > 86400} { set zeit(s_since_mn) [expr ($zeit(s_since_mn) - 86400)] }
   # This is the beat:
   set zeit(beat) [expr ((($zeit(s_since_mn)) * 10000) / 86400)]
   # Stick in a decimal point:
   set beat "[string range $zeit(beat) 0 2].[string range $zeit(beat) 3 end]"
   # transform the integer value to a string with leading zeroes:
   if [expr $beat < 10] { set beat "@00$beat" } elseif [expr $beat < 100] { set beat "@0$beat" } else { set beat "@$beat" }
   return "$beat"
}

bind pub vfo|vfo !swatch pub:swatch
proc pub:swatch {nick host hand chan args} { puthelp "PRIVMSG $chan :Swatch Internet Time: [swatch]" }
