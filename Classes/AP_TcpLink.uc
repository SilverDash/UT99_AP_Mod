//Lot's of code credit to CookieCat
//A lot of the work is done but must be backported
class AP_TcpLink extends TcpLink;


var transient array<string> CurrentMessage;
var transient bool ParsingMessage;
var transient bool ConnectingToAP;
var transient bool FullyConnected;
var transient bool Refused;
var transient bool Reconnecting;
var transient int EmptyCount;

var AP_SlotData SlotData;
var AP_ModMutator Mod;
var PlayerPawn PlayerP;


var byte CODE_TEXT_FIN; //129 			// (10000001) - Text frame with FIN bit set (use this for single-fragment text messages)

var byte CODE_CONTINUATION; //0 		// (00000000) - Continuation frame

var byte CODE_PING; // 137               // (10001001) - Ping

var byte CODE_PONG; // 138               // (10001010) - Pong

var byte CODE_TEXT; // 1 				// (00000001) - Text frame (use CODE_CONTINUATION to continue a text message)

var byte CODE_CONTINUATION_FIN;  //128 	// (10000000) - Continuation frame with FIN bit set (ends a multi-fragment message)



/*

var Archipelago_ItemResender ItemResender;
var array<Hat_GhostPartyPlayerStateBase> Buddies; // Online Party co-op support
var array<class<Object> > CachedShopInvs;
var transient int ActMapChangeChapter;
var transient bool ActMapChange;
var transient bool CollectiblesShuffled;
var transient bool ControllerCapsLock;
var transient bool ContractEventActive;
var transient bool ItemSoundCooldown;
var transient bool DeathLinked;
var transient string DebugMsg;*/


const MaxSentMessageLength = 246;

event PostBeginPlay()
{
	CODE_TEXT_FIN = 129;
	CODE_CONTINUATION = 0;
	CODE_PING = 137;
	CODE_PONG = 138;
	CODE_TEXT = 1;
	CODE_CONTINUATION_FIN = 128;

	Connect();
}

Function AP_SlotData GetSlotData()
{
	local PlayerPawn PP;

	foreach AllActors(Class'PlayerPawn', PP)
	{
		if (PP != None)
		{
			return AP_UTConsole(PP.Player.Console).SlotData;
		}
	}
	
}



function Connect()
{
	Log("TCPLINK Connect");
	SlotData = GetSlotData();
	GetMutator();
	if (FullyConnected || ConnectingToAP || LinkState == STATE_Connecting)
		return;
	
	ReceiveMode = RMODE_Manual;
	LinkMode = MODE_Line;
	
	Level.Game.BroadcastMessage("Connecting to the Unreal Tournament AP Client");
	
    Resolve("localhost");
}

event Resolved(IpAddr Addr)
{
	Log("TCPLINK Resolved");
	StringToIpAddr("localhost", Addr);
    Addr.Port = 2341;
    BindPort();
	
	Level.Game.BroadcastMessage("Opening connection...");
    if (!Open(Addr))
    {
	    Level.Game.BroadcastMessage("Failed to open connection to localhost:2341");

		Close();
		Connect();
    }
}

function TimedOut()
{
	if (!FullyConnected && !ConnectingToAP)
	{
		Log("TCPLINK TimedOut");
		Level.Game.BroadcastMessage("Connection attempt timed out. Is the Unreal Tournament AP Client running?");
		Close();
		Connect();
	}
}

event ResolveFailed()
{
	Log("TCPLINK ResolveFailed");
    Level.Game.BroadcastMessage("Unable to resolve localhost:11311. Retrying...");
	Close();
	Connect();
}

event Opened()
{
	local string crlf;
	Log("TCPLINK OPENED");
	SlotData = GetSlotData();
	
	crlf = chr(13)$chr(10);
	Level.Game.BroadcastMessage("Opened connection, sending HTTP request...");
	
	SendText("GET / HTTP/1.1" $crlf
	$"Host: " $SlotData.Host $crlf
	$"Connection: keep-alive, Upgrade" $crlf
	$"Upgrade: websocket" $crlf
	$"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" $crlf
	$"Sec-WebSocket-Version: 13" $crlf
	$"Accept: /" $crlf);
	LinkMode = MODE_Binary;

	Level.Game.BroadcastMessage("Connected to Unreal Touranement Client, awaiting room information from server... (connect the Unreal Touranement AP client to the server if you haven't)");
}

