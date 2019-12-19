/*
	As description says, this is primarily used for debugging maps.
	Useful client commands are unlocked. snd_show, mat_leafvis, etc.
*/

public Plugin myinfo = 
{
	name = "Admin Cvar Unlocker",
	author = "Mapeadores",
	description = "sv_cheats but not sv_cheats for roots, ideally for debugging maps client side in server.",
	version = "0.3",
	url = ""
};

public void OnClientPostAdminCheck(int client)
{
	if (GetAdminFlag(GetUserAdmin(client), Admin_Root)) SendConVarValue(client, FindConVar("sv_cheats"), "1");
}