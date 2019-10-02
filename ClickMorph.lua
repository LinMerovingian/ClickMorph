ClickMorph = {}
local CM = ClickMorph
CM.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)

-- inventory type -> equipment slot -> slot name
local SlotNames = {
	[INVSLOT_HEAD] = "head", -- 1
	[INVSLOT_SHOULDER] = "shoulder", -- 3
	[INVSLOT_BODY] = "shirt", -- 4
	[INVSLOT_CHEST] = "chest", -- 5
	[INVSLOT_WAIST] = "belt", -- 6
	[INVSLOT_LEGS] = "legs", -- 7
	[INVSLOT_FEET] = "feet", -- 8
	[INVSLOT_WRIST] = "wrist", -- 9
	[INVSLOT_HAND] = "hands", -- 10
	[INVSLOT_BACK] = "cloak", -- 15
	[INVSLOT_MAINHAND] = "mainhand", -- 16
	[INVSLOT_OFFHAND] = "offhand", -- 17
	[INVSLOT_RANGED] = "ranged", -- 18
	[INVSLOT_TABARD] = "tabard", -- 19
}

-- https://wow.gamepedia.com/Enum_Item.InventoryType
local InvTypeToSlot = {
	INVTYPE_HEAD = INVSLOT_HEAD, -- 1
	INVTYPE_SHOULDER = INVSLOT_SHOULDER, -- 3
	INVTYPE_BODY = INVSLOT_BODY, -- 4
	INVTYPE_CHEST = INVSLOT_CHEST, -- 5
	INVTYPE_ROBE = INVSLOT_CHEST, -- 5 (cloth)
	INVTYPE_WAIST = INVSLOT_WAIST, -- 6
	INVTYPE_LEGS = INVSLOT_LEGS, -- 7
	INVTYPE_FEET = INVSLOT_FEET, -- 8
	INVTYPE_WRIST = INVSLOT_WRIST, -- 9
	INVTYPE_HAND = INVSLOT_HAND, -- 10
	INVTYPE_CLOAK = INVSLOT_BACK, -- 15
	INVTYPE_2HWEAPON = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPON = INVSLOT_MAINHAND, -- 17
	INVTYPE_WEAPONMAINHAND = INVSLOT_MAINHAND, -- 16
	INVTYPE_WEAPONOFFHAND = INVSLOT_OFFHAND, -- 17
	INVTYPE_HOLDABLE = INVSLOT_OFFHAND, -- 17
	INVTYPE_RANGED = INVSLOT_RANGED, -- 18
	INVTYPE_THROWN = INVSLOT_RANGED, -- 18
	INVTYPE_RANGEDRIGHT = INVSLOT_RANGED, -- 18
	INVTYPE_SHIELD = INVSLOT_OFFHAND, -- 17
	INVTYPE_TABARD = INVSLOT_TABARD, -- 19
}

local GearSlots = {
	INVSLOT_HEAD, -- 1
	INVSLOT_SHOULDER, -- 3
	INVSLOT_BODY, -- 4
	INVSLOT_CHEST, -- 5
	INVSLOT_WAIST, -- 6
	INVSLOT_LEGS, -- 7
	INVSLOT_FEET, -- 8
	INVSLOT_WRIST, -- 9
	INVSLOT_HAND, -- 10
	INVSLOT_BACK, -- 15
}

local DualWieldSlot = {
	INVTYPE_2HWEAPON = true,
	INVTYPE_WEAPON = true,
	INVTYPE_WEAPONMAINHAND = true,
	INVTYPE_WEAPONOFFHAND = true,
}

local AltenateWeaponSlot = {
	[INVSLOT_MAINHAND] = INVSLOT_OFFHAND,
	[INVSLOT_OFFHAND] = INVSLOT_MAINHAND,
}

function CM:PrintChat(msg, r, g, b)
	DEFAULT_CHAT_FRAME:AddMessage(format("|cff7fff00ClickMorph|r: |r%s", msg), r, g, b)
end

function CM:LoadFileData(addon, frame)
	local loaded, reason = LoadAddOn(addon)
	if not loaded then
		if reason == "DISABLED" then
			EnableAddOn(addon, true)
			LoadAddOn(addon)
		else
			frame:SetScript("OnUpdate", nil) -- cancel wardrobe timer
			self:PrintChat("The ClickMorphData folder could not be found!", 1, 1, 0)
			error(addon..": "..reason)
		end
	end
	local fd = _G[addon]
	return fd:GetItemAppearance(), fd:GetItemVisuals(), fd:GetNpcDisplayIdsClassic()
end

function CM:CanMorph(override)
	if IsAltKeyDown() or override then
		for _, morpher in pairs(self.morphers) do
			if morpher.loaded() then
				return morpher
			end
		end
		self:PrintChat("Could not find any morpher!", 1, 1, 0)
	end
