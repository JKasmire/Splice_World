;;; https://github.com/JKasmire/Splice_World to copy my code and code along.


;; Dice to roll has gone squiffy - seems to always say 0 even though the monsters should not be
;; taking on missions for which they do not have sufficient dice to roll on each necessary attribute
extensions [csv]

globals [
Game_Round
Basic_Monsters_List
Total_Successes_Dice_Roll
Total_Doubles_Dice_Roll
temp_doubling_list
temp_attribute
Cards_list
]

breed [Monsters Monster]
breed [Body_Parts Body_Part]

Monsters-own [
Name
Theoretical?
Attack
Cute
Defence
Fear
Intelligence
Speed
Total_Attack
Total_Defence
Total_Fear
Total_Cute
Total_Speed
Total_Intelligence
Hand
Part_to_Purchase
Boost
My_Goals
Money
Points
My_Mission
Mission_Attribute_Successes
Mission_Name
Mission_Money_Reward
Mission_Points_Reward
Decision
Shaft_Share
]

Body_Parts-own [
Name
Theoretical?
From_What_Animal
Body_Position
Attack
Cute
Defence
Fear
Intelligence
Speed
Cost
Battle_Score
]

to setup
  clear-all
  set Basic_Monsters_List ["bug" "tortoise" "rabbit" "spider" "bird" "cat"]
  set Basic_Monsters_List shuffle Basic_Monsters_List                        ;;; Shuffles the list of Basic or Starter monsters so that games with fewer than the max number of players will not always get the same monsters or in the same order
  set Cards_list csv:from-file "cards_list_min.csv"
  set Cards_list shuffle Cards_list
  if Garrulous? [print "Cards shuffled!"]
  setup_Monsters
  Calculate_Total_Attributes
  reset-ticks
end

to setup_Monsters
  create-Monsters Number_Players                                    ;;; Creates starter monsters equal to the number of players
  ask Monsters [                                                    ;;;
    set Name first Basic_Monsters_List                              ;;; The first monster sets its name to the first on the recently shuffled list of basic or starter monsters. Effectively, player one draws a card to see what monster to play as
    set Basic_Monsters_List but-first Basic_Monsters_List           ;;; Removes the first monster from the basic monster list so the next player will draw a different "card"
    set Theoretical? False                                          ;;; This may or may not be used long term... currently it is expected to be useful for determining which body part to buy
    set size 2                                                      ;;; Adjusts size to be more visible
    set Money 5                                                     ;;; Gets a starting bank balance
    set Points 0                                                    ;;; Ensures the starting points balance is at zero
    set shape Name                                                  ;;; Sets shape to improve visibility of game play
  ]

  layout-circle Monsters 10                                         ;;; once all monsters have been created, at least in the basic sense, they are organised into a circle
  ask Monsters [      set ycor ycor + 3 ]                           ;;; The monsters all then take three steps toward the top of the screen to make room for their body parts to be visible below them without  without overlapping or getting weird

  file-close-all                                                    ;;; close all open files before opening the body parts file
  if not file-exists? "Parts_min.csv" [                             ;;; sanity check to ensure parts file exists before trying to open it
    user-message "No file 'Parts_min.csv' exists!"
    stop]

  file-open "Parts_min.csv"                                         ;;; open the file with the body parts data
  while [ not file-at-end? ] [                                      ;;; We'll read all the data in a single loop
    let data csv:from-row file-read-line                            ;;; here the CSV extension grabs a single line and puts the read data in a list
    create-Body_Parts 1 [                                           ;;; now we can use that list to create a turtle with the saved properties
      set Name ""                                                   ;;; Leave the name field blank for now, because the name only matters when the body part becomes a part of an existing monster
      set Theoretical? True                                         ;;; Initially, all body parts are theoretical. They only become real when they are attached to a monster
      set From_What_Animal item 0 data                              ;;; This describes the animal that the body part comes from
      set Body_Position item 1 data                                 ;;; this describes the body part (e.g. left arm, legs, etc.)
      set Attack item 2 data                                        ;;; This, and the following 7 lines, define the properties of the body part
      set Cute item 3 data
      set Defence item 4 data
      set Fear item 5 data
      set Intelligence item 6 data
      set Speed item 7 data
      set Cost item 8 data
      set Battle_Score item 9 data
      set hidden? True                                             ;;; Is hidden like theoretical? why do I need two? Hidden is primitive feature Netlogo that determines if the object is visible in the agent field
    ]]

