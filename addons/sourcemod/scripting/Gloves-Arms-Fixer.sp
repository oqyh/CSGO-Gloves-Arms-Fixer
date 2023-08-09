#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <clientprefs>
#include <multicolors>
//#include <gloves>

#define ARMS "models/weapons/t_arms.mdl" 
#define PLUGIN_VERSION    "1.0.2"
#define SZF(%0) 			%0, sizeof(%0)

Handle 
	Arr_SteamIDs = INVALID_HANDLE,
	g_hGameConf,
	g_AgfCookie,
	g_hPrecacheModel;

ConVar
	g_enable,
	g_checker,
	g_ctimer,
	g_force,
	g_Etoggles,
	g_glovesmod,
	g_hFlags,
	g_SteamIDPath,
	g_CVAR_Toggle_CMD,
	g_timer;

bool
	DisableGloves[MAXPLAYERS+1],
	PlayerIsSpecial[MAXPLAYERS+1],
	DontRE[MAXPLAYERS+1],
	g_benable = false,
	g_bchecker = false,
	g_NGloves = false,
	g_bforce = false;

int
	g_bglovesmod = 0,
	g_btoggles = 0;
	
float
	g_btimer = 0.0,
	g_bctimer = 0.0;

char
	b_armzz[128];

public Plugin myinfo =
{
	name = "[CSGO] Arms Gloves Fixer",
	author = "Gold KingZ ",
	description = "Fix Gloves Arms For Custom Models Compatibility With Gloves Plugin",
	version = PLUGIN_VERSION,
	url = "https://github.com/oqyh"
}

