local _fApplyRecovery = nil;

function onInit()
	_fApplyRecovery = ActionRecovery.applyRecovery;
	ActionRecovery.applyRecovery = applyRecovery;
end

function applyRecovery(nodeActor, nMightNew, nSpeedNew, nIntellectNew, nRemainder)
	_fApplyRecovery(nodeActor, nMightNew, nSpeedNew, nIntellectNew, nRemainder);

	-- Handle recharging powers
	local nRecoveryUsed = DB.getValue(nodeActor, "recoveryused", 0);

	for _, abilityNode in ipairs(DB.getChildList(nodeActor, "abilitylist")) do
		local sPeriod = DB.getValue(abilityNode, "period", "");
		local bRecharge = (sPeriod == "first" and nRecoveryUsed == 1) or 
						  (sPeriod == "last" and nRecoveryUsed == 4) or
						  (sPeriod == "any");

		if bRecharge then
			DB.setValue(abilityNode, "used", "number", 0);
		end
	end
end