local _fUpdate = nil;

function onInit()
	_fUpdate = super.update;
	super.update = update;

	super.onInit();
end

function update()
	_fUpdate();

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	local bShowResistances = (resistances.getWindowCount() ~= 0);

	-- Update the edit and add buttons
	if bReadOnly then
		resistances_iedit.setValue(0);
	end
	resistances_iedit.setVisible(not bReadOnly);
	resistances_iadd.setVisible(not bReadOnly);

	-- Only show this section if we're in edit mode OR if the list isn't empty
	header_resistances.setVisible((not bReadOnly) or bShowResistances);
	resistances.setVisible((not bReadOnly) or bShowResistances);

	-- Update all resistance subwindows
	for _,w in ipairs(resistances.getWindows()) do
		w.damagetype.setReadOnly(bReadOnly);
		w.type.setReadOnly(bReadOnly);
		w.amount.setReadOnly(bReadOnly);
	end

	-- Update all actions
	if bReadOnly then
		actions_iedit.setValue(0);
	end
	actions_iedit.setVisible(not bReadOnly);
	actions_iadd.setVisible(not bReadOnly);

	for _,w in ipairs(actions.getWindows()) do
		w.name.setReadOnly(bReadOnly);
		w.desc.setReadOnly(bReadOnly);
	end
end