file-close                                                         ;;; make sure to close the file
  ask Body_Parts [
    if Body_Position =  "head" [set shape "face happy"]            ;;; All of the newly created (but only theoretical and hidden) body parts set their shape accordingly
    if Body_Position = "trunk" [set shape "pentagon"]
    if Body_Position = "legs"  [set shape "triangle"]
    if Body_Position = "left_arm" [set shape "footprint other"]
    if Body_Position = "right_arm" [set shape "footprint other"] ]

  ask Monsters [acquire-starter-parts]                             ;;; run nested code to ask their matching body parts to move into position, become visible, set colour, etc.
  ask Monsters [set Hand []]                                       ;;; sets the Hand to be an empty list
  ask Monsters [ draw_hand]                                        ;;; each monster draws a hand of cards and sets their hand varable to be that list
  ask Monsters [set label length Hand]

end

to acquire-starter-parts
        ask Body_Parts with [From_What_Animal = [Name] of myself] [ ;;; The monsters ask all body parts who belong to the animal that matches its own name (e.g. the bug monster asks the bug body parts, etc.)
          set Theoretical? False                                    ;;; to set themselves real
          set hidden? False                                         ;;; to set themselves visible
          set Name [Name] of myself                                 ;;; to set their name to match the monster's name
          set color [color] of myself                               ;;; to set their color to match the monster's colour
          move-to myself                                            ;;; to set their position as the same as the monster's position and then (according to which part they are) move into position relative to the monster (e.g. head moves up, legs down, etc.)
          if Body_Position = "head"  [set ycor ycor - 2]
          if Body_Position = "trunk" [set ycor ycor - 3]
          if Body_Position = "legs"  [set ycor ycor - 4]
          if Body_Position = "left_arm" [set xcor xcor - 1 set ycor ycor - 3]
          if Body_Position = "right_arm" [set xcor xcor + 1 set ycor ycor - 3] ]
end

;;;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Set up only procedures above this line ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to go
  ask Monsters [set Money Money + 2                               ;;; each Monster's turn starts with collecting two coins from the bank
                use_hand
                Calculate_Total_Attributes
                draw_hand]
  tick
end

to use_hand
  foreach Hand [[i] ->                                            ;;; The Monster looks through their hand and applies all instant apply cards
    if item 0 i = "boost" [ set Boost item 1 i                    ;;; Boosts are instant apply cards, so the monster applies any Boost cards
                            if Garrulous? [print Boost]
                               set Attack Attack + item 2 i
                               set Cute Cute + item 3 i
                               set Defence Defence + item 4 i
                               set Fear Fear + item 5 i
                               set Intelligence Intelligence + item 6 i
                               set Speed Speed + item 7 i
                               set Hand remove i Hand]
    if item 0 i = "action" [if Garrulous? [print i]]              ;;; Actions require decision making, so currently the instant apply here is only to say that there is an action
    if item 0 i = "mission" [if Garrulous? [print i]
                             set My_Mission i
                             Decide_on_Mission
                             ifelse member? 0 Decision [set My_Mission [] ]
                                                       [Attempt_Mission
                                                        set Hand remove i Hand ] ]
    if item 0 i = "body_part" [if Garrulous? [print i]
                               if Money >= item 9 i [
                                    set Part_to_Purchase Body_Parts with [(From_What_Animal = item 1 i) and (Body_Position = item 2 i)]
                                    print (word "I can purchase " Part_to_Purchase )
                                    acquire-upgrade-parts]
                                    set Hand remove i Hand]
    if item 0 i = "goal" [if Garrulous? [print i]]
  ]
