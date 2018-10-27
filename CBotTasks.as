
// ------------------------------------
// TASKS / SCHEDULES - 	START
// ------------------------------------
class RCBotTask
{
	bool m_bComplete = false;
	bool m_bFailed = false;
    bool m_bInit = false;

    float m_fTimeout = 0.0f;
    float m_fDefaultTimeout = 30.0f;

    RCBotSchedule@ m_pContainingSchedule;

	void Complete ()
	{
		m_bComplete = true;	
	}

	void Failed ()
	{
		m_bFailed = true;
	}	

    void setSchedule ( RCBotSchedule@ sched )
    {
        @m_pContainingSchedule = sched;
    }

    void init ()
    {
        if ( m_bInit == false )
        {
            m_fTimeout = g_Engine.time + m_fDefaultTimeout;
            m_bInit = true;
        }
        
    }

    string DebugString ()
    {
        return "";
    }

    bool timedOut ()
    {
        return g_Engine.time > m_fTimeout;
    }

    void execute ( RCBot@ bot )
    {
 
    }
}

class RCBotSchedule
{
	array<RCBotTask@> m_pTasks;
    uint m_iCurrentTaskIndex;

    RCBotSchedule()
    {
        m_iCurrentTaskIndex = 0;
    }

	void addTaskFront ( RCBotTask@ pTask )
	{
        pTask.setSchedule(this);
		m_pTasks.insertAt(0,pTask);
	}

	void addTask ( RCBotTask@ pTask )
	{	
        pTask.setSchedule(this);
		m_pTasks.insertLast(pTask);
	}

	bool execute (RCBot@ bot)
	{        
        if ( m_pTasks.length() == 0 )
            return true;

        RCBotTask@ m_pCurrentTask = m_pTasks[0];

        m_pCurrentTask.init();
        m_pCurrentTask.execute(bot);

        if ( m_pCurrentTask.m_bComplete )
        {                
            BotMessage("m_pTasks.removeAt(0)");
            m_pTasks.removeAt(0);
        BotMessage(m_pCurrentTask.DebugString()+" COMPLETE");
            if ( m_pTasks.length() == 0 )
            {
                BotMessage("m_pTasks.length() == 0");
                return true;
            }
        }
        else if ( m_pCurrentTask.timedOut() )
        {
                    BotMessage(m_pCurrentTask.DebugString()+" FAILED");

            m_pCurrentTask.m_bFailed = true;
            // failed
            return true;
        }
        else if ( m_pCurrentTask.m_bFailed )
        {
                    BotMessage(m_pCurrentTask.DebugString()+" FAILED");

            return true;
        }

        return false;
	}
}

// ------------------------------------
// TASKS / SCHEDULES - 	END
// ------------------------------------


final class CFindHealthTask : RCBotTask 
{
    CFindHealthTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindHealthTask";
    }

    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        BotMessage("CFindHealthTask");

        while( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "func_healthcharger")) !is null )
        {
            if ( bot.distanceFrom(pent) < 400 )
            {
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, pent, bot.m_pPlayer ))
                {
                        if ( pent.pev.frame == 0  )
                        {
                            BotMessage("func_healthcharger");

                            // add task to use health charger
                            m_pContainingSchedule.addTask(CUseHealthChargerTask(bot,pent));
                            Complete();
                            return;
                        }
                }
            }
        }
        
        while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "item_healthkit")) !is null )
        {
            // within reaching distance
            if ( bot.distanceFrom(pent) < 400 )
            {
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, pent, bot.m_pPlayer ))
                {
                        if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW )
                        {
                            BotMessage("item_healthkit");
                            // add Task to pick up health
                            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
                            Complete();
                            return;
                        }
                }
            }

        }

        
            BotMessage("nothing FOUND");

        Failed();
    }
}

final class CFindAmmoTask : RCBotTask 
{
    CFindAmmoTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindAmmoTask";
    }
    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        BotMessage("CFindAmmoTask");

        array<CBaseEntity@> pickup;
        
        while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, bot.m_pPlayer.pev.origin, 512,"ammo_*", "classname" )) !is null )
        {
            if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW )
            {      
                if ( bot.m_pPlayer.HasNamedPlayerItem(pent.GetClassname()) is null )
                {
                    if ( UTIL_IsVisible(bot.origin(),pent,bot.m_pPlayer) )
                    {
                        pickup.insertLast(pent);                  
                    }
                }
            }						
        }

        if ( pickup.length() > 0 )
        {
            @pent = pickup[Math.RandomLong(0,pickup.length()-1)];

            BotMessage(pent.GetClassname());	

            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));

            Complete();            
            return;
        }

        Failed();
        return;
    }
}


