class APItemManager extends LadderInventory;

// Game
var travel int			Slot;					// Savegame slot.

// Ladder
var travel int			TournamentDifficulty;
var travel int			PendingChange;			// Pending Change 
												// 0 = None  1 = DM
												// 2 = CTF   3 = DOM
												// 4 = AS
var travel int			PendingRank;
var travel int			PendingPosition;
var travel int			LastMatchType;
var travel Class<LadderAP> CurrentLadder;

// Deathmatch
var travel int			DMRank;						// Rank in the ladder.
var travel int			DMPosition;					// Position in the ladder.

// Capture the Flag
var travel int			CTFRank;
var travel int			CTFPosition;

// Domination
var travel int			DOMRank;
var travel int			DOMPosition;

// Assault
var travel int			ASRank;
var travel int			ASPosition;

// Challenge
var travel int			ChalRank;
var travel int			ChalPosition;

var travel int TDMRank;
var travel int TDMPosition;

var travel int EXRank;
var travel int EXPosition;

var travel int EX2Rank;
var travel int EX2Position;

var travel int EX3Rank;
var travel int EX3Position;

var travel bool TDMEnabled;
var travel bool EXEnabled;
var travel bool EX2Enabled;
var travel bool EX3Enabled;


// TeamInfo
var travel class<RatedTeamInfo> Team;

var travel int			Face;
var travel string		Sex;

var travel string		SkillText;

var AP_UTConsole ApConsole;	

function GetOwnerVariables()
{
	TDMEnabled = AP_UTConsole(PlayerPawn(Owner).Player.Console).SlotData.AddTDM;
	EXEnabled  = AP_UTConsole(PlayerPawn(Owner).Player.Console).SlotData.ExtraLadders;
	EX2Enabled = AP_UTConsole(PlayerPawn(Owner).Player.Console).SlotData.ExtraLadders;
	EX3Enabled = AP_UTConsole(PlayerPawn(Owner).Player.Console).SlotData.ExtraLadders;
}

function Reset()
{
	TournamentDifficulty = 0;
	PendingChange = 0;
	PendingRank = 0;
	PendingPosition = 0;
	LastMatchType = 0;
	CurrentLadder = None;
	DMRank = 0;
	DMPosition = 0;
    TDMRank = 0;
    TDMPosition = 0;
	CTFRank = 0;
	CTFPosition = 0;
	DOMRank = 0;
	DOMPosition = 0;
	ASRank = 0;
	ASPosition = 0;
	ChalRank = 0;
	ChalPosition = 0;
    EXRank = 0;
    EXPosition = 0;
    EX2Rank = 0;
    EX2Position = 0;
    EX3Rank = 0;
    EX3Position = 0;
	Face = 0;
	Sex = "";
}

function TravelPostAccept()
{
	if (DeathMatchPlus(Level.Game) != None)
	{
		Log("APLadderInventory: Calling InitRatedGame");
		DeathMatchPlus(Level.Game).InitRatedGame(Self, PlayerPawn(Owner));
	}
}

function GiveTo( Pawn Other )
{
	Log(Self$" giveto "$Other);
	Instigator = Other;
	BecomeItem();
	Other.AddInventory( Self );
	GetOwnerVariables();
	GotoState('Idle2');
}

function Destroyed()
{
	Log("Something destroyed the APLadderInventory! THIS IS BAD!!!");
    Level.Game.BroadcastMessage("Something destroyed the APLadderInventory! THIS IS BAD!!!");
	Super.Destroyed();
}

defaultproperties
{
	TournamentDifficulty=1
	bDisplayableInv=False
	bActivatable=False
	bHidden=True
}