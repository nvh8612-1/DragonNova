-- Delta Executor: Dragon Nova Hub v18.7 (Default Config Updated - Speed: 310, Chunk: 20)
-- 🚀 Teleguiado: Bay theo chuỗi logic mới (Thẳng 0.5s -> Trái Z 0.3s -> Thẳng 0.1s -> Phải Z 0.3s)
-- 👾 Monster Parasite: Đi tìm bay thẳng tuyệt đối -> Nhìn từ trên xuống đất -> Tương tác -> Về base bằng Teleguiado

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- 1. CẤU HÌNH TRẠNG THÁI DRAGON NOVA HUB (MẶC ĐỊNH MỚI)
-- =================================================================

local teleguiadoActive = false
local autoSteal = false
local antiStun = false
local autoEggActive = false
local hitboxActive = false
local antiTrapActive = false
local monsterParasiteActive = false

local speedVal = 310
local chunkVal = 20
local baseCFrame = CFrame.new(519.01, 70.27, -362.74)

local currentTween = nil

-- Biến cho logic trạng thái bay mới của Teleguiado (0: thẳng, 1: trái, 2: thẳng ngắn, 3: phải)
local teleguiadoStepState = 0
local stepTimer = 0

local updateTeleguiadoUI = function() end
local updateMonsterUI = function() end

local function setTeleguiado(state)
    if teleguiadoActive == state then
        return
    end

    teleguiadoActive = state

    if not state then
        if currentTween then
            pcall(function()
                currentTween:Cancel()
            end)
            currentTween = nil
        end

        teleguiadoStepState = 0
        stepTimer = 0
    end

    updateTeleguiadoUI()
end

local function setMonsterParasite(state)
    monsterParasiteActive = state
    updateMonsterUI()
end

