function onInit()
	GameSystem.actions["defense"] = { sIcon = "action_roll", sTargeting = "each", bUseModStack = true }
	table.insert(GameSystem.targetactions, "defense");

	ActionsManager.registerResultHandler("defense", onRoll);
	ActionsManager.registerModHandler("defense", modRoll)
end

function performRoll(draginfo, rActor, rAction)
	ActionDefenseCPP.applyEffort(rActor, rAction);
	local bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);

	if bCanRoll then
		local rRoll = ActionDefenseCPP.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function applyEffort(rActor, rAction)
	RollManagerCPP.addEffortToAction(rActor, rAction, "defense");
	RollManagerCPP.addWoundedToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rAction);
	RollManagerCPP.calculateEffortCost(rActor, rAction)
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "defense";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;
	rRoll.sDesc = string.format("[DEFENSE] %s", rAction.label);
	rRoll.nDifficulty = rAction.nDifficulty or 0;

	RollManagerCPP.encodeStat(rAction, rRoll);
	RollManagerCPP.encodeAssets(rAction, rRoll);
	RollManagerCPP.encodeEdge(rAction, rRoll);
	RollManagerCPP.encodeEffort(rAction, rRoll);
	RollManagerCPP.encodeTraining(rAction, rRoll);

	if rAction.rTarget then
		local sTarget = ActorManager.getCTNodeName(rAction.rTarget)
		if sTarget or "" ~= "" then
			rRoll.sDesc = rRoll.sDesc .. " [TARGET: " .. sTarget .. "]"
		end
	end

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManagerCPP.decodeStat(rRoll, true);
	local rTarget = RollManagerCPP.resolveTarget(rRoll, rTarget, true);
	local nAssets = RollManagerCPP.decodeAssets(rRoll) or 0;
	local nEffort = RollManagerCPP.decodeEffort(rRoll, true) or 0;
	local bInability, bTrained, bSpecialized = RollManagerCPP.decodeTraining(rRoll, true);

	local bEffects = false;
	local nDiffEffects = 0; -- Keep track of the roll's difficulty changes via effects
	local nRollEffects = 0; -- Keep track of the roll's modifier changes via effects

	-- Get base difficulty
	-- Only calc difficulty if it's not already been set
	-- this is because defense vs rolls will calc the difficulty of an NPC attack
	-- ahead of time. Defense rolls in response don't need to do any work
	if rTarget and not ActorManager.isPC(rTarget) and rRoll.nDifficulty == 0 then
		rRoll.nDifficulty = ActorManagerCPP.getCreatureLevel(rTarget);
		local nLevelBonus = EffectManagerCPP.getEffectsBonusByType(rTarget, "LEVEL", { "attack", "atk", sStat }, rSource);
		if nLevelBonus ~= 0 then
			bEffects = true;
			nDiffEffects = nDiffEffects + nLevelBonus;
			rRoll.nDifficulty = rRoll.nDifficulty + nLevelBonus;
		end
	end

	local nFinalDiffMod = 0;
	-- Adjust difficulty based on assets
	local nAssetEffect = EffectManagerCPP.getEffectsBonusByType(rSource, "ASSET", { "def", "defense", sStat }, rTarget)
	if nAssetEffect ~= 0 then
		bEffects = true;
		-- Calculate the actual amount of asset effect bonus that gets applied
		nAssetEffect = math.min(nAssetEffect, 2 - nAssets);
		nDiffEffects = nDiffEffects - math.min(nAssetEffect, 2); -- Always capped at 2 assets
	end
	nAssets = math.min(nAssets + nAssetEffect, 2);
	nFinalDiffMod = nFinalDiffMod - nAssets
	RollManagerCPP.encodeAssets({ nAssets = nAssets }, rRoll);

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nAttackEffect = EffectManagerCPP.getEffectsBonusByType(rSource, { "DEF", "DEFENSE" }, { sStat }, rTarget)
	if nAttackEffect ~= 0 then
		bEffects = true;

		-- Every adjustment of 3 is a difficulty adjustment
		local nDiffMod = math.floor(nAttackEffect / 3);
		nDiffEffects = nDiffEffects - nDiffMod;
		nRollEffects = nRollEffects + nAttackEffect % 3;

		nFinalDiffMod = nFinalDiffMod - nDiffMod;
	end

	-- Get ease/hinder effects
	local bEase, bHinder, bEffects = RollManagerCPP.getEaseHindrance(rSource, rTarget, { "defense", "def", sStat }, sStat);
	if bEase then
		nFinalDiffMod = nFinalDiffMod - 1;
		if bEffects then
			nDiffEffects = nDiffEffects - 1;
		end
	end
	if bHinder then
		nFinalDiffMod = nFinalDiffMod + 1;
		if bEffects then
			nDiffEffects = nDiffEffects + 1;
		end
	end
	RollManagerCPP.encodeEaseHindrance(rRoll, bEase, bHinder);

	-- Adjust difficulty based on effort
	local nEffortEffect = EffectManagerCPP.getEffectsBonusByType(rSource, { "EFFORT", "EFF" }, { sStat, "defense", "def" }, rTarget);
	local nMaxEffort = ActorManagerCPP.getMaxEffort(rSource, sStat, "defense");
	local nEffortEffectApplied = math.min(nEffortEffect, nMaxEffort - nEffort); -- This calculates how much effect modified the effort applied to the roll

	-- If the effort effect actually modified the amount of effort applied to this roll, state that
	if nEffortEffectApplied > 0 then
		bEffects = true;
		nDiffEffects = nDiffEffects - nEffortEffectApplied;
		rRoll.nDifficulty = rRoll.nDifficulty - nEffortEffectApplied;
	end

	-- Adjust difficulty based on effort
	nFinalDiffMod = nFinalDiffMod - nEffort;

	-- Adjust difficulty based on training
	if bInability then
		nFinalDiffMod = nFinalDiffMod + 1;
	end
	if bTrained then
		nFinalDiffMod = nFinalDiffMod - 1;
	end
	if bSpecialized then
		nFinalDiffMod = nFinalDiffMod - 2;
	end

	-- Dazed doesn't stack with the other conditions
	if EffectManager.hasCondition(rSource, "Dazed") or 
	   (sStat == "might" and EffectManager.hasCondition(rSource, "Staggered")) or
	   (sStat == "speed" and EffectManager.hasCondition(rSource, "Frostbitten")) or
	   (sStat == "intellect" and EffectManager.hasCondition(rSource, "Confused")) then
		bEffects = true;
		nDiffEffects = nDiffEffects + 1;
		nFinalDiffMod = nFinalDiffMod + 1;
	end
	if EffectManager.hasCondition(rTarget, "Dazed") or 
		(sStat == "might" and EffectManager.hasCondition(rTarget, "Staggered")) or
		(sStat == "speed" and EffectManager.hasCondition(rTarget, "Frostbitten")) or
		(sStat == "intellect" and EffectManager.hasCondition(rTarget, "Confused"))then
		bEffects = true;
		nDiffEffects = nDiffEffects - 1;
		nFinalDiffMod = nFinalDiffMod - 1;
	end

	rRoll.nMod = rRoll.nMod + nRollEffects;
	RollManagerCPP.encodeEffects(rRoll, nDiffEffects, nRollEffects, bEffects);

	-- If a PC is attacking a PC, then instead of reducing difficulty, we add a mod of 3 per difficulty reduction
	if rTarget and ActorManager.isPC(rTarget) then
		rRoll.nMod = rRoll.nMod + (nFinalDiffMod * -3); -- negative 3 because we want to increase the mod for every difficulty reduction. So we need to invert
	else
		rRoll.nDifficulty = rRoll.nDifficulty + nFinalDiffMod;
	end