public MRESReturn Detour_PrecacheModel(int entity, Handle hReturn, Handle hParams)
{
	char buffer[128];
	DHookGetParamString(hParams, 1, buffer, sizeof(buffer));
	if (!strncmp(buffer, "models/weapons/v_models/arms/glove_hardknuckle/", 47, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if (!strncmp(buffer, "models/weapons/v_models/arms/glove_fingerless/", 46, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if (!strncmp(buffer, "models/weapons/v_models/arms/glove_fullfinger/", 46, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if (!strncmp(buffer, "models/weapons/v_models/arms/anarchist/", 39, false))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	if(StrContains(buffer, "error") != -1)
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void OnPluginStart()
{
	LoadTranslations( "Gloves-Arms-Fixer.phrases" );
	
	CreateConVar("agf_version", PLUGIN_VERSION, "[ANY] Arms Gloves Fixer Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_enable = CreateConVar("agf_enable_plugin", "1", "Gloves Arms Fixer?\n1= Enable \n0= Disable", _, true, 0.0, true, 1.0);
	
	g_glovesmod = CreateConVar("agf_mode", "1", "How would you like to fix the arms / gloves method \n1= Timer (every agf_delay_fixer x Secs do fix) \n2= On Respawn (do fix after agf_delay_fixer x Secs 1 time Every Respawn)", _, true, 0.0, true, 2.0);
	
	g_force = CreateConVar("agf_force_remove", "0", "Force remove gloves?\n1= yes(custom arms override gloves.smx plugin) \n0= no(gloves.smx override custom arms except default gloves)", _, true, 0.0, true, 1.0);
	
	g_timer = CreateConVar("agf_delay_fixer", "4.0", "(in Secs) Timer delay to make fix arms / gloves, make it higher if there is apply skins delay (need restart server to set new timer)");
	
	
	g_Etoggles = CreateConVar("agf_enable_toggle"		     , "0", "Make toggle invisible arms / gloves?\n3= yes ( specific steamids agf_steamid_list_path ) need restart server\n2= yes ( specific flags agf_flags )\n1= yes ( everyone can toggle on/off )\n0= no (disable toggle on/off )", _, true, 0.0, true, 3.0);
	g_checker = CreateConVar("agf_check_access", "0", "Enable checker timer to check access \n1= yes(to avoid stuck client on viplist do check every agf_check_timer x Secs) \n0= no", _, true, 0.0, true, 1.0);
	g_ctimer = CreateConVar("agf_check_timer", "5.0", "[if agf_check_access 1] (in Secs) Timer to check clients");
	g_hFlags = CreateConVar("agf_flags",	"abcdefghijklmnoz",	"[if agf_enable_toggle 2] which flags is it");
	g_SteamIDPath = CreateConVar("agf_steamid_list_path", "configs/viplist.txt", "[if agf_enable_toggle 3] where is list steamid located in addons/sourcemod/");
	g_CVAR_Toggle_CMD = CreateConVar("agf_cmd", "sm_hidearms;sm_hidearm;sm_ha", "[if agf_enable_toggle 1 or 2 or 3] which commands would you like to make it  toggle on/off hide arms / gloves (need restart server)");
	UTIL_LoadToggleCmd(g_CVAR_Toggle_CMD, Command_Gloves);
	
	HookEvent("player_spawn", PlayerSpawn);
	
	HookConVarChange(g_enable, OnSettingsChanged);
	HookConVarChange(g_force, OnSettingsChanged);
	HookConVarChange(g_timer, OnSettingsChanged);
	HookConVarChange(g_Etoggles, OnSettingsChanged);
	HookConVarChange(g_glovesmod, OnSettingsChanged);
	HookConVarChange(g_checker, OnSettingsChanged);
	HookConVarChange(g_ctimer, OnSettingsChanged);
	
	g_AgfCookie = RegClientCookie("agf_toggle_arms", "Hide arms / gloves", CookieAccess_Protected);

	if (GetFeatureStatus(FeatureType_Native, "Gloves_SetArmsModel") == FeatureStatus_Available || GetFeatureStatus(FeatureType_Native, "Gloves_IsClientUsingGloves") == FeatureStatus_Available || GetFeatureStatus(FeatureType_Native, "Gloves_GetArmsModel") == FeatureStatus_Available)
	{
		g_NGloves = true;
	}else
	{
		g_NGloves = false;
	}
	
	AutoExecConfig(true, "Gloves-Arms-Fixer");
	
	g_hGameConf = LoadGameConfigFile("Gloves-Arms-Fixer.games");
	if (g_hGameConf == null) {
		SetFailState("Failed to load \"Gloves-Arms-Fixer.games\" gamedata");
	}

	Address engine = CreateEngineInterface("VEngineServer023");
	if (engine == Address_Null) {
		SetFailState("Failed to get interface for \"VEngineServer023\"");
	}

	g_hPrecacheModel = DHookCreate(0, HookType_Raw, ReturnType_Int, ThisPointer_Address);
	if (!g_hPrecacheModel) {
		SetFailState("Failed to setup hook for \"PrecacheModel\"");
	}
	DHookAddParam(g_hPrecacheModel, HookParamType_CharPtr);
	DHookAddParam(g_hPrecacheModel, HookParamType_Bool);
	//DHookRaw(g_hPrecacheModel, false, engine);
	
	if (!DHookSetFromConf(g_hPrecacheModel, g_hGameConf, SDKConf_Virtual, "PrecacheModel")) {
		SetFailState("Failed to load \"PrecacheModel\" offset from gamedata");
	}
	DHookRaw(g_hPrecacheModel, false, engine, _, Detour_PrecacheModel);

	delete g_hGameConf;
	
	LoadSteamIDList();
}

public void OnClientDisconnect(int client)
{
	DisableGloves[client] = false;
	PlayerIsSpecial[client] = false;
	DontRE[client] = false;
}

public void OnClientCookiesCached(int client)
{
	char sCookie[8];
	GetClientCookie(client,g_AgfCookie, sCookie, sizeof(sCookie));
	DisableGloves[client] = view_as<bool>(StringToInt(sCookie));
}

public void OnClientPostAdminCheck(int client)
{
	char auth[32];

	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	if (FindStringInArray(Arr_SteamIDs, auth) != -1)
	{
		PlayerIsSpecial[client] = true;
	}
	else
	{
		PlayerIsSpecial[client] = false;
	}
}

void LoadSteamIDList()
{
	char[] path = new char[PLATFORM_MAX_PATH];
	char szBuffer[PLATFORM_MAX_PATH];
	g_SteamIDPath.GetString(szBuffer, sizeof(szBuffer));
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "%s", szBuffer);

	Handle fSteamIDList = OpenFile(path, "rt");

	if (fSteamIDList == INVALID_HANDLE)
	{
		SetFailState("Unable to load file: %s", path);
	}

	Arr_SteamIDs = CreateArray(256);

	char auth[256];

	while (!IsEndOfFile(fSteamIDList) && ReadFileLine(fSteamIDList, auth, sizeof(auth)))
	{
		ReplaceString(auth, sizeof(auth), "\r", "");
		ReplaceString(auth, sizeof(auth), "\n", "");

		PushArrayString(Arr_SteamIDs, auth);
	}

	CloseHandle(fSteamIDList);
} 

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("Gloves_SetArmsModel");
	MarkNativeAsOptional("Gloves_IsClientUsingGloves");
	MarkNativeAsOptional("Gloves_GetArmsModel");
	return APLRes_Success;
} 

public void OnConfigsExecuted()
{
	g_benable = GetConVarBool(g_enable);
	g_bforce = GetConVarBool(g_force);
	g_bchecker = GetConVarBool(g_checker);
	g_btimer = GetConVarFloat(g_timer);
	g_bctimer = GetConVarFloat(g_ctimer);
	g_btoggles = GetConVarInt(g_Etoggles);
	g_bglovesmod = GetConVarInt(g_glovesmod);
}

public int OnSettingsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_enable)
	{
		g_benable = g_enable.BoolValue;
	}
	
	if(convar == g_force)
	{
		g_bforce = g_force.BoolValue;
	}
	
	if(convar == g_checker)
	{
		g_bchecker = g_checker.BoolValue;
	}
	
	if(convar == g_timer)
	{
		g_btimer = g_timer.FloatValue;
	}
	
	if(convar == g_ctimer)
	{
		g_bctimer = g_ctimer.FloatValue;
	}
	
	if(convar == g_Etoggles)
	{
		g_btoggles = g_Etoggles.IntValue;
	}
	
	if(convar == g_glovesmod)
	{
		g_bglovesmod = g_glovesmod.IntValue;
	}
	
	return 0;
}

public void OnMapStart() 
{
	if(g_benable)
	{
		PrecacheModel(ARMS, true);
		
		if(g_bglovesmod == 1)
		{
			CreateTimer(g_btimer, Fix_Arms_Auto, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		
		if(g_bchecker)
		{
			CreateTimer(g_bctimer, checkaccess, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		}
		
	}
}

public Action PlayerSpawn(Handle event, const char[] name, bool dbc) 
{
	if(!g_benable || g_bglovesmod != 2)return Plugin_Continue;
	
	int i = GetClientOfUserId(GetEventInt(event, "userid")); 
	
	if(!IsPlayerValid(i) && !IsPlayerAlive(i))return Plugin_Continue;
	
	CreateTimer(g_btimer, Fix_Arms, i, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action Command_Gloves(int client, int args)
{
	if(!g_benable || g_btoggles == 0) return Plugin_Continue;
	
	if (client == 0)
	{
		CReplyToCommand(client, "This command is only available in game.");
		return Plugin_Handled;
    }
	
	if(g_btoggles == 1)
	{
		if(IsPlayerValid(client))
		{
			DisableGloves[client] = !DisableGloves[client];
			
			char sCookie[8];
			IntToString(DisableGloves[client], sCookie, sizeof(sCookie));
			SetClientCookie(client, g_AgfCookie, sCookie);
			
			if(DisableGloves[client])
			{
				DontRE[client] = false;
				if(g_bglovesmod == 1)
				{
					CReplyToCommand(client, " %t", "GlovesHidden");
				}else if(g_bglovesmod == 2)
				{
					CReplyToCommand(client, " %t", "GlovesHiddenNext");
				}
			}
			else
			{
				DontRE[client] = true;
				if(g_bglovesmod == 1)
				{
					CReplyToCommand(client, " %t", "GlovesShowen");
				}else if(g_bglovesmod == 2)
				{
					CReplyToCommand(client, " %t", "GlovesShowenNext");
				}
			}
			return Plugin_Handled;
		}
	}else if(g_btoggles == 2)
	{
		char zFlags[32];
		GetConVarString(g_hFlags, zFlags, sizeof(zFlags));
		if(!CheckAdminFlagsByString(client, zFlags))
		{
			CReplyToCommand(client, " %t", "FlagVIP");
			return Plugin_Handled;
		}
		
		if(CheckAdminFlagsByString(client, zFlags))
		{
			if(IsPlayerValid(client))
			{
				DisableGloves[client] = !DisableGloves[client];
				
				char sCookie[8];
				IntToString(DisableGloves[client], sCookie, sizeof(sCookie));
				SetClientCookie(client, g_AgfCookie, sCookie);
				
				if(DisableGloves[client])
				{
					DontRE[client] = false;
					if(g_bglovesmod == 1)
					{
						CReplyToCommand(client, " %t", "GlovesHidden");
					}else if(g_bglovesmod == 2)
					{
						CReplyToCommand(client, " %t", "GlovesHiddenNext");
					}
				}
				else
				{
					DontRE[client] = true;
					if(g_bglovesmod == 1)
					{
						CReplyToCommand(client, " %t", "GlovesShowen");
					}else if(g_bglovesmod == 2)
					{
						CReplyToCommand(client, " %t", "GlovesShowenNext");
					}
				}
				return Plugin_Handled;
			}
		}
	}else if(g_btoggles == 3)
	{
		char zFlags[32];
		GetConVarString(g_hFlags, zFlags, sizeof(zFlags));
		if(!PlayerIsSpecial[client])
		{
			CReplyToCommand(client, " %t", "SpecialPlayer");
			return Plugin_Handled;
		}
		
		if(PlayerIsSpecial[client])
		{
			if(IsPlayerValid(client))
			{
				DisableGloves[client] = !DisableGloves[client];
				
				char sCookie[8];
				IntToString(DisableGloves[client], sCookie, sizeof(sCookie));
				SetClientCookie(client, g_AgfCookie, sCookie);
				
				if(DisableGloves[client])
				{
					DontRE[client] = false;
					if(g_bglovesmod == 1)
					{
						CReplyToCommand(client, " %t", "GlovesHidden");
					}else if(g_bglovesmod == 2)
					{
						CReplyToCommand(client, " %t", "GlovesHiddenNext");
					}
				}
				else
				{
					DontRE[client] = true;
					if(g_bglovesmod == 1)
					{
						CReplyToCommand(client, " %t", "GlovesShowen");
					}else if(g_bglovesmod == 2)
					{
						CReplyToCommand(client, " %t", "GlovesShowenNext");
					}
				}
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Fix_Arms(Handle timer, any i)
{
	if(!g_benable || g_bglovesmod != 2)return Plugin_Continue;
	
	if(g_NGloves){
	//PrintToChatAll("gloves.smx found");
	if(IsPlayerValid(i) && IsPlayerAlive(i))
	{
		char sz_model[128];
		GetClientModel(i, sz_model, sizeof(sz_model));
		if (StrContains(sz_model, "models/player/tm_") != -1 || StrContains(sz_model, "models/player/ctm_") != -1 || StrContains(sz_model, "models/player/custom_player/legacy/") != -1)
		{
			//PrintToChat(i, "you are not using custom");
			//PrintToChat(i, "%s", sz_model);
			if(Gloves_IsClientUsingGloves(i) == false)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						EmptyArms(i);
						return Plugin_Continue;
					}
					
					EmptyArms(i);
					SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
				}
			}else if(Gloves_IsClientUsingGloves(i) == true)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(DontRE[i] == true)
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
					}else
					{
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
						EmptyArms(i);
						
						if(GetEntProp(i, Prop_Send, "m_bIsControllingBot"))
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
						}
					}
				}
			}
		}else
		{
			char b_arms[128];
			Gloves_GetArmsModel(i, b_arms, sizeof(b_arms));
			char b_armz[128];
			GetEntPropString(i, Prop_Send, "m_szArmsModel", b_armz, sizeof(b_armz));
			//PrintToChat(i, "you are using custom");
			//PrintToChat(i, "%s", b_arms);
			if(Gloves_IsClientUsingGloves(i) == false)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(DontRE[i] == true)
					{
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
						
						int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
						if(ent != -1)
						{
							AcceptEntityInput(ent, "KillHierarchy");
						}
						
						if(b_armz[0])
						{
							Gloves_SetArmsModel(i, b_arms);
						}else
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", b_arms);
						}
					}else
					{
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
						int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
						if(ent != -1)
						{
							AcceptEntityInput(ent, "KillHierarchy");
						}
					}
				}
			}else if(Gloves_IsClientUsingGloves(i) == true)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					if(g_bforce)
					{
						int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
						if(ent != -1)
						{
							AcceptEntityInput(ent, "KillHierarchy");
						}
						
						if(b_armz[0])
						{
							Gloves_SetArmsModel(i, b_arms);
						}else
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", b_arms);
						}
						
					}else
					{
						if(DontRE[i] == true)
						{
							int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
							if(ent != -1)
							{
								AcceptEntityInput(ent, "KillHierarchy");
							}
							
							if(b_armz[0])
							{
								DontRE[i] = false;
							}else
							{
								SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS); 
								DontRE[i] = false;
							}
						}else
						{
							if(GetEntProp(i, Prop_Send, "m_bIsControllingBot") || g_bforce)return Plugin_Continue;
							char armsModel[256];
							GetEntPropString(i, Prop_Send, "m_szArmsModel", armsModel, sizeof(armsModel));
							if(StrEqual(armsModel, "models/weapons/t_arms.mdl"))return Plugin_Continue;
							EmptyArms(i);
						}
					}
				}
			}
		}
	}
	}else
	{
	if(IsPlayerValid(i) && IsPlayerAlive(i))
	{
		//PrintToChat(i, "no gloves.smx");
		char sz_model[128];
		GetClientModel(i, sz_model, sizeof(sz_model));
		if (StrContains(sz_model, "models/player/tm_") != -1 || StrContains(sz_model, "models/player/ctm_") != -1 || StrContains(sz_model, "models/player/custom_player/legacy/") != -1)
		{
			//PrintToChat(i, "you are not using custom");
			//PrintToChat(i, "%s", sz_model);
			if(DisableGloves[i])
			{
				if(!IsFakeClient(i))
				{
					CreateFakeSpawnEvent(i);
				}
				
				int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
				if(ent != -1)
				{
					AcceptEntityInput(ent, "KillHierarchy");
				}
				
				EmptyArms(i);
			}else
			{
				if(!IsFakeClient(i))
				{
					CreateFakeSpawnEvent(i);
				}
				
				int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
				if(ent != -1)
				{
					EmptyArms(i);
					return Plugin_Continue;
				}
				EmptyArms(i);
				SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
			}
		}else
		{
			//PrintToChat(i, "you are using custom");
			//PrintToChat(i, "%s", b_arms);
			if(DisableGloves[i])
			{
				if(!IsFakeClient(i))
				{
					CreateFakeSpawnEvent(i);
				}
				
				int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
				if(ent != -1)
				{
					AcceptEntityInput(ent, "KillHierarchy");
				}
				
				EmptyArms(i);
			}else
			{
				if(DontRE[i] == true)
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					if(b_armzz[0])
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", b_armzz);
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
					}else
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", b_armzz);
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
					}
				}else
				{
					GetEntPropString(i, Prop_Send, "m_szArmsModel", b_armzz, sizeof(b_armzz));
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
				}
			}
		}
	}
	}
	return Plugin_Stop;
}