-- =================================================================
-- 2. PROXIMITY PROMPT
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

    if not parent then
        return nil
    end

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
    if not prompt or not prompt.Enabled then
        return
    end

    bypassPrompt(prompt)

    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
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

        if not autoEggActive and not autoSteal then
            continue
        end

        pcall(function()
            local char = LocalPlayer.Character
            if not char then
                return
            end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                return
            end

            -- =====================================================
            -- AUTO PICK
            -- =====================================================

            if autoEggActive then
                local closestPrompt = nil
                local minDist = 25

                for prompt, _ in pairs(shownPrompts) do
                    if prompt
                        and prompt.Enabled
                        and prompt.Parent
                        and prompt:IsDescendantOf(
                            workspace:FindFirstChild("AreaEggSlotsClient")
                            or workspace
                        )
                    then
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

            -- =====================================================
            -- AUTO STEAL
            -- =====================================================

            if autoSteal then
                for prompt, _ in pairs(shownPrompts) do
                    if prompt
                        and prompt.Enabled
                        and prompt.Parent
                    then
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
    if not char then
        return
    end

    local hum = char:WaitForChild("Humanoid", 5)

    if hum then
        hum:SetStateEnabled(
            Enum.HumanoidStateType.Physics,
            false
        )

        hum:SetStateEnabled(
            Enum.HumanoidStateType.Ragdoll,
            false
        )

        hum:SetStateEnabled(
            Enum.HumanoidStateType.FallingDown,
            false
        )

        hum.StateChanged:Connect(function(_, newState)
            if antiStun and (
                newState == Enum.HumanoidStateType.Physics
                or newState == Enum.HumanoidStateType.Ragdoll
                or newState == Enum.HumanoidStateType.FallingDown
            ) then

                hum:ChangeState(
                    Enum.HumanoidStateType.GettingUp
                )

                local hrp = char:FindFirstChild(
                    "HumanoidRootPart"
                )

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
    if not antiStun then
        return
    end

    pcall(function()
        local char = LocalPlayer.Character

        if not char then
            return
        end

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
-- 4. TELEGUIADO BAY TWEEN VỀ BASE (LOGIC MỚI: Thẳng -> Trái -> Thẳng -> Phải)
-- =================================================================

RunService.RenderStepped:Connect(function(deltaTime)
    if not teleguiadoActive then
        return
    end

    pcall(function()
        local char = LocalPlayer.Character

        if not char then
            return
        end

        local hrp = char:FindFirstChild(
            "HumanoidRootPart"
        )

        if not hrp then
            return
        end

        local targetPos = baseCFrame.Position
        local currentPos = hrp.Position

        local flatTarget = Vector3.new(
            targetPos.X,
            currentPos.Y,
            targetPos.Z
        )

        local mainDir = flatTarget - currentPos
        local distance = mainDir.Magnitude

        if distance <= 6 then
            setTeleguiado(false)
            return
        end

        stepTimer = stepTimer + deltaTime

        -- Quản lý thời gian chuyển đổi các trạng thái:
        -- State 0 (Bay thẳng): 0.5s
        -- State 1 (Bay Z trái): 0.3s
        -- State 2 (Bay thẳng ngắn): 0.1s
        -- State 3 (Bay Z phải): 0.3s
        if teleguiadoStepState == 0 and stepTimer >= 0.5 then
            teleguiadoStepState = 1
            stepTimer = 0
        elseif teleguiadoStepState == 1 and stepTimer >= 0.3 then
            teleguiadoStepState = 2
            stepTimer = 0
        elseif teleguiadoStepState == 2 and stepTimer >= 0.1 then
            teleguiadoStepState = 3
            stepTimer = 0
        elseif teleguiadoStepState == 3 and stepTimer >= 0.3 then
            teleguiadoStepState = 0
            stepTimer = 0
        end

        local unitDir = mainDir.Unit
        local moveDir = unitDir
        local perp = Vector3.new(-unitDir.Z, 0, unitDir.X).Unit
        local offsetMagnitude = chunkVal / 10

        if teleguiadoStepState == 1 then
            -- Lệch trái
            moveDir = (unitDir - perp * offsetMagnitude).Unit
        elseif teleguiadoStepState == 3 then
            -- Lệch phải
            moveDir = (unitDir + perp * offsetMagnitude).Unit
        else
            -- Bay thẳng (State 0 và State 2)
            moveDir = unitDir
        end

        local moveDistance =
            speedVal * deltaTime

        local nextPos =
            currentPos
            + (moveDir * moveDistance)

        if currentTween then
            pcall(function()
                currentTween:Cancel()
            end)
        end

        local tweenInfo = TweenInfo.new(
            deltaTime,
            Enum.EasingStyle.Linear
        )

        currentTween = TweenService:Create(
            hrp,
            tweenInfo,
            {
                CFrame = CFrame.new(
                    nextPos,
                    nextPos + moveDir
                )
            }
        )

        currentTween:Play()
    end)
end)

-- =================================================================
-- 5. MONSTER PARASITE LOGIC (ĐI TÌM BAY THẲNG + NHÌN TỪ TRÊN XUỐNG ĐẤT)
-- =================================================================

task.spawn(function()
    while true do
        task.wait(0.3)

        if not monsterParasiteActive then
            continue
        end

        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local areaSlots = workspace:FindFirstChild("AreaEggSlotsClient")
            if not areaSlots then return end

            local targetVisual = nil
            for _, descendant in ipairs(areaSlots:GetDescendants()) do
                if descendant.Name == "MonsterParasiteVisual" then
                    targetVisual = descendant
                    break
                end
            end

            if not targetVisual then return end

            local targetPos = nil
            local parentObj = targetVisual.Parent

            if parentObj then
                if parentObj:IsA("BasePart") then
                    targetPos = parentObj.Position
                elseif parentObj:IsA("Attachment") then
                    targetPos = parentObj.WorldPosition
                elseif parentObj:IsA("Model") then
                    targetPos = parentObj:GetPivot().Position
                end
            end

            if not targetPos then return end

            local finalTargetPos = targetPos + Vector3.new(0, 3, 0)
            local reachedTarget = false
            local connection
            
            -- Bay đi đến Monster (Bay thẳng tuyệt đối)
            connection = RunService.RenderStepped:Connect(function(deltaTime)
                if not monsterParasiteActive then
                    connection:Disconnect()
                    return
                end

                pcall(function()
                    local currentPos = hrp.Position
                    local mainDir = finalTargetPos - currentPos
                    local distance = mainDir.Magnitude

                    if distance <= 2 then
                        reachedTarget = true
                        connection:Disconnect()
                        return
                    end

                    local moveDir = mainDir.Unit
                    local moveDistance = speedVal * deltaTime
                    local nextPos = currentPos + (moveDir * moveDistance)

                    if currentTween then
                        pcall(function() currentTween:Cancel() end)
                    end

                    local tweenInfo = TweenInfo.new(deltaTime, Enum.EasingStyle.Linear)
                    currentTween = TweenService:Create(hrp, tweenInfo, {
                        CFrame = CFrame.new(nextPos, nextPos + moveDir)
                    })
                    currentTween:Play()
                end)
            end)

            while not reachedTarget and monsterParasiteActive do
                task.wait(0.05)
            end

            if not monsterParasiteActive then
                if connection then connection:Disconnect() end
                return
            end

            -- Đặt góc nhìn từ trên xuống đất (Top-down view)
            pcall(function()
                local camera = workspace.CurrentCamera
                if camera and hrp then
                    camera.CameraType = Enum.CameraType.Scriptable
                    camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 15, 0), hrp.Position)
                end
            end)

            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then
                    local pPos = getPromptPosition(prompt)
                    if pPos and (hrp.Position - pPos).Magnitude <= 15 then
                        prompt.MaxActivationDistance = 1
                        bypassPrompt(prompt)
                    end
                end
            end

            task.wait(0.3)

            for prompt, _ in pairs(shownPrompts) do
                if prompt and prompt.Enabled then
                    local pPos = getPromptPosition(prompt)
                    if pPos and (hrp.Position - pPos).Magnitude <= 15 then
                        triggerPrompt(prompt)
                    end
                end
            end

            -- Trả lại camera về chế độ thông thường của game
            pcall(function()
                local camera = workspace.CurrentCamera
                if camera then
                    camera.CameraType = Enum.CameraType.Custom
                    camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                end
            end)

            -- Sau khi xong, bật Teleguiado để bay về base bằng logic Zig Zag mới
            setTeleguiado(true)

            monsterParasiteActive = false
            updateMonsterUI()
        end)
    end
end)

