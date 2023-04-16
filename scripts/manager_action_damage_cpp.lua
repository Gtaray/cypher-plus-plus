function onInit()
	ActionDamage.applyDamage = applyDamage;

	ActionsManager.registerModHandler("damage", modRoll);
	ActionsManager.registerResultHandler("damage", onRoll);
end

function performRoll(draginfo, rActor, rAction)
	ActionDamageCPP.applyEffort(rActor, rAction);

	local bCanRoll = false;
	if ActorManager.isPC(rActor) then
		bCanRoll = RollManager.spendPointsForRoll(ActorManager.getCreatureNode(rActor), rAction);
	else
		bCanRoll = true;
	end

	if bCanRoll then
		local rRoll = getRoll(rActor, rAction);
		ActionsManager.performAction(draginfo, rActor, rRoll);
	end
end

function applyEffort(rActor, rAction)
	if ActorManager.isPC(rActor) then
		RollManagerCPP.addEffortToAction(rActor, rAction, "damage");
		RollManager.applyDesktopAdjustments(rAction);
		RollManagerCPP.calculateEffortCost(rActor, rAction)

		if rAction.nEffort > 0 then
			local nExtraDamage = rAction.nEffort * 3;
			rAction.nDamage = rAction.nDamage + nExtraDamage;
		end
	end
end

function getRoll(rActor, rAction)
	local rRoll = {}
	rRoll.sType = "damage"
	rRoll.sDesc = string.format("[DAMAGE (%s, %s)] %s", rAction.sDamageType or "", rAction.sStatDamage, rAction.label or "");
	rRoll.aDice = { };
	rRoll.nMod = rAction.nDamage;

	-- No need to encode stat used for NPCs, they don't use stats
	if ActorManager.isPC(rActor) then
		RollManagerCPP.encodeStat(rAction, rRoll);
	end
	RollManagerCPP.encodePiercing(rAction, rRoll);
	RollManagerCPP.encodeAmbientDamage(rAction, rRoll);

	if (rAction.nEffort or 0) > 0 then
		local nExtraDamage = rAction.nEffort * 3;
		rRoll.sDesc = rRoll.sDesc .. string.format(" [APPLIED %d EFFORT FOR +%d DAMAGE]", rAction.nEffort, nExtraDamage);
	end
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	-- Get damage stat
	local sStat = RollManagerCPP.decodeStat(rRoll, true);
	local sDamageType = RollManagerCPP.decodeDamageType(rRoll);
	local bPiercing, nPierceAmount = RollManagerCPP.decodePiercing(rRoll); -- We'll re-encode at the end

	local aFilters = { };
	if (sStat or "") ~= "" then
		table.insert(aFilters, sStat);
	end
	if (sDamageType or "") ~= "" then
		table.insert(aFilters, sDamageType);
	end

	-- Get and encode piercing
	local nPierceEffectAmount, nPierceEffectCount = EffectManagerCPP.getEffectsBonusByType(rSource, "PIERCE", { sDamageType }, rTarget);
	if nPierceEffectCount > 0 then
		-- if we have pierce effects, then bPiercing is set locked to true.
		bPiercing = true;

		-- If either the effect or innate pierce is equal to 0, 
		-- it means we have global piercing for all damage, and that has precedence
		if nPierceEffectAmount == 0 or nPierceAmount == 0 then
			nPierceAmount = 0;

		-- In this case there's no innate piercing, but there is an effect amount
		-- Assign piercing value
		elseif nPierceAmount < 0 then
			nPierceAmount = nPierceEffectAmount

		-- Innate and effect piercing are both positive.
		-- We can safely add the two together
		else
			nPierceAmount = nPierceAmount + nPierceEffectAmount;
		end
	end

	if bPiercing then
		RollManagerCPP.encodePiercing({ bPierce = true, nPierceAmount = nPierceAmount }, rRoll);
	end

	local nDmgBonus, nDmgEffectCount = EffectManagerCPP.getEffectsBonusByType(rSource, "DMG", aFilters, rTarget)

	rRoll.nMod = rRoll.nMod + nDmgBonus;

	if nDmgEffectCount > 0 then
		rRoll.sDesc = rRoll.sDesc .. " [EFFECTS";
		if nDmgBonus < 0 then
			rRoll.sDesc = rRoll.sDesc  .. " " .. nDmgBonus .. "]";
		elseif nEffects > 0 then
			rRoll.sDesc = rRoll.sDesc  .. " +" .. nDmgBonus .. "]";
		else
			rRoll.sDesc = rRoll.sDesc .. "]";
		end
	end
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rTarget ~= nil then
		rMessage.text = rMessage.text:gsub(" %[STAT: %w-%]", "");
	end

	local rResult;
	rSource, rTarget, rResult = ActionDamageCPP.buildRollResult(rSource, rTarget, rRoll);

	if rResult.bSourceNPC and rResult.bTargetPC then
		rMessage.text = rMessage.text .. " -> " .. (ActorManager.getDisplayName(rTarget) or "")
	end
	rMessage.icon = "action_damage";
	Comm.deliverChatMessage(rMessage);

	if rTarget then
		ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll.bTower, rRoll.sType, rRoll.sDesc, rResult.nTotal);	
	end	
