local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer
local BoothUpdate = ReplicatedStorage.CustomiseBooth

local Messages = {
	"Tip: Word detection is case-insensitive, so no matter how you type, the game will detect it.",
	"You probably don't own an air fryer.",
	"McDonald's fixed the ice cream machine.",
	"Players who spam every letter in one message have no skill and ruin the game for others.",
}

local Points = {}
local Rounds = 6
local RoundTime = 25

if _G.useBoothSignAsRangeBase == nil then
	_G.useBoothSignAsRangeBase = false
end

-- Helper Functions
local function getBooth()
	for _, booth in pairs(game.Workspace:GetChildren()) do
		if booth:GetAttribute("TenantUsername") == LocalPlayer.Name then
			return booth
		end
	end
end

local function getRangeBase()
	if not _G.useBoothSignAsRangeBase and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
		return LocalPlayer.Character.Head
	end

	return getBooth().Banner
end

local function chat(msg)
	if _G.useBoothSignAsRangeBase then
		return
	end

	if ChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
		ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All")
	else
		ChatService.TextChannels.RBXGeneral:SendAsync(msg)
	end
end

local function randomCategory(categories)
	local array = {}
	for i in pairs(categories) do
		table.insert(array, i)
	end
	local randomNum = math.random(1, #array)
	return categories[array[randomNum]]
end

local function sortLeaderboard()
	local players = Players:GetPlayers()
	if players[1] == LocalPlayer then
		table.remove(players, 1)
	end
	table.sort(players, function(p1, p2)
		return Points[p1.UserId] > Points[p2.UserId]
	end)
	return players
end

local function displayLeaderboard()
	local leaderboardTable = sortLeaderboard()
	local leaderboard = "Leaderboard"

	for i = 1, 4, 1 do
		leaderboard = leaderboard .. "\n" .. leaderboardTable[i].Name .. ": 💠 " .. Points[leaderboardTable[i].UserId]
	end
	BoothUpdate:FireServer("Update", {
		["DescriptionText"] = leaderboard,
		["ImageId"] = 0,
	})
	print(leaderboard)
	wait(0.5)
	for _, booth in pairs(game.Workspace:GetChildren()) do
		if booth:GetAttribute("TenantUsername") == LocalPlayer.Name then
			if string.find(booth.Banner.SurfaceGui.Frame.Description.Text, "#####################") then
				BoothUpdate:FireServer("Update", {
					["DescriptionText"] = "The leaderboard was filtered by Roblox >:(",
					["ImageId"] = 0,
				})
			end
		end
	end
end

local function trim(str)
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

local function updateSign(text, category, round, timeLeft, icon)
	BoothUpdate:FireServer("Update", {
		["DescriptionText"] = "[🕹️] Word Guess (" .. tostring(round) .. "/" .. tostring(Rounds) .. ")\n[🔤] " .. text .. "\nCategory: " .. category .. "\n[⏰]" .. timeLeft,
		["ImageId"] = icon,
	})
end

Players.PlayerRemoving:Connect(function(plr)
	Points[plr.UserId] = nil
end)

Players.PlayerAdded:Connect(function(plr)
	Points[plr.UserId] = 0
end)

spawn(function()
	while true do
		wait(120)
		chat(Messages[math.random(1, #Messages)])
	end
end)

spawn(function()
	local MyBooth = getBooth()
	MyBooth.Carpet.Parent = game.Workspace

	while true do
		for _, part in ipairs(game:GetService("Workspace"):GetPartBoundsInBox(MyBooth.Banner.CFrame, MyBooth.Banner.Size + Vector3.new(0.5, -1, 0.5))) do
			if part.Parent:FindFirstChildOfClass("Humanoid") and part.Parent.Name ~= LocalPlayer.Name then
				local name = part.Parent.Name
				BoothUpdate:FireServer("AddBlacklist", name)
				chat("Don't block the sign, " .. name .. ".")
				wait(2)
				BoothUpdate:FireServer("RemoveBlacklist", name)
				break
			end
		end
		wait(0.5)
	end
end)

-- Main Loop
while true do
	for _, plr in pairs(Players:GetPlayers()) do
		Points[plr.UserId] = 0
	end

	local words = game:GetService("HttpService"):JSONDecode(
		game:HttpGet("https://raw.githubusercontent.com/MinnertheBaddie/rate-my-avatar-word-guess/main/rate%20my%20avatar%20word%20guess/words.json", true)
	)

	for round = 1, Rounds, 1 do
		math.randomseed(os.time())
		local roundStarted = true
		local timeLeft = RoundTime
		local category = randomCategory(words)
		local word = category["words"][math.random(1, #category["words"])]
		local splitWord = string.split(word, "")
		local found = ""
		local wordFound = false
		local foundBy

		for _, v in ipairs(splitWord) do
			if v ~= " " then
				found ..= "_"
			else
				found ..= " "
			end
		end

		updateSign(found, category.name, round, timeLeft, 10343484341)

		chatted.OnClientEvent:Connect(function(msgInfo, recipient)
			if recipient ~= "All" or Players:FindFirstChild(msgInfo.FromSpeaker) == LocalPlayer then
				return
			end

			local plr = Players:FindFirstChild(msgInfo.FromSpeaker)
			local rangeBase = getRangeBase()
			local message = msgInfo.Message
			if
				roundStarted
				and wordFound == false
				and plr.Character
				and plr.Character.Head
				and (plr.Character.Head.Position - rangeBase.Position).Magnitude <= 15
				and string.lower(message) ~= "abcdefghijklmnopqrstuvwxyz1234567890"
			then
				local trimmed = message:lower()
				if string.find(trimmed, word:lower()) then
					Points[plr.UserId] += 1
					wordFound = true
					foundBy = plr.Name
				else
					for _, item in pairs(string.split(trimmed, "")) do
						if table.find(splitWord, item) then
							local splitFound = string.split(found, "")
							splitFound[table.find(splitWord, item)] = splitWord[table.find(splitWord, item)]
							found = table.concat(splitFound)
						end
					end
				end
			end
		end)

		repeat
			wait(1)
			timeLeft -= 1
			updateSign(found, category.name, round, timeLeft, 10343484341)
		until wordFound == true or timeLeft == 0

		wait(0.5)
		if wordFound then
			updateSign(foundBy .. " found the word! It was " .. word, category.name, round, timeLeft, 7871748216)
		else
			updateSign("You ran out of time :(\n It was " .. word, category.name, round, timeLeft, 8844520510)
		end

		wait(3)
		displayLeaderboard()
		wait(5)
	end

	local leaderboardTable = sortLeaderboard()
	local first = leaderboardTable[1]
	local winners = {}

	for i, plr in ipairs(leaderboardTable) do
		if Points[leaderboardTable[i].UserId] == Points[first.UserId] then
			table.insert(winners, plr)
		end
	end

	if #winners > 1 then
		local tie = ""

		for i, winner in ipairs(winners) do
			if i == 1 then
				continue
			end
			tie ..= ", " .. winner.Name
		end

		BoothUpdate:FireServer("Update", {
			["DescriptionText"] = "There was a tie between " .. winners[1].Name .. tie .. " with 💠 " .. Points[leaderboardTable[1].UserId] .. "!",
			["ImageId"] = 5791881437,
		})
	else
		BoothUpdate:FireServer("Update", {
			["DescriptionText"] = leaderboardTable[1].Name .. " wins with 💠 " .. Points[leaderboardTable[1].UserId],
			["ImageId"] = 5791881437,
		})
	end

	wait(5)
end
