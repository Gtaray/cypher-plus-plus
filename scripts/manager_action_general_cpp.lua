local _fOnRoll = nil;

function onInit()
	_fOnRoll = ActionGeneral.onRoll;

	ActionsManager.registerResultHandler("dice", onRoll);
end

function onRoll(rSource, rTarget, rRoll)
	_fOnRoll(rSource, rTarget, rRoll)
end