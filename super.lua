-- Delta X - iOS 26 Liquid Glass UI (Dragon Nova Hub - Layout 2x4 Mini Arena)
local iOS26Glass = {}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- LOGIC TÍNH NĂNG (GAMEPLAY LOGIC)
-- =================================================================
local autoSteal = false
local antiStun = true
local autoZoneActive = false
local hitboxActive = true
local antiTrapActive = true
local godModeActive = false

local speedVal = 600
local chunkVal = 12
local baseCFrame = CFrame.new(519.01, 70.27, -362.74)

-- =================================================================
-- HỆ THỐNG NÚT MINI ARENA (CẤU TRÚC 2 HÀNG X 4 CỘT)
-- =================================================================
local MiniGui = Instance.new("ScreenGui")
MiniGui.Name = "iOS26_MiniArenaGui"
if gethui then
    MiniGui.Parent = gethui()
else
    MiniGui.Parent = CoreGui
end

local ArenaContainer = Instance.new("Frame")
ArenaContainer.Name = "ArenaContainer"
ArenaContainer.Size = UDim2.new(0, 180, 0, 85)
ArenaContainer.AnchorPoint = Vector2.new(1, 0)
ArenaContainer.Position = UDim2.new(1, -20, 0, 10)
ArenaContainer.BackgroundTransparency = 1
ArenaContainer.Parent = MiniGui

local miniButtonsData = {
    -- HÀNG TRÊN (Row = 0)
    { id = "Base",     icon = "🏠",   col = 0, row = 0, xyz = baseCFrame or CFrame.new(519.01, 70.27, -362.74) },
    { id = "Volcano",  icon = "🌋",   col = 1, row = 0, xyz = CFrame.new(1878, 70, -395) },
    { id = "Ocean",    icon = "🌊",   col = 2, row = 0, xyz = CFrame.new(2281, 70, -329) },
    { id = "Dino",     icon = "🦖",   col = 3, row = 0, xyz = CFrame.new(2815, 70, -396) },

    -- HÀNG DƯỚI (Row = 1)
    { id = "AngelDev", icon = "👼😈", col = 0, row = 1, xyz = CFrame.new(5662, 70, -344) },
    { id = "Galaxy",   icon = "🌌",   col = 1, row = 1, xyz = CFrame.new(3393, 70, -327) },
    { id = "Flower",   icon = "🌸",   col = 2, row = 1, xyz = CFrame.new(4030, 70, -398) },
    { id = "Lizard",   icon = "🦎",   col = 3, row = 1, xyz = CFrame.new(4797, 70, -330) }
}

local activeTeleportToken = 0
local buttonStates = {}
local miniStrokes = {}
local miniButtonObjects = {}

local function stopTeleport()
    activeTeleportToken = activeTeleportToken + 1
end

local function startChunkTeleport(targetCF, sourceBtn)
    activeTeleportToken = activeTeleportToken + 1
    local currentToken = activeTeleportToken

    task.spawn(function()
        while activeTeleportToken == currentToken and targetCF do
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local currentPos = hrp.Position
                        local targetPos = targetCF.Position
                        local direction = (targetPos - currentPos)
                        local distance = direction.Magnitude
                        local stepDistance = chunkVal or 12

                        if distance > stepDistance then
                            local moveVector = direction.Unit * stepDistance
                            hrp.CFrame = CFrame.new(currentPos + moveVector)
                        else
                            hrp.CFrame = targetCF
                            activeTeleportToken = 0
                            
                            if sourceBtn and miniStrokes[sourceBtn] then
                                buttonStates[sourceBtn] = false
                                TweenService:Create(miniStrokes[sourceBtn], TweenInfo.new(0.2), {
                                    Color = Color3.fromRGB(255, 255, 255)
                                }):Play()
                            end
                        end
                    end
                end
            end)

            local speed = speedVal or 600
            local delayTime = math.clamp(1 / (speed / 15), 0.001, 0.1)
            task.wait(delayTime)
        end
    end)
end

