class APDMLadder extends APLadder;

function Created()
{
	Super.Created();

	if (LadderObj.DMPosition == -1) {
		LadderObj.DMPosition = 1;
		SelectedMatch = 0;
	} else {
		SelectedMatch = LadderObj.DMPosition;
	}
	SetupLadder(LadderObj.DMPosition, LadderObj.DMRank);

	if (class'UTLadderStub'.Static.IsDemo())
		RequiredRungs = 4;
}

function FillInfoArea(int i)
{
	MapInfoArea.Clear();
	if ( (LadderObj.CurrentLadder.Default.DemoDisplay[i] == 1) ||
		(class'UTLadderStub'.Static.IsDemo() && !class'UTLadderStub'.Static.DemoHasTuts() && i == 0) )
		MapInfoArea.AddText(NotAvailableString);
	MapInfoArea.AddText(MapText$" "$LadderObj.CurrentLadder.Static.GetMapTitle(i));
	MapInfoArea.AddText(FragText$" "$LadderObj.CurrentLadder.Static.GetFragLimit(i));
	MapInfoArea.AddText(LadderObj.CurrentLadder.Static.GetDesc(i));
}

function NextPressed()
{
	local APEnemyBrowser EB;
	local string MapName;

	if (PendingPos > ArrowPos)
		return;

	if (SelectedMatch == 0)
	{
		MapName = LadderObj.CurrentLadder.Default.MapPrefix$Ladder.Static.GetMap(0);
		if (class'UTLadderStub'.Static.IsDemo())
		{
			if (class'UTLadderStub'.Static.DemoHasTuts())
			{
				CloseUp();
				StartMap(MapName, 0, "Botpack.TrainingDM");
			}
		} else {
			CloseUp();
			StartMap(MapName, 0, "Botpack.TrainingDM");
		}
	} else {
		HideWindow();
		LOG("NEXT PRESSED FROM APDMLADDER");
		EB = APEnemyBrowser(Root.CreateWindow(class'APEnemyBrowser', 100, 100, 200, 200, Root, True));
		EB.LadderWindow = Self;
		EB.Ladder = LadderObj.CurrentLadder;
		EB.Match = SelectedMatch;
		EB.GameType = GameType;
		EB.Initialize();
	}
}

function StartMap(string StartMap, int Rung, string GameType)
{
	local Class<GameInfo> GameClass;
	LOG("START MAP FROM APDMLADDER"@StartMap@Rung@GameType);
	GameClass = Class<GameInfo>(DynamicLoadObject(GameType, Class'Class'));
	GameClass.Static.ResetGame();
	LOG("GAMECLASS"@GameClass);
	StartMap = StartMap
				$"?Game="$GameType
				$"?Mutator=Archipelago.AP_ModMutator"
				$"?Tournament="$Rung
				$"?Name="$GetPlayerOwner().PlayerReplicationInfo.PlayerName
				$"?Team=255";
	LOG("START MAP ARGS:"@StartMap);
	Root.Console.CloseUWindow();
	if ( TournamentGameInfo(GetPlayerOwner().Level.Game) != None )
		TournamentGameInfo(GetPlayerOwner().Level.Game).LadderTransition(StartMap);
	else
		GetPlayerOwner().ClientTravel(StartMap, TRAVEL_Absolute, True);
}

function EvaluateMatch(optional bool bTrophyVictory)
{
	local int Pos;
	local string MapName;

	if (LadderObj.PendingPosition > LadderObj.DMPosition)
	{
		if (class'UTLadderStub'.Static.IsDemo() && LadderObj.PendingPosition > 4)
		{
			PendingPos = 4;
		} else {
			PendingPos = LadderObj.PendingPosition;
			LadderObj.DMPosition = LadderObj.PendingPosition;
		}
	}
	if (LadderObj.PendingRank > LadderObj.DMRank)
	{
		LadderObj.DMRank = LadderObj.PendingRank;
		LadderObj.PendingRank = 0;
	}
	LadderPos = LadderObj.DMPosition;
	LadderRank = LadderObj.DMRank;
	if (LadderObj.DMRank == 6)
		Super.EvaluateMatch(True);
	else
		Super.EvaluateMatch();
}

function CheckOpenCondition()
{
	if (class'UTLadderStub'.Static.IsDemo())
	{
		if (LadderObj.DMRank == 4)
		{
			PendingPos = -1;
			BackPressed();
		}
	} else
		Super.CheckOpenCondition();
}

defaultproperties
{
	GameType="Botpack.DeathMatchPlus"
	LadderName="Deathmatch"
	Ladder=class'Archipelago.LadderAPDM'
	DemoLadder=class'Botpack.LadderDMDemo'
	GOTYLadder=class'Archipelago.LadderAPDMGOTY'
	TrophyMap="EOL_DeathMatch.unr"
	LadderTrophy=TrophyDM
}