end

function buildRollResult(rSource, rTarget, rRoll)
	local rResult = {};

	rResult.sDesc = rRoll.sDesc;
	rResult.bSourcePC = (rSource and ActorManager.isPC(rSource)) or false;
	rResult.bTargetPC = (rTarget and ActorManager.isPC(rTarget)) or false;
	rResult.bSourceNPC = (rSource and not ActorManager.isPC(rSource)) or false;
	rResult.bTargetNPC = (rTarget and not ActorManager.isPC(rTarget)) or false;
	rResult.sStat = RollManagerCPP.decodeStat(rRoll, true);
	rResult.sDamageType, rResult.sDamageStat = RollManagerCPP.decodeDamageType(rRoll);
	rResult.bPiercing, rResult.nPierceAmount = RollManagerCPP.decodePiercing(rRoll, true);
	rResult.bAmbient = RollManagerCPP.decodeAmbientDamage(rRoll, true);
	rResult.nTotal = ActionsManager.total(rRoll);

	return rSource, rTarget, rResult;
end

-- This completely overwrites the original applyDamage function since it's
-- one monolithic method that can't be interfaced in any sane way.
function applyDamage(rSource, rTarget, bSecret, sRollType, sDamage, nTotal)	
	-- Get damage stat and type
	local rRoll = { sDesc = sDamage }; -- Hack to allow the decoding to work
	local bPersist = rTarget == nil;
	local sStat = RollManagerCPP.decodeStat(rRoll, bPersist);
	local sDamageType, sDamageStat = RollManagerCPP.decodeDamageType(sDamage);
	local bAmbient = RollManagerCPP.decodeAmbientDamage(sDamage, bPersist);
	local bPiercing, nPierceAmount = RollManagerCPP.decodePiercing(sDamage);

	-- Remember current health status
	local sOriginalStatus = ActorHealthManager.getHealthStatus(rTarget);
	
	-- Apply damage, and generate notifications
	local nPCWounds = nil;
	local aNotifications = {};

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return;
	end

	-- Only calculate damage reduction if we're dealing damage, and not if we're healing
	if nTotal > 0 then
		if not bAmbient then
			local nArmorAdjust = ActionDamageCPP.calculateArmor(rSource, rTarget, sDamageStat, aNotifications)

			if bPiercing then
				-- if pierce amount is 0 (but bPierce is true), then pierce all armor
				-- Otherwise it's a flat reduction
				if nPierceAmount > 0 then
					nArmorAdjust = nArmorAdjust - nPierceAmount;
				elseif nPierceAmount == 0 then
					nArmorAdjust = 0;
				end
			end
			nTotal = nTotal - nArmorAdjust;
		end
		nTotal = ActionDamageCPP.calculateDamageResistances(rSource, rTarget, nTotal, sDamageType, sDamageStat, aNotifications);
	end

	if sTargetNodeType == "pc" then
		if (sDamageStat or "") == "" and nTotal < 0 then
			sDamageStat = sStat; -- sDamageStat is not given with heal rolls, so we match it up here
		end

		ActionDamageCPP.applyDamageToPc(rSource, rTarget, nTotal, sDamageStat, sDamageType, aNotifications);
	elseif sTargetNodeType == "ct" then
		ActionDamageCPP.applyDamageToNpc(rSource, rTarget, nTotal, sDamageStat, sDamageType, aNotifications);
	else
		return;
	end

	-- Check for status change
	local bShowStatus = false;
	if ActorManager.isFaction(rTarget, "friend") then
		bShowStatus = not OptionsManager.isOption("SHPC", "off");
	else
		bShowStatus = not OptionsManager.isOption("SHNPC", "off");
	end
	if bShowStatus then
		local sNewStatus = ActorHealthManager.getHealthStatus(rTarget);
		if sOriginalStatus ~= sNewStatus then
			table.insert(aNotifications, string.format("[%s: %s]", Interface.getString("combat_tag_status"), sNewStatus));
		end
	end

	-- Output
	if not (rTarget or sExtraResult ~= "") then
		return;
	end
	
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgLong.text = "";
	if nTotal < 0 then
		msgShort.icon = "roll_heal";
		msgLong.icon = "roll_heal";

		-- Report positive values only
		nTotal = math.abs(nTotal);
		msgLong.text = string.format("[%s healing (%s)]", nTotal, sStat)
	else
		msgShort.icon = "roll_damage";
		msgLong.icon = "roll_damage";

		if sDamageType then
			msgLong.text = string.format("[%s %s damage]", nTotal, sDamageType);
		else
			msgLong.text = string.format("[%s damage]", nTotal);
		end
	end

	if nPCWounds then
		msgLong.text = string.format("%s (%+d)", msgLong.text, nPCWounds);
	end
	msgLong.text = string.format("%s ->", msgLong.text);
	if rTarget then
		msgLong.text = string.format("%s [to %s", msgLong.text, ActorManager.getDisplayName(rTarget));
	end
	if ActorManager.isPC(rTarget) and (sDamageStat or "") ~= "" then
		msgLong.text = string.format("%s's %s", msgLong.text, sDamageStat);
	end
	msgLong.text = msgLong.text .. "]";
	msgShort.text = msgLong.text;
	
	if #aNotifications > 0 then
		msgLong.text = string.format("%s %s", msgLong.text, table.concat(aNotifications, " "));
	end
	
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