//un-used.
function ConnectToAP()
{
	local JsonObject json;
	local JsonObject jsonVersion;
	local string message, slotName;
	
	if (FullyConnected)
		return;
	
	ConnectingToAP = true;
	CurrentMessage.Length = 0;
	
	// This Connect packet isn't actually sent to the server itself, but is used by the AP client
	json = new class'JsonObject';
	json.SetStringValue("cmd", "Connect");
	json.SetStringValue("game", "Unreal Tournament");

	slotName = SlotData.SlotName;
	slotName = Repl(slotName, "\"", "\\\"", false);
	json.SetStringValue("name", slotName);
	json.SetStringValue("password", SlotData.Password);
	json.SetStringValue("uuid", "");
	json.SetStringValue("seed_name", SlotData.SeedName); // Used by AP client for verification.
	
	json.SetIntValue("items_handling", 7);
	json.SetBoolValue("slot_data", !SlotData.Initialized);
	
	jsonVersion = new class'JsonObject';
	jsonVersion.SetStringValue("major", "0");
	jsonVersion.SetStringValue("minor", "6");
	jsonVersion.SetStringValue("build", "1");
	jsonVersion.SetStringValue("class", "Version");
	json.SetObject("version", jsonVersion);
	
	if (SlotData.DeathLink)
	{
		json.SetStringValue("tags", "[\"DeathLink\", \"AP\"]");
	}
	else
	{
		json.SetStringValue("tags", "[\"AP\"]");
	}
	
	// remove "" from tags array
	message = EncodeJson2(json);
	message = Repl(message, "\"[", "[");
	message = Repl(message, "]\"", "]");
	
	SendBinaryMessage(message);
	json = None;
	jsonVersion = None;
}

// Archipelago requires JSON messages to be encased in []
function string EncodeJson2(JsonObject json)
{
	local string message;
	message = "["$class'JsonObject'.static.EncodeJson(json)$"]";
	return message;
}

event Tick(float d)
{
	local byte byteMessage[255];
	local int count, i, a, k, bracket, attempts;
	local string character, pong, msg, nullChar;
	local bool b, validMsg;
	
	Super.Tick(d);
	
	if (LinkState != STATE_Connected || LinkMode != MODE_Binary)
		return;
	
	// We can only read 255 bytes from the socket at a time.
	// IsDataPending ALWAYS returns true if we're connected, even if there isn't any data pending on the socket
	while (EmptyCount <= 5 && attempts <= 20)
	{
		attempts++;
		count = ReadBinary(255, byteMessage);
		
		if (count <= 0)
		{
			if (ParsingMessage)
				EmptyCount++;
			
			break;
		}
		else
		{
			EmptyCount = 0;
			
			// Check for a ping
			if (!ParsingMessage && count <= 10)
			{
				for (i = 0; i < count; i++)
				{
					// UnrealScript doesn't allow null characters in strings, so we need to do this crap
					if (byteMessage[i] == byte(0))
					{
						if (nullChar != "")
						{
							msg $= nullChar;
							continue;
						}
						
						for (a = 33; a <= 255; a++)
						{
							b = false;
							
							for (k = 0; k < count; k++)
							{
								if (byteMessage[k] == byte(a))
								{
									b = true;
									break;
								}
							}
							
							if (!b)
							{
								nullChar = Chr(a);
								msg $= nullChar;
								break;
							}
						}
						
						continue;
					}
					
					msg $= Chr(byteMessage[i]);
				}
				
				for (i = 0; i < Len(msg); i++)
				{
					if (Asc(Mid("a"$msg, i, 1)) == CODE_PING)
					{
						// Need to send the same data back as a pong
						// This is a dumb way to do it, but whatever works.
						pong = Mid(msg, InStr(msg, Chr(CODE_PING)));
						pong = Mid(pong, 2);
						SendBinaryMessage(pong, false, true, nullChar);
						break;
					}
				}
				
				if (pong != "")
					return;
			}
			//todo: fix the insert lines on each of these arrays
			for (i = 0; i < count; i++)
			{
				character = Chr(byteMessage[i]);
				CurrentMessage.insert(CurrentMessage.Length);
				CurrentMessage[CurrentMessage.Length-1] = character;
				
				if (character == "[")
				{
					if (!ParsingMessage)
					{
						CurrentMessage.Length = 0;
						ParsingMessage = true;
					}
				}
			}
		}
	}
	
	if (ParsingMessage)
	{
		if (EmptyCount > 5)
		{
			// We've got a JSON message, parse it
			msg = "";
			
			for (i = 0; i < CurrentMessage.Length; i++)
			{
				if (CurrentMessage[i] == "{")
				{
					if (!validMsg && CurrentMessage[i+1] == "\"")
						validMsg = true;
					
					if (validMsg)
						bracket--;
				}
				else if (validMsg && CurrentMessage[i] == "}")
				{
					bracket++;
				}
				
				if (validMsg)
				{
					msg $= CurrentMessage[i];
					if (bracket >= 0)
					{
						ParseJSON(msg);
						msg = "";
						validMsg = false;
						bracket = 0;
					}
				}
			}
			
			CurrentMessage.Length = 0;
			ParsingMessage = false;
			EmptyCount = 0;
		}
	}
}

