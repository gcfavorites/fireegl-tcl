# slowvoice.tcl v1.4 by FireEgl@EFNet <FireEgl@LinuxFan.com> - January 2001

### Description:
# Will voice +v users on join after a random delay and checks
# to see if they're not already voiced to avoid +v mode flooding.


### Notes:
# You must set your channel(s) -autovoice for this script to do the voiceing.
#
# Delayed auto-voiceing is now a feature of Eggdrop itself as of v1.6.2+.  (See .help chaninfo)


### Options:
## Delay in seconds before we voice someone:
# x:y random delay; minimum x sec, maximum y sec
set sv(delay) 3:99

## Should we bother to voice people that have ops?  (1 = yes, 0 no)
set sv(voiceops) 0

## Slow Voice method:
# Set to 1 for the old method, which is only look at the person who joined to see if they need to be voiced.
# Set to 2 for the new method, which is voice anybody in the channel who should have voice. (uses pushmode)
set sv(method) 2


### Begin Script:
if {$numversion < 1060200} {
   bind join v|v * join:sv
   proc join:sv {nick host hand chan} { global sv
      utimer [expr [lindex [split $sv(delay) :] 0] + [rand [lindex [split $sv(delay) :] 1]]] [list sv:voice $nick $host $hand $chan]
   }
   proc sv:voice {nick host hand chan} {
      if {[botisop $chan]} { global sv
         switch -- "$sv(method)" {
            "1" {
               if {((![isbotnick $nick]) && (![isbotnick [hand2nick $hand $chan]]))} {
                  if {(([onchan $nick $chan]) && ("[getchanhost $nick $chan]" == "$host") && (![isvoice $nick $chan]) && (($sv(voiceops)) || (![isop $nick $chan])))} {
                     # They still have the nick they joined with.
                     puthelp "MODE $chan +v $nick"
                  } elseif {((![onchan $nick $chan]) && ([handonchan $hand $chan]) && (![isvoice [hand2nick $hand $chan] $chan]) && (($sv(voiceops)) || (![isop [hand2nick $hand $chan] $chan])))} {
                     # They most likely changed nicks after joining.
                     puthelp "MODE $chan +v [hand2nick $hand $chan]"
                  }
               }
            }
            "2" {
               foreach u "[chanlist $chan]" {
                  if {((![isvoice $u $chan]) && ([matchattr [nick2hand $u $chan] v|v $chan]) && (![isbotnick $u]) && (($sv(voiceops)) || (![isop $u $chan])))} {
                     pushmode $chan +v $u
                  }
               }
            }
         }
      }
   }

   if {"[info commands isbotnick]" == ""} {
      proc isbotnick {nick} { global botnick
         if {"[string tolower $nick]" == "[string tolower $botnick]"} { set nick 1 } { set nick 0 }
      }
   }

   foreach c "[channels]" { channel set "$c" -autovoice }
   catch { unset $c }
} else {
   putlog "slowvoice.tcl: Your Eggdrop version already supports delayed auto-voiceing."
}

putlog "slowvoice.tcl v1.4 by FireEgl@EFNet <FireEgl@LinuxFan.com> - Loaded."
