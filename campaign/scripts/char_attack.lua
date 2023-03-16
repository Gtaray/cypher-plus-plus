function onInit()
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "type"), "onUpdate", onAttackTypeUpdated);

	update();
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "type"), "onUpdate", onAttackTypeUpdated);
end

function onAttackTypeUpdated()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	equipped.setVisible(sType ~= "magic");
end

function update()
	onAttackTypeUpdated();
end

function toggleDetail()
	Interface.openWindow("attack_editor", getDatabaseNode());
end

function onEquippedChanged()
	local bEquipped = equipped.getValue() == 1;

	if bEquipped then
		local nodeActor = windowlist.window.getDatabaseNode();
		ActorManagerCPP.setEquippedWeapon(nodeActor, getDatabaseNode())
	end
end

function actionAttack(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);

	local rAction = {};
	rAction.label = DB.getValue(nodeAction, "name", "");
	rAction.sAttackRange = DB.getValue(nodeAction, "atkrange", "");
	rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "stat", ""));
	rAction.sTraining = DB.getValue(nodeAction, "training", "");
	rAction.nAsset = DB.getValue(nodeAction, "asset", 0);
	rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);
	rAction.nLevel = DB.getValue(nodeAction, "level", 0);
	rAction.nCost = DB.getValue(nodeAction, "cost", 0);
	rAction.sCostStat = rAction.sStat; -- Might be a limitation, but right now the attack/damage all uses the same stat

	ActionAttackCPP.performRoll(draginfo, rActor, rAction)
end

function actionDamage(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);

	local rAction = {};
	rAction.label = DB.getValue(nodeAction, "name", "");
	rAction.nDamage = DB.getValue(nodeAction, "damage", 0);
	rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "stat", ""));
	rAction.sStatDamage = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "statdmg", ""));
	rAction.sDamageType = RollManagerCPP.resolveDamageType(DB.getValue(nodeAction, "damagetype", ""));

	rAction.bPierce = DB.getValue(nodeAction, "pierce", "") == "yes";
	if rAction.bPierce then
		rAction.nPierceAmount = DB.getValue(nodeAction, "pierceamount", 0);	
	end
	
	ActionDamageCPP.performRoll(draginfo, rActor, rAction);
end