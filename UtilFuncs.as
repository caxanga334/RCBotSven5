

	float  UTIL_FixFloatAngle ( float fAngle )
	{
		int iLoops; // safety

		iLoops = 0;

		if ( fAngle < -180 )
		{
			while ( (iLoops < 4) && (fAngle < -180) )
			{
				fAngle += 360.0;
				iLoops++;
			}
		}
		else if ( fAngle > 180 )
		{
			while ( (iLoops < 4) && (fAngle > 180) )
			{
				fAngle -= 360.0;
				iLoops++;
			}
		}

		if ( iLoops >= 4 )
			fAngle = 0; // reset

			return fAngle;
	}

	Vector UTIL_CrossProduct ( Vector a , Vector b )
	{
		return Vector( a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x );
	}

	Vector UTIL_EyePosition ( CBaseEntity@ entity )
	{
		return entity.EyePosition() - Vector(0,0,16);
	}	

	Vector UTIL_EntityOrigin ( CBaseEntity@ entity )
	{

	//if ( entity.pev.flags & FL_MONSTER == FL_MONSTER )
	//	return entity.pev.origin + (entity.pev.view_ofs/2);

	return (entity.pev.absmin + entity.pev.absmax)/2;// (entity.pev.size / 2);

	//return entity.pev.origin;

	}

	CBasePlayer@ UTIL_FindNearestPlayerOnTop ( CBasePlayer@ pOnTopOf, float minDistance = 512.0f )
	{
		CBasePlayer@ ret = null;
		Vector vOrigin = UTIL_EntityOrigin(pOnTopOf);

			//If the plugin was reloaded, find all bots and add them again.
			for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
				float dist;

				if( pPlayer is null )
					continue;
				
				if ( pPlayer is pOnTopOf )
					continue;

				if ( pPlayer.pev.groundentity is null )
					continue;

				if ( pPlayer.pev.groundentity !is pOnTopOf.edict() )
					continue;

				dist  = (pPlayer.pev.origin - vOrigin).Length();
									
				if ( dist < minDistance )
				{
					minDistance = dist;
					@ret = pPlayer;
				}
			}

			return ret;
	}	

	CBasePlayer@ UTIL_FindNearestPlayer ( Vector vOrigin, float minDistance = 512.0f, CBasePlayer@ ignore = null, bool onGroundOnly = false, bool bMovingOnly = false )
	{
		CBasePlayer@ ret = null;

			//If the plugin was reloaded, find all bots and add them again.
			for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
				float dist;
				
				if( pPlayer is null )
					continue;
				
				if ( pPlayer is ignore )
					continue;				

				if ( onGroundOnly )
				{
					if ( pPlayer.pev.groundentity !is null )
					{
					CBaseEntity@ gnd = g_EntityFuncs.Instance(pPlayer.pev.groundentity);

					if ( gnd.GetClassname() != "worldspawn" )
						continue;
					}

					if ( pPlayer.pev.flags & FL_DUCKING != FL_DUCKING )
						continue;

					if ( pPlayer.pev.flags & FL_ONGROUND != FL_ONGROUND )
						continue;

					if ( pPlayer.pev.movetype == MOVETYPE_FLY )
						continue;
				}

				if ( bMovingOnly )
				{
					if ( pPlayer.pev.velocity.Length() == 0.0f )
						continue;
				}

					dist = (pPlayer.pev.origin - vOrigin).Length();

				if ( dist < minDistance )
				{
					minDistance = dist;
					@ret = pPlayer;
				}
			}

			return ret;
	}

	CBaseEntity@ UTIL_FindEntityByTarget ( CBaseEntity@ pent, string target )
	{
		return g_EntityFuncs.FindEntityByString(pent,"target", target);
	}
    
    void BotMessage ( string message )
    {
		//if ( g_DebugLevel & DEBUG_THINK == DEBUG_THINK )
    	g_Game.AlertMessage( at_console, "[RCBOT]" + message + "\n" );	
    }

	void SayMessage ( CBasePlayer@ player, string message )
	{
		g_PlayerFuncs.SayText(player, "[RCBOT]" + message + "\n" );
	}

	void SayMessageAll ( CBasePlayer@ player, string message )
	{
		g_PlayerFuncs.SayTextAll(player, "[RCBOT]" + message + "\n" );	
	}

    void UTIL_PrintVector ( string name, Vector v )
    {
		if ( g_DebugLevel & DEBUG_THINK == DEBUG_THINK )
        	g_Game.AlertMessage( at_console, name + " = (" + v.x + "," + v.y + "," + v.z + ")\n" );	
    }

	float UTIL_DotProduct ( Vector vA, Vector vB )
	{
		return ( (vA.x * vB.x) + (vA.y + vB.y) + (vA.z * vB.z) );
	}

	float UTIL_yawAngleFromEdict ( Vector vOrigin, Vector vBotAngles, Vector vBotOrigin)
	{
		float fAngle;

        //UTIL_PrintVector("vOrigin" , vOrigin);   

        Vector vComp = vBotOrigin - vOrigin;
        Vector vAngles;

        vAngles = Math.VecToAngles(vComp);

       // UTIL_PrintVector("vAngles" , vAngles);        
		
		fAngle = vBotAngles.y - vAngles.y;

        fAngle += 180;

		fAngle = UTIL_FixFloatAngle(fAngle);

		return fAngle;

	}

	void UTIL_DebugMsg ( CBaseEntity@ debugBot, string message, int level = 0 )
	{
		if ( g_DebugBot == debugBot )
		{
			if ( level == 0 || g_DebugLevel & level == level )
			{
				string debugLevelName = "NONE";

				switch ( level )
				{					
					case DEBUG_NAV:
						debugLevelName = "NAV";
					break;
					case DEBUG_TASK:
						debugLevelName = "TASK";
					break;
					case DEBUG_THINK:
						debugLevelName = "THINK";
					break;
					case DEBUG_UTIL:
						debugLevelName = "UTIL";
					break;
					case DEBUG_VISIBLES:
						debugLevelName = "VISIBLES";
					break;
				}

				BotMessage("[DEBUG - " + debugLevelName + "] " + message);
			}
		}
	}

	bool UTIL_VectorInsideEntity ( CBaseEntity@ pent, Vector v )
	{
		return ( v.x > pent.pev.absmin.x && v.y > pent.pev.absmin.y && v.z > pent.pev.absmin.z &&
				 v.x < pent.pev.absmax.x && v.y < pent.pev.absmax.y && v.z < pent.pev.absmax.z );
	}

    bool UTIL_IsVisible ( Vector vFrom, Vector vTo, CBaseEntity@ ignore = null )
    {
        TraceResult tr;

//void TraceHull(const Vector& in vecStart, const Vector& in vecEnd, IGNORE_MONSTERS igmon,HULL_NUMBER hullNumber, edict_t@ pEntIgnore, TraceResult& out ptr)

        g_Utility.TraceLine( vFrom, vTo, ignore_monsters,dont_ignore_glass, ignore is null ? null : ignore.edict(), tr );

        return tr.flFraction >= 1.0f;
    }   
		
    bool UTIL_IsVisible ( Vector vFrom, CBaseEntity@ pTo, CBaseEntity@ ignore )
    {
        TraceResult tr;

		Vector vTo = UTIL_EntityOrigin(pTo);

        g_Utility.TraceLine( vFrom, vTo, ignore_monsters, dont_ignore_glass , ignore !is null ? null : ignore.edict(), tr );

        CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

        return tr.flFraction >= 1.0f || (pTo is pEntity);
    }   
		        

