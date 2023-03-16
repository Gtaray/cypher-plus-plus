-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	PowerManagerCore.registerDefaultPowerMenu(self);
	PowerManagerCore.handleDefaultPowerInitParse(getDatabaseNode());

	self.updateDetailButton();
	self.toggleDetail();
	self.onDisplayChanged();

	local node = getDatabaseNode();
	local sActionsPath = PowerManagerCore.getPowerActionsPath();
	DB.addHandler(DB.getPath(node, sActionsPath), "onChildAdded", self.onActionListChanged);
	DB.addHandler(DB.getPath(node, sActionsPath), "onChildDeleted", self.onActionListChanged);
	DB.addHandler(DB.getPath(node, "period"), "onUpdate", self.onUsePeriodChanged);

	if ActorManager.isPC(DB.getChild(node, "...")) then
		onCostChanged();
		onUsePeriodChanged();
	end
end
function onClose()
	if super and super.onClose then
		super.onClose();
	end
	local node = getDatabaseNode();
	local sActionsPath = PowerManagerCore.getPowerActionsPath();
	DB.removeHandler(DB.getPath(node, sActionsPath), "onChildAdded", self.onActionListChanged);
	DB.removeHandler(DB.getPath(node, sActionsPath), "onChildDeleted", self.onActionListChanged);
end

function onMenuSelection(...)
	PowerManagerCore.onDefaultPowerMenuSelection(self, ...)
end

function onCostChanged()
	local bShow = (statcost.getValue() ~= 0);
	statcostview.setVisible(bShow);
				
	local sStatView = "" .. statcost.getValue();
	local sStat = stat.getValue();
	if sStat ~= "" then
		sStatView = sStatView .. " " .. StringManager.capitalize(sStat:sub(1,2));
	end
	statcostview.setValue(sStatView);
end

function onCostDoubleClicked()
	local node = getDatabaseNode();
	local nodeActor = DB.getChild(node, "...");
	local rAction = {
		label = string.format("[COST] %s", name.getValue()),
		nCost = statcost.getValue(),
		sCostStat = stat.getValue(),
		nEffort = 0,
		nAssets = 0,
		bDisableEdge = false
	};

	RollManagerCPP.addEffortToAction(nodeActor, rAction, "cost");
	RollManagerCPP.calculateEffortCost(nodeActor, rAction);

	if RollManager.spendPointsForRoll(nodeActor, rAction) then
		local rMessage = ChatManager.createBaseMessage(nodeActor);
		rMessage.text = rAction.label;
		rMessage.icon = "action_damage";
		Comm.deliverChatMessage(rMessage);
	end

end

function onUsePeriodChanged()
	local bShowUseCheckbox = DB.getValue(getDatabaseNode(), "period", "") ~= "";
	used.setVisible(bShowUseCheckbox);
end

function onActionListChanged()
	if not activatedetail then
		return;
	end

	self.updateDetailButton();
	if DB.getChildCount(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()) > 0 then
		activatedetail.setValue(1);
	else
		activatedetail.setValue(0);
	end
end
function updateDetailButton()
	if not activatedetail then
		return;
	end

	local bShow = (DB.getChildCount(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()) > 0);
	activatedetail.setVisible(bShow);
end
function toggleDetail()
	if not activatedetail then
		return;
	end

	local bShow = (activatedetail.getValue() == 1);
	if bShow then
		actions.setDatabaseNode(DB.createChild(getDatabaseNode(), PowerManagerCore.getPowerActionsPath()));
	else
		actions.setDatabaseNode(nil);
	end
	actions.setVisible(bShow);
end

function onDisplayChanged()
	PowerManagerCore.updatePowerDisplay(self);
end
