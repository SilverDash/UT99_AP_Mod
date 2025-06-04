class AP_SlotData extends Object
config(Archipelago);
//Save data related to the specific AP slot that was connected to
/* "death_link","EndGoal","prog_armor","prog_weapons",
   "prog_Bots","RandomMapsPerLadder","VaryRandomMapNumber","ExtraLaddersNumber",
   "ShuffleLadderUnlocks","StartingLadder","LadderRandomizer","ExtraLadders",
   "RandomItemsPerMap","CustomMapRanges","MapsPerAS","MapsPerDM","MapsPerTDM",
   "MapsPerDOM","MapsPerCTF","MapsPerEX","MapsPerEX2","MapsPerEX3","AddTDM") */

var(DO_NOT_TOUCH) config bool prog_armor;
var(DO_NOT_TOUCH) config bool prog_weapons;
var(DO_NOT_TOUCH) config bool prog_bots;
var(DO_NOT_TOUCH) config bool RandomMapsPerLadder;
var(DO_NOT_TOUCH) config bool VaryRandomMapNumber;
var(DO_NOT_TOUCH) config bool ShuffleLadderUnlocks;
var(DO_NOT_TOUCH) config string StartingLadder;
var(DO_NOT_TOUCH) config bool LadderRamdomizer;
var(DO_NOT_TOUCH) config bool ExtraLadders;
var(DO_NOT_TOUCH) config int ExtraLaddersNumber;
var(DO_NOT_TOUCH) config int RandomItemsPerMap;
var(DO_NOT_TOUCH) config bool CustomMapRanges;
var(DO_NOT_TOUCH) config bool AddTDM;

var(DO_NOT_TOUCH) config int MapsPerAS;
var(DO_NOT_TOUCH) config int MapsPerDM;
var(DO_NOT_TOUCH) config int MapsPerTDM;
var(DO_NOT_TOUCH) config int MapsPerCTF;
var(DO_NOT_TOUCH) config int MapsPerDOM;
var(DO_NOT_TOUCH) config int MapsPerEX;
var(DO_NOT_TOUCH) config int MapsPerEX2;
var(DO_NOT_TOUCH) config int MapsPerEX3;

var(DO_NOT_TOUCH) config bool Initialized;
var(DO_NOT_TOUCH) config array<AP_ModMutator.LocationInfo> LocationInfoArray;
var(DO_NOT_TOUCH) config array<string> PlayerNames;
var(DO_NOT_TOUCH) config bool PlayerNamesInitialized;

var(DO_NOT_TOUCH) config bool ConnectedOnce;

var(DO_NOT_TOUCH) config int PlayerSlot;
var(DO_NOT_TOUCH) config string SlotName;
var(DO_NOT_TOUCH) config string Password;
var(DO_NOT_TOUCH) config string Host;
var(DO_NOT_TOUCH) config int Port;

var(DO_NOT_TOUCH) config string Seed;
var(DO_NOT_TOUCH) config string SeedName;

var(DO_NOT_TOUCH) config array<int> CheckedLocations;
var(DO_NOT_TOUCH) config array<string> PendingCompletedLadder;

var(DO_NOT_TOUCH) config int Goal;
var(DO_NOT_TOUCH) config int TotalLocations;

var(DO_NOT_TOUCH) config bool DeathLink;

var AP_ModMutator GameMod;


//My god the lack of save related data
var(DO_NOT_TOUCH) config array<bool> MapScouted;
var(DO_NOT_TOUCH) config int LastItemIndex;

var(DO_NOT_TOUCH) config string DO_NOT_TOUCH_THESE_VALUES;


function SetLastItemIndex(int i)
{
	LastItemIndex = i;
	APSaveConfig();
}

function int GetLastItemIndex()
{
	return LastItemIndex;
}

function APSaveConfig()
{
    SaveConfig();
}

defaultproperties
{
    DO_NOT_TOUCH_THESE_VALUES="DO_NOT_TOUCH_THESE_VALUES"
    Host="localhost"
    Port=2341
    prog_armor=false
    prog_weapons=false
    prog_bots=false
    RandomMapsPerLadder=false
    VaryRandomMapNumber=false
    ShuffleLadderUnlocks=false
    StartingLadder=""
    LadderRamdomizer=false
    ExtraLadders=false
    ExtraLaddersNumber=0
    RandomItemsPerMap=3
    CustomMapRanges=false
    AddTDM=false

    MapsPerAS=6
    MapsPerDM=14
    MapsPerTDM=14
    MapsPerCTF=10
    MapsPerDOM=9
    MapsPerEX=7
    MapsPerEX2=7
    MapsPerEX3=7

    Initialized=false

    PlayerNamesInitialized=false

    ConnectedOnce=false

    PlayerSlot=0
    SlotName=""
    Password=""

    Seed=""
    SeedName=""



    Goal=0
    TotalLocations=0

    DeathLink=false

    LastItemIndex=0

}