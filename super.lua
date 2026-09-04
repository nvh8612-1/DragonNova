-- Delta Executor: Dragon Nova Hub v25.3 (Distance = 25 Studs + Monster MaxDistance = 1 + Clean UI)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- States (Đã tự động bật Anti Stun, Anti Trap, Hitbox)
local teleguiadoActive = false
local autoSteal = false
local antiStun = true
local autoEggActive = false
local hitboxActive = true
local antiTrapActive = true
local monsterScanActive = false
local zigzagMode = false -- Mặc định bay thẳng

-- Configs (Mặc định Speed 300 / Chunk 10)
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

    -- SPEED DISPLAY (GÓC TRÊN BÊN PHẢI MÀN HÌNH)
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

    local btnInfo = Instance.new("TextButton")
    btnInfo.Parent = mainFrame
    btnInfo.Size = UDim2.new(0, 55, 0, 18)
    btnInfo.Position = UDim2.new(0.06, 0, 0, 32)
    btnInfo.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btnInfo.Text = "ⓘ Chi Tiết"
    btnInfo.Font = Enum.Font.GothamBold
    btnInfo.TextColor3 = Color3.fromRGB(0, 220, 255)
    btnInfo.TextSize = 9
    Instance.new("UICorner", btnInfo).CornerRadius = UDim.new(0, 6)

    local btnSettings = Instance.new("TextButton")
    btnSettings.Parent = mainFrame
    btnSettings.Size = UDim2.new(0, 55, 0, 18)
    btnSettings.Position = UDim2.new(0.31, 0, 0, 32)
    btnSettings.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btnSettings.Text = "⚙ Settings"
    btnSettings.Font = Enum.Font.GothamBold
    btnSettings.TextColor3 = Color3.fromRGB(0, 220, 255)
    btnSettings.TextSize = 9
    Instance.new("UICorner", btnSettings).CornerRadius = UDim.new(0, 6)

    local btnLennon = Instance.new("TextButton")
    btnLennon.Parent = mainFrame
    btnLennon.Size = UDim2.new(0, 55, 0, 18)
    btnLennon.Position = UDim2.new(0.56, 0, 0, 32)
    btnLennon.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btnLennon.Text = "★ Lennon"
    btnLennon.Font = Enum.Font.GothamBold
    btnLennon.TextColor3 = Color3.fromRGB(255, 215, 0)
    btnLennon.TextSize = 9
    Instance.new("UICorner", btnLennon).CornerRadius = UDim.new(0, 6)

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

    -- INFO PANEL
    local infoPanel = Instance.new("Frame")
    infoPanel.Parent = screenGui
    infoPanel.Size = UDim2.new(0, 260, 0, 310)
    infoPanel.Position = mainFrame.Position + UDim2.new(0, 260, 0, 0)
    infoPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    infoPanel.Visible = false
    infoPanel.Active = true
    infoPanel.Draggable = true
    Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 12)
    local infoStroke = Instance.new("UIStroke", infoPanel)
    infoStroke.Color = Color3.fromRGB(0, 220, 255)
    infoStroke.Thickness = 2

    local infoTitle = Instance.new("TextLabel")
    infoTitle.Parent = infoPanel
    infoTitle.Size = UDim2.new(1, 0, 0, 35)
    infoTitle.Position = UDim2.new(0, 0, 0, 5)
    infoTitle.Text = "📖 HƯỚNG DẪN CHỨC NĂNG"
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.TextSize = 13
    infoTitle.TextColor3 = Color3.fromRGB(0, 220, 255)
    infoTitle.BackgroundTransparency = 1

    local infoScrolling = Instance.new("ScrollingFrame")
    infoScrolling.Parent = infoPanel
    infoScrolling.Size = UDim2.new(0.9, 0, 0, 255)
    infoScrolling.Position = UDim2.new(0.05, 0, 0, 40)
    infoScrolling.BackgroundTransparency = 1
    infoScrolling.CanvasSize = UDim2.new(0, 0, 0, 380)
    infoScrolling.ScrollBarThickness = 4

    local infoContent = Instance.new("TextLabel")
    infoContent.Parent = infoScrolling
    infoContent.Size = UDim2.new(1, 0, 1, 0)
    infoContent.Font = Enum.Font.Gotham
    infoContent.TextSize = 11
    infoContent.TextColor3 = Color3.fromRGB(210, 210, 220)
    infoContent.TextXAlignment = Enum.TextXAlignment.Left
    infoContent.TextYAlignment = Enum.TextYAlignment.Top
    infoContent.TextWrapped = true
    infoContent.BackgroundTransparency = 1
    infoContent.Text = [[• Teleguiado: Bay thẳng về Base.
• Auto Steal: Kích hoạt Prompt xung quanh.
• Auto Pick: Tự động nhặt trứng/vật phẩm.
• Monster Scan: Tìm MonsterParasite gần nhất, hạ Cam 90°, đặt tầm Prompt = 1 stud & chở về Base.
• Anti Stun: Chống khựng/Ragdoll/Văng.
• Hitbox: Phóng to Hitbox kẻ địch (15x15).
• Anti Trap: Xóa bẫy trong __DEBRIS.]]

    btnInfo.MouseButton1Click:Connect(function() 
        infoPanel.Visible = not infoPanel.Visible 
        if infoPanel.Visible then
            settingsPanel.Visible = false
            lennonPanel.Visible = false
        end
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

    btnSettings.MouseButton1Click:Connect(function() 
        settingsPanel.Visible = not settingsPanel.Visible 
        if settingsPanel.Visible then
            infoPanel.Visible = false
            lennonPanel.Visible = false
        end
    end)

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

    btnLennon.MouseButton1Click:Connect(function() 
        lennonPanel.Visible = not lennonPanel.Visible 
        if lennonPanel.Visible then
            infoPanel.Visible = false
            settingsPanel.Visible = false
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
        infoPanel.Visible = false
        settingsPanel.Visible = false
        lennonPanel.Visible = false
        minIcon.Visible = true 
    end)
    minIcon.MouseButton1Click:Connect(function() 
        mainFrame.Visible = true 
        minIcon.Visible = false 
    end)
end

createHubUI()
