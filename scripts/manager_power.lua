function onInit()
	local tPowerHandlers = {
		fnGetActorNode = PowerManager.getPowerActorNode
	}
	PowerManagerCore.registerPowerHandlers(tPowerHandlers);
	
	local tPowerActionHandlers = {
		fnGetButtonIcons = PowerManager.getActionButtonIcons,
		fnGetText = PowerManager.getActionText,
		fnGetTooltip = PowerManager.getActionTooltip,
		fnPerform = PowerManager.performAction,
	}
	PowerActionManagerCore.registerActionType("", tPowerActionHandlers)
	PowerActionManagerCore.registerActionType("stat", {})
	PowerActionManagerCore.registerActionType("attack", {})
	PowerActionManagerCore.registerActionType("damage", {})
	PowerActionManagerCore.registerActionType("heal", {})
	PowerActionManagerCore.registerActionType("effect", {})
end

function getPowerActorNode(node)
	return DB.getChild(node, "...");
end

-------------------------
-- POWER ACTIONS
-------------------------
function getActionButtonIcons(node, tData)
	if tData.sType == "stat" then
		return "button_roll", "button_roll_down";
	elseif tData.sType == "attack" then
		return "button_action_attack", "button_action_attack_down";
	elseif tData.sType == "damage" then
		return "button_action_damage", "button_action_damage_down";
	elseif tData.sType == "heal" then
		return "button_action_heal", "button_action_heal_down";
	elseif tData.sType == "effect" then
		return "button_action_effect", "button_action_effect_down";
	end
	return "", "";
end
function getActionText(node, tData)
	if tData.sType == "stat" then
		return PowerManager.getPCPowerStatActionText(node);
	elseif tData.sType == "attack" then
		return PowerManager.getPCPowerAttackActionText(node);
	elseif tData.sType == "damage" then
		return PowerManager.getPCPowerDamageActionText(node);
	elseif tData.sType == "heal" then
		return PowerManager.getPCPowerHealActionText(node);
	elseif tData.sType == "effect" then
		return PowerActionManagerCore.getActionEffectText(node, tData);
	end
	return "";