end

to Decide_on_Mission
  set Decision []
  set Mission_Attribute_Successes 0
  set Mission_Money_Reward 0
  set Mission_Points_Reward 0
  set My_Mission but-first My_Mission
  set My_Mission but-last My_Mission
  set Mission_name first My_Mission
  set My_Mission but-first My_Mission
  set Mission_Points_Reward last My_Mission
  set My_Mission but-last My_Mission
  set Mission_Money_Reward last My_Mission
  set My_Mission but-last My_Mission
  set Shaft_Share random 1

if item 0 My_Mission > 0 [ifelse item 0 My_Mission > Total_Attack  [set Decision fput 0 Decision ][set Decision fput 1 Decision ]]
if item 1 My_Mission > 0 [ifelse item 1 My_Mission > Total_Cute    [set Decision fput 0 Decision ][set Decision fput 1 Decision ]]
if item 2 My_Mission > 0 [ifelse item 2 My_Mission > Total_Defence    [set Decision fput 0 Decision ][set Decision fput 1 Decision ]]
if item 3 My_Mission > 0 [ifelse item 3 My_Mission > Total_Fear    [set Decision fput 0 Decision ][set Decision fput 1 Decision ]]
if item 4 My_Mission > 0 [ifelse item 4 My_Mission > Total_Intelligence    [set Decision fput 0 Decision ][set Decision fput 1 Decision ]]
if item 5 My_Mission > 0 [ifelse item 5 My_Mission > Total_Speed    [set Decision fput 0 Decision ][set Decision fput 1 Decision ]]

  if Garrulous? [  ifelse member? 0 Decision [print (word Name " considered the " Mission_name " mission, but would have to cooperate so decided against.")]
                                             [print (word Name " decided to go for the " Mission_name " mission, which needs "
                                                       length Decision " attribute(s) and is worth " Mission_Money_Reward " money and "
                                                       Mission_Points_Reward " points." )]]
end

to Attempt_Mission

  if item 0 My_Mission > 0 [   if Garrulous? [  print (word "Now, I need to roll for attack.") ] roll-dice Total_Attack  item 0 My_Mission ]
  if item 1 My_Mission > 0 [   if Garrulous? [  print (word "Now, I need to roll for cute.") ] roll-dice Total_Cute item 1 My_Mission]
  if item 2 My_Mission > 0 [  if Garrulous? [  print (word "Now, I need to roll for defense.") ] roll-dice Total_Defence item 2 My_Mission]
  if item 3 My_Mission > 0 [   if Garrulous? [  print (word "Now, I need fear.") ] roll-dice Total_Fear item 3 My_Mission]
  if item 4 My_Mission > 0 [   if Garrulous? [  print (word "Now, I need intelligence.") ] roll-dice Total_Intelligence item 4 My_Mission]
  if item 5 My_Mission > 0 [  if Garrulous? [  print (word "Now, I need speed.") ] roll-dice Total_Speed item 5 My_Mission]
  ifelse Mission_Attribute_Successes = length Decision
    [ set Money Money + Mission_Money_Reward
      set Points Points + Mission_Points_Reward
      if Garrulous? [print "Succeeded on all attributes and so succeeded on the mission."]]
    [print "Failed on at least one attribute and so failed on the mission."]
  ;; Need to add cooperative mission aspect at some point
end

