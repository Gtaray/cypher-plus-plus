function onInit()
	GameSystem.actions["skill"] = { sIcon = "action_roll", sTargeting = "each", bUseModStack = true }
	table.insert(GameSystem.targetactions, "skill");

	ActionsManager.registerResultHandler("skill", onRoll);
	ActionsManager.registerModHandler("skill", modRoll)
end

function performRoll(draginfo, rActor, rAction)
	ActionSkillCPP.applyEffort(rActor, rAction);
	local rRoll = ActionSkillCPP.getRoll(rActor, rAction);

	local bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);

	if bCanRoll then
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function applyEffort(rActor, rAction)
	RollManagerCPP.addEffortToAction(rActor, rAction, "skill");
	RollManagerCPP.addWoundedToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rAction);
	RollManagerCPP.calculateEffortCost(rActor, rAction)
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "skill";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;
	rRoll.sDesc = string.format("[SKILL (%s)] %s", StringManager.capitalize(rAction.sStat or ""), rAction.label or "");

	RollManagerCPP.encodeStat(rAction, rRoll);
	RollManagerCPP.encodeTraining(rAction, rRoll);
	RollManagerCPP.encodeAssets(rAction, rRoll);
	RollManagerCPP.encodeEdge(rAction, rRoll);
	RollManagerCPP.encodeEffort(rAction, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManagerCPP.decodeStat(rRoll, true);
	local sSkill = RollManagerCPP.decodeSkill(rRoll, true);
	local nAssets = RollManagerCPP.decodeAssets(rRoll) or 0;
	local nEffort = RollManagerCPP.decodeEffort(rRoll, true) or 0;
	local bInability, bTrained, bSpecialized = RollManagerCPP.decodeTraining(rRoll, true);

	local bEffects = false;
	local nDiffEffects = 0; -- Keep track of the roll's difficulty changes via effects
	local nRollEffects = 0; -- Keep track of the roll's modifier changes via effects

	-- Get base difficulty
	rRoll.nDifficulty = 0;
	if rTarget and not ActorManager.isPC(rTarget) then
		rRoll.nDifficulty = ActorManagerCPP.getCreatureLevel(rTarget);
		local nLevelBonus = EffectManagerCPP.getEffectsBonusByType(rTarget, "LEVEL", { sStat }, rSource);
		if nLevelBonus ~= 0 then
			bEffects = true;
			nDiffEffects = nDiffEffects + nLevelBonus;
			rRoll.nDifficulty = rRoll.nDifficulty + nLevelBonus;
		end
	end

	-- Adjust difficulty based on assets
	local nAssetEffect = EffectManagerCPP.getEffectsBonusByType(rSource, "ASSET", { "skill", "skills", sStat, sSkill }, rTarget)
	if nAssetEffect ~= 0 then
		bEffects = true;
		-- Calculate the actual amount of asset effect bonus that gets applied
		nAssetEffect = math.min(nAssetEffect, 2 - nAssets);
		nDiffEffects = nDiffEffects - math.min(nAssetEffect, 2); -- Always capped at 2 assets
	end
	nAssets = math.min(nAssets + nAssetEffect, 2);
	rRoll.nDifficulty = rRoll.nDifficulty - nAssets
	RollManagerCPP.encodeAssets({ nAssets = nAssets }, rRoll);

	--Adjust raw modifier, converting every increment of 3 to a difficultly modifier
	local nSkillEffect = EffectManagerCPP.getEffectsBonusByType(rSource, { "SKILL", "SKILLS" }, { sStat, sSkill }, rTarget)
	if nSkillEffect ~= 0 then
		bEffects = true;

		-- Every adjustment of 3 is a difficulty adjustment
		local nDiffMod = math.floor(nSkillEffect / 3);
		nDiffEffects = nDiffEffects - nDiffMod;
		nRollEffects = nRollEffects + nSkillEffect % 3;

		rRoll.nDifficulty = rRoll.nDifficulty - nDiffMod;
	end

	-- Get ease/hinder effects
	local bEase, bHinder, bEffects = RollManagerCPP.getEaseHindrance(rSource, rTarget, { "skill", sStat, sSkill }, sStat);
	if bEase then
		rRoll.nDifficulty = rRoll.nDifficulty - 1;
		if bEffects then
			nDiffEffects = nDiffEffects - 1;
		end
	end
	if bHinder then
		rRoll.nDifficulty = rRoll.nDifficulty + 1;
		if bEffects then
			nDiffEffects = nDiffEffects + 1;
		end
	end
	RollManagerCPP.encodeEaseHindrance(rRoll, bEase, bHinder);

	-- Adjust difficulty based on effort
	rRoll.nDifficulty = rRoll.nDifficulty - nEffort;

	-- Adjust difficulty based on training
	if bInability then
		rRoll.nDifficulty = rRoll.nDifficulty + 1;
	end
	if bTrained then
		rRoll.nDifficulty = rRoll.nDifficulty - 1;
	end
	if bSpecialized then
		rRoll.nDifficulty = rRoll.nDifficulty - 2;
	end

	-- Dazed doesn't stack with the other conditions
	if EffectManager.hasCondition(rSource, "Dazed") or 
	   (sStat == "might" and EffectManager.hasCondition(rSource, "Staggered")) or
	   (sStat == "speed" and EffectManager.hasCondition(rSource, "Frostbitten")) or
	   (sStat == "intellect" and EffectManager.hasCondition(rSource, "Confused")) then
		bEffects = true;
		nDiffMod = nDiffMod + 1;
		rRoll.nDifficulty = rRoll.nDifficulty + 1;
	end
	if EffectManager.hasCondition(rTarget, "Dazed") or 
		(sStat == "might" and EffectManager.hasCondition(rTarget, "Staggered")) or
		(sStat == "speed" and EffectManager.hasCondition(rTarget, "Frostbitten")) or
		(sStat == "intellect" and EffectManager.hasCondition(rTarget, "Confused"))then
		bEffects = true;
		nDiffMod = nDiffMod - 1;
		rRoll.nDifficulty = rRoll.nDifficulty - 1;
	end

	rRoll.nMod = rRoll.nMod + nRollEffects;
	RollManagerCPP.encodeEffects(rRoll, nDiffEffects, nRollEffects, bEffects);
end

function onRoll(rSource, rTarget, rRoll)
	local bPersist = rTarget == nil;
	local sStat = RollManagerCPP.decodeStat(rRoll);
	local sSkill = RollManagerCPP.decodeSkill(rRoll)
	local bInability, bTrained, bSpecialized = RollManagerCPP.decodeTraining(rRoll, bPersist);
	local nAssets = RollManagerCPP.decodeAssets(rRoll, bPersist) or 0;
	local nEffort = RollManagerCPP.decodeEffort(rRoll, true) or 0;

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_roll";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
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
		if bAutomaticSuccess then
			rMessage.text = rMessage.text .. " [AUTOMATIC SUCCESS]";
		elseif bSuccess then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end

	Comm.deliverChatMessage(rMessage);
end