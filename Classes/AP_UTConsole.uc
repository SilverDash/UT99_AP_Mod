class AP_UTConsole extends TournamentConsole
config(Archipelago);

// Speech
var SpeechWindow		SpeechWindow;
var globalconfig byte	SpeechKey;

// Timedemo
var bool				bTimeDemoIsEntry;

// Message
var bool				bShowMessage, bWasShowingMessage;
var MessageWindow		MessageWindow;

var string ManagerWindowClass;
var string UTLadderDMClass;
var string UTLadderCTFClass;
var string UTLadderDOMClass;
var string UTLadderASClass;
var string UTLadderChalClass;

var string UTLadderDMTestClass;
var string UTLadderDOMTestClass;

var string InterimObjectType;
var string SlotWindowType;

var travel AP_TcpLink Client;
var travel AP_SlotData SlotData;
var AP_ItemResender ItemResender;
var AP_ModMutator GameMod;
var bool VerboseLogging;
var bool DebugMode;

event PostRender( canvas Canvas )
{
	Super.PostRender(Canvas);

	if(bShowSpeech || bShowMessage)
		RenderUWindow( Canvas );
}

event bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
{
	local ManagerWindowStub ManagerMenu;

	if( Action!=IST_Press )
		return false;

	if( Key==SpeechKey )
	{
		if ( !bShowSpeech && !bTyping && ViewPort.Actor.PlayerReplicationInfo.VoiceType != None )
		{
			ShowSpeech();
			bQuickKeyEnable = True;
			LaunchUWindow();
		}
		return true;
	}

	if( Key == IK_Escape )
	{
		if ( (Viewport.Actor.Level.NetMode == NM_Standalone)
			 && Viewport.Actor.Level.Game.IsA('TrophyGame') )
		{
			bQuickKeyEnable = False;
			LaunchUWindow();
			bLocked = True;
			UMenuRootWindow(Root).MenuBar.HideWindow();
			ManagerMenu = ManagerWindowStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(ManagerWindowClass, Class'Class')), 100, 100, 200, 200, Root, True));
			return true;
		}
	}
	return Super.KeyEvent(Key, Action, Delta );
}

event Tick( float Delta )
{
	Super.Tick( Delta );

	if ( (Root != None) && bShowMessage )
		Root.DoTick( Delta );
}

state UWindow
{
	event bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
	{
		if(Action==IST_Release && Key==SpeechKey)
		{
			if (bShowSpeech)
				HideSpeech();
			return True;
		}
	
		if ( bShowSpeech && (SpeechWindow != None) )
		{
			
			//forward input to speech window
			if ( SpeechWindow.KeyEvent(Key, Action, Delta) )
				return true;
		}

		return Super.KeyEvent(Key, Action, Delta);
	}

	event Tick( float Delta )
	{
		local Music MenuSong;

		Super.Tick( Delta );
		if (Root == None)
			return;
		if (Root.GetPlayerOwner().Song == None &&
			( Left(Viewport.Actor.Level.GetLocalURL(), 9) ~= "cityintro" || 
			  Left(Viewport.Actor.Level.GetLocalURL(), 9) ~= "utcredits" ||
			  Left(Viewport.Actor.Level.GetLocalURL(), 5) ~= "entry") )
		{
			MenuSong = Music(DynamicLoadObject("utmenu23.utmenu23", class'Music'));
			Root.GetPlayerOwner().ClientSetMusic( MenuSong, 0, 255, MTRAN_Fade );
		}
	}
	exec function MenuCmd(int Menu, int Item)
	{
	}
}

state Typing
{
	exec function MenuCmd(int Menu, int Item)
	{
	}
}

function LaunchUWindow()
{
	LOG("CUSTOM AP CONSOLE LAUNCHED UWINDOW");
	Super.LaunchUWindow();

	if( !bQuickKeyEnable && 
	    ( Left(Viewport.Actor.Level.GetLocalURL(), 9) ~= "cityintro" || 
	      Left(Viewport.Actor.Level.GetLocalURL(), 9) ~= "utcredits") )
		Viewport.Actor.ClientTravel( "?entry", TRAVEL_Absolute, False );

	if (bShowMessage)
	{
		bWasShowingMessage = True;
		HideMessage();
	}
}

function CloseUWindow()
{
	Super.CloseUWindow();

	if (bWasShowingMessage)
		ShowMessage();
}

function CreateRootWindow(Canvas Canvas)
{
	Super.CreateRootWindow(Canvas);

	// Create the speech window.
	CreateSpeech();

	// Create the message window.
	CreateMessage();
}

