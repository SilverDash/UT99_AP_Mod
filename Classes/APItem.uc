class APItem extends Inventory
	abstract;

var int LocationId;
var string ItemId;
var int ItemOwner;
var int ItemFlags;

var class<object> InventoryClass;
var string OriginalCollectibleName;

var AP_SlotData Data;


function bool WasFromServer()
{
	return LocationId == 0;
}

function bool IsOwnItem()
{
	return ItemOwner == Data.PlayerSlot;
}

defaultproperties
{

}