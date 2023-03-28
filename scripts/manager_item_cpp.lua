function onInit()
	-- This doesn't evne work, because the event that's raised doesn't include the 
	-- data for the item that was just added to a parcel. Only the parcel itself.
	--ItemManager.registerPostTransferHandler(onItemTransfer);
end

function onDesktopInit()
end

function onItemTransfer(rSource, rTarget)
	-- Handle automatically rolling levels for cyphers
	if rSource.sType == "item" and rTarget.sType == "treasureparcel" then
		local bCypher = DB.getValue(rSource.node, "type", "") == "cypher";
		local sLevelRoll = DB.getValue(rSource.node, "levelroll", "");
		local nLevel = DB.getValue(rSource.node, "level", 0);

		-- Only roll for cyphers with a valid level roll string and a level that's not already set
		if bCypher and StringManager.isDiceString(sLevelRoll) and nLevel == 0 then
			nLevel = StringManager.evalDiceString(sLevelRoll, true);
			--DB.setValue(rSource.node, "level", "number", nLevel);
		end
	end
end