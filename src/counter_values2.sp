/*
	Made for mappers in mind, server admins (roots) can watch / check a maps math_counter values as they change.
	It is not possible to retrieve this value on the fly. Only when the math_counter is called. Which would be
	an awful thing to do as a server owner because there are outputs for the mappers that can fire.
	
	The '2' in the file name was trying to achieve it on the fly, which clearly wasn't successful. Whomp, whomp.
*/

#include <sdktools_entoutput>

bool ShouldPrintValues;

public Plugin myinfo = 
{
	name = "Counter Values",
	author = "Mapeadores",
	description = "Print math_counter values.",
	version = "0.2",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_countervalues", ToggleMathCounterValuesPrint, ADMFLAG_RCON, "sm_countervalues - Toggle print math_counter values.");
	
	HookEntityOutput("math_counter", "OutValue", GetMathCounterValues);
}

public void GetMathCounterValues(const char[] output, int caller, int activator, float delay)
{
	if (ShouldPrintValues){
		char TargetName[32];
		GetEntPropString(caller, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
		
		int OutValue = FindDataMapInfo(caller, "m_OutValue");
		float TrueOutValue = GetEntDataFloat(caller, OutValue);
		
		float Min = GetEntPropFloat(caller, Prop_Data, "m_flMin");
		float Max = GetEntPropFloat(caller, Prop_Data, "m_flMax");
		
		PrintToConsoleAll_Roots("TargetName: %s, Value: %f, Min: %f, Max: %f", TargetName, TrueOutValue, Min, Max);
	}
}

public Action ToggleMathCounterValuesPrint(int client, int args)
{
	if (ShouldPrintValues){
		ShouldPrintValues = false;
		ReplyToCommand(client, "[SM] math_counter prints are off.");
	} else {
		ShouldPrintValues = true;
		ReplyToCommand(client, "[SM] math_counter prints are on.");
	}	
}

public void OnMapEnd()
{
	ShouldPrintValues = false;
}

stock void PrintToConsoleAll_Roots(const char[] format, any ...)
{
	char buffer[254];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetAdminFlag(GetUserAdmin(i), Admin_Root))
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToConsole(i, "%s", buffer);
		}
	}
}