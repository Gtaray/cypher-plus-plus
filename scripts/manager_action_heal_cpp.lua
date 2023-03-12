function onInit()
	ActionsManager.registerModHandler("heal", modRoll);
	ActionsManager.registerResultHandler("heal", onRoll);

	GameSystem.actions["heal"] = { sIcon = "action_heal", sTargeting = "all", bUseModStack = true }
	table.insert(GameSystem.targetactions, "heal");
end

function performRoll(draginfo, rActor, rAction)
	ActionHealCPP.applyEffort(rActor, rAction);
	local rRoll = getRoll(rActor, rAction);

	local bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);

	if bCanRoll then
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function applyEffort(rActor, rAction)
	RollManagerCPP.addEffortToAction(rActor, rAction, "heal");
	RollManager.applyDesktopAdjustments(rAction);
	RollManagerCPP.calculateEffortCost(rActor, rAction)

	if rAction.nEffort > 0 then
		local nExtraHeal = rAction.nEffort * 3;
		rAction.nHeal = rAction.nHeal + nExtraHeal;
	end
end


function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = { };
	rRoll.nMod = rAction.nHeal or 0;
	
	rRoll.sDesc = string.format("[HEAL (%s)] %s", rAction.sStat, rAction.label);

	-- Handle self-targeting
	if rAction.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end

	RollManagerCPP.encodeStat(rAction, rRoll)
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	local sStat = RollManagerCPP.decodeStat(rRoll, true);
	local nHealBonus, nHealEffectCount = EffectManagerCPP.getEffectsBonusByType(rSource, "HEAL", { sStat }, rTarget)

	rRoll.nMod = rRoll.nMod + nHealBonus;

	if nHealEffectCount > 0 then
		if nHealBonus < 0 then
			rRoll.sDesc = rRoll.sDesc  .. " " .. nHealBonus .. "]";
		elseif nEffects > 0 then
			rRoll.sDesc = rRoll.sDesc  .. " +" .. nHealBonus .. "]";
		else
			rRoll.sDesc = rRoll.sDesc .. "]";
		end
	end
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	rMessage.icon = "action_heal";
	if rTarget ~= nil then
		rMessage.text = rMessage.text:gsub(" %[STAT: %w-%]", "");
	end

	Comm.deliverChatMessage(rMessage);

	-- Apply damage to the PC or CT entry referenced
	local nTotal = ActionsManager.total(rRoll) * -1;
	if nTotal ~= 0 then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, nTotal);
	end
end