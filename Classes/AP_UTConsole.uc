class AP_UTConsole extends UTConsole
config(Archipelago);

var AP_TcpLink Client;
var AP_SlotData SlotData;
var AP_ItemResender ItemResender;
var AP_ModMutator GameMod;
var bool VerboseLogging;
var bool DebugMode;


function AP_SlotData SpawnSlotDataObject()
{
	local LevelInfo Entry;
	local AP_ModMutator mod;

	if(SlotData == None)
		SlotData = new class'AP_SlotData';
	//Dirty
	Entry = Root.Console.ViewPort.Actor.GetEntryLevel();
	if(GameMod == None)
	{
		GameMod = Entry.Spawn(class'AP_ModMutator');
		GameMod.PlayerP = Root.GetPlayerOwner();
		log("Console Player"@Root.GetPlayerOwner()@"Was set to GameMod Player"@GameMod.PlayerP);
	}
	foreach Root.GetPlayerOwner().AllActors(class 'AP_ModMutator', mod)
	{
		mod.PlayerP = Root.GetPlayerOwner();
		log("Console Player"@Root.GetPlayerOwner()@"Was set to Mod Player"@mod.PlayerP);
	}



	return SlotData;
}


function StartNewGame()
{
	local class<Info> InterimObjectClass;
	local Info InterimObject;

	SpawnSlotDataObject();
	if (SlotData==none)
	{
		log("Missing Slot Data aborting...");
		Return;
	}
	Log("Starting a new Archipelago game...");
	InterimObjectClass = Class<Info>(DynamicLoadObject(InterimObjectType, Class'Class'));
	InterimObject = Root.GetPlayerOwner().Spawn(InterimObjectClass, Root.GetPlayerOwner());
}

function LoadGame()
{
	SpawnSlotDataObject();
	if (SlotData==none)
	{
		log("Missing Slot Data aborting...");
		Return;
	}
	// Clear all slots.
	Root.GetPlayerOwner().PlaySound(sound'LadderSounds.ladvance', SLOT_Misc, 0.1);
	Root.GetPlayerOwner().PlaySound(sound'LadderSounds.ladvance', SLOT_Pain, 0.1);
	Root.GetPlayerOwner().PlaySound(sound'LadderSounds.ladvance', SLOT_Interact, 0.1);
	Root.GetPlayerOwner().PlaySound(sound'LadderSounds.ladvance', SLOT_Talk, 0.1);
	Root.GetPlayerOwner().PlaySound(sound'LadderSounds.ladvance', SLOT_Interface, 0.1);

	// Create load game dialog.
	bNoDrawWorld = True;
	bLocked = True;
	UMenuRootWindow(Root).MenuBar.HideWindow();

	// Go to the slot window.
	Root.CreateWindow(Class<UWindowWindow>(DynamicLoadObject(SlotWindowType, class'Class')), 100, 100, 200, 200, Root, True);
}

function ScreenMessage(String message, optional Name type)
{
	local PlayerPawn pp;
	
	//if (VerboseLogging)
	//{
        log(Message);
	//}
	
	pp = GetPlayer();
    if (pp == None)
		return;
    
    pp.ClientMessage(message, type, true);
}

function DebugMessage(String message, optional Name type)
{
	local PlayerPawn pp;
	if (VerboseLogging)
	{
        log(Message);
	}
	
	if (DebugMode)
		return;
	
	pp = GetPlayer();
    if (pp == None)
		return;
    
    pp.ClientMessage(message, type, true);
}

Function PlayerPawn GetPlayer()
{
	return Root.GetPlayerOwner();
}

// Archipelago requires JSON messages to be encased in []
function string EncodeJson2(JsonObject json)
{
	local string message;
	message = "["$class'JsonObject'.static.EncodeJson(json)$"]";
	return message;
}

// Removes the \# at the start of the string when reading a value
// This is mainly used to properly retrieve number values that could potentially be 64 bit which would break with JsonObject.GetIntValue()
function string GetStringValue2(JsonObject json, string key)
{
	return Mid(json.GetStringValue(key), 2);
}


defaultproperties
{
	ManagerWindowClass="Archipelago.APManagerWindow"
	UTLadderDMClass="Archipelago.APLadderDM"
	UTLadderCTFClass="Archipelago.APLadderCTF"
	UTLadderDOMClass="Archipelago.APLadderDOM"
	UTLadderASClass="Archipelago.APLadderAS"
	UTLadderChalClass="Archipelago.APLadderChal"
	UTLadderTDMClass="Archipelago.APTDMLadder"


	UTLadderDMTestClass="UTMenu.UTLadderDMTest"
	UTLadderDOMTestClass="UTMenu.UTLadderDOMTest"
	// IK_V
	SpeechKey=86

	InterimObjectType="Archipelago.AP_NewGameInteremObject"
	SlotWindowType="Archipelago.AP_SlotWindow"
}