function GetMutator()
{
	local AP_ModMutator mute;
	ForEach AllActors(class'AP_ModMutator', mute)
	{
		if(mute != None)
		{
			mod = mute;
		}
	}
}


function ParseJSON(string json)
{
	local bool b;
	local Name msgType;
	local int i, a, count, pos, locId, count1, count2;
	local array<int> missingLocs;
	local string s, text, num, json2, player;
	local JsonObject jsonObj, jsonChild, textObj;
	
	if (Len(json) <= 10) // this is probably garbage that we thought was a json
		return;
	
	// remove garbage at start and end of string
	for (i = 0; i < Len(json); i++)
	{
		if (Mid(json, i, 2) == "{\"")
		{
			json = Mid(json, i);
			break;
		}
	}
	
	Mod.DebugMessage("[ParseJSON] Received command: " $json);
	
	// UnrealScript's JSON parser does not like []
	json = Repl(json, "[{", "{");
	json = Repl(json, "}]", "}");
	
	// Dumb, but fixes the incorrect player slot being assigned
	if (InStr(json, "Connected") != -1)
	{
		Mod.ReplOnce(json, "slot", "my_slot", json);
	}
	
	Mod.DebugMessage("[ParseJSON] Reformatted command: " $json);
	if (InStr(json, "\"RoomInfo\"") == -1 && InStr(json, "\"Connected\"") == -1)
	{
		// Security
		for (i = 0; i < Len(json); i++)
		{
			if (Mid(json, i, 1) == "{")
				count1++;
			else if (Mid(json, i, 1) == "}")
				count2++;
		}
		
		if (count1 != count2)
		{
			Mod.DebugMessage("[ParseJSON] [WARNING] Encountered JSON message with mismatching braces. Cancelling to prevent crash!");
			return;
		}
	}
	
	jsonObj = new class'JsonObject';
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
	{
		Mod.DebugMessage("[ParseJSON] Failed to parse JSON: " $json);
		return;
	}
	
	switch (jsonObj.GetStringValue("cmd"))
	{
		case "RoomInfo":
			Mod.DebugMessage("Received RoomInfo packet, sending Connect packet...");
			//ConnectToAP();
			break;
		
		case "Connected":
			Mod.OnPreConnected();
			
			
			Mod.ScreenMessage("Successfully connected to AP Client (" $SlotData.Host $":"$SlotData.Port $")");
			
			Reconnecting = false;
			SlotData.PlayerSlot = jsonObj.GetIntValue("my_slot");
			SlotData.SlotName = jsonObj.GetStringValue("name");
			FullyConnected = true;
			ConnectingToAP = false;
			
			if (!SlotData.Initialized)
			{
				jsonChild = jsonObj.GetObject("slot_data");
				Mod.LoadSlotData(jsonChild);
			}
			
			// If we have checked locations that haven't been sent for some reason, send them now
			pos = InStr(json, "\"missing_locations\":[");
			if (pos != -1)
			{
				pos += len("\"missing_locations\":[");
				num = "";
				
				for (i = pos; i < len(json); i++)
				{
					s = Mid(json, i, 1);
					if (s == "]")
						break;
					
					if (len(num) > 0 && s == ",")
					{
						locId = int(num);
						for (a = 0; a < SlotData.LocationInfoArray.Length; a++)
						{
							if (SlotData.LocationInfoArray[a].ID == locId)
							{
								if (Mod.CheckArrayForElement(SlotData.CheckedLocations,locId))
									missingLocs.Insert(missingLocs.Length);
									missingLocs[missingLocs.Length-1]=locId;
								
								break;
							}
						}
						
						num = "";
					}
					else if (s != "," && s != "[")
					{
						num $= s;
					}
				}
			}
			
			pos = InStr(json, "\"checked_locations\":[");
			if (pos != -1)
			{
				pos += len("\"checked_locations\":[");
				num = "";
				
				for (i = pos; i < len(json); i++)
				{
					s = Mid(json, i, 1);
					if (s == "]")
						break;
					
					if (len(num) > 0 && s == ",")
					{
						locId = int(num);
						if (!Mod.CheckArrayForElement(SlotData.CheckedLocations,locId) && !Mod.CheckArrayForElement(missingLocs,locId))
						{
							SlotData.CheckedLocations.insert(SlotData.CheckedLocations.Length);
							SlotData.CheckedLocations[SlotData.CheckedLocations.Length-1]=locId;
						}
						
						num = "";
					}
					else if (s != "," && s != "[")
					{
						num $= s;
					}
				}
			}
			
			if (missingLocs.Length > 0)
			{
				Mod.DebugMessage("Sending missing locations");
				Mod.SendMultipleLocationChecks(missingLocs);
			}
			
			if (!SlotData.PlayerNamesInitialized)
			{
				// Initialize our player's names
				Mod.ReplOnce(json, "players", "players_0", json, true);
				b = true;
				count = 0;
				
				while (b)
				{
					if (Mod.ReplOnce(json, ",{", ",\"players_"$count+1 $"\":{", s, false))
					{
						json = s;
						count++;
					}
					else
					{
						b = false;
					}
				}
				
				jsonObj = class'JsonObject'.static.DecodeJson(json);
				for (i = 0; i <= count; i++)
				{
					jsonChild = jsonObj.GetObject("players_"$i);
					if (jsonChild == None)
						continue;
						
					SlotData.PlayerNames[jsonChild.GetIntValue("slot")] = jsonChild.GetStringValue("alias");
					if (jsonChild.GetIntValue("slot") == SlotData.PlayerSlot)
					{
						SlotData.SlotName = jsonChild.GetStringValue("name");
					}
				}
				
				SlotData.PlayerNamesInitialized = true;
			}
			
			if (SlotData.DeathLink)
			{
				json2 = "[{`cmd`: `ConnectUpdate`, `tags`: [`DeathLink`]}]";
				json2 = Repl(json2, "`", "\"");
				SendBinaryMessage(json2);
			}
			
			// Fully connected
			Mod.OnFullyConnected();
			break;
			
			
		case "PrintJSON":
			if (jsonObj.GetStringValue("type") == "Join")
			{
				if (InStr(json, ""$SlotData.SlotName$" ") != -1)
					break;
			}
			
			Mod.ReplOnce(json, "\"data\"", "\"0\"", json);
			
			for (i = 0; i < Len(json); i++)
			{
				if (Mid(json, i, 3) == "},{")
				{
					Mod.ReplOnce(json, "},{", 
						"}," $"\"" $a+1 $"\"" $":{", json);
					
					a++;
				}
			}
			
			jsonChild = class'JsonObject'.static.DecodeJson(json);
			if (jsonChild == None)
				break;
				
			for (i = 0; i <= a; i++)
			{
				textObj = jsonChild.GetObject(string(i));
				if (textObj == None)
					continue;
				
				switch (textObj.GetStringValue("type"))
				{
					case "player_id":
						player = Mod.PlayerIDToName(int(textObj.GetStringValue("text")));

						if (player == SlotData.SlotName)
							msgType = 'Warning';
						
						text $= player;
						break;
					
					/*
					case "item_id":
						text $= Mod.ItemIDToName(textObj.GetStringValue("text"));
						break;
					
					case "location_id":
						text $= Mod.LocationIDToName(textObj.GetStringValue("text"));
						break;
					*/
					
					default:
						text $= textObj.GetStringValue("text");
						break;
				}
			}
			
			if (InStr(text, "Now that you are connected") != -1)
				break;
			
			Mod.ScreenMessage(text, msgType);
			break;
			
			
		case "ConnectionRefused":
			ConnectingToAP = false;
			Mod.ScreenMessage("Connection refused by server. Check to make sure your slot name, password, etc. are correct.");
			Refused = true;
			Close();
			break;
		
		
		case "ReceivedItems":
			OnReceivedItemsCommand(json);
			break;
		
		
		case "LocationInfo":
			OnLocationInfoCommand(json);
			break;
		
		
		case "Bounced":
			OnBouncedCommand(json);
			break;


		case "Retrieved":
			OnRetrievedCommand(json);
			break;
			
		
		case "RoomUpdate":
			// Paste-a la CTRL+Vista baby.
			// I'm not sorry. Please help me.
			pos = InStr(json, "\"checked_locations\":[");
			if (pos != -1)
			{
				pos += len("\"checked_locations\":[");
				num = "";
				
				for (i = pos; i < len(json); i++)
				{
					s = Mid(json, i, 1);
					if (s == "]")
						break;
					
					if (len(num) > 0 && s == ",")
					{
						locId = int(num);
						if (!Mod.CheckArrayForElement(SlotData.CheckedLocations,locId))
						{
							SlotData.CheckedLocations.insert(SlotData.CheckedLocations.Length);
							SlotData.CheckedLocations[SlotData.CheckedLocations.Length-1]=locId;
						}
						
						num = "";
					}
					else if (s != "," && s != "[")
					{
						num $= s;
					}
				}
			}
			
			SlotData.APSaveConfig();
			break;
		
			
		default:
			break;
	}

	jsonObj = None;
	jsonChild = None;
	textObj = None;
}