final class CFindWeaponTask : RCBotTask 
{
    CFindWeaponTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindWeaponTask";
    }
    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        array<CBaseEntity@> pickup;


        BotMessage("CFindWeaponTask");
        
        
        while ( (@pent = g_EntityFuncs.FindEntityInSphere(pent, bot.m_pPlayer.pev.origin, 512,"weapon_*", "classname" )) !is null )
        {
            if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW )
            {      
                if ( bot.m_pPlayer.HasNamedPlayerItem(pent.GetClassname()) is null )
                {
                    if ( UTIL_IsVisible(bot.origin(),pent,bot.m_pPlayer) )
                    {
                        pickup.insertLast(pent);                  
                    }
                }
            }						
        }

        if ( pickup.length() > 0 )
        {
            @pent = pickup[Math.RandomLong(0,pickup.length()-1)];

            BotMessage(pent.GetClassname());	

            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
            
            Complete();            
            return;
        }

        Failed();
        return;
    }
}

final class CFindArmorTask : RCBotTask 
{
    CFindArmorTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindArmorTask";
    }
    void execute ( RCBot@ bot )
    {
        // Search for health to pick up or health dispenser
        CBaseEntity@ pent = null;

        BotMessage("CFindArmorTask");

        while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "func_recharge")) !is null )
        {
            float dist =  bot.distanceFrom(pent);
            BotMessage("FUNC_RECHARD DIST == " + dist);
            // within reaching distance
            if ( dist < 400 )
            {
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, pent, bot.m_pPlayer ))
                {
                    if ( pent.pev.frame == 0 )
                    {
                        BotMessage("func_recharge");

                        // add task to use health charger
                        m_pContainingSchedule.addTask(CUseArmorCharger(bot,pent));
                        Complete();
                        return;
                    }          
                    //else
                    // BotMessage("FRAME != 0!!!");          
                }
            }
        }
        
        while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "item_battery")) !is null )
        {

            
            // within reaching distance
            if ( bot.distanceFrom(pent) < 400 )
            {
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, pent, bot.m_pPlayer ))
                {
                        if ( (pent.pev.effects & EF_NODRAW) != EF_NODRAW )
                        {
                            BotMessage("item_battery");
                            // add Task to pick up health
                            m_pContainingSchedule.addTask(CPickupItemTask(bot,pent));
                            Complete();
                            return;
                        }                
                }
            }
            
        }

        BotMessage("nothing FOUND");

        Failed();
    }
}

final class CPickupItemTask : RCBotTask 
{
    CBaseEntity@ m_pItem;
    string DebugString ()
    {
        return "CPickupItemTask";
    }
    CPickupItemTask ( RCBot@ bot, CBaseEntity@ item )
    {
        @m_pItem = item;
    } 

    void execute ( RCBot@ bot )
    {
        BotMessage("CPickupItemTask");

        if ( m_pItem.pev.effects & EF_NODRAW == EF_NODRAW )
        {
            BotMessage("EF_NODRAW");
            Complete();
        }

        if ( bot.distanceFrom(m_pItem) > 48 )
        {
            bot.setMove(m_pItem.pev.origin);

             BotMessage("bot.setMove(m_pItem.pev.origin);");
        }
        else
            Complete();
    }
}

final class CFindButtonTask : RCBotTask
{
    CFindButtonTask ( )
    {

    }
    string DebugString ()
    {
        return "CFindButtonTask";
    }
    void execute ( RCBot@ bot )
    {
        CBaseEntity@ pent = null;

        while ( (@pent = g_EntityFuncs.FindEntityByClassname(pent, "func_button")) !is null )
        {            
            // within reaching distance
            if ( bot.distanceFrom(pent) < 400 )
            {
                if ( UTIL_IsVisible(bot.m_pPlayer.pev.origin, pent, bot.m_pPlayer ))
                {
                        BotMessage("func_button");
                        // add Task to pick up health
                        m_pContainingSchedule.addTask(CUseButtonTask(pent));
                        Complete();
                        return;                                    
                }
            }
            
        }

        Failed();
    }
}

