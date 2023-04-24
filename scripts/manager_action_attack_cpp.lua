function onInit()
	ActionsManager.registerModHandler("attack", modRoll);
	ActionsManager.registerResultHandler("attack", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	ActionAttackCPP.applyEffort(rActor, rAction);

	local bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);

	if bCanRoll then
		local rRoll = ActionAttackCPP.getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function applyEffort(rActor, rAction)
	RollManagerCPP.addEffortToAction(rActor, rAction, "attack");
	RollManagerCPP.addWoundedToAction(rActor, rAction);
	RollManager.applyDesktopAdjustments(rAction);
	RollManagerCPP.calculateEffortCost(rActor, rAction)
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "attack";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.nModifier or 0;
	rRoll.sDesc = string.format("[ATTACK (%s)] %s", rAction.sAttackRange, rAction.label);

	RollManagerCPP.encodeStat(rAction, rRoll);
	RollManagerCPP.encodeTraining(rAction, rRoll);
	RollManagerCPP.encodeAssets(rAction, rRoll);
	RollManagerCPP.encodeLevel(rAction, rRoll);
	RollManagerCPP.encodeEdge(rAction, rRoll);
	RollManagerCPP.encodeEffort(rAction, rRoll);
	RollManagerCPP.encodeCost(rAction, rRoll);
	RollManagerCPP.encodeWeaponType(rAction, rRoll);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManagerCPP.decodeStat(rRoll, true);
	local nAssets = RollManagerCPP.decodeAssets(rRoll) or 0;
	local nEffort = RollManagerCPP.decodeEffort(rRoll, true) or 0;
	local bInability, bTrained, bSpecialized = RollManagerCPP.decodeTraining(rRoll, true);
	local nLevel = RollManagerCPP.decodeLevel(rRoll); -- Don't need to persist here
	local sWeaponType = RollManagerCPP.decodeWeaponType(rRoll); -- Don't persist

	local bEffects = false;
	local nDiffEffects = 0; -- Keep track of the roll's difficulty changes via effects
	local nRollEffects = 0; -- Keep track of the roll's modifier changes via effects

	-- Get base difficulty
	rRoll.nDifficulty = 0;
	if rTarget and not ActorManager.isPC(rTarget) then
		rRoll.nDifficulty = ActorManagerCPP.getCreatureLevel(rTarget);
		local nLevelBonus = EffectManagerCPP.getEffectsBonusByType(rTarget, "LEVEL", { "def", "defense", sStat }, rSource);
		if nLevelBonus ~= 0 then
			bEffects = true;
			nDiffEffects = nDiffEffects + nLevelBonus;
			rRoll.nDifficulty = rRoll.nDifficulty + nLevelBonus;
		end
	end

	-- Adjust difficulty based on assets
	local nAssetEffect = EffectManagerCPP.getEffectsBonusByType(rSource, "ASSET", { "atk", "attack", sStat }, rTarget)
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
	local nAttackEffect = EffectManagerCPP.getEffectsBonusByType(rSource, { "ATK", "ATTACK" }, { sStat }, rTarget)
	if nAttackEffect ~= 0 then
		bEffects = true;

		-- Every adjustment of 3 is a difficulty adjustment
		local nDiffMod = math.floor(nAttackEffect / 3);
		nDiffEffects = nDiffEffects - nDiffMod;
		nRollEffects = nRollEffects + nAttackEffect % 3;

		rRoll.nDifficulty = rRoll.nDifficulty - nDiffMod;
	end

	-- Adjust difficulty based on weapon type (ease light weapons by 1 step)
	if sWeaponType == "light" then
		rRoll.nDifficulty = rRoll.nDifficulty - 1;
	end

	-- Adjust the roll based on the level
	if nLevel ~= 0 then
		rRoll.nDifficulty = rRoll.nDifficulty + nLevel;
	end

	-- Get ease/hinder effects
	local bEase, bHinder;
	bEase, bHinder, bEffects = RollManagerCPP.getEaseHindrance(rSource, rTarget, { "attack", "atk", sStat }, sStat);
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
	local nEffortEffect = EffectManagerCPP.getEffectsBonusByType(rSource, { "EFFORT", "EFF" }, { sStat, "attack", "atk" }, rTarget);
	local nMaxEffort = ActorManagerCPP.getMaxEffort(rSource, sStat, "attack");
	local nEffortEffectApplied = math.min(nEffortEffect, nMaxEffort - nEffort); -- This calculates how much effect modified the effort applied to the roll

	-- If the effort effect actually modified the amount of effort applied to this roll, state that
	if nEffortEffectApplied > 0 then
		bEffects = true;
		nDiffEffects = nDiffEffects - nEffortEffectApplied;
	end

	rRoll.nDifficulty = rRoll.nDifficulty - nEffort - nEffortEffectApplied;

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
		nDiffEffects = nDiffEffects + 1;
		rRoll.nDifficulty = rRoll.nDifficulty + 1;
	end
	if EffectManager.hasCondition(rTarget, "Dazed") or 
		(sStat == "might" and EffectManager.hasCondition(rTarget, "Staggered")) or
		(sStat == "speed" and EffectManager.hasCondition(rTarget, "Frostbitten")) or
		(sStat == "intellect" and EffectManager.hasCondition(rTarget, "Confused"))then
		bEffects = true;
		nDiffEffects = nDiffEffects - 1;
		rRoll.nDifficulty = rRoll.nDifficulty - 1;
	end

	rRoll.nMod = rRoll.nMod + nRollEffects;
	RollManagerCPP.encodeEffects(rRoll, nDiffEffects, nRollEffects, bEffects);

	-- If a PC is attacking a PC, then instead of reducing difficulty, we add a mod of 3 per difficulty reduction
	if rTarget and ActorManager.isPC(rTarget) then
		rRoll.nMod = rRoll.nMod + (rRoll.nDifficulty * -3); -- negative 3 because we want to increase the mod for every difficulty reduction. So we need to invert
	end
