local fGetRoll;
local fOnEffect;

function onTabletopInit()
	fGetRoll = ActionEffect.getRoll;
	ActionEffect.getRoll = getRoll;

	fOnEffect = ActionEffect.onEffect;
	ActionsManager.registerResultHandler("effect", onEffect);
end

function getRoll(draginfo, rActor, rAction)
	local rRoll = fGetRoll(draginfo, rActor, rAction);

	if rAction.bDisableEdge then
		rAction.label = string.format("%s [EDGE DISABLED]", rAction.label);
	elseif rAction.bUsedEdge then
		rAction.label = string.format("%s [APPLIED %s EDGE]", rAction.label, rAction.nEdge);
	end

	rRoll.sDesc = string.format("%s {%s}", rRoll.sDesc, rAction.label)

	return rRoll;
end

function onEffect(rSource, rTarget, rRoll)
	local sText = rRoll.sDesc:match("{(.*)}");
	rRoll.sDesc = rRoll.sDesc:gsub("{.*}", "");

	sendEffectActionMessageToChat(rSource, sText);
	fOnEffect(rSource, rTarget, rRoll);
end

function sendEffectActionMessageToChat(rActor, sText)
	-- All we want to do is print a message in chat saying what ability was used, 
	-- then hand off to the original effect handler
	local rMessage = ChatManager.createBaseMessage(rActor);
	rMessage.icon = "action_effect";
	rMessage.text = string.format("[EFFECT] %s", sText);
	Comm.deliverChatMessage(rMessage);
end