end
function getActionTooltip(node, tData)
	if tData.sType == "stat" then
		return string.format("%s: %s", Interface.getString("power_tooltip_stat"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "attack" then
		return string.format("%s: %s", Interface.getString("power_tooltip_attack"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "damage" then
		return string.format("%s: %s", Interface.getString("power_tooltip_damage"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "heal" then
		return string.format("%s: %s", Interface.getString("power_tooltip_heal"), PowerActionManagerCore.getActionText(node, tData));
	elseif tData.sType == "effect" then
		return PowerActionManagerCore.getActionEffectTooltip(node, tData);
	end
	return "";
end

function getPCPowerStatActionText(nodeAction)
	local sText = "";

	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then
		local nDiff, nMod = RollManagerCPP.resolveDifficultyModifier(rAction.sTraining, rAction.nAsset, rAction.nModifier);
		local sDice = StringManager.convertDiceToString({ "d20" }, nMod);

		sText = string.format("%s: %s", StringManager.capitalize(rAction.sStat), sDice)

		if nDiff < 0 then
			sText = string.format("%s [Diff: %s]", sText, nDiff);
		elseif nDiff > 0 then
			sText = string.format("%s [Diff: +%s]", sText, nDiff);
		end

		if rAction.nCost > 0 then
			sText = string.format("%s [Cost: %s]", sText, rAction.nCost);
		end
	end

	return sText;
end

function getPCPowerAttackActionText(nodeAction)
	local sAttack = "";

	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then		
		local nDiff, nMod = RollManagerCPP.resolveDifficultyModifier(rAction.sTraining, rAction.nAsset, rAction.nLevel, rAction.nModifier);
		local sDice = StringManager.convertDiceToString({ "d20" }, nMod);

		if rAction.sAttackRange ~= "" then
			sAttack = string.format("%s (%s): %s", StringManager.capitalize(rAction.sStat), rAction.sAttackRange, sDice)
		else
			sAttack = string.format("%s: %s", StringManager.capitalize(rAction.sStat), sDice)
		end

		if nDiff < 0 then
			sAttack = string.format("%s [Diff: %s]", sAttack, nDiff);
		elseif nDiff > 0 then
			sAttack = string.format("%s [Diff: +%s]", sAttack, nDiff);
		end

		if rAction.nCost > 0 then
			sAttack = string.format("%s [Cost: %s]", sAttack, rAction.nCost);
		end
	end
	
	return sAttack;
end

function getPCPowerDamageActionText(nodeAction)
	local sDamage = "";
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then
		sDamage = string.format("%s: %s %s damage", StringManager.capitalize(rAction.sStat), rAction.nDamage, rAction.sDamageType);

		if rAction.sStat ~= rAction.sStatDamage then
			sDamage = string.format("%s -> %s", sDamage, StringManager.capitalize(rAction.sStatDamage));
		end

		if rAction.bPierce then
			local sPierceAmount = "";
			if rAction.nPierceAmount > 0 then
				sPierceAmount = string.format(": %s", rAction.nPierceAmount);
			end

			sDamage = string.format("%s [PIERCE%s]", sDamage, sPierceAmount);
		end

		if rAction.bAmbient then
			sDamage = string.format("%s [AMBIENT]", sDamage);
		end
	end
	return sDamage;
end

function getPCPowerHealActionText(nodeAction)
	local sHeal = "";
	
	local rAction, rActor = PowerManager.getPCPowerAction(nodeAction);
	if rAction then		
		sHeal = string.format("%s %s", rAction.nHeal, StringManager.capitalize(rAction.sStat));

		if DB.getValue(nodeAction, "healtargeting", "") == "self" then
			sHeal = sHeal .. " [SELF]";
		end
	end
	
	return sHeal;
end

function getPCPowerActionOutputOrder(nodeAction)
	if not nodeAction then
		return 1;
	end
	local nodeActionList = DB.getParent(nodeAction);
	if not nodeActionList then
		return 1;
	end
	
	-- First, pull some ability attributes
	local sType = DB.getValue(nodeAction, "type", "");
	local nOrder = DB.getValue(nodeAction, "order", 0);
	
	-- Iterate through list node
	local nOutputOrder = 1;
	for _, v in ipairs(DB.getChildList(nodeActionList)) do
		if DB.getValue(v, "type", "") == sType then
			if DB.getValue(v, "order", 0) < nOrder then
				nOutputOrder = nOutputOrder + 1;
			end
		end
	end
	
	return nOutputOrder;
end

function getPCPowerAction(nodeAction)
	if not nodeAction then
		return;
	end

	local nodePower = DB.getChild(nodeAction, "...");
	local rActor = ActorManager.resolveActor(PowerManagerCore.getPowerActorNode(nodePower));
	if not rActor then
		return;
	end

	local rAction = {};
	rAction.type = DB.getValue(nodeAction, "type", "");
	rAction.label = DB.getValue(nodeAction, "...name", "");
	rAction.order = PowerManager.getPCPowerActionOutputOrder(nodeAction);

	if rAction.type == "stat" then
		rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "stat", ""));
		rAction.sTraining = DB.getValue(nodeAction, "training", "");
		rAction.nAsset = DB.getValue(nodeAction, "asset", 0);
		rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);
		rAction.nCost = DB.getValue(nodeAction, "cost", 0);
	elseif rAction.type == "attack" then
		-- This is here because when NPCs attack it uses the default stat for defense
		-- rather than attack
		local sDefaultStat = nil;
		if ActorManager.isPC(rActor) then
			sDefaultStat = "might";
		else
			sDefaultStat = "speed";
		end

		rAction.sAttackRange = DB.getValue(nodeAction, "atkrange", "");
		rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "stat", ""), sDefaultStat);
		rAction.sTraining = DB.getValue(nodeAction, "training", "");
		rAction.nAsset = DB.getValue(nodeAction, "asset", 0);
		rAction.nLevel = DB.getValue(nodeAction, "level", 0);
		rAction.nModifier = DB.getValue(nodeAction, "modifier", 0);
		rAction.nCost = DB.getValue(nodeAction, "cost", 0);

	elseif rAction.type == "damage" then
		rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "stat", ""));
		rAction.nDamage = DB.getValue(nodeAction, "damage", 0);
		rAction.sDamageType = RollManagerCPP.resolveDamageType(DB.getValue(nodeAction, "damagetype", ""));
		rAction.sStatDamage = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "statdmg", ""));
		rAction.bPierce = DB.getValue(nodeAction, "pierce", "") == "yes";
		rAction.bAmbient = DB.getValue(nodeAction, "ambient", "") == "yes";

		if rAction.bPierce then
			rAction.nPierceAmount = DB.getValue(nodeAction, "pierceamount", 0);	
		end
	elseif rAction.type == "heal" then
		rAction.sTargeting = DB.getValue(nodeAction, "healtargeting", "");
		rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "statheal", ""));
		rAction.nHeal = DB.getValue(nodeAction, "heal", 0);
	elseif rAction.type == "effect" then
		rAction.sName = DB.getValue(nodeAction, "label", "");

		rAction.sApply = DB.getValue(nodeAction, "apply", "");
		rAction.sTargeting = DB.getValue(nodeAction, "targeting", "");
		
		rAction.nDuration = DB.getValue(nodeAction, "durmod", 0);
		rAction.sUnits = DB.getValue(nodeAction, "durunit", "");
	end

	return rAction, rActor
