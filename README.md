# [CSGO] Arm Gloves Fixer (1.0.1)
https://forums.alliedmods.net/showthread.php?t=343329

### Fix Gloves Arms For Custom Models With/Without Gloves Plugin

![gif1](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/52541686-dd97-44c8-ae90-88f9e6c0c9b7)
![gif2](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/a6f5a1b8-216e-421f-9dbd-75f776633bd4)

![before1](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/d381789c-ee38-45cf-9f59-c690473f96b7)
![after1](https://github.com/oqyh/CSGO-Arm-Gloves-Fixer/assets/48490385/665d0e65-8970-4f3a-b553-a0f187f11103)


## .:[ ConVars ]:.
```
=========================================================
Gloves-Arm-Fixer(With Gloves Plugin).smx
=========================================================
// Arm Gloves Fixer(With Gloves Plugin)?
// 1= Enable 
// 0= Disable
agf_enable_plugin "1"


// Force remove gloves plugin on custom arms?
// 1= yes 
// 0= no
agf_force_remove "0"


// Timer delay to make fix arm/gloves, make it higher if there is apply skins delay
agf_delay_fixer "4.0"



=========================================================
Gloves-Arm-Fixer(Without Gloves Plugin).smx
=========================================================
// Arm Gloves Fixer?
// 1= Enable 
// 0= Disable
agf2_enable_plugin "1"

// Timer delay to make fix arm/gloves, make it higher if there is apply skins delay
agf2_delay_fixer "4.0"
```

## .:[ FAQ ]:.
```
-What Gloves-Arm-Fixer(With Gloves Plugin).smx do?
if server using gloves.smx and custom arms/gloves
the plugin will fix only people with default gloves
if they use gloves.smx the custom arms will not override
unless if you turn agf_force_remove "1" it will force custom arm on gloves.smx


-What Gloves-Arm-Fixer(Without Gloves Plugin).smx do?
if server not using gloves.smx and using custom arms/gloves
the plugin will fix arms/gloves


-Arms still not fixed?
in game try to increase agf_delay_fixer/agf2_delay_fixer 
it happen because of delay apply skin


-Still not fixed on zephyrus-store-preview-new-syntax
recommanded to delete these lines
https://github.com/nuclearsilo583/zephyrus-store-preview-new-syntax/blob/91b00c56053ddc90250b89d9053f4c7dfa5b2998/addons/sourcemod/scripting/store_item_playerskins.sp#L92
https://github.com/nuclearsilo583/zephyrus-store-preview-new-syntax/blob/91b00c56053ddc90250b89d9053f4c7dfa5b2998/addons/sourcemod/scripting/store_item_playerskins.sp#L107
https://github.com/nuclearsilo583/zephyrus-store-preview-new-syntax/blob/91b00c56053ddc90250b89d9053f4c7dfa5b2998/addons/sourcemod/scripting/store_item_playerskins.sp#L108
to avoid bugs we removed command sm_hidegloves + cookies
then recompile store_item_playerskins.sp and change timer agf_delay_fixer or agf2_delay_fixer to 4.0 it depend which plugin you wanna use
```

## .:[ Change Log ]:.
```
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