function EvaluateMatch(int PendingChange, bool Evaluate)
{
	local UTLadderStub LadderMenu;
	local ManagerWindowStub ManagerMenu;

	LaunchUWindow();
	bNoDrawWorld = True;
	bLocked = True;
	UMenuRootWindow(Root).MenuBar.HideWindow();

	LOG("EVALUATE MATCH");

	switch (PendingChange)
	{
		case 0:
			ManagerMenu = ManagerWindowStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(ManagerWindowClass, Class'Class')), 100, 100, 200, 200, Root, True));
			break;
		case 1:
			LadderMenu = UTLadderStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(UTLadderDMClass, Class'Class')), 100, 100, 200, 200, Root, True));
			if (Evaluate)
				LadderMenu.EvaluateMatch();
			break;
		case 2:
			LadderMenu = UTLadderStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(UTLadderCTFClass, Class'Class')), 100, 100, 200, 200, Root, True));
			if (Evaluate)
				LadderMenu.EvaluateMatch();
			break;
		case 3:
			LadderMenu = UTLadderStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(UTLadderDOMClass, Class'Class')), 100, 100, 200, 200, Root, True));
			if (Evaluate)
				LadderMenu.EvaluateMatch();
			break;
		case 4:
			LadderMenu = UTLadderStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(UTLadderASClass, Class'Class')), 100, 100, 200, 200, Root, True));
			if (Evaluate)
				LadderMenu.EvaluateMatch();
			break;
		case 5:
			LadderMenu = UTLadderStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(UTLadderChalClass, Class'Class')), 100, 100, 200, 200, Root, True));
			if (Evaluate)
				LadderMenu.EvaluateMatch();
			break;
		case 6:
			LadderMenu = UTLadderStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(UTLadderDMTestClass, Class'Class')), 100, 100, 200, 200, Root, True));
			if (Evaluate)
				LadderMenu.EvaluateMatch();
			break;
		case 7:
			LadderMenu = UTLadderStub(Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject(UTLadderDOMTestClass, Class'Class')), 100, 100, 200, 200, Root, True));
			if (Evaluate)
				LadderMenu.EvaluateMatch();
			break;
	}
}

function NotifyLevelChange()
{
	Super.NotifyLevelChange();

	bWasShowingMessage = False;
	HideMessage();
}

/*
 * Speech
 */

function CreateSpeech()
{
	SpeechWindow = SpeechWindow(Root.CreateWindow(Class'SpeechWindow', 100, 100, 200, 200));
	SpeechWindow.bLeaveOnScreen = True;
	if(bShowSpeech)
	{
		Root.SetMousePos(0, 132.0/768 * Root.WinWidth);
		SpeechWindow.HideWindow();
		SpeechWindow.SlideInWindow();
	} 
	else
		SpeechWindow.HideWindow();
}

function ShowSpeech()
{
	if ( bUWindowActive )
		return;
	bShowSpeech = True;
	if(!bCreatedRoot)
		CreateRootWindow(None);

	Root.SetMousePos(0, 132.0/768 * Root.WinWidth);
	SpeechWindow.SlideInWindow();
	if ( ChallengeHUD(Viewport.Actor.myHUD) != None )
		ChallengeHUD(Viewport.Actor.myHUD).bHideCenterMessages = true;
}

function HideSpeech()
{
	bShowSpeech = False;
	if ( ChallengeHUD(Viewport.Actor.myHUD) != None )
		ChallengeHUD(Viewport.Actor.myHUD).bHideCenterMessages = false;

	if (SpeechWindow != None)
		SpeechWindow.SlideOutWindow();
}

/*
 * Tutorial Message Interface
 */

function CreateMessage()
{
	MessageWindow = MessageWindow(Root.CreateWindow(Class'MessageWindow', 100, 100, 200, 200));
	MessageWindow.bLeaveOnScreen = True;
	MessageWindow.HideWindow();
}

function ShowMessage()
{
	if (MessageWindow != None)
	{
		bWasShowingMessage = False;
		bShowMessage = True;
		MessageWindow.ShowWindow();
	}
}

function HideMessage()
{
	if (MessageWindow != None)
	{
		bShowMessage = False;
		MessageWindow.HideWindow();
	}
}

function AddMessage( string NewMessage )
{
	MessageWindow.AddMessage( NewMessage );
}

exec function ShowObjectives()
{
	local GameReplicationInfo GRI;
	local class<GameInfo> AssaultClass, GameClass;
	
	if(!bCreatedRoot)
		CreateRootWindow(None);

	AssaultClass = class<GameInfo>(DynamicLoadObject("Botpack.Assault", class'Class'));

	foreach Root.GetPlayerOwner().AllActors(class'GameReplicationInfo', GRI)
	{
		GameClass = class<GameInfo>(DynamicLoadObject(GRI.GameClass, class'Class'));
		if ( ClassIsChildOf(GameClass, AssaultClass) )
		{
			bLocked = True;
			bNoDrawWorld = True;
			UMenuRootWindow(Root).MenuBar.HideWindow();
			LaunchUWindow();
			Root.CreateWindow(class<UWindowWindow>(DynamicLoadObject("UTMenu.InGameObjectives", class'Class')), 100, 100, 100, 100);
		}
	}
}

