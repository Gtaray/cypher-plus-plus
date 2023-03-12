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
