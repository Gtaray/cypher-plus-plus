function addAbilityToCharacter(nodeChar, nodeAbility)
	if not nodeChar then return false end
	if not nodeAbility then return false end

	local abilityList = DB.getChild(nodeChar, "abilitylist");
	if not abilityList then return false end;

	local newNode = DB.createChild(abilityList);
	DB.copyNode(nodeAbility, newNode);

	return true;
end