-- =================================================================
-- 6. HITBOX EXPANDER
-- =================================================================

local function resetHitboxes()
    pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer
                and player.Character
            then
                local hrp = player.Character:FindFirstChild(
                    "HumanoidRootPart"
                )

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
                    if player ~= LocalPlayer
                        and player.Character
                    then
                        local hrp =
                            player.Character:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if hrp then
                            hrp.Size = Vector3.new(
                                15,
                                15,
                                15
                            )

                            hrp.Transparency = 0.7
                            hrp.BrickColor =
                                BrickColor.new("Really red")

                            hrp.Material =
                                Enum.Material.Neon

                            hrp.CanCollide = false
                        end
                    end
                end
            end)
        end
    end
end)

-- =================================================================
-- 7. ANTI TRAP
-- =================================================================

local trapESP = {}

local function createTrapESP(part)
    if not antiTrapActive then
        return
    end

    if not part or not part:IsA("BasePart") then
        return
    end

    if trapESP[part] then
        return
    end

    local highlight = Instance.new("Highlight")

    highlight.Name =
        "DragonNova_TrapESP"

    highlight.Adornee = part

    highlight.DepthMode =
        Enum.HighlightDepthMode.AlwaysOnTop

    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0

    highlight.FillColor =
        Color3.fromRGB(255, 50, 50)

    highlight.OutlineColor =
        Color3.fromRGB(255, 255, 255)

    highlight.Parent = part

    trapESP[part] = highlight
end

local function removeTrapESP()
    for part, highlight in pairs(trapESP) do
        pcall(function()
            if highlight then
                highlight:Destroy()
            end
        end)

        trapESP[part] = nil
    end