function OnLocationInfoCommand(string json)
{
	local AP_ModMutator.LocationInfo locInfo;
	local bool isItem;
	local int i, locId, count, flags;
	local string s, mapName, itemId;
	local JsonObject jsonObj, jsonChild;
	local APItem item;


	local Actor container;

		

	Mod.ReplOnce(json, "locations", "locations_0", json, true);
	count = 0;
	
	while (Mod.ReplOnce(json, ",{", ",\"locations_" $count+1 $"\":{", s, false))
	{
		json = s;
		count++;
	}
	
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	
	for (i = 0; i <= count; i++)
	{
		jsonChild = jsonObj.GetObject("locations_"$i);
		if (jsonChild == None)
			continue;
		
		locId = jsonChild.GetIntValue("location");

	}
	
	jsonObj = None;
	jsonChild = None;
}

function OnReceivedItemsCommand(string json)
{
	local int count, serverIndex, index, total, i, start, item;
	local string s;
	local JsonObject jsonObj, jsonChild;
	local bool b;
	

	Mod.ReplOnce(json, "items", "items_0", json, true);
	b = true;
	count = 0;
	
	while (b)
	{
		if (Mod.ReplOnce(json, ",{", ",\"items_"$count+1 $"\":{", s, false))
		{
			json = s;
			count++;
		}
		else
		{
			b = false;
		}
	}
	
	Mod.DebugMessage("Receiving items... "$json);
	jsonObj = class'JsonObject'.static.DecodeJson(json);
	index = SlotData.GetLastItemIndex();
	serverIndex = jsonObj.GetIntValue("index");
	
	// This means we are reconnecting to a previous session, and the server is giving us our entire list of items,
	// so we need to begin from the next new item in our list or don't give anything otherwise
	Mod.DebugMessage("serverIndex: "$serverIndex);
	Mod.DebugMessage("index: "$index);
	if (serverIndex == 0 && index > 0)
	{
		if (index > count)
		{
			jsonObj = None;
			return;
		}
		else
		{
			start = index;
		}	
	}
	else
	{
		start = 0;
	}
	
	Mod.DebugMessage("start: "$start);
	for (i = start; i <= count; i++)
	{
		jsonChild = jsonObj.GetObject("items_"$i);
		if (jsonChild != None)
		{
			// this should absolutely never be a 64 bit integer, so we can safely pass as an int
			item = jsonChild.GetIntValue("item");
			if (item > 0)
			{
				GrantItem(item);
				total++;
			}
		}
	}
	
	jsonObj = None;
	jsonChild = None;
}

