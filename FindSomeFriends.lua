
FSF = {};
FSF.fully_loaded = false;
FSF.default_options = {

	-- main frame position
	frameRef = "CENTER",
	frameX = 0,
	frameY = 0,
	hide = false,

	-- sizing
	frameW = 200,
	frameH = 200,

	-- the 'invited' list
	invited = {},
};
FSF.waiting_on_whois = false;
FSF.last_filter = '';
FSF.invites_pending = {};
FSF.all_buttons = {};
FSF.last_btn_id = nil;


function FSF.OnReady()

	-- set up default options
	_G.FindSomeFriendsDB = _G.FindSomeFriendsDB or {};

	for k,v in pairs(FSF.default_options) do
		if (not _G.FindSomeFriendsDB[k]) then
			_G.FindSomeFriendsDB[k] = v;
		end
	end

	FSF.CreateUIFrame();
end

function FSF.OnSaving()

	if (FSF.UIFrame) then
		local point, relativeTo, relativePoint, xOfs, yOfs = FSF.UIFrame:GetPoint()
		_G.FindSomeFriendsDB.frameRef = relativePoint;
		_G.FindSomeFriendsDB.frameX = xOfs;
		_G.FindSomeFriendsDB.frameY = yOfs;
	end
end

function FSF.OnUpdate()
	if (not FSF.fully_loaded) then
		return;
	end

	if (_G.FindSomeFriendsDB.hide) then 
		return;
	end

	FSF.UpdateFrame();
end

function FSF.OnEvent(frame, event, ...)

	if (event == 'ADDON_LOADED') then
		local name = ...;
		if name == 'FindSomeFriends' then
			FSF.OnReady();
		end
		return;
	end

	if (event == 'PLAYER_LOGIN') then

		FSF.fully_loaded = true;
		return;
	end

	if (event == 'PLAYER_LOGOUT') then
		FSF.OnSaving();
		return;
	end

	if (event == 'WHO_LIST_UPDATE') then
		if (FSF.waiting_on_whois) then
			FSF.ScanWho();
		end
	end
end

function FSF.CreateUIFrame()

	local prefs = _G.FindSomeFriendsDB;

	-- create the UI frame
	FSF.UIFrame = CreateFrame("Frame",nil,UIParent);
	FSF.UIFrame:SetFrameStrata("BACKGROUND")
	FSF.UIFrame:SetWidth(prefs.frameW);
	FSF.UIFrame:SetHeight(prefs.frameH);

	-- make it black
	FSF.UIFrame.texture = FSF.UIFrame:CreateTexture();
	FSF.UIFrame.texture:SetAllPoints(FSF.UIFrame);
	FSF.UIFrame.texture:SetTexture(0, 0, 0);

	-- position it
	FSF.UIFrame:SetPoint(prefs.frameRef, prefs.frameX, prefs.frameY);

	-- make it draggable
	FSF.UIFrame:SetMovable(true);
	FSF.UIFrame:EnableMouse(true);

	-- create a button that covers the entire addon
	FSF.Cover = CreateFrame("Button", nil, FSF.UIFrame);
	FSF.Cover:SetFrameLevel(128);
	FSF.Cover:SetPoint("TOPLEFT", 0, 0);
	FSF.Cover:SetWidth(prefs.frameW);
	FSF.Cover:SetHeight(prefs.frameH);
	FSF.Cover:EnableMouse(true);
	FSF.Cover:RegisterForClicks("AnyUp");
	FSF.Cover:RegisterForDrag("LeftButton");
	FSF.Cover:SetScript("OnDragStart", FSF.OnDragStart);
	FSF.Cover:SetScript("OnDragStop", FSF.OnDragStop);
	FSF.Cover:SetScript("OnClick", FSF.OnClick);

	-- add a main label - just so we can show something
	FSF.Label = FSF.Cover:CreateFontString(nil, "OVERLAY");
	FSF.Label:SetPoint("CENTER", FSF.UIFrame, "CENTER", 2, -10);
	FSF.Label:SetJustifyH("LEFT");
	FSF.Label:SetFont([[Fonts\FRIZQT__.TTF]], 12, "OUTLINE");
	FSF.Label:SetText(" ");
	FSF.Label:SetTextColor(1,1,1,1);
	FSF.SetFontSize(FSF.Label, 20);


	-- some simple scan buttons
	local pad = 5;
	local w = 60;
	local h = 24;

	FSF.CreateButton('btn1', FSF.UIFrame, pad+((w+pad)*0), pad+((h+pad)*0), w, h, "1-9"  , function() FSF.StartScan('btn1', "1-9"  ); end);
	FSF.CreateButton('btn2', FSF.UIFrame, pad+((w+pad)*1), pad+((h+pad)*0), w, h, "10-19", function() FSF.StartScan('btn2', "10-19"); end);
	FSF.CreateButton('btn3', FSF.UIFrame, pad+((w+pad)*2), pad+((h+pad)*0), w, h, "20-29", function() FSF.StartScan('btn3', "20-29"); end);

	FSF.CreateButton('btn4', FSF.UIFrame, pad+((w+pad)*0), pad+((h+pad)*1), w, h, "30-39", function() FSF.StartScan('btn4', "30-39"); end);
	FSF.CreateButton('btn5', FSF.UIFrame, pad+((w+pad)*1), pad+((h+pad)*1), w, h, "40-49", function() FSF.StartScan('btn5', "40-49"); end);
	FSF.CreateButton('btn6', FSF.UIFrame, pad+((w+pad)*2), pad+((h+pad)*1), w, h, "50-59", function() FSF.StartScan('btn6', "50-59"); end);

	FSF.CreateButton('btn7', FSF.UIFrame, pad+((w+pad)*0), pad+((h+pad)*2), w, h, "60-69", function() FSF.StartScan('btn7', "60-69"); end);
	FSF.CreateButton('btn8', FSF.UIFrame, pad+((w+pad)*1), pad+((h+pad)*2), w, h, "70-79", function() FSF.StartScan('btn8', "70-79"); end);
	--FSF.CreateButton('btn9', FSF.UIFrame, pad+((w+pad)*2), pad+((h+pad)*2), w, h, "80-89", function() FSF.StartScan('btn9', "80-89"); end);

	FSF.CreateButton('btn10', FSF.UIFrame, pad, 130, 190, 30, "Just Invite", function() FSF.InviteNext(false); end);
	FSF.CreateButton('btn11', FSF.UIFrame, pad, 165, 190, 30, "Whisper & Invite", function() FSF.InviteNext(true); end);
