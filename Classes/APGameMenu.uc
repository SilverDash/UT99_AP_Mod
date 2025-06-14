class APGameMenu extends UWindowPulldownMenu;

var UWindowPulldownMenuItem NewGame, LoadGame, Quit, ReturnToGame;

var localized string NewGameName;
var localized string NewGameHelp;
var localized string LoadGameName;
var localized string LoadGameHelp;
var localized string ReturnToGameName;
var localized string ReturnToGameHelp;
var localized string QuitName;
var localized string QuitHelp;
var localized string QuitTitle;
var localized string QuitText;
var localized string DemoQuitText;

var UWindowMessageBox ConfirmQuit;

function Created()
{
	Super.Created();
	// Add menu items.
	NewGame = AddMenuItem(NewGameName, None);
	AddMenuItem("-", None);
	LoadGame = AddMenuItem(LoadGameName, None);
	ReturnToGame = AddMenuItem(ReturnToGameName, None);
	AddMenuItem("-", None);
	Quit = AddMenuItem(QuitName, None);
}

function ShowWindow()
{
	Super.ShowWindow();
	ReturnToGame.bDisabled = GetLevel().Game != None && GetLevel().Game.IsA('UTIntro');
}

function MessageBoxDone(UWindowMessageBox W, MessageBoxResult Result)
{
	if(class'GameInfo'.Default.DemoBuild == 1)
	{
		if(W == ConfirmQuit)
		{
			switch(Result)
			{
			case MR_Yes:
				GetPlayerOwner().ConsoleCommand("start http://www.unrealtournament.com");
				GetPlayerOwner().ConsoleCommand("exit");
				break;
			case MR_No:
				Root.QuitGame();
				break;
			}				
		}
	}
	else
	{
		if(W == ConfirmQuit && Result == MR_Yes)
			Root.QuitGame();
	}
}

function ExecuteItem(UWindowPulldownMenuItem I) 
{
	local string StartMap;
	local int EmptySlot, j;

	switch(I)
	{
	case NewGame:
		Log("GAME MENU NEW GAME");
		GetPlayerOwner().ClientTravel( "UT-Logo-Map.unr?Game=Archipelago.LadderNewGame", TRAVEL_Absolute, True );
		break;
	case LoadGame:
		Log("GAME MENU LOAD GAME");
		GetPlayerOwner().ClientTravel( "UT-Logo-Map.unr?Game=Archipelago.LadderLoadGame", TRAVEL_Absolute, True );
		break;
	case Quit:
		if(class'GameInfo'.Default.DemoBuild == 1)
			ConfirmQuit = MessageBox(QuitTitle, DemoQuitText, MB_YesNoCancel, MR_Cancel, MR_No);
		else
			ConfirmQuit = MessageBox(QuitTitle, QuitText, MB_YesNo, MR_No, MR_Yes);
		break;
	case ReturnToGame:
		Root.Console.CloseUWindow();
		break;
	}

	Super.ExecuteItem(I);
}

function Select(UWindowPulldownMenuItem I)
{
	switch(I)
	{
	case NewGame:
		UMenuMenuBar(GetMenuBar()).SetHelp(NewGameHelp);
		return;
	case LoadGame:
		UMenuMenuBar(GetMenuBar()).SetHelp(LoadGameHelp);
		return;
	case Quit:
		UMenuMenuBar(GetMenuBar()).SetHelp(QuitHelp);
		break;
	case ReturnToGame:
		UMenuMenuBar(GetMenuBar()).SetHelp(ReturnToGameHelp);
		break;
	}

	Super.Select(I);
}

defaultproperties
{
	NewGameName="&Start AP Unreal Tournament"
	NewGameHelp="Select to start a new AP Unreal Tournament game!"
	LoadGameName="&Resume Saved AP Tournament"
	LoadGameHelp="Select to resume a saved Unreal Tournament game."

	ReturnToGameName="Return to &Current Game"
	ReturnToGameHelp="Leave the menus and return to your current game.  Pressing the ESC key also returns you to the current game."
	QuitName="&Quit"
	QuitHelp="Select to save preferences and exit Unreal."
	QuitTitle="Confirm Quit"
	QuitText="Are you sure you want to Quit?"
	DemoQuitText="Thank you for playing the Unreal Tournament Demo.  Visit our website for information on the full version of the game, which contains 7 unique game types and over 50 levels!\\n\\nWould you like to visit the Unreal Tournament website now?"
}