final class CUseButtonTask : RCBotTask
{
    CBaseEntity@ m_pButton;
    string DebugString ()
    {
        return "CUseButtonTask";
    }
    CUseButtonTask ( CBaseEntity@ button )
    {
        @m_pButton = button;
    } 

    void execute ( RCBot@ bot )
    {
        Vector vOrigin = UTIL_EntityOrigin(m_pButton);

        if ( bot.distanceFrom(m_pButton) > 56 )
        {
            bot.setMove(vOrigin);
            BotMessage("bot.setMove(m_pCharger.pev.origin)");
        }
        else
        {
            bot.StopMoving();
            bot.setLookAt(vOrigin);
            BotMessage("bot.PressButton(IN_USE)");

            if ( Math.RandomLong(0,100) < 99 )
            {
                bot.PressButton(IN_USE);
                Complete();
            }
        }
    }
}


final class CUseArmorCharger : RCBotTask
{
    CBaseEntity@ m_pCharger;
    string DebugString ()
    {
        return "CUseArmorCharger";
    }
    CUseArmorCharger ( RCBot@ bot, CBaseEntity@ charger )
    {
        @m_pCharger = charger;
        m_fDefaultTimeout = 8.0;
    } 

    void execute ( RCBot@ bot )
    {
        BotMessage("CUseArmorCharger");

        if ( m_pCharger.pev.frame != 0 )
        {
            Complete();
            BotMessage(" m_pCharger.pev.frame == 0");
        }
        if ( bot.m_pPlayer.pev.armorvalue >= 100 )
        {
            Complete();
            BotMessage(" bot.m_pPlayer.pev.armorvalue >= 100");
        }

        Vector vOrigin = UTIL_EntityOrigin(m_pCharger);

        if ( bot.distanceFrom(m_pCharger) > 56 )
        {
            bot.setMove(vOrigin);
            BotMessage("bot.setMove(m_pCharger.pev.origin)");
        }
        else
        {
            bot.StopMoving();
            bot.setLookAt(vOrigin);
            BotMessage("bot.PressButton(IN_USE)");

            if ( Math.RandomLong(0,100) < 99 )
            {
                bot.PressButton(IN_USE);
            }
        }
    }  
}

final class CUseHealthChargerTask : RCBotTask
{
    CBaseEntity@ m_pCharger;
    string DebugString ()
    {
        return "CUseHealthChargerTask";
    }
    CUseHealthChargerTask ( RCBot@ bot, CBaseEntity@ charger )
    {
        @m_pCharger = charger;
        m_fDefaultTimeout = 8.0;
    } 

    void execute ( RCBot@ bot )
    {
        if ( m_pCharger.pev.frame != 0 )
            Complete();

        BotMessage("Health  = " + bot.m_pPlayer.pev.health);
        BotMessage("MAx Health = " + bot.m_pPlayer.pev.max_health);

        if ( bot.m_pPlayer.pev.health >= bot.m_pPlayer.pev.max_health )
            Complete();

        Vector vOrigin = UTIL_EntityOrigin(m_pCharger);

        if ( bot.distanceFrom(m_pCharger) > 56 )
            bot.setMove(vOrigin);
        else
        {
            bot.StopMoving();
            bot.setLookAt(vOrigin);

            if ( Math.RandomLong(0,100) < 99 )
            {
                bot.PressButton(IN_USE);
            }
        }
    }  
}

final class CBotButtonTask : RCBotTask 
{
    int m_iButton;
    string DebugString ()
    {
        return "CBotButtonTask";
    }
    CBotButtonTask ( int button )
    {
        m_iButton = button;
    }

    void execute ( RCBot@ bot )
    {
        bot.PressButton(m_iButton);
        Complete();
    }
}

final class CFindPathTask : RCBotTask
{
    RCBotNavigator@ navigator;
    string DebugString ()
    {
        return "CFindPathTask";
    }
    CFindPathTask ( RCBot@ bot, int wpt )
    {
        @navigator = RCBotNavigator(bot,wpt);
    }

