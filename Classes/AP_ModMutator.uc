Class AP_ModMutator extends Mutator
config(Archipelago);

var AP_TcpLink Client;



var array<int> LocationsToResend;

const SlotDataVersion = 11;

var transient bool ItemSoundCooldown;
var transient bool DeathLinked;
var transient string DebugMsg;

var config bool DebugMode;

var config bool VerboseLogging;

var transient bool TrapsDestroyed;
var transient float TimeSinceLastItem;
var PlayerPawn PlayerP;


struct LocationInfo
{
	var int ID;
	var string ItemID; // string since it can be item IDs from other games, which can be 64 bit.
	var int Player;
	var int Flags;
	var bool IsStatic;

	
	var Vector Position;
	var class<Actor> ItemClass;
	var class<Actor> ContainerClass;
};

/* "death_link","EndGoal","prog_armor","prog_weapons",
   "prog_Bots","RandomMapsPerLadder","VaryRandomMapNumber","ExtraLaddersNumber",
   "ShuffleLadderUnlocks","StartingLadder","LadderRandomizer","ExtraLadders",
   "RandomItemsPerMap","CustomMapRanges","MapsPerAS","MapsPerDM","MapsPerTDM",
   "MapsPerDOM","MapsPerCTF","MapsPerEX","MapsPerEX2","MapsPerEX3","AddTDM") */

function LoadSlotData(JsonObject json)
{
	local string n, hg, itemName;
	local int i, j, v, id;
	local AP_SlotData SlotData;
	Log("LOADSLOT DATA CALLED");
	GetPlayer();
	Log("LOADSLOT DATA:"@PlayerP);
	SlotData = AP_UTConsole(PlayerP.Player.Console).SlotData;
	Log("LOADSLOT DATA:"@SlotData);

	if (SlotData.Initialized)
		return;
	
	SlotData.ConnectedOnce = true;
	SlotData.Goal = json.GetIntValue("EndGoal");
	SlotData.TotalLocations = json.GetIntValue("TotalLocations");

	SlotData.DeathLink = json.GetBoolValue("death_link");
	SlotData.Seed = json.GetStringValue("SeedNumber");
	SlotData.SeedName = json.GetStringValue("SeedName");
	SlotData.prog_armor = json.GetBoolValue("prog_armor");
	SlotData.prog_Bots = json.GetBoolValue("prog_Bots");
	SlotData.prog_weapons = json.GetBoolValue("prog_weapons");
	SlotData.RandomMapsPerLadder = json.GetBoolValue("RandomMapsPerLadder");
	SlotData.VaryRandomMapNumber = json.GetBoolValue("VaryRandomMapNumber");
	SlotData.ExtraLaddersNumber = json.GetIntValue("ExtraLaddersNumber");
	SlotData.ShuffleLadderUnlocks = json.GetBoolValue("ShuffleLadderUnlocks");
	SlotData.StartingLadder = json.GetStringValue("StartingLadder");
	SlotData.ExtraLadders = json.GetBoolValue("ExtraLadders");
	SlotData.RandomItemsPerMap = json.GetIntValue("RandomItemsPerMap");
	SlotData.CustomMapRanges = json.GetBoolValue("CustomMapRanges");
	SlotData.AddTDM = json.GetBoolValue("AddTDM");
	SlotData.MapsPerAS = json.GetIntValue("MapsPerAS");
	SlotData.MapsPerDM = json.GetIntValue("MapsPerDM");
	SlotData.MapsPerTDM = json.GetIntValue("MapsPerTDM");
	SlotData.MapsPerDOM = json.GetIntValue("MapsPerDOM");
	SlotData.MapsPerCTF = json.GetIntValue("MapsPerCTF");
	SlotData.MapsPerEX = json.GetIntValue("MapsPerEX");
	SlotData.MapsPerEX2 = json.GetIntValue("MapsPerEX2");
	SlotData.MapsPerEX3 = json.GetIntValue("MapsPerEX3");


	SlotData.Initialized = true;
	
}

