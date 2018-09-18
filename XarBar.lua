local XarBar = LibStub("AceAddon-3.0"):NewAddon("XarBar", "AceConsole-3.0", "AceEvent-3.0");

local MAX_BUFFS = 32;
local MAX_DEBUFFS = 32;

local BuffsFrame = CreateFrame("Frame", "XarBarBuffs");
local DebuffsFrame = CreateFrame("Frame", "XarBarDebuffs");
BuffsFrame:SetSize(10, 10);
DebuffsFrame:SetSize(10, 10);

local function UpdateBuffAnchor(self, buffName, index, numDebuffs, newRow, startX, startY)
	local buff = _G[buffName..index];
	
	if ( index == 1 ) then
		if ( XarBar.db.profile.buffsOnTop or numDebuffs == 0 ) then
			-- XarBar.db.profile.buffsOnTop is true or there are no debuffs... buffs start on top
			buff:SetPoint("TOPLEFT", self, "BOTTOMLEFT", startX, startY);
		else
			-- XarBar.db.profile.buffsOnTop is false and we have debuffs...buffs start on bottom
			buff:SetPoint("TOPLEFT", DebuffsFrame, "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
		end
		BuffsFrame:SetPoint("TOPLEFT", buff, "TOPLEFT", 0, 0);
		BuffsFrame:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
	elseif ( newRow ) then
		buff:SetPoint("TOPLEFT", _G[buffName..(index - XarBar.db.profile.maxRowSize)], "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
		BuffsFrame:SetPoint("BOTTOMLEFT", buff, "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
	else
		buff:SetPoint("TOPLEFT", _G[buffName..(index - 1)], "TOPRIGHT", XarBar.db.profile.auraSpacingX, 0);
	end

	-- Resize
	buff:SetWidth(XarBar.db.profile.auraIconSize);
	buff:SetHeight(XarBar.db.profile.auraIconSize);
end

local function UpdateDebuffAnchor(self, debuffName, index, numBuffs, newRow, startX, startY)
	local debuff = _G[debuffName..index];

	if ( index == 1 ) then
		if ( XarBar.db.profile.buffsOnTop and numBuffs > 0 ) then
			-- XarBar.db.profile.buffsOnTop is true and there are buffs... debuffs start on bottom
			debuff:SetPoint("TOPLEFT", BuffsFrame, "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
		else
			-- XarBar.db.profile.buffsOnTop is false or there are no buffs... debuffs start on top
			debuff:SetPoint("TOPLEFT", self, "BOTTOMLEFT", startX, startY);
		end
		DebuffsFrame:SetPoint("TOPLEFT", debuff, "TOPLEFT", 0, 0);
		DebuffsFrame:SetPoint("BOTTOMLEFT", debuff, "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
	elseif ( newRow ) then
		debuff:SetPoint("TOPLEFT", _G[debuffName..(index - XarBar.db.profile.maxRowSize)], "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
		DebuffsFrame:SetPoint("BOTTOMLEFT", debuff, "BOTTOMLEFT", 0, -XarBar.db.profile.auraSpacingY);
	else
		debuff:SetPoint("TOPLEFT", _G[debuffName..(index - 1)], "TOPRIGHT", XarBar.db.profile.auraSpacingX + 1, 0);
	end

	-- Resize
	debuff:SetWidth(XarBar.db.profile.auraIconSize);
	debuff:SetHeight(XarBar.db.profile.auraIconSize);
	
	local debuffFrame =_G[debuffName..index.."Border"];
	debuffFrame:SetWidth(XarBar.db.profile.auraIconSize+2);
	debuffFrame:SetHeight(XarBar.db.profile.auraIconSize+2);
end

local function UpdateAuraPositions(self, auraName, numAuras, numOppositeAuras, updateFunc)
	local startX, startY;
	if ( PetFrame and PetFrame:IsShown() ) then
		startX, startY = XarBar.db.profile.auraPetStartX, XarBar.db.profile.auraPetStartY;
	else
		startX, startY = XarBar.db.profile.auraStartX, XarBar.db.profile.auraStartY;
	end

	-- current width of a row, increases as auras are added and resets when a new aura's width exceeds the max row width
	local rowSize = 0;
	for i=1, numAuras do
		-- anchor the current aura
		if ( i == 1 ) then
			rowSize = 1;
		else
			rowSize = rowSize + 1;
		end
		if ( rowSize > XarBar.db.profile.maxRowSize ) then
			-- this aura would cause the current row to exceed the max row size, so make this aura
			-- the start of a new row instead
			rowSize = 1;
			updateFunc(self, auraName, i, numOppositeAuras, true, startX, startY);
		else
			updateFunc(self, auraName, i, numOppositeAuras, false, startX, startY);
		end
	end
end

local function UpdateAuras()
	local self = PlayerFrame;
	local frame, frameName;
	local frameIcon, frameCount, frameCooldown;
	local numBuffs = 0;
	
	for i = 1, XarBar.db.profile.maxBuffs do
		local buffName, icon, count, _, duration, expirationTime = UnitBuff(self.unit, i, nil);
		if ( buffName ) then
			frameName = "XarBarBuff"..(i);
			frame = _G[frameName];
			if ( not frame ) then
				if ( not icon ) then
					break;
				else
					frame = CreateFrame("Button", frameName, self, "TargetBuffFrameTemplate");
					frame.unit = self.unit;
				end
			end
			if ( icon ) then
				frame:SetID(i);
				
				-- set the icon
				frameIcon = _G[frameName.."Icon"];
				frameIcon:SetTexture(icon);
				
				-- set the count
				frameCount = _G[frameName.."Count"];
				if ( count > 1 and XarBar.db.profile.showAuraCount ) then
					frameCount:SetText(count);
					frameCount:Show();
				else
					frameCount:Hide();
				end
				
				-- Handle cooldowns
				frameCooldown = _G[frameName.."Cooldown"];
				CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);
				
				numBuffs = numBuffs + 1;

				frame:ClearAllPoints();
				frame:Show();
			else
				frame:Hide();
			end
		else
			break;
		end
	end
	
	for i = numBuffs + 1, MAX_BUFFS do
		local frame = _G["XarBarBuff"..i];
		if ( frame ) then
			frame:Hide();
		else
			break;
		end
	end
	
	local color;
	local frameBorder;
	local numDebuffs = 0;
	
	for i = 1, XarBar.db.profile.maxDebuffs do
		local debuffName, icon, count, debuffType, duration, expirationTime = UnitDebuff(self.unit, i, nil);
		if ( debuffName ) then
			frameName = "XarBarDebuff"..(i);
			frame = _G[frameName];
			if ( not frame ) then
				if ( not icon ) then
					break;
				else
					frame = CreateFrame("Button", frameName, self, "TargetDebuffFrameTemplate");
					frame.unit = self.unit;
				end
			end
			if ( icon ) then
				frame:SetID(i);
				
				-- set the icon
				frameIcon = _G[frameName.."Icon"];
				frameIcon:SetTexture(icon);
				
				-- set the count
				frameCount = _G[frameName.."Count"];
				if ( count > 1 and XarBar.db.profile.showAuraCount ) then
					frameCount:SetText(count);
					frameCount:Show();
				else
					frameCount:Hide();
				end
				
				-- Handle cooldowns
				frameCooldown = _G[frameName.."Cooldown"];
				CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);
				
				-- set debuff type color
				if ( debuffType ) then
					color = DebuffTypeColor[debuffType];
				else
					color = DebuffTypeColor["none"];
				end
				frameBorder = _G[frameName.."Border"];
				frameBorder:SetVertexColor(color.r, color.g, color.b);
				
				numDebuffs = numDebuffs + 1;

				frame:ClearAllPoints();
				frame:Show();
			else
				frame:Hide();
			end
		else
			break;
		end
	end
	
	for i = numDebuffs + 1, MAX_DEBUFFS do
		local frame = _G["XarBarDebuff"..i];
		if ( frame ) then
			frame:Hide();
		else
			break;
		end
	end
	
	-- update buff positions
	UpdateAuraPositions(self, "XarBarBuff", numBuffs, numDebuffs, UpdateBuffAnchor);
	
	-- update debuff positions
	UpdateAuraPositions(self, "XarBarDebuff", numDebuffs, numBuffs, UpdateDebuffAnchor);
end

local function OnEvent (event, ...)
	local arg1 = ...;
	
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		UpdateAuras();
	elseif ( event == "UNIT_AURA" ) then
		if ( arg1 == "player" ) then
			UpdateAuras();
		end
	elseif ( event == "UNIT_PET" ) then
		if ( arg1 == "player" ) then
			UpdateAuras();
		end
	elseif ( event == "UNIT_ENTERED_VEHICLE" ) then
		if ( arg1 == "player" ) then
			UpdateAuras();
		end
	elseif ( event == "UNIT_EXITED_VEHICLE" ) then
		if ( arg1 == "player" ) then
			UpdateAuras();
		end
	end
end

local defaults = {
	profile = {
		auraIconSize = 17,
		maxBuffs = 32,
		maxDebuffs = 16,
		maxRowSize = 6,
		showAuraCount = true,
		buffsOnTop = true,
		auraSpacingX = 3,
		auraSpacingY = 3,
		auraStartX = 108,
		auraStartY = 32,
		auraPetStartX = 108,
		auraPetStartY = -8,
	},
}

local options = {
    name = "XarBar",
    handler = XarBar,
    type = 'group',
    args = {
		general = {
			name = "General",
			type = "group",
			order = 1,
			get = function(info) return XarBar.db.profile[info[#info]] end,
			set = function(info, val) XarBar.db.profile[info[#info]] = val; UpdateAuras(); end,
			args = {
				auraIconSize = {
					name = "Aura Icon Size",
					desc = "Size of the aura icons",
					type = "range",
					order = 1,
					min = 6,
					max = 52,
					step = 1,
				},
				maxRowSize = {
					name = "Max Icons Per Row",
					desc = "Maximum number of auras per row",
					type = "range",
					order = 2,
					min = 1,
					max = 16,
					step = 1,
				},
				maxGroup = {
					name = "Max # of icons",
					type = "group",
					order = 3,
					inline = true,
					args = {
						maxBuffs = {
							name = "Buffs",
							desc = "Maximum number of buffs shown",
							type = "range",
							order = 1,
							min = 1,
							max = 32,
							step = 1,
						},
						maxDebuffs = {
							name = "Debuffs",
							desc = "Maximum number of debuffs shown",
							type = "range",
							order = 2,
							min = 1,
							max = 32,
							step = 1,
						},
					},
				},
				spacingGroup = {
					name = "Spacing",
					type = "group",
					order = 4,
					inline = true,
					args = {
						auraSpacingX = {
							name = "Horizontal",
							desc = "Horizontal spacing between each aura",
							type = "range",
							order = 1,
							min = 0,
							max = 32,
							step = 1,
						},
						auraSpacingY = {
							name = "Vertical",
							desc = "Vertical spacing between each aura",
							type = "range",
							order = 2,
							min = 0,
							max = 32,
							step = 1,
						},
					},
				},
				positioningGroup = {
					name = "Positioning (without pet)",
					type = "group",
					order = 5,
					inline = true,
					args = {
						auraStartX = {
							name = "X Offset",
							type = "range",
							order = 1,
							softMin = -200,
							softMax = 200,
							min = -600,
							max = 600,
							step = 1,
						},
						auraStartY = {
							name = "Y Offset",
							type = "range",
							order = 2,
							softMin = -200,
							softMax = 200,
							min = -600,
							max = 600,
							step = 1,
						},
					},
				},
				petPositioningGroup = {
					name = "Positioning (with pet)",
					type = "group",
					order = 6,
					inline = true,
					args = {
						auraPetStartX = {
							name = "X Offset",
							type = "range",
							order = 1,
							softMin = -200,
							softMax = 200,
							min = -600,
							max = 600,
							step = 1,
						},
						auraPetStartY = {
							name = "Y Offset",
							type = "range",
							order = 2,
							softMin = -200,
							softMax = 200,
							min = -600,
							max = 600,
							step = 1,
						},
					},
				},
				showAuraCount = {
					name = "Show Aura Count",
					desc = "Show the count for auras that have stacks (e.g. Earth Shield)",
					type = "toggle",
					order = 7,
					width = "normal",
				},
				buffsOnTop = {
					name = "Buffs on Top",
					desc = "Buffs will be shown first, debuffs second",
					type = "toggle",
					order = 8,
					width = "normal",
				},
			},
		},
        
    },
}

function XarBar:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("XarBarDB", defaults, true);
	self.db.RegisterCallback(self, "OnProfileChanged", UpdateAuras);
	self.db.RegisterCallback(self, "OnProfileCopied", UpdateAuras);
	self.db.RegisterCallback(self, "OnProfileReset", UpdateAuras);
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db);
	LibStub("AceConfig-3.0"):RegisterOptionsTable("XarBar", options);
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XarBar");
	self:RegisterChatCommand("xarbar", function() LibStub("AceConfigDialog-3.0"):Open("XarBar") end);
	self:RegisterChatCommand("xb", function() LibStub("AceConfigDialog-3.0"):Open("XarBar") end);
	
	self:RegisterEvent("PLAYER_ENTERING_WORLD", OnEvent);
	self:RegisterEvent("UNIT_AURA", OnEvent);
	self:RegisterEvent("UNIT_PET", OnEvent);
	self:RegisterEvent("UNIT_ENTERED_VEHICLE", OnEvent);
	self:RegisterEvent("UNIT_EXITED_VEHICLE", OnEvent);
end