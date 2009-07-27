# keeplinked.tcl v1.3 by FireEgl@EFNet <FireEgl@EMail.Com> <FireEgl.cjb.Net) - June 2001

### Description:
# Keeps all your +h (hub) and +a (alt-hub) bots linked.
# (It tries to link to them once per hour.)

### Notes:
# It's just as well that "bind time" doesn't seem to support */10 or 10,20,30,...
# Because you'd see messages like "Lost Bot: Lamest" all the time then..

### Options:
## Besides +h and +a what other bot flag should we try to keep linked?
# Use .botattr to add this flag to your bots.  This must be a number 0-9.
# (Set to -1 to disable checking for this flag)
set kl(botflag) 1

## Set this to 1 for it to try to link the missing
## bots via all the other linked bots that are known:
# This means it'll ask other bots on the botnet that are
# also in the userlist to link to the missing bot. (0 to disable.)
set kl(viaknown) 0


### Begin Script:
if {(([info procs "time:keeplinked"] == {}) && (![catch { bind time - "[rand 5][rand 9] * * * *" time:keeplinked }]))} {
   proc time:keeplinked {min hour day month year} { global kl
      foreach b "[userlist b]" {
         if {((![islinked $b]) && (([string match "*h*" "[set botfl [getuser $b BOTFL]]"]) || ([string match "*a*" "$botfl"]) || (($kl(botflag) != "-1") && ([string match "*$kl(botflag)*" "$botfl"]))) && (![string match "*r*" "$botfl"]) && (![isbotnick $b]))} {
            if {[link "$b"]} { putlog "\[\002KL\002\] Attemping to link to $b..." }
            if {$kl(viaknown)} { foreach v "[bots]" { if {[matchattr "$v" b]} { link "$v" "$b" } } }
         }
      }
   }
   if {"[info commands isbotnick]" == {}} {
      proc isbotnick {nick} { global botnick
         if {"[string tolower $nick]" == "[string tolower $botnick]"} { set nick 1 } else { set nick 0 }
      }
   }
   putlog {keeplinked.tcl v1.3 by FireEgl@EFNet <FireEgl@EMail.Com> (FireEgl.cjb.Net) - Loaded.}
}