    CFindPathTask ( RCBot@ bot, Vector origin )
    {
        @navigator = RCBotNavigator(bot,origin);
    }
/*
}
	const int NavigatorState_Complete = 0;
	const int NavigatorState_InProgress = 1;
	const int NavigatorState_Fail = 2;
*/
    void execute ( RCBot@ bot )
    {
        @bot.navigator = navigator;

        switch ( bot.navigator.run() )
        {
        case NavigatorState_Complete:
            // follow waypoint
            //BotMessage("NavigatorState_Complete");
        break;
        case NavigatorState_InProgress:
            // waiting...
           // BotMessage("NavigatorState_InProgress");
        break;
        case NavigatorState_Fail:
           // BotMessage("NavigatorState_Fail");
            Failed();
        break;
        case NavigatorState_ReachedGoal:

           /// BotMessage("NavigatorState_ReachedGoal");
            Complete();

            break;
        }

    }
}

class CFindPathSchedule : RCBotSchedule
{
    CFindPathSchedule ( RCBot@ bot, int iWpt )
    {
        addTask(CFindPathTask(bot,iWpt));
    }
}


class CBotTaskFindCoverSchedule : RCBotSchedule
{    
    CBotTaskFindCoverSchedule ( RCBot@ bot, CBaseEntity@ hide_from )
    {
        addTask(CBotTaskFindCoverTask(bot,hide_from));
        // reload when arrive at cover point
        addTask(CBotButtonTask(IN_RELOAD));
    }
    
}
/*
class CBotTaskFindCoverCompleteTask : RCBotTask
{
    CBotTaskFindCoverCompleteTask ( )
    {

    }

     void execute ( RCBot@ bot )
     {
         Complete
     }
}
*/
class CBotTaskFindCoverTask : RCBotTask
{    
    RCBotCoverWaypointFinder@ finder;
    string DebugString ()
    {
        return "CBotTaskFindCoverTask";
    }
    CBotTaskFindCoverTask ( RCBot@ bot, CBaseEntity@ hide_from )
    {
        @finder = RCBotCoverWaypointFinder(g_Waypoints.m_VisibilityTable,bot,hide_from);    

        if ( finder.state == NavigatorState_Fail )
        {
            BotMessage("FINDING COVER FAILED!!!");
            Failed();
        }
    }


     void execute ( RCBot@ bot )
     {
         if ( finder.execute() )
         {
             m_pContainingSchedule.addTask(CFindPathTask(bot,finder.m_iGoalWaypoint));
             BotMessage("FINDING COVER COMPLETE!!!");
             Complete();
         }
         else
            Failed();
     }
}


/// UTIL

abstract class CBotUtil
{
    float utility;
    float m_fNextDo;

    CBotUtil ( ) 
    { 
        utility = 0; 
        m_fNextDo = 0.0;   
    }

    void reset ()
    {
        m_fNextDo = 0.0;
    }

    bool canDo (RCBot@ bot)
    {
        return g_Engine.time > m_fNextDo;
    }

    void setNextDo ()
    {
        m_fNextDo = g_Engine.time + 30.0f;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        return null;
    }

    float calculateUtility ( RCBot@ bot )
    {
        return 0;
    }    

    void setUtility ( float util )
    {
        utility = util;
    }
}

class CBotGetHealthUtil : CBotUtil
{

    float calculateUtility ( RCBot@ bot )
    {
        float healthPercent = float(bot.m_pPlayer.pev.health) / bot.m_pPlayer.pev.max_health;
     
        return (1.0f - healthPercent);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_HEALTH);				

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);

            sched.addTask(CFindHealthTask());

            return sched;
        }

        return null;
    }
}

class CBotGetWeapon : CBotUtil
{

   float calculateUtility ( RCBot@ bot )
    {
        // TO DO calculate on bots current weapons collection
        return 0.5;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_WEAPON);				

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);
            sched.addTask(CFindWeaponTask());
            return sched;
        }

        return null;
    }    
}

class CBotGetAmmo : CBotUtil
{

   float calculateUtility ( RCBot@ bot )
    {
        // TO DO Calculate based on bots current weapon / ammo inventory
        return 0.45;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_AMMO);				

        if ( iWpt != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);
            sched.addTask(CFindAmmoTask());
            return sched;
        }

        return null;
    }    
}

class CBotGetArmorUtil : CBotUtil
{
    