function applyDamageToPc(rSource, rTarget, nDamage, sDamageStat, sDamageType, aNotifications)
	local sTargetNodeType, nodePC = ActorManager.getTypeAndNode(rTarget);
	if not nodePC then
		return;
	end

	local nIntellectHP = DB.getValue(nodePC, "abilities.intellect.current", 0);
	local nSpeedHP = DB.getValue(nodePC, "abilities.speed.current", 0);
	local nMightHP = DB.getValue(nodePC, "abilities.might.current", 0);
	local nWounds = DB.getValue(nodePC, "wounds", 0);
	
	local nOrigIntellectHP = nIntellectHP;
	local nOrigSpeedHP = nSpeedHP;
	local nOrigMightHP = nMightHP;

	-- Damage
	if nDamage > 0 then
		nDamage, nMightHP, nSpeedHP, nIntellectHP = ActionDamageCPP.calculateDamageToHealthPools(nDamage, sDamageStat, nMightHP, nSpeedHP, nIntellectHP);
		
		local nNewWounds = 0;
		if nOrigIntellectHP > 0 and nIntellectHP <= 0 then
			nNewWounds = nNewWounds + 1;
		end
		if nOrigSpeedHP > 0 and nSpeedHP <= 0 then
			nNewWounds = nNewWounds + 1;
		end
		if nOrigMightHP > 0 and nMightHP <= 0 then
			nNewWounds = nNewWounds + 1;
		end
		if nNewWounds > 0 then
			if nWounds < 3 then
				local nOrigWounds = nWounds;
				nWounds = math.min(nWounds + nNewWounds, 3);
				nPCWounds = nOrigWounds - nWounds;
			end
		end
	
	-- Healing?
	elseif nDamage < 0 then
		if sDamageStat == "intellect" then
			local nIntellectMax = DB.getValue(nodePC, "abilities.intellect.max", 0);
			if nIntellectHP < nIntellectMax then
				nIntellectHP = math.min(nIntellectHP - nDamage, nIntellectMax);
			end
		elseif sDamageStat == "speed" then
			local nSpeedMax = DB.getValue(nodePC, "abilities.speed.max", 0);
			if nSpeedHP < nSpeedMax then
				nSpeedHP = math.min(nSpeedHP - nDamage, nSpeedMax);
			end
		else
			local nMightMax = DB.getValue(nodePC, "abilities.might.max", 0);
			if nMightHP < nMightMax then
				nMightHP = math.min(nMightHP - nDamage, nMightMax);
			end
		end
		
		local nNewHealing = 0;
		if nOrigIntellectHP <= 0 and nIntellectHP > 0 then
			nNewHealing = nNewHealing + 1;
		end
		if nOrigSpeedHP <= 0 and nSpeedHP > 0 then
			nNewHealing = nNewHealing + 1;
		end
		if nOrigMightHP <= 0 and nMightHP > 0 then
			nNewHealing = nNewHealing + 1;
		end
		if nNewHealing > 0 then
			if nWounds > 0 then
				local nOrigWounds = nWounds;
				nWounds = math.max(nWounds - nNewHealing, 0);
				nPCWounds = nOrigWounds - nWounds;
			end
		end
	end
	
	DB.setValue(nodePC, "abilities.intellect.current", "number", nIntellectHP);
	DB.setValue(nodePC, "abilities.speed.current", "number", nSpeedHP);
	DB.setValue(nodePC, "abilities.might.current", "number", nMightHP);
	DB.setValue(nodePC, "wounds", "number", nWounds);
