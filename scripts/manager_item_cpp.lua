function onInit()
	ItemManager.registerCleanupTransferHandler(onItemTransfer);
end

function onItemTransfer(rSource, rTemp, rTarget)
	if not ItemManagerCPP.isItemCypher(rTemp.node) then
		return;
	end
	-- Handle automatically rolling levels for cyphers
	if rSource.sType == "item" and (rTarget.sType == "treasureparcel" or rTarget.sType == "charsheet") then
		ItemManagerCPP.generateCypherLevel(rTemp.node);
	end
end

function isItemCypher(itemNode)
	return DB.getValue(itemNode, "type", "") == "cypher";
end

function generateCypherLevel(itemNode)
	local sLevelRoll = DB.getValue(itemNode, "levelroll", "");
	local nLevel = DB.getValue(itemNode, "level", 0);

	if StringManager.isDiceString(sLevelRoll) and nLevel == 0 then
		nLevel = StringManager.evalDiceString(sLevelRoll, true);
		DB.setValue(itemNode, "level", "number", nLevel);

		return nLevel;
	end

	return 0;
end