-- Delta Executor: Dragon Nova Hub v18.3
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- 1. CẤU HÌNH TRẠNG THÁI DRAGON NOVA HUB
-- =================================================================
local teleguiadoActive = false
local autoSteal = false
local antiStun = false
local autoEggActive = false
local hitboxActive = false
local antiTrapActive = false

local speedVal = 220
local chunkVal = 18
local baseCFrame = CFrame.new(519.01, 70.27, -362.74)

local currentTween = nil
local stepCounter = 0
local phaseTimer = 0
local isStraightPhase = false

local updateTeleguiadoUI = function() end

local function setTeleguiado(state)
    if teleguiadoActive == state then return end
    teleguiadoActive = state

    if not state then
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
        stepCounter = 0
        phaseTimer = 0
        isStraightPhase = false
    end

    updateTeleguiadoUI()
end

-- =================================================================
-- 2. TỐI ƯU TỐC ĐỘ (DELAY 0) & GIỚI HẠN TẦM 25 STUDS
-- =================================================================
local shownPrompts = {}

local function bypassPrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 25
    end
end

local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    if parent:IsA("BasePart") then
        return parent.Position
    elseif parent:IsA("Attachment") then
        return parent.WorldPosition
    elseif parent:IsA("Model") then
        return parent:GetPivot().Position
    end
    return nil
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Enabled then return end
    bypassPrompt(prompt)
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        pcall(function()
            prompt:InputHoldBegin()
            prompt:InputHoldEnd()
        end)
    end
end

ProximityPromptService.PromptShown:Connect(function(prompt)
    bypassPrompt(prompt)
    shownPrompts[prompt] = true
    
    if autoSteal then
        triggerPrompt(prompt)
    end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    shownPrompts[prompt] = nil
end)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        bypassPrompt(descendant)
    end
end)

task.spawn(function()
    while true do
        task.wait()
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
                    if prompt and prompt.Enabled and prompt.Parent and prompt:IsDescendantOf(workspace:FindFirstChild("AreaEggSlotsClient") or workspace) then
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
                    setTeleguiado(true)
                end
            end

            if autoSteal then
                for prompt, _ in pairs(shownPrompts) do
                    if prompt and prompt.Enabled and prompt.Parent then
                        local pos = getPromptPosition(prompt)
                        if pos then
                            local dist = (hrp.Position - pos).Magnitude
                            if dist <= 25 then
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

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if player == LocalPlayer and autoEggActive then
        setTeleguiado(true)
    end
end)

-- =================================================================
-- 3. ANTI-STUN & ANTI-KNOCKBACK
-- =================================================================
local function setupCharacter(char)
    if not char then return end

    local hum = char:WaitForChild("Humanoid", 5)

    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

        hum.StateChanged:Connect(function(_, newState)
            if antiStun and (
                newState == Enum.HumanoidStateType.Physics
                or newState == Enum.HumanoidStateType.Ragdoll
                or newState == Enum.HumanoidStateType.FallingDown
            ) then

                hum:ChangeState(Enum.HumanoidStateType.GettingUp)

                local hrp = char:FindFirstChild("HumanoidRootPart")

                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end)
    end
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

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
                if motor:IsA("Motor6D") and not motor.Enabled then
                    motor.Enabled = true
                end
            end

            if hum.Sit then
                hum.Sit = false
            end

            if hum.PlatformStand then
                hum.PlatformStand = false
            end

            hum.AutoRotate = true
        end

        if hrp and hrp.Anchored then
            hrp.Anchored = false
        end
    end)
end)

