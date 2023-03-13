local _fToggleDetail = nil;

function onInit()
	_fToggleDetail = super.toggleDetail;
	super.toggleDetail = toggleDetail;

	super.actionAttack = actionAttack;
	super.actionDamage = actionDamage;

	if super and super.onInit then
		super.onInit()
	end
end
function toggleDetail()
	_fToggleDetail();

	local bShow = (activatedetail.getValue() == 1);
	label_energytype.setVisible(bShow);
	energytype.setVisible(bShow);
end

function actionAttack(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);

	local rAction = {};
	rAction.label = DB.getValue(nodeAction, "name", "");
	rAction.sAttackRange = DB.getValue(nodeAction, "range", "");
	rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "stat", ""));
	rAction.sTraining = DB.getValue(nodeAction, "training", "");
	rAction.nAsset = DB.getValue(nodeAction, "asset", 0);
	rAction.nModifier = DB.getValue(nodeAction, "attack", 0);
	rAction.nCost = DB.getValue(nodeAction, "cost", 0);

	ActionAttackCPP.performRoll(draginfo, rActor, rAction)
end

function actionDamage(draginfo)
	local nodeAction = getDatabaseNode();
	local nodeActor = windowlist.window.getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeActor);

	local rAction = {};
	rAction.label = DB.getValue(nodeAction, "name", "");
	rAction.nDamage = DB.getValue(nodeAction, "damage", 0);
	rAction.sStat = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "stat", ""));
	rAction.sStatDamage = RollManagerCPP.resolveStat(DB.getValue(nodeAction, "damagetype", ""));
	rAction.sDamageType = RollManagerCPP.resolveDamageType(DB.getValue(nodeAction, "energytype", ""));

	rAction.bPierce = false;
	
	ActionDamageCPP.performRoll(draginfo, rActor, rAction);
end