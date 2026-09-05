-- Delta Executor: Dragon Nova Hub v25.5 (Full Features + Spotify Tab Integration)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- States
local teleguiadoActive = false
local autoSteal = false
local antiStun = true
local autoEggActive = false
local hitboxActive = true
local antiTrapActive = true
local monsterScanActive = false

-- Server Hop Configs
local targetPlayerCount = 0

-- Configs
local speedVal = 300
local chunkVal = 10
local baseCFrame = CFrame.new(519.01, 70.27, -362.74)
local currentTween = nil
local currentStatus = "..."

-- UI Callbacks
local updateStatusUI = function(text) end
local updateMonsterUI = function() end
local updateTeleguiadoUI = function() end

local function updateStatus(text)
    currentStatus = text
    updateStatusUI(text)
end

-- =================================================================
-- SOUND SYSTEM (SPOTIFY)
-- =================================================================
local currentSound = Instance.new("Sound")
currentSound.Name = "NovaSpotifySound"
currentSound.Volume = 0.5
currentSound.Looped = true
currentSound.Parent = workspace

local function playMusicById(soundId, songName)
    pcall(function()
        currentSound:Stop()
        currentSound.SoundId = "rbxassetid://" .. tostring(soundId)
        currentSound:Play()
        updateStatus("🎵 Đang phát: " .. songName)
    end)
end

-- =================================================================
-- 1. PROXIMITY PROMPT & BYPASS
-- =================================================================
local shownPrompts = {}

local function bypassPrompt(prompt, maxDist)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = maxDist or 25
    end
end

local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    if parent:IsA("BasePart") then return parent.Position
    elseif parent:IsA("Attachment") then return parent.WorldPosition
    elseif parent:IsA("Model") then return parent:GetPivot().Position end
    return nil
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    if fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
    else
        pcall(function() prompt:InputHoldBegin() task.wait(0.1) prompt:InputHoldEnd() end)
    end
end

ProximityPromptService.PromptShown:Connect(function(prompt)
    bypassPrompt(prompt, monsterScanActive and 1 or 25)
    shownPrompts[prompt] = true
    if autoSteal then triggerPrompt(prompt) end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    shownPrompts[prompt] = nil
end)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then 
        bypassPrompt(descendant, monsterScanActive and 1 or 25) 
    end
end)

-- AUTO PICK & AUTO STEAL LOOP
task.spawn(function()
    while true do
        task.wait(0.1)
        if not autoEggActive and not autoSteal then continue end

        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if autoEggActive then
                local closestPrompt = nil
                local minDist = 25
                for prompt, _ in pairs(shownPrompts) do
                    if prompt and prompt.Enabled and prompt.Parent then
                        local pos = getPromptPosition(prompt)
                        if pos then
                            local dist = (hrp.Position - pos).Magnitude
                            if dist <= minDist then
                                minDist = dist
                                closestPrompt = prompt
                            end
                        end
                    end
                end
                if closestPrompt then
                    triggerPrompt(closestPrompt)
                    teleguiadoActive = true
                    updateTeleguiadoUI()
                end
            end

            if autoSteal then
                for prompt, _ in pairs(shownPrompts) do
                    if prompt and prompt.Enabled and prompt.Parent then
                        local pos = getPromptPosition(prompt)
                        if pos then
                            if (hrp.Position - pos).Magnitude <= 25 then
                                triggerPrompt(prompt)
                            end
                        else
                            triggerPrompt(prompt)
                        end
                    end
                end
            end
        end)
    end
end)

-- =================================================================
-- 2. ANTI STUN & ANTI KNOCKBACK
-- =================================================================
local function setupCharacter(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

        hum.StateChanged:Connect(function(_, newState)
            if antiStun and (newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.FallingDown) then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
            end
            
            if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.PlatformStanding then
                if teleguiadoActive or monsterScanActive then
                    teleguiadoActive = false
                    monsterScanActive = false
                    updateStatus("⚠️ Ngắt do Stun!")
                    updateTeleguiadoUI()
                    updateMonsterUI()
                    if currentTween then pcall(function() currentTween:Cancel() end) currentTween = nil end
                end
            end
        end)
    end
    
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if hrp then
        task.spawn(function()
            while char and char.Parent do
                task.wait(0.1)
                if (teleguiadoActive or monsterScanActive) and hrp then
                    if hrp.AssemblyLinearVelocity.Magnitude > 350 then
                        teleguiadoActive = false
                        monsterScanActive = false
                        updateStatus("🚀 Ngắt do Văng!")
                        updateTeleguiadoUI()
                        updateMonsterUI()
                        if currentTween then pcall(function() currentTween:Cancel() end) currentTween = nil end
                    end
                end
            end
        end)
    end
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

RunService.Stepped:Connect(function()
    if not antiStun then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            for _, motor in ipairs(char:GetDescendants()) do
                if motor:IsA("Motor6D") and not motor.Enabled then motor.Enabled = true end
            end
            if hum.Sit then hum.Sit = false end
            if hum.PlatformStand then hum.PlatformStand = false end
            hum.AutoRotate = true
        end
        if hrp and hrp.Anchored then hrp.Anchored = false end
    end)
end)