public Action checkaccess(Handle timer)
{
	if(!g_benable || !g_bchecker || g_btoggles == 1) return Plugin_Continue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerValid(i))
		{
			if(g_btoggles == 0 && DisableGloves[i] == true)
			{
				DisableGloves[i] = false;
				DontRE[i] = false;
			}
			
			char zFlags[32];
			GetConVarString(g_hFlags, zFlags, sizeof(zFlags));
			if(g_btoggles == 2 && DisableGloves[i] == true && !CheckAdminFlagsByString(i, zFlags))
			{
				DisableGloves[i] = false;
				DontRE[i] = false;
			}
			
			if(g_btoggles == 3 && DisableGloves[i] == true && PlayerIsSpecial[i] == false)
			{
				DisableGloves[i] = false;
				DontRE[i] = false;
			}
		}
	}
	return Plugin_Continue;
}

public Action Fix_Arms_Auto(Handle timer)
{
	if(!g_benable || g_bglovesmod != 1)return Plugin_Continue;
	
	if(g_NGloves){
	//PrintToChatAll("gloves.smx found");
	for (int i = 1; i <= MaxClients; i++) {
	if(IsPlayerValid(i) && IsPlayerAlive(i))
	{
		char sz_model[128];
		GetClientModel(i, sz_model, sizeof(sz_model));
		if (StrContains(sz_model, "models/player/tm_") != -1 || StrContains(sz_model, "models/player/ctm_") != -1 || StrContains(sz_model, "models/player/custom_player/legacy/") != -1)
		{
			//PrintToChat(i, "you are not using custom");
			//PrintToChat(i, "%s", sz_model);
			if(Gloves_IsClientUsingGloves(i) == false)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						EmptyArms(i);
						return Plugin_Continue;
					}
					
					EmptyArms(i);
					SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
				}
			}else if(Gloves_IsClientUsingGloves(i) == true)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(DontRE[i] == true)
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
					}else
					{
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
						EmptyArms(i);
						
						if(GetEntProp(i, Prop_Send, "m_bIsControllingBot"))
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
						}
					}
				}
			}
		}else
		{
			char b_arms[128];
			Gloves_GetArmsModel(i, b_arms, sizeof(b_arms));
			char b_armz[128];
			GetEntPropString(i, Prop_Send, "m_szArmsModel", b_armz, sizeof(b_armz));
			//PrintToChat(i, "you are using custom");
			//PrintToChat(i, "%s", b_arms);
			if(Gloves_IsClientUsingGloves(i) == false)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(DontRE[i] == true)
					{
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
						
						int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
						if(ent != -1)
						{
							AcceptEntityInput(ent, "KillHierarchy");
						}
						
						if(b_armz[0])
						{
							Gloves_SetArmsModel(i, b_arms);
						}else
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", b_arms); 
						}
					}else
					{
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
						int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
						if(ent != -1)
						{
							AcceptEntityInput(ent, "KillHierarchy");
						}
					}
				}
			}else if(Gloves_IsClientUsingGloves(i) == true)
			{
				if(DisableGloves[i])
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					EmptyArms(i);
				}else
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					if(g_bforce)
					{
						int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
						if(ent != -1)
						{
							AcceptEntityInput(ent, "KillHierarchy");
						}
						
						if(b_armz[0])
						{
							Gloves_SetArmsModel(i, b_arms);
						}else
						{
							SetEntPropString(i, Prop_Send, "m_szArmsModel", b_arms); 
						}
						
					}else
					{
						if(DontRE[i] == true)
						{
							int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
							if(ent != -1)
							{
								AcceptEntityInput(ent, "KillHierarchy");
							}
							
							if(b_armz[0])
							{
								DontRE[i] = false;
							}else
							{
								SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS); 
								DontRE[i] = false;
							}
						}else
						{
							if(GetEntProp(i, Prop_Send, "m_bIsControllingBot") || g_bforce)return Plugin_Continue;
							char armsModel[256];
							GetEntPropString(i, Prop_Send, "m_szArmsModel", armsModel, sizeof(armsModel));
							if(StrEqual(armsModel, "models/weapons/t_arms.mdl"))return Plugin_Continue;
							EmptyArms(i);
						}
					}
				}
			}
		}
	}
	}
	}else
	{
	for (int i = 1; i <= MaxClients; i++) {
	if(IsPlayerValid(i) && IsPlayerAlive(i))
	{
		//PrintToChat(i, "no gloves.smx");
		char sz_model[128];
		GetClientModel(i, sz_model, sizeof(sz_model));
		if (StrContains(sz_model, "models/player/tm_") != -1 || StrContains(sz_model, "models/player/ctm_") != -1 || StrContains(sz_model, "models/player/custom_player/legacy/") != -1)
		{
			//PrintToChat(i, "you are not using custom");
			//PrintToChat(i, "%s", sz_model);
			if(DisableGloves[i])
			{
				if(!IsFakeClient(i))
				{
					CreateFakeSpawnEvent(i);
				}
				
				int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
				if(ent != -1)
				{
					AcceptEntityInput(ent, "KillHierarchy");
				}
				
				EmptyArms(i);
			}else
			{
				if(!IsFakeClient(i))
				{
					CreateFakeSpawnEvent(i);
				}
				
				int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
				if(ent != -1)
				{
					EmptyArms(i);
					return Plugin_Continue;
				}
				EmptyArms(i);
				SetEntPropString(i, Prop_Send, "m_szArmsModel", ARMS);
			}
		}else
		{
			//PrintToChat(i, "you are using custom");
			//PrintToChat(i, "%s", b_arms);
			if(DisableGloves[i])
			{
				if(!IsFakeClient(i))
				{
					CreateFakeSpawnEvent(i);
				}
				
				int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
				if(ent != -1)
				{
					AcceptEntityInput(ent, "KillHierarchy");
				}
				
				EmptyArms(i);
			}else
			{
				if(DontRE[i] == true)
				{
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
					
					if(b_armzz[0])
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", b_armzz);
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
					}else
					{
						SetEntPropString(i, Prop_Send, "m_szArmsModel", b_armzz);
						if(!IsFakeClient(i))
						{
							CreateFakeSpawnEvent(i);
						}
					}
				}else
				{
					GetEntPropString(i, Prop_Send, "m_szArmsModel", b_armzz, sizeof(b_armzz));
					if(!IsFakeClient(i))
					{
						CreateFakeSpawnEvent(i);
					}
					int ent = GetEntPropEnt(i, Prop_Send, "m_hMyWearables");
					if(ent != -1)
					{
						AcceptEntityInput(ent, "KillHierarchy");
					}
				}
			}
		}
	}
	}
	}
	return Plugin_Continue;
}