function GrantItem(int itemId)
{
	local class<Actor> worldClass, invOverride;
	local APItem item;
	local Pawn player;

	
	
}

function OnBouncedCommand(string json)
{
	local JsonObject jsonObj, jsonChild;
	local string cause, msg, source;




	jsonObj = class'JsonObject'.static.DecodeJson(json);
	if (jsonObj == None)
		return;
	
	jsonChild = jsonObj.GetObject("data");
	if (jsonChild != None && Mod.IsDeathLinkEnabled())
	{
		source = jsonChild.GetStringValue("source");
		if (source != "" && source != SlotData.SlotName)
		{
			Mod.DeathLinked = true;
		
			msg = "You were Killed by: " $source;
			cause = jsonChild.GetStringValue("cause");
			if (cause != "")
				msg $= " (" $cause $")";
			
				Level.Game.BroadcastMessage(msg);
		}
	}
	
	jsonObj = None;
	jsonChild = None;
}

function OnRetrievedCommand(string json)
{

	local int pos, i, v;
	local string s;
	local bool b;
	local JsonObject jsonObj, jsonChild;
	

	jsonObj = None;
	jsonChild = None;
}

function SendBinaryMessage(string message, optional bool continuation, optional bool pong, optional string nullChar)
{
	local byte byteMessage[255];
	local string buffer;
	local int length, offset, keyIndex, i, totalSent;
	local int maskKey[4];
	
	for (i = 0; i < 4; i++)
	{
		maskKey[i] = RandRange(1, 2147483647);
	}
	
	length = Len(message);
	
	// If the length is bigger than this, we must split our message into multiple fragments, as SendBinary() can only send 255 bytes at a time.
	if (length > MaxSentMessageLength)
	{
		buffer = Mid(message, 0, MaxSentMessageLength);
		totalSent = MaxSentMessageLength;
		
		if (!continuation) // start our continuation message
		{
			byteMessage[0] = CODE_TEXT;
		}
		else // continue our message
		{
			byteMessage[0] = CODE_CONTINUATION;
		}
	}
	else
	{
		buffer = message;
		totalSent = length;
		
		if (pong)
		{
			byteMessage[0] = CODE_PONG;
		}
		else if (continuation) // End our continuation message
		{
			byteMessage[0] = CODE_CONTINUATION_FIN;
		}
		else
		{
			byteMessage[0] = CODE_TEXT_FIN;
		}
	}
	
	offset = 0;
	
	if (totalSent <= 125)
	{
		byteMessage[1] = 128+totalSent;
	}
	else
	{
		offset = 2;
		byteMessage[1] = 128+126;
		byteMessage[2] = (totalSent >> 8) & 255;
		byteMessage[3] = totalSent & 255;
	}
	
	byteMessage[2+offset] = maskKey[0];
	byteMessage[3+offset] = maskKey[1];
	byteMessage[4+offset] = maskKey[2];
	byteMessage[5+offset] = maskKey[3];
	
	offset = offset+6;
	for (i = offset; i < totalSent+offset; i++)
	{
		// null character
		if (pong && nullChar != "" && Mid(buffer, i-offset, 1) == nullChar)
		{
			byteMessage[i] = byte(0) ^ maskKey[keyIndex];
		}
		else
		{
			byteMessage[i] = Asc(Mid(buffer, i-offset, 1)) ^ maskKey[keyIndex];
		}
		
		keyIndex++;
		if (keyIndex > 3)
			keyIndex = 0;
	}
	
	SendBinary(offset+totalSent, byteMessage);
	
	if (byteMessage[0] == CODE_TEXT || byteMessage[0] == CODE_CONTINUATION)
	{
		SendBinaryMessage(Mid(message, Len(buffer)), true);
	}
}

event Closed()
{
	Log("TCPLINK Closed");
	if (!Refused)
	{
		if (SlotData.ConnectedOnce)
				Level.Game.BroadcastMessage("Connection was closed. Reconnecting in 5 seconds...");

		Refused = false;
	}
	
	CurrentMessage.Length = 0;
	EmptyCount = 0;
	ParsingMessage = false;
	FullyConnected = false;
	ConnectingToAP = false;
	Reconnecting = true;
}

event Destroyed()
{
	Close();
	Super.Destroyed();
}



defaultproperties
{
    Host="localhost";
    Port=11311;
	bAlwaysTick = true;
}