-- =================================================================
-- 4. TELEGUIADO BAY TWEEN VỀ BASE
-- =================================================================
RunService.RenderStepped:Connect(function(deltaTime)
    if not teleguiadoActive then return end
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local targetPos = baseCFrame.Position
        local currentPos = hrp.Position
        local flatTarget = Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)
        local mainDir = (flatTarget - currentPos)
        local distance = mainDir.Magnitude

        if distance <= 6 then
            setTeleguiado(false)
            return
        end

        phaseTimer = phaseTimer + deltaTime
        if not isStraightPhase and phaseTimer >= 1.0 then
            isStraightPhase = true
            phaseTimer = 0
        elseif isStraightPhase and phaseTimer >= 0.5 then
            isStraightPhase = false
            phaseTimer = 0
        end

        local unitDir = mainDir.Unit
        local moveDir = unitDir

        if not isStraightPhase then
            local perp = Vector3.new(-unitDir.Z, 0, unitDir.X).Unit
            stepCounter = stepCounter + 1
            local zWave = math.sin(stepCounter * 0.35) * (chunkVal / 10)
            moveDir = (unitDir + perp * zWave).Unit
        end

        local moveDistance = speedVal * deltaTime
        local nextPos = currentPos + (moveDir * moveDistance)

        if currentTween then
            currentTween:Cancel()
        end

        local tweenInfo = TweenInfo.new(deltaTime, Enum.EasingStyle.Linear)
        currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(nextPos, nextPos + moveDir)})
        currentTween:Play()
    end)
end)

-- =================================================================
-- 5. HITBOX EXPANDER (ĐÃ FIX KHÔNG BỊ TRÔI & RESET SẠCH)
-- =================================================================
local function resetHitboxes()
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.Material = Enum.Material.Plastic
                    hrp.CanCollide = false
                end
            end
        end
    end)
end

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
-- 6. ANTI TRAP & TRAP ESP (workspace.__DEBRIS.PlayerTrap.Hitbox)
-- =================================================================
local trapESP = {}

local function getTrapFolder()
    local debris = workspace:FindFirstChild("__DEBRIS")
    if not debris then return nil end
    local playerTrap = debris:FindFirstChild("PlayerTrap")
    if not playerTrap then return nil end
    return playerTrap:FindFirstChild("Hitbox")
end

local function createTrapESP(part)
    if not antiTrapActive then return end
    if not part or not part:IsA("BasePart") then return end
    if trapESP[part] then return end

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
        pcall(function()
            if highlight then highlight:Destroy() end
        end)
        trapESP[part] = nil
    end
end

local function disableTrap(part)
    if not part or not part:IsA("BasePart") then return end

    pcall(function()
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false

        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("TouchTransmitter") or child.ClassName == "TouchInterest" then
                child:Destroy()
            end
        end

        if antiTrapActive then
            createTrapESP(part)
        end
    end)
end

local function scanTraps()
    local folder = getTrapFolder()
    if not folder then return end

    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("BasePart") then
            disableTrap(obj)
        end
    end
end

local function setAntiTrap(state)
    antiTrapActive = state
    if state then
        scanTraps()
    else
        removeTrapESP()
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if antiTrapActive then
            pcall(scanTraps)
        end
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if not antiTrapActive then return end
    pcall(function()
        local folder = getTrapFolder()
        if folder and obj:IsDescendantOf(folder) and obj:IsA("BasePart") then
            disableTrap(obj)
        end
    end)
end)