to roll-dice [dice_to_roll bar_to_pass]
  if Garrulous? [
    ifelse dice_to_roll < bar_to_pass
    [print (word "I need cooperate because I need at least " bar_to_pass " blues for this attribute, but I only have " dice_to_roll " dice to roll.")]
    [print (word "Rolling " dice_to_roll " dice in order to get at least " bar_to_pass " blues to complete this attribute test for this mission.") ] ]

  set Total_Successes_Dice_Roll 0
  set Total_Doubles_Dice_Roll 0

  repeat dice_to_roll
  [let temp-number random 6
    if temp-number < 3 [set Total_Successes_Dice_Roll Total_Successes_Dice_Roll + 1
      if Garrulous? [print "Got a blue!"]]
    if (temp-number = 3) or (temp-number = 4) [ if Garrulous? [print "Got a red!"] ]
    if temp-number = 5 [set Total_Doubles_Dice_Roll Total_Doubles_Dice_Roll + 1 if Garrulous? [print "Got a yellow!"] ] ]

  if (Total_Successes_Dice_Roll > 0) and (Total_Doubles_Dice_Roll > 0)
  [ set temp_doubling_list []
    set temp_doubling_list fput Total_Successes_Dice_Roll temp_doubling_list
    set temp_doubling_list fput Total_Doubles_Dice_Roll temp_doubling_list
    set temp_doubling_list sort temp_doubling_list
    set Total_Successes_Dice_Roll Total_Successes_Dice_Roll + first temp_doubling_list]

  print (word "Including doubles, I got " Total_Successes_Dice_Roll " blues, and I needed " bar_to_pass " so..." )
  ifelse Total_Successes_Dice_Roll >= bar_to_pass
    [ set Mission_Attribute_Successes Mission_Attribute_Successes + 1 print "I succeded on this attribute!"]
    [print "Failed on this attribute."]
end

to cooperate
  ; find other monster with attributes > attributes needed for this mission and ask to cooperate
  ; if yes, both monsters choose "shaft or share"
  ; other monster rolls dice
  ; if mission succeeds, both monsters reveal their "shaft or share"
  ; if both mosters have share, share
  ; if one monster has shaft and other has share, monster with shaft takes all prizes
  ; if both monsters have shaft, no prizes awarded
end

to acquire-upgrade-parts
      ask one-of Part_to_Purchase [
      set hidden? False
      set Theoretical? False
      set Name [Name] of myself
      set color [color] of myself
      move-to myself
      if Body_Position =  "head" [set ycor ycor - 2]
      if Body_Position = "trunk" [set ycor ycor - 3]
      if Body_Position = "legs"  [set ycor ycor - 4]
      if Body_Position = "left_arm" [set xcor xcor - 1 set ycor ycor - 3]
      if Body_Position = "right_arm" [set xcor xcor + 1 set ycor ycor - 3]
      ask myself [set Money Money - [Cost] of one-of Part_to_Purchase]
      print (word Name " purchased a " From_What_Animal " " Body_Position " for " Cost)
      let old-part one-of other turtles-here
      if old-part != nobody [ ask old-part [ set Name ""
                                             set hidden? True
                                             set Theoretical? True
      setxy 0 0 ] ] ]
end


to Calculate_Total_Attributes
  ask Monsters [
    set Total_Attack sum [Attack] of turtles with [(Name = [Name] of myself) and (Theoretical? = False)]
    set Total_Defence sum [Defence] of turtles with [(Name = [Name] of myself) and (Theoretical? = False)]
    set Total_Cute sum [Cute] of turtles with [(Name = [Name] of myself) and (Theoretical? = False)]
    set Total_Fear sum [Fear] of turtles with [(Name = [Name] of myself) and (Theoretical? = False)]
    set Total_Intelligence sum [Intelligence] of turtles with [(Name = [Name] of myself) and (Theoretical? = False)]
    set Total_Speed sum [Speed] of turtles with [(Name = [Name] of myself) and (Theoretical? = False)]

;    if Garrulous? [  print Name
;      if Total_Attack > 0 [print "Total Attack" print Total_Attack]
;      if Total_Cute > 0 [print "Total Cute" print Total_Cute]
;      if Total_Defence > 0 [print "Total Defence" print Total_Defence]
;      if Total_Fear > 0 [print "Total Fear" print Total_Fear]
;      if Total_Intelligence > 0 [print "Total Intelligence" print Total_Intelligence]
;      if Total_Speed > 0 [print "Total Speed" print Total_Speed]  ]
  ]
end