   float calculateUtility ( RCBot@ bot )
    {
        float healthPercent = float(bot.m_pPlayer.pev.armorvalue) / 100;

        return (1.0f - healthPercent);
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iWpt = g_Waypoints.getNearestFlaggedWaypoint(bot.m_pPlayer,W_FL_ARMOR);				

        if ( iWpt != -1 )
        {
             RCBotSchedule@ sched = CFindPathSchedule(bot,iWpt);

             sched.addTask(CFindArmorTask());   

             return sched;
        }
        return null;
    }    
}

class CBotGotoObjectiveUtil : CBotUtil
{

    float calculateUtility ( RCBot@ bot )
    {
        return 0.2;
    }

    void setNextDo ()
    {
        m_fNextDo = g_Engine.time + 1.0f;
    }   

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_IMPORTANT);

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

            sched.addTask(CFindButtonTask());

            return sched;
        }

        return null;
    }
}

class CBotFindLastEnemyUtil : CBotUtil
{
    float calculateUtility ( RCBot@ bot )
    {        
            return bot.totalHealth(); 
    }

    bool canDo (RCBot@ bot)
    {
        if ( bot.m_pEnemy.GetEntity() is null && bot.m_bLastSeeEnemyValid && bot.m_pLastEnemy.GetEntity() !is null )
            return CBotUtil::canDo(bot);

        return false;
    }    

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getNearestWaypointIndex(bot.m_vLastSeeEnemy);

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

          //  sched.addTask(CFindButtonTask());

            return sched;
        }

        return null;
    }
}


class CBotGotoEndLevelUtil : CBotUtil
{
    float calculateUtility ( RCBot@ bot )
    {
        return 0.3;
    }

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_ENDLEVEL);    

        if ( iRandomGoal != -1 )
        {
            RCBotSchedule@ sched = CFindPathSchedule(bot,iRandomGoal);

            sched.addTask(CFindButtonTask());

            return sched;
        }

        return null;
    }
}
/*
class CBotRoamUtil : CBotUtil
{
    CBotRoamUtil( RCBot@ bot )
    {
        super(bot);
    }

    float calculateUtility ( RCBot@ bot )
    {
        return (0.1);
    }

    void setNextDo ()
    {
        m_fNextDo = g_Engine.time + 1.0f;
    }    

    RCBotSchedule@ execute ( RCBot@ bot )
    {
        int iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_ENDLEVEL);

        if ( iRandomGoal == -1 )
            iRandomGoal = g_Waypoints.getRandomFlaggedWaypoint(W_FL_IMPORTANT);    

        if ( iRandomGoal != -1 )
        {
            return CFindPathSchedule(bot,iRandomGoal);
        }

        return null;
    }
}*/

class CBotUtilities 
{
    array <CBotUtil@>  m_Utils;

    CBotUtilities ( RCBot@ bot )
    {
            m_Utils.insertLast(CBotGetHealthUtil());
            m_Utils.insertLast(CBotGetArmorUtil());
            m_Utils.insertLast(CBotGotoObjectiveUtil());
            m_Utils.insertLast(CBotGotoEndLevelUtil());
            m_Utils.insertLast(CBotGetAmmo());
            m_Utils.insertLast(CBotGetWeapon());
            m_Utils.insertLast(CBotFindLastEnemyUtil());
    }

    void reset ()
    {
        for ( uint i = 0; i < m_Utils.length(); i ++ )
        {
             m_Utils[i].reset();            
        }
    }

    RCBotSchedule@  execute ( RCBot@ bot )
    {
        array <CBotUtil@>  UtilsCanDo;

        for ( uint i = 0; i < m_Utils.length(); i ++ )
        {
            if ( m_Utils[i].canDo(bot) )
            {
                   
                m_Utils[i].setUtility(m_Utils[i].calculateUtility(bot));
                BotMessage("Utility = " + m_Utils[i].utility);
                UtilsCanDo.insertLast(m_Utils[i]);
            }
        }

        if ( UtilsCanDo.length() > 0 )
        {
            UtilsCanDo.sort(function(a,b) { return a.utility > b.utility; });

            for ( uint i = 0; i < UtilsCanDo.length(); i ++ )
            {
                RCBotSchedule@ sched = UtilsCanDo[i].execute(bot);

                if ( sched !is null )
                {
                    
                    UtilsCanDo[i].setNextDo();
                    return sched;
                }
            }
        }

        return null;
    }
}