-- =================================================================
-- 3. CHUNK TWEEN MOVEMENT
-- =================================================================
local function chunkTweenTo(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local startPos = hrp.Position
    local targetPos = targetCFrame.Position
    local totalDistance = (targetPos - startPos).Magnitude

    if totalDistance <= 1.5 then
        hrp.CFrame = targetCFrame
        hrp.AssemblyLinearVelocity = Vector3.zero
        return
    end

    local steps = math.max(1, math.floor(totalDistance / chunkVal))
    local direction = (targetPos - startPos).Unit

    for i = 1, steps do
        if not monsterScanActive and not teleguiadoActive then break end

        local nextPos = startPos + (direction * (i * chunkVal))
        if i == steps then nextPos = targetPos end

        local stepDistance = (nextPos - hrp.Position).Magnitude
        local duration = stepDistance / math.max(speedVal, 1)

        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(nextPos, nextPos + direction)})
        
        currentTween:Play()
        currentTween.Completed:Wait()
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

-- MONSTER ESP SYSTEM
local monsterESPFolder = Instance.new("Folder")
monsterESPFolder.Name = "MonsterESP_Folder"
monsterESPFolder.Parent = CoreGui

task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            monsterESPFolder:ClearAllChildren()
            local areaSlots = workspace:FindFirstChild("AreaEggSlotsClient")
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if areaSlots and hrp then
                for _, desc in ipairs(areaSlots:GetDescendants()) do
                    if desc.Name == "MonsterParasiteVisual" or desc.Name == "MonsterParasite" then
                        local mPos = desc:IsA("Model") and desc:GetPivot().Position or (desc:IsA("BasePart") and desc.Position)
                        if mPos then
                            local dist = math.floor((mPos - hrp.Position).Magnitude)
                            
                            local bgui = Instance.new("BillboardGui")
                            bgui.Name = "MonsterESP"
                            bgui.Adornee = desc:IsA("Model") and (desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")) or desc
                            bgui.Size = UDim2.new(0, 150, 0, 30)
                            bgui.StudsOffset = Vector3.new(0, 3, 0)
                            bgui.AlwaysOnTop = true
                            bgui.Parent = monsterESPFolder

                            local txt = Instance.new("TextLabel")
                            txt.Parent = bgui
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.Text = "👾 MonsterParasite [" .. tostring(dist) .. "m]"
                            txt.TextColor3 = Color3.fromRGB(180, 50, 255)
                            txt.Font = Enum.Font.GothamBold
                            txt.TextSize = 12
                            txt.TextStrokeTransparency = 0
                            txt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        end
                    end
                end
            end
        end)
    end
end)

-- =================================================================
-- 4. NEAREST MONSTER SCANNER
-- =================================================================
local function getNearestMonster()
    local areaSlots = workspace:FindFirstChild("AreaEggSlotsClient")
    if not areaSlots then return nil, nil end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end

    local closestObj = nil
    local closestPos = nil
    local minDistance = math.huge

    for _, desc in ipairs(areaSlots:GetDescendants()) do
        if desc.Name == "MonsterParasiteVisual" or desc.Name == "MonsterParasite" then
            local mPos = desc:IsA("Model") and desc:GetPivot().Position or (desc:IsA("BasePart") and desc.Position)
            if mPos then
                local dist = (mPos - hrp.Position).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    closestObj = desc
                    closestPos = mPos
                end
            end
        end
    end

    return closestObj, closestPos
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if not monsterScanActive then continue end

        local monsterObj, monsterPos = getNearestMonster()

        if monsterPos then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local dist = hrp and math.floor((monsterPos - hrp.Position).Magnitude) or 0

            updateStatus("Đang bay tới quái [" .. tostring(dist) .. "m]")
            chunkTweenTo(CFrame.new(monsterPos))

            if monsterScanActive then
                updateStatus("Đang tương tác...")

                local camera = workspace.CurrentCamera
                if camera and hrp then
                    camera.CameraType = Enum.CameraType.Scriptable
                    camera.FieldOfView = 50
                    camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 8, 0), hrp.Position)
                end

                task.wait(0.15)

                pcall(function()
                    for prompt, _ in pairs(shownPrompts) do
                        if prompt and prompt.Enabled and prompt.Parent then
                            bypassPrompt(prompt, 1)
                            triggerPrompt(prompt)
                        end
                    end
                end)

                pcall(function()
                    if camera then
                        camera.FieldOfView = 70
                        camera.CameraType = Enum.CameraType.Custom
                        camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    end
                end)

                updateStatus("Bay về Base...")
                teleguiadoActive = true
                updateTeleguiadoUI()
                chunkTweenTo(baseCFrame)
                teleguiadoActive = false
                updateTeleguiadoUI()

                task.wait(0.2)
            end
        else
            updateStatus("Không tìm thấy MonsterParasite")
        end
    end
end)

-- =================================================================
-- 5. HITBOX & ANTI TRAP SYSTEM
-- =================================================================
local trapESP = {}
local function createTrapESP(part)
    if not antiTrapActive or not part or not part:IsA("BasePart") or trapESP[part] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "DragonNova_TrapESP"
    highlight.Adornee = part
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Parent = part
    trapESP[part] = highlight
end

local function removeTrapESP()
    for part, highlight in pairs(trapESP) do
        pcall(function() if highlight then highlight:Destroy() end end)
        trapESP[part] = nil
    end
end

local function disableTrapPart(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function()
        part.CanTouch = false
        part.CanCollide = false
        part.CanQuery = false
        if string.lower(part.Name) == "hitbox" then part.Size = Vector3.new(0.001, 0.001, 0.001) end
        for _, child in ipairs(part:GetDescendants()) do
            if child:IsA("TouchTransmitter") or child.ClassName == "TouchInterest" then child:Destroy() end
        end
        if antiTrapActive then createTrapESP(part) end
    end)
