/*
	Note: Used as an idea to encourage killing remaining or any CT's that might be delaying rounds.
	Players WILL forget their radar exists. This is a little bit of help and notice but they can still often go missed.
	This does not burn edicts or resources apart from destroying the clients FPS if multiple are glowing with high duration.
	
	THIS WAS MADE FOR ZOMBIES HUNTING HUMANS! No support (yet?) for the other way around.
	
	
	Bug: If a player dies or has their team switched as the game is ongoing they will continue to glow.
	e.g. Zombie infects CT. CT becomes Zombie. CT that became a zombie will still be glowing for the team he is on.
	
	You could use this bug to your advantage in other ways but for us there's no use and is just an annoyance to note.
*/

#include <zombiereloaded>
#include <sdktools>

float LastFrame;

ConVar AliveCT = null;
ConVar RoundTime = null;
ConVar GlowDuration = null;

bool CanSpot = true;

Handle GlowTimer = INVALID_HANDLE;

int CurrentRoundTime = 0;

public Plugin myinfo = 
{
	name = "Opposite team spot",
	author = "Mapeadores",
	description = "Spot opposite teams.",
	version = "0.3",
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_spot", GlowPlayer, ADMFLAG_KICK, "sm_spot <name> [duration] - Spot a player for the other team.");
	
	AliveCT = CreateConVar("sm_spot_atctalive", "0", "Spot CT's when at or lower this amount.", _, true, 0.0, true, 64.0);
	RoundTime = CreateConVar("sm_spot_roundtime", "0", "Spot CT's when at or lower this time (secs).", _, true, 0.0, false, _);
	GlowDuration = CreateConVar("sm_spot_duration", "0", "Spotted CT's glow for this duration.", _, true, 0.0, true, 120.0);
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_freeze_end", Event_RoundStarted, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action GlowPlayer(int client, int args)
{
	if (CanSpot && args == 2){
		char arg1[64], arg2[4];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		float EngineTime = GetEngineTime();
		
		if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) > 0){
			for (int i = 0; i < target_count; i++){
				if (IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i])){
					GlowClient(target_list[i], StringToFloat(arg2));
					
					//Not "worldspawn" (server).
					if (client > 0){
						//In case of abuse.						
						char AdminName[64];
						char AdminSteam[MAX_NAME_LENGTH];
						GetClientName(client, AdminName, sizeof(AdminName));
						GetClientAuthId(client, AuthId_Steam2, AdminSteam, MAX_NAME_LENGTH);
						
						if (target_count > 1){
							//So we don't flood the logging. Ugly way out.
							if (EngineTime > LastFrame + 0.1){
								LogAction(client, target_list[i], "%s<%s> spotted multiple players for %f.", AdminName, AdminSteam, StringToFloat(arg2));
								ReplyToCommand(client, "[SM] Spotted multiple players for %f.", StringToFloat(arg2));
								LastFrame = EngineTime;
							}
						} else {
							char TargetName[64];
							char TargetSteam[MAX_NAME_LENGTH];
							GetClientName(target_list[i], TargetName, sizeof(TargetName));
							GetClientAuthId(target_list[i], AuthId_Steam2, TargetSteam, MAX_NAME_LENGTH);
							
							LogAction(client, target_list[i], "%s<%s> spotted %s<%s> for %f.", AdminName, AdminSteam, TargetName, TargetSteam, StringToFloat(arg2));
							ReplyToCommand(client, "[SM] Spotted %s for %f.", TargetName, StringToFloat(arg2));
						}
					}
				}
			}
		} else {
			ReplyToTargetError(client, target_count);
		}
	} else if (!CanSpot){
		ReplyToCommand(client, "[SM] Cannot spot at this time.");
	} else {
		ReplyToCommand(client, "[SM] Invalid parameters.");
	}
}

public void Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int PlayerDiedID = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(PlayerDiedID) == 3) SpotRemainingCT(false);
	
	//Reset player who died if is spotted.
	if (IsClientValid(PlayerDiedID, true, true) && GlowTime(PlayerDiedID) > 0.0) RequestFrame(RemoveGlow, PlayerDiedID);
}

public void RemoveGlow(int client)
{
	GlowClient(client, 0.0)
}

public void SpotRemainingCT(bool Timer)
{	
	if (CanSpot){
		int CTSpotPoint;
		int TotalCTs;
		
		//Lazy way out. If this is being used from the timer, proceed no matter what.
		if (!Timer){
			CTSpotPoint = AliveCT.IntValue;
			TotalCTs = GetTotalPlayingOnTeam(3);
		} else {
			CTSpotPoint = 1;
			TotalCTs = 1;
		}
		
		if (CTSpotPoint > 0 && TotalCTs <= CTSpotPoint)
			for (int i = 1; i <= MaxClients; i++)
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
					GlowClient(i, GlowDuration.FloatValue);
	}
}

//Mother zombie spawning, spot can be used.
public Action ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if (motherInfect && !CanSpot) CanSpot = true;
}

public void Event_RoundStarted(Handle event, char[] name, bool dontBroadcast)
{
	CurrentRoundTime = GameRules_GetProp("m_iRoundTime");
	if (RoundTime.IntValue > 0) GlowTimer = CreateTimer(1.0, ShouldGlow, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action ShouldGlow(Handle timer)
{
	CurrentRoundTime--;
		
	if (CurrentRoundTime <= RoundTime.IntValue) SpotRemainingCT(true);
	
	if (CurrentRoundTime <= 0) return Plugin_Stop;
	
	return Plugin_Continue;
}

//Always reset all players on round end. Just a precaution.
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	EndGlowSession();
}

public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	EndGlowSession();
}

public void OnMapEnd()
{
	EndGlowSession();
}

public EndGlowSession()
{
	for (int i = 1; i <= MaxClients; i++) if (IsClientValid(i, true, false) && GlowTime(i) > 0.0) GlowClient(i, 0.0);
	
	CanSpot = false;
	
	delete GlowTimer;
}

stock GlowClient(int client, float duration)
{
	//If already set to a high amount, don't overwrite it.
	float ToSet = GetGameTime() + duration;
	
	if (duration <= 0.0)
		SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", 0.0);
	else if (GlowTime(client) < ToSet)
		SetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime", ToSet);
}

stock float GlowTime(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flDetectedByEnemySensorTime");
}

stock bool IsClientValid(int client, bool connected, bool playing)
{
	if(client < 1 || !IsValidEntity(client)) return false;
	if(connected && !IsClientConnected(client)) return false;
	if(playing && GetClientTeam(client) < 2) return false;
	
	return true;
}

stock int GetTotalPlayingOnTeam(int team)
{
	int TotalPlaying;
	
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientValid(i, true, false) && GetClientTeam(i) == team)
			TotalPlaying++;
	
	return TotalPlaying;
}