local function triggerMiniButtonByName(idName)
    local obj = miniButtonObjects[idName]
    if not obj then return end

    for otherBtn, otherStroke in pairs(miniStrokes) do
        buttonStates[otherBtn] = false
        TweenService:Create(otherStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(255, 255, 255)
        }):Play()
    end

    buttonStates[obj.btn] = true

    TweenService:Create(obj.stroke, TweenInfo.new(0.2), {
        Color = Color3.fromRGB(48, 209, 88)
    }):Play()

    startChunkTeleport(obj.data.xyz, obj.btn)
end

for _, data in ipairs(miniButtonsData) do
    local btn = Instance.new("TextButton")
    btn.Name = "MiniBtn_" .. data.id
    btn.Size = UDim2.new(0, 38, 0, 38)
    btn.Position = UDim2.new(0, data.col * 44, 0, data.row * 44)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = data.icon
    btn.TextSize = 12.5
    btn.AutoButtonColor = false
    btn.Visible = true
    btn.Parent = ArenaContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn

    miniStrokes[btn] = stroke
    buttonStates[btn] = false
    miniButtonObjects[data.id] = {
        btn = btn,
        stroke = stroke,
        data = data
    }

    btn.MouseButton1Click:Connect(function()
        local isON = not buttonStates[btn]

        for otherBtn, otherStroke in pairs(miniStrokes) do
            buttonStates[otherBtn] = false

            TweenService:Create(otherStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 255, 255)
            }):Play()
        end

        buttonStates[btn] = isON

        if isON then
            TweenService:Create(stroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(48, 209, 88)
            }):Play()

            startChunkTeleport(data.xyz, btn)
        else
            TweenService:Create(stroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 255, 255)
            }):Play()

            stopTeleport()
        end
    end)
end

-- =================================================================
-- LOGIC AUTO ZONE
-- =================================================================
local autoZoneState = 0
local lastPromptTime = 0

local function monitorCharacterStun(char)
    if not char then return end

    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Physics
        or newState == Enum.HumanoidStateType.Ragdoll
        or newState == Enum.HumanoidStateType.FallingDown
        or newState == Enum.HumanoidStateType.PlatformStanding then

            if autoZoneActive
            and autoZoneState == 0
            and (os.clock() - lastPromptTime <= 3.5) then
                autoZoneState = 1
            end
        end
    end)

    hum:GetPropertyChangedSignal("Sit"):Connect(function()
        if hum.Sit
        and autoZoneActive
        and autoZoneState == 0
        and (os.clock() - lastPromptTime <= 3.5) then
            autoZoneState = 1
        end
    end)
end

if LocalPlayer.Character then
    monitorCharacterStun(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(monitorCharacterStun)

ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
    if playerWhoTriggered == LocalPlayer then
        lastPromptTime = os.clock()

        if autoZoneActive then
            if autoZoneState == 1 then
                autoZoneState = 2

                triggerMiniButtonByName("Base")

                task.spawn(function()
                    task.wait(10)
                    autoZoneState = 0
                end)
            end
        end
    end
end)

-- =================================================================
-- GOD MODE LOGIC CHUẨN (CLONE HUMANOID)
-- =================================================================
local function toggleGodMode(state)
    local character = LocalPlayer.Character
    if not character then return end
    
    if state then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = LocalPlayer.Backpack
            end
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not rootPart then
            return
        end
        
        local currentCFrame = rootPart.CFrame
        
        local newHumanoid = humanoid:Clone()
        newHumanoid.Parent = character

        humanoid:Destroy()
        
        LocalPlayer.Character = nil
        LocalPlayer.Character = character

        workspace.CurrentCamera.CameraSubject = newHumanoid
        
        task.defer(function()
            if rootPart then
                rootPart.CFrame = currentCFrame
            end
        end)
    else
        LocalPlayer:LoadCharacter()
    end
end

-- =================================================================
-- PROXIMITY PROMPT & BYPASS
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

    if fireproximityprompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
    else
        pcall(function()
            prompt:InputHoldBegin()
            task.wait(0.1)
            prompt:InputHoldEnd()
        end)
    end
end

ProximityPromptService.PromptShown:Connect(function(prompt)
    bypassPrompt(prompt, 25)
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
        bypassPrompt(descendant, 25)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)

        if not autoSteal then
            continue
        end

        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            for prompt, _ in pairs(shownPrompts) do
                if prompt
                and prompt:IsDescendantOf(workspace)
                and prompt.Enabled then

                    local pos = getPromptPosition(prompt)

                    if pos then
                        if (hrp.Position - pos).Magnitude <= 25 then
                            triggerPrompt(prompt)
                        end
                    else
                        triggerPrompt(prompt)
                    end
                else
                    shownPrompts[prompt] = nil
                end
            end
        end)
    end