end

local function disableTrapPart(part)
    if not part or not part:IsA("BasePart") then
        return
    end

    pcall(function()
        part.CanTouch = false
        part.CanCollide = false
        part.CanQuery = false

        if string.lower(part.Name) == "hitbox" then
            part.Size = Vector3.new(
                0.001,
                0.001,
                0.001
            )
        end

        for _, child in ipairs(part:GetDescendants()) do
            if child:IsA("TouchTransmitter")
                or child.ClassName == "TouchInterest"
            then
                child:Destroy()
            end
        end

        if antiTrapActive then
            createTrapESP(part)
        end
    end)
end

local function scanTraps()
    local debris =
        workspace:FindFirstChild("__DEBRIS")

    if not debris then
        return
    end

    for _, child in ipairs(debris:GetChildren()) do

        for _, descendant in ipairs(
            child:GetDescendants()
        ) do
            if descendant:IsA("BasePart") then
                disableTrapPart(descendant)
            end
        end

        if child:IsA("BasePart") then
            disableTrapPart(child)
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
        task.wait(0.1)

        if antiTrapActive then
            pcall(scanTraps)
        end
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if not antiTrapActive then
        return
    end

    pcall(function()
        local debris =
            workspace:FindFirstChild("__DEBRIS")

        if debris
            and obj:IsDescendantOf(debris)
            and obj:IsA("BasePart")
        then
            disableTrapPart(obj)
        end
    end)
end)

-- =================================================================
-- 8. GIAO DIỆN DRAGON NOVA HUB
-- =================================================================

