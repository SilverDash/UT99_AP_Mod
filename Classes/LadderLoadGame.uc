class LadderLoadGame extends UTIntro;

event playerpawn Login
(
	string Portal,
	string Options,
	out string Error,
	class<playerpawn> SpawnClass
)
{
	return Super.Login(Portal, Options, Error, SpawnClass);
}

function AcceptInventory(pawn PlayerPawn)
{
	
	local inventory Inv, Next;
	local APItemManager LadderObj;
	Log("LADDER LOAD GAME ACCEPT INVENTORY");
	for( Inv=PlayerPawn.Inventory; Inv!=None; Inv=Next )
	{
		Inv.Destroy();
	}
	Log("RUNNING LOAD GAME ON CONSOLE");
	AP_UTConsole(PlayerPawn(PlayerPawn).Player.Console).LoadGame();
	PlayerPawn.Weapon = None;
	PlayerPawn.SelectedItem = None;
}

function PlayTeleportEffect( actor Incoming, bool bOut, bool bSound)
{
}

defaultproperties
{
	bGameEnded=true
}