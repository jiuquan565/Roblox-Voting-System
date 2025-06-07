-- 客户端脚本 - 位于 StarterGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local VotingEvent = ReplicatedStorage:WaitForChild("VotingEvent")

-- 选项配置
local OPTIONS = {
	{name = "赞成", display = "赞成-FOR", color = Color3.new(0, 1, 0)},
	{name = "反对", display = "反对-AGAINST", color = Color3.new(1, 0, 0)},
	{name = "弃票", display = "弃票-ABSTINING", color = Color3.new(0.5, 0.5, 0.5)}
}

-- 创建投票界面
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VotingUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Frame = Instance.new("Frame")
Frame.Name = "VoteFrame"
Frame.Size = UDim2.new(0, 450, 0, 350)
Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
Frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
Frame.BorderSizePixel = 0
Frame.Visible = false
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame

local QuestionLabel = Instance.new("TextLabel")
QuestionLabel.Name = "QuestionLabel"
QuestionLabel.Size = UDim2.new(0.9, 0, 0, 60)
QuestionLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
QuestionLabel.BackgroundTransparency = 1
QuestionLabel.TextColor3 = Color3.new(1, 1, 1)
QuestionLabel.Font = Enum.Font.SourceSansBold
QuestionLabel.TextSize = 28
QuestionLabel.TextXAlignment = Enum.TextXAlignment.Left
QuestionLabel.TextWrapped = true
QuestionLabel.Parent = Frame

local OptionsFrame = Instance.new("Frame")
OptionsFrame.Name = "OptionsFrame"
OptionsFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
OptionsFrame.Position = UDim2.new(0.05, 0, 0.25, 0)
OptionsFrame.BackgroundTransparency = 1
OptionsFrame.Parent = Frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Name = "ListLayout"
UIListLayout.Padding = UDim.new(0, 15)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = OptionsFrame

-- 投票事件处理
VotingEvent.OnClientEvent:Connect(function(action, ...)
	if action == "StartVote" then
		local voteData = ...
		StartVoteUI(voteData)
	elseif action == "EndVote" then
		local voteData, results = ...
		ShowVoteResults(voteData, results)
		CloseVoteUI()
	elseif action == "UpdateVotes" then
		local newVotes, votedPlayers = ...
		UpdateVoteCounts(newVotes, votedPlayers)
	elseif action == "VoteError" then
		local message = ...
		ShowNotification("投票错误: " .. message, Color3.new(1, 0.3, 0.3))
	elseif action == "VoteSuccess" then
		local selectedOption = ...
		ShowNotification("投票成功: " .. selectedOption, Color3.new(0, 1, 0))
	elseif action == "CloseVoteUI" then
		CloseVoteUI()
	end
end)

-- 显示通知
function ShowNotification(message, color)
	local notification = Instance.new("TextLabel")
	notification.Size = UDim2.new(0.4, 0, 0.1, 0)
	notification.Position = UDim2.new(0.3, 0, 0.9, 0)
	notification.BackgroundColor3 = Color3.new(0, 0, 0)
	notification.BackgroundTransparency = 0.3
	notification.BorderSizePixel = 0
	notification.TextColor3 = color or Color3.new(1, 1, 1)
	notification.Font = Enum.Font.SourceSansBold
	notification.TextSize = 20
	notification.Text = message
	notification.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 5)
	UICorner.Parent = notification

	task.wait(3)
	for i = 1, 10 do
		notification.BackgroundTransparency = 0.3 + (i * 0.07)
		notification.TextTransparency = i * 0.1
		task.wait(0.1)
	end
	notification:Destroy()
end