end)

-- =================================================================
-- ANTI STUN & KNOCKBACK
-- =================================================================
local function setupCharacter(char)
    if not char then return end

    local hum = char:WaitForChild("Humanoid", 5)

    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

        hum.StateChanged:Connect(function(_, newState)
            if antiStun
            and (
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
-- HITBOX & ANTI TRAP
-- =================================================================
local trapESP = {}

local function createTrapESP(part)
    if not antiTrapActive
    or not part
    or not part:IsA("BasePart")
    or trapESP[part] then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "DragonNova_TrapESP"
    highlight.Adornee = part
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.FillColor = Color3.fromRGB(255, 60, 60)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
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
            part.Size = Vector3.new(0.001, 0.001, 0.001)
        end

        for _, child in ipairs(part:GetDescendants()) do
            if child:IsA("TouchTransmitter")
            or child.ClassName == "TouchInterest" then
                child:Destroy()
            end
        end

        if antiTrapActive then
            createTrapESP(part)
        end
    end)
end

local function scanTraps()
    local debris = workspace:FindFirstChild("__DEBRIS")
    if not debris then return end

    for _, child in ipairs(debris:GetChildren()) do
        for _, desc in ipairs(child:GetDescendants()) do
            if desc:IsA("BasePart") then
                disableTrapPart(desc)
            end
        end

        if child:IsA("BasePart") then
            disableTrapPart(child)
        end
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
                            hrp.Transparency = 0.75
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
-- iOS 26 LIQUID GLASS UI ENGINE
-- =================================================================
local function enableDragging(topbar, frame)
    local dragging, dragInput, dragStart, startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function iOS26Glass:CreateWindow(titleText)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "iOS26_LiquidGlass_WindUI"

    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end

    local originalSize = UDim2.new(0, 522, 0, 324)
    local openPosition = UDim2.new(0.5, -261, 0.5, -162)

    local islandSize = UDim2.new(0, 160, 0, 34)
    local islandPosition = UDim2.new(0.5, -80, 0, 15)

    local isMinimized = false
    local isAnimating = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = originalSize
    MainFrame.Position = openPosition
    MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainFrame.BackgroundTransparency = 0.78
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 22)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1.2
    MainStroke.Color = Color3.fromRGB(255, 255, 255)
    MainStroke.Transparency = 0.6
    MainStroke.Parent = MainFrame

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Rotation = 45
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 245, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })

    MainGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.5, 0.75),
        NumberSequenceKeypoint.new(1, 0.8)
    })

    MainGradient.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText or "Liquid Glass Menu"
    Title.TextColor3 = Color3.fromRGB(15, 15, 20)
    Title.TextSize = 13.5
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local IslandLabel = Instance.new("TextLabel")
    IslandLabel.Name = "IslandLabel"
    IslandLabel.Size = UDim2.new(1, 0, 1, 0)
    IslandLabel.BackgroundTransparency = 1
    IslandLabel.Text = titleText or "Liquid Glass"
    IslandLabel.TextColor3 = Color3.fromRGB(15, 15, 20)
    IslandLabel.Font = Enum.Font.GothamBold
    IslandLabel.TextSize = 12
    IslandLabel.Visible = false
    IslandLabel.Parent = MainFrame

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 22, 0, 22)
    MinimizeBtn.Position = UDim2.new(1, -30, 0.5, -11)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.BackgroundTransparency = 0.75
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Color3.fromRGB(20, 20, 25)
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.TextSize = 14
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.Parent = TopBar

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(1, 0)
    MinCorner.Parent = MinimizeBtn

    enableDragging(TopBar, MainFrame)
    enableDragging(MainFrame, MainFrame)

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 130, 1, -46)
    Sidebar.Position = UDim2.new(0, 10, 0, 36)
    Sidebar.BackgroundTransparency = 0.80
    Sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Sidebar.ClipsDescendants = true
    Sidebar.Parent = MainFrame

    local SideCorner = Instance.new("UICorner")
    SideCorner.CornerRadius = UDim.new(0, 16)
    SideCorner.Parent = Sidebar

    local SideStroke = Instance.new("UIStroke")
    SideStroke.Thickness = 1
    SideStroke.Color = Color3.fromRGB(255, 255, 255)
    SideStroke.Transparency = 0.65
    SideStroke.Parent = Sidebar

    local TabHolder = Instance.new("ScrollingFrame")
    TabHolder.Name = "TabHolder"
    TabHolder.Size = UDim2.new(1, 0, 1, -100)
    TabHolder.Position = UDim2.new(0, 0, 0, 0)
    TabHolder.BackgroundTransparency = 1
    TabHolder.BorderSizePixel = 0
    TabHolder.ScrollBarThickness = 0
    TabHolder.Parent = Sidebar

    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding = UDim.new(0, 5)
    TabList.Parent = TabHolder

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop = UDim.new(0, 6)
    TabPadding.PaddingLeft = UDim.new(0, 5)
    TabPadding.PaddingRight = UDim.new(0, 5)
    TabPadding.Parent = TabHolder

    local PlayerContainer = Instance.new("Frame")
    PlayerContainer.Name = "PlayerAvatarContainer"
    PlayerContainer.Size = UDim2.new(1, 0, 0, 96)
    PlayerContainer.Position = UDim2.new(0, 0, 1, -96)
    PlayerContainer.BackgroundTransparency = 1
    PlayerContainer.Parent = Sidebar

    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Name = "AvatarImage"
    AvatarImage.Size = UDim2.new(0, 48, 0, 48)
    AvatarImage.Position = UDim2.new(0.5, -24, 0, 4)
    AvatarImage.BackgroundTransparency = 1
    AvatarImage.Parent = PlayerContainer

    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = AvatarImage

    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Thickness = 1
    AvatarStroke.Color = Color3.fromRGB(255, 255, 255)
    AvatarStroke.Transparency = 0.65
    AvatarStroke.Parent = AvatarImage

    task.spawn(function()
        local content, isLoaded = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )

        if isLoaded and content then
            AvatarImage.Image = content
        end
    end)

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -8, 0, 14)
    NameLabel.Position = UDim2.new(0, 4, 1, -28)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = LocalPlayer.DisplayName
    NameLabel.TextColor3 = Color3.fromRGB(25, 25, 30)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 10.5
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = PlayerContainer

    local UserLabel = Instance.new("TextLabel")
    UserLabel.Size = UDim2.new(1, -8, 0, 12)
    UserLabel.Position = UDim2.new(0, 4, 1, -13)
    UserLabel.BackgroundTransparency = 1
    UserLabel.Text = "@" .. LocalPlayer.Name
    UserLabel.TextColor3 = Color3.fromRGB(110, 115, 125)
    UserLabel.Font = Enum.Font.Gotham
    UserLabel.TextSize = 9
    UserLabel.TextTruncate = Enum.TextTruncate.AtEnd
    UserLabel.Parent = PlayerContainer

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -152, 1, -44)
    ContentContainer.Position = UDim2.new(0, 144, 0, 36)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local function minimizeMenu()
        if isAnimating or isMinimized then
            return
        end

        isAnimating = true

        Sidebar.Visible = false
        ContentContainer.Visible = false
        TopBar.Visible = false

        local dotTween = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0.5, -9, 0, 15)
            }
        )

        TweenService:Create(MainCorner, TweenInfo.new(0.25), {
            CornerRadius = UDim.new(1, 0)
        }):Play()

        dotTween:Play()
        dotTween.Completed:Wait()

        local expandIsland = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Size = islandSize,
                Position = islandPosition
            }
        )

        expandIsland:Play()
        expandIsland.Completed:Wait()

        IslandLabel.Visible = true
        isMinimized = true
        isAnimating = false
    end

    local function expandMenu()
        if isAnimating or not isMinimized then
            return
        end

        isAnimating = true
        IslandLabel.Visible = false

        local swellTween = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = UDim2.new(0, 176, 0, 44),
                Position = UDim2.new(0.5, -88, 0, 15)
            }
        )

        swellTween:Play()
        swellTween.Completed:Wait()

        local menuTween = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {
                Size = originalSize,
                Position = openPosition
            }
        )

        TweenService:Create(MainCorner, TweenInfo.new(0.35), {
            CornerRadius = UDim.new(0, 22)
        }):Play()

        menuTween:Play()
        menuTween.Completed:Wait()

        Sidebar.Visible = true
        ContentContainer.Visible = true
        TopBar.Visible = true

        isMinimized = false
        isAnimating = false
    end

    MinimizeBtn.MouseButton1Click:Connect(minimizeMenu)

    MainFrame.InputBegan:Connect(function(input)
        if isMinimized
        and not isAnimating
        and (
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            expandMenu()
        end
    end)

    local Window = {
        ActiveTab = nil
    }

    function Window:AddTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 30)
        TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabButton.BackgroundTransparency = 0.85
        TabButton.Text = tabName
        TabButton.TextColor3 = Color3.fromRGB(40, 40, 45)
        TabButton.Font = Enum.Font.GothamMedium
        TabButton.TextSize = 11.5
        TabButton.Parent = TabHolder

        local TabBtnCorner = Instance.new("UICorner")
        TabBtnCorner.CornerRadius = UDim.new(0, 9)
        TabBtnCorner.Parent = TabButton

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = tabName .. "_Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 2
        TabContent.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 190)
        TabContent.Visible = false
        TabContent.Parent = ContentContainer

        local ContentList = Instance.new("UIListLayout")
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Padding = UDim.new(0, 7)
        ContentList.Parent = TabContent

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingRight = UDim.new(0, 5)
        ContentPadding.Parent = TabContent

        local function activate()
            for _, child in pairs(ContentContainer:GetChildren()) do
                if child:IsA("ScrollingFrame") then
                    child.Visible = false
                end
            end

            for _, btn in pairs(TabHolder:GetChildren()) do
                if btn:IsA("TextButton") then
                    TweenService:Create(btn, TweenInfo.new(0.2), {
                        BackgroundTransparency = 0.85,
                        TextColor3 = Color3.fromRGB(40, 40, 45)
                    }):Play()
                end
            end

            TabContent.Visible = true

            TweenService:Create(TabButton, TweenInfo.new(0.2), {
                BackgroundTransparency = 0.45,
                TextColor3 = Color3.fromRGB(0, 0, 0)
            }):Play()
        end

        TabButton.MouseButton1Click:Connect(activate)

        if not Window.ActiveTab then
            activate()
            Window.ActiveTab = TabContent
        end

        local Tab = {}

        function Tab:AddButton(text, callback)
            local BtnFrame = Instance.new("TextButton")
            BtnFrame.Size = UDim2.new(1, 0, 0, 35)
            BtnFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            BtnFrame.BackgroundTransparency = 0.78
            BtnFrame.Text = text
            BtnFrame.TextColor3 = Color3.fromRGB(20, 20, 25)
            BtnFrame.Font = Enum.Font.GothamMedium
            BtnFrame.TextSize = 11.5
            BtnFrame.AutoButtonColor = false
            BtnFrame.Parent = TabContent

            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 10)
            Corner.Parent = BtnFrame

            local Stroke = Instance.new("UIStroke")
            Stroke.Thickness = 1.5
            Stroke.Color = Color3.fromRGB(255, 255, 255)
            Stroke.Transparency = 0.6
            Stroke.Parent = BtnFrame

            BtnFrame.MouseButton1Click:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.08), {
                    BackgroundTransparency = 0.4
                }):Play()

                task.wait(0.08)

                TweenService:Create(BtnFrame, TweenInfo.new(0.12), {
                    BackgroundTransparency = 0.78
                }):Play()

                if callback then
                    callback()
                end
            end)
        end

        function Tab:AddToggle(text, defaultState, callback)
            local toggled = defaultState or false

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleFrame.BackgroundTransparency = 0.78
            ToggleFrame.Parent = TabContent

            local TCorner = Instance.new("UICorner")
            TCorner.CornerRadius = UDim.new(0, 10)
            TCorner.Parent = ToggleFrame

            local TStroke = Instance.new("UIStroke")
            TStroke.Thickness = 1.5
            TStroke.Color = Color3.fromRGB(255, 255, 255)
            TStroke.Transparency = 0.5
            TStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            TStroke.Parent = ToggleFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -65, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(20, 20, 25)
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 11.5
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame

            local SwitchTrack = Instance.new("Frame")
            SwitchTrack.Size = UDim2.new(0, 44, 0, 24)
            SwitchTrack.AnchorPoint = Vector2.new(1, 0.5)
            SwitchTrack.Position = UDim2.new(1, -8, 0.5, 0)
            SwitchTrack.BackgroundColor3 = toggled
                and Color3.fromRGB(48, 209, 88)
                or Color3.fromRGB(220, 220, 225)
            SwitchTrack.BackgroundTransparency = toggled and 0.25 or 0.6
            SwitchTrack.Parent = ToggleFrame

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = SwitchTrack

            local Knob = Instance.new("Frame")
            Knob.AnchorPoint = Vector2.new(0.5, 0.5)
            Knob.Size = UDim2.new(0, 18, 0, 18)
            Knob.Position = toggled
                and UDim2.new(1, -11, 0.5, 0)
                or UDim2.new(0, 11, 0.5, 0)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BackgroundTransparency = 0.15
            Knob.Parent = SwitchTrack

            local KnobCorner = Instance.new("UICorner")
            KnobCorner.CornerRadius = UDim.new(1, 0)
            KnobCorner.Parent = Knob

            local ClickArea = Instance.new("TextButton")
            ClickArea.Size = UDim2.new(1, 0, 1, 0)
            ClickArea.BackgroundTransparency = 1
            ClickArea.Text = ""
            ClickArea.Parent = ToggleFrame

            ClickArea.MouseButton1Click:Connect(function()
                toggled = not toggled

                local targetPos = toggled
                    and UDim2.new(1, -11, 0.5, 0)
                    or UDim2.new(0, 11, 0.5, 0)

                local targetBg = toggled
                    and Color3.fromRGB(48, 209, 88)
                    or Color3.fromRGB(220, 220, 225)

                local targetTrans = toggled and 0.25 or 0.6

                TweenService:Create(
                    Knob,
                    TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Size = UDim2.new(0, 24, 0, 14),
                        Position = targetPos
                    }
                ):Play()

                TweenService:Create(
                    SwitchTrack,
                    TweenInfo.new(0.25),
                    {
                        BackgroundColor3 = targetBg,
                        BackgroundTransparency = targetTrans
                    }
                ):Play()

                task.wait(0.12)

                TweenService:Create(
                    Knob,
                    TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {
                        Size = UDim2.new(0, 18, 0, 18)
                    }
                ):Play()

                if callback then
                    callback(toggled)
                end
            end)
        end

        function Tab:AddSlider(text, min, max, default, callback)
            local value = default or min
            local dragging = false

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 48)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderFrame.BackgroundTransparency = 0.78
            SliderFrame.Parent = TabContent

            local SCorner = Instance.new("UICorner")
            SCorner.CornerRadius = UDim.new(0, 10)
            SCorner.Parent = SliderFrame

            local SStroke = Instance.new("UIStroke")
            SStroke.Thickness = 1
            SStroke.Color = Color3.fromRGB(255, 255, 255)
            SStroke.Transparency = 0.6
            SStroke.Parent = SliderFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 0, 16)
            Label.Position = UDim2.new(0, 10, 0, 5)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Color3.fromRGB(20, 20, 25)
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 11.5
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 40, 0, 16)
            ValLabel.Position = UDim2.new(1, -50, 0, 5)
            ValLabel.BackgroundTransparency = 1
            ValLabel.Text = tostring(value)
            ValLabel.TextColor3 = Color3.fromRGB(80, 80, 90)
            ValLabel.Font = Enum.Font.GothamBold
            ValLabel.TextSize = 11.5
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = SliderFrame

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -20, 0, 7)
            Track.Position = UDim2.new(0, 10, 1, -14)
            Track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Track.BackgroundTransparency = 0.65
            Track.Parent = SliderFrame

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(
                (value - min) / (max - min),
                0,
                1,
                0
            )
            Fill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
            Fill.BackgroundTransparency = 0.25
            Fill.Parent = Track

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local Thumb = Instance.new("Frame")
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.Size = UDim2.new(0, 14, 0, 14)
            Thumb.Position = UDim2.new(
                (value - min) / (max - min),
                0,
                0.5,
                0
            )
            Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Thumb.BackgroundTransparency = 0.15
            Thumb.Parent = Track

            local ThumbCorner = Instance.new("UICorner")
            ThumbCorner.CornerRadius = UDim.new(1, 0)
            ThumbCorner.Parent = Thumb

            local function update(input)
                local relativeX = math.clamp(
                    (input.Position.X - Track.AbsolutePosition.X)
                    / Track.AbsoluteSize.X,
                    0,
                    1
                )

                local newValue = math.floor(
                    min + (max - min) * relativeX
                )

                value = newValue
                ValLabel.Text = tostring(value)
                Fill.Size = UDim2.new(relativeX, 0, 1, 0)
                Thumb.Position = UDim2.new(relativeX, 0, 0.5, 0)

                if callback then
                    callback(value)
                end
            end

            SliderFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                    dragging = true

                    TweenService:Create(
                        Thumb,
                        TweenInfo.new(
                            0.2,
                            Enum.EasingStyle.Back,
                            Enum.EasingDirection.Out
                        ),
                        {
                            Size = UDim2.new(0, 26, 0, 18),
                            BackgroundTransparency = 0.05
                        }
                    ):Play()

                    TweenService:Create(
                        Track,
                        TweenInfo.new(0.2),
                        {
                            Size = UDim2.new(1, -20, 0, 9)
                        }
                    ):Play()

                    update(input)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging
                and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    update(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then

                    dragging = false

                    TweenService:Create(
                        Thumb,
                        TweenInfo.new(
                            0.25,
                            Enum.EasingStyle.Back,
                            Enum.EasingDirection.Out
                        ),
                        {
                            Size = UDim2.new(0, 14, 0, 14),
                            BackgroundTransparency = 0.15
                        }
                    ):Play()

                    TweenService:Create(
                        Track,
                        TweenInfo.new(0.25),
                        {
                            Size = UDim2.new(1, -20, 0, 7)
                        }
                    ):Play()
                end
            end)
        end

        return Tab
    end

    return Window
