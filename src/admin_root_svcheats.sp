/*
	As description says, this is primarily used for debugging maps.
	Useful client commands are unlocked. snd_show, mat_leafvis, etc.
*/

public Plugin myinfo = 
{
	name = "Admin Cvar Unlocker",
	author = "Mapeadores",
	description = "sv_cheats but not sv_cheats for roots, ideally for debugging maps client side in server.",
	version = "0.4",
	url = ""
};

public void OnClientPostAdminCheck(int client)
{
	if (GetAdminFlag(GetUserAdmin(client), Admin_Root)) SendConVarValue(client, FindConVar("sv_cheats"), "1");
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_replicate", ReplicateValue, ADMFLAG_ROOT, "sm_replicate <cvar> [value] - Replicate a command value to client.");
}

public Action ReplicateValue(int client, int args)
{
	if (args == 3){
		char arg1[64], arg2[64], arg3[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) > 0){
			for (int i = 0; i < target_count; i++){
				if (IsClientInGame(target_list[i])){
					SendConVarValue(target_list[i], FindConVar(arg2), arg3);
				}
			}
		} else {
			ReplyToTargetError(client, target_count);
		}
	} else {
		ReplyToCommand(client, "[SM] Invalid parameters.");
	}
	return Plugin_Handled;
}