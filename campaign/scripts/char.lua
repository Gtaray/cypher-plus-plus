function onDrop(x, y, draginfo)
	if not draginfo.isType("shortcut") then
		return;
	end

	local sClass, sNodeName = draginfo.getShortcutData();
	local abilityNode = draginfo.getDatabaseNode();

	if not abilityNode then
		return;
	end
	if sClass ~= "reference_ability" then
		return;
	end

	return CharManagerCPP.addAbilityToCharacter(getDatabaseNode(), abilityNode);
end