end

function CM:CanMorphMount()
	if IsMounted() and not UnitOnTaxi("player") then
		return true
	else
		CM:PrintChat("You need to be mounted and not on a flight path", 1, 1, 0)
	end
end

CM.morphers = {
	iMorph = { -- classic
		-- morphers can be unloaded and initialized at any later moment
		loaded = function() return IMorphInfo end,
		reset = function() -- todo: add reset to naked
			Reset()
		end,
		model = function(_, displayID)
			Morph(displayID)
		end,
		race = function(_, raceID, genderID)
			SetRace(raceID, genderID)
		end,
		mount = function(displayID)
			if CM:CanMorphMount() then
				SetMount(displayID)
				return true
			end
		end,
		item = function(_, slotID, itemID)
			SetItem(slotID, itemID)
		end,
		itemset = function(itemSetID) -- handled in iMorph Lua
			SetItemSet(itemSetID)
		end,
		--SetEnchant(slotId, enchantId)
		--SetTitle(titleId)
		--SetMedal(medalId)
		--SetFace(face)
		--SetFeatures(feature)
		--SetHairStyle(style)
		--SetHairColor(color)
		--SetSkinColor(color)
	},
	jMorph = { -- retail
		loaded = function() return jMorphLoaded end,
		update = function(unit)
			UpdateModel(unit)
		end,
		model = function(unit, displayID)
			SetDisplayID(unit, displayID)
			UpdateModel(unit)
		end,
		race = function(unit, raceID)
			SetDisplayID(unit, 0)
			SetAlternateRace(unit, raceID)
			UpdateModel(unit)
		end,
		gender = function(unit, genderID, raceID)
			SetGender(unit, genderID)
			SetAlternateRace(unit, raceID)
			UpdateModel(unit)
		end,
		mount = function(displayID)
			if CM:CanMorphMount() then
				SetMountDisplayID("player", displayID)
				MorphPlayerMount()
				return true
			end
		end,
		item = function(unit, slotID, itemID, itemModID)
			SetVisibleItem(unit, slotID, itemID, itemModID)
			-- dont automatically update for every item in an item set
		end,
		enchant = function(unit, slotID, visualID)
			SetVisibleEnchant(unit, slotID, visualID)
			UpdateModel(unit)
		end,
		-- spell (nyi)
		-- title
		-- scale
		-- skin
		-- face
		-- hair
		-- haircolor
		-- piercings
		-- tattoos
		-- horns
		-- blindfold
		-- shapeshift
		-- weather
	},
	LucidMorph = { -- retail
		loaded = function() return lm end,
		model = function(_, displayID)
			lm("model", displayID)
			lm("morph")
		end,
		mount = function(displayID)
			lm("mount", displayID)
			lm("morph")
			return true
		end,
		item = function(_, slotID, itemID, itemModID)
			lm(SlotNames[slotID], itemID, itemModID)
		end,
		update = function()
			lm("morph")
		end,
		enchant = function(_, slotID, visualID)
			lm(SlotNames[slotID], nil, nil, visualID)
			lm("morph")
		end,
	},
}

function CM:ResetMorph()
	local morph = self:CanMorph()
	if morph and morph.reset then
		morph.reset()
	end
end

