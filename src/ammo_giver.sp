/*
	Why hook weapon_fire? weapon_reload does not fire appropriately if ammo is depleted entirely. SDK Hook'ing can be
	expensive and we're trying to keep it as simple as possible without gamedata or other messes. This is the route to take.
	
	Known bug: Burst fire is not checked for weapons (famas & glock) and does not apply appropriate ammo as the event
	fires only once. For us, we don't really care for it. It is worth noting and fixing at a later appropriate time... (when?)
*/

ConVar AmmoFilter = null;

char AmmoToFilter[32][64];

int AmmoFilterTotal;

bool ShouldProceed;

public Plugin myinfo = 
{
	name = "Ammo Giver",
	author = "Mapeadores",
	description = "Refills ammo on fire.",
	version = "0.2",
	url = ""
};

public void OnPluginStart()
{
	AmmoFilter = CreateConVar("sm_ammogiver_filter", "none", "Ammo to filter by ent. e.g. none, all, or decoy,flashbang,grenade,...");

	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
}

public void OnMapStart()
{
	char AmmoFilterList[256];
	AmmoFilter.GetString(AmmoFilterList, sizeof(AmmoFilterList));
	
	AmmoFilterTotal = ExplodeString(AmmoFilterList, ",", AmmoToFilter, sizeof(AmmoToFilter), sizeof(AmmoToFilter[])) - 1;
	
	if (strlen(AmmoToFilter[0]) == 0 || StrEqual(AmmoToFilter[0], "all", false))
		ShouldProceed = false;
	else
		ShouldProceed = true;
}

public void Event_WeaponFire(Handle event, char[] name, bool dontBroadcast)
{
	if (ShouldProceed){
		int PlayerID = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsClientConnected(PlayerID)){
			char WeaponName[256];
			GetEventString(event, "weapon", WeaponName, sizeof(WeaponName));
			
			for (int i = 0; i <= AmmoFilterTotal; i++)
				if (StrContains(WeaponName, AmmoToFilter[i], false) == -1)
					SetReserveAmmo(PlayerID, GetReserveAmmo(PlayerID) + 1);
		}
	}
}

stock int GetReserveAmmo(int iClient)
{
	int iWep = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");

	if(iWep < 1) return -1;

	int iAmmoType = GetEntProp(iWep, Prop_Send, "m_iPrimaryAmmoType");
	
	if (iAmmoType < 0) return -1;
	
	return GetEntProp(iClient, Prop_Send, "m_iAmmo", _, iAmmoType);
}

stock void SetReserveAmmo(int iClient, int iAmmo)
{
	int iWep = GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon");

	if(iWep < 1) return;

	int iAmmoType = GetEntProp(iWep, Prop_Send, "m_iPrimaryAmmoType");

	if(iAmmoType == -1) return;

	SetEntProp(iClient, Prop_Send, "m_iAmmo", iAmmo, _, iAmmoType);
}