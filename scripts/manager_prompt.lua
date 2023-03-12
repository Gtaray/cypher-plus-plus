OOB_MSG_TYPE_INITIATEDEFPRMOPT = "initiatedefprompt";
OOB_MSGTYPE_PROMPTDEFENSE = "promptdefense";
OOB_MSGTYPE_PROMPTCOST = "promptcost";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSG_TYPE_INITIATEDEFPRMOPT, handleInitiateDefensePrompt);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_PROMPTDEFENSE, handlePromptDefenseRoll);
	-- OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_PROMPTCOST, handlePromptCost);
end

-- We need a double OOB here so that the GM is the one sending out the defense prompt OOB
function initiateDefensePrompt(rSource, rPlayer, rResult)
	local msgOOB = {};
	msgOOB.type = OOB_MSG_TYPE_INITIATEDEFPRMOPT;
	msgOOB.sAttackerNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rPlayer);
	msgOOB.nDifficulty = rResult.nDifficulty;
	msgOOB.sStat = rResult.sStat

	Comm.deliverOOBMessage(msgOOB);
end

function handleInitiateDefensePrompt(msgOOB)
	if not Session.IsHost then
		return;
	end

	local rPlayer = ActorManager.resolveActor(msgOOB.sTargetNode);

	-- Gets the username of the player who owns rPlayer
	local sUser = getUser(rPlayer);
	-- if there's no user, then auto-roll
	if sUser == nil then
		local rAction = getActionFromOobMsg(msgOOB);
		ActionDefenseCPP.performRoll(nil, rPlayer, rAction);
	end

	-- Change the type and forward the OOB msg
	msgOOB.type = OOB_MSGTYPE_PROMPTDEFENSE;
	Comm.deliverOOBMessage(msgOOB, sUser)
end

function promptDefenseRoll(rSource, rPlayer, rResult)
	-- Gets the username of the player who owns rPlayer
	local sUser = getUser(rPlayer);

	-- ADD THIS BACK IN ONCE TESTING IS COMPLETE
	-- This is only here so I can test as a GM
	-- if sUser == nil then
	-- 	return false;
	-- end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_PROMPTDEFENSE;
	msgOOB.sAttackerNode = ActorManager.getCTNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCTNodeName(rPlayer);
	msgOOB.nDifficulty = rResult.nDifficulty;
	msgOOB.sStat = rResult.sStat

	Comm.deliverOOBMessage(msgOOB, sUser);
	return true;
end

function handlePromptDefenseRoll(msgOOB)
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local rSource = ActorManager.resolveActor(msgOOB.sAttackerNode);
	local nDifficulty = tonumber(msgOOB.nDifficulty)
	local sStat = msgOOB.sStat;

	local window = Interface.openWindow("prompt_defense", "")
	if window then
		window.setData(rSource, rTarget, sStat, nDifficulty);
	else
		local rAction = getActionFromOobMsg(msgOOB);
		ActionDefenseCPP.performRoll(nil, rTarget, rAction);
	end
end

function getActionFromOobMsg(msgOOB)
	local rAction = {};
	rAction.nDifficulty = tonumber(msgOOB.nDifficulty) or 0;
	rAction.sStat = msgOOB.sStat;
	rAction.rTarget = ActorManager.resolveActor(msgOOB.sAttackerNode)

	return rAction
end

function promptCostWindow(rSource, vTarget, rRolls)
	-- Don't use an OOB for this because we always want the prompt to happen on the client
	-- that clicks the action button
	if rSource and #rRolls > 0 then
		local window = Interface.openWindow("cost_prompt", "");
		window.setData(rSource, vTarget, rRolls);
	end
	
	return true;
end

function getUser(rPlayer)
	for _,sIdentity in pairs(User.getAllActiveIdentities()) do
		local sName = User.getIdentityLabel(sIdentity);
		if sName == rPlayer.sName then
			return User.getIdentityOwner(sIdentity)
		end
	end
end