end

function calculateDamageToHealthPools(nDamage, sDamageStat, nMightHP, nSpeedHP, nIntellectHP)
	-- Handle intellect and speed damage first
	-- Any overflow damage will fall into the normal 
	-- might -> speed -> intellect flow below
	if sDamageStat == "intellect" then
		if nIntellectHP > 0 then
			nIntellectHP = nIntellectHP - nDamage;
			if nIntellectHP < 0 then
				nDamage = -nIntellectHP;
				nIntellectHP = 0;
			else
				nDamage = 0;
			end
		end
	elseif sDamageStat == "speed" then
		if nSpeedHP > 0 then
			nSpeedHP = nSpeedHP - nDamage;
			if nSpeedHP < 0 then
				nDamage = -nSpeedHP;
				nSpeedHP = 0;
			else
				nDamage = 0;
			end
		end
	end
	
	if nMightHP > 0 then
		nMightHP = nMightHP - nDamage;
		if nMightHP < 0 then
			nDamage = -nMightHP;
			nMightHP = 0;
		else
			nDamage = 0;
		end
	end
	if nSpeedHP > 0 then
		nSpeedHP = nSpeedHP - nDamage;
		if nSpeedHP < 0 then
			nDamage = -nSpeedHP;
			nSpeedHP = 0;
		else
			nDamage = 0;
		end
	end
	if nIntellectHP > 0 then
		nIntellectHP = nIntellectHP - nDamage;
		if nIntellectHP < 0 then
			nDamage = -nIntellectHP;
			nIntellectHP = 0;
		else
			nDamage = 0;
		end
	end

	return nDamage, nMightHP, nSpeedHP, nIntellectHP;
end

function applyDamageToNpc(rSource, rTarget, nDamage, sDamageStat, sDamageType, aNotifications)
	local sTargetNodeType, nodeNPC = ActorManager.getTypeAndNode(rTarget);
	if not nodeNPC then
		return;
	end

	local nWounds = DB.getValue(nodeNPC, "wounds", 0);
	local nHP = DB.getValue(nodeNPC, "hp", 0);

	nWounds = math.max(math.min(nWounds + nDamage, nHP), 0);
	DB.setValue(nodeNPC, "wounds", "number", nWounds);
end

function calculateArmor(rSource, rTarget, sDamageStat)
	local _, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return 0;
	end
	
	-- Apply Armor
	if sDamageStat == "might" then
		local nArmor = ActorManagerCPP.getArmorWithMods(rTarget, rSource);
		return nArmor; -- Return the amount of damage to adjust by
	end

	return 0;
end

function calculateDamageResistances(rSource, rTarget, nDamage, sDamageType, sDamageStat, aNotifications)
	if ActorManagerCPP.isImmune(rTarget, rSource, {sDamageType, sDamageStat}) then
		nDamage = 0;
		table.insert(aNotifications, "[IMMUNE]");
		return nDamage;
	end

	local bResist, nResistAmount = ActorManagerCPP.isResistant(rTarget, rSource, {sDamageType, sDamageStat})
	if bResist and nResistAmount >= 0 then
		-- Resist half if amount is 0, otherwise flat reduction
		if nResistAmount == 0 then
			nDamage = math.floor(nDamage / 2);
		else
			nDamage = math.max(0, nDamage - nResistAmount);
		end
		if nDamage > 0 then
			table.insert(aNotifications, "[PARTIALLY RESISTED]")
		else
			table.insert(aNotifications, "[RESISTED]")
		end
	end

	local bVuln, nVulnAmount = ActorManagerCPP.isVulnerable(rTarget, rSource, {sDamageType, sDamageStat});
	if bVuln and nVulnAmount >= 0 then
		if nVulnAmount == 0 then
			nDamage = nDamage * 2;
		else
			nDamage = nDamage + nVulnAmount;
		end
		table.insert(aNotifications, "[VULNERABLE]");
	end

	return nDamage;
end