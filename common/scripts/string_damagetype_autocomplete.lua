function onChar()
	if super and super.onChar then
		super.onChar();
	end
	
	if getCursorPosition() == #getValue() + 1 then
		local sCompletion = StringManager.autoComplete(DamageTypeManager.get(), getValue(), true)
		if sCompletion then
			setValue(getValue() .. sCompletion);
			setSelectionPosition(getCursorPosition() + #sCompletion);
		end
	end
end