public void CreateFakeSpawnEvent(int i)
{
//https://forums.alliedmods.net/showthread.php?t=314546
	Event event = CreateEvent("player_spawn", true);
	if (event == null)
		return;

	event.SetInt("userid", GetClientUserId(i));
	event.FireToClient(i);
	event.Cancel();
}

stock bool IsPlayerValid(int i)
{
	if(i > 0 && i <= MaxClients && IsClientInGame(i))
		return true;
	return false;
}

stock void EmptyArms(int i)
{
	char temp[128];
	GetEntPropString(i, Prop_Send, "m_szArmsModel", temp, sizeof(temp));
	if(temp[0])
	{
		SetEntPropString(i, Prop_Send, "m_szArmsModel", "");
	}
}

stock Address CreateEngineInterface(const char[] sInterfaceKey, Address ptr = Address_Null) {
	static Handle hCreateInterface = null;
	if (hCreateInterface == null) {
		if (g_hGameConf == null)
			return Address_Null;

		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CreateInterface")) {
			LogError("[Create Engine Interface] Failed to get CreateInterface");
			return Address_Null;
		}

		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		hCreateInterface = EndPrepSDKCall();
		if (hCreateInterface == null) {
			LogError("[Create Engine Interface] Function CreateInterface was not loaded right.");
			return Address_Null;
		}
	}

	if (g_hGameConf == null)
		return Address_Null;

	char sInterfaceName[64];
	if (!GameConfGetKeyValue(g_hGameConf, sInterfaceKey, sInterfaceName, sizeof(sInterfaceName)))
		strcopy(sInterfaceName, sizeof(sInterfaceName), sInterfaceKey);

	Address addr = SDKCall(hCreateInterface, sInterfaceName, ptr);
	if (addr == Address_Null) {
		LogError("[Create Engine Interface] Failed to get pointer to interface %s(%s)", sInterfaceKey, sInterfaceName);
		return Address_Null;
	}

	return addr;
}

