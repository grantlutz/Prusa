; =====================================================================
;  Nozzle Wiper test  -  Prusa CORE One+ (Gen 1 frame, Gen 2 wiper)
;  Firmware: 6.8.1 Buddy
;  Requires: Settings -> Hardware -> Nozzle Wiper = ON
;
;  G12 is the firmware wipe routine added in FW 6.8.1. It uses
;  coordinates baked into the firmware, so the Nozzle Wiper toggle
;  must be ON and the wiper must sit in the stock Gen 2 position.
;
;  FIRST RUN: keep an eye on it and be ready to hit Reset.
;  To dry-run cold, comment out the two M104/M109 lines below.
; =====================================================================

M73 P0                    ; progress 0%
M107                      ; part fan off
G90                       ; absolute XYZ
M83                       ; relative E

M17                       ; enable steppers
G28                       ; home all axes

; --- soften any residue on the nozzle (stock cleaning temp) ---
M104 S170                 ; start heating hotend
M109 R170                 ; wait for 170 C (waits on heat-up and cool-down)

M73 P25
M117 Wiping nozzle...

G12                       ; >>> firmware nozzle wipe <<<

; --- optional second pass: uncomment if one wipe is not enough ---
;G4 S1
;G12

M73 P75
M117 Wipe done

; --- park and shut down ---
M104 S0                   ; hotend off
M140 S0                   ; bed off
M107                      ; fans off
G0 X125 Y100 F6000        ; move head to a clear spot
G0 Z50 F1000              ; drop bed away from the nozzle

M300 S880 P200            ; beep
M73 P100
M84                       ; disable steppers
