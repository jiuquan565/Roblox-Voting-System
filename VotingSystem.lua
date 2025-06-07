-- 服务器脚本 - 位于 ServerScriptService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- 创建远程事件
local VotingEvent = Instance.new("RemoteEvent")
VotingEvent.Name = "VotingEvent"
VotingEvent.Parent = ReplicatedStorage

-- 投票数据
local currentVote = nil
local votes = {}
local votedPlayers = {}
local admins = {"Jiuquan565"} -- 替换为管理员用户名

-- 选项配置
local OPTIONS = {
	{name = "赞成", display = "赞成-FOR", color = Color3.new(0, 1, 0)},
	{name = "反对", display = "反对-AGAINST", color = Color3.new(1, 0, 0)},
	{name = "弃票", display = "弃票-ABSTINING", color = Color3.new(0.5, 0.5, 0.5)}
}

-- 查找或创建VoteResultPart
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

-- 创建SurfaceGui
local surfaceGui = voteResultPart:FindFirstChild("VoteResultGui")
if not surfaceGui then
	surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "VoteResultGui"
	surfaceGui.Adornee = voteResultPart
	surfaceGui.AlwaysOnTop = true
	surfaceGui.Parent = voteResultPart
end

-- 创建主文本标签
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

-- 创建选项文本标签
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
		optionLabel.Text = option.display .. ": 0票"
		optionLabel.Parent = surfaceGui
	end
	optionLabels[option.name] = optionLabel
end

-- 检查是否所有玩家都投票了
local function checkAllPlayersVoted()
	if not currentVote then return false end

	local onlinePlayers = Players:GetPlayers()
	local totalVoted = 0

	for _, player in ipairs(onlinePlayers) do
		-- 排除管理员
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

	-- 计算需要投票的玩家数（排除管理员）
	local playersToVote = #onlinePlayers
	for _, player in ipairs(onlinePlayers) do
		for _, adminName in ipairs(admins) do
			if player.Name == adminName then
				playersToVote = playersToVote - 1
				break
			end
		end
	end

	-- 如果没有普通玩家，只有管理员，也结束投票
	if playersToVote == 0 then
		return true
	end

	return totalVoted >= playersToVote
end

-- 启动投票函数
function StartVote(question, duration)
	if currentVote then
		return false, "已有投票正在进行中"
	end

	-- 获取当前在线玩家列表
	local onlinePlayers = Players:GetPlayers()

	-- 设置投票数据
	currentVote = {
		Question = question,
		Options = {"赞成", "反对", "弃票"},
		StartTime = os.time(),
		EndTime = os.time() + duration,
		Duration = duration,
		TotalPlayers = #onlinePlayers
	}

	-- 重置投票记录
	votes = {
		["赞成"] = 0,
		["反对"] = 0,
		["弃票"] = 0
	}
	votedPlayers = {}

	-- 通知所有玩家开始投票
	VotingEvent:FireAllClients("StartVote", currentVote)

	-- 更新Part上的显示
	UpdateVoteResultDisplay()

	-- 启动计时器
	local voteConnection
	voteConnection = game:GetService("RunService").Heartbeat:Connect(function()
		-- 更新显示
		UpdateVoteResultDisplay()

		-- 检查是否所有玩家都投票了
		if checkAllPlayersVoted() then
			voteConnection:Disconnect()
			EndVote()
		elseif os.time() >= currentVote.EndTime then
			voteConnection:Disconnect()
			EndVote()
		end
	end)

	return true, "投票已启动: " .. question
end

-- 结束投票函数
function EndVote()
	if not currentVote then
		return false, "没有正在进行的投票"
	end

	-- 整理结果
	local results = {}
	for option, count in pairs(votes) do
		table.insert(results, {Option = option, Votes = count})
	end

	-- 按票数排序
	table.sort(results, function(a, b)
		return a.Votes > b.Votes
	end)

	-- 通知所有玩家投票结束
	VotingEvent:FireAllClients("EndVote", currentVote, results)

	-- 更新Part上的显示为最终结果
	UpdateVoteResultDisplay(true)

	-- 清理投票数据
	currentVote = nil
	votes = {}
	votedPlayers = {}

	return true, "投票已结束"