end

-------------------------
-- POWER USAGE
-------------------------
function performAction(node, tData)
	local draginfo = tData.draginfo;
	local rAction, rActor = PowerManager.getPCPowerAction(node);

	if not rActor or not rAction then
		return false;
	end

	-- These are separate because PCs will need to spend effort and stuff
	-- NPC don't
	if ActorManager.isPC(rActor) then
		return performPcAction(draginfo, rActor, rAction);
	else
		return performNpcAction(draginfo, rActor, rAction);
	end
end

function performPcAction(draginfo, rActor, rAction)
	local nodeActor = ActorManager.getCreatureNode(rActor);

	local rRolls = {};	
	if rAction.type == "stat" then
		ActionStatCPP.applyEffort(rActor, rAction);
		local bCanRoll = RollManager.spendPointsForRoll(nodeActor, rAction);
		if bCanRoll then
			table.insert(rRolls, ActionStatCPP.getRoll(rActor, rAction));
		end
	elseif rAction.type == "attack" then
		ActionAttackCPP.applyEffort(rActor, rAction);
		local bCanRoll = RollManager.spendPointsForRoll(nodeActor, rAction);
		if bCanRoll then
			table.insert(rRolls, ActionAttackCPP.getRoll(rActor, rAction));
		end
		
	elseif rAction.type == "damage" then
		ActionDamageCPP.applyEffort(rActor, rAction);
		local bCanRoll = RollManager.spendPointsForRoll(nodeActor, rAction);
		if bCanRoll then
			table.insert(rRolls, ActionDamageCPP.getRoll(rActor, rAction));
		end
		
	elseif rAction.type == "heal" then
		table.insert(rRolls, ActionHealCPP.getRoll(rActor, rAction));
		
	elseif rAction.type == "effect" then
		local rRoll = ActionEffect.getRoll(draginfo, rActor, rAction);
		if rRoll then
			table.insert(rRolls, rRoll);
		end
	end
	
	if #rRolls > 0 then
		ActionsManager.performMultiAction(draginfo, rActor, rRolls[1].sType, rRolls);
	end
	return true;
end

function performNpcAction(draginfo, rActor, rAction)
	if rAction.type == "stat" then
		-- Display a warning and do nothing
		Comm.addChatMessage({ text = "This action is not available for NPCs.", font = "systemfont" });
	elseif rAction.type == "attack" then
		ActionDefenseVsCPP.performRoll(draginfo, rActor, rAction);
	elseif rAction.type == "damage" then
		ActionDamageCPP.performRoll(draginfo, rActor, rAction);
	elseif rAction.type == "heal" then
	elseif rAction.type == "effect" then

	end
	return true;
end