class AP_NewGameInteremObject expands Info;

var string GameWindowType;

function PostBeginPlay()
{
	local APItemManager LadderObj;
	local int EmptySlot, j;

	EmptySlot = -1;
	for (j=0; j<5; j++)
	{
		if (class'AP_SlotWindow'.Default.Saves[j] == "") {
			EmptySlot = j;
			break;
		}
	}

	if (EmptySlot < 0)
	{
		// Create "You must first free a slot..." dialog.
		AP_UTConsole(PlayerPawn(Owner).Player.Console).Root.CreateWindow(class'FreeSlotsWindow', 100, 100, 200, 200);
		return;
	}

	// Create new game dialog.
	AP_UTConsole(PlayerPawn(Owner).Player.Console).bNoDrawWorld = True;
	AP_UTConsole(PlayerPawn(Owner).Player.Console).bLocked = True;
	UMenuRootWindow(TournamentConsole(PlayerPawn(Owner).Player.Console).Root).MenuBar.HideWindow();

	// Make them a ladder object.
	LadderObj = APItemManager(PlayerPawn(Owner).FindInventoryType(class'APItemManager'));
	if (LadderObj == None)
	{
		// Make them a ladder object.
		LadderObj = Spawn(class'APItemManager');
		Log(Self@"Created a new APLadderInventory (APItemManager).");
		LadderObj.GiveTo(PlayerPawn(Owner));
	}
	LadderObj.Reset();
	LadderObj.Slot = EmptySlot; // Find a free slot.
	class'APManagerWindow'.Default.EX3DoorOpen[EmptySlot] = 0;
	class'APManagerWindow'.Default.EX2DoorOpen[EmptySlot] = 0;
	class'APManagerWindow'.Default.EXDoorOpen[EmptySlot] = 0;

	class'APManagerWindow'.Default.TDMDoorOpen[EmptySlot] = 0;

	class'APManagerWindow'.Default.DMDoorOpen[EmptySlot] = 0;
	class'APManagerWindow'.Default.DOMDoorOpen[EmptySlot] = 0;
	class'APManagerWindow'.Default.CTFDoorOpen[EmptySlot] = 0;
	class'APManagerWindow'.Default.ASDoorOpen[EmptySlot] = 0;
	class'APManagerWindow'.Default.ChalDoorOpen[EmptySlot] = 0;
	class'APManagerWindow'.Static.StaticSaveConfig();
	Log("Assigned player a LadderInventory.");

	// Clear all slots.
	Owner.PlaySound(sound'LadderSounds.ladvance', SLOT_Misc, 0.1);
	Owner.PlaySound(sound'LadderSounds.ladvance', SLOT_Pain, 0.1);
	Owner.PlaySound(sound'LadderSounds.ladvance', SLOT_Interact, 0.1);
	Owner.PlaySound(sound'LadderSounds.ladvance', SLOT_Talk, 0.1);
	Owner.PlaySound(sound'LadderSounds.ladvance', SLOT_Interface, 0.1);

	// Go to the character creation screen.
	AP_UTConsole(PlayerPawn(Owner).Player.Console).Root.CreateWindow(Class<UWindowWindow>(DynamicLoadObject(GameWindowType, Class'Class')), 100, 100, 200, 200, TournamentConsole(PlayerPawn(Owner).Player.Console).Root, True);
}

defaultproperties
{
	GameWindowType="Archipelago.AP_NewCharacterWindow"
}