CBaseEntity@ FIND_ENTITY_BY_TARGETNAME(CBaseEntity@ startEntity, string name )
{
    return g_EntityFuncs.FindEntityByString(startEntity,"targetname", name);
}

CBaseEntity@ FIND_ENTITY_BY_TARGET(CBaseEntity@ startEntity, string name )
{
    return g_EntityFuncs.FindEntityByString(startEntity,"target", name);
}

CBaseEntity@ UTIL_RandomTarget ( string targetname, CBaseEntity@ pPlayer )
{
	CBaseEntity@ pent = null;
	array<CBaseEntity@> pButtonsVisible;
	array<CBaseEntity@> pButtonsNotVisible;

	Vector vEye = pPlayer.EyePosition();
	
	while ( (@pent = FIND_ENTITY_BY_TARGET(pent,targetname)) !is null )
	{
		Vector vOrigin = UTIL_EntityOrigin(pent);

		if ( UTIL_IsVisible(vEye,vOrigin,pPlayer) )
			pButtonsVisible.insertLast(pent);
		else
			pButtonsNotVisible.insertLast(pent);		
	}

	if ( pButtonsVisible.length() > 0 )
		return pButtonsVisible[Math.RandomLong(0,pButtonsVisible.length()-1)];	
	if ( pButtonsNotVisible.length() > 0 )
		return pButtonsNotVisible[Math.RandomLong(0,pButtonsNotVisible.length()-1)];	
	return null;
}

