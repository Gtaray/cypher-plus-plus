function onInit()
	EffectManager.setCustomOnEffectRollEncode(onEffectRollEncode);
end

---------------------------------
-- EFFECT MANAGER OVERRIDES
---------------------------------
function onEffectRollEncode(rRoll, rEffect)
	if rEffect.sTargeting and rEffect.sTargeting == "self" then
		rRoll.bSelfTarget = true;
	end
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
		aFilter = { aFilter };
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
									if not StringManager.contains(aFilter, tag) then
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