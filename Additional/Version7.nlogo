;; ants exist as abstraction. The bigger a colony is, the more foragers it has. Each forager will collect food individually.
;; the process of collecting food is abstract (the ant won't actually move)
;; this was done this way, as opposed to the colony having n attempts to collect food, to ensure that colonies act at the same time (as opposed to one colony collecting all food before others get a chance)

globals
[
  component-number ;; might change into gui-controlled variable, instead of hardcoded.
  ants-killed
]


breed [ants ant]
ants-own [
  mother ; colony controller ant belongs to
  distance-to-colony
  profile ; chemical profile (array of numbers)
]

breed [colony-controllers colony-controller]
colony-controllers-own [
  number-of-ants
  amount-of-food

  profile ; "average" profile of all ants (technically the template from which the individual ant's profile is derived)
  tolerance ; modifies perceived distance to any other ant-colonies.

  steal-weight
  stole
  got-stolen
]

breed [food-sources food-source]

to setup
  clear-all
  reset-ticks
  set-default-shape turtles "bug"

  ;; set global variables / parameters to well tested values, as to not overcrowd the GUI with unused options.
  set component-number 10

  birth-new-colony-controllers colony-count
end

to go
  tick
  ask food-sources [die] ;; kill all remaining food-sources to prevent overflowing (simulates food not collected by ants being collected by other animals)
  ask colony-controllers [
    set amount-of-food amount-of-food - 1 * (sum profile * profile-cost / 1000)

    if amount-of-food <= 0 and (selection = true)
    [
      kill-colony
      set ants-killed ants-killed + 1
    ]
  ]

  create-food-sources food-number [
    set shape "circle"
    ;; set xcor random-pxcor ;; coordinates aren't used in the current model, but don't realle affect runtime either
    ;;set ycor random-pycor
    set size 0 ] ;; set size to 0, so the simulation doesn't look like a disco with all the food-sources flashing


  if ticks mod generation-interval = 0 [start-new-generation]

  ask ants [forage]

end


to birth-new-colony-controllers [n]
  create-colony-controllers n[
    set xcor random-pxcor
    set ycor random-pycor
    set profile (list)

    ifelse startprofile-random
      [repeat component-number [set profile lput (random-exponential 10) profile]]
      [repeat component-number [set profile lput (1) profile]]


    set tolerance random-float 0.8 + 0.6

    set amount-of-food 25
    set stole 0
    set got-stolen 0
    set steal-weight 100

    birth-ants 10
  ]
end

to birth-evolved-colony-controllers [n]
  hatch-colony-controllers n [
    set xcor random-pxcor
    set ycor random-pycor

    set profile (evolve-profile evolvability)
    set tolerance random-float 0.8 + 0.6

    set amount-of-food 25
    set stole 0
    set got-stolen 0
    set steal-weight 100

    birth-ants 10
  ]
end

to birth-ants [n]
  hatch-ants n [
    set mother myself
    set profile evolve-profile (evolvability / 10)
    set distance-to-colony chemical-distance profile [profile] of mother
  ]
end


to forage
  let target nobody ; initialize target
  set target one-of turtles with [breed != ants and (self != [mother] of myself)] ; set target. colonies and food sources have same weight

  if target = nobody [show "error, no foraging target possible" stop] ; if there is no possible target, stop. This is unlikely to happen and only for error-catching


  if [breed] of target = colony-controllers ; case differentiation
  [steal-food target stop] ; steal food when the target is a colony
  collect-food target ; simply pick it up when it is a food-source
end

; lets an ant collect food from a food-source. Food-source is destroyed in the process
to collect-food [target]
  ask target [die]
  bring-back-food
end


; lets an ant steal food from another colony
to steal-food [target]
  if stealing-succesfull(target) ;; was the attempt to steal food succesfull?

  ;; if yes, reduce the targeted colonies food-amount and increase the own colony's
  [
    ask target [
      set amount-of-food amount-of-food - 1
      set got-stolen got-stolen + 1

      ; if the targeted colony has no food, remove it
      if amount-of-food <= 0  and (selection = true) [
        kill-colony
      ]


    ]
    bring-back-food
    ask mother [
      set stole stole + 1
    ]
  ]
end

;; calculate a stealing-probability derived from the chemical distance between this ant's and the the target-colony's CHC-profile and compare with a random float
to-report stealing-succesfull [target]
  if random-float 1 < (chemical-distance profile [profile] of target)  * ([tolerance] of target)
    [report false]
  report true
end

to bring-back-food
  if selfrec[
    if stealing-succesfull mother [
      ask mother [set amount-of-food amount-of-food + 1]
    ]
  ]
  if not selfrec [
     ask mother [set amount-of-food amount-of-food + 1]
  ]
end

;; calculate a chemical dissimilarity between two chemical profiles (given as list)
to-report chemical-distance [A B]
  ;; Bray-Curtis
  if recognition-mode = "gestalt" [
    let top 0
    let bottom 0
    let counter 0
    repeat length A [
      set top top + min (list item counter A item counter B)
      set bottom bottom + item counter A + item counter B
      set counter counter + 1
    ]
    report 1 - (2 * top / bottom)
  ]

  ;; Bray curtis, but when the stealing ant (A) has more of a component, this component is treaded
  ;; as if it is the same as of the victim colony (B), since it is "present"
  if recognition-mode = "desirable-present" [
    let top 0
    let bottom 0
    let counter 0
    repeat length A [
      ifelse item counter A > item counter B[
        set top top + item counter A
        set bottom bottom + 2 * item counter A
      ][
        set top top + min (list item counter A item counter B)
        set bottom bottom + item counter A + item counter B
      ]
      set counter counter + 1
    ]
    report 1 - (2 * top / bottom)
  ]

  ;; vice versa from the "desirable-present": when the thieving ant has less of a component, it is treaded the same
  ;; as in the victim B, since it is not present
  if recognition-mode = "undesirable-absent" [
    let top 0
    let bottom 0
    let counter 0
    repeat length A [
      ifelse item counter A < item counter B[
        set top top + item counter A
        set bottom bottom + 2 * item counter A
      ][
        set top top + min (list item counter A item counter B)
        set bottom bottom + item counter A + item counter B
      ]
      set counter counter + 1
    ]
    if bottom = 0 [set bottom 0.001 show "0 profile"]
    report 1 - (2 * top / bottom)
  ]
end


; removes a colony-controller and its ants
to kill-colony
  ask ants with [mother = myself][die]
  die
end

; getter for the profile to shorten other funcitons
to-report my-profile
  report [profile] of mother
end



to-report evolve-profile [var]
  let newprof (list)
  let temp 0
  let counter 0

  ifelse mating and not [breed]of self = ants [
    set newprof (mate profile [profile]of one-of other colony-controllers)]
  [
    repeat length profile [
      set temp item counter profile + random-normal 0 var
      if temp < 0 [set temp 0]

      set newprof lput temp newprof
      set counter counter + 1
    ]
  ]
  report newprof
end


to-report mate [A B]
  let C (list)
  let temp 0
  let counter 0

  repeat length A [
    set temp one-of list (item counter A) (item counter B) + random-normal 0 evolvability

    set temp temp + random-normal 0 evolvability
    if temp < 0 [set temp 0]


    set C lput temp C
  ]
  report C
end

to start-new-generation
  ;; if there is not supposed to be selection, set the amount of food of all colonies to the same values, so colonies will be treated equally.
  if not selection [ask colony-controllers [set amount-of-food 25]]


  let sorted-food-numbers sort [amount-of-food] of colony-controllers

  ;; calculate how many colonies need to be killed to have an x% selection per generation. Lower this number if some colonies already died during the interval
  let n-to-kill (selection-proportion * colony-count) - (colony-count - count colony-controllers)
  if n-to-kill < 0 [set n-to-kill 0]

  ;; take the (n-to-kill) colonies with the least amount of food (item (n-to-kill) sorted-food-numbers is the highest amount of food of any of them) and remove them
  ask n-of (n-to-kill) colony-controllers with [amount-of-food <= item (n-to-kill) sorted-food-numbers]  [
    kill-colony
  ]


  let sum-food sum [amount-of-food] of colony-controllers
  let n-new-colonies (colony-count - count colony-controllers) ;; count colony-controllers <- how the number of colonies currently is; colony-count <- how the number of colonies should be


  ;; surviving colony creates offspring
  ;; according to the proportion of their collected food compared to the total food compared
  ask colony-controllers [
    let numb round (amount-of-food / sum-food * n-new-colonies)
    birth-evolved-colony-controllers numb
 ;   show numb
  ]


  ; due to number rounding or more colonies dying during an interval than specified as selection-proportion, there might now be more or less than the amount of colonies wished. In this case, we will kill excess colonies or let the biggest colony fill the gaps.
  while [count colony-controllers < colony-count] [
    ask one-of colony-controllers with [amount-of-food = max sorted-food-numbers][
      birth-evolved-colony-controllers 1
    ]
  ]

  while [count colony-controllers > colony-count] [
    ask one-of colony-controllers with [amount-of-food = min [amount-of-food] of colony-controllers][
      kill-colony
    ]
  ]

  ask colony-controllers [set amount-of-food 25]
end


;; chemical distance (according to the current recognition mode)  between colonies
to-report meanchemdistreporter
  let temp  0
  ask colony-controllers [
  set temp temp + mean [chemical-distance profile [profile] of myself] of other colony-controllers
  ]
  report temp / count colony-controllers
end


;; mean chemical distance between ants in a colony
to-report intracol-variance
  let meanchemdist -1
  ask one-of ants with [mother = myself] [
  set meanchemdist mean [truebray profile [profile] of myself] of other ants with [mother = [mother] of myself]
  ]
  report (meanchemdist)
end


;; mean chemical distance as bray curtis dissimilarity between colonies
to-report mean-chemical-difference
  let temp  0
  ask colony-controllers [
    set temp temp + chemical-difference-to-others
  ]
  report temp / count colony-controllers
end


;; mean chemical distance as bray curtis dissimilarity between colonies
to-report chemical-difference-to-others
  let temp  0
  set temp mean [truebray profile [profile] of myself] of other colony-controllers
  report temp
end


;; bray curtis dissimilarity
to-report truebray [A B]
  let top 0
  let bottom 0
  let counter 0
  repeat length A [
    set top top + min (list item counter A item counter B)
    set bottom bottom + item counter A + item counter B
    set counter counter + 1
  ]
  report 1 - (2 * top / bottom)
end


to-report measurestuff
  let temp (list startprofile-random selection mating profile-cost  ticks evolvability food-number)
  if ticks mod 100 = 0 [report temp]
  report "X"
end


to-report measurestuff2
  if ticks mod generation-interval = generation-interval - 1 [
    let foodsorted sort [amount-of-food] of colony-controllers

    let minsuccess  [chemical-difference-to-others] of one-of colony-controllers with [amount-of-food = min foodsorted] ;; mean bray curtis dissimilarity of least successfull colony to others
    let maxsuccess [chemical-difference-to-others] of one-of colony-controllers with [amount-of-food = max foodsorted] ;; "" of most succesfull
    let randomsuccess  [chemical-difference-to-others] of one-of colony-controllers ;; "" of a random colony
    let maxdist max [chemical-difference-to-others] of colony-controllers ;; "" of the most distant colony
    let mindist min [chemical-difference-to-others] of colony-controllers ;; "" of the least distant colony

    let abundance (mean [sum profile] of colony-controllers)
    let meanintracolvar mean [intracol-variance] of colony-controllers

    let temp (list startprofile-random selection mating recognition-mode profile-cost selection-proportion food-number evolvability ticks meanchemdistreporter minsuccess maxsuccess randomsuccess maxdist mindist mean-chemical-difference abundance meanintracolvar selfrec ants-killed)
    report temp
  ]
  report "X"
end
@#$#@#$#@
GRAPHICS-WINDOW
328
10
765
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
59
37
126
70
NIL
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

BUTTON
60
77
123
110
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
8
171
163
231
colony-count
50.0
1
0
Number

SWITCH
9
342
194
375
startprofile-random
startprofile-random
0
1
-1000

SWITCH
10
426
124
459
selection
selection
1
1
-1000

INPUTBOX
8
110
163
170
generation-interval
100.0
1
0
Number

INPUTBOX
8
233
163
293
evolvability
1.0
1
0
Number

INPUTBOX
167
111
322
171
food-number
300.0
1
0
Number

SWITCH
11
462
114
495
mating
mating
1
1
-1000

CHOOSER
9
378
183
423
recognition-mode
recognition-mode
"gestalt" "desirable-present" "undesirable-absent"
0

INPUTBOX
167
172
322
232
selection-proportion
0.4
1
0
Number

INPUTBOX
167
234
322
294
profile-cost
30.0
1
0
Number

SWITCH
202
440
305
473
selfrec
selfrec
0
1
-1000

@#$#@#$#@
# Variables
## generation-interval
Standard set to 100. The time frame in which colonies forage for food. After each generation-interval, colonies die and new ones get born. The food of colonies gets reset, so all colonies have the same chances. To low values (< 20) lead to bad results, because there is no time for evolutionary pressure to work.
## food-number
The number of food sources available. Has no strong effect, but high numbers weaken the results.
## colony-count
The number of colonies that can be alive at the same time. Higher number improve results (variance and strength), but lead to higher runtime. Try keeping below 100.
## selection-proportion
Standard set to 0.4. The proportion of colonies that are killed after each generation-interval. Higher values can lead to stronger results, but also lead to a founder effect.
## evolvability
Standard set to 5. When a colony births a new one, all profile components get a random-normal number added (or subtracted) with "evolvability" being the sd of the normal-distribution. Higher values lead to stronger results but with higher variance.
## profile-cost
The number that controlls the cost of profiles. The actual cost is calculated as thousands of fraction of the abundance (total CHC-amount) of the profile, as in a profile-cost of 100 would lead to a cost of abundance * 100 / 1000 = cost of abundance / 10.

## startprofile-random
Standard set to true. If true, all colonies start with a random profile. If false, all colonies start with the same profile.
## recognition-mode
- "gestalt": Ants consider the bray-curtis distance between their own and their targets profile as the chemical difference
- "desirable-present": Ants consider the bray curtis distance, but all components the target has more than in the own profile is considered to be the same in both.
- "undesirable-absent": similar to "desirable-present", but instead they consider components that are less in the target's profile than the own to be the same in both.
## selection
Always test true and false. Important to create a control-group. If true, then colonies can die during the experiment and only the most successfull ones create offspring. If false, then colonies don't die by food shortage and random ones are chosen to die or create offspring each interval. 
## mating
Standard set to false. If true, then when a colony is created, it choses a random other one as mate. The offspring created will for each component chose randomly between both parent's version. After this, the profile will be further evolved by adding random-normal numbers. If false, then offspring inherits the single parent's profile which then gets mutated.
## selfrec
Standard set to true. If true, the profile of ants bringing back food is compared to the colonies template and only if it similar will the food be accepted. Otherwise, the food won't be acceptet, but the ant can forage again in the next time step. This simulates the need to recognize nestmates. If false, food brought back by an ant is always accepted, meaning that nestmates are always recognized as such. Variable has only a weak effect.

# Changelog
### Version 1
- Built a framework that lets colonies collect and steal food. Colonies have random profiles and success to steal depends on profile-similarity.
### Version 2 
- Added differing tolerances
### Version 3 
- Added Evolutin. Evolution by adding random value in interval [-x, x].
- Added the option to have all colonies start with the same profile
### Version 4 
- Changed Profiles from random between 0 to 1 to exponential-distributed with lambda 10 and evolution by adding normal-distributed values.
- Added option to have colonies mate: instead of newborn colony inheriting its parents profile and modifying it, it gets a profile with components randomly taken from its parent and a random other colony (and then modifies this). This might solve the founder-effect that leads to colonies quickly having a single ancestor.
### Version 5
- Removed ability to learn, since it wasn't used
- re-added the ability for colonies to die when their collected food reaches zero
- added a food-consumption per tick. Rate is set so there is always exactly the amount of food needed for all colonies to survive
- Added an option to chose the proportion of colonies that die each generation
- Surviving colonies will create a number of offspring proportional to their amount of collected food relative to the total amount of food of living colonies
- Added two additional models for recognition: "desirable present" and "undesirable absent"
### Version 6
- Added a cost to total profile abundance
- Added individual profiles to colonies. When bringing back food, the profile of ants is compared to the colonies profile the same way as when they steal, and only if they are considered a friend is the food brought back (otherwise it is discarded but the ant can keep foraging in the next time step).
- record the intra-colonial variance
### Version 6b
- fixed a bug where for the main measurement, where always the mean chemical distance between all colonies was reported where the mean chemical distance of one colony to the others was asked
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

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="ExperimentMain" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>measurestuff2</metric>
    <enumeratedValueSet variable="recognition-mode">
      <value value="&quot;gestalt&quot;"/>
      <value value="&quot;desirable-present&quot;"/>
      <value value="&quot;undesirable-absent&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generation-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection-proportion">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Evolvability">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-count">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startprofile-random">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mating">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-cost">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfrec">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ExperimentFoodCostExp" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>measurestuff2</metric>
    <enumeratedValueSet variable="recognition-mode">
      <value value="&quot;gestalt&quot;"/>
      <value value="&quot;desirable-present&quot;"/>
      <value value="&quot;undesirable-absent&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generation-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection-proportion">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Evolvability">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-count">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startprofile-random">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mating">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-cost">
      <value value="20"/>
      <value value="40"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfrec">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ExperimentSelectionExp" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>measurestuff2</metric>
    <enumeratedValueSet variable="recognition-mode">
      <value value="&quot;gestalt&quot;"/>
      <value value="&quot;desirable-present&quot;"/>
      <value value="&quot;undesirable-absent&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generation-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection-proportion">
      <value value="0.1"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Evolvability">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-count">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startprofile-random">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mating">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-cost">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfrec">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ExperimentEvolvExp" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>measurestuff2</metric>
    <enumeratedValueSet variable="recognition-mode">
      <value value="&quot;gestalt&quot;"/>
      <value value="&quot;desirable-present&quot;"/>
      <value value="&quot;undesirable-absent&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generation-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection-proportion">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Evolvability">
      <value value="1"/>
      <value value="5"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-count">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startprofile-random">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mating">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-cost">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfrec">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ExperimentFoodCostControl" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>measurestuff2</metric>
    <enumeratedValueSet variable="recognition-mode">
      <value value="&quot;gestalt&quot;"/>
      <value value="&quot;desirable-present&quot;"/>
      <value value="&quot;undesirable-absent&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generation-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection-proportion">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Evolvability">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-count">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startprofile-random">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mating">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-cost">
      <value value="20"/>
      <value value="40"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfrec">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ExperimentSelectionControl" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>measurestuff2</metric>
    <enumeratedValueSet variable="recognition-mode">
      <value value="&quot;gestalt&quot;"/>
      <value value="&quot;desirable-present&quot;"/>
      <value value="&quot;undesirable-absent&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generation-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection-proportion">
      <value value="0.1"/>
      <value value="0.4"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Evolvability">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-count">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startprofile-random">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mating">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-cost">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfrec">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ExperimentEvolvControl" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>measurestuff2</metric>
    <enumeratedValueSet variable="recognition-mode">
      <value value="&quot;gestalt&quot;"/>
      <value value="&quot;desirable-present&quot;"/>
      <value value="&quot;undesirable-absent&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generation-interval">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection-proportion">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Evolvability">
      <value value="1"/>
      <value value="5"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="colony-count">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startprofile-random">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mating">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selection">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="profile-cost">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="selfrec">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
0
@#$#@#$#@
