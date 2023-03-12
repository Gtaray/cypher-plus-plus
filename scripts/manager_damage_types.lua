local _damageTypes = {};

function onInit()
	if Session.IsHost then
		local node = DB.findNode("damagetypes");
		if not node then
			node = DB.createNode("damagetypes");
			DB.setPublic(node, true);
		end

		DB.addHandler("damagetypes", "onChildUpdate", DamageTypeManager.updateDamageTypes);
		DamageTypeManager.updateDamageTypes();

		OptionsManager.registerButton("library_recordtype_label_damagetypes", "damagetypes", "damagetypes");
	end
end

---------------------------------------------------------------
-- DAMAGE TYPE MANAGEMENT
---------------------------------------------------------------
function updateDamageTypes(nodeParent, nodeUpdated)
	if Session.IsHost then
		_damageTypes = {};

		local node = nodeParent
		if not node then 
			node = DB.findNode("damagetypes");
		end

		for _,v in ipairs(DB.getChildList(node)) do
			local sType = DB.getValue(v, "label", "");
			if sType ~= "" then
				DamageTypeManager.add(sType);
			end
		end
	end
end

function isDamageType(sType)
	sType = sType:lower();
	if sType == "all" then
		return true;
	end
	return StringManager.isWord(sType, DamageTypeManager.get());
end

function get()
	return _damageTypes;
end

function add(sType)
	sType = sType:lower();
	if not DamageTypeManager.isDamageType(sType) then
		table.insert(_damageTypes, sType);
	end
end