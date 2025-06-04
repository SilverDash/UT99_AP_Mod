class AP_ModMenuItem extends UMenuModMenuItem;

function Setup()
{
    MenuCaption="Archipelago";
    MenuHelp="Start an Archipelago run";
}

function Execute()
{
   MenuItem.Owner.Root.CreateWindow(Class<UWindowFramedWindow>(DynamicLoadObject("Archipelago.AP_StartWindow", class'Class')),20,20,200,200);
}


