local _fBuildPCRollInfo = nil;
function onInit()
	_fBuildPCRollInfo = RollManager.buildPCRollInfo;
	RollManager.buildPCRollInfo = buildPCRollInfo;

	RollManager.spendPointsForRoll = spendPointsForRoll;
end

function buildPCRollInfo(nodeActor, sDesc, sStat)
	local tInfo = _fBuildPCRollInfo(nodeActor, sDesc, sStat);
	local rActor = ActorManager.resolveActor(nodeActor);

	-- Go in and update nEdge based on effects
	local nEdgeBonus, nEdgeEffectCount = EffectManagerCPP.getEffectsBonusByType(rActor, "EDGE", sStat)

	tInfo.nEdge = (tInfo.nEdge or 0) + nEdgeBonus;

	if nEdgeEffectCount > 0 then
		tInfo.sDesc = tInfo.sDesc .. " [EFFECTS]"
	end

	return tInfo;
end

function spendPointsForRoll(nodeActor, tInfo)
	if not nodeActor or not tInfo then
		return false;
	end
	
	if tInfo.nCost <= 0 then
		return true;
	end

	if tInfo.sCostStat == "" then
		local rActor = ActorManager.resolveActor(nodeActor);
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rMessage.text .. " [STAT NOT SPECIFIED FOR POINT SPEND]";
		Comm.deliverChatMessage(rMessage);
		return false;
	end

	local nCurrentPool = DB.getValue(nodeActor, "abilities." .. tInfo.sCostStat .. ".current", 0);
	if tInfo.nCost > nCurrentPool then
		local rActor = ActorManager.resolveActor(nodeActor);
		local rMessage = ChatManager.createBaseMessage(rActor);
		rMessage.text = rMessage.text .. " [INSUFFICIENT POINTS IN POOL]";
		Comm.deliverChatMessage(rMessage);
		return false;
	end

	tInfo.label = tInfo.label .. string.format(" [SPENT %d FROM %s POOL]", tInfo.nCost, Interface.getString(tInfo.sCostStat):upper());

	-- This is only here because effects use sName instead of label, and we want to display it there too
	if tInfo.sName then
		tInfo.sName = tInfo.sName .. string.format(" [SPENT %d FROM %s POOL]", tInfo.nCost, Interface.getString(tInfo.sCostStat):upper());
	end

    local nNewPool = nCurrentPool - tInfo.nCost;
	DB.setValue(nodeActor, "abilities." .. tInfo.sCostStat .. ".current", "number", nNewPool);
    
    if nNewPool == 0 then
        local nCurrentWounds = DB.getValue(nodeActor, "wounds", 0);
        DB.setValue(nodeActor, "wounds", "number", nCurrentWounds + 1);
    end

	return true;
end

-- Resolves a stat to either speed, intellect, or might
function resolveStat(sStat, sDefault)
	if not sDefault then
		sDefault = "might";
	end

	sStat = sStat:lower();
	if sStat ~= "speed" and sStat ~= "intellect" then
		sStat = sDefault;
	end
	return sStat;
end

function resolveDamageType(sDamageType)
	sDamageType = sDamageType:lower();
	-- Don't do this, let people put whatever damage types they want
	-- if not DamageTypeManager.isDamageType(sDamageType) then
	-- 	sDamageType = "untyped";
	-- end
	return sDamageType;
end

-- Returns a number representing of how the difficulty of an NPC is modified
-- based on training, assets, and modifier
function resolveDifficultyModifier(sTraining, nAssets, nLevel, nMod)
	local nDifficulty = nLevel or 0;

	sTraining = sTraining:lower();
	if sTraining == "trained" then
		nDifficulty = -1;
	elseif sTraining == "specialized" then
		nDifficulty = -2;
	elseif sTraining == "inability" then
		nDifficulty = 1;
	end

	local nDiffMod = math.floor(nMod / 3);
	local nFinalMod = nMod % 3;

	nDifficulty = nDifficulty - nDiffMod - nAssets;

	return nDifficulty, nFinalMod;
