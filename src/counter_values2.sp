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
	description = "Print values.",
	version = "0.3",
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_countervalues", ToggleMathCounterValuesPrint, ADMFLAG_RCON, "sm_countervalues - Toggle print values.");
	
	HookEntityOutput("math_counter", "OutValue", GetMathCounterValues);
	
	HookEntityOutput("func_breakable", "OnHealthChanged", GetBreakableValues);
	HookEntityOutput("func_physbox", "OnHealthChanged", GetBreakableValues);
	HookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", GetBreakableValues);
	
	HookEntityOutput("prop_dynamic", "OnHealthChanged", GetBreakableValues);
	HookEntityOutput("prop_physics", "OnHealthChanged", GetBreakableValues);
	HookEntityOutput("prop_physics_multiplayer", "OnHealthChanged", GetBreakableValues);
	HookEntityOutput("prop_door_rotating", "OnHealthChanged", GetBreakableValues);
	
	HookEntityOutput("chicken", "OnHealthChanged", GetBreakableValues);
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
		
		if (strlen(TargetName) == 0)
			Format(TargetName, sizeof(TargetName), "NULL");
		
		PrintToConsoleAll_Roots("math_counter TargetName: %s, Value: %f, Min: %f, Max: %f", TargetName, TrueOutValue, Min, Max);
	}
}

public void GetBreakableValues(const char[] output, int caller, int activator, float delay)
{
	if (ShouldPrintValues){
		char TargetName[32];
		GetEntPropString(caller, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
		
		char ClassName[32];
		GetEdictClassname(caller, ClassName, sizeof(ClassName));
		
		int Health = GetEntProp(caller, Prop_Data, "m_iHealth");
		
		if (strlen(TargetName) == 0)
			Format(TargetName, sizeof(TargetName), "NULL");
			
		if (Health > 0)
			PrintToConsoleAll_Roots("%s TargetName: %s, Health: %i", ClassName, TargetName, Health);
	}
}

public Action ToggleMathCounterValuesPrint(int client, int args)
{
	if (ShouldPrintValues){
		ShouldPrintValues = false;
		ReplyToCommand(client, "[SM] Value prints are off.");
	} else {
		ShouldPrintValues = true;
		ReplyToCommand(client, "[SM] Value prints are on.");
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