uint UTIL_StringMatch ( string truncated, string search_in )
{
	uint len = search_in.Length();
	uint trunc_len = truncated.Length();
	
	if ( trunc_len > len )
		return 0;

	uint total_len = len - trunc_len;	
	uint i = 0;
	uint trunc_i = 0;
	uint search_i = 0;
	uint contiguous_match = 0;
	uint max_match = 0;

	while ( i < total_len )
	{

		trunc_i = 0;
		search_i = i;
		contiguous_match =0;

		while ( search_i < len )
		{
			if ( uint8(tolower(truncated[trunc_i])) == uint8(tolower(search_in[search_i])) )
			{
				search_i++;
				trunc_i ++;
				contiguous_match ++;
			}
			else
			{
				
				break;
			}
		}

		if ( contiguous_match > max_match )
		{
			max_match = contiguous_match;
		}

		i++;
	}
	return max_match;
}

// Finds a player from a truncated name
// e.g. 'wh' will find [m00]wh3y
CBasePlayer@ UTIL_FindPlayer ( string szName, CBaseEntity@ pIgnore = null, bool bBotsOnly = false )
{
	CBasePlayer@ pBestMatch = null;
	uint iBestMatch = 0;

	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
		uint iMatch = 0;

		if( pPlayer is null )
			continue;
		if ( pPlayer is pIgnore )
			continue;
		if ( bBotsOnly )
		{
			if ( pPlayer.pev.flags & FL_FAKECLIENT != FL_FAKECLIENT )
				continue;
		}

		iMatch = UTIL_StringMatch(szName,pPlayer.pev.netname);
		
		if ( iMatch > iBestMatch )
		{			
			@pBestMatch = pPlayer;
			iBestMatch = iMatch;
		}
	}

	return pBestMatch;

}

CBaseEntity@ UTIL_FindButton ( CBaseToggle@ door, CBaseEntity@ pPlayer )
{
    string masterName = door.m_sMaster;

    CBaseEntity@ pMaster = FIND_ENTITY_BY_TARGETNAME(null,masterName);
	CBaseEntity@ pButton;

    if ( pMaster !is null )
    {
		UTIL_DebugMsg(pPlayer,"pMaster !is null",DEBUG_THINK);
		return UTIL_RandomTarget(pMaster.pev.targetname,pPlayer);
    }

	if ( door.pev.targetname == "" )
	{
		UTIL_DebugMsg(pPlayer,"door.pev.targetname is empty :(",DEBUG_THINK);		
		return null;
	}	

	@pButton = FIND_ENTITY_BY_TARGET(null,door.pev.targetname);

	if ( pButton !is null )
	{
		string szClassname = pButton.GetClassname();
		UTIL_DebugMsg(pPlayer,"pButton !is null",DEBUG_THINK);

		if ( szClassname != "func_button" && szClassname != "func_rot_button"  && szClassname != "momentary_rot_button" )
		{			
			UTIL_DebugMsg(pPlayer,"pButton is " + pButton.GetClassname() +  " pButton.pev.targetname != \"\"",DEBUG_THINK);

			return UTIL_RandomTarget(pButton.pev.targetname,pPlayer);
		}
		else 
			return UTIL_RandomTarget(door.pev.targetname,pPlayer);
	}

	return null;
}