end

-- 处理玩家投票
function CastVote(player, option)
	if not currentVote then
		return false, "没有正在进行的投票"
	end

	-- 检查选项是否有效
	local isValidOption = false
	for _, validOption in ipairs(currentVote.Options) do
		if validOption == option then
			isValidOption = true
			break
		end
	end

	if not isValidOption then
		return false, "无效的投票选项"
	end

	-- 检查是否是管理员
	local isAdmin = false
	for _, adminName in ipairs(admins) do
		if player.Name == adminName then
			isAdmin = true
			break
		end
	end

	-- 允许修改投票
	if votedPlayers[player.UserId] then
		-- 减少之前的投票
		local previousVote = votedPlayers[player.UserId]
		votes[previousVote] = votes[previousVote] - 1
	end

	-- 记录新投票
	votes[option] = votes[option] + 1
	votedPlayers[player.UserId] = option

	-- 更新所有玩家的投票计数
	VotingEvent:FireAllClients("UpdateVotes", votes, votedPlayers)

	-- 只有非管理员投票后才关闭UI
	if not isAdmin then
		VotingEvent:FireClient(player, "CloseVoteUI")
	else
		VotingEvent:FireClient(player, "VoteSuccess", option)
	end

	-- 更新Part上的显示
	UpdateVoteResultDisplay()

	-- 检查是否所有玩家都投票了
	if checkAllPlayersVoted() then
		EndVote()
	end

	return true, "投票已记录"
end

-- 更新投票结果显示在Part上
function UpdateVoteResultDisplay(isFinalResult)
	if not currentVote then
		mainTextLabel.Text = "等待投票开始..."
		for _, option in ipairs(OPTIONS) do
			if optionLabels[option.name] then
				optionLabels[option.name].Text = option.display .. ": 0票"
			end
		end
		return
	end

	-- 更新主标题
	if isFinalResult then
		mainTextLabel.Text = "投票标题: " .. currentVote.Question

		-- 计算总票数
		local totalVotes = 0
		for _, count in pairs(votes) do
			totalVotes = totalVotes + count
		end

		-- 按票数排序选项
		local sortedOptions = {}
		for option, count in pairs(votes) do
			table.insert(sortedOptions, {option = option, count = count})
		end

		table.sort(sortedOptions, function(a, b)
			return a.count > b.count
		end)

		-- 显示排序后的结果
		for i, optionData in ipairs(sortedOptions) do
			local option = optionData.option
			local count = optionData.count
			local percentage = totalVotes > 0 and math.floor((count / totalVotes) * 100) or 0

			if optionLabels[option] then
				optionLabels[option].Text = optionLabels[option].Text .. " (" .. percentage .. "%)"
			end
		end
	else
		mainTextLabel.Text = "投票中: " .. currentVote.Question

		-- 显示当前投票数
		for _, option in ipairs(OPTIONS) do
			if optionLabels[option.name] then
				optionLabels[option.name].Text = option.display .. ": " .. (votes[option.name] or 0) .. "票"
			end
		end
	end
end

-- 远程事件处理
VotingEvent.OnServerEvent:Connect(function(player, action, ...)
	if action == "CastVote" then
		local option = ...
		local success, message = CastVote(player, option)

		if not success then
			VotingEvent:FireClient(player, "VoteError", message)
		end
	end
end)

-- 聊天命令处理
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- 检查是否是管理员
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

		-- 管理员命令
		if string.sub(message, 1, 11):lower() == "!startvote " then
			local question = string.sub(message, 12)
			if question and #question > 0 then
				StartVote(question, 30)
			else
				VotingEvent:FireClient(player, "VoteMessage", "请提供投票标题，格式: !startvote [投票标题]")
			end
		elseif string.lower(message) == "!startvote" then
			VotingEvent:FireClient(player, "VoteMessage", "请提供投票标题，格式: !startvote [投票标题]")
		elseif string.lower(message) == "!endvote" then
			EndVote()
		end
	end)
end)

-- 游戏启动时设置初始显示
UpdateVoteResultDisplay()    