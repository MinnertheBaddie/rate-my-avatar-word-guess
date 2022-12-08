local plrs = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local chatService = game:GetService("TextChatService")
local lplr = plrs.LocalPlayer
local boothUpdate = replicatedStorage.CustomiseBooth
local chatted = replicatedStorage:FindFirstChild("DefaultChatSystemChatEvents").OnMessageDoneFiltering
local chatVersion = chatService.ChatVersion
local messages = {
	"Tip: Word detection is caps insensitive so no matter if you type like THIS, This, or tHiS I will detect what you chat.",
	"You probably don't own an air fryer.",
	"McDonalds fixed the ice cream machine.",
	"Players who spam every letter in one message have no skill and ruin the game for others.",
}
local points = {}
local rounds = 6
local roundTime = 30

if _G.useBoothSignAsRangeBase == nil then
	_G.useBoothSignAsRangeBase = true -- if false you must stay at your booth, but chat messages will be enabled
end

local function getBooth()
	for _, booth in pairs(game.Workspace:GetChildren()) do
		if booth:GetAttribute("TenantUsername") == lplr.Name then
			return booth
		end
	end
end
local function getRangeBase()
	if not _G.useBoothSignAsRangeBase and lplr.Character and lplr.Character:FindFirstChild("Head") then
		return lplr.Character:FindFirstChild("Head")
	end

	return getBooth().Banner
end
local function chat(msg)
	if _G.useBoothSignAsRangeBase then
		return
	end

	if chatVersion == Enum.ChatVersion.LegacyChatService then
		replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
	else
		chatService.TextChannels.RBXGeneral:SendAsync(msg)
	end
