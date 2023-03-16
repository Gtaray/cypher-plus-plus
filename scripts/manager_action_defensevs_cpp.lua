-- These rolls are used by NPCs to force PCs to make defense rolls without applying damage.
function onInit()
    ActionsManager.registerModHandler("defensevs", modRoll);
	ActionsManager.registerResultHandler("defensevs", onRoll);

	GameSystem.actions["defensevs"] = { sIcon = "action_attack", sTargeting = "all", bUseModStack = true }
	table.insert(GameSystem.targetactions, "defensevs");
end

--  NPCs should be the only ones making these rolls
function performRoll(draginfo, rActor, rAction)
    local rRoll = getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "defensevs";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	-- This is the base difficulty of the defense task
	-- This is here for display purposes. The difficulty will be re-calced
	-- when the player makes a defense roll
	rRoll.nDifficulty = rAction.nLevel or 0;

	rRoll.sDesc = string.format(
		"[ATTACK (%s, %s)] %s", 
		rAction.sAttackRange, 
		rAction.sStat, 
		rAction.label);

	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = rRoll.sDesc:match("%[ATTACK %(%w+, (%w+)%)");
	local bEffects = false;
	local nEffects = 0;

	-- Get difficulty
	rRoll.nDifficulty = rRoll.nDifficulty + ActorManagerCPP.getCreatureLevel(rSource);
	local nLevelBonus = EffectManagerCPP.getEffectsBonusByType(rSource, "LEVEL", { "attack", "atk", sStat }, rTarget);
	if nLevelBonus ~= 0 then
		bEffects = true;
		nEffects = nEffects + nLevelBonus
		rRoll.nDifficulty = rRoll.nDifficulty + nLevelBonus;
	end

	rRoll.sDesc = string.format("%s (Lvl %s)", rRoll.sDesc, rRoll.nDifficulty);

	if bEffects then
		rRoll.sDesc = rRoll.sDesc .. " [EFFECTS";
		if nEffects < 0 then
			rRoll.sDesc = rRoll.sDesc  .. " " .. nEffects .. "]";
		elseif nEffects > 0 then
			rRoll.sDesc = rRoll.sDesc  .. " +" .. nEffects .. "]";
		else
			rRoll.sDesc = rRoll.sDesc .. "]";
		end
	end
end

function onRoll(rSource, rTarget, rRoll)
	local sStat = rRoll.sDesc:match("%[ATTACK %(%w+, (%w+)%)");

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.icon = "roll_attack";
	if rTarget then
		rMessage.text = rMessage.text .. " -> " .. ActorManager.getDisplayName(rTarget)
	end
	Comm.deliverChatMessage(rMessage);

	if ActorManager.isPC(rTarget) then
		local rResult = {};
		rResult.nDifficulty = rRoll.nDifficulty;
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