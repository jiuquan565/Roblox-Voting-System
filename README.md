# Roblox投票系统开发文档

## 一、系统概述
本投票系统基于Roblox客户端-服务器架构设计，实现了管理员发起投票、玩家投票、实时统计票数及结果展示等功能。系统支持动态调整字体大小、管理员权限控制及投票结果自动/手动结束，适用于Roblox游戏内的决策场景。

[English](#system-overview) | [中文](#一系统概述) |

## 二、系统架构
### 2.1 目录结构
```
ServerScriptService/
└── VotingSystem.lua       -- 服务器端核心逻辑
StarterGui/
└── VotingUI.lua           -- 客户端UI逻辑
```

### 2.2 技术栈
- **通信机制**：使用Roblox远程事件（RemoteEvent）实现客户端与服务器数据交互。
- **数据存储**：全局变量存储投票状态（`currentVote`）、票数（`votes`）及玩家投票记录（`votedPlayers`）。
- **界面渲染**：
  - 服务器端：通过`SurfaceGui`在3D部件（Part）上显示投票结果。
  - 客户端：使用`ScreenGui`创建2D投票界面，支持按钮交互和结果弹窗。


## 三、核心功能设计

### 3.1 投票流程
1. **发起投票**：
   - 管理员通过聊天命令`!startvote [问题]`发起投票，支持设置投票时长（默认30秒）。
   - 服务器广播`StartVote`事件，客户端显示投票界面。

2. **玩家投票**：
   - 玩家点击选项按钮（赞成/反对/弃票），客户端向服务器发送`CastVote`请求。
   - 服务器验证投票有效性，支持修改投票（覆盖前一次选择）。
   - 非管理员玩家投票后自动关闭UI，管理员可多次修改投票。

3. **结束投票**：
   - **自动结束**：所有非管理员玩家投票完成或到达预设时长。
   - **手动结束**：管理员通过命令`!endvote`强制结束。
   - 服务器广播`EndVote`事件，客户端显示最终结果弹窗。


### 3.2 界面与交互
#### 3.2.1 服务器端显示（3D部件）
- **主标题**：显示投票状态（进行中/结果），字体颜色动态变化（白色→绿色）。
- **选项标签**：实时显示各选项票数，颜色对应选项类型（绿色-赞成，红色-反对，灰色-弃票）。
- **字体大小**：初始为固定值（主标题32px，选项28px），可通过修改`TextSize`属性调整。

#### 3.2.2 客户端界面（2D UI）
- **投票界面**：
  - 包含问题标题、选项按钮（带实时票数）及状态通知。
  - 按钮点击后高亮显示当前选择，投票成功后提示通知。
- **结果弹窗**：
  - 显示投票问题、各选项票数及百分比。
  - 支持手动关闭或自动消失（8秒后）。


### 3.3 权限控制
- **管理员功能**：
  - 发起/结束投票。
  - 可多次修改投票，UI保持打开状态。
- **普通玩家**：
  - 仅能投票一次（修改投票视为单次操作）。
  - 投票后自动关闭UI。


## 四、关键代码解析

### 4.1 服务器端核心逻辑（VotingSystem.lua）
#### 4.1.1 投票启动函数
```lua
function StartVote(question, duration)
    if currentVote then return false, "已有投票进行中" end
    currentVote = {
        Question = question,
        StartTime = os.time(),
        EndTime = os.time() + duration,
        Options = {"赞成", "反对", "弃票"}
    }
    votes = {["赞成"]=0, ["反对"]=0, ["弃票"]=0}
    VotingEvent:FireAllClients("StartVote", currentVote) -- 广播投票开始
    UpdateVoteResultDisplay()
end
```

#### 4.1.2 投票处理函数
```lua
function CastVote(player, option)
    local previousVote = votedPlayers[player.UserId]
    if previousVote then votes[previousVote] = votes[previousVote] - 1 end -- 修改投票逻辑
    votes[option] = votes[option] + 1
    votedPlayers[player.UserId] = option
    VotingEvent:FireAllClients("UpdateVotes", votes, votedPlayers) -- 实时更新票数
    if not isAdmin then VotingEvent:FireClient(player, "CloseVoteUI") end -- 非管理员关闭UI
end
```

#### 4.1.3 结果更新函数
```lua
function UpdateVoteResultDisplay(isFinalResult)
    if isFinalResult then
        mainTextLabel.Text = "投票结果: " .. currentVote.Question
        mainTextLabel.TextColor3 = Color3.new(0, 1, 0)
    else
        mainTextLabel.Text = "投票中: " .. currentVote.Question
    end
    -- 更新各选项票数显示
    for _, option in ipairs(OPTIONS) do
        optionLabels[option.name].Text = option.display .. ": " .. (votes[option.name] or 0) .. "票"
    end
end
```


### 4.2 客户端UI逻辑（VotingUI.lua）
#### 4.2.1 投票界面初始化
```lua
function StartVoteUI(voteData)
    Frame.Visible = true
    QuestionLabel.Text = "投票: " .. voteData.Question
    -- 创建选项按钮
    for i, option in ipairs(OPTIONS) do
        local btn = Instance.new("TextButton")
        btn.Text = option.display
        btn.TextColor3 = option.color
        btn.MouseButton1Click:Connect(function()
            VotingEvent:FireServer("CastVote", option.name) -- 发送投票请求
        end)
    end
end
```

#### 4.2.2 结果弹窗显示
```lua
function ShowVoteResults(voteData, results)
    local resultFrame = Instance.new("Frame")
    -- 显示投票问题和各选项结果
    for i, result in ipairs(results) do
        local item = Instance.new("Frame")
        -- 显示选项名称、票数及百分比
        PercentageLabel.Text = math.floor((result.Votes / totalVotes) * 100) .. "%"
    end
    -- 添加关闭按钮和自动销毁逻辑
    CloseButton.MouseButton1Click:Connect(function() resultFrame:Destroy() end)
    task.wait(8, function() resultFrame:Destroy() end)
end
```


## 五、部署与配置
### 5.1 管理员配置
- 修改服务器端代码中的`admins`表，添加管理员用户名：
  ```lua
  local admins = {"AdminName1", "AdminName2"} -- 替换为实际管理员名称
  ```

### 5.2 界面调整
- **字体大小**：直接修改`TextSize`属性（如主标题`mainTextLabel.TextSize = 36`）。
- **颜色方案**：调整`OPTIONS`表中的`color`字段（如`Color3.new(0, 0.8, 0)`为亮绿色）。
- **界面尺寸**：修改`Frame`的`Size`和`Position`属性（使用UDim2实现自适应布局）。


## 六、扩展建议
1. **多语言支持**：添加语言切换功能，通过配置表管理文本本地化。
2. **投票历史记录**：存储投票记录，支持管理员查询历史结果。
3. **反作弊机制**：限制同一玩家多次投票（基于UserID验证）。
4. **动画效果**：为结果弹窗添加渐入渐出动画，提升交互体验。


## 七、问题排查
| 问题现象               | 可能原因                          | 解决方案                          |
|------------------------|-----------------------------------|-----------------------------------|
| 投票界面未弹出         | 远程事件未正确广播                | 检查`VotingEvent:FireAllClients`调用 |
| 票数未实时更新         | 客户端未监听`UpdateVotes`事件     | 确认`VotingEvent.OnClientEvent`绑定 |
| 管理员无法修改投票     | 权限判断逻辑错误                  | 检查`isAdmin`身份验证代码         |
| 结果弹窗数据错误       | 服务器结果数据未正确传递          | 确保`EndVote`事件参数包含`results` |


## 多语言版本

### System Overview

# Roblox Voting System Development Documentation  

## 1. System Overview  
This voting system is designed based on the Roblox client-server architecture, enabling features such as admin-initiated voting, player voting, real-time vote counting, and result display. The system supports dynamic font size adjustment, admin permission control, and automatic/manual vote termination, suitable for decision-making scenarios in Roblox games.  

[English](#system-overview) | [中文](#一系统概述) 
## 2. System Architecture  
### 2.1 Directory Structure  
```  
ServerScriptService/  
└── VotingSystem.lua       -- Server-side core logic  
StarterGui/  
└── VotingUI.lua           -- Client-side UI logic  
```  

### 2.2 Technology Stack  
- **Communication**: Uses Roblox RemoteEvents for data interaction between the client and server.  
- **Data Storage**: Global variables store voting status (`currentVote`), vote counts (`votes`), and player voting records (`votedPlayers`).  
- **UI Rendering**:  
  - *Server-side*: Displays results on a 3D Part using `SurfaceGui`.  
  - *Client-side*: Creates a 2D voting interface with `ScreenGui`, supporting button interactions and result pop-ups.  


## 3. Core Functionality Design  
### 3.1 Voting Flow  
1. **Initiate Vote**:  
   - Admins trigger voting via the chat command `!startvote [Question]`, with a default duration of 30 seconds.  
   - The server broadcasts a `StartVote` event, and the client displays the voting UI.  

2. **Player Voting**:  
   - Players click option buttons (For/Against/Abstain), and the client sends a `CastVote` request to the server.  
   - The server validates votes and allows changes (overwriting previous choices).  
   - Non-admin players’ UIs close automatically after voting; admins can modify votes multiple times.  

3. **End Vote**:  
   - **Automatic End**: Triggered when all non-admin players have voted or the duration expires.  
   - **Manual End**: Admins use the `!endvote` command to force termination.  
   - The server broadcasts an `EndVote` event, and the client shows a final result pop-up.  


### 3.2 Interface and Interaction  
#### 3.2.1 Server-side Display (3D Part)  
- **Main Title**: Shows voting status (In Progress/Results), with dynamic color changes (white → green).  
- **Option Labels**: Real-time vote counts for each option, color-coded (green-For, red-Against, gray-Abstain).  
- **Font Size**: Fixed by default (main title: 32px, options: 28px); adjustable via the `TextSize` property.  

#### 3.2.2 Client-side UI (2D Interface)  
- **Voting Interface**:  
  - Includes the question title, option buttons (with live vote counts), and status notifications.  
  - Buttons highlight the selected option, and a success notification appears after voting.  
- **Result Pop-up**:  
  - Displays the voting question, vote counts, and percentages for each option.  
  - Supports manual closure or auto-dismissal (after 8 seconds).  


### 3.3 Permission Control  
- **Admin Features**:  
  - Initiate/end votes.  
  - Modify votes multiple times (UI remains open).  
- **Regular Players**:  
  - Can vote only once (modifications count as single operations).  
  - UI closes automatically after voting.  


## 4. Key Code Analysis  
### 4.1 Server-side Core Logic (`VotingSystem.lua`)  
#### 4.1.1 Vote Initiation Function  
```lua  
function StartVote(question, duration)  
    if currentVote then return false, "Vote already in progress" end  
    currentVote = {  
        Question = question,  
        StartTime = os.time(),  
        EndTime = os.time() + duration,  
        Options = {"FOR", "AGAINST", "ABSTAIN"}  
    }  
    votes = {["FOR"]=0, ["AGAINST"]=0, ["ABSTAIN"]=0}  
    VotingEvent:FireAllClients("StartVote", currentVote) -- Broadcast vote start  
    UpdateVoteResultDisplay()  
end  
```  

#### 4.1.2 Vote Handling Function  
```lua  
function CastVote(player, option)  
    local previousVote = votedPlayers[player.UserId]  
    if previousVote then votes[previousVote] = votes[previousVote] - 1 end -- Vote modification logic  
    votes[option] = votes[option] + 1  
    votedPlayers[player.UserId] = option  
    VotingEvent:FireAllClients("UpdateVotes", votes, votedPlayers) -- Update vote counts in real time  
    if not isAdmin then VotingEvent:FireClient(player, "CloseVoteUI") end -- Close UI for non-admins  
end  
```  

#### 4.1.3 Result Update Function  
```lua  
function UpdateVoteResultDisplay(isFinalResult)  
    if isFinalResult then  
        mainTextLabel.Text = "Voting Result: " .. currentVote.Question  
        mainTextLabel.TextColor3 = Color3.new(0, 1, 0)  
    else  
        mainTextLabel.Text = "Voting in Progress: " .. currentVote.Question  
    end  
    -- Update vote counts for each option  
    for _, option in ipairs(OPTIONS) do  
        optionLabels[option.name].Text = option.display .. ": " .. (votes[option.name] or 0) .. " Votes"  
    end  
end  
```  

### 4.2 Client-side UI Logic (`VotingUI.lua`)  
#### 4.2.1 Voting Interface Initialization  
```lua  
function StartVoteUI(voteData)  
    Frame.Visible = true  
    QuestionLabel.Text = "Vote: " .. voteData.Question  
    -- Create option buttons  
    for i, option in ipairs(OPTIONS) do  
        local btn = Instance.new("TextButton")  
        btn.Text = option.display  
        btn.TextColor3 = option.color  
        btn.MouseButton1Click:Connect(function()  
            VotingEvent:FireServer("CastVote", option.name) -- Send vote request  
        end)  
    end  
end  
```  

#### 4.2.2 Result Pop-up Display  
```lua  
function ShowVoteResults(voteData, results)  
    local resultFrame = Instance.new("Frame")  
    -- Display vote question and results for each option  
    for i, result in ipairs(results) do  
        local item = Instance.new("Frame")  
        -- Show option name, votes, and percentage  
        PercentageLabel.Text = math.floor((result.Votes / totalVotes) * 100) .. "%"  
    end  
    -- Add close button and auto-destruction logic  
    CloseButton.MouseButton1Click:Connect(function() resultFrame:Destroy() end)  
    task.wait(8, function() resultFrame:Destroy() end)  
end  
```  


## 5. Deployment and Configuration  
### 5.1 Admin Configuration  
- Modify the `admins` table in the server script to add admin usernames:  
  ```lua  
  local admins = {"AdminName1", "AdminName2"} -- Replace with actual admin names  
  ```  

### 5.2 Interface Customization  
- **Font Size**: Adjust the `TextSize` property (e.g., `mainTextLabel.TextSize = 36` for the main title).  
- **Color Scheme**: Change the `color` field in the `OPTIONS` table (e.g., `Color3.new(0, 0.8, 0)` for bright green).  
- **Layout Size**: Modify the `Size` and `Position` properties of `Frame` (use UDim2 for adaptive layouts).  


## 6. Extension Suggestions  
1. **Multilingual Support**: Add language switching via a configuration table for text localization.  
2. **Vote History**: Store voting records for admins to query past results.  
3. **Anti-Cheat**: Restrict multiple votes per player using UserID validation.  
4. **Animations**: Add fade-in/out effects to result pop-ups for better UX.  


## 7. Issue Troubleshooting  
| Issue Description        | Possible Cause                          | Solution                          |  
|--------------------------|-----------------------------------------|-----------------------------------|  
| Voting UI not displayed  | Remote event broadcast failed          | Check `VotingEvent:FireAllClients` |  
| Votes not updating real-time | Client not listening to `UpdateVotes` | Verify `VotingEvent.OnClientEvent` binding |  
| Admins cannot modify votes | Permission check error                  | Review `isAdmin` authentication logic |  
| Incorrect data in result pop-up | Server result data not passed correctly | Ensure `results` are included in `EndVote` event |