event ConnectFailure( string FailCode, string URL )
{
	Log("This function is Disabled while playing Archipelago. Use a fresh install to play online instead.");
    //Level.Game.BroadcastMessage("This function is disabled while playing Archipelago!");
}

function ConnectWithPassword(string URL, string Password)
{
	Log("This function is Disabled while playing Archipelago. Use a fresh install to play online instead.");
    //Level.Game.BroadcastMessage("This function is disabled while playing Archipelago!");
}

exec function MenuCmd(int Menu, int Item)
{
	if (bLocked)
		return;

	bQuickKeyEnable = False;
	LaunchUWindow();
	if(!bCreatedRoot) 
		CreateRootWindow(None);
	UMenuRootWindow(Root).MenuBar.MenuCmd(Menu, Item);
}

function StartTimeDemo()
{
	Viewport.Actor.GetEntryLevel().TimeDilation = 1;
	TimeDemoFont = None;
	Super.StartTimeDemo();
	bTimeDemoIsEntry =		Viewport.Actor.Level.Game != None
						&&	Viewport.Actor.Level.Game.IsA('UTIntro') 
						&&	!(Left(Viewport.Actor.Level.GetLocalURL(), 9) ~= "cityintro");
}

function TimeDemoRender( Canvas C )
{
	if(	TimeDemoFont == None )
		TimeDemoFont = class'FontInfo'.Static.GetStaticSmallFont(C.ClipX);

	if( !bTimeDemoIsEntry )
		Super.TimeDemoRender(C);
	else
	{
		if( Viewport.Actor.Level.Game == None ||
			!Viewport.Actor.Level.Game.IsA('UTIntro') ||
			(Left(Viewport.Actor.Level.GetLocalURL(), 9) ~= "cityintro")
		)
		{
			bTimeDemoIsEntry = False;
			Super.TimeDemoRender(C);
		}
	}
}

function PrintTimeDemoResult()
{
	if( !bTimeDemoIsEntry )
		Super.PrintTimeDemoResult();
}

exec function Spec() {
	Root.Console.ViewPort.Actor.updateURL("OverrideClass", "Botpack.CHSpectator", true);
	Root.Console.ViewPort.Actor.ConsoleCommand("Reconnect");
}

exec function Play() {
	Root.Console.ViewPort.Actor.updateURL("OverrideClass", "", true);
	Root.Console.ViewPort.Actor.ConsoleCommand("Reconnect");
}

exec function SetTeam(int Team) {
	ViewPort.Actor.ChangeTeam(Team);
}

exec function Red() {
	SetTeam(0);
}

exec function Blue() {
	SetTeam(1);
}

exec function Green() {
	SetTeam(2);
}

exec function Gold() {
	SetTeam(3);
}


function CreateClient()
{
	local AP_TcpLink Cl;
	Log("CREATE CLIENT CALLED");
	Log("CREATE CLIENT CALLED:CLIENT IS"@Client);
	if (Client != None)
		return;
	
    foreach Root.GetLevel().AllActors(Class'AP_TcpLink', Cl)
    {
        if(Cl != none && Client == None)
        {
			LOG("FOUND CLIENT SETTING VAR:CLIENT ="@CL);
			Client = Cl;
            break;
        }
    }
	if(Client == None)
	{
		LOG("CLIENT NOT FOUND. SPAWNING NEW CLIENT");
		Client = Root.GetLevel().Spawn(class'AP_TcpLink');
	}
	

	Client.PlayerP = Root.GetPlayerOwner();
	LOG("SETTING CLIENTS PLAYER VAR TO"@Client.PlayerP );
	//PlayerP=GetPlayer();	
	if(SlotData == None)
	{
		LOG("SLOT DATA IS NONE ON CLIENT. SPAWNING");
		Client.SlotData = SpawnSlotDataObject();
		Client.Mod = GameMod;
	}
}



function AP_SlotData SpawnSlotDataObject()
{
	local LevelInfo Entry;
	local AP_ModMutator mod;
	Log("CONSOLE CALLING SPAWN SLOT DATA");
	Log("SLOT DATA IS"@SlotData);

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

	Log("CONSOLE SLOTDATA RETURNING"@SlotData);

	return SlotData;
}


function StartNewGame()
{
	local class<Info> InterimObjectClass;
	local Info InterimObject;
	CreateClient();

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
	CreateClient();

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