end

local function scanTraps()
    local debris = workspace:FindFirstChild("__DEBRIS")
    if not debris then return end
    for _, child in ipairs(debris:GetChildren()) do
        for _, desc in ipairs(child:GetDescendants()) do if desc:IsA("BasePart") then disableTrapPart(desc) end end
        if child:IsA("BasePart") then disableTrapPart(child) end
    end
end

task.spawn(function()
    while true do task.wait(0.1) if antiTrapActive then pcall(scanTraps) end end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        if hitboxActive then
            pcall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Size = Vector3.new(15, 15, 15)
                            hrp.Transparency = 0.7
                            hrp.BrickColor = BrickColor.new("Really red")
                            hrp.Material = Enum.Material.Neon
                            hrp.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
end)

-- =================================================================
-- 6. UNIVERSAL UI PARENT FINDER & CREATION
-- =================================================================
local function getSafeUIParent()
    local target = nil
    if gethui then pcall(function() target = gethui() end) end
    if not target then pcall(function() target = game:GetService("CoreGui") end) end
    if not target then pcall(function() target = LocalPlayer:WaitForChild("PlayerGui", 5) end) end
    return target
end

-- SERVER HOP FUNCTION WITH FLEXIBLE SEARCH LOGIC
local function joinServerWithPlayers(reqPlayers)
    updateStatus("Đang quét Server (<= " .. tostring(reqPlayers) .. " player)...")
    local placeId = game.PlaceId
    local cursor = ""
    local foundServer = nil

    pcall(function()
        local pageCount = 0
        repeat
            pageCount = pageCount + 1
            local url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor ~= "" then url = url .. "&cursor=" .. cursor end
            
            local req = (syn and syn.request) or (http and http.request) or http_request or request
            if not req then
                updateStatus("Executor không hỗ trợ HTTP Request!")
                return
            end

            local res = req({Url = url, Method = "GET"})
            if res and res.StatusCode == 200 then
                local data = HttpService:JSONDecode(res.Body)
                if data and data.data then
                    for _, s in ipairs(data.data) do
                        if s.playing <= reqPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                            foundServer = s
                            break
                        end
                    end
                    cursor = data.nextPageCursor or ""
                else
                    break
                end
            else
                break
            end
            task.wait(0.2)
        until foundServer or not cursor or cursor == "" or pageCount >= 5
    end)

    if foundServer then
        updateStatus("Đang tham gia server...")
        pcall(function()
            local starterGui = game:GetService("StarterGui")
            starterGui:SetCore("SendNotification", {
                Title = "★ Dragon Nova Hub",
                Text = "Join server-id:" .. tostring(foundServer.id) .. " - player:" .. tostring(foundServer.playing),
                Duration = 6
            })
        end)
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(placeId, foundServer.id, LocalPlayer)
    else
        updateStatus("Chuyển server ngẫu nhiên...")
        pcall(function()
            TeleportService:Teleport(placeId, LocalPlayer)
        end)
    end
end

