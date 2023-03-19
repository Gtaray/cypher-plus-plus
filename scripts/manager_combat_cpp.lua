local _fOnNPCPostAdd = nil;
function onInit()
	_fOnNPCPostAdd = CombatManager2.onNPCPostAdd;

	CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd)
end

function onNPCPostAdd(tCustom)
	_fOnNPCPostAdd(tCustom);

	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	local sModifications = DB.getValue(tCustom.nodeCT, "modifications", "");
	local aEffects = CombatManagerCPP.parseNpcModifications(sModifications, tCustom.nodeCT);
	for _, effect in ipairs(aEffects) do
		EffectManager.addEffect(nil, nil, tCustom.nodeCT, effect, false);
	end
end

function parseNpcModifications(sText, nodeCreature)
	-- Get rid of some problem characters, and make lowercase
	local sLocal = sText:gsub("’", "'");
	sLocal = sLocal:gsub("–", "-");
	sLocal = sLocal:lower();

	-- Parse the words
	local aWords, aWordStats = StringManager.parseWords(sLocal, ".:;\n");

	-- Add/separate markers for end of sentence, end of clause and clause label separators
	-- aWords, aWordStats = CombatManagerCPP.parseHelper(sPowerDesc, aWords, aWordStats);

	-- Build Effects
	return CombatManagerCPP.parseModification(aWords, nodeCreature)
end

-- Adds markers for end of sentence, end of clause, and clause label separators
function parseHelper(s, words, words_stats)
	local final_words = {};
	local final_words_stats = {};
	
	-- Separate words ending in periods, colons and semicolons
	for i = 1, #words do
	  local nSpecialChar = string.find(words[i], "[%.:;\n]");
	  if nSpecialChar then
		  local sWord = words[i];
		  local nStartPos = words_stats[i].startpos;
		  while nSpecialChar do
			  if nSpecialChar > 1 then
				  table.insert(final_words, string.sub(sWord, 1, nSpecialChar - 1));
				  table.insert(final_words_stats, {startpos = nStartPos, endpos = nStartPos + nSpecialChar - 1});
			  end
			  
			  table.insert(final_words, string.sub(sWord, nSpecialChar, nSpecialChar));
			  table.insert(final_words_stats, {startpos = nStartPos + nSpecialChar - 1, endpos = nStartPos + nSpecialChar});
			  
			  nStartPos = nStartPos + nSpecialChar;
			  sWord = string.sub(sWord, nSpecialChar + 1);
			  
			  nSpecialChar = string.find(sWord, "[%.:;\n]");
		  end
		  if string.len(sWord) > 0 then
			  table.insert(final_words, sWord);
			  table.insert(final_words_stats, {startpos = nStartPos, endpos = words_stats[i].endpos});
		  end
	  else
		  table.insert(final_words, words[i]);
		  table.insert(final_words_stats, words_stats[i]);
	  end
	end
	
  return final_words, final_words_stats;
end

function parseModification(aWords, nodeCreature)
	local effects = {};
	local i = 1;
	while aWords[i] do
		local effect = nil;

		-- Look for defense modification
		if StringManager.isWord(aWords[i], {"defense", "defends" }) then
			i, effect = parseDefenseModification(aWords, i, nodeCreature);
		-- Look for attack modification
		elseif StringManager.isWord(aWords[i], "attacks") then
			i, effect = parseAttackModification(aWords, i, nodeCreature);
		end

		if effect then
			table.insert(effects, effect);
		end

		i = i + 1;
	end

	return effects
end

function parseDefenseModification(aWords, i, nodeCreature)
	local sStat = nil;
	local nLevel = nil;
	if aWords[i - 1] and StringManager.isWord(aWords[i - 1], { "might", "speed", "intellect"}) then
		sStat = aWords[i - 1];
	end
	if aWords[i + 1] and StringManager.isWord(aWords[i + 1], "as")
		and aWords[i + 2] and StringManager.isWord(aWords[i + 2], "level")
		and aWords[i + 3] and tonumber(aWords[i + 3]) then
		nLevel = tonumber(aWords[i + 3]);
		i = i + 3
	end

	local effect = nil;

	-- stat is optional, level is not.
	if nLevel ~= nil then
		local nCreatureLevel = ActorManagerCPP.getCreatureLevel(nodeCreature);

		-- We want the difference between the state level and creature level
		-- so we know what mod the effect should have
		nLevel = nLevel - nCreatureLevel
		local sName = string.format("LEVEL: %s defense", nLevel);
		if sStat then
			sName = string.format("%s, %s", sName, sStat);
		end
		effect = {
			nGMOnly = 1,
			sName = sName
		}
	end
	return i, effect
end

function parseAttackModification(aWords, i, nodeCreature)
	local sStat = nil;
	local nLevel = nil;
	if aWords[i - 1] and StringManager.isWord(aWords[i - 1], { "might", "speed", "intellect"}) then
		sStat = aWords[i - 1];
	end
	if aWords[i + 1] and StringManager.isWord(aWords[i + 1], "as")
		and aWords[i + 2] and StringManager.isWord(aWords[i + 2], "level")
		and aWords[i + 3] and tonumber(aWords[i + 3]) then
		nLevel = tonumber(aWords[i + 3]);
		i = i + 3
	end

	local effect = nil;

	-- stat is optional, level is not.
	if nLevel ~= nil then
		local nCreatureLevel = ActorManagerCPP.getCreatureLevel(nodeCreature);

		-- We want the difference between the state level and creature level
		-- so we know what mod the effect should have
		nLevel = nLevel - nCreatureLevel
		local sName = string.format("LEVEL: %s attack", nLevel);
		if sStat then
			sName = string.format("%s, %s", sName, sStat);
		end
		effect = {
			nGMOnly = 1,
			sName = sName
		}
	end
	return i, effect
end