-- =================================================================
-- 7. GIAO DIỆN DRAGON NOVA HUB
-- =================================================================
local function createHubUI()
    local oldGui = CoreGui:FindFirstChild("DragonNovaHub") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("DragonNovaHub"))
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DragonNovaHub"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui
    mainFrame.Size = UDim2.new(0, 240, 0, 260)
    mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Color3.fromRGB(0, 200, 255) mainStroke.Thickness = 2

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Parent = mainFrame
    titleLabel.Size = UDim2.new(0.75, 0, 0, 35)
    titleLabel.Position = UDim2.new(0.05, 0, 0, 0)
    titleLabel.Text = "🐉 DRAGON NOVA HUB"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 15
    titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1

    local btnMin = Instance.new("TextButton")
    btnMin.Parent = mainFrame
    btnMin.Size = UDim2.new(0, 28, 0, 28)
    btnMin.Position = UDim2.new(0.85, 0, 0.02, 0)
    btnMin.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    btnMin.Text = "[-]"
    btnMin.Font = Enum.Font.SourceSansBold
    btnMin.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnMin.TextSize = 14
    Instance.new("UICorner", btnMin).CornerRadius = UDim.new(0, 6)

    local minIcon = Instance.new("TextButton")
    minIcon.Name = "MinIcon"
    minIcon.Parent = screenGui
    minIcon.Size = UDim2.new(0, 50, 0, 50)
    minIcon.Position = UDim2.new(0.02, 0, 0.45, 0)
    minIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    minIcon.Text = "🐉"
    minIcon.Font = Enum.Font.SourceSansBold
    minIcon.TextSize = 24
    minIcon.Visible = false
    minIcon.Active = true
    minIcon.Draggable = true
    Instance.new("UICorner", minIcon).CornerRadius = UDim.new(1, 0)
    local iconStroke = Instance.new("UIStroke", minIcon)
    iconStroke.Color = Color3.fromRGB(0, 200, 255) iconStroke.Thickness = 2

    btnMin.MouseButton1Click:Connect(function() mainFrame.Visible = false minIcon.Visible = true end)
    minIcon.MouseButton1Click:Connect(function() mainFrame.Visible = true minIcon.Visible = false end)

    local function createSlider(yPos, name, minVal, maxVal, defaultVal, callback)
        local container = Instance.new("Frame")
        container.Parent = mainFrame
        container.Size = UDim2.new(0.9, 0, 0, 38)
        container.Position = UDim2.new(0.05, 0, 0, yPos)
        container.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel")
        lbl.Parent = container
        lbl.Size = UDim2.new(1, 0, 0, 16)
        lbl.Text = name .. ": " .. tostring(defaultVal)
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.BackgroundTransparency = 1

        local bg = Instance.new("Frame")
        bg.Parent = container
        bg.Size = UDim2.new(1, 0, 0, 8)
        bg.Position = UDim2.new(0, 0, 0, 20)
        bg.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

        local fill = Instance.new("Frame")
        fill.Parent = bg
        local initPercent = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(initPercent, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

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
                dragging = true update(input)
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

    createSlider(35, "⚡ Tween Speed", 10, 600, speedVal, function(val) speedVal = val end)
    createSlider(75, "🌀 Chunk (S+Z)", 2, 100, chunkVal, function(val) chunkVal = val end)

    local function createGridButton(xRel, yPos, wRel, text, defaultState, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = mainFrame
        btn.Size = UDim2.new(wRel, -4, 0, 36)
        btn.Position = UDim2.new(xRel, 2, 0, yPos)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        btn.Text = text .. (defaultState and ": ON" or ": OFF")
        btn.Font = Enum.Font.SourceSansBold
        btn.TextColor3 = defaultState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 75, 75)
        btn.TextSize = 12
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = defaultState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 75, 75)
        stroke.Thickness = 1.5

        btn.MouseButton1Click:Connect(function()
            local newState = callback()
            btn.Text = text .. (newState and ": ON" or ": OFF")
            btn.TextColor3 = newState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 75, 75)
            stroke.Color = newState and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 75, 75)
        end)

        return btn
    end

    local btnTele = createGridButton(0.05, 120, 0.45, "🚀 Teleguiado", teleguiadoActive, function()
        setTeleguiado(not teleguiadoActive)
        return teleguiadoActive
    end)

    updateTeleguiadoUI = function()
        btnTele.Text = "🚀 Teleguiado" .. (teleguiadoActive and ": ON" or ": OFF")
        btnTele.TextColor3 = teleguiadoActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 75, 75)
    end

    createGridButton(0.50, 120, 0.45, "⚡ Auto Steal", autoSteal, function()
        autoSteal = not autoSteal
        return autoSteal
    end)

    createGridButton(0.05, 165, 0.45, "🛡️ Anti Stun", antiStun, function()
        antiStun = not antiStun
        return antiStun
    end)

    createGridButton(0.50, 165, 0.45, "🥚 Auto Pick", autoEggActive, function()
        autoEggActive = not autoEggActive
        return autoEggActive
    end)

    createGridButton(0.05, 210, 0.45, "🎯 Hitbox", hitboxActive, function()
        hitboxActive = not hitboxActive
        if not hitboxActive then resetHitboxes() end
        return hitboxActive
    end)

    createGridButton(0.50, 210, 0.45, "🪤 Anti Trap", antiTrapActive, function()
        setAntiTrap(not antiTrapActive)
        return antiTrapActive
    end)
end

createHubUI()
