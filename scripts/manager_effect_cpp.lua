function onInit()
	EffectManager.registerEffectVar("sUnits", { sDBType = "string", sDBField = "unit", bSkipAdd = true });
	EffectManager.registerEffectVar("sApply", { sDBType = "string", sDBField = "apply", sDisplay = "[%s]" });
	EffectManager.registerEffectVar("sTargeting", { sDBType = "string", bClearOnUntargetedDrop = true });

	EffectManager.setCustomOnEffectAddStart(onEffectAddStart);
	
	EffectManager.setCustomOnEffectRollEncode(onEffectRollEncode);
	EffectManager.setCustomOnEffectTextEncode(onEffectTextEncode);
	EffectManager.setCustomOnEffectTextDecode(onEffectTextDecode);
end

---------------------------------
-- EFFECT MANAGER OVERRIDES
---------------------------------
function onEffectAddStart(rEffect)
	rEffect.nDuration = rEffect.nDuration or 1;
	if rEffect.sUnits == "minute" then
		rEffect.nDuration = rEffect.nDuration * 10;
	elseif rEffect.sUnits == "hour" or rEffect.sUnits == "day" then
		rEffect.nDuration = 0;
	end
	rEffect.sUnits = "";
end

function onEffectRollEncode(rRoll, rEffect)
	if rEffect.sTargeting and rEffect.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end
end

function onEffectTextEncode(rEffect)
	local aMessage = {};
	
	if rEffect.sUnits and rEffect.sUnits ~= "" then
		local sOutputUnits = nil;
		if rEffect.sUnits == "minute" then
			sOutputUnits = "MIN";
		elseif rEffect.sUnits == "hour" then
			sOutputUnits = "HR";
		elseif rEffect.sUnits == "day" then
			sOutputUnits = "DAY";
		end

		if sOutputUnits then
			table.insert(aMessage, "[UNITS " .. sOutputUnits .. "]");
		end
	end
	if rEffect.sTargeting and rEffect.sTargeting ~= "" then
		table.insert(aMessage, string.format("[%s]", rEffect.sTargeting:upper()));
	end
	if rEffect.sApply and rEffect.sApply ~= "" then
		table.insert(aMessage, string.format("[%s]", rEffect.sApply:upper()));
	end
	
	return table.concat(aMessage, " ");
end

function onEffectTextDecode(sEffect, rEffect)
	local s = sEffect;
	
	local sUnits = s:match("%[UNITS ([^]]+)]");
	if sUnits then
		s = s:gsub("%[UNITS ([^]]+)]", "");
		if sUnits == "MIN" then
			rEffect.sUnits = "minute";
		elseif sUnits == "HR" then
			rEffect.sUnits = "hour";
		elseif sUnits == "DAY" then
			rEffect.sUnits = "day";
		end
	end
	if s:match("%[SELF%]") then
		s = s:gsub("%[SELF%]", "");
		rEffect.sTargeting = "self";
	end
	if s:match("%[ACTION%]") then
		s = s:gsub("%[ACTION%]", "");
		rEffect.sApply = "action";
	elseif s:match("%[ROLL%]") then
		s = s:gsub("%[ROLL%]", "");
		rEffect.sApply = "roll";
	elseif s:match("%[SINGLE%]") then
		s = s:gsub("%[SINGLE%]", "");
		rEffect.sApply = "single";
	end
	
	return s;
end

---------------------------------
-- EFFECT GETTERS
---------------------------------
function getEffectsBonusByType(rActor, aEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor or not aEffectType then
		return 0, 0;
	end
	
	-- MAKE BONUS TYPE INTO TABLE, IF NEEDED
	if type(aEffectType) ~= "table" then
		aEffectType = { aEffectType };
	end
	if type(aFilter) ~= "table" then
		aFilter = { aFilter:lower() };
	end
	
	-- PER EFFECT TYPE VARIABLES
	local results = {};
	local bonuses = {};
	local penalties = {};
	local nEffectCount = 0;

	for k, v in pairs(aEffectType) do
		-- LOOK FOR EFFECTS THAT MATCH BONUSTYPE
		local aEffectsByType = getEffectsByType(rActor, v, aFilter, rFilterActor, bTargetedOnly);

		-- ITERATE THROUGH EFFECTS THAT MATCHED
		for k2,v2 in pairs(aEffectsByType) do
			-- {type = STAT, remainder = {}, original = STATS: +1, dice = {}, mod = 1}

			-- Add matched effect to results table
			table.insert(results, v2)

			-- ADD TO EFFECT COUNT
			nEffectCount = nEffectCount + 1;
		end
	end

	local nBonus = 0;
	for k,v in pairs(results) do
		nBonus = nBonus + v.mod;
	end

	return nBonus, nEffectCount;
end

function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local results = {};
	aFilter = toLower(aFilter);
	
	-- Iterate through effects
	for _,v in pairs(DB.getChildren(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		if (nActive ~= 0) then
			local sLabel = DB.getValue(v, "label", "");
			local sApply = DB.getValue(v, "apply", "");

			-- IF COMPONENT WE ARE LOOKING FOR SUPPORTS TARGETS, THEN CHECK AGAINST OUR TARGET
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local aEffectComps = EffectManager.parseEffect(sLabel);

				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp,sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager.parseEffectCompSimple(sEffectComp);
										
					-- Check for match
					local comp_match = false;
					if rEffectComp.type:lower() == sEffectType:lower() then

						-- Check effect targeting
						if bTargetedOnly and not bTargeted then
							comp_match = false;
						else
							comp_match = true;
						end

						-- Check filters
						if #aFilter > 0 then
							local bMatch = true;
							-- No remainder matches with anything
							-- So we skip this check
							if #(rEffectComp.remainder) > 0 then
								-- Match against all effect tags, or don't match at all
								for _,tag in pairs(rEffectComp.remainder) do
									if not StringManager.contains(aFilter, tag:lower()) then
										bMatch = false;
										break;
									end
								end
							end
							if not bMatch then
								comp_match = false;
							end
						end
					end

					-- Match!
					if comp_match then
						nMatch = kEffectComp;
						if nActive == 1 then
							table.insert(results, rEffectComp);
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	-- RESULTS
	return results;
end

function toLower(aList)
	local temp = {};
	for k,v in ipairs(aList) do
		temp[k] = v:lower();
	end
	return temp;
end