void UTIL_LoadToggleCmd(ConVar &hCvar, ConCmd Call_CMD)
{
	char szPart[64], szBuffer[128];
	int reloc_idx, iPos;
	hCvar.GetString(SZF(szBuffer));
	reloc_idx = 0;
	while ((iPos = SplitString(szBuffer[reloc_idx], ";", SZF(szPart))))
	{
		if (iPos == -1)
		{
			strcopy(SZF(szPart), szBuffer[reloc_idx]);
		}
		else
		{
			reloc_idx += iPos;
		}
		
		TrimString(szPart);
		
		if (szPart[0])
		{
			RegConsoleCmd(szPart, Call_CMD);
			
			if (iPos == -1)
			{
				return;
			}
		}
	}
}

stock bool CheckAdminFlagsByString(int client, const char[] flagString)
{
    AdminId admin = view_as<AdminId>(GetUserAdmin(client));
    if (admin != INVALID_ADMIN_ID)
    {
        int flags = ReadFlagString(flagString);
        for (int i = 0; i <= 20; i++)
        {
            if (flags & (1<<i))
            {
                if(GetAdminFlag(admin, view_as<AdminFlag>(i)))
                    return true;
              }
          }
    }
    return false;
}


native void Gloves_SetArmsModel(int i, const char[] armsModel);
native bool Gloves_IsClientUsingGloves(int i);
native void Gloves_GetArmsModel(int i, char[] armsModel, int size);