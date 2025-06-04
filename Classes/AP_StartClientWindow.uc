class AP_StartClientWindow extends UWindowDialogClientWindow
Config(Archipelago);

// Window
var UMenuPageControl Pages;
var UWindowSmallCloseButton CloseButton;
var UWindowSmallButton StartNewButton;
var UWindowSmallButton LoadButton;
var UMenuScreenshotCW ScreenshotWindow;


var localized string StartMatchTab;
var localized string StartText;

var UWindowEditControl AP_Port;
var UWindowEditControl AP_IP;

var UwindowEditControl AP_SlotName;
var UwindowEditControl AP_Password;
var AP_ModMutator GameMod;


function Created()
{
    local class<UWindowPageWindow> PageClass;
	local LevelInfo Entry;
	local float ControlWidth, ControlLeft, ControlRight,CenterWidth,CenterPos,ButtonWidth,ButtonLeft,ControlOffset;

    //Dirty
	Entry = Root.Console.ViewPort.Actor.GetEntryLevel();
	if(GameMod == None)
	{
		GameMod = Entry.Spawn(class'AP_ModMutator');
	}
	
    Super.Created();
    SetSize(300, 350);
    WinWidth=300;
    WinHeight=350;
    CloseButton = UWindowSmallCloseButton(CreateWindow(class'UWindowSmallCloseButton', WinWidth-56, 308, 48, 16));

	StartNewButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', WinWidth-106, WinHeight-24, 48, 16));
	StartNewButton.SetText("Start New Run");
	StartNewButton.SetFont(F_Bold);
	StartNewButton.Align = TA_Right;

    LoadButton = UWindowSmallButton(CreateControl(class'UWindowSmallButton', WinWidth-126, WinHeight-24, 48, 16));
	LoadButton.SetText("Continue Run");
	LoadButton.SetFont(F_Bold);
	LoadButton.Align = TA_Right;


    ControlWidth = WinWidth/2.5;
	ControlLeft = (WinWidth/2 - ControlWidth)/2;
	ControlRight = WinWidth/2 + ControlLeft;

	CenterWidth = (WinWidth/4)*3;
	CenterPos = (WinWidth - CenterWidth)/2;

	ButtonWidth = WinWidth - 140;
	ButtonLeft = WinWidth - ButtonWidth - 40;


	AP_Port = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, ControlWidth, 1));
	AP_Port.SetText("Archipelago Port");
	AP_Port.SetFont(F_Normal);
	AP_Port.SetNumericOnly(True);
	AP_Port.SetMaxLength(8);
	AP_Port.Align = TA_Right;
    ControlOffset += 25;

	AP_SlotName = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, ControlWidth, 1));
	AP_SlotName.SetText("Slot Name");
	AP_SlotName.SetFont(F_Normal);
	AP_SlotName.SetMaxLength(99);
	AP_SlotName.Align = TA_Right;
    ControlOffset += 25;

	AP_Password = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, ControlWidth, 1));
	AP_Password.SetText("Archipelago Password");
	AP_Password.SetFont(F_Normal);
	AP_Password.SetMaxLength(99);
	AP_Password.Align = TA_Right;
    ControlOffset += 25;

	AP_IP = UWindowEditControl(CreateControl(class'UWindowEditControl', ControlLeft, ControlOffset, ControlWidth, 1));
	AP_IP.SetText("Archipelago IP");
	AP_IP.SetFont(F_Normal);
	AP_IP.SetNumericOnly(True);
	AP_IP.SetMaxLength(99);
	AP_IP.Align = TA_Right;

}

function WindowEvent(WinMessage Msg, Canvas C, float X, float Y, int Key) 
{
	if (Key == GetPlayerOwner().EInputKey.IK_Enter)
	{	
		switch(Msg)
		{
		case WM_KeyDown:
		case WM_KeyUp:
		case WM_KeyType:
			bHandledEvent = true;
			return;
		}
	}
	Super.WindowEvent(Msg, C, X, Y, Key);
}

function Resized()
{
	CloseButton.WinLeft = WinWidth-52;
	CloseButton.WinTop = WinHeight-20;

	LoadButton.WinLeft = WinWidth-52;
	LoadButton.WinTop = WinHeight-20;
	StartNewButton.WinLeft = WinWidth-102;
	StartNewButton.WinTop = WinHeight-20;
}

function IPChanged()
{
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(GetPlayerOwner().Player.Console).SlotData;
	SlotData.Host = AP_IP.GetValue();
    SaveConfigs();
}

function PortChanged()
{
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(GetPlayerOwner().Player.Console).SlotData;
	SlotData.Port = int(AP_Port.GetValue());
    SaveConfigs();
}

function SlotNameChanged()
{
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(GetPlayerOwner().Player.Console).SlotData;
	SlotData.slotName = AP_SlotName.GetValue();
    SaveConfigs();
}

function PasswordChanged()
{
	local AP_SlotData SlotData;
	SlotData = AP_UTConsole(GetPlayerOwner().Player.Console).SlotData;
	SlotData.Password = AP_Password.GetValue();
    SaveConfigs();
}

function Paint(Canvas C, float X, float Y)
{
	local Texture T;

	T = GetLookAndFeelTexture();
	DrawUpBevel( C, 0, LookAndFeel.TabUnselectedM.H, WinWidth, WinHeight-LookAndFeel.TabUnselectedM.H, T);
}

function Notify(UWindowDialogControl C, byte E)
{
	Super.Notify(C, E);

	switch(E)
	{
    case DE_Change:
        Switch(C)
        {
        case AP_IP:
            IPChanged();
            break;
        case AP_Port:
            PortChanged();
            break;
		case AP_SlotName:
            SlotNameChanged();
            break;
        case AP_Password:
            PasswordChanged();
            break;
        }
	case DE_Click:
		switch (C)
		{
		case StartNewButton:
			GetPlayerOwner().ClientTravel( "UT-Logo-Map.unr?Game=Archipelago.StartNewGame?Mutator=Archipelago.AP_ModMutator", TRAVEL_Absolute, True );
			break;
        case LoadButton:
			GetPlayerOwner().ClientTravel( "UT-Logo-Map.unr?Game=Archipelago.LoadGame?Mutator=Archipelago.AP_ModMutator", TRAVEL_Absolute, True );
			break;
		}
	}
}

function SaveConfigs()
{
	local AP_SlotData SlotData;
	
	SlotData = AP_UTConsole(GetPlayerOwner().Player.Console).SlotData;
	SlotData.APSaveConfig();
	Super.SaveConfigs();
}

defaultproperties
{
}