bool UTIL_DoorIsOpen ( CBaseDoor@ door, CBaseEntity@ pActivator )
{
    string masterName = door.m_sMaster;

    CBaseEntity@ pMaster = FIND_ENTITY_BY_TARGETNAME(null,masterName);
	CBaseEntity@ pButton;

    if ( pMaster !is null )
    {
        return pMaster.IsTriggered(pActivator);
    }

	if ( door.pev.targetname == "" )
		return true;

	return false;
}
/**
 * UTIL_CanUseTank
 * @param CBaseEntity pTankEnt tank entity
 * @return true if a player can use the tank
 */
bool UTIL_CanUseTank ( CBaseEntity@ pBot, CBaseEntity@ pTankEnt )
{
	CBaseTank@ pTank = cast<CBaseTank@>(pTankEnt);

	if ( pTank is null )
	{
		//BotMessage("pTank is null");
		return false;
	}

	if ( pTank.pev.effects & EF_NODRAW == EF_NODRAW )
		return false;

	if ( !pTank.IsTriggered(pBot) )
	{
		//BotMessage("!pTank.IsTriggered()");
		return false;
	}

	return ( pTank.GetController() is null );
}
/**
 * UTIL_FindNearestEntity
 * 
 * Finds the nearest entity with classname 
 *
 * @param checkFrame - only check entities with frame == 0 (useful for buttons etc)
 */
CBaseEntity@ UTIL_FindNearestEntity ( string classname, Vector vOrigin, float fMinDist, bool checkFrame, bool bVisible )
{
	CBaseEntity@ pent = null;
	CBaseEntity@ pNearest = null;
	float fDist;

	while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent,classname)) !is null )
	{        
		Vector entityOrigin = UTIL_EntityOrigin(pent);

		if ( checkFrame && pent.pev.frame != 0 )
			continue;
		
		fDist = (entityOrigin - vOrigin).Length();

		// within reaching distance
		if ( fDist < fMinDist )
		{
			if ( !bVisible || UTIL_IsVisible(vOrigin,UTIL_EntityOrigin(pent)) )
			{
				fMinDist = fDist;
				@pNearest = pent;                           
			}
		}
		
	}	

	return pNearest;
}

bool UTIL_PlayerIsAttacking ( CBaseEntity@ pPlayer )
{
	switch ( pPlayer.pev.sequence )
	{
case 21:
case 49:
case 57:
case 132:
case 79:
case 65:
case 113:
case 147:
case 87:
case 73:
case 107:
case 159:
case 171:
case 95:
		return true;
	}

	return false;
}

bool UTIL_DoesNearestTeleportGoTo ( Vector vTeleportOrigin, Vector vGoto )
{
	CBaseEntity@ pTeleIn = UTIL_FindNearestEntity("trigger_teleport",vTeleportOrigin,128.0f,false,true);

	if ( pTeleIn is null )
		return false;

	if ( pTeleIn.pev.target == "" )
		return false;
	
	CBaseEntity@ pTeleportDestination = FIND_ENTITY_BY_TARGETNAME(null,pTeleIn.pev.target);

	if ( pTeleportDestination is null )
		return false;

	return (UTIL_EntityOrigin(pTeleportDestination) - vGoto).Length() < 400.0f;

}