local function createHubUI()
    local parentFolder = getSafeUIParent()
    if not parentFolder then return end

    for _, old in ipairs(parentFolder:GetChildren()) do
        if old.Name == "DragonNovaHub" then old:Destroy() end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DragonNovaHub"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    screenGui.Parent = parentFolder

    -- SPEED DISPLAY
    local speedDisplayLabel = Instance.new("TextLabel")
    speedDisplayLabel.Name = "SpeedDisplay"
    speedDisplayLabel.Parent = screenGui
    speedDisplayLabel.Size = UDim2.new(0, 160, 0, 30)
    speedDisplayLabel.Position = UDim2.new(1, -170, 0, 10)
    speedDisplayLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    speedDisplayLabel.BackgroundTransparency = 0.2
    speedDisplayLabel.Text = "Speed: 0"
    speedDisplayLabel.Font = Enum.Font.GothamBold
    speedDisplayLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    speedDisplayLabel.TextSize = 14
    speedDisplayLabel.TextXAlignment = Enum.TextXAlignment.Center

    local speedCorner = Instance.new("UICorner", speedDisplayLabel)
    speedCorner.CornerRadius = UDim.new(0, 8)

    local speedStroke = Instance.new("UIStroke", speedDisplayLabel)
    speedStroke.Color = Color3.fromRGB(0, 220, 255)
    speedStroke.Thickness = 1.5

    task.spawn(function()
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        if leaderstats then
            local speedStat = leaderstats:WaitForChild("Speed", 10)
            if speedStat then
                speedDisplayLabel.Text = "Speed: " .. tostring(speedStat.Value)
                speedStat.Changed:Connect(function(newVal)
                    speedDisplayLabel.Text = "Speed: " .. tostring(newVal)
                end)
            else
                speedDisplayLabel.Text = "Speed: N/A"
            end
        else
            speedDisplayLabel.Text = "Speed: N/A"
        end
    end)

    -- MAIN FRAME
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 250, 0, 310)
    mainFrame.Position = UDim2.new(0.35, 0, 0.25, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Color3.fromRGB(0, 220, 255)
    mainStroke.Thickness = 2

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(0.5, 0, 0, 24)
    titleLabel.Position = UDim2.new(0.06, 0, 0, 8)
    titleLabel.Text = "★ DRAGON NOVA"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1

    local btnServer = Instance.new("TextButton")
    btnServer.Parent = mainFrame
    btnServer.Size = UDim2.new(0, 42, 0, 18)
    btnServer.Position = UDim2.new(0.06, 0, 0, 32)
    btnServer.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btnServer.Text = "Server"
    btnServer.Font = Enum.Font.GothamBold
    btnServer.TextColor3 = Color3.fromRGB(0, 220, 255)
    btnServer.TextSize = 8
    Instance.new("UICorner", btnServer).CornerRadius = UDim.new(0, 6)

    local btnSettings = Instance.new("TextButton")
    btnSettings.Parent = mainFrame
    btnSettings.Size = UDim2.new(0, 48, 0, 18)
    btnSettings.Position = UDim2.new(0.24, 0, 0, 32)
    btnSettings.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btnSettings.Text = "⚙ Settings"
    btnSettings.Font = Enum.Font.GothamBold
    btnSettings.TextColor3 = Color3.fromRGB(0, 220, 255)
    btnSettings.TextSize = 8
    Instance.new("UICorner", btnSettings).CornerRadius = UDim.new(0, 6)

    local btnLennon = Instance.new("TextButton")
    btnLennon.Parent = mainFrame
    btnLennon.Size = UDim2.new(0, 48, 0, 18)
    btnLennon.Position = UDim2.new(0.45, 0, 0, 32)
    btnLennon.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btnLennon.Text = "★ Lennon"
    btnLennon.Font = Enum.Font.GothamBold
    btnLennon.TextColor3 = Color3.fromRGB(255, 215, 0)
    btnLennon.TextSize = 8
    Instance.new("UICorner", btnLennon).CornerRadius = UDim.new(0, 6)

    -- SPOTIFY TAB
    local btnSpotifyTab = Instance.new("TextButton")
    btnSpotifyTab.Parent = mainFrame
    btnSpotifyTab.Size = UDim2.new(0, 58, 0, 18)
    btnSpotifyTab.Position = UDim2.new(0.66, 0, 0, 32)
    btnSpotifyTab.BackgroundColor3 = Color3.fromRGB(20, 45, 25)
    btnSpotifyTab.Text = "♫ Spotify ♫"
    btnSpotifyTab.Font = Enum.Font.GothamBold
    btnSpotifyTab.TextColor3 = Color3.fromRGB(30, 215, 96)
    btnSpotifyTab.TextSize = 8
    Instance.new("UICorner", btnSpotifyTab).CornerRadius = UDim.new(0, 6)

    local statusBox = Instance.new("Frame")
    statusBox.Parent = mainFrame
    statusBox.Size = UDim2.new(0.88, 0, 0, 34)
    statusBox.Position = UDim2.new(0.06, 0, 0, 58)
    statusBox.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 10)
    local statusStroke = Instance.new("UIStroke", statusBox)
    statusStroke.Color = Color3.fromRGB(0, 180, 220)
    statusStroke.Thickness = 1

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = statusBox
    statusLabel.Size = UDim2.new(1, 0, 1, 0)
    statusLabel.Text = "..."
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 180)
    statusLabel.TextSize = 11
    statusLabel.BackgroundTransparency = 1

    updateStatusUI = function(text)
        if statusLabel then statusLabel.Text = text end
    end

    -- SERVER PANEL
    local serverPanel = Instance.new("Frame")
    serverPanel.Parent = screenGui
    serverPanel.Size = UDim2.new(0, 250, 0, 310)
    serverPanel.Position = mainFrame.Position + UDim2.new(0, 260, 0, 0)
    serverPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    serverPanel.Visible = false
    serverPanel.Active = true
    serverPanel.Draggable = true
    Instance.new("UICorner", serverPanel).CornerRadius = UDim.new(0, 12)
    local serverStroke = Instance.new("UIStroke", serverPanel)
    serverStroke.Color = Color3.fromRGB(0, 220, 255)
    serverStroke.Thickness = 2

    local serverTitle = Instance.new("TextLabel")
    serverTitle.Parent = serverPanel
    serverTitle.Size = UDim2.new(1, 0, 0, 35)
    serverTitle.Position = UDim2.new(0, 0, 0, 5)
    serverTitle.Text = "🌐 TÌM SERVER"
    serverTitle.Font = Enum.Font.GothamBold
    serverTitle.TextSize = 13
    serverTitle.TextColor3 = Color3.fromRGB(0, 220, 255)
    serverTitle.BackgroundTransparency = 1

    local counterFrame = Instance.new("Frame")
    counterFrame.Parent = serverPanel
    counterFrame.Size = UDim2.new(0.88, 0, 0, 45)
    counterFrame.Position = UDim2.new(0.06, 0, 0, 55)
    counterFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    Instance.new("UICorner", counterFrame).CornerRadius = UDim.new(0, 8)
    local counterStroke = Instance.new("UIStroke", counterFrame)
    counterStroke.Color = Color3.fromRGB(0, 180, 220)
    counterStroke.Thickness = 1.2

    local btnSub = Instance.new("TextButton")
    btnSub.Parent = counterFrame
    btnSub.Size = UDim2.new(0, 40, 1, 0)
    btnSub.Position = UDim2.new(0, 0, 0, 0)
    btnSub.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btnSub.Text = "-"
    btnSub.Font = Enum.Font.GothamBold
    btnSub.TextColor3 = Color3.fromRGB(255, 80, 80)
    btnSub.TextSize = 20
    Instance.new("UICorner", btnSub).CornerRadius = UDim.new(0, 8)

    local playerCountLabel = Instance.new("TextLabel")
    playerCountLabel.Parent = counterFrame
    playerCountLabel.Size = UDim2.new(1, -80, 1, 0)
    playerCountLabel.Position = UDim2.new(0, 40, 0, 0)
    playerCountLabel.Text = "0"
    playerCountLabel.Font = Enum.Font.GothamBold
    playerCountLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    playerCountLabel.TextSize = 18
    playerCountLabel.BackgroundTransparency = 1

    local btnAdd = Instance.new("TextButton")
    btnAdd.Parent = counterFrame
    btnAdd.Size = UDim2.new(0, 40, 1, 0)
    btnAdd.Position = UDim2.new(1, -40, 0, 0)
    btnAdd.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    btnAdd.Text = "+"
    btnAdd.Font = Enum.Font.GothamBold
    btnAdd.TextColor3 = Color3.fromRGB(80, 255, 120)
    btnAdd.TextSize = 20
    Instance.new("UICorner", btnAdd).CornerRadius = UDim.new(0, 8)

    btnSub.MouseButton1Click:Connect(function()
        if targetPlayerCount > 0 then
            targetPlayerCount = targetPlayerCount - 1
            playerCountLabel.Text = tostring(targetPlayerCount)
        end
    end)

    btnAdd.MouseButton1Click:Connect(function()
        targetPlayerCount = targetPlayerCount + 1
        playerCountLabel.Text = tostring(targetPlayerCount)
    end)

    local btnJoinServer = Instance.new("TextButton")
    btnJoinServer.Parent = serverPanel
    btnJoinServer.Size = UDim2.new(0.88, 0, 0, 40)
    btnJoinServer.Position = UDim2.new(0.06, 0, 0, 115)
    btnJoinServer.BackgroundColor3 = Color3.fromRGB(0, 60, 45)
    btnJoinServer.Text = "Tham Gia Server"
    btnJoinServer.Font = Enum.Font.GothamBold
    btnJoinServer.TextColor3 = Color3.fromRGB(0, 255, 150)
    btnJoinServer.TextSize = 13
    Instance.new("UICorner", btnJoinServer).CornerRadius = UDim.new(0, 8)
    local joinStroke = Instance.new("UIStroke", btnJoinServer)
    joinStroke.Color = Color3.fromRGB(0, 255, 150)
    joinStroke.Thickness = 1.2

    btnJoinServer.MouseButton1Click:Connect(function()
        task.spawn(function()
            joinServerWithPlayers(targetPlayerCount)
        end)
    end)

    -- SETTINGS PANEL
    local settingsPanel = Instance.new("Frame")
    settingsPanel.Parent = screenGui
    settingsPanel.Size = UDim2.new(0, 250, 0, 310)
    settingsPanel.Position = mainFrame.Position + UDim2.new(0, 260, 0, 0)
    settingsPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    settingsPanel.Visible = false
    settingsPanel.Active = true
    settingsPanel.Draggable = true
    Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0, 12)
    local setsStroke = Instance.new("UIStroke", settingsPanel)
    setsStroke.Color = Color3.fromRGB(255, 165, 0)
    setsStroke.Thickness = 2

    local setsTitle = Instance.new("TextLabel")
    setsTitle.Parent = settingsPanel
    setsTitle.Size = UDim2.new(1, 0, 0, 35)
    setsTitle.Position = UDim2.new(0, 0, 0, 5)
    setsTitle.Text = "⚙ CÀI ĐẶT (SETTINGS)"
    setsTitle.Font = Enum.Font.GothamBold
    setsTitle.TextSize = 13
    setsTitle.TextColor3 = Color3.fromRGB(255, 165, 0)
    setsTitle.BackgroundTransparency = 1

    -- LENNON PANEL
    local lennonPanel = Instance.new("Frame")
    lennonPanel.Parent = screenGui
    lennonPanel.Size = UDim2.new(0, 250, 0, 310)
    lennonPanel.Position = mainFrame.Position + UDim2.new(0, 260, 0, 0)
    lennonPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    lennonPanel.Visible = false
    lennonPanel.Active = true
    lennonPanel.Draggable = true
    Instance.new("UICorner", lennonPanel).CornerRadius = UDim.new(0, 12)
    local lennonStroke = Instance.new("UIStroke", lennonPanel)
    lennonStroke.Color = Color3.fromRGB(255, 215, 0)
    lennonStroke.Thickness = 2

    local lennonTitle = Instance.new("TextLabel")
    lennonTitle.Parent = lennonPanel
    lennonTitle.Size = UDim2.new(1, 0, 0, 35)
    lennonTitle.Position = UDim2.new(0, 0, 0, 5)
    lennonTitle.Text = "★ LENNON MENU"
    lennonTitle.Font = Enum.Font.GothamBold
    lennonTitle.TextSize = 13
    lennonTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    lennonTitle.BackgroundTransparency = 1

    local btnLennonHubVip = Instance.new("TextButton")
    btnLennonHubVip.Parent = lennonPanel
    btnLennonHubVip.Size = UDim2.new(0.88, 0, 0, 40)
    btnLennonHubVip.Position = UDim2.new(0.06, 0, 0, 50)
    btnLennonHubVip.BackgroundColor3 = Color3.fromRGB(35, 30, 15)
    btnLennonHubVip.Text = "★ Lennon Hub Vip"
    btnLennonHubVip.Font = Enum.Font.GothamBold
    btnLennonHubVip.TextColor3 = Color3.fromRGB(255, 215, 0)
    btnLennonHubVip.TextSize = 13
    Instance.new("UICorner", btnLennonHubVip).CornerRadius = UDim.new(0, 8)

    local lennonBtnStroke = Instance.new("UIStroke", btnLennonHubVip)
    lennonBtnStroke.Color = Color3.fromRGB(255, 215, 0)
    lennonBtnStroke.Thickness = 1.2

    btnLennonHubVip.MouseButton1Click:Connect(function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/lennonxscripts/lennonhub/main/stealaegg.lua"))()
        end)
    end)

    -- SPOTIFY PANEL
    local spotifyPanel = Instance.new("Frame")
    spotifyPanel.Parent = screenGui
    spotifyPanel.Size = UDim2.new(0, 250, 0, 310)
    spotifyPanel.Position = mainFrame.Position + UDim2.new(0, 260, 0, 0)
    spotifyPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    spotifyPanel.Visible = false
    spotifyPanel.Active = true
    spotifyPanel.Draggable = true
    Instance.new("UICorner", spotifyPanel).CornerRadius = UDim.new(0, 12)

    local spotifyStroke = Instance.new("UIStroke", spotifyPanel)
    spotifyStroke.Color = Color3.fromRGB(30, 215, 96)
    spotifyStroke.Thickness = 2

    local spotifyTitle = Instance.new("TextLabel")
    spotifyTitle.Parent = spotifyPanel
    spotifyTitle.Size = UDim2.new(1, 0, 0, 30)
    spotifyTitle.Position = UDim2.new(0, 0, 0, 5)
    spotifyTitle.Text = "♫ SPOTIFY PLAYER ♫"
    spotifyTitle.Font = Enum.Font.GothamBold
    spotifyTitle.TextSize = 13
    spotifyTitle.TextColor3 = Color3.fromRGB(30, 215, 96)
    spotifyTitle.BackgroundTransparency = 1

    local songCtrlFrame = Instance.new("Frame")
    songCtrlFrame.Parent = spotifyPanel
    songCtrlFrame.Size = UDim2.new(0.88, 0, 0, 32)
    songCtrlFrame.Position = UDim2.new(0.06, 0, 0, 40)
    songCtrlFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    Instance.new("UICorner", songCtrlFrame).CornerRadius = UDim.new(0, 8)

    local btnPrev = Instance.new("TextButton")
    btnPrev.Parent = songCtrlFrame
    btnPrev.Size = UDim2.new(0, 30, 1, 0)
    btnPrev.Text = "←"
    btnPrev.Font = Enum.Font.GothamBold
    btnPrev.TextColor3 = Color3.fromRGB(30, 215, 96)
    btnPrev.TextSize = 16
    btnPrev.BackgroundTransparency = 1

    local songNameLbl = Instance.new("TextLabel")
    songNameLbl.Parent = songCtrlFrame
    songNameLbl.Size = UDim2.new(1, -60, 1, 0)
    songNameLbl.Position = UDim2.new(0, 30, 0, 0)
    songNameLbl.Text = "_ThonRemix_"
    songNameLbl.Font = Enum.Font.GothamBold
    songNameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    songNameLbl.TextSize = 11
    songNameLbl.BackgroundTransparency = 1

    local btnNext = Instance.new("TextButton")
    btnNext.Parent = songCtrlFrame
    btnNext.Size = UDim2.new(0, 30, 1, 0)
    btnNext.Position = UDim2.new(1, -30, 0, 0)
    btnNext.Text = "→"
    btnNext.Font = Enum.Font.GothamBold
    btnNext.TextColor3 = Color3.fromRGB(30, 215, 96)
    btnNext.TextSize = 16
    btnNext.BackgroundTransparency = 1

    local volContainer = Instance.new("Frame")
    volContainer.Parent = spotifyPanel
    volContainer.Size = UDim2.new(0.88, 0, 0, 35)
    volContainer.Position = UDim2.new(0.06, 0, 0, 78)
    volContainer.BackgroundTransparency = 1

    local volLbl = Instance.new("TextLabel")
    volLbl.Parent = volContainer
    volLbl.Size = UDim2.new(1, 0, 0, 14)
    volLbl.Text = "Volume: 50%"
    volLbl.Font = Enum.Font.GothamBold
    volLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    volLbl.TextSize = 10
    volLbl.TextXAlignment = Enum.TextXAlignment.Left
    volLbl.BackgroundTransparency = 1

    local volBg = Instance.new("Frame")
    volBg.Parent = volContainer
    volBg.Size = UDim2.new(1, 0, 0, 6)
    volBg.Position = UDim2.new(0, 0, 0, 18)
    volBg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", volBg).CornerRadius = UDim.new(0, 3)

    local volFill = Instance.new("Frame")
    volFill.Parent = volBg
    volFill.Size = UDim2.new(0.5, 0, 1, 0)
    volFill.BackgroundColor3 = Color3.fromRGB(30, 215, 96)
    Instance.new("UICorner", volFill).CornerRadius = UDim.new(0, 3)

    local draggingVol = false
    local function updateVolume(input)
        local pos = math.clamp((input.Position.X - volBg.AbsolutePosition.X) / volBg.AbsoluteSize.X, 0, 1)
        volFill.Size = UDim2.new(pos, 0, 1, 0)
        local volVal = math.floor(pos * 100)
        volLbl.Text = "Volume: " .. tostring(volVal) .. "%"
        currentSound.Volume = pos
    end

    volBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingVol = true updateVolume(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateVolume(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingVol = false
        end
    end)

    local btnPlayThon = Instance.new("TextButton")
    btnPlayThon.Parent = spotifyPanel
    btnPlayThon.Size = UDim2.new(0.88, 0, 0, 35)
    btnPlayThon.Position = UDim2.new(0.06, 0, 0, 122)
    btnPlayThon.BackgroundColor3 = Color3.fromRGB(20, 45, 25)
    btnPlayThon.Text = "▶ ThonRemix (81533059856274)"
    btnPlayThon.Font = Enum.Font.GothamBold
    btnPlayThon.TextColor3 = Color3.fromRGB(30, 215, 96)
    btnPlayThon.TextSize = 10
    Instance.new("UICorner", btnPlayThon).CornerRadius = UDim.new(0, 8)

    btnPlayThon.MouseButton1Click:Connect(function()
        songNameLbl.Text = "ThonRemix"
        playMusicById("81533059856274", "ThonRemix")
    end)

    local btnPlayChina = Instance.new("TextButton")
    btnPlayChina.Parent = spotifyPanel
    btnPlayChina.Size = UDim2.new(0.88, 0, 0, 35)
    btnPlayChina.Position = UDim2.new(0.06, 0, 0, 165)
    btnPlayChina.BackgroundColor3 = Color3.fromRGB(20, 45, 25)
    btnPlayChina.Text = "▶ 中国音乐 (87570666848900)"
    btnPlayChina.Font = Enum.Font.GothamBold
    btnPlayChina.TextColor3 = Color3.fromRGB(30, 215, 96)
    btnPlayChina.TextSize = 10
    Instance.new("UICorner", btnPlayChina).CornerRadius = UDim.new(0, 8)

    btnPlayChina.MouseButton1Click:Connect(function()
        songNameLbl.Text = "中国音乐"
        playMusicById("87570666848900", "中国音乐")
    end)

    local btnStopMusic = Instance.new("TextButton")
    btnStopMusic.Parent = spotifyPanel
    btnStopMusic.Size = UDim2.new(0.88, 0, 0, 30)
    btnStopMusic.Position = UDim2.new(0.06, 0, 0, 210)
    btnStopMusic.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
    btnStopMusic.Text = "⏸ Dừng Phát Nhạc"
    btnStopMusic.Font = Enum.Font.GothamBold
    btnStopMusic.TextColor3 = Color3.fromRGB(255, 80, 80)
    btnStopMusic.TextSize = 10
    Instance.new("UICorner", btnStopMusic).CornerRadius = UDim.new(0, 8)

    btnStopMusic.MouseButton1Click:Connect(function()
        currentSound:Stop()
        updateStatus("⏸ Đã dừng nhạc")
    end)

    -- PANEL TOGGLES
    btnServer.MouseButton1Click:Connect(function() 
        serverPanel.Visible = not serverPanel.Visible 
        if serverPanel.Visible then
            settingsPanel.Visible = false
            lennonPanel.Visible = false
            spotifyPanel.Visible = false
        end
    end)

    btnSettings.MouseButton1Click:Connect(function() 
        settingsPanel.Visible = not settingsPanel.Visible 
        if settingsPanel.Visible then
            serverPanel.Visible = false
            lennonPanel.Visible = false
            spotifyPanel.Visible = false
        end
    end)

    btnLennon.MouseButton1Click:Connect(function() 
        lennonPanel.Visible = not lennonPanel.Visible 
        if lennonPanel.Visible then
            serverPanel.Visible = false
            settingsPanel.Visible = false
            spotifyPanel.Visible = false
        end
    end)

    btnSpotifyTab.MouseButton1Click:Connect(function()
        spotifyPanel.Visible = not spotifyPanel.Visible
        if spotifyPanel.Visible then
            serverPanel.Visible = false
            settingsPanel.Visible = false
            lennonPanel.Visible = false
        end
    end)

    local function createGridButtonInPanel(parentPanel, xRel, yPos, wRel, text, defaultState, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = parentPanel
        btn.Size = UDim2.new(wRel, -4, 0, 32)
        btn.Position = UDim2.new(xRel, 2, 0, yPos)
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 45, 30) or Color3.fromRGB(25, 25, 35)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = defaultState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 200, 210)
        btn.TextSize = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = defaultState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(50, 50, 65)
        stroke.Thickness = 1.2

        btn.MouseButton1Click:Connect(function()
            local newState = callback()
            btn.BackgroundColor3 = newState and Color3.fromRGB(0, 45, 30) or Color3.fromRGB(25, 25, 35)
            btn.TextColor3 = newState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 200, 210)
            stroke.Color = newState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(50, 50, 65)
        end)
        return btn
    end

    createGridButtonInPanel(settingsPanel, 0.06, 40, 0.42, "Anti Stun", antiStun, function() antiStun = not antiStun return antiStun end)
    createGridButtonInPanel(settingsPanel, 0.52, 40, 0.42, "Anti Trap", antiTrapActive, function() 
        antiTrapActive = not antiTrapActive 
        if not antiTrapActive then removeTrapESP() end
        return antiTrapActive 
    end)

    createGridButtonInPanel(settingsPanel, 0.06, 78, 0.88, "Hitbox (15x15)", hitboxActive, function() 
        hitboxActive = not hitboxActive 
        if not hitboxActive then
            pcall(function()
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.Size = Vector3.new(2, 2, 1) hrp.Transparency = 1 hrp.CanCollide = false end
                    end
                end
            end)
        end
        return hitboxActive 
    end)

    local function createSlider(yPos, name, minVal, maxVal, defaultVal, callback)
        local container = Instance.new("Frame")
        container.Parent = settingsPanel
        container.Size = UDim2.new(0.88, 0, 0, 38)
        container.Position = UDim2.new(0.06, 0, 0, yPos)
        container.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel")
        lbl.Parent = container
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.Text = name .. ": " .. tostring(defaultVal)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BackgroundTransparency = 1

        local bg = Instance.new("Frame")
        bg.Parent = container
        bg.Size = UDim2.new(1, 0, 0, 6)
        bg.Position = UDim2.new(0, 0, 0, 20)
        bg.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 3)

        local fill = Instance.new("Frame")
        fill.Parent = bg
        local initPercent = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(initPercent, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

        local dragging = false
        local function update(input)
            local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor(minVal + (maxVal - minVal) * pos)
            lbl.Text = name .. ": " .. tostring(val)
            callback(val)
        end

        bg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(input)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    createSlider(125, "⚡ Tween Speed", 10, 600, speedVal, function(val) speedVal = val end)
    createSlider(175, "🌀 Chunk", 2, 100, chunkVal, function(val) chunkVal = val end)

    -- MAIN MENU BUTTONS
    local function createMainGridButton(xRel, yPos, wRel, text, defaultState, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = mainFrame
        btn.Size = UDim2.new(wRel, -4, 0, 35)
        btn.Position = UDim2.new(xRel, 2, 0, yPos)
        btn.BackgroundColor3 = defaultState and Color3.fromRGB(0, 45, 30) or Color3.fromRGB(25, 25, 35)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = defaultState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 200, 210)
        btn.TextSize = 11
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = defaultState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(50, 50, 65)
        stroke.Thickness = 1.2

        btn.MouseButton1Click:Connect(function()
            local newState = callback()
            btn.BackgroundColor3 = newState and Color3.fromRGB(0, 45, 30) or Color3.fromRGB(25, 25, 35)
            btn.TextColor3 = newState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 200, 210)
            stroke.Color = newState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(50, 50, 65)
        end)
        return btn
    end

    local btnTele = createMainGridButton(0.06, 105, 0.42, "Teleguiado", teleguiadoActive, function()
        teleguiadoActive = not teleguiadoActive
        if teleguiadoActive then task.spawn(function() chunkTweenTo(baseCFrame) end) end
        return teleguiadoActive
    end)

    updateTeleguiadoUI = function()
        btnTele.BackgroundColor3 = teleguiadoActive and Color3.fromRGB(0, 45, 30) or Color3.fromRGB(25, 25, 35)
        btnTele.TextColor3 = teleguiadoActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 200, 210)
        local stroke = btnTele:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = teleguiadoActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(50, 50, 65) end
    end

    createMainGridButton(0.52, 105, 0.42, "Auto Steal", autoSteal, function() autoSteal = not autoSteal return autoSteal end)
    createMainGridButton(0.06, 145, 0.42, "Auto Pick", autoEggActive, function() autoEggActive = not autoEggActive return autoEggActive end)

    local btnMonster = createMainGridButton(0.52, 145, 0.42, "Monster", monsterScanActive, function()
        monsterScanActive = not monsterScanActive
        if not monsterScanActive then 
            updateStatus("...") 
        end
        return monsterScanActive
    end)

    updateMonsterUI = function()
        btnMonster.BackgroundColor3 = monsterScanActive and Color3.fromRGB(0, 45, 30) or Color3.fromRGB(25, 25, 35)
        btnMonster.TextColor3 = monsterScanActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 200, 210)
        local stroke = btnMonster:FindFirstChildOfClass("UIStroke")
        if stroke then stroke.Color = monsterScanActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(50, 50, 65) end
    end

    -- NÚT THU NHỎ
    local btnMin = Instance.new("TextButton")
    btnMin.Parent = mainFrame
    btnMin.Size = UDim2.new(0, 26, 0, 26)
    btnMin.Position = UDim2.new(0.84, 0, 0.05, 0)
    btnMin.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btnMin.Text = "-"
    btnMin.Font = Enum.Font.GothamBold
    btnMin.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMin.TextSize = 14
    Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, 6)

    local minIcon = Instance.new("TextButton")
    minIcon.Name = "MinIcon"
    minIcon.Parent = screenGui
    minIcon.Size = UDim2.new(0, 45, 0, 45)
    minIcon.Position = UDim2.new(0.02, 0, 0.45, 0)
    minIcon.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    minIcon.Text = "★"
    minIcon.Font = Enum.Font.GothamBold
    minIcon.TextSize = 22
    minIcon.Visible = false
    minIcon.Active = true
    minIcon.Draggable = true
    Instance.new("UICorner", minIcon).CornerRadius = UDim.new(1, 0)
    local iconStroke = Instance.new("UIStroke", minIcon)
    iconStroke.Color = Color3.fromRGB(0, 220, 255)
    iconStroke.Thickness = 2

    btnMin.MouseButton1Click:Connect(function() 
        mainFrame.Visible = false 
        serverPanel.Visible = false
        settingsPanel.Visible = false
        lennonPanel.Visible = false
        spotifyPanel.Visible = false
        minIcon.Visible = true 
    end)
    minIcon.MouseButton1Click:Connect(function() 
        mainFrame.Visible = true 
        minIcon.Visible = false 
    end)
end

createHubUI()