local function createHubUI()

    local oldGui =
        CoreGui:FindFirstChild("DragonNovaHub")
        or (
            LocalPlayer:FindFirstChild("PlayerGui")
            and LocalPlayer.PlayerGui:FindFirstChild(
                "DragonNovaHub"
            )
        )

    if oldGui then
        oldGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")

    screenGui.Name =
        "DragonNovaHub"

    screenGui.ResetOnSpawn = false

    screenGui.Parent =
        (gethui and gethui())
        or CoreGui
        or LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")

    mainFrame.Name = "MainFrame"
    mainFrame.Parent = screenGui

    mainFrame.Size =
        UDim2.new(0, 240, 0, 300)

    mainFrame.Position =
        UDim2.new(0.05, 0, 0.2, 0)

    mainFrame.BackgroundColor3 =
        Color3.fromRGB(20, 20, 25)

    mainFrame.Active = true
    mainFrame.Draggable = true

    Instance.new("UICorner", mainFrame).CornerRadius =
        UDim.new(0, 10)

    local mainStroke =
        Instance.new("UIStroke", mainFrame)

    mainStroke.Color =
        Color3.fromRGB(0, 200, 255)

    mainStroke.Thickness = 2

    local titleLabel =
        Instance.new("TextLabel")

    titleLabel.Parent = mainFrame

    titleLabel.Size =
        UDim2.new(0.75, 0, 0, 35)

    titleLabel.Position =
        UDim2.new(0.05, 0, 0, 0)

    titleLabel.Text =
        "🐉 DRAGON NOVA HUB"

    titleLabel.Font =
        Enum.Font.SourceSansBold

    titleLabel.TextSize = 15

    titleLabel.TextColor3 =
        Color3.fromRGB(0, 200, 255)

    titleLabel.TextXAlignment =
        Enum.TextXAlignment.Left

    titleLabel.BackgroundTransparency = 1

    local btnMin =
        Instance.new("TextButton")

    btnMin.Parent = mainFrame

    btnMin.Size =
        UDim2.new(0, 28, 0, 28)

    btnMin.Position =
        UDim2.new(0.85, 0, 0.02, 0)

    btnMin.BackgroundColor3 =
        Color3.fromRGB(45, 45, 55)

    btnMin.Text = "[-]"

    btnMin.Font =
        Enum.Font.SourceSansBold

    btnMin.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    btnMin.TextSize = 14

    Instance.new("UICorner", btnMin).CornerRadius =
        UDim.new(0, 6)

    local minIcon =
        Instance.new("TextButton")

    minIcon.Name = "MinIcon"
    minIcon.Parent = screenGui

    minIcon.Size =
        UDim2.new(0, 50, 0, 50)

    minIcon.Position =
        UDim2.new(0.02, 0, 0.45, 0)

    minIcon.BackgroundColor3 =
        Color3.fromRGB(20, 20, 25)

    minIcon.Text = "🐉"

    minIcon.Font =
        Enum.Font.SourceSansBold

    minIcon.TextSize = 24

    minIcon.Visible = false
    minIcon.Active = true
    minIcon.Draggable = true

    Instance.new("UICorner", minIcon).CornerRadius =
        UDim.new(1, 0)

    local iconStroke =
        Instance.new("UIStroke", minIcon)

    iconStroke.Color =
        Color3.fromRGB(0, 200, 255)

    iconStroke.Thickness = 2

    btnMin.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        minIcon.Visible = true
    end)

    minIcon.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        minIcon.Visible = false
    end)

    local function createSlider(
        yPos,
        name,
        minVal,
        maxVal,
        defaultVal,
        callback
    )

        local container =
            Instance.new("Frame")

        container.Parent = mainFrame

        container.Size =
            UDim2.new(0.9, 0, 0, 38)

        container.Position =
            UDim2.new(0.05, 0, 0, yPos)

        container.BackgroundTransparency = 1

        local lbl =
            Instance.new("TextLabel")

        lbl.Parent = container

        lbl.Size =
            UDim2.new(1, 0, 0, 16)

        lbl.Text =
            name .. ": " .. tostring(defaultVal)

        lbl.Font =
            Enum.Font.SourceSansBold

        lbl.TextColor3 =
            Color3.fromRGB(220, 220, 220)

        lbl.TextSize = 12

        lbl.TextXAlignment =
            Enum.TextXAlignment.Left

        lbl.BackgroundTransparency = 1

        local bg =
            Instance.new("Frame")

        bg.Parent = container

        bg.Size =
            UDim2.new(1, 0, 0, 8)

        bg.Position =
            UDim2.new(0, 0, 0, 20)

        bg.BackgroundColor3 =
            Color3.fromRGB(45, 45, 55)

        Instance.new("UICorner", bg).CornerRadius =
            UDim.new(0, 4)

        local fill =
            Instance.new("Frame")

        fill.Parent = bg

        local initPercent =
            math.clamp(
                (defaultVal - minVal)
                / (maxVal - minVal),
                0,
                1
            )

        fill.Size =
            UDim2.new(initPercent, 0, 1, 0)

        fill.BackgroundColor3 =
            Color3.fromRGB(0, 200, 255)

        Instance.new("UICorner", fill).CornerRadius =
            UDim.new(0, 4)

        local dragging = false

        local function update(input)

            local pos =
                math.clamp(
                    (
                        input.Position.X
                        - bg.AbsolutePosition.X
                    )
                    / bg.AbsoluteSize.X,
                    0,
                    1
                )

            fill.Size =
                UDim2.new(pos, 0, 1, 0)

            local val =
                math.floor(
                    minVal
                    + (maxVal - minVal) * pos
                )

            lbl.Text =
                name .. ": " .. tostring(val)

            callback(val)
        end

        bg.InputBegan:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch
            then

                dragging = true
                update(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)

            if dragging
                and (
                    input.UserInputType ==
                    Enum.UserInputType.MouseMovement
                    or input.UserInputType ==
                    Enum.UserInputType.Touch
                )
            then
                update(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)

            if input.UserInputType ==
                Enum.UserInputType.MouseButton1
                or input.UserInputType ==
                Enum.UserInputType.Touch
            then
                dragging = false
            end
        end)
    end

    createSlider(
        35,
        "⚡ Tween Speed",
        10,
        600,
        speedVal,
        function(val)
            speedVal = val
        end
    )

    createSlider(
        75,
        "🌀 Chunk (S+Z)",
        2,
        100,
        chunkVal,
        function(val)
            chunkVal = val
        end
    )

    local function createGridButton(
        xRel,
        yPos,
        wRel,
        text,
        defaultState,
        callback
    )

        local btn =
            Instance.new("TextButton")

        btn.Parent = mainFrame

        btn.Size =
            UDim2.new(wRel, -4, 0, 36)

        btn.Position =
            UDim2.new(xRel, 2, 0, yPos)

        btn.BackgroundColor3 =
            Color3.fromRGB(35, 35, 45)

        btn.Text =
            text
            .. (defaultState and ": ON" or ": OFF")

        btn.Font =
            Enum.Font.SourceSansBold

        btn.TextColor3 =
            defaultState
            and Color3.fromRGB(0, 255, 150)
            or Color3.fromRGB(255, 75, 75)

        btn.TextSize = 12

        Instance.new("UICorner", btn).CornerRadius =
            UDim.new(0, 8)

        local stroke =
            Instance.new("UIStroke", btn)

        stroke.Color =
            defaultState
            and Color3.fromRGB(0, 255, 150)
            or Color3.fromRGB(255, 75, 75)

        stroke.Thickness = 1.5

        btn.MouseButton1Click:Connect(function()

            local newState = callback()

            btn.Text =
                text
                .. (newState and ": ON" or ": OFF")

            btn.TextColor3 =
                newState
                and Color3.fromRGB(0, 255, 150)
                or Color3.fromRGB(255, 75, 75)

            stroke.Color =
                newState
                and Color3.fromRGB(0, 255, 150)
                or Color3.fromRGB(255, 75, 75)
        end)

        return btn
    end

    local btnTele =
        createGridButton(
            0.05,
            120,
            0.45,
            "🚀 Teleguiado",
            teleguiadoActive,
            function()

                setTeleguiado(
                    not teleguiadoActive
                )

                return teleguiadoActive
            end
        )

    updateTeleguiadoUI = function()

        btnTele.Text =
            "🚀 Teleguiado"
            .. (
                teleguiadoActive
                and ": ON"
                or ": OFF"
            )

        btnTele.TextColor3 =
            teleguiadoActive
            and Color3.fromRGB(0, 255, 150)
            or Color3.fromRGB(255, 75, 75)
    end

    createGridButton(
        0.50,
        120,
        0.45,
        "⚡ Auto Steal",
        autoSteal,
        function()

            autoSteal =
                not autoSteal

            return autoSteal
        end
    )

    createGridButton(
        0.05,
        165,
        0.45,
        "🛡️ Anti Stun",
        antiStun,
        function()

            antiStun =
                not antiStun

            return antiStun
        end
    )

    createGridButton(
        0.50,
        165,
        0.45,
        "🥚 Auto Pick",
        autoEggActive,
        function()

            autoEggActive =
                not autoEggActive

            return autoEggActive
        end
    )

    createGridButton(
        0.05,
        210,
        0.45,
        "🎯 Hitbox",
        hitboxActive,
        function()

            hitboxActive =
                not hitboxActive

            if not hitboxActive then
                resetHitboxes()
            end

            return hitboxActive
        end
    )

    createGridButton(
        0.50,
        210,
        0.45,
        "🪤 Anti Trap",
        antiTrapActive,
        function()

            setAntiTrap(
                not antiTrapActive
            )

            return antiTrapActive
        end
    )

    local btnMonster = createGridButton(
        0.05,
        255,
        0.90,
        "👾 Monster Parasite",
        monsterParasiteActive,
        function()
            setMonsterParasite(not monsterParasiteActive)
            return monsterParasiteActive
        end
    )

    updateMonsterUI = function()
        btnMonster.Text = "👾 Monster Parasite" .. (monsterParasiteActive and ": ON" or ": OFF")
        btnMonster.TextColor3 = monsterParasiteActive and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 75, 75)
    end
end

-- =================================================================
-- START
-- =================================================================

createHubUI()
