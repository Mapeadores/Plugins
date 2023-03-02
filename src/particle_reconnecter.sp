/*
	As the idea floats around using absurd databases and likely scenarios where things could fall apart... comes this.
	This is not a guarantee that it will work as intended. There's flaws. For example, it should also take into map file size
	as a factor. However, this seems to work alright for what it is. Don't expect results to be accurate all the time.
	
	smlib (Client_GetFakePing) is not necessarily needed but I believe results were more positive. I may be wrong on this.
	You can get the clients 'ping' from the game itself (m_iPing) and judge from there. The game ping upon connect is
	sketchy though.
	
	BE AWARE - PLAYERS MAY BE UNHAPPY OF A RECONNECT. THERE'S TOO MUCH TO CONSIDER. IF YOU DON'T GIVE A DAMN, GO AT IT!
	
	FORMULA				m*ln(x)+c
	
		PING			DOWNLOAD TIME
		 40                 25        
		 60                 27        
		 80                 29        
		100                 31        
		150                 34        
		200                 38        
*/

#include <sdktools>
#include <smlib>

ConVar ShouldReconnect;

float ConnectionTime[MAXPLAYERS+1];

bool MapHasParticles;

ArrayList ClientsCached;

#define CacheMax 80

public Plugin myinfo = 
{
	name = "Particle Reconnecter",
	author = "Mapeadores",
	description = "Reconnects clients if map has custom particles.",
	version = "0.3",
	url = ""
};

public void OnPluginStart()
{
	ShouldReconnect = CreateConVar("sm_map_reconnect", "1", "Reconnect players if necessary. (e.g. particles) 0 - Disable.", _, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_rejoin", CmdRejoin, "sm_rejoin - Rejoin server if any issues... why not type 'retry' in console?");
	
	ClientsCached = new ArrayList(CacheMax);
	
	HookEvent("player_connect_full", Event_PlayerConnectFull);
}

public void OnMapStart() 
{
	char CurrentMap[64]; 
	GetCurrentMap(CurrentMap, sizeof(CurrentMap)); 
	
	char ParticlePath[PLATFORM_MAX_PATH]; 
	FormatEx(ParticlePath, sizeof(ParticlePath), "maps/%s_particles.txt", CurrentMap); 
	
	if (FileExists(ParticlePath, true, NULL_STRING))
		MapHasParticles = true;
	else
		MapHasParticles = false;
		
	ClientsCached.Clear();
}

public void OnClientConnected(client)
{
	ConnectionTime[client] = GetEngineTime();
}

public void Event_PlayerConnectFull(Handle event, char[] name, bool dontBroadcast)
{
	int PlayerUserID = GetEventInt(event, "userid");
	int Player = GetClientOfUserId(PlayerUserID);
	int PlayerLatency = Client_GetFakePing(Player, false);
	float PlayerConnectionTime = GetEngineTime() - ConnectionTime[Player];
	float downloadSeconds = 6.316684 * Logarithm(float(PlayerLatency), 2.71828) - 5.222344;
	if (downloadSeconds < 10.0) downloadSeconds = 10.0;
	
	if (MapHasParticles && ShouldReconnect.BoolValue)
		if (PlayerConnectionTime > downloadSeconds)
			ClientParticleCacheCheck(Player);
		else
			PrintToChat(Player, "\x01 \x06[INFO]\x05 This map has effects that may require you to see them. Type \x04!rejoin\x05 if you have issues.");
}

public void ClientParticleCacheCheck(int client)
{
	char ClientSteamID[MAX_NAME_LENGTH];
	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, MAX_NAME_LENGTH);
	for (int i = 0; i < ClientsCached.Length; i++){
		char TempClientSteamIDCheck[MAX_NAME_LENGTH];
		ClientsCached.GetString(i, TempClientSteamIDCheck, sizeof(TempClientSteamIDCheck))
		if (StrEqual(TempClientSteamIDCheck, ClientSteamID))
			return;
	}
	
	ClientsCached.PushString(ClientSteamID);
	
	ClientCommand(client, "echo [SERVER] You are being reconnected now to see map effects properly!;disconnect;retry");
		
	if (ClientsCached.Length > CacheMax)
		ClientsCached.Erase(0);
}

public Action CmdRejoin(int client, int args)
{
	ClientCommand(client, "echo [SERVER] You are being reconnected now!;disconnect;retry");
	return Plugin_Handled;
}