end

function FSF.CreateButton(id, parent, x, y, w, h, label, onclick)

	local b = CreateFrame("Button", id, parent, "UIPanelButtonTemplate");
	b:SetPoint("TOPLEFT", x, 0-y);
	b:SetWidth(w);
	b:SetHeight(h);
	b:SetNormalTexture(texture);

	b.text = b:GetFontString();
	b.text:SetPoint("LEFT", b, "LEFT", 7, 0);
	b.text:SetPoint("RIGHT", b, "RIGHT", -7, 0);

	b:SetScript("OnClick", onclick);
	b:RegisterForClicks("AnyDown");

	b:SetText(label);
	b:SetNormalFontObject("GameFontNormal");

	b:SetFrameLevel(129);
	b:EnableMouse();

	FSF.all_buttons[id] = b;
end

function FSF.SetFontSize(string, size)

	local Font, Height, Flags = string:GetFont()
	if (not (Height == size)) then
		string:SetFont(Font, size, Flags)
	end
end

function FSF.OnDragStart(frame)
	FSF.UIFrame:StartMoving();
	FSF.UIFrame.isMoving = true;
	GameTooltip:Hide()
end

function FSF.OnDragStop(frame)
	FSF.UIFrame:StopMovingOrSizing();
	FSF.UIFrame.isMoving = false;
end

function FSF.OnClick(self, aButton)
	if (aButton == "RightButton") then
		print("show menu here!");
	end
end

function FSF.UpdateFrame()

	local i;
	local c = 0;
	for i in pairs(FSF.invites_pending) do
		c = c + 1;
	end

	-- update the main frame state here
	FSF.Label:SetText(string.format("%d in queue", c));
end


function FSF.ScanWho()

	if (FSF.last_btn_id) then
		local id, btn;
		for id, btn in pairs(FSF.all_buttons) do
			if (id == FSF.last_btn_id) then
				btn.text:SetTextColor(1,1,1);
			else
				btn.text:SetTextColor(1,1,0);			
			end
		end
		FSF.last_btn_id = nil;
	end

	local total, num = GetNumWhoResults();

	local num_invite = 0;
	local num_dupe = 0;
	local num_guild = 0;
	local num_already_invited = 0;

	local i;
	for i=1,num do
		local name, guild, level, race, class, zone, classFileName = GetWhoInfo(i);
		if (not (guild == "")) then
			num_guild = num_guild + 1;
		elseif (_G.FindSomeFriendsDB.invited[name]) then
			num_already_invited = num_already_invited + 1;
		elseif (FSF.invites_pending[name]) then
			num_dupe = num_dupe + 1;
		else
			num_invite = num_invite + 1;
			FSF.invites_pending[name] = 1;
		end
	end

	print(string.format("%s: %d added, %d skipped, %d guilded, %d old", FSF.last_filter, num_invite, num_dupe, num_guild, num_already_invited));

	if (total > num) then
		print("We found more matches than we can show - try narrowing your filter!");
	end

	FSF.StopWaiting();
end

function FSF.StartScan(btn_id, filter)

	FSF.StartWaiting();
	SetWhoToUI(1);
	FSF.last_filter = filter;
	FSF.last_btn_id = btn_id;
	SendWho(filter);
end

function FSF.StartWaiting()
	FSF.waiting_on_whois = true;
end

function FSF.StopWaiting()
	FSF.waiting_on_whois = false;
end

function FSF.InviteNext(whisper)

	local i;
	for i,v in pairs(FSF.invites_pending) do
		FSF.DoInvite(i, whisper);
		FSF.invites_pending[i] = nil;
		_G.FindSomeFriendsDB.invited[i] = 1;
		return;
	end
end

function FSF.DoInvite(name, whisper)

	--print(string.format("DoInvite: %s", name));

	if (whisper) then
		local msg = "<Not Your Typical Heroes> is a new guild for players of any level who are interested in questing, dungeons, pvp or just hanging out and playing WoW!";
		SendChatMessage(msg, "WHISPER", nil, name);
	end

	GuildInvite(name);
end


FSF.EventFrame = CreateFrame("Frame");
FSF.EventFrame:Show();
FSF.EventFrame:SetScript("OnEvent", FSF.OnEvent);
FSF.EventFrame:SetScript("OnUpdate", FSF.OnUpdate);
FSF.EventFrame:RegisterEvent("ADDON_LOADED");
FSF.EventFrame:RegisterEvent("PLAYER_LOGIN");
FSF.EventFrame:RegisterEvent("PLAYER_LOGOUT");
FSF.EventFrame:RegisterEvent("WHO_LIST_UPDATE");

