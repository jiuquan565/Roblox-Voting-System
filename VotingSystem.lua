-- �������ű� - λ�� ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ����Զ���¼�
local VotingEvent = Instance.new("RemoteEvent")
VotingEvent.Name = "VotingEvent"
VotingEvent.Parent = ReplicatedStorage

-- ͶƱ����
local currentVote = nil
local votes = {}
local votedPlayers = {}
local admins = {"Jiuquan565"} -- �滻Ϊ����Ա�û���

-- ѡ������
local OPTIONS = {
	{name = "�޳�", display = "�޳�-FOR", color = Color3.new(0, 1, 0)},
	{name = "����", display = "����-AGAINST", color = Color3.new(1, 0, 0)},
	{name = "��Ʊ", display = "��Ʊ-ABSTINING", color = Color3.new(0.5, 0.5, 0.5)}
}

-- ���һ򴴽�VoteResultPart
local voteResultPart = Workspace:FindFirstChild("vote")
if not voteResultPart then
	voteResultPart = Instance.new("Part")
	voteResultPart.Name = "vote"
	voteResultPart.Size = Vector3.new(15, 5, 0.2)
	voteResultPart.Anchored = true
	voteResultPart.CanCollide = false
	voteResultPart.Position = Vector3.new(0, 5, 0)
	voteResultPart.BrickColor = BrickColor.new("Dark blue")
	voteResultPart.Parent = Workspace
end

-- ����SurfaceGui
local surfaceGui = voteResultPart:FindFirstChild("VoteResultGui")
if not surfaceGui then
	surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "VoteResultGui"
	surfaceGui.Adornee = voteResultPart
	surfaceGui.AlwaysOnTop = true
	surfaceGui.Parent = voteResultPart
end

-- �������ı���ǩ
local mainTextLabel = surfaceGui:FindFirstChild("MainTextLabel")
if not mainTextLabel then
	mainTextLabel = Instance.new("TextLabel")
	mainTextLabel.Name = "MainTextLabel"
	mainTextLabel.Size = UDim2.new(1, 0, 0.3, 0)
	mainTextLabel.Position = UDim2.new(0, 0, 0, 0)
	mainTextLabel.BackgroundTransparency = 1
	mainTextLabel.TextColor3 = Color3.new(1, 1, 1)
	mainTextLabel.Font = Enum.Font.SourceSansBold
	mainTextLabel.TextSize = 40
	mainTextLabel.TextWrapped = true
	mainTextLabel.Parent = surfaceGui
end

-- ����ѡ���ı���ǩ
local optionLabels = {}
for i, option in ipairs(OPTIONS) do
	local optionLabel = surfaceGui:FindFirstChild("OptionLabel" .. i)
	if not optionLabel then
		optionLabel = Instance.new("TextLabel")
		optionLabel.Name = "OptionLabel" .. i
		optionLabel.Size = UDim2.new(1, 0, 0.15, 0)
		optionLabel.Position = UDim2.new(0, 0, 0.3 + (i-1) * 0.15, 0)
		optionLabel.BackgroundTransparency = 1
		optionLabel.Font = Enum.Font.SourceSansBold
		optionLabel.TextSize = 50
		optionLabel.TextColor3 = option.color
		optionLabel.TextXAlignment = Enum.TextXAlignment.Left
		optionLabel.Text = option.display .. ": 0Ʊ"
		optionLabel.Parent = surfaceGui
	end
	optionLabels[option.name] = optionLabel
end

-- ����Ƿ�������Ҷ�ͶƱ��
local function checkAllPlayersVoted()
	if not currentVote then return false end

	local onlinePlayers = Players:GetPlayers()
	local totalVoted = 0

	for _, player in ipairs(onlinePlayers) do
		-- �ų�����Ա
		local isAdmin = false
		for _, adminName in ipairs(admins) do
			if player.Name == adminName then
				isAdmin = true
				break
			end
		end

		if not isAdmin and votedPlayers[player.UserId] then
			totalVoted = totalVoted + 1
		end
	end

	-- ������ҪͶƱ����������ų�����Ա��
	local playersToVote = #onlinePlayers
	for _, player in ipairs(onlinePlayers) do
		for _, adminName in ipairs(admins) do
			if player.Name == adminName then
				playersToVote = playersToVote - 1
				break
			end
		end
	end

	-- ���û����ͨ��ң�ֻ�й���Ա��Ҳ����ͶƱ
	if playersToVote == 0 then
		return true
	end

	return totalVoted >= playersToVote
end

-- ����ͶƱ����
function StartVote(question, duration)
	if currentVote then
		return false, "����ͶƱ���ڽ�����"
	end

	-- ��ȡ��ǰ��������б�
	local onlinePlayers = Players:GetPlayers()

	-- ����ͶƱ����
	currentVote = {
		Question = question,
		Options = {"�޳�", "����", "��Ʊ"},
		StartTime = os.time(),
		EndTime = os.time() + duration,
		Duration = duration,
		TotalPlayers = #onlinePlayers
	}

	-- ����ͶƱ��¼
	votes = {
		["�޳�"] = 0,
		["����"] = 0,
		["��Ʊ"] = 0
	}
	votedPlayers = {}

	-- ֪ͨ������ҿ�ʼͶƱ
	VotingEvent:FireAllClients("StartVote", currentVote)

	-- ����Part�ϵ���ʾ
	UpdateVoteResultDisplay()

	-- ������ʱ��
	local voteConnection
	voteConnection = game:GetService("RunService").Heartbeat:Connect(function()
		-- ������ʾ
		UpdateVoteResultDisplay()

		-- ����Ƿ�������Ҷ�ͶƱ��
		if checkAllPlayersVoted() then
			voteConnection:Disconnect()
			EndVote()
		elseif os.time() >= currentVote.EndTime then
			voteConnection:Disconnect()
			EndVote()
		end
	end)

	return true, "ͶƱ������: " .. question
