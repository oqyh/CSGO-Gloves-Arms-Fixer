# [CSGO] Gloves Arms Fixer (1.0.2)
https://forums.alliedmods.net/showthread.php?t=343329

### Fix Gloves Arms For Custom Models Compatibility With Gloves Plugin

![gif1](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/52541686-dd97-44c8-ae90-88f9e6c0c9b7)
![gif2](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/a6f5a1b8-216e-421f-9dbd-75f776633bd4)


![beforer](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/d3bc8aba-b052-435e-b2cf-7a4f1c52b4b8)  ![afterr](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/35c881b5-2683-4197-addd-ba22ee496953)

## .:[ installation ]:.
```
Remove any arm fixes
VVVVVVV
csgo\addons\sourcemod\plugins\n_arms_fix.smx
csgo\addons\sourcemod\extensions\ArmsFix.autoload
csgo\addons\sourcemod\extensions\ArmsFix.ext.2.csgo.so

then Drop Gloves Arms Fixer files in ../csgo/
restart server 
```

## .:[ ConVars ]:.
```
// Gloves Arms Fixer?
// 1= Enable 
// 0= Disable
agf_enable_plugin "1"

// How would you like to fix the arms / gloves method 
// 1= Timer (every agf_delay_fixer x Secs do fix) 
// 2= On Respawn (do fix after agf_delay_fixer x Secs 1 time Every Respawn)
agf_mode "1"

// (in Secs) Timer delay to make fix arms / gloves, make it higher if there is apply skins delay (need restart server to set new timer)
agf_delay_fixer "4.0"

// Force remove gloves?
// 1= yes(custom arms override gloves.smx plugin) 
// 0= no(gloves.smx override custom arms except default gloves)
agf_force_remove "0"

//==========================================================================================

// Make toggle invisible arms / gloves?
// 3= yes ( specific steamids agf_steamid_list_path ) need restart server
// 2= yes ( specific flags agf_flags )
// 1= yes ( everyone can toggle on/off )
// 0= no (disable toggle on/off )
agf_enable_toggle "0"

// [if agf_enable_toggle 2] which flags is it
agf_flags "abcdefghijklmnoz"

// [if agf_enable_toggle 3] where is list steamid located in addons/sourcemod/
agf_steamid_list_path "configs/viplist.txt"

// [if agf_enable_toggle 1 or 2 or 3] which commands would you like to make it  toggle on/off hide arms / gloves (need restart server)
agf_cmd "sm_hidearms;sm_hidearm;sm_ha"

//==========================================================================================

// Enable checker timer to check access 
// 1= yes(to avoid stuck client on viplist do check every agf_check_timer x Secs) 
// 0= no
agf_check_access "0"

// [if agf_check_access 1] (in Secs) Timer to check clients
agf_check_timer "5.0"
```

## .:[ FAQ ]:.
```
-Why i see stretch gloves? (Example: https://github.com/oqyh/CSGO-Gloves-Arms-Fixer/assets/48490385/e4d83c7b-4880-4e3d-9cc1-7e1ce0026f58)

if you using gloves.smx make convar sm_gloves_enable_world_model "1" to "0"
then restart server
```

## .:[ Change Log ]:.
```
(1.0.2)
 -Combine two plugins works with/without gloves.smx
 -Fix agf_force_remove
 -Added two mode agf_mode 1-real time fix 2-every respawn
 -Added agf_enable_toggle toggle visible/invisible arms gloves (Requested)
 -Added agf_flags flags to access visible/invisible gloves if agf_enable_toggle 2
 -Added agf_steamid_list_path to access visible/invisible gloves if agf_enable_toggle 3
 -Added agf_cmd custom commands toggle visible/invisible gloves
 -Added agf_check_access to check access if client or server change agf_enable_toggle
 -Added agf_check_timer timer for agf_check_access to check all clients

(1.0.1)
=Gloves-Arm-Fixer(With Gloves Plugin).smx
 -Fix convar agf_force_remove 
 -Better Detect Custom models
 -Plugin no longer removing if client not using gloves.smx and have his own gloves
 -Plugin no longer removing if client has his own gloves and not using custom models and gloves.smx
 -Fix client on bot arms/gloves or custom or not

=Gloves-Arm-Fixer(Without Gloves Plugin).smx
 -Remove include <gloves>
 -Better Detect Custom models
 -Plugin no longer removing if client has his own gloves and not using custom models
 -Fix client on bot arms/gloves or custom or not

(1.0.0)
- Initial Release
```

## .:[ Donation ]:.

If this project help you reduce time to develop, you can give me a cup of coffee :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/oQYh)
