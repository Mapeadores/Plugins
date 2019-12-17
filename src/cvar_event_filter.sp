/*
	FCVAR_NOTIFY event. This is always called with information about what would go public to players... and is completely unnecessary!
	Players are already notified in console of everything that goes on, why would they need to know in chat?
	Either way, simple enough. Less noise. More action. Customizeable by the server operator. No configs.
*/

ConVar CvarFilter = null;

char CvarsToFilter[32][64];

CvarsToFilterTotal = 0;

public Plugin:myinfo = 
{
	name = "Cvar Event Filter",
	author = "Mapeadores",
	description = "Filters specific or all 'server_cvar' events.",
	version = "0.2",
	url = ""
};

public OnPluginStart()
{
	CvarFilter = CreateConVar("sm_cvarevent_filter", "none", "Cvar(s) to filter. e.g. none, all, or mp_timelimit,sv_gravity,...");
	
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
}

public void OnMapStart()
{
	char CvarList[256];
	CvarFilter.GetString(CvarList, sizeof(CvarList));
	
	//Get total things and split.
	CvarsToFilterTotal = ExplodeString(CvarList, ",", CvarsToFilter, sizeof(CvarsToFilter), sizeof(CvarsToFilter[])) - 1;
}

public Action Event_ServerCvar(Handle event, char[] name, bool dontBroadcast)
{
	char CvarName[256];
	GetEventString(event, "cvarname", CvarName, sizeof(CvarName));
	
	ReplaceString(CvarName, sizeof(CvarName), " ", "", false)
	
	//If cvar is "all" or blank, filter everything.
	if (StrEqual(CvarsToFilter[0], "all", false) || !CvarsToFilter[0])
		return Plugin_Handled;
	
	//Go through what we're filtering and see if it matches.
	for (int i = 0; i <= CvarsToFilterTotal; i++)
		if (StrEqual(CvarName, CvarsToFilter[i], false))
			return Plugin_Handled;
	
	return Plugin_Continue;
}