-- Mounts
function CM:MorphMount(unit, mountID)
	local morph = self:CanMorph()
	if morph and morph.mount then
		local _, spellID = C_MountJournal.GetMountInfoByID(mountID)
		local displayID = C_MountJournal.GetMountInfoExtraByID(mountID)
		if not displayID then
			local multipleIDs = C_MountJournal.GetMountAllCreatureDisplayInfoByID(mountID)
			displayID = multipleIDs[random(#multipleIDs)].creatureDisplayID
		end
		if morph.mount(displayID) then
			CM:PrintChat(format("Morphed mount to |cff71D5FF%d|r %s", displayID, GetSpellLink(spellID)))
		end
	end
end

function CM.MorphMountModelScene()
	local mountID = MountJournal.selectedMountID
	CM:MorphMount("player", mountID)
end

function CM.MorphMountScrollFrame(frame)
	local mountID = select(12, C_MountJournal.GetDisplayedMountInfo(frame.index))
	CM:MorphMount("player", mountID)
end

-- Items
function CM:GetItemInfo(item)
	-- try to preserve item link if we receive one
	if type(item) == "string" then
		local itemID = tonumber(item:match("item:(%d+)"))
		local equipLoc = select(9, GetItemInfo(itemID))
		return itemID, item, equipLoc
	else
		local itemLink, _, _, _, _, _, _, equipLoc = select(2, GetItemInfo(item))
		return item, itemLink, equipLoc
	end
end

local lastWeaponSlot

function CM.MorphItem(item)
	local morph = CM:CanMorph()
	if item and morph and morph.item then
		local itemID, itemLink, equipLoc = CM:GetItemInfo(item)
		local slotID = InvTypeToSlot[equipLoc]
		if slotID then
			if DualWieldSlot[equipLoc] and IsSpellKnown(674) then -- Rogue/Warrior/Hunter Dual Wield
				if lastWeaponSlot then
					slotID = AltenateWeaponSlot[lastWeaponSlot]
				end
				lastWeaponSlot = slotID
			end
			morph.item("player", slotID, itemID)
			CM:PrintChat(format("Morphed |cffFFFF00%s|r to item |cff71D5FF%d:%d|r %s", SlotNames[slotID], itemID, 0, itemLink))
		end
	end
end

hooksecurefunc("HandleModifiedItemClick", CM.MorphItem)

function CM:MorphItemBySource(unit, source)
	local morph = self:CanMorph()
	if morph and morph.item then
		local slotID = C_Transmog.GetSlotForInventoryType(source.invType)
		local itemLink = select(6, C_TransmogCollection.GetAppearanceSourceInfo(source.sourceID))
		local itemText = itemLink:find("%[%]") and CM.ItemAppearance and CM.ItemAppearance[source.visualID] or itemLink
		morph.item(unit, slotID, source.itemID, source.itemModID)
		morph.update(unit)
		self:PrintChat(format("Morphed |cffFFFF00%s|r to item |cff71D5FF%d:%d|r %s", SlotNames[slotID], source.itemID, source.itemModID, itemText))
	end
end

function CM:MorphEnchant(unit, slotID, visualID, enchantName)
	local morph = self:CanMorph()
	if morph and morph.enchant then
		morph.enchant(unit, slotID, visualID)
		self:PrintChat(format("Morphed |cffFFFF00%s|r to enchant |cff71D5FF%d|r %s", SlotNames[slotID], visualID, enchantName))
	end
end

function CM:MorphModel(unit, displayID, npcID, npcName, override)
	local morph = self:CanMorph(override)
	if morph and morph.model then
		morph.model(unit, displayID)
		if npcID and npcName then
			self:PrintChat(format("Morphed to NPC |cffFFFF00%d|r, model |cff71D5FF%d|r, %s", npcID, displayID, npcName))
		else
			self:PrintChat(format("Morphed to model |cff71D5FF%d|r, %s", displayID))
		end
	end
end

-- Appearances
function CM.MorphTransmogSet()
	local morph = CM:CanMorph()
	if morph and morph.item then
		local setID = WardrobeCollectionFrame.SetsCollectionFrame.selectedSetID
		local setInfo = C_TransmogSets.GetSetInfo(setID)

		for _, v in pairs(WardrobeSetsDataProviderMixin:GetSortedSetSources(setID)) do
			local source = C_TransmogCollection.GetSourceInfo(v.sourceID)
			local slotID = C_Transmog.GetSlotForInventoryType(v.invType)
			morph.item("player", SlotNames[slotID], source.itemID, source.itemModID)
		end
		morph.update("player")
		CM:PrintChat(format("Morphed to set |cff71D5FF%d: %s|r (%s)", setID, setInfo.name, setInfo.description or ""))
	end
end

function CM.MorphTransmogItem(frame)
	local transmogType = WardrobeCollectionFrame.ItemsCollectionFrame.transmogType
	local visualID = frame.visualInfo.visualID

	if transmogType == LE_TRANSMOG_TYPE_ILLUSION then
		local activeSlot = WardrobeCollectionFrame.ItemsCollectionFrame.activeSlot
		local slotID = GetInventorySlotInfo(activeSlot)
		local name
		if frame.visualInfo.sourceID then
			local link = select(3, C_TransmogCollection.GetIllusionSourceInfo(frame.visualInfo.sourceID))
			name = #link > 0 and link
		end
		CM:MorphEnchant("player", slotID, visualID, name or CM.ItemVisuals[visualID])
	elseif transmogType == LE_TRANSMOG_TYPE_APPEARANCE then
		local sources = WardrobeCollectionFrame_GetSortedAppearanceSources(visualID)
		for idx, source in pairs(sources) do
			-- get the index the arrow is pointing at
			if idx == WardrobeCollectionFrame.tooltipSourceIndex then
				CM:MorphItemBySource("player", source)
			end
		end
	end
end

function CM:MorphItemSet(itemSetID)
	local morph = CM:CanMorph()
	if morph then
		if morph.item then -- reset gear to naked first
			-- todo: only do it for gear item sets instead of weapon sets
			for _, slot in pairs(GearSlots) do
				morph.item("player", slot, 0)
			end
		end
		if morph.itemset then
			morph.itemset(itemSetID)
		end
	end
end
