-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local sStat = stat[1];
	if (sStat or "") == "" then
		return;
	end

	local nodeActor = window.getDatabaseNode()
	local rActor = ActorManager.resolveActor(nodeActor);
	local rAction = {};
	rAction.label = StringManager.capitalize(sStat);
	rAction.sStat = sStat;
	rAction.nTraining = DB.getValue(nodeActor, "abilities." .. sStat .. ".def.training", 1)
	rAction.nAssets = DB.getValue(nodeActor, "abilities." .. sStat .. ".def.asset", 0);
	rAction.nModifier = DB.getValue(nodeActor, "abilities." .. sStat .. ".def.misc", 0);
	ActionDefenseCPP.performRoll(draginfo, rActor, rAction);
end

function onButtonPress()
	action();
	return true;
end
function onDragStart(button, x, y, draginfo)
	action(draginfo);
	return true;
end
