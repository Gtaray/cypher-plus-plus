aRecordOverrides = {
	["ability"] = {
		bExport = true,
		aDataMap = { "ability", "reference.ability" },
		sRecordDisplayClass = "reference_ability",
		aCustomFilters = {
			["Type"] = { sField = "type" }
		}
	}
}

function onInit()
	for kRecordType,vRecordType in pairs(aRecordOverrides) do
		LibraryData.overrideRecordTypeInfo(kRecordType, vRecordType);
	end
end