end

function onRoll(rSource, rTarget, rRoll)
	local rTarget = RollManagerCPP.resolveTarget(rRoll, rTarget);

	local bPersist = rTarget == nil;
	local sStat = RollManagerCPP.decodeStat(rRoll);
	local aState = RollManagerCPP.decodeDefenseState(rRoll);
	local bInability, bTrained, bSpecialized = RollManagerCPP.decodeTraining(rRoll, bPersist);
	local nAssets = RollManagerCPP.decodeAssets(rRoll, bPersist) or 0;
	local nEffort = RollManagerCPP.decodeEffort(rRoll, true) or 0;

	local nDmg = 0;
	if aState.nDmg then
		nDmg = aState.nDmg;
	end

	-- Resolve between rTarget and aState.attacker
	-- rTarget always takes priority
	-- Really there shouldn't be any state data if there's a target that doesn't match the state
	if aState.rAttacker and not rTarget then
		rTarget = aState.rAttacker;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	if rTarget then
		rMessage.text = rMessage.text .. " [from " .. (ActorManager.getDisplayName(rTarget) or "unknown") .. "]";
	end

	local aAddIcons = {};
	local nFirstDie = rRoll.aDice[1].result or 0;
	if nFirstDie >= 20 then
		rMessage.text = rMessage.text .. " [MAJOR EFFECT]";
		table.insert(aAddIcons, "roll20");
	elseif nFirstDie == 19 then
		rMessage.text = rMessage.text .. " [MINOR EFFECT]";
		table.insert(aAddIcons, "roll19");
	elseif nFirstDie == 1 then
		rMessage.text = rMessage.text .. " [GM INTRUSION]";
		table.insert(aAddIcons, "roll1");
	end

	local bSuccess, bAutomaticSuccess = RollManagerCPP.processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons);

	if rTarget then
		local sIcon = "";
		if bSuccess then
			if bAutomaticSuccess then
				rMessage.text = rMessage.text .. " [AUTOMATIC MISS]";
			else
				rMessage.text = rMessage.text .. " [MISS]";
			end
			if nFirstDie >= 19 then
				sIcon = "roll_attack_crit_miss";
			else
				sIcon = "roll_attack_miss";
			end
		else
			rMessage.text = rMessage.text .. " [HIT]";

			if nFirstDie == 1 then
				sIcon = "roll_attack_crit";
			else
				sIcon = "roll_attack_hit";
			end
		end

		-- If we have multiple icons, replace the first.
		if type(rMessage.icon) == "table" then
			rMessage.icon[1] = sIcon
		else
			rMessage.icon = sIcon;
		end
	end

	Comm.deliverChatMessage(rMessage);

	-- Finally, we apply the damage to the PC if they failed
	if rTarget and (not bSuccess) and nDmg > 0 then
		local rDmgRoll = buildDamageRoll(rTarget, nDmg, aState.sDamageStat, aState.sDamageType);
		ActionDamage.notifyApplyDamage(rTarget, rSource, rRoll.bTower, rRoll.sType, rDmgRoll.sDesc, nDmg);	
	end
end

function buildDamageRoll(rActor, nDamage, sStatDamage, sDamageType)
	local rAction = {};
	rAction.sDamageType = sDamageType;
	rAction.sStatDamage = sStatDamage;
	rAction.nDamage = nDamage;
	return ActionDamageCPP.getRoll(rActor, rAction)
end