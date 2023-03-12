function onInit()
	super.actionSkill = actionSkill;
end

-- Check constraints and set up for an ability roll.
function actionSkill(draginfo)
	local nodeSkill = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);
	local node = getDatabaseNode();

	local rAction = {};
	rAction.label = DB.getValue(nodeSkill, "name", "");
	rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeSkill, "stat", ""));
	rAction.nTraining = DB.getValue(nodeSkill, "training", 1);
	rAction.nAssets = DB.getValue(nodeSkill, "asset", 0);
	rAction.nModifier = DB.getValue(nodeSkill, "misc", 0);

	ActionSkillCPP.performRoll(draginfo, rActor, rAction);
end