to draw_hand
  while [length Hand < 5] [                                       ;;; The monsters continue to draw cards until they have 5 cards each in their Hand
    let temp_Hand first Cards_list                                ;;; "pick up the top card from the draw pile"
    set Hand fput temp_Hand Hand                                  ;;; "put that picked up card in the monster's Hand"
    set Cards_list butfirst Cards_list]                           ;;; set the draw pile to be the draw pile minus the card that was just "picked up"
  set label length Hand
end


; Copyright 2020 Dr. J. Kasmire
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
298
10
726
439
-1
-1
12.0
1
8
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
210
75
273
108
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
40
75
106
108
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
41
37
231
70
Number_Players
Number_Players
3
6
5.0
1
1
NIL
HORIZONTAL

SWITCH
45
125
157
158
Garrulous?
Garrulous?
0
1
-1000

BUTTON
125
75
188
108
NIL
Go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## ACKNOWLEDGMENT


## WHAT IS IT?


## HOW IT WORKS


## HOW TO USE IT


## THINGS TO NOTICE


## THINGS TO TRY

## EXTENDING THE MODEL


## NETLOGO FEATURES


## RELATED MODELS

## CREDITS AND REFERENCES

This model is adapted from:


This model is inspired by:


## HOW TO CITE

For the model itself:

* Rand, W., Wilensky, U. (2007).  NetLogo El Farol model.  http://ccl.northwestern.edu/netlogo/models/ElFarol.  Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.


## COPYRIGHT AND LICENSE

Copyright 2020 Dr. J. Kasmire

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

campsite
false
0
Polygon -7500403 true true 150 11 30 221 270 221
Polygon -16777216 true false 151 90 92 221 212 221
Line -7500403 true 150 30 150 225

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

cat
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

fish 3
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1184463 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

footprint other
true
0
Polygon -7500403 true true 75 195 90 240 135 270 165 270 195 255 225 195 225 180 195 165 177 154 167 139 150 135 132 138 124 151 105 165 76 172
Polygon -7500403 true true 250 136 225 165 210 135 210 120 227 100 241 99
Polygon -7500403 true true 75 135 90 135 105 120 105 75 90 75 60 105
Polygon -7500403 true true 120 122 155 121 161 62 148 40 136 40 118 70
Polygon -7500403 true true 176 126 200 121 206 89 198 61 186 57 166 106
Polygon -7500403 true true 93 69 103 68 102 50
Polygon -7500403 true true 146 34 136 33 137 15
Polygon -7500403 true true 198 55 188 52 189 34
Polygon -7500403 true true 238 92 228 94 229 76

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rabbit
false
0
Polygon -7500403 true true 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -7500403 true true 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -7500403 true true 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -7500403 true true 49 89 57 47 78 4 89 20 70 88
Circle -16777216 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -5825686 true false 0 150 15 165 15 150
Polygon -5825686 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

spider
true
0
Polygon -7500403 true true 134 255 104 240 96 210 98 196 114 171 134 150 119 135 119 120 134 105 164 105 179 120 179 135 164 150 185 173 199 195 203 210 194 240 164 255
Line -7500403 true 167 109 170 90
Line -7500403 true 170 91 156 88
Line -7500403 true 130 91 144 88
Line -7500403 true 133 109 130 90
Polygon -7500403 true true 167 117 207 102 216 71 227 27 227 72 212 117 167 132
Polygon -7500403 true true 164 210 158 194 195 195 225 210 195 285 240 210 210 180 164 180
Polygon -7500403 true true 136 210 142 194 105 195 75 210 105 285 60 210 90 180 136 180
Polygon -7500403 true true 133 117 93 102 84 71 73 27 73 72 88 117 133 132
Polygon -7500403 true true 163 140 214 129 234 114 255 74 242 126 216 143 164 152
Polygon -7500403 true true 161 183 203 167 239 180 268 239 249 171 202 153 163 162
Polygon -7500403 true true 137 140 86 129 66 114 45 74 58 126 84 143 136 152
Polygon -7500403 true true 139 183 97 167 61 180 32 239 51 171 98 153 137 162

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tortoise
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