end
local function randomCategory(categories: table)
	local array = {}
	local name
	for i in pairs(categories) do
		table.insert(array, i)
	end
	local randomNum = math.random(1, #array)
	return categories[array[randomNum]]
end
local function sortLeaderboard()
	local players = plrs:GetPlayers()
	if players[1] == lplr then
		table.remove(players, 1)
	end
	table.sort(players, function(p1, p2)
		return points[p1.UserId] > points[p2.UserId]
	end)
	return players
end
local function displayLeaderboard()
	local leaderboardTable = sortLeaderboard()
	local leaderboard = "Leaderboard"

	for i = 1, 4, 1 do
		leaderboard ..= "\n" .. leaderboardTable[i].Name .. ": 💠 " .. points[leaderboardTable[i].UserId]
	end
	boothUpdate:FireServer("Update", {
		["DescriptionText"] = leaderboard,
		["ImageId"] = 0,
	})
	print(leaderboard)
	task.wait(0.5)
	for _, booth in pairs(game.Workspace:GetChildren()) do
		if booth:GetAttribute("TenantUsername") == lplr.Name then
			if string.find(booth.Banner.SurfaceGui.Frame.Description.Text, "#####################") then
				boothUpdate:FireServer("Update", {
					["DescriptionText"] = "the leaderboard was filtered by roblox >:(",
					["ImageId"] = 0,
				})
			end
		end
	end
end
local function trim(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end
local function updateSign(text: string, category: string, round: number, timeLeft: number, icon: number)
	boothUpdate:FireServer("Update", {
		["DescriptionText"] = "[🕹️] word guess ("..tostring(round).."/"..tostring(rounds)..")\n[🔤] "..text.."\ncategory: "..category.."\n[⏰]"..timeLeft,
		["ImageId"] = icon,
	})
end
plrs.PlayerRemoving:Connect(function(plr)
	if points[plr.UserId] then
		points[plr.UserId] = nil
	end
end)
plrs.PlayerAdded:Connect(function(plr)
	points[plr.UserId] = 0
end)
task.spawn(function()
	while true do
		task.wait(120)
		chat(messages[math.random(1, #messages)])
	end
end)
task.spawn(function()
	local myBooth = getBooth()

	myBooth.Carpet.Parent = game.Workspace
	while true do
		for _, part in
			pairs(
				game
					:GetService("Workspace")
					:GetPartBoundsInBox(myBooth.Banner.CFrame, myBooth.Banner.Size + Vector3.new(0.5, -1, 0.5))
			)
		do
			if part.Parent:FindFirstChildOfClass("Humanoid") and part.Parent.Name ~= lplr.Name then
				local name = part.Parent.Name
				boothUpdate:FireServer("AddBlacklist", name)
				chat("Don't block the sign, " .. name .. ".")
				task.wait(2)
				boothUpdate:FireServer("RemoveBlacklist", name)
				break
			end
		end
		task.wait(0.5)
	end
end)
-- main loop
while true do
	for _, plr in pairs(plrs:GetPlayers()) do
		points[plr.UserId] = 0
	end
	local words = game:GetService("HttpService"):JSONDecode(
		game:HttpGet(
			"https://raw.githubusercontent.com/swatTurret/roblox-scripts/main/rate%20my%20avatar%20word%20guess/words.json",
			true
		)
	)
	for round = 1, rounds, 1 do
		math.randomseed(os.time())
		roundStarted = true
		local timeLeft = roundTime
		local category = randomCategory(words)
		local word = category["words"][math.random(1, #category["words"])]
		local splitWord = string.split(word, "")
		local loweredSplitWord = {}
		for _, v in ipairs(splitWord) do
			table.insert(loweredSplitWord, string.lower(v))
		end
		local found: string = ""
		local wordFound = false
		local foundBy
		print(word)
		for _, v in pairs(splitWord) do
			if v ~= " " then
				found ..= "_"
			else
				found ..= " "
			end
		end
		updateSign(found, category.name, round, timeLeft, 10343484341)

		chatted.OnClientEvent:Connect(function(msgInfo, recipient)
			if recipient ~= "All" or plrs:FindFirstChild(msgInfo.FromSpeaker) == lplr then
				return
			end
			local plr = plrs:FindFirstChild(msgInfo.FromSpeaker)
			local rangeBase = getRangeBase()
			local message = msgInfo.Message

			if
				roundStarted
				and wordFound == false
				and plr.Character
				and plr.Character.Head
				and (plr.Character.Head.Position - rangeBase.Position).Magnitude <= 15 --plr:DistanceFromCharacter(lplr.Character.Head.Position) <= 15
				and string.lower(message) ~= "abcdefghijklmnopqrstuvwxyz1234567890" -- "abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz" works help
			then
				local trimmed = message
				trim(trimmed)
				if string.find(string.lower(trimmed), string.lower(word)) then -- string.find because we still want to accept the answer if theres trailing whitespace or something
					points[plr.UserId] += 1
					wordFound = true
					foundBy = plr.Name
				else
					for _, item in pairs(string.split(string.lower(trimmed), "")) do
						if table.find(loweredSplitWord, item) then
							local splitFound = string.split(found, "")
							splitFound[table.find(loweredSplitWord, item)] = splitWord[table.find(
								loweredSplitWord,
								item
							)]
							found = ""
							for _, letter in pairs(splitFound) do
								found ..= letter
							end
						end
					end
				end
			end
		end)

		repeat
			task.wait(1)
			timeLeft -= 1
			updateSign(found, category.name, round, timeLeft, 10343484341)
		until wordFound == true or timeLeft == 0
		task.wait(0.5)
		if wordFound then
			updateSign(foundBy .. " found the word! it was " .. word, category.name, round, timeLeft, 7871748216)
		else
			updateSign("you ran out of time :(\n it was " .. word, category.name, round, timeLeft, 8844520510)
		end
		task.wait(3)
		displayLeaderboard()
		task.wait(5)
	end
	local leaderboardTable = sortLeaderboard()
	local first = leaderboardTable[1]
	local winners = {}

	for i, plr in pairs(leaderboardTable) do
		if points[leaderboardTable[i].UserId] == points[first.UserId] then
			table.insert(winners, plr)
		end
	end

	if #winners > 1 then
		local tie = ""

		for i, winner in ipairs(winners) do
			if i == 1 then
				continue
			end

			tie ..= ", "..winner.Name
		end
		boothUpdate:FireServer("Update", {
			["DescriptionText"] = "There was a tie between "..winners[1].Name..tie.." with 💠 "..points[leaderboardTable[1].UserId].."!",
			["ImageId"] = 5791881437,
		})
	else
		boothUpdate:FireServer("Update", {
			["DescriptionText"] = leaderboardTable[1].Name .. " wins with 💠 " .. points[leaderboardTable[1].UserId],
			["ImageId"] = 5791881437,
		})
	end
	task.wait(5)
end