function ScreenMessage(String message, optional Name type)
{
	local PlayerPawn pp;
	
	if (VerboseLogging)
	{
        log(Message);
	}
	
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
    local PlayerPawn Player;
    foreach AllActors(Class'PlayerPawn', Player)
    {
        if(Player != none && PlayerP == None)
        {
			PlayerP = Player;
            break;
        }
    }
	
    return Player;
}

function string PlayerIdToName(int id)
{
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(PlayerP.Player.Console).SlotData;
	if (id <= 0)
		return "Archipelago";
	
	if (id >= SlotData.PlayerNames.Length || SlotData.PlayerNames[id] == "")
		return "Unknown Player";
	
	return SlotData.PlayerNames[id];
}


//************* */
//
//Item Resending
//
//************ */
function OnPreConnected()
{
	
}
function OnFullyConnected();

//Check the dynamic array for an element since we don't have a find method
function bool CheckArrayForElement(array<int> a, int element)
{
	local int i;
	for (i = 0; i < a.Length; i++)
	{
		if (a[i] == element)
		{
			return True;
		}
	}
	return False;
}


function ResendLocations()
{
    if (LocationsToResend.Length == 0 || Client.LinkState != STATE_Connected)
        return;
    
    DebugMessage("Resending locations");
    SendMultipleLocationChecks(LocationsToResend);
    LocationsToResend.Length = 0;
}

function AddLocation(int location)
{
    if (CheckArrayForElement(LocationsToResend,location))
        return;

    LocationsToResend.Insert(LocationsToResend.Length);
    LocationsToResend[LocationsToResend.Length-1]=location;
}

function AddMultipleLocations(array<int> locationList)
{
    local int i;
    for (i = 0; i < locationList.Length; i++)
    {
        if (CheckArrayForElement(locationList,locationList[i]))
            continue;

        LocationsToResend.Insert(LocationsToResend.Length);
		LocationsToResend[LocationsToResend.Length-1]=locationList[i];

    }
}

event Tick(float d)
{
	Super.Tick(d);	
}


function KeepConnectionAlive()
{
	local string message;
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(PlayerP.Player.Console).SlotData;
	if (!IsFullyConnected())
		return;
	
	message = "[{`cmd`:`Bounce`,`slots`:["$SlotData.PlayerSlot$"]}]";
	message = Repl(message, "`", "\"");
	client.SendBinaryMessage(message);
}

function bool PreventDeath(Pawn Killed, Pawn Killer, name damageType, vector HitLocation)
{
    if(PlayerPawn(Killed)==None)
        OnPlayerDeath();
	if ( NextMutator != None )
		return NextMutator.PreventDeath(Killed,Killer, damageType,HitLocation);
	return false;
}

function OnPlayerDeath()
{
	local string message, deathString;
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(PlayerP.Player.Console).SlotData;
	if (!IsDeathLinkEnabled())
		return;
	
	DeathLinked = true;
	message = "[{`cmd`:`Bounce`,`tags`:[`DeathLink`],`data`:{`time`:" $"`" $0$"`" $",`source`:" $"`" $SlotData.SlotName $"`" $"}}]";
	message = Repl(message, "`", "\"");
	client.SendBinaryMessage(message);
}

function SendLocationCheck(int id, optional bool scout, optional bool hint)
{
	local string jsonMessage;
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(PlayerP.Player.Console).SlotData;
	
	
	if (!scout)
	{
		jsonMessage = "[{`cmd`:`LocationChecks`,`locations`:[" $id $"]}]";
		DebugMessage("Sending location ID: " $id);
		
		if (!CheckArrayForElement(SlotData.CheckedLocations,id))
		{
			SlotData.CheckedLocations.Insert(SlotData.CheckedLocations.Length);
			SlotData.CheckedLocations[SlotData.CheckedLocations.Length-1]=SlotData.CheckedLocations[id];
		}
	}
	else
	{
		if (hint)
		{
			jsonMessage = "[{`cmd`:`LocationScouts`,`locations`:[" $id $"],`create_as_hint`:2}]";
		}
		else
		{
			jsonMessage = "[{`cmd`:`LocationScouts`,`locations`:[" $id $"]}]";
		}
	}
	
	jsonMessage = Repl(jsonMessage, "`", "\"");
	Client.SendBinaryMessage(jsonMessage);
}

