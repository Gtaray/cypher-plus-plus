---@diagnostic disable: need-check-nil
------------------------------
-- DEFENSE STATE MANAGEMENT
------------------------------
-- This script manages the state of PCs that are dealt damage by NPCs
-- When a PC is dealt damage by an NPC, this updates that PCs state such that the next
-- applicable defense roll they make will be applied to the damage that the NPC dealt.

OOB_MSGTYPE_APPLYDEFSTATE = "applydefstate";
aDefState = {};

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDEFSTATE, handleSetDefenseState);
end


------------------------------
-- SET
------------------------------
-- rSource is the attacker
-- rTarget is the defender (PC)
function setDefState(rSource, rTarget, rData)
	local msgOOB = buildDefenseStateOobMessage(rSource, rTarget, rData)
	if (msgOOB.sSourceNode or "") == "" then
		ChatManager.Message(Interface.getString("error_defense_state_source_not_on_ct"), true);
		return;
	end
	if (msgOOB.sTargetNode or "") == "" then
		ChatManager.Message(Interface.getString("error_defense_state_target_not_on_ct"), true);
		return;
	end
	Comm.deliverOOBMessage(msgOOB);
end

function buildDefenseStateOobMessage(rSource, rTarget, rData)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDEFSTATE;
	
	msgOOB.sSourceNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rTarget);
	msgOOB.nDmg = rData.nTotal;
	msgOOB.sDamageStat = rData.sDamageStat
	msgOOB.sDamageType = rData.sDamageType;
	msgOOB.sStat = rData.sStat;

	if rData.bAmbient then
		msgOOB.bAmbient = "true";
	end

	return msgOOB;
end

function handleSetDefenseState(msgOOB)
	local sSourceCT, sTargetCT, aState = buildDefenseState(msgOOB)
	
	if (sSourceCT or "") == "" or (sTargetCT or "") == "" then
		return;
	end

	if aDefState[sTargetCT] == nil then
		aDefState[sTargetCT] = {};
	end

	-- Target is the PC
	aDefState[sTargetCT] = aState;
end

function buildDefenseState(msgOOB)
	local sSourceCT = msgOOB.sSourceNode;
	local sTargetCT = msgOOB.sTargetNode;
	if sSourceCT == "" or sTargetCT == "" then
		return;
	end
	
	local aState = {
		sAttacker = sSourceCT,
        nDmg = tonumber(msgOOB.nDmg) or 0,
		sDamageStat = msgOOB.sDamageStat,
		sDamageType = msgOOB.sDamageType,
		sStat = msgOOB.sStat,
		bAmbient = msgOOB.bAmbient == "true"
    };	

	return sSourceCT, sTargetCT, aState
end

------------------------------
-- GET
------------------------------

-- rSource is the defender (PC)
function getDefState(rSource, sStat, bRetain)
	local sSourceCT = ActorManager.getCTNodeName(rSource);
	if sSourceCT == "" then
		return {};
	end
	
	if not aDefState[sSourceCT] then
		return {};
	end
	
	local aState = aDefState[sSourceCT];
	-- check if this is the correct stat being rolled
	if sStat ~= aState.sStat then
		return {};
	end

	-- There might be an issue with booleans

	-- in this case, Defenses property was not set, so any defense will work
	if not bRetain then
		aDefState[sSourceCT] = nil;
	end
	return aState;
end