end

-- ����ͶƱ����
function EndVote()
	if not currentVote then
		return false, "û�����ڽ��е�ͶƱ"
	end

	-- ������
	local results = {}
	for option, count in pairs(votes) do
		table.insert(results, {Option = option, Votes = count})
	end

	-- ��Ʊ������
	table.sort(results, function(a, b)
		return a.Votes > b.Votes
	end)

	-- ֪ͨ�������ͶƱ����
	VotingEvent:FireAllClients("EndVote", currentVote, results)

	-- ����Part�ϵ���ʾΪ���ս��
	UpdateVoteResultDisplay(true)

	-- ����ͶƱ����
	currentVote = nil
	votes = {}
	votedPlayers = {}

	return true, "ͶƱ�ѽ���"
end

-- �������ͶƱ
function CastVote(player, option)
	if not currentVote then
		return false, "û�����ڽ��е�ͶƱ"
	end

	-- ���ѡ���Ƿ���Ч
	local isValidOption = false
	for _, validOption in ipairs(currentVote.Options) do
		if validOption == option then
			isValidOption = true
			break
		end
	end

	if not isValidOption then
		return false, "��Ч��ͶƱѡ��"
	end

	-- ����Ƿ��ǹ���Ա
	local isAdmin = false
	for _, adminName in ipairs(admins) do
		if player.Name == adminName then
			isAdmin = true
			break
		end
	end

	-- �����޸�ͶƱ
	if votedPlayers[player.UserId] then
		-- ����֮ǰ��ͶƱ
		local previousVote = votedPlayers[player.UserId]
		votes[previousVote] = votes[previousVote] - 1
	end

	-- ��¼��ͶƱ
	votes[option] = votes[option] + 1
	votedPlayers[player.UserId] = option

	-- ����������ҵ�ͶƱ����
	VotingEvent:FireAllClients("UpdateVotes", votes, votedPlayers)

	-- ֻ�зǹ���ԱͶƱ��Źر�UI
	if not isAdmin then
		VotingEvent:FireClient(player, "CloseVoteUI")
	else
		VotingEvent:FireClient(player, "VoteSuccess", option)
	end

	-- ����Part�ϵ���ʾ
	UpdateVoteResultDisplay()

	-- ����Ƿ�������Ҷ�ͶƱ��
	if checkAllPlayersVoted() then
		EndVote()
	end

	return true, "ͶƱ�Ѽ�¼"
end

-- ����ͶƱ�����ʾ��Part��
function UpdateVoteResultDisplay(isFinalResult)
	if not currentVote then
		mainTextLabel.Text = "�ȴ�ͶƱ��ʼ..."
		for _, option in ipairs(OPTIONS) do
			if optionLabels[option.name] then
				optionLabels[option.name].Text = option.display .. ": 0Ʊ"
			end
		end
		return
	end

	-- ����������
	if isFinalResult then
		mainTextLabel.Text = "ͶƱ����: " .. currentVote.Question

		-- ������Ʊ��
		local totalVotes = 0
		for _, count in pairs(votes) do
			totalVotes = totalVotes + count
		end

		-- ��Ʊ������ѡ��
		local sortedOptions = {}
		for option, count in pairs(votes) do
			table.insert(sortedOptions, {option = option, count = count})
		end

		table.sort(sortedOptions, function(a, b)
			return a.count > b.count
		end)

		-- ��ʾ�����Ľ��
		for i, optionData in ipairs(sortedOptions) do
			local option = optionData.option
			local count = optionData.count
			local percentage = totalVotes > 0 and math.floor((count / totalVotes) * 100) or 0

			if optionLabels[option] then
				optionLabels[option].Text = optionLabels[option].Text .. " (" .. percentage .. "%)"
			end
		end
	else
		mainTextLabel.Text = "ͶƱ��: " .. currentVote.Question

		-- ��ʾ��ǰͶƱ��
		for _, option in ipairs(OPTIONS) do
			if optionLabels[option.name] then
				optionLabels[option.name].Text = option.display .. ": " .. (votes[option.name] or 0) .. "Ʊ"
			end
		end
	end
end

-- Զ���¼�����
VotingEvent.OnServerEvent:Connect(function(player, action, ...)
	if action == "CastVote" then
		local option = ...
		local success, message = CastVote(player, option)

		if not success then
			VotingEvent:FireClient(player, "VoteError", message)
		end
	end
end)

-- ���������
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- ����Ƿ��ǹ���Ա
		local isAdmin = false
		for _, adminName in ipairs(admins) do
			if player.Name == adminName then
				isAdmin = true
				break
			end
		end

		if not isAdmin then
			return
		end

		-- ����Ա����
		if string.sub(message, 1, 11):lower() == "!startvote " then
			local question = string.sub(message, 12)
			if question and #question > 0 then
				StartVote(question, 30)
			else
				VotingEvent:FireClient(player, "VoteMessage", "���ṩͶƱ���⣬��ʽ: !startvote [ͶƱ����]")
			end
		elseif string.lower(message) == "!startvote" then
			VotingEvent:FireClient(player, "VoteMessage", "���ṩͶƱ���⣬��ʽ: !startvote [ͶƱ����]")
		elseif string.lower(message) == "!endvote" then
			EndVote()
		end
	end)
end)

-- ��Ϸ����ʱ���ó�ʼ��ʾ
UpdateVoteResultDisplay()    