function SendMultipleLocationChecks(array<int> locationArray, optional bool scout, optional bool hint)
{
	local string jsonMessage;
	local int i;
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(PlayerP.Player.Console).SlotData;
		
	if (!scout)
	{
		jsonMessage = "[{`cmd`:`LocationChecks`,`locations`:[";
		for (i = 0; i < locationArray.Length; i++)
		{
			jsonMessage $= locationArray[i];
			DebugMessage("Sending location ID: " $locationArray[i]);
			
			//if (!IsLocationChecked(locationArray[i]))
			//	SlotData.CheckedLocations.AddItem(locationArray[i]);
			if (!CheckArrayForElement(SlotData.CheckedLocations,locationArray[i])){
				SlotData.CheckedLocations.Insert(SlotData.CheckedLocations.Length);
				SlotData.CheckedLocations[SlotData.CheckedLocations.Length-1]=SlotData.CheckedLocations[locationArray[i]];
				}
			
			if (i+1 < locationArray.Length)
				jsonMessage $= ",";
		}
	}
	else
	{
		jsonMessage = "[{`cmd`:`LocationScouts`,`locations`:[";
		for (i = 0; i < locationArray.Length; i++)
		{
			jsonMessage $= locationArray[i];
			if (i+1 < locationArray.Length)
			{
				jsonMessage $= ",";
			}
		}
	}
	
	if (scout && hint)
	{
		jsonMessage $= "],`create_as_hint`:2";
	}
	else
	{
		jsonMessage $= "]";
	}
	
	jsonMessage $= "}]";
	jsonMessage = Repl(jsonMessage, "`", "\"");
	client.SendBinaryMessage(jsonMessage);
}

function ItemSoundTimer()
{
	ItemSoundCooldown = false;
}

function BeatGame()
{
	local JsonObject json;
		
	json = new class'JsonObject';
	json.SetStringValue("cmd", "StatusUpdate");
	json.SetIntValue("status", 30);
	client.SendBinaryMessage(EncodeJson2(json));
	//ScreenMessage("Total Checks: " $SlotData.CheckedLocations.Length $"/"$SlotData.TotalLocations);
	json = None;
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

function bool IsFullyConnected()
{
	return client != None && client.FullyConnected && !client.ConnectingToAP && client.LinkState == STATE_Connected;
}

function bool IsDeathLinkEnabled()
{
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(PlayerP.Player.Console).SlotData;
	return !DeathLinked && SlotData.DeathLink;
}

function bool ReplOnce(
    string str, 
    string match, 
    string withReplacement, 
    out string result, 
    optional bool caseSensitive /* = false */)
{
    local int idx, matchLen;
    local string leftPart, rightPart;
    local string haystack, needle;

    // prepare for case‐insensitive if requested
    if (caseSensitive)
    {
        haystack = str;
        needle   = match;
    }
    else
    {
        haystack = Caps(str);
        needle   = Caps(match);
    }

    // find first occurrence
    idx = InStr(haystack, needle);
    if (idx == -1)
    {
        // no match → return original
        result = str;
        return false;
    }

    matchLen = Len(match);

    // everything *before* the match
    leftPart = Left(str, idx);

    // everything *after* the match
    // InStr/Mid are 0‑based, so skip idx characters + the length of match
    rightPart = Mid(str, idx + matchLen, Len(str) - (idx + matchLen));

    // stitch it back together
    result = leftPart $ withReplacement $ rightPart;
    return true;
}

//Pretty sure VSize is enough for this.
function float GetVectorDistance(Vector start, Vector end)
{
	local float distance;
	distance = Abs(start.x - end.x);
	distance += Abs(start.y - end.y);
	distance += Abs(start.z - end.z);
	return distance;
}

