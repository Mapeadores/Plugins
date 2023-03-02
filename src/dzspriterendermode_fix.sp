/*
	Note: Map weapons/items will look like ass. For each update, ensure this is necessary.
	Bug: Render modes of anything parented onto weapons will act the same way onto players.
	Temp Fix: Change render mode to something flat.
	
	Idea by Darnias.
*/
public Plugin myinfo = 
{
	name = "Weapon Sprite Temp-Fix",
	author = "Mapeadores",
	description = "Changes render mode for parented sprites post-DZ Sirocco.",
	version = "0.2",
	url = ""
};

public void OnEntityCreated(int entity, char[] classname)
{
	if (IsValidEntity(entity) && strcmp(classname, "env_sprite", false) == 0) RequestFrame(CheckSprite, entity);
}

public void CheckSprite(int entity)
{
	if (IsValidEntity(entity)){
		int ParentEntity = GetEntPropEnt(entity, Prop_Data, "m_pParent");
		
		if (IsValidEntity(ParentEntity)){
			ParentEntity = GetRootMoveParent(ParentEntity);
			
			char ParentClassName[32];
			GetEntityClassname(ParentEntity, ParentClassName, sizeof(ParentClassName));
			
			if (StrContains(ParentClassName, "weapon_", false) != -1){
				if (GetEntityRenderMode(entity) == RENDER_GLOW || GetEntityRenderMode(entity) == RENDER_WORLDGLOW){
					//If a glow sprite, reduce inflated scale so it isn't massive for the player.
					if (GetEntityRenderMode(entity) == RENDER_GLOW && GetEntPropFloat(entity, Prop_Data, "m_flSpriteScale") > 0.35) SetEntPropFloat(entity, Prop_Data, "m_flSpriteScale", 0.35);
					
					SetEntityRenderMode(entity, RENDER_TRANSADD);
				}
			}
		}
	}
}

int GetRootMoveParent(int iEntity) {
	int iCurrentEntity = iEntity;
	
	while (IsValidEntity(iCurrentEntity)) {
		int iCurrentParent = GetEntPropEnt(iCurrentEntity, Prop_Data, "m_pParent");
		
		if (!IsValidEntity(iCurrentParent)) {
			return iCurrentEntity;
		}
		
		iCurrentEntity = iCurrentParent;
	}
	
	return iCurrentEntity;
}