-- 显示投票结果
function ShowVoteResults(voteData, results)
	local resultFrame = Instance.new("Frame")
	resultFrame.Name = "ResultFrame"
	resultFrame.Size = UDim2.new(0, 500, 0, 400)
	resultFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
	resultFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	resultFrame.BorderSizePixel = 0
	resultFrame.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 10)
	UICorner.Parent = resultFrame

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "TitleLabel"
	TitleLabel.Size = UDim2.new(0.9, 0, 0, 60)
	TitleLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.TextColor3 = Color3.new(0, 1, 0)
	TitleLabel.Font = Enum.Font.SourceSansBold
	TitleLabel.TextSize = 32
	TitleLabel.Text = "投票结果"
	TitleLabel.Parent = resultFrame

	local QuestionLabel = Instance.new("TextLabel")
	QuestionLabel.Name = "QuestionLabel"
	QuestionLabel.Size = UDim2.new(0.9, 0, 0, 60)
	QuestionLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
	QuestionLabel.BackgroundTransparency = 1
	QuestionLabel.TextColor3 = Color3.new(1, 1, 1)
	QuestionLabel.Font = Enum.Font.SourceSansBold
	QuestionLabel.TextSize = 24
	QuestionLabel.Text = voteData.Question
	QuestionLabel.Parent = resultFrame

	local ResultsFrame = Instance.new("Frame")
	ResultsFrame.Name = "ResultsFrame"
	ResultsFrame.Size = UDim2.new(0.9, 0, 0.5, 0)
	ResultsFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
	ResultsFrame.BackgroundTransparency = 1
	ResultsFrame.Parent = resultFrame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Name = "ListLayout"
	UIListLayout.Padding = UDim.new(0, 10)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Parent = ResultsFrame

	-- 计算总票数
	local totalVotes = 0
	for _, result in ipairs(results) do
		totalVotes = totalVotes + result.Votes
	end

	-- 显示结果
	for i, result in ipairs(results) do
		local optionData = nil
		for _, opt in ipairs(OPTIONS) do
			if opt.name == result.Option then
				optionData = opt
				break
			end
		end

		if optionData then
			local resultItem = Instance.new("Frame")
			resultItem.Name = "ResultItem" .. i
			resultItem.Size = UDim2.new(1, 0, 0, 40)
			resultItem.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
			resultItem.BorderSizePixel = 0
			resultItem.LayoutOrder = i
			resultItem.Parent = ResultsFrame

			local UICorner = Instance.new("UICorner")
			UICorner.CornerRadius = UDim.new(0, 5)
			UICorner.Parent = resultItem

			local OptionLabel = Instance.new("TextLabel")
			OptionLabel.Name = "OptionLabel"
			OptionLabel.Size = UDim2.new(0.4, 0, 1, 0)
			OptionLabel.Position = UDim2.new(0.02, 0, 0, 0)
			OptionLabel.BackgroundTransparency = 1
			OptionLabel.TextColor3 = optionData.color
			OptionLabel.Font = Enum.Font.SourceSansBold
			OptionLabel.TextSize = 20
			OptionLabel.Text = optionData.display
			OptionLabel.Parent = resultItem

			local VotesLabel = Instance.new("TextLabel")
			VotesLabel.Name = "VotesLabel"
			VotesLabel.Size = UDim2.new(0.2, 0, 1, 0)
			VotesLabel.Position = UDim2.new(0.45, 0, 0, 0)
			VotesLabel.BackgroundTransparency = 1
			VotesLabel.TextColor3 = Color3.new(1, 1, 1)
			VotesLabel.Font = Enum.Font.SourceSansBold
			VotesLabel.TextSize = 20
			VotesLabel.Text = result.Votes .. "票"
			VotesLabel.Parent = resultItem

			local PercentageLabel = Instance.new("TextLabel")
			PercentageLabel.Name = "PercentageLabel"
			PercentageLabel.Size = UDim2.new(0.2, 0, 1, 0)
			PercentageLabel.Position = UDim2.new(0.7, 0, 0, 0)
			PercentageLabel.BackgroundTransparency = 1
			PercentageLabel.TextColor3 = Color3.new(1, 1, 0)
			PercentageLabel.Font = Enum.Font.SourceSansBold
			PercentageLabel.TextSize = 20

			local percentage = totalVotes > 0 and math.floor((result.Votes / totalVotes) * 100) or 0
			PercentageLabel.Text = percentage .. "%"
			PercentageLabel.Parent = resultItem
		end
	end

	-- 关闭按钮
	local CloseButton = Instance.new("TextButton")
	CloseButton.Name = "CloseButton"
	CloseButton.Size = UDim2.new(0.3, 0, 0, 40)
	CloseButton.Position = UDim2.new(0.35, 0, 0.9, 0)
	CloseButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
	CloseButton.BorderSizePixel = 0
	CloseButton.Font = Enum.Font.SourceSansBold
	CloseButton.TextSize = 20
	CloseButton.TextColor3 = Color3.new(1, 1, 1)
	CloseButton.Text = "关闭"
	CloseButton.Parent = resultFrame

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 5)
	UICorner.Parent = CloseButton

	CloseButton.MouseButton1Click:Connect(function()
		resultFrame:Destroy()
	end)

	-- 3秒后自动关闭
	task.wait(8)
	if resultFrame and resultFrame.Parent then
		resultFrame:Destroy()
	end
end

function StartVoteUI(voteData)
	Frame.Visible = true
	QuestionLabel.Text = "投票: " .. voteData.Question

	for _, child in ipairs(OptionsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i, option in ipairs(OPTIONS) do
		local OptionButton = Instance.new("TextButton")
		OptionButton.Name = "OptionButton" .. i
		OptionButton.Size = UDim2.new(1, 0, 0, 70)
		OptionButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		OptionButton.BorderSizePixel = 0
		OptionButton.Font = Enum.Font.SourceSansBold
		OptionButton.TextSize = 28
		OptionButton.TextColor3 = option.color
		OptionButton.Text = option.display
		OptionButton.LayoutOrder = i
		OptionButton.Parent = OptionsFrame

		local UICorner = Instance.new("UICorner")
		UICorner.CornerRadius = UDim.new(0, 8)
		UICorner.Parent = OptionButton

		OptionButton.MouseButton1Click:Connect(function()
			VotingEvent:FireServer("CastVote", option.name)
		end)
	end
end

function UpdateVoteCounts(newVotes, votedPlayers)
	local playerVote = votedPlayers[LocalPlayer.UserId]

	for _, child in ipairs(OptionsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			for _, option in ipairs(OPTIONS) do
				if child.Text:match("^" .. option.display) then
					local count = newVotes[option.name] or 0
					child.Text = option.display .. " (" .. count .. "票)"

					if playerVote == option.name then
						child.BackgroundColor3 = option.color
						child.TextColor3 = Color3.new(1, 1, 1)
					else
						child.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
						child.TextColor3 = option.color
					end

					break
				end
			end
		end
	end
end

function CloseVoteUI()
	Frame.Visible = false
end    