end

function processRollSuccesses(rSource, rTarget, rRoll, rMessage, aAddIcons)
	if #(rRoll.aDice) == 1 and rRoll.aDice[1].type == "d20" then		
		local nDifficulty = tonumber(rRoll.nDifficulty) or 0;
		
		-- Calculate the total number of successes in this roll
		-- We don't account for assets or effort here becuase assets were already used to adjust the 	
		-- difficulty in the modRoll function
		local nTotal = ActionsManager.total(rRoll);
		local nSuccess = math.floor(nTotal / 3);
		nSuccess = math.max(0, math.min(10, nSuccess));
		
		-- A bit of jank, but if there's no target, then we need to display the actual difficulty we 
		-- beat. There's no nDifficulty to reduce, so we invert the difficulty mod and use that as our 
		-- bonus
		if rTarget then
			if ActorManager.isPC(rTarget) then
				-- For PC vs PC, we are simply comparing the raw rolls, and nDifficulty is the attack's total roll
				nSuccess = nTotal;
			else
				-- If we have a target, then we want the icon to display the difficulty
				-- of the target after all of the calc
				nDifficulty = math.min(math.max(nDifficulty, 0), 10);
				table.insert(aAddIcons, "task" .. nDifficulty)
			end
		else
			-- For rolls without targets, we subtract the difficulty of the roll
			-- since difficulty bonuses for the PC are negative, this inverts it so nSuccesses
			-- Will show what difficulty our roll would have beat
			nSuccess = nSuccess - nDifficulty;
			table.insert(aAddIcons, "task" .. nSuccess);
		end
		
		if #aAddIcons > 0 then
			rMessage.icon = { rMessage.icon };
			for _,v in ipairs(aAddIcons) do
				table.insert(rMessage.icon, v);
			end
		end

		if rTarget and nDifficulty >= 0 then
			if nDifficulty == 0 then
				return true, true;
			elseif nSuccess >= nDifficulty then
				return true, false;
			end
		end
	end

	return false, false;
end