end

function onRoll(rSource, rTarget, rRoll)
	-- If there's no target, we want to keep all this data here
	local bPersist = rTarget == nil;
	local sStat = RollManagerCPP.decodeStat(rRoll, bPersist);
	local bInability, bTrained, bSpecialized = RollManagerCPP.decodeTraining(rRoll, bPersist);
	local nAssets = RollManagerCPP.decodeAssets(rRoll, bPersist) or 0;
	local nEffort = RollManagerCPP.decodeEffort(rRoll, true) or 0;
	local nCost = RollManagerCPP.decodeCost(rRoll, false) or 0; -- We don't need to display cost in the message
	local nTotal = ActionsManager.total(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "action_attack";

	if rTarget then
		rMessage.icon = "roll_attack";
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end

	local aAddIcons = {};
	local nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		nFirstDie = rRoll.aDice[1].result or 0;
	end
	if nFirstDie >= 20 then
		rMessage.text = rMessage.text .. " [DAMAGE +4 OR MAJOR EFFECT]";
		table.insert(aAddIcons, "roll20");
	elseif nFirstDie == 19 then
		rMessage.text = rMessage.text .. " [DAMAGE +3 OR MINOR EFFECT]";
		table.insert(aAddIcons, "roll19");
	elseif nFirstDie == 18 then
		rMessage.text = rMessage.text .. " [DAMAGE +2]";
		table.insert(aAddIcons, "roll18");
	elseif nFirstDie == 17 then
		rMessage.text = rMessage.text .. " [DAMAGE +1]";
		table.insert(aAddIcons, "roll17");
	elseif nFirstDie == 1 then
		rMessage.text = rMessage.text .. " [GM INTRUSION]";
		table.insert(aAddIcons, "roll1");
	end
	
	-- Only process roll successes if a PC is attacking an NPC (not PC vs PC)
	local bSuccess, bAutomaticSuccess = RollManagerCPP.processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons);
	if rTarget and not ActorManager.isPC(rTarget) then
		local sIcon = "";
		if bSuccess then
			if bAutomaticSuccess then
				rMessage.text = rMessage.text .. " [AUTOMATIC HIT]";
			else
				rMessage.text = rMessage.text .. " [HIT]";
			end
			if nFirstDie >= 17 then
				sIcon = "roll_attack_crit";
			else
				sIcon = "roll_attack_hit";
			end
		else
			rMessage.text = rMessage.text .. " [MISS]";

			if nFirstDie == 1 then
				sIcon = "roll_attack_crit_miss";
			else
				sIcon = "roll_attack_miss";
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

	-- for PC vs PC rolls, prompt a defense roll
	if ActorManager.isPC(rSource) and rTarget and ActorManager.isPC(rTarget) then
		local rResult = {};
		rResult.nDifficulty = nTotal;
		rResult.sStat = sStat;
		rResult.rTarget = rSource;

		-- Attempt to prompt the target to defend
		-- if there's no one controlling the defending PC, then automatically roll defense
		if Session.IsHost then
			local bPrompt = PromptManager.promptDefenseRoll(rSource, rTarget, rResult);

			if not bPrompt then
				ActionDefenseCPP.performRoll(nil, rTarget, rResult);
			end
		else
			PromptManager.initiateDefensePrompt(rSource, rTarget, rResult);
		end
	end
end