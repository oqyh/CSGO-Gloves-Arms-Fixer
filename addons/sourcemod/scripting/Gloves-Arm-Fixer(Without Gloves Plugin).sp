#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <gloves>

#define ARMS "models/weapons/t_arms.mdl" 
#define PLUGIN_VERSION    "1.0.0"

//bool ClientOnBot[MAXPLAYERS+1];
Handle g_hGameConf;
Handle g_hPrecacheModel;
ConVar
	g_enable,
	g_timer;

bool
	g_benable = false;

float
	g_btimer = 0.0;
	
public Plugin myinfo =
{
	name = "[CSGO] Arm/Gloves Fixer",
	author = "Gold KingZ ",
	description = "Fix Gloves Arms For Custom Models",
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
	CreateConVar("agf2_version", PLUGIN_VERSION, "[ANY] Arm Gloves Fixer Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_enable = CreateConVar("agf2_enable_plugin", "1", "Arm Gloves Fixer?\n1= Enable \n0= Disable", _, true, 0.0, true, 1.0);
	
	g_timer = CreateConVar("agf2_delay_fixer", "2.0", "Timer delay to make fix arm/gloves, make it higher if there is apply skins delay");
	
	HookEvent("player_spawn", PlayerSpawn);
	
	HookConVarChange(g_enable, OnSettingsChanged);
	HookConVarChange(g_timer, OnSettingsChanged);
	
	//HookEvent("round_end", Event_RoundEnd);
	//CreateTimer(1.0, Fix_Arms, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	AutoExecConfig(true, "Gloves-Arm-Fixer_Without-Gloves-Plugin");
	
	g_hGameConf = LoadGameConfigFile("Gloves-Fixer.games");
	if (g_hGameConf == null) {
		SetFailState("Failed to load \"Gloves-Fixer.games\" gamedata");
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
	
}

public void OnConfigsExecuted()
{
	g_benable = GetConVarBool(g_enable);
	g_btimer = GetConVarFloat(g_timer);
}

public int OnSettingsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_enable)
	{
		g_benable = g_enable.BoolValue;
	}

	if(convar == g_timer)
	{
		g_btimer = g_timer.FloatValue;
	}
	
	return 0;
}

public void OnMapStart() 
{
	if(g_benable)
	{
		PrecacheModel(ARMS, true);
	}
} 

/*
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsPlayerValid(i))
		{
			ClientOnBot[i] = false;
		}
	}
	return Plugin_Continue;
}
*/

public Action PlayerSpawn(Handle event, const char[] name, bool dbc) 
{
	if(!g_benable)return Plugin_Continue;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 
	
	if(!IsPlayerValid(client))return Plugin_Continue;
	
	CreateTimer(g_btimer, Fix_Arms, client, TIMER_FLAG_NO_MAPCHANGE);
	
	/*
	char dmodel[128];
	GetClientModel(client, dmodel, sizeof(dmodel));
	if(StrContains(dmodel, "models/player/custom_player/legacy/") == -1)
	{
		
	}else
	{
		if(Gloves_IsClientUsingGloves(client) == false)
		{
			//EmptyArms(client);
			//if(ClientOnBot[client] == false)return Plugin_Continue;
			int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
			if(ent != -1)
			{
				EmptyArms(client);
				return Plugin_Continue;
			}
			SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS);
			
		}else if(Gloves_IsClientUsingGloves(client) == true)
		{
			if(ClientOnBot[client] == true)
			{
				SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS);
			}
		}
	}
	*/
	return Plugin_Continue;
}

//#if defined _gloves_included_

public Action Fix_Arms(Handle timer, any client)
{
	if(!g_benable)return Plugin_Continue;
	
	if(IsPlayerValid(client))
	{
		char sz_model[128];
		GetClientModel(client, sz_model, sizeof(sz_model));
		if(StrContains(sz_model, "models/player/custom_player/legacy/") == -1)
		{
			if(!IsFakeClient(client))
			{
				CreateFakeSpawnEvent(client);
			}
			int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
			if(ent != -1)
			{
				AcceptEntityInput(ent, "KillHierarchy");
			}
			
		}else
		{
			if(!IsFakeClient(client))
			{
				CreateFakeSpawnEvent(client);
			}
			
			int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
			if(ent != -1)
			{
				EmptyArms(client);
				return Plugin_Continue;
			}
			
			EmptyArms(client);
			SetEntPropString(client, Prop_Send, "m_szArmsModel", ARMS);
		}
	}
	return Plugin_Stop;
}

//#endif 

public void CreateFakeSpawnEvent(int client)
{
//https://github.com/nuclearsilo583/zephyrus-store-preview-new-syntax/blob/91b00c56053ddc90250b89d9053f4c7dfa5b2998/addons/sourcemod/scripting/store_item_playerskins.sp#L692
	Event event = CreateEvent("player_spawn", true);
	if (event == null)
		return;

	event.SetInt("userid", GetClientUserId(client));
	event.FireToClient(client);
	event.Cancel();
}

/*
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (buttons & IN_USE && !IsPlayerAlive(client))
	{
		int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (target != -1 && IsFakeClient(target) && ClientOnBot[client] == false)
		{
			ClientOnBot[client] = true;
		}
	}
	return Plugin_Continue;
}
*/

static bool IsPlayerValid( int client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client))
        return false; 
     
    return true; 
}

stock void EmptyArms(int client)
{
	char temp[128];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", temp, sizeof(temp));
	if(temp[0])
	{
		SetEntPropString(client, Prop_Send, "m_szArmsModel", "");
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