function getEaseHindrance(rSource, rTarget, aFilter)
	local bEase, bHinder = false, false;
	if type(aFilter) == "string" then
		aFilter = { aFilter }
	end

	local aEaseEffects = EffectManagerCPP.getEffectsByType(rSource, "EASE", aFilter, rTarget)
	local aHinderEffects = EffectManagerCPP.getEffectsByType(rSource, "HINDER", aFilter, rTarget)

	bEase = #aEaseEffects > 0 or ModifierManager.getKey("EASE");
	bHinder = #aHinderEffects > 0 or ModifierManager.getKey("HINDER");

	return bEase, bHinder, (#aEaseEffects > 0 or #aHinderEffects > 0);
end

----------------------------------------
-- ACTION ADJUSTMENTS
----------------------------------------
function addEffortToAction(rActor, rAction, sRollType)
	if not rActor or (rAction.sStat or "") == "" then
		return;
	end

	rAction.nEdge = ActorManagerCPP.getEdge(rActor, rAction.sStat, sRollType);
	rAction.nMaxEffort = ActorManagerCPP.getMaxEffort(rActor, rAction.sStat, sRollType);
	if rAction.sStat == "speed" then
		rAction.nArmorEffortCost = ActorManagerCPP.getArmorSpeedCost(rActor);
	else 
		rAction.nArmorEffortCost = 0;
	end
end

function addWoundedToAction(rActor, rAction)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return;
	end

	rAction.bWounded = (DB.getValue(nodeActor, "wounds", 0) > 0);
end

function calculateEffortCost(rActor, rAction)
	local nWounded = 0;
	if rAction.bWounded then
		nWounded = 1;
	end

	local nEffortCost = 0;
	if (rAction.nEffort or 0) > 0 then
		nEffortCost = 3 + ((rAction.nEffort - 1) * 2) + (rAction.nEffort * nWounded) + (rAction.nEffort * rAction.nArmorEffortCost);
	end

	local nCostMod = EffectManagerCPP.getEffectsBonusByType(rActor, "COST", { rAction.sStat });

	rAction.nCost = (rAction.nCost or 0) + nEffortCost + nCostMod;

	if ((rAction.nCost or 0) > 0) and ((rAction.nEdge or 0) > 0) then
		if not rAction.bDisableEdge then
			rAction.nCost = rAction.nCost - rAction.nEdge;
		end
	end

	rAction.nCost = math.max(rAction.nCost, 0);
end

----------------------------------------
-- ROLL ENCODING
----------------------------------------
function encodeStat(rAction, rRoll)
	if (rAction.sStat or "") ~= "" then
		rRoll.sDesc = string.format("%s [STAT: %s]", rRoll.sDesc, rAction.sStat);
	end
end

function decodeStat(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	local sStat = sDesc:match("%[STAT: (%w-)%]");
	if not bPersist then
		sDesc = sDesc:gsub(" %[STAT: %w-%]", "")
	end

	if type(vRoll) == "table" then
		vRoll.sDesc = sDesc;
	end
	return sStat;
end

function encodeTraining(rAction, rRoll)
	if rAction.sTraining == "trained" or rAction.nTraining == 2 then
		rRoll.sDesc = string.format("%s [TRAINED]", rRoll.sDesc);
	elseif rAction.sTraining == "specialized" or rAction.nTraining == 3 then
		rRoll.sDesc = string.format("%s [SPECIALIZED]", rRoll.sDesc);
	elseif rAction.sTraining == "inability" or rAction.nTraining == 0 then
		rRoll.sDesc = string.format("%s [INABILITY]", rRoll.sDesc);
	end
end

function decodeTraining(rRoll, bPersist)
	local bInability =  rRoll.sDesc:match("%[INABILITY%]") ~= nil;
	local bTrained =  rRoll.sDesc:match("%[TRAINED%]") ~= nil;
	local bSpecialized =  rRoll.sDesc:match("%[SPECIALIZED%]") ~= nil;

	if not bPersist then
		rRoll.sDesc = rRoll.sDesc:gsub(" %[INABILITY%]", "")
		rRoll.sDesc = rRoll.sDesc:gsub(" %[TRAINED%]", "")
		rRoll.sDesc = rRoll.sDesc:gsub(" %[SPECIALIZED%]", "")
	end

	return bInability, bTrained, bSpecialized;
end

function encodeAssets(rAction, rRoll)
	if (rAction.nAssets or 0) ~= 0 then
		rRoll.sDesc = string.format("%s [ASSET %d]", rRoll.sDesc, rAction.nAssets)
	end
end

function decodeAssets(rRoll, bPersist)
	local nAsset = rRoll.sDesc:match("%[ASSET (-?%d+)%]");
	if not bPersist then
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ASSET %-?%d+%]", "")
	end
	return nAsset;
end

function encodeCost(rAction, rRoll)
	if (rAction.nCost or 0) > 0 then
		rRoll.sDesc = string.format("%s [COST: %s]", rRoll.sDesc, rAction.nCost)
	end
end

function decodeCost(rRoll, bPersist)
	local nCost = rRoll.sDesc:match("%[COST: (%d-)%]");
	if not bPersist then
		rRoll.sDesc = rRoll.sDesc:gsub(" %[COST: %d-%]", "")
	end
	return nCost;
end

function decodeDamageType(vRoll)
	if type(vRoll) == "table" then
		vRoll = vRoll.sDesc;
	end
	return vRoll:match("%[DAMAGE %((%w-), (%w-)%)%]");
end

function encodeEdge(rAction, rRoll)
	if rAction.bEdgeDisabled then
		rRoll.sDesc = string.format("%s [EDGE DISABLED]", rRoll.sDesc);
	elseif rAction.nEdge > 0 then
		rRoll.sDesc = string.format("%s [APPLIED %s EDGE]", rRoll.sDesc, rAction.nEdge);
	end
end

function encodeEffort(rAction, rRoll)
	if (rAction.nEffort or 0) > 0 then
		rRoll.sDesc = string.format("%s [APPLIED %s EFFORT]", rRoll.sDesc, rAction.nEffort)
	end
end

function decodeEffort(rRoll, bPersist)
	local nEffort = rRoll.sDesc:match("%[APPLIED (%d-) EFFORT%]")
	if not bPersist then
		rRoll.sDesc = rRoll.sDesc:gsub(" %[APPLIED %d- EFFORT%]", "")
	end

	return nEffort;
end

function encodeEffects(rRoll, nDiffMod, nRollMod, bIncludeEffects)
	-- If the tag is already in the description, then remove it
	-- we'll re-add it later so it gets pushed to the end of the desc
	if rRoll.sDesc:match("%[EFFECTS%s-%d-\\/-%d-%]") then
		rRoll.sDesc = rRoll.sDesc:gsub(" %[EFFECTS%s-%d-\\/-%d-%]", "")
	end

	if bIncludeEffects then
		rRoll.sDesc = string.format("%s [EFFECTS", rRoll.sDesc);
		if nDiffMod ~= 0 or nRollMod ~= 0 then
			rRoll.sDesc = string.format("%s %s/%s]", rRoll.sDesc, nDiffMod, nRollMod);
		else
			rRoll.sDesc = rRoll.sDesc .. "]";
		end
	end
end

function decodeEffects(rRoll, bPersist)
	local nDiffMod, nRollMod =  rRoll.sDesc:match("%[EFFECTS%s-(%d-)\\/-(%d-)%]");

	if not bPersist then
		rRoll.sDesc = rRoll.sDesc:gsub(" %[EFFECTS%s-%d-\\/-%d-%]", "")
	end

	nDiffMod = tonumber(nDiffMod) or 0;
	nRollMod = tonumber(nRollMod) or 0;

	return nDiffMod, nRollMod;
end

function decodeSkill(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	local sSkill = sDesc:match("%[SKILL .-%] (%w+) %[") or "";
	sSkill = StringManager.trim(sSkill:lower());
	if not bPersist then
		sDesc = sDesc:gsub(" %[SKILL: %w-%]", "")

		if type(vRoll) == "table" then
			vRoll.sDesc = sDesc;
		end
	end
	return sSkill;
end

function encodeAmbientDamage(rAction, rRoll)
	if rAction.bAmbient then
		rRoll.sDesc = string.format("%s [AMBIENT]", rRoll.sDesc)
	end
end

function decodeAmbientDamage(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	local bAmbient = sDesc:match("%[AMBIENT%]") ~= nil

	if not bPersist then
		sDesc = sDesc:gsub(" %[AMBIENT%]", "");
		if type(vRoll) == "table" then
			vRoll.sDesc = sDesc;
		end
	end

	return bAmbient;
end

function encodeDefenseState(rRoll, aState)
	if aState.sAttacker then
		local rAttacker = ActorManager.resolveActor(aState.sAttacker);	
		if rAttacker and rAttacker.sCreatureNode then
        	rRoll.sDesc = rRoll.sDesc .. " [ATTACKER: " .. rAttacker.sCreatureNode .. "]";
		end
	end
    if aState.nDmg then
        rRoll.sDesc = rRoll.sDesc .. " [DMG: ".. aState.nDmg .. "]";
    end
    if aState.sDamageStat then
        rRoll.sDesc = rRoll.sDesc .. " [STATDMG: " .. aState.sDamageStat .. "]";
    end
	if aState.sDamageType then
		rRoll.sDesc = rRoll.sDesc .. " [TYPE: " .. aState.sDamageType .. "]";
	end
end

function decodeDefenseState(rRoll)
    local aDefState = {};
    local sDmg = rRoll.sDesc:match("%[DMG: (.-)%]");
    if sDmg then
        rRoll.sDesc = rRoll.sDesc:gsub(" %[DMG: (.-)%]", "")
        aDefState.nDmg = tonumber(sDmg);
    end

    local sDamageStat = rRoll.sDesc:match("%[STATDMG: (.-)%]");
    if sDamageStat then
        rRoll.sDesc = rRoll.sDesc:gsub(" %[STATDMG: (.-)%]", "");
        aDefState.sDamageStat = sDamageStat;
    end

    local sAttacker = rRoll.sDesc:match("%[ATTACKER: (.-)%]");
    if sAttacker then
        rRoll.sDesc = rRoll.sDesc:gsub(" %[ATTACKER: (.-)%]", "")
        aDefState.rAttacker = ActorManager.resolveActor(sAttacker);
    end

	local sDmgType = rRoll.sDesc:match("%[TYPE: ([^]]*)%]");
    if sDmgType then
        rRoll.sDesc = rRoll.sDesc:gsub(" %[TYPE: [^]]*%]", "");
        aDefState.sDamageType = sDmgType;
    end

    return aDefState;
end

function encodeEaseHindrance(rRoll, bEase, bHinder)
	if bEase then
		rRoll.sDesc = rRoll.sDesc .. " [EASED]";
	end
	if bHinder then
		rRoll.sDesc = rRoll.sDesc .. " [HINDERED]";
	end
end

function decodeEaseHindrance(rRoll, bPersist)
	local bEase, bHinder = false, false;
	bEase = rRoll.sDesc:match("%[EASED%]");
	bHinder = rRoll.sDesc:match("%[HINDERED%]");

	if not bPersist then
		rRoll.sDesc = rRoll.sDesc:gsub(" %[EASED%]", "");
		rRoll.sDesc = rRoll.sDesc:gsub(" %[HINDERED%]", "");
	end

	return bEase, bHinder
end

function encodePiercing(rAction, rRoll)
	if rAction.bPierce then
		rRoll.sDesc = string.format("%s [PIERCE", rRoll.sDesc);
		if (rAction.nPierceAmount or 0) > 0 then
			rRoll.sDesc = string.format("%s %s", rRoll.sDesc, rAction.nPierceAmount);
		end
		rRoll.sDesc = rRoll.sDesc .. "]";
	end
end

function decodePiercing(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	local sPiercing = sDesc:match("%[PIERCE%s?%d-%]");
	local bPiercing = sPiercing ~= nil;
	local nPierceAmount = tonumber(sDesc:match("%[PIERCE (%d+)%]")) or -1;

	-- Dumb hack. If we want to pierce all armor, then nPierceAmount needs to be 0
	-- But it needs to be -1 if bPiercing is false
	-- And it needs to be an actual number if we have a flat pierce amount
	if bPiercing and nPierceAmount == -1 then
		nPierceAmount = 0;
	end

	if not bPersist then
		sDesc = sDesc:gsub("%[PIERCE%s?%d-%]", "");

		if type(vRoll) == "table" then
			vRoll.sDesc = sDesc;
		end
	end

	return bPiercing, nPierceAmount
end

function resolveTarget(rRoll, rTarget, bRetainText)
	if not rTarget or not rTarget.sCTNode then
		local sTargetNode = rRoll.sDesc:match("%[TARGET: ([^]]+)%]")
		if sTargetNode then
			rTarget = ActorManager.resolveActor(sTargetNode);
		end
	end

    if not bRetainText then
	    rRoll.sDesc = rRoll.sDesc:gsub(" %[TARGET:[^]]*%]", "");
    end
	return rTarget;
end

function encodeLevel(rAction, rRoll)
	if (rAction.nLevel or 0) ~= 0 then
		rRoll.sDesc = string.format("%s [LEVEL: %s]", rRoll.sDesc, rAction.nLevel)
	end
end

function decodeLevel(vRoll, bPersist)
	local sDesc = vRoll;
	if type(vRoll) == "table" then
		sDesc = vRoll.sDesc;
	end

	local nLevel = tonumber(sDesc:match("%[LEVEL: (-?%d+)%]") or 0);

	if not bPersist then
		sDesc = sDesc:gsub(" %[LEVEL: %-?%d+%]", "");
		if type(vRoll) == "table" then
			vRoll.sDesc = sDesc;
		end
	end

	return nLevel;
end