end

-- =================================================================
-- THIẾT LẬP MENU MAIN & TABS
-- =================================================================
local Library = iOS26Glass:CreateWindow("Dragon Nova Hub")

local MainTab   = Library:AddTab("Main")
local ArenaTab  = Library:AddTab("Arena")
local BypassTab = Library:AddTab("Bypass")
local MiscTab   = Library:AddTab("Misc")

-- =================================================================
-- TAB MAIN
-- =================================================================
MainTab:AddToggle("Auto Steal", autoSteal, function(val)
    autoSteal = val
end)

MainTab:AddToggle("Auto Zone", autoZoneActive, function(val)
    autoZoneActive = val

    if not val then
        autoZoneState = 0
    end
end)

MainTab:AddSlider("Speed", 10, 1000, speedVal, function(val)
    speedVal = val
end)

MainTab:AddSlider("Chunk", 1, 100, chunkVal, function(val)
    chunkVal = val
end)

-- =================================================================
-- TAB ARENA
-- =================================================================
ArenaTab:AddToggle("Hiện cụm nút Arena", true, function(state)
    ArenaContainer.Visible = state
end)

for _, data in ipairs(miniButtonsData) do
    ArenaTab:AddToggle(
        data.icon .. " " .. data.id,
        true,
        function(state)
            local obj = miniButtonObjects[data.id]

            if obj and obj.btn then
                obj.btn.Visible = state

                if not state and buttonStates[obj.btn] then
                    buttonStates[obj.btn] = false
                    stopTeleport()

                    TweenService:Create(
                        obj.stroke,
                        TweenInfo.new(0.2),
                        {
                            Color = Color3.fromRGB(255, 255, 255)
                        }
                    ):Play()
                end
            end
        end
    )
end

-- =================================================================
-- TAB BYPASS
-- =================================================================
BypassTab:AddToggle("God Mode", false, function(val)
    godModeActive = val
    toggleGodMode(val)
end)

BypassTab:AddToggle("Anti Trap", antiTrapActive, function(val)
    antiTrapActive = val

    if not antiTrapActive then
        removeTrapESP()
    end
end)

BypassTab:AddToggle("Hitbox (15x15)", hitboxActive, function(val)
    hitboxActive = val

    if not hitboxActive then
        pcall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")

                    if hrp then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 1
                        hrp.CanCollide = false
                    end
                end
            end
        end)
    end
end)

BypassTab:AddToggle("Anti Stun", antiStun, function(val)
    antiStun = val
end)

-- =================================================================
-- TAB MISC
-- =================================================================

-- GHI CHÚ
MiscTab:AddButton(
    "Fix lag/boost Fps sẽ xoá những hiệu ứng không cần thiết\nXoá Map sẽ ẩn toàn bộ map GPU giảm tải",
    function()
        -- Chỉ là ghi chú, không thực hiện hành động
    end
)

-- =================================================================
-- FIX LAG / BOOST FPS
-- =================================================================
MiscTab:AddButton("Fix Lag / Boost FPS", function()
    pcall(function()
        local Workspace = game:GetService("Workspace")
        local Lighting = game:GetService("Lighting")

        local function optimize(obj)
            pcall(function()
                if obj:IsA("ParticleEmitter")
                or obj:IsA("Trail")
                or obj:IsA("Beam")
                or obj:IsA("Smoke")
                or obj:IsA("Fire")
                or obj:IsA("Sparkles") then

                    obj.Enabled = false

                elseif obj:IsA("Explosion") then
                    obj.BlastPressure = 0
                    obj.BlastRadius = 0

                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0

                elseif obj:IsA("Texture")
                or obj:IsA("Decal") then

                    obj.Texture = ""

                elseif obj:IsA("MeshPart") then
                    obj.TextureID = ""

                elseif obj:IsA("SpecialMesh") then
                    obj.TextureId = ""

                elseif obj:IsA("SurfaceAppearance") then
                    obj:Destroy()
                end
            end)
        end

        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.Brightness = 1
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0

            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("BloomEffect")
                or effect:IsA("ColorCorrectionEffect")
                or effect:IsA("SunRaysEffect")
                or effect:IsA("DepthOfFieldEffect")
                or effect:IsA("BlurEffect") then

                    effect.Enabled = false
                end
            end
        end)

        pcall(function()
            local Terrain = Workspace.Terrain

            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end)

        for _, obj in ipairs(game:GetDescendants()) do
            optimize(obj)
        end

        if not getgenv().FTGS_FixLagConnection then
            getgenv().FTGS_FixLagConnection =
                game.DescendantAdded:Connect(function(obj)
                    task.defer(function()
                        optimize(obj)
                    end)
                end)
        end

        pcall(function()
            settings().Rendering.QualityLevel =
                Enum.QualityLevel.Level01
        end)
    end)
end)

-- =================================================================
-- HIDE MAP
-- Không xoá Build, chỉ ẩn LOCAL
-- ON  = ẩn workspace.__OBJECTS.Build
-- OFF = hiện lại
-- =================================================================
local mapHidden = false

local function setBuildHidden(state)
    pcall(function()
        local objects = workspace:FindFirstChild("__OBJECTS")
        if not objects then
            return
        end

        local build = objects:FindFirstChild("Build")
        if not build then
            return
        end

        -- Nếu chính Build là BasePart
        if build:IsA("BasePart") then
            build.LocalTransparencyModifier = state and 1 or 0
        end

        -- Các Part/Texture/Decal bên trong Build
        for _, obj in ipairs(build:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") then
                    -- Không Destroy, chỉ ẩn phía client
                    obj.LocalTransparencyModifier =
                        state and 1 or 0

                elseif obj:IsA("Decal")
                or obj:IsA("Texture") then

                    obj.Transparency =
                        state and 1 or 0
                end
            end)
        end

        mapHidden = state
    end)
end

MiscTab:AddToggle("Hide Map", false, function(state)
    mapHidden = state
    setBuildHidden(state)
end)

-- =================================================================
-- SERVER HOP
-- =================================================================
MiscTab:AddButton("Server NhiiiX-HopSV", function()
    pcall(function()
        loadstring(
            game:HttpGet(
                "https://raw.githubusercontent.com/Nhoiii/NhoiiiX-Hub-Dev/refs/heads/main/NhoiiiHopSv.lua"
            )
        )()
    end)
end)
