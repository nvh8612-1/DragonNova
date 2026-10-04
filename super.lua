-- Delta X - iOS 26 Liquid Glass UI (Dragon Nova Hub) + VIP + BodyPosition Fly

local iOS26Glass = {}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- =================================================================
-- LOGIC TÍNH NĂNG
-- =================================================================
local autoSteal = false
local antiStun = true
local autoZoneActive = false
local hitboxActive = true
local antiTrapActive = true
local godModeActive = false
local autoBatActive = false

local tpWalkActive = false
local tpWalkSpeed = 16

local moveMode = "Teleport"
local speedVal = 600
local chunkVal = 12
local baseCFrame = CFrame.new(519.01, 70.27, -362.74)

local bypassGuardActive = false
local flyActive = false
local flyFolder = nil
local flyPlatform = nil
local flyThread = nil
local flyCurrentY = 67
local FLY_START_Y = 67
local FLY_END_Y = 90
local FLY_FOLDER_NAME = "Fly"
local JAIL_HOLD_TIME = 0.2
local jailTpRunning = false

local flyBodyPos = nil
local flyRiseThread = nil
local flyFastRise = false
local CAM_LOCK_TIME = 0.3

-- LOOP TPWALK
RunService.Heartbeat:Connect(function(deltaTime)
    if tpWalkActive then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.MoveDirection.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (hum.MoveDirection * (tpWalkSpeed / 10) * deltaTime * 60)
                end
            end
        end)
    end
end)

-- =================================================================
-- MINI ARENA
-- =================================================================
local MiniGui = Instance.new("ScreenGui")
MiniGui.Name = "iOS26_MiniArenaGui"
if gethui then MiniGui.Parent = gethui() else MiniGui.Parent = CoreGui end

local ArenaContainer = Instance.new("Frame")
ArenaContainer.Size = UDim2.new(0, 180, 0, 85)
ArenaContainer.AnchorPoint = Vector2.new(1, 0)
ArenaContainer.Position = UDim2.new(1, -20, 0.01, 0)
ArenaContainer.BackgroundTransparency = 1
ArenaContainer.Visible = false
ArenaContainer.Parent = MiniGui

local miniButtonsData = {
    { id = "Base",     icon = "🏠",   col = 0, row = 0, xyz = baseCFrame },
    { id = "Volcano",  icon = "🌋",   col = 1, row = 0, xyz = CFrame.new(1878, 70, -395) },
    { id = "Ocean",    icon = "🌊",   col = 2, row = 0, xyz = CFrame.new(2281, 70, -329) },
    { id = "Dino",     icon = "🦖",   col = 3, row = 0, xyz = CFrame.new(2815, 70, -396) },
    { id = "AngelDev", icon = "👼😈", col = 0, row = 1, xyz = CFrame.new(5662, 70, -344) },
    { id = "Galaxy",   icon = "🌌",   col = 1, row = 1, xyz = CFrame.new(3393, 70, -327) },
    { id = "Flower",   icon = "🌸",   col = 2, row = 1, xyz = CFrame.new(4030, 70, -398) },
    { id = "Lizard",   icon = "🦎",   col = 3, row = 1, xyz = CFrame.new(4797, 70, -330) }
}

local activeTeleportToken = 0
local activeTween = nil
local buttonStates = {}
local miniStrokes = {}
local miniButtonObjects = {}

local function stopTeleport()
    activeTeleportToken = activeTeleportToken + 1
    if activeTween then activeTween:Cancel() activeTween = nil end
end

local function startMovement(targetCF, sourceBtn)
    stopTeleport()
    local currentToken = activeTeleportToken
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetCF then return end
    local distance = (targetCF.Position - hrp.Position).Magnitude

    if moveMode == "Teleport" then
        task.spawn(function()
            while activeTeleportToken == currentToken and targetCF do
                pcall(function()
                    local cChar = LocalPlayer.Character
                    if cChar then
                        local cHrp = cChar:FindFirstChild("HumanoidRootPart")
                        if cHrp then
                            local dir = targetCF.Position - cHrp.Position
                            local dist = dir.Magnitude
                            local stepDist = chunkVal or 12
                            if dist > stepDist then
                                cHrp.CFrame = CFrame.new(cHrp.Position + dir.Unit * stepDist)
                            else
                                cHrp.CFrame = targetCF
                                activeTeleportToken = 0
                                if sourceBtn and miniStrokes[sourceBtn] then
                                    buttonStates[sourceBtn] = false
                                    TweenService:Create(miniStrokes[sourceBtn], TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 255, 255) }):Play()
                                end
                            end
                        end
                    end
                end)
                local delayTime = math.clamp(1 / ((speedVal or 600) / 15), 0.001, 0.1)
                task.wait(delayTime)
            end
        end)
    elseif moveMode == "Tween" then
        local flySpeed = math.max(speedVal, 10)
        activeTween = TweenService:Create(hrp, TweenInfo.new(distance / flySpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = targetCF})
        activeTween:Play()
        activeTween.Completed:Connect(function()
            if sourceBtn and miniStrokes[sourceBtn] then
                buttonStates[sourceBtn] = false
                TweenService:Create(miniStrokes[sourceBtn], TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 255, 255) }):Play()
            end
            activeTween = nil
        end)
    end
end

local function triggerMiniButtonByName(idName)
    local obj = miniButtonObjects[idName]
    if not obj then return end
    for otherBtn, otherStroke in pairs(miniStrokes) do
        buttonStates[otherBtn] = false
        TweenService:Create(otherStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 255, 255) }):Play()
    end
    buttonStates[obj.btn] = true
    TweenService:Create(obj.stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(48, 209, 88) }):Play()
    startMovement(obj.data.xyz, obj.btn)
end

for _, data in ipairs(miniButtonsData) do
    local btn = Instance.new("TextButton")
    btn.Name = "MiniBtn" .. data.id
    btn.Size = UDim2.new(0, 38, 0, 38)
    btn.Position = UDim2.new(0, data.col * 44, 0, data.row * 44)
    btn.BackgroundTransparency = 1
    btn.Text = data.icon
    btn.TextSize = 12.5
    btn.AutoButtonColor = false
    btn.Visible = false
    btn.Parent = ArenaContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.3
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = btn

    miniStrokes[btn] = stroke
    buttonStates[btn] = false
    miniButtonObjects[data.id] = { btn = btn, stroke = stroke, data = data }

    btn.MouseButton1Click:Connect(function()
        local isON = not buttonStates[btn]
        for otherBtn, otherStroke in pairs(miniStrokes) do
            buttonStates[otherBtn] = false
            TweenService:Create(otherStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 255, 255) }):Play()
        end
        buttonStates[btn] = isON
        if isON then
            TweenService:Create(stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(48, 209, 88) }):Play()
            startMovement(data.xyz, btn)
        else
            TweenService:Create(stroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(255, 255, 255) }):Play()
            stopTeleport()
        end
    end)
end

-- =================================================================
-- FIND REMOTE
-- =================================================================
local function findRemote(keyword, class)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA(class) and obj.Name:find(keyword, 1, true) then
            return obj
        end
    end
    return nil
end

local EggCarryRE = findRemote("FieldEggCarry", "RemoteEvent")

-- =================================================================
-- TELEPORT BASE + LOCK CAMERA
-- =================================================================
local function teleportToBase()
    if jailTpRunning then return end
    jailTpRunning = true

    local char = LocalPlayer.Character
    if not char then jailTpRunning = false return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then jailTpRunning = false return end
    local cam = workspace.CurrentCamera
    if not cam then jailTpRunning = false return end

    local savedCFrame = cam.CFrame
    local savedType = cam.CameraType
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = savedCFrame

    local lockConn = RunService.RenderStepped:Connect(function()
        if cam then cam.CFrame = savedCFrame end
    end)

    hrp.CFrame = baseCFrame
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero

    task.wait(CAM_LOCK_TIME)

    local holdStart = os.clock()
    while os.clock() - holdStart < JAIL_HOLD_TIME do
        RunService.Heartbeat:Wait()
        local c = LocalPlayer.Character
        if c then
            local h = c:FindFirstChild("HumanoidRootPart")
            if h then
                h.CFrame = baseCFrame
                h.AssemblyLinearVelocity = Vector3.zero
                h.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    if lockConn then lockConn:Disconnect() end
    if cam then cam.CameraType = savedType end
    print("[BypassGuard] TP base + lock cam xong")
    jailTpRunning = false
end

-- =================================================================
-- FLY (BodyPosition Y-only)
-- =================================================================
local function createFlyFolder()
    if flyFolder and flyFolder.Parent then flyFolder:Destroy() end
    flyFolder = Instance.new("Folder")
    flyFolder.Name = FLY_FOLDER_NAME
    flyFolder.Parent = workspace
    return flyFolder
end

local function detachCharFromPlatform()
    if flyBodyPos then flyBodyPos:Destroy() flyBodyPos = nil end
    if flyRiseThread then task.cancel(flyRiseThread) flyRiseThread = nil end
end

local function attachCharToPlatform()
    if flyBodyPos and flyBodyPos.Parent then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    flyBodyPos = Instance.new("BodyPosition")
    flyBodyPos.MaxForce = Vector3.new(0, 500000, 0)
    flyBodyPos.P = 8000
    flyBodyPos.D = 600
    flyBodyPos.Position = Vector3.new(hrp.Position.X, flyCurrentY + 3, hrp.Position.Z)
    flyBodyPos.Parent = hrp

    task.spawn(function()
        while flyBodyPos and flyBodyPos.Parent do
            RunService.Heartbeat:Wait()
            local c = LocalPlayer.Character
            if not c then break end
            local h = c:FindFirstChild("HumanoidRootPart")
            if not h then break end
            flyBodyPos.Position = Vector3.new(h.Position.X, flyCurrentY + 3, h.Position.Z)
        end
    end)
end

local function cleanupFly()
    detachCharFromPlatform()
    if flyThread then task.cancel(flyThread) flyThread = nil end
    if flyPlatform then flyPlatform:Destroy() flyPlatform = nil end
    if flyFolder then flyFolder:Destroy() flyFolder = nil end
    flyCurrentY = FLY_START_Y
    flyFastRise = false
end

local function startFlyPlatform()
    if flyPlatform and flyPlatform.Parent then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    createFlyFolder()
    flyCurrentY = FLY_START_Y

    flyPlatform = Instance.new("Part")
    flyPlatform.Name = "FlyPlatform"
    flyPlatform.Size = Vector3.new(30, 1, 30)
    flyPlatform.Position = Vector3.new(hrp.Position.X, FLY_START_Y, hrp.Position.Z)
    flyPlatform.Anchored = true
    flyPlatform.CanCollide = true
    flyPlatform.Transparency = 0.3
    flyPlatform.Color = Color3.fromRGB(0, 150, 255)
    flyPlatform.Material = Enum.Material.Neon
    flyPlatform.Parent = flyFolder

    attachCharToPlatform()

    flyThread = task.spawn(function()
        while flyPlatform and flyPlatform.Parent do
            RunService.Heartbeat:Wait()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChild("HumanoidRootPart")
                if h and flyPlatform and flyPlatform.Parent then
                    flyPlatform.Position = Vector3.new(h.Position.X, flyCurrentY, h.Position.Z)
                end
            else
                break
            end
        end
    end)
end

local function flyRiseFast()
    if not flyPlatform or not flyPlatform.Parent then return end
    if flyFastRise then return end
    flyFastRise = true

    attachCharToPlatform()

    task.spawn(function()
        local stepSize = 0.25
        local stepWait = 0.05
        local target = FLY_END_Y
        while flyPlatform and flyPlatform.Parent and flyCurrentY < target do
            flyCurrentY = math.min(flyCurrentY + stepSize, target)
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChild("HumanoidRootPart")
                if h then
                    flyPlatform.Position = Vector3.new(h.Position.X, flyCurrentY, h.Position.Z)
                end
            end
            task.wait(stepWait)
        end
        print("[Fly] Rise xong → Y = " .. flyCurrentY)
        flyFastRise = false
    end)
end

if EggCarryRE then
    EggCarryRE.OnClientEvent:Connect(function(data)
        if typeof(data) ~= "table" then return end
        if data.IsCarrying == true and data.Uid then
            if bypassGuardActive then task.spawn(teleportToBase) end
            if flyActive then
                if not flyPlatform or not flyPlatform.Parent then
                    task.spawn(startFlyPlatform)
                    task.wait(0.1)
                end
                flyRiseFast()
            end
        end
    end)
end

-- =================================================================
-- BYPASS GUARD / FLY GUI (180x118)
-- =================================================================
local bfGui = Instance.new("ScreenGui")
bfGui.Name = "BypassFlyGUI"
bfGui.ResetOnSpawn = false
if gethui then bfGui.Parent = gethui() else bfGui.Parent = CoreGui end

local BFFrame = Instance.new("TextButton")
BFFrame.Size = UDim2.new(0, 180, 0, 118)
BFFrame.Position = UDim2.new(0, 20, 0.5, -59)
BFFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
BFFrame.BorderSizePixel = 0
BFFrame.Text = ""
BFFrame.AutoButtonColor = false
BFFrame.Active = true
BFFrame.Visible = false
BFFrame.Parent = bfGui
Instance.new("UICorner", BFFrame).CornerRadius = UDim.new(0, 8)

local BFFS = Instance.new("UIStroke")
BFFS.Thickness = 1.5
BFFS.Color = Color3.fromRGB(255, 150, 60)
BFFS.Parent = BFFrame

local GuardBtn = Instance.new("TextButton")
GuardBtn.Size = UDim2.new(1, -8, 0, 30)
GuardBtn.Position = UDim2.new(0, 4, 0, 6)
GuardBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 60)
GuardBtn.Text = "BYPASS GUARD"
GuardBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GuardBtn.Font = Enum.Font.GothamBold
GuardBtn.TextSize = 11
GuardBtn.AutoButtonColor = false
GuardBtn.Parent = BFFrame
Instance.new("UICorner", GuardBtn).CornerRadius = UDim.new(0, 5)

local GuardStatus = Instance.new("TextLabel")
GuardStatus.Size = UDim2.new(1, -8, 0, 12)
GuardStatus.Position = UDim2.new(0, 4, 0, 38)
GuardStatus.BackgroundTransparency = 1
GuardStatus.Text = "OFF | Carry → TP base + lock cam"
GuardStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
GuardStatus.Font = Enum.Font.Gotham
GuardStatus.TextSize = 9
GuardStatus.TextXAlignment = Enum.TextXAlignment.Left
GuardStatus.Parent = BFFrame

local FlyBtn = Instance.new("TextButton")
FlyBtn.Size = UDim2.new(1, -8, 0, 30)
FlyBtn.Position = UDim2.new(0, 4, 0, 56)
FlyBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 60)
FlyBtn.Text = "FLY"
FlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyBtn.Font = Enum.Font.GothamBold
FlyBtn.TextSize = 11
FlyBtn.AutoButtonColor = false
FlyBtn.Parent = BFFrame
Instance.new("UICorner", FlyBtn).CornerRadius = UDim.new(0, 5)

local FlyStatus = Instance.new("TextLabel")
FlyStatus.Size = UDim2.new(1, -8, 0, 12)
FlyStatus.Position = UDim2.new(0, 4, 0, 88)
FlyStatus.BackgroundTransparency = 1
FlyStatus.Text = "OFF | Rise 5y/s khi carry"
FlyStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
FlyStatus.Font = Enum.Font.Gotham
FlyStatus.TextSize = 9
FlyStatus.TextXAlignment = Enum.TextXAlignment.Left
FlyStatus.Parent = BFFrame

GuardBtn.MouseButton1Click:Connect(function()
    bypassGuardActive = not bypassGuardActive
    if bypassGuardActive then
        TweenService:Create(GuardBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(48, 209, 88) }):Play()
        GuardStatus.Text = "ON | Carry → TP base + lock cam"
        GuardStatus.TextColor3 = Color3.fromRGB(48, 209, 88)
    else
        TweenService:Create(GuardBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(255, 150, 60) }):Play()
        GuardStatus.Text = "OFF | Carry → TP base + lock cam"
        GuardStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
    end
end)

FlyBtn.MouseButton1Click:Connect(function()
    flyActive = not flyActive
    if flyActive then
        TweenService:Create(FlyBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(0, 150, 255) }):Play()
        FlyStatus.Text = "ON | Rise 5y/s khi carry"
        FlyStatus.TextColor3 = Color3.fromRGB(100, 200, 255)
    else
        TweenService:Create(FlyBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(255, 150, 60) }):Play()
        FlyStatus.Text = "OFF | Rise 5y/s khi carry"
        FlyStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
        cleanupFly()
    end
end)

local bfDragging, bfDragStart, bfStartPos
BFFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        bfDragging = true
        bfDragStart = input.Position
        bfStartPos = BFFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then bfDragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if bfDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - bfDragStart
        BFFrame.Position = UDim2.new(bfStartPos.X.Scale, bfStartPos.X.Offset + delta.X, bfStartPos.Y.Scale, bfStartPos.Y.Offset + delta.Y)
    end
end)

-- =================================================================
-- PANEL STEAL EGG VIP
-- =================================================================
local MUTATION_COLORS_VIP = {
    ["Golden"]=Color3.fromRGB(255,215,0),["Gold"]=Color3.fromRGB(255,215,0),
    ["Silver"]=Color3.fromRGB(192,192,200),["Rainbow"]=Color3.fromRGB(255,100,255),
    ["Luminous"]=Color3.fromRGB(255,255,200),["Fractured"]=Color3.fromRGB(150,220,255),
    ["Parasite"]=Color3.fromRGB(180,80,80),["Spirit Bloom"]=Color3.fromRGB(255,180,255),
    ["Bloom"]=Color3.fromRGB(255,200,220),
}

local VIP_HOME_POS        = Vector3.new(519, 70, -362.74)
local VIP_ARRIVE_DIST     = 2.5
local VIP_HOME_ARRIVE     = 6
local VIP_MAX_TIME        = 45
local VIP_SLOW_RADIUS     = 12
local VIP_MIN_SPEED       = 6
local VIP_DEFAULT_SPEED   = 16
local VIP_BRAKE_DIST      = 4
local VIP_STOP_HOLD_TICKS = 8
local VIP_STOP_HOLD_WAIT  = 0.02
local VIP_CARRY_CONFIRM_TIMEOUT = 5
local VIP_VERIFY_INTERVAL       = 0.15
local VIP_SNAPSHOT_INTERVAL     = 0.5
local VIP_TP_OFFSET_Y           = 3

local vipMovementMode = "walk"
local vipIsRunning = false
local vipEggList = {}
local vipCarrySignal = nil
local vipEggCarrying = false
local vipIsRagdoll = false
local vipHeldUid = nil
local vipNeedRecover = false
local vipStealingUid = nil
local vipStealingCategory = nil
local vipStealingState = nil

local function vipNormalizeState(s)
    if type(s) ~= "string" then return "" end
    return s:lower():gsub("%s+", "")
end
local function vipClassifyState(stateStr)
    local s = vipNormalizeState(stateStr)
    if s == "" then return "unknown" end
    if s:find("claim", 1, true) then return "claimed" end
    if s:find("drop", 1, true) then return "dropped" end
    if s:find("carried", 1, true) or s:find("guardcarry", 1, true) or s == "carry" then return "carried" end
    if s:find("slot", 1, true) or s:find("available", 1, true) then return "slot" end
    return "unknown"
end
local function vipGetMutations(rec)
    local r = {}
    if rec.BaseMutation and rec.BaseMutation ~= "" then r[rec.BaseMutation] = true end
    if typeof(rec.Mutations) == "table" then
        for _, m in pairs(rec.Mutations) do
            if typeof(m) == "string" and m ~= "" then r[m] = true end
        end
    end
    local list = {}
    for m in pairs(r) do table.insert(list, m) end
    table.sort(list)
    return list
end

local VIP_SnapshotRF = findRemote("AskFieldEggSnapshot", "RemoteFunction")
local VIP_EggCarryRF = findRemote("AskFieldEggCarry", "RemoteFunction")
local VIP_EggShiftedRE = findRemote("FieldEggShifted", "RemoteEvent")
local VIP_EggGoneRE = findRemote("FieldEggGone", "RemoteEvent")

local function vipUpdateEgg(data)
    if typeof(data) ~= "table" or not data.Uid then return end
    local e = vipEggList[data.Uid] or {}
    e.category = data.AssetCategory or data.Category or e.category
    e.state    = data.State or e.state
    e.cframe   = data.BoundsCFrame or data.CFrame or e.cframe
    e.uid      = data.Uid
    e.area     = data.AreaId or e.area
    e.slot     = data.NestId or e.slot
    e.mutations = vipGetMutations(data)
    vipEggList[data.Uid] = e
    if data.Uid == vipStealingUid then
        local cls = vipClassifyState(e.state)
        if cls ~= vipStealingState then vipStealingState = cls end
    end
end

local function vipTakeSnapshot()
    if not VIP_SnapshotRF then return 0 end
    local ok, res = pcall(function() return VIP_SnapshotRF:InvokeServer() end)
    if not ok or typeof(res) ~= "table" then return 0 end
    local records = res.Records or res.records
    if typeof(records) ~= "table" then return 0 end
    local seen = {}
    local n = 0
    for _, rec in ipairs(records) do
        if typeof(rec) == "table" and rec.Uid then
            seen[rec.Uid] = true
            vipUpdateEgg(rec)
            n = n + 1
        end
    end
    for uid in pairs(vipEggList) do
        if not seen[uid] and uid ~= vipStealingUid then vipEggList[uid] = nil end
    end
    return n
end

if VIP_EggShiftedRE then VIP_EggShiftedRE.OnClientEvent:Connect(vipUpdateEgg) end
if VIP_EggGoneRE then
    VIP_EggGoneRE.OnClientEvent:Connect(function(uid)
        if uid and uid ~= vipStealingUid then vipEggList[uid] = nil end
    end)
end

if EggCarryRE then
    EggCarryRE.OnClientEvent:Connect(function(data)
        if typeof(data) ~= "table" then return end
        local uid = data.Uid
        if data.IsCarrying == true and uid then
            vipEggCarrying = true
            vipCarrySignal = uid
            if not vipHeldUid then vipHeldUid = uid end
            if vipEggList[uid] then vipEggList[uid].state = "Carried" end
        elseif data.IsCarrying == false then
            vipEggCarrying = false
            vipCarrySignal = nil
            if uid and vipEggList[uid] then vipEggList[uid].state = "Dropped" end
            if vipHeldUid then vipNeedRecover = true end
        end
    end)
end

local function vipIsEggAvailable(uid)
    local live = vipEggList[uid]
    if not live or not live.cframe then return false end
    local cls = vipClassifyState(live.state)
    if cls == "carried" or cls == "claimed" then return false end
    return true
end

local function vipGetBaseSpeed()
    local char = LocalPlayer.Character
    if not char then return VIP_DEFAULT_SPEED end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return VIP_DEFAULT_SPEED end
    local spd = hum.WalkSpeed
    if not spd or spd <= 0 then return VIP_DEFAULT_SPEED end
    return spd
end

local function vipKillMomentum(holdTicks)
    holdTicks = holdTicks or VIP_STOP_HOLD_TICKS
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.WalkSpeed = 0
    hum:MoveTo(hrp.Position)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    local anchorCF = hrp.CFrame
    for _ = 1, holdTicks do
        local c = LocalPlayer.Character
        if not c then break end
        local cHrp = c:FindFirstChild("HumanoidRootPart")
        local cHum = c:FindFirstChildOfClass("Humanoid")
        if not cHrp or not cHum then break end
        cHrp.AssemblyLinearVelocity = Vector3.zero
        cHrp.AssemblyAngularVelocity = Vector3.zero
        cHrp.CFrame = anchorCF
        cHum:MoveTo(anchorCF.Position)
        cHum.WalkSpeed = 0
        task.wait(VIP_STOP_HOLD_WAIT)
    end
    hum.WalkSpeed = vipGetBaseSpeed()
end

local function vipAbortWalk()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 0
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hum:MoveTo(hrp.Position) end
        end
    end
    vipKillMomentum()
end

local function vipIsHoldingEgg()
    if vipEggCarrying then return true end
    local char = LocalPlayer.Character
    if not char then return false end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("egg", 1, true) then return true end
    end
    return false
end

local function vipWalkToVerified(uid, targetProvider, arriveDist, maxTime)
    arriveDist = arriveDist or VIP_ARRIVE_DIST
    maxTime    = maxTime or VIP_MAX_TIME
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local baseSpeed = vipGetBaseSpeed()
    local startTime = os.clock()
    local lastVerify = 0
    while vipIsRunning and os.clock() - startTime < maxTime do
        if os.clock() - lastVerify > VIP_VERIFY_INTERVAL then
            lastVerify = os.clock()
            if not vipIsEggAvailable(uid) then vipAbortWalk() return false end
        end
        if vipIsRagdoll then
            task.wait(0.1) startTime = os.clock()
        else
            local c = LocalPlayer.Character
            if not c or c ~= char then break end
            local cHrp = c:FindFirstChild("HumanoidRootPart")
            local cHum = c:FindFirstChildOfClass("Humanoid")
            if not cHrp or not cHum then break end
            local curTarget = targetProvider and targetProvider()
            if not curTarget then vipAbortWalk() return false end
            local dist = (cHrp.Position - curTarget).Magnitude
            if dist <= arriveDist then
                if vipMovementMode == "teleport" then
                    cHrp.CFrame = CFrame.new(curTarget + Vector3.new(0, VIP_TP_OFFSET_Y, 0)) * (cHrp.CFrame - cHrp.CFrame.Position)
                    task.wait(0.05)
                else
                    vipKillMomentum()
                end
                if not vipIsEggAvailable(uid) then return false end
                return true
            end
            if vipMovementMode == "teleport" then
                cHum.WalkSpeed = 0
                cHrp.CFrame = CFrame.new(curTarget + Vector3.new(0, VIP_TP_OFFSET_Y, 0)) * (cHrp.CFrame - cHrp.CFrame.Position)
                task.wait(0.05)
            else
                if dist <= VIP_SLOW_RADIUS then
                    local ratio = (dist - VIP_BRAKE_DIST) / (VIP_SLOW_RADIUS - VIP_BRAKE_DIST)
                    cHum.WalkSpeed = math.max(VIP_MIN_SPEED, VIP_MIN_SPEED + (baseSpeed - VIP_MIN_SPEED) * math.clamp(ratio, 0, 1))
                else
                    cHum.WalkSpeed = baseSpeed
                end
                cHum:MoveTo(curTarget)
                task.wait(0.05)
            end
        end
    end
    return false
end

local function vipWalkHomeRealtime()
    local char = LocalPlayer.Character
    if not char then return "nochar" end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return "nohum" end
    local baseSpeed = vipGetBaseSpeed()
    local startTime = os.clock()
    while vipIsRunning and os.clock() - startTime < VIP_MAX_TIME do
        if vipStealingUid then
            local info = vipEggList[vipStealingUid]
            if info then
                local cls = vipClassifyState(info.state)
                if cls ~= vipStealingState then vipStealingState = cls end
                if cls == "dropped" then vipAbortWalk() return "dropped" end
                if cls == "claimed" then vipAbortWalk() return "claimed" end
                if cls == "gone" then vipAbortWalk() return "gone" end
            end
        end
        if vipIsRagdoll then
            task.wait(0.1) startTime = os.clock()
        else
            local c = LocalPlayer.Character
            if not c or c ~= char then break end
            local cHrp = c:FindFirstChild("HumanoidRootPart")
            local cHum = c:FindFirstChildOfClass("Humanoid")
            if not cHrp or not cHum then break end
            local dist = (cHrp.Position - VIP_HOME_POS).Magnitude
            if dist <= VIP_HOME_ARRIVE then vipKillMomentum() return "home" end
            if vipMovementMode == "teleport" then
                cHum.WalkSpeed = 0
                cHrp.CFrame = CFrame.new(VIP_HOME_POS + Vector3.new(0, VIP_TP_OFFSET_Y, 0)) * (cHrp.CFrame - cHrp.CFrame.Position)
                task.wait(0.05)
            else
                if dist <= VIP_SLOW_RADIUS then
                    local ratio = (dist - VIP_BRAKE_DIST) / (VIP_SLOW_RADIUS - VIP_BRAKE_DIST)
                    cHum.WalkSpeed = math.max(VIP_MIN_SPEED, VIP_MIN_SPEED + (baseSpeed - VIP_MIN_SPEED) * math.clamp(ratio, 0, 1))
                else
                    cHum.WalkSpeed = baseSpeed
                end
                cHum:MoveTo(VIP_HOME_POS)
                task.wait(0.05)
            end
        end
    end
    return "timeout"
end

local function vipSendCarryAndWait(uid, timeout)
    if not uid or not VIP_EggCarryRF then return false end
    timeout = timeout or VIP_CARRY_CONFIRM_TIMEOUT
    vipCarrySignal = nil
    local ok, result = pcall(function() return VIP_EggCarryRF:InvokeServer({ Uid = uid }) end)
    if ok and typeof(result) == "table" then
        if result.Success == false or result.Ok == false then return false end
    end
    local st = os.clock()
    while vipIsRunning and os.clock() - st < timeout do
        if vipCarrySignal == uid then vipHeldUid = uid return true end
        if vipCarrySignal and vipCarrySignal ~= uid then return false end
        task.wait(0.05)
    end
    return false
end

local function vipStealLoopByUid(targetUid)
    while vipIsRunning and vipStealingUid == targetUid do
        local info = vipEggList[targetUid]
        if not info then return end
        local cls = vipClassifyState(info.state)
        vipStealingState = cls
        if cls == "claimed" or cls == "gone" then return end

        if cls == "carried" then
            if vipIsHoldingEgg() or vipEggCarrying then
                local result = vipWalkHomeRealtime()
                if result == "home" then return
                elseif result == "claimed" or result == "gone" then return
                end
            else
                local ws = os.clock()
                while vipIsRunning and vipStealingUid == targetUid and os.clock() - ws < 3 do
                    task.wait(0.15)
                    local e2 = vipEggList[targetUid]
                    if e2 and vipClassifyState(e2.state) ~= "carried" then break end
                end
            end
        elseif cls == "dropped" or cls == "slot" then
            local capturedUid = targetUid
            local function eggProvider()
                if not vipIsEggAvailable(capturedUid) then return nil end
                local live = vipEggList[capturedUid]
                if live and live.cframe then return live.cframe.Position end
                return nil
            end
            if info.cframe then
                local ok = vipWalkToVerified(capturedUid, eggProvider, VIP_ARRIVE_DIST, VIP_MAX_TIME)
                if vipIsRunning and vipStealingUid == targetUid and ok then
                    vipSendCarryAndWait(targetUid, VIP_CARRY_CONFIRM_TIMEOUT)
                end
            end
        end
        task.wait(0.3)
    end
end

local function vipProcessStealByUid(targetUid, targetCategory)
    if vipIsRunning then
        vipIsRunning = false
        task.wait(0.3)
    end
    vipIsRunning = true
    vipHeldUid = nil
    vipNeedRecover = false
    vipStealingUid = targetUid
    vipStealingCategory = targetCategory
    vipStealingState = nil
    local info = vipEggList[targetUid]
    if info then vipStealingState = vipClassifyState(info.state) end
    task.spawn(function()
        while vipIsRunning and vipStealingUid == targetUid do
            task.wait(VIP_SNAPSHOT_INTERVAL)
            vipTakeSnapshot()
        end
    end)
    vipStealLoopByUid(targetUid)
    vipStealingUid = nil
    vipStealingCategory = nil
    vipStealingState = nil
    vipIsRunning = false
end

-- VIP GUI
local vipGui = Instance.new("ScreenGui")
vipGui.Name = "StealEggVipGUI"
vipGui.ResetOnSpawn = false
if gethui then vipGui.Parent = gethui() else vipGui.Parent = CoreGui end

local VipFrame = Instance.new("Frame")
VipFrame.Size = UDim2.new(0, 180, 0, 118)
VipFrame.Position = UDim2.new(0.5, -90, 0.5, -59)
VipFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
VipFrame.BorderSizePixel = 0
VipFrame.Visible = false
VipFrame.Parent = vipGui
Instance.new("UICorner", VipFrame).CornerRadius = UDim.new(0, 8)
local VipFS = Instance.new("UIStroke")
VipFS.Thickness = 1.5
VipFS.Color = Color3.fromRGB(255, 200, 60)
VipFS.Parent = VipFrame

local VipStealLabel = Instance.new("TextLabel")
VipStealLabel.Size = UDim2.new(1, -8, 0, 18)
VipStealLabel.Position = UDim2.new(0, 4, 0, 4)
VipStealLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
VipStealLabel.Text = "IDLE"
VipStealLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
VipStealLabel.Font = Enum.Font.Code
VipStealLabel.TextSize = 10
VipStealLabel.Parent = VipFrame
Instance.new("UICorner", VipStealLabel).CornerRadius = UDim.new(0, 4)

local function vipRefreshLabel()
    if not vipStealingUid then
        VipStealLabel.Text = "IDLE"
        VipStealLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        VipStealLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        return
    end
    local st = tostring(vipStealingState or "?"):upper()
    local col = Color3.fromRGB(255, 200, 100)
    if vipStealingState == "slot" then col = Color3.fromRGB(150, 255, 180)
    elseif vipStealingState == "carried" then col = Color3.fromRGB(100, 200, 255)
    elseif vipStealingState == "dropped" then col = Color3.fromRGB(255, 150, 100)
    elseif vipStealingState == "claimed" then col = Color3.fromRGB(150, 150, 150)
    elseif vipStealingState == "gone" then col = Color3.fromRGB(255, 100, 100)
    end
    VipStealLabel.Text = "STEAL: " .. tostring(vipStealingCategory or "?") .. " [" .. st .. "]"
    VipStealLabel.TextColor3 = col
end

local VipStopBtn = Instance.new("TextButton")
VipStopBtn.Size = UDim2.new(1, -8, 0, 26)
VipStopBtn.Position = UDim2.new(0, 4, 0, 24)
VipStopBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
VipStopBtn.Text = "STOP"
VipStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VipStopBtn.Font = Enum.Font.GothamBold
VipStopBtn.TextSize = 11
VipStopBtn.AutoButtonColor = false
VipStopBtn.Parent = VipFrame
Instance.new("UICorner", VipStopBtn).CornerRadius = UDim.new(0, 5)

local VipModeBtn = Instance.new("TextButton")
VipModeBtn.Size = UDim2.new(1, -8, 0, 26)
VipModeBtn.Position = UDim2.new(0, 4, 0, 54)
VipModeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
VipModeBtn.Text = "Mode: Walk"
VipModeBtn.TextColor3 = Color3.fromRGB(30, 30, 30)
VipModeBtn.Font = Enum.Font.GothamBold
VipModeBtn.TextSize = 11
VipModeBtn.AutoButtonColor = false
VipModeBtn.Parent = VipFrame
Instance.new("UICorner", VipModeBtn).CornerRadius = UDim.new(0, 5)

VipModeBtn.MouseButton1Click:Connect(function()
    if vipMovementMode == "walk" then
        vipMovementMode = "teleport"
        VipModeBtn.Text = "Mode: Teleport"
        VipModeBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 60)
    else
        vipMovementMode = "walk"
        VipModeBtn.Text = "Mode: Walk"
        VipModeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
    end
end)

local VipShowBtn = Instance.new("TextButton")
VipShowBtn.Size = UDim2.new(1, -8, 0, 26)
VipShowBtn.Position = UDim2.new(0, 4, 0, 84)
VipShowBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 220)
VipShowBtn.Text = "SHOW EGG"
VipShowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VipShowBtn.Font = Enum.Font.GothamBold
VipShowBtn.TextSize = 11
VipShowBtn.AutoButtonColor = false
VipShowBtn.Parent = VipFrame
Instance.new("UICorner", VipShowBtn).CornerRadius = UDim.new(0, 5)

VipStopBtn.MouseButton1Click:Connect(function()
    vipIsRunning = false
    vipStealingUid = nil
    vipStealingCategory = nil
    vipStealingState = nil
    vipAbortWalk()
    VipStealLabel.Text = "STOPPED"
    VipStealLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
end)

-- SHOW EGG PANEL VIP
local vipShowGui = Instance.new("ScreenGui")
vipShowGui.Name = "VipShowEggGUI"
vipShowGui.ResetOnSpawn = false
vipShowGui.Enabled = false
if gethui then vipShowGui.Parent = gethui() else vipShowGui.Parent = CoreGui end

local VSFrame = Instance.new("Frame")
VSFrame.Size = UDim2.new(0, 533, 0, 311)
VSFrame.Position = UDim2.new(0.5, -266, 0.5, -155)
VSFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
VSFrame.BorderSizePixel = 0
VSFrame.Parent = vipShowGui
Instance.new("UICorner", VSFrame).CornerRadius = UDim.new(0, 8)
local VSFS = Instance.new("UIStroke")
VSFS.Thickness = 1.5
VSFS.Color = Color3.fromRGB(255, 200, 60)
VSFS.Parent = VSFrame

local VSTitle = Instance.new("TextLabel")
VSTitle.Size = UDim2.new(1, -140, 0, 18)
VSTitle.Position = UDim2.new(0, 4, 0, 3)
VSTitle.BackgroundTransparency = 1
VSTitle.Text = "SHOW EGG VIP"
VSTitle.TextColor3 = Color3.fromRGB(255, 220, 150)
VSTitle.Font = Enum.Font.GothamBold
VSTitle.TextSize = 11
VSTitle.TextXAlignment = Enum.TextXAlignment.Left
VSTitle.Parent = VSFrame

local VSRefreshBtn = Instance.new("TextButton")
VSRefreshBtn.Size = UDim2.new(0, 60, 0, 18)
VSRefreshBtn.Position = UDim2.new(1, -128, 0, 3)
VSRefreshBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
VSRefreshBtn.Text = "REFRESH"
VSRefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VSRefreshBtn.Font = Enum.Font.GothamBold
VSRefreshBtn.TextSize = 8
VSRefreshBtn.AutoButtonColor = false
VSRefreshBtn.Parent = VSFrame
Instance.new("UICorner", VSRefreshBtn).CornerRadius = UDim.new(0, 4)

local VSCloseBtn = Instance.new("TextButton")
VSCloseBtn.Size = UDim2.new(0, 60, 0, 18)
VSCloseBtn.Position = UDim2.new(1, -66, 0, 3)
VSCloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
VSCloseBtn.Text = "CLOSE"
VSCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VSCloseBtn.Font = Enum.Font.GothamBold
VSCloseBtn.TextSize = 8
VSCloseBtn.AutoButtonColor = false
VSCloseBtn.Parent = VSFrame
Instance.new("UICorner", VSCloseBtn).CornerRadius = UDim.new(0, 4)

local VSBiomeScroll = Instance.new("ScrollingFrame")
VSBiomeScroll.Size = UDim2.new(0, 110, 1, -36)
VSBiomeScroll.Position = UDim2.new(0, 4, 0, 24)
VSBiomeScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
VSBiomeScroll.BorderSizePixel = 0
VSBiomeScroll.ScrollBarThickness = 4
VSBiomeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
VSBiomeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
VSBiomeScroll.Parent = VSFrame
Instance.new("UICorner", VSBiomeScroll).CornerRadius = UDim.new(0, 4)

local VSBiomeList = Instance.new("UIListLayout")
VSBiomeList.SortOrder = Enum.SortOrder.LayoutOrder
VSBiomeList.Padding = UDim.new(0, 2)
VSBiomeList.Parent = VSBiomeScroll

local VSDetailScroll = Instance.new("ScrollingFrame")
VSDetailScroll.Size = UDim2.new(1, -120, 1, -36)
VSDetailScroll.Position = UDim2.new(0, 116, 0, 24)
VSDetailScroll.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
VSDetailScroll.BorderSizePixel = 0
VSDetailScroll.ScrollBarThickness = 4
VSDetailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
VSDetailScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
VSDetailScroll.Parent = VSFrame
Instance.new("UICorner", VSDetailScroll).CornerRadius = UDim.new(0, 4)

local VSDetailList = Instance.new("UIListLayout")
VSDetailList.SortOrder = Enum.SortOrder.LayoutOrder
VSDetailList.Padding = UDim.new(0, 1)
VSDetailList.Parent = VSDetailScroll

local VSInfoLabel = Instance.new("TextLabel")
VSInfoLabel.Size = UDim2.new(1, -120, 0, 16)
VSInfoLabel.Position = UDim2.new(0, 116, 0, 8)
VSInfoLabel.BackgroundTransparency = 1
VSInfoLabel.Text = "Chọn biome..."
VSInfoLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
VSInfoLabel.Font = Enum.Font.GothamBold
VSInfoLabel.TextSize = 10
VSInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
VSInfoLabel.Parent = VSFrame

local VIP_ALL_BIOMES = {
    "Forest","Lake","Desert","Jungle","Snow","Volcano",
    "Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom",
    "Titan Temple","Light Dark",
}

local vipShowBuckets = {}
local vipShowSelectedBiome = nil
local vipShowButtons = {}

local function vipRebuildShowBuckets()
    vipShowBuckets = {}
    for _, b in ipairs(VIP_ALL_BIOMES) do vipShowBuckets[b] = {} end
    for uid, info in pairs(vipEggList) do
        local cls = vipClassifyState(info.state)
        if cls ~= "claimed" then
            local b = info.area or "Unknown"
            if not vipShowBuckets[b] then vipShowBuckets[b] = {} end
            table.insert(vipShowBuckets[b], {
                uid = uid, category = info.category,
                state = info.state, stateCls = cls, cframe = info.cframe,
                mutations = info.mutations or {}, slot = info.slot,
            })
        end
    end
    for _, list in pairs(vipShowBuckets) do
        table.sort(list, function(a, b)
            return tostring(a.slot or "") < tostring(b.slot or "")
        end)
    end
end

local function vipClearShowDetail()
    for _, c in ipairs(VSDetailScroll:GetChildren()) do
        if c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
end

local function vipShowBiomeDetail(biome)
    vipClearShowDetail()
    VSInfoLabel.Text = "Biome: " .. biome
    local list = vipShowBuckets[biome] or {}

    if #list == 0 then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -4, 0, 16)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  (không có egg)"
        lbl.TextColor3 = Color3.fromRGB(150, 150, 180)
        lbl.Font = Enum.Font.Code
        lbl.TextSize = 9
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = VSDetailScroll
        return
    end

    for i, e in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 18)
        row.BackgroundTransparency = 1
        row.LayoutOrder = i
        row.Parent = VSDetailScroll

        local slotStr = tostring(e.slot or "?"):gsub("Slot_0*", "Slot")
        if not slotStr:find("Slot", 1, true) then slotStr = "Slot" .. slotStr end

        local mutStr = ""
        local mutCol = nil
        if #e.mutations > 0 then
            local shorts = {}
            for _, m in ipairs(e.mutations) do
                table.insert(shorts, tostring(m):lower())
                if not mutCol and MUTATION_COLORS_VIP[m] then mutCol = MUTATION_COLORS_VIP[m] end
            end
            mutStr = "[" .. table.concat(shorts, "+") .. "]"
        end

        local stateStr = "[" .. tostring(e.state or "?"):lower() .. "]"

        local col = Color3.fromRGB(220, 220, 240)
        if e.stateCls == "slot" then col = Color3.fromRGB(150, 255, 180)
        elseif e.stateCls == "carried" then col = Color3.fromRGB(255, 150, 150)
        elseif e.stateCls == "dropped" then col = Color3.fromRGB(255, 200, 100)
        end
        if mutCol then col = mutCol end
        if e.uid == vipStealingUid then col = Color3.fromRGB(255, 80, 80) end

        local text = string.format("%s %s %s%s",
            slotStr, tostring(e.category or "?"), stateStr, mutStr)

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(0.76, 0, 1, 0)
        info.BackgroundTransparency = 1
        info.Text = text
        info.TextColor3 = col
        info.Font = Enum.Font.Code
        info.TextSize = 10
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextScaled = true
        info.TextWrapped = false
        info.Parent = row

        local sizeCon = Instance.new("UITextSizeConstraint")
        sizeCon.MaxTextSize = 10
        sizeCon.MinTextSize = 6
        sizeCon.Parent = info

        local stealBtn = Instance.new("TextButton")
        stealBtn.Size = UDim2.new(0.23, -2, 0.95, 0)
        stealBtn.Position = UDim2.new(0.77, 2, 0.025, 0)
        if e.uid == vipStealingUid then
            stealBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            stealBtn.Text = "STOP"
        else
            stealBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            stealBtn.Text = "STEAL"
        end
        stealBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stealBtn.Font = Enum.Font.GothamBold
        stealBtn.TextSize = 9
        stealBtn.AutoButtonColor = false
        stealBtn.Parent = row
        Instance.new("UICorner", stealBtn).CornerRadius = UDim.new(0, 3)

        local capturedUid = e.uid
        local capturedCategory = e.category
        stealBtn.MouseButton1Click:Connect(function()
            if capturedUid == vipStealingUid then
                vipIsRunning = false
                vipStealingUid = nil
                vipStealingCategory = nil
                vipStealingState = nil
                vipAbortWalk()
                VipStealLabel.Text = "STOPPED"
                VipStealLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            else
                vipShowGui.Enabled = false
                VipShowBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 220)
                task.spawn(function()
                    vipProcessStealByUid(capturedUid, capturedCategory)
                end)
            end
        end)
    end
end

local function vipSelectShowBiome(biome)
    vipShowSelectedBiome = biome
    for b, btn in pairs(vipShowButtons) do
        btn.BackgroundColor3 = (b == biome)
            and Color3.fromRGB(200, 160, 60)
            or Color3.fromRGB(40, 40, 60)
    end
    vipShowBiomeDetail(biome)
end

local function vipRebuildShowButtons()
    for _, c in ipairs(VSBiomeScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    vipShowButtons = {}

    for i, biome in ipairs(VIP_ALL_BIOMES) do
        local count = #(vipShowBuckets[biome] or {})
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        btn.Text = " " .. biome .. " (" .. count .. ")"
        btn.TextColor3 = Color3.fromRGB(220, 220, 240)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.AutoButtonColor = false
        btn.LayoutOrder = i
        btn.Parent = VSBiomeScroll
        vipShowButtons[biome] = btn
        btn.MouseButton1Click:Connect(function() vipSelectShowBiome(biome) end)
    end

    if vipShowSelectedBiome and vipShowBuckets[vipShowSelectedBiome] then
        vipSelectShowBiome(vipShowSelectedBiome)
    else
        vipSelectShowBiome(VIP_ALL_BIOMES[1])
    end
end

VipShowBtn.MouseButton1Click:Connect(function()
    vipShowGui.Enabled = not vipShowGui.Enabled
    if vipShowGui.Enabled then
        vipTakeSnapshot()
        vipRebuildShowBuckets()
        vipRebuildShowButtons()
        VipShowBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
    else
        VipShowBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 220)
    end
end)

VSRefreshBtn.MouseButton1Click:Connect(function()
    vipTakeSnapshot()
    vipRebuildShowBuckets()
    vipRebuildShowButtons()
end)

VSCloseBtn.MouseButton1Click:Connect(function()
    vipShowGui.Enabled = false
    VipShowBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 220)
end)

task.spawn(function()
    while vipGui.Parent do
        task.wait(0.4)
        vipRefreshLabel()
        if vipShowGui.Enabled then
            vipTakeSnapshot()
            vipRebuildShowBuckets()
            vipRebuildShowButtons()
        end
    end
end)

local vipD, vipDS, vipSP
VipFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        vipD = true
        vipDS = input.Position
        vipSP = VipFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then vipD = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if vipD and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - vipDS
        VipFrame.Position = UDim2.new(vipSP.X.Scale, vipSP.X.Offset + delta.X, vipSP.Y.Scale, vipSP.Y.Offset + delta.Y)
    end
end)

local vsD, vsDS, vsSP
VSFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if input.Position.Y < VSFrame.AbsolutePosition.Y + 24 then
            vsD = true
            vsDS = input.Position
            vsSP = VSFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then vsD = false end
            end)
        end
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if vsD and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - vsDS
        VSFrame.Position = UDim2.new(vsSP.X.Scale, vsSP.X.Offset + delta.X, vsSP.Y.Scale, vsSP.Y.Offset + delta.Y)
    end
end)

-- =================================================================
-- AUTO ZONE
-- =================================================================
local autoZoneState = 0
local lastPromptTime = 0

local function monitorCharacterStun(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll
            or newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.PlatformStanding then
            if autoZoneActive and autoZoneState == 0 and (os.clock() - lastPromptTime <= 3.5) then
                autoZoneState = 1
            end
        end
    end)
    hum:GetPropertyChangedSignal("Sit"):Connect(function()
        if hum.Sit and autoZoneActive and autoZoneState == 0 and (os.clock() - lastPromptTime <= 3.5) then
            autoZoneState = 1
        end
    end)
end

if LocalPlayer.Character then monitorCharacterStun(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(monitorCharacterStun)

ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
    if playerWhoTriggered == LocalPlayer then
        lastPromptTime = os.clock()
        if autoZoneActive and autoZoneState == 1 then
            autoZoneState = 2
            triggerMiniButtonByName("Base")
            task.spawn(function()
                task.wait(10)
                autoZoneState = 0
            end)
        end
    end
end)

-- =================================================================
-- GOD MODE
-- =================================================================
local godModeEnabled = false

local function toggleGodMode(state)
    local character = LocalPlayer.Character
    if not character then return end
    if state then
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then tool.Parent = LocalPlayer.Backpack end
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end
        local currentCFrame = rootPart.CFrame
        local newHumanoid = humanoid:Clone()
        newHumanoid.Parent = character
        humanoid:Destroy()
        LocalPlayer.Character = nil
        LocalPlayer.Character = character
        workspace.CurrentCamera.CameraSubject = newHumanoid
        task.defer(function()
            if rootPart then rootPart.CFrame = currentCFrame end
        end)
    else
        LocalPlayer:LoadCharacter()
    end
end

-- =================================================================
-- PROXIMITY PROMPT BYPASS
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
    if autoSteal then triggerPrompt(prompt) end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    shownPrompts[prompt] = nil
end)

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then bypassPrompt(descendant, 25) end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if not autoSteal then continue end
        pcall(function()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for prompt, _ in pairs(shownPrompts) do
                if prompt and prompt:IsDescendantOf(workspace) and prompt.Enabled then
                    local pos = getPromptPosition(prompt)
                    if pos then
                        if (hrp.Position - pos).Magnitude <= 25 then triggerPrompt(prompt) end
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
local knockbackRunning = false
local knockbackConn = nil
local lastStableCFrame = nil

local function isBadState(state)
    return state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.PlatformStanding
end

local function startAntiKnockback(char, hum, hrp)
    if knockbackRunning then return end
    knockbackRunning = true
    lastStableCFrame = hrp.CFrame
    knockbackConn = RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then
            if knockbackConn then knockbackConn:Disconnect() knockbackConn = nil end
            knockbackRunning = false
            return
        end
        local cHrp = char:FindFirstChild("HumanoidRootPart")
        local cHum = char:FindFirstChildOfClass("Humanoid")
        if not cHrp or not cHum then return end
        cHrp.AssemblyLinearVelocity = Vector3.zero
        cHrp.AssemblyAngularVelocity = Vector3.zero
        cHrp.Velocity = Vector3.zero
        cHrp.RotVelocity = Vector3.zero
        if lastStableCFrame then
            local dist = (cHrp.Position - lastStableCFrame.Position).Magnitude
            if dist > 5 then
                local pos = lastStableCFrame.Position
                cHrp.CFrame = CFrame.new(pos, pos + lastStableCFrame.LookVector)
            end
        end
        pcall(function()
            cHum:ChangeState(Enum.HumanoidStateType.Running)
            cHum.PlatformStand = false
            cHum.Sit = false
            cHum.AutoRotate = true
        end)
        for _, motor in ipairs(char:GetDescendants()) do
            if motor:IsA("Motor6D") and not motor.Enabled then motor.Enabled = true end
        end
    end)
end

local function stopAntiKnockback()
    if knockbackConn then knockbackConn:Disconnect() knockbackConn = nil end
    knockbackRunning = false
end

local function setupCharacter(char)
    if not char then return end
    stopAntiKnockback()
    lastStableCFrame = nil
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum.StateChanged:Connect(function(_, newState)
            if not antiStun then return end
            if isBadState(newState) then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    startAntiKnockback(char, hum, hrp)
                end
            else
                if newState == Enum.HumanoidStateType.Running or newState == Enum.HumanoidStateType.RunningNoPhysics
                    or newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.GettingUp then
                    stopAntiKnockback()
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then lastStableCFrame = hrp.CFrame end
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
-- HITBOX & ANTI TRAP
-- =================================================================
local trapESP = {}

local function createTrapESP(part)
    if not antiTrapActive or not part or not part:IsA("BasePart") or trapESP[part] then return end
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
    local transient = workspace:FindFirstChild("Transient")
    if not transient then return end
    local playerTrap = transient:FindFirstChild("PlayerTrap")
    if not playerTrap then return end
    for _, obj in ipairs(playerTrap:GetDescendants()) do
        if obj:IsA("BasePart") then disableTrapPart(obj) end
    end
    if playerTrap:IsA("BasePart") then disableTrapPart(playerTrap) end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if antiTrapActive then pcall(scanTraps) end
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
-- AUTO BAT
-- =================================================================
local function fireAutoBatM1(tool)
    if not tool or not tool.Parent then return end
    pcall(function() tool:Activate() end)
    if getconnections then
        for _, sig in ipairs({ tool.Activated, tool.MouseButton1Click, tool.MouseButton1Down }) do
            pcall(function()
                for _, conn in ipairs(getconnections(sig)) do
                    if conn.Fire then conn:Fire() end
                end
            end)
        end
    end
    for _, desc in ipairs(tool:GetDescendants()) do
        pcall(function()
            if desc:IsA("RemoteEvent") then desc:FireServer()
            elseif desc:IsA("RemoteFunction") then desc:InvokeServer()
            elseif desc:IsA("BindableEvent") then desc:Fire() end
        end)
    end
    local handle = tool:FindFirstChild("Handle")
    if handle and getconnections then
        pcall(function()
            for _, conn in ipairs(getconnections(handle.MouseButton1Click)) do
                if conn.Fire then conn:Fire() end
            end
        end)
    end
end

local function collectAutoBatTools()
    local list = {}
    local char = LocalPlayer.Character
    if not char then return list end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local scramblerName = "The Scrambler [X1]"
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name == scramblerName or tool:FindFirstChild("HitAnim")) then
                table.insert(list, tool)
            end
        end
    end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name == scramblerName or tool:FindFirstChild("HitAnim")) then
            local dup = false
            for _, t in ipairs(list) do if t == tool then dup = true break end end
            if not dup then table.insert(list, tool) end
        end
    end
    return list
end

task.spawn(function()
    local currentIndex = 1
    local lastSwapTime = 0
    local SWAP_INTERVAL = 0.3
    while true do
        task.wait(0.05)
        if not autoBatActive then
            currentIndex = 1
            lastSwapTime = 0
            task.wait(0.2)
            continue
        end
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then task.wait(0.3) continue end
        local tools = collectAutoBatTools()
        if #tools == 0 then task.wait(0.4) continue end
        if currentIndex > #tools then currentIndex = 1 end
        local targetTool = tools[currentIndex]
        if not targetTool or not targetTool.Parent then currentIndex = 1 task.wait(0.1) continue end
        if os.clock() - lastSwapTime >= SWAP_INTERVAL then
            lastSwapTime = os.clock()
            if targetTool.Parent ~= char then
                pcall(function() humanoid:EquipTool(targetTool) end)
                task.wait(0.05)
            end
            currentIndex = currentIndex + 1
            if currentIndex > #tools then currentIndex = 1 end
        end
        local equippedTool = nil
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and (t.Name == "The Scrambler [X1]" or t:FindFirstChild("HitAnim")) then
                equippedTool = t
                break
            end
        end
        if equippedTool then pcall(function() fireAutoBatM1(equippedTool) end) end
        RunService.Heartbeat:Wait()
    end
end)

-- =================================================================
-- iOS 26 UI ENGINE
-- =================================================================
local function enableDragging(topbar, frame)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function iOS26Glass:CreateWindow(titleText)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "iOS26_LiquidGlass_WindUI"
    if gethui then ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
    else ScreenGui.Parent = CoreGui end

    local originalSize = UDim2.new(0, 522, 0, 324)
    local openPosition = UDim2.new(0.5, -261, 0.01, 0)
    local islandSize = UDim2.new(0, 160, 0, 34)
    local islandPosition = UDim2.new(0.5, -80, 0.01, 0)

    local isMinimized = false
    local isAnimating = false

    local MainFrame = Instance.new("Frame")
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
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -70, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = (titleText or "Dragon Nova Hub") .. " <font size='4' color='#787882'>00:00:00</font>"
    Title.RichText = true
    Title.TextColor3 = Color3.fromRGB(15, 15, 20)
    Title.TextSize = 13.5
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    task.spawn(function()
        while true do
            local t = os.date("!*t", os.time() + 7 * 3600)
            local clock = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
            Title.Text = (titleText or "Dragon Nova Hub") .. " <font size='4' color='#787882'>" .. clock .. "</font>"
            task.wait(0.25)
        end
    end)

    local IslandLabel = Instance.new("TextLabel")
    IslandLabel.Size = UDim2.new(1, 0, 1, 0)
    IslandLabel.BackgroundTransparency = 1
    IslandLabel.Text = titleText or "Liquid Glass"
    IslandLabel.TextColor3 = Color3.fromRGB(15, 15, 20)
    IslandLabel.Font = Enum.Font.GothamBold
    IslandLabel.TextSize = 12
    IslandLabel.Visible = false
    IslandLabel.Parent = MainFrame

    local MinimizeBtn = Instance.new("TextButton")
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
    Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(1, 0)

    enableDragging(TopBar, MainFrame)
    enableDragging(MainFrame, MainFrame)

    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 130, 1, -46)
    Sidebar.Position = UDim2.new(0, 10, 0, 36)
    Sidebar.BackgroundTransparency = 0.80
    Sidebar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Sidebar.ClipsDescendants = true
    Sidebar.Parent = MainFrame
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)

    local SideStroke = Instance.new("UIStroke")
    SideStroke.Thickness = 1
    SideStroke.Color = Color3.fromRGB(255, 255, 255)
    SideStroke.Transparency = 0.65
    SideStroke.Parent = Sidebar

    local TabHolder = Instance.new("ScrollingFrame")
    TabHolder.Size = UDim2.new(1, 0, 1, -100)
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
    PlayerContainer.Size = UDim2.new(1, 0, 0, 96)
    PlayerContainer.Position = UDim2.new(0, 0, 1, -96)
    PlayerContainer.BackgroundTransparency = 1
    PlayerContainer.Parent = Sidebar

    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Size = UDim2.new(0, 48, 0, 48)
    AvatarImage.Position = UDim2.new(0.5, -24, 0, 4)
    AvatarImage.BackgroundTransparency = 1
    AvatarImage.Parent = PlayerContainer
    Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        local content, isLoaded = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        if isLoaded and content then AvatarImage.Image = content end
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
    ContentContainer.Size = UDim2.new(1, -152, 1, -44)
    ContentContainer.Position = UDim2.new(0, 144, 0, 36)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local function minimizeMenu()
        if isAnimating or isMinimized then return end
        isAnimating = true
        Sidebar.Visible = false
        ContentContainer.Visible = false
        TopBar.Visible = false

        local dotTween = TweenService:Create(MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0.5, -9, 0.01, 0) })
        TweenService:Create(MainCorner, TweenInfo.new(0.25), { CornerRadius = UDim.new(1, 0) }):Play()
        dotTween:Play()
        dotTween.Completed:Wait()

        local expandIsland = TweenService:Create(MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = islandSize, Position = islandPosition })
        expandIsland:Play()
        expandIsland.Completed:Wait()

        IslandLabel.Visible = true
        isMinimized = true
        isAnimating = false
    end

    local function expandMenu()
        if isAnimating or not isMinimized then return end
        isAnimating = true
        IslandLabel.Visible = false

        local swellTween = TweenService:Create(MainFrame,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 176, 0, 44), Position = UDim2.new(0.5, -88, 0.01, 0) })
        swellTween:Play()
        swellTween.Completed:Wait()

        local menuTween = TweenService:Create(MainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = originalSize, Position = openPosition })
        TweenService:Create(MainCorner, TweenInfo.new(0.35), { CornerRadius = UDim.new(0, 22) }):Play()
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
        if isMinimized and not isAnimating and (
            input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
        ) then
            expandMenu()
        end
    end)

    local Window = { ActiveTab = nil }

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
        Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 9)

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
                if child:IsA("ScrollingFrame") then child.Visible = false end
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
        if not Window.ActiveTab then activate() Window.ActiveTab = TabContent end

        local Tab = {}

        function Tab:AddProfileCard()
            local ProfileFrame = Instance.new("Frame")
            ProfileFrame.Size = UDim2.new(1, 0, 0, 48)
            ProfileFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ProfileFrame.BackgroundTransparency = 0.78
            ProfileFrame.Parent = TabContent
            Instance.new("UICorner", ProfileFrame).CornerRadius = UDim.new(0, 10)

            local PStroke = Instance.new("UIStroke")
            PStroke.Thickness = 1.5
            PStroke.Color = Color3.fromRGB(255, 255, 255)
            PStroke.Transparency = 0.5
            PStroke.Parent = ProfileFrame

            local CircleAvatar = Instance.new("ImageLabel")
            CircleAvatar.Size = UDim2.new(0, 34, 0, 34)
            CircleAvatar.Position = UDim2.new(0, 8, 0.5, -17)
            CircleAvatar.BackgroundTransparency = 1
            CircleAvatar.Parent = ProfileFrame
            Instance.new("UICorner", CircleAvatar).CornerRadius = UDim.new(1, 0)

            task.spawn(function()
                local content, isLoaded = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                if isLoaded and content then CircleAvatar.Image = content end
            end)

            local N = Instance.new("TextLabel")
            N.Size = UDim2.new(1, -52, 0, 16)
            N.Position = UDim2.new(0, 48, 0, 8)
            N.BackgroundTransparency = 1
            N.Text = LocalPlayer.DisplayName
            N.TextColor3 = Color3.fromRGB(20, 20, 25)
            N.Font = Enum.Font.GothamBold
            N.TextSize = 11.5
            N.TextXAlignment = Enum.TextXAlignment.Left
            N.TextTruncate = Enum.TextTruncate.AtEnd
            N.Parent = ProfileFrame

            local U = Instance.new("TextLabel")
            U.Size = UDim2.new(1, -52, 0, 14)
            U.Position = UDim2.new(0, 48, 0, 24)
            U.BackgroundTransparency = 1
            U.Text = "@" .. LocalPlayer.Name
            U.TextColor3 = Color3.fromRGB(110, 115, 125)
            U.Font = Enum.Font.Gotham
            U.TextSize = 10
            U.TextXAlignment = Enum.TextXAlignment.Left
            U.TextTruncate = Enum.TextTruncate.AtEnd
            U.Parent = ProfileFrame
        end

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
            Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 10)

            local Stroke = Instance.new("UIStroke")
            Stroke.Thickness = 1.5
            Stroke.Color = Color3.fromRGB(255, 255, 255)
            Stroke.Transparency = 0.6
            Stroke.Parent = BtnFrame

            BtnFrame.MouseButton1Click:Connect(function()
                TweenService:Create(BtnFrame, TweenInfo.new(0.08), { BackgroundTransparency = 0.4 }):Play()
                task.wait(0.08)
                TweenService:Create(BtnFrame, TweenInfo.new(0.12), { BackgroundTransparency = 0.78 }):Play()
                if callback then callback() end
            end)
        end

        function Tab:AddToggle(text, defaultState, callback)
            local toggled = defaultState or false
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleFrame.BackgroundTransparency = 0.78
            ToggleFrame.Parent = TabContent
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 10)

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
            SwitchTrack.BackgroundColor3 = toggled and Color3.fromRGB(48, 209, 88) or Color3.fromRGB(220, 220, 225)
            SwitchTrack.BackgroundTransparency = toggled and 0.25 or 0.6
            SwitchTrack.Parent = ToggleFrame
            Instance.new("UICorner", SwitchTrack).CornerRadius = UDim.new(1, 0)

            local Knob = Instance.new("Frame")
            Knob.AnchorPoint = Vector2.new(0.5, 0.5)
            Knob.Size = UDim2.new(0, 18, 0, 18)
            Knob.Position = toggled and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.BackgroundTransparency = 0.15
            Knob.Parent = SwitchTrack
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

            local ClickArea = Instance.new("TextButton")
            ClickArea.Size = UDim2.new(1, 0, 1, 0)
            ClickArea.BackgroundTransparency = 1
            ClickArea.Text = ""
            ClickArea.Parent = ToggleFrame

            ClickArea.MouseButton1Click:Connect(function()
                toggled = not toggled
                local targetPos = toggled and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
                local targetBg = toggled and Color3.fromRGB(48, 209, 88) or Color3.fromRGB(220, 220, 225)
                local targetTrans = toggled and 0.25 or 0.6

                local stretchW, stretchH
                if toggled then stretchW = 24 stretchH = 14
                else stretchW = 20 stretchH = 20 end

                TweenService:Create(Knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, stretchW, 0, stretchH), Position = targetPos
                }):Play()
                TweenService:Create(SwitchTrack, TweenInfo.new(0.25), {
                    BackgroundColor3 = targetBg, BackgroundTransparency = targetTrans
                }):Play()
                task.wait(0.12)
                TweenService:Create(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 18, 0, 18)
                }):Play()
                if callback then callback(toggled) end
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
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 10)

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
            Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
            Fill.BackgroundTransparency = 0.25
            Fill.Parent = Track
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

            local Thumb = Instance.new("Frame")
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.Size = UDim2.new(0, 14, 0, 14)
            Thumb.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Thumb.BackgroundTransparency = 0.15
            Thumb.Parent = Track
            Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)

            local function update(input)
                local relativeX = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local newValue = math.floor(min + (max - min) * relativeX)
                value = newValue
                ValLabel.Text = tostring(value)
                Fill.Size = UDim2.new(relativeX, 0, 1, 0)
                Thumb.Position = UDim2.new(relativeX, 0, 0.5, 0)
                if callback then callback(value) end
            end

            SliderFrame.InputBegan:Connect(function(input)
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

        return Tab
    end

    return Window
end

-- =================================================================
-- MENU & TABS
-- =================================================================
local Library = iOS26Glass:CreateWindow("Dragon Nova Hub")

local MainTab   = Library:AddTab("Main")
local ArenaTab  = Library:AddTab("Arena")
local PlayerTab = Library:AddTab("Player")
local MiscTab   = Library:AddTab("Misc")

-- TAB MAIN
MainTab:AddToggle("Bypass Guard/Fly", false, function(val)
    BFFrame.Visible = val
end)

MainTab:AddToggle("Panel Steal Egg Vip", false, function(val)
    VipFrame.Visible = val
    if not val then
        vipShowGui.Enabled = false
        VipShowBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 220)
        if vipIsRunning then
            vipIsRunning = false
            vipStealingUid = nil
            vipStealingCategory = nil
            vipStealingState = nil
            vipAbortWalk()
            VipStealLabel.Text = "STOPPED"
            VipStealLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
end)

MainTab:AddToggle("Auto Steal", autoSteal, function(val) autoSteal = val end)
MainTab:AddToggle("Auto Zone", autoZoneActive, function(val)
    autoZoneActive = val
    if not val then autoZoneState = 0 end
end)

-- TAB ARENA
ArenaTab:AddToggle("Hiện cụm nút Arena", false, function(state)
    ArenaContainer.Visible = state
end)

for _, data in ipairs(miniButtonsData) do
    ArenaTab:AddToggle(data.icon .. " " .. data.id, false, function(state)
        local obj = miniButtonObjects[data.id]
        if obj and obj.btn then
            obj.btn.Visible = state
            if not state and buttonStates[obj.btn] then
                buttonStates[obj.btn] = false
                stopTeleport()
                TweenService:Create(obj.stroke, TweenInfo.new(0.2), {
                    Color = Color3.fromRGB(255, 255, 255)
                }):Play()
            end
        end
    end)
end

-- TAB PLAYER
PlayerTab:AddProfileCard()
PlayerTab:AddSlider("SpeedWalk", 1, 1000, tpWalkSpeed, function(val) tpWalkSpeed = val end)
PlayerTab:AddToggle("Activate", false, function(val) tpWalkActive = val end)
PlayerTab:AddToggle("God mode", godModeEnabled, function(val)
    godModeEnabled = val
    toggleGodMode(val)
end)
PlayerTab:AddToggle("Auto Bat", false, function(val) autoBatActive = val end)
PlayerTab:AddToggle("Anti Stun", antiStun, function(val) antiStun = val end)
PlayerTab:AddToggle("Anti Trap", antiTrapActive, function(val)
    antiTrapActive = val
    if not antiTrapActive then removeTrapESP() end
end)
PlayerTab:AddToggle("Hit box", hitboxActive, function(val)
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

-- TAB MISC
MiscTab:AddSlider("Speed", 10, 1000, speedVal, function(val) speedVal = val end)
MiscTab:AddSlider("Chunk", 1, 100, chunkVal, function(val) chunkVal = val end)
MiscTab:AddButton("Fix lag/boost Fps sẽ xoá những hiệu ứng không cần thiết\nXoá Map sẽ ẩn toàn bộ map GPU giảm tải", function() end)

MiscTab:AddButton("Fix Lag / Boost FPS", function()
    pcall(function()
        local Workspace = game:GetService("Workspace")
        local Lighting = game:GetService("Lighting")

        local function optimize(obj)
            pcall(function()
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                    obj.Enabled = false
                elseif obj:IsA("Explosion") then
                    obj.BlastPressure = 0
                    obj.BlastRadius = 0
                elseif obj:IsA("BasePart") then
                    obj.CastShadow = false
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
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
                if effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") then
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

        for _, obj in ipairs(game:GetDescendants()) do optimize(obj) end

        if not getgenv().FTGS_FixLagConnection then
            getgenv().FTGS_FixLagConnection = game.DescendantAdded:Connect(function(obj)
                task.defer(function() optimize(obj) end)
            end)
        end

        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    end)
end)

local mapHidden = false
local function setBuildHidden(state)
    pcall(function()
        local objects = workspace:FindFirstChild("__OBJECTS")
        if not objects then return end
        local build = objects:FindFirstChild("Build")
        if not build then return end
        if build:IsA("BasePart") then build.LocalTransparencyModifier = state and 1 or 0 end
        for _, obj in ipairs(build:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") then
                    obj.LocalTransparencyModifier = state and 1 or 0
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = state and 1 or 0
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

local deleteMapActive = false
local deleteMapLoopThread = nil

local function runDeleteMapLogic()
    pcall(function()
        if getgenv().DynamicFloorCleanup then getgenv().DynamicFloorCleanup() end

        local floorPart, wallLeft, wallRight, wallFolder = nil, nil, nil, nil
        local heartbeatConnection = nil
        local isEnabled = false

        local function destroyBuildMap()
            pcall(function()
                local world = workspace:FindFirstChild("World")
                if world and world:FindFirstChild("Build") then
                    world.Build:Destroy()
                end
            end)
        end

        local function cleanup()
            isEnabled = false
            if heartbeatConnection then heartbeatConnection:Disconnect() heartbeatConnection = nil end
            if floorPart then floorPart:Destroy() floorPart = nil end
            if wallLeft then wallLeft:Destroy() wallLeft = nil end
            if wallRight then wallRight:Destroy() wallRight = nil end
            if wallFolder then wallFolder:Destroy() wallFolder = nil end
        end
        getgenv().DynamicFloorCleanup = cleanup

        local function enableSystem()
            cleanup()
            isEnabled = true
            destroyBuildMap()

            wallFolder = Instance.new("Folder")
            wallFolder.Name = "Dynamic_200Stud_System"
            wallFolder.Parent = workspace

            floorPart = Instance.new("Part")
            floorPart.Size = Vector3.new(200, 10, 200)
            floorPart.CanCollide = true
            floorPart.Anchored = true
            floorPart.Transparency = 1
            floorPart.Parent = wallFolder

            wallLeft = Instance.new("Part")
            wallLeft.Size = Vector3.new(200, 52, 10)
            wallLeft.CanCollide = true
            wallLeft.Anchored = true
            wallLeft.Transparency = 1
            wallLeft.Parent = wallFolder

            wallRight = Instance.new("Part")
            wallRight.Size = Vector3.new(200, 52, 10)
            wallRight.CanCollide = true
            wallRight.Anchored = true
            wallRight.Transparency = 1
            wallRight.Parent = wallFolder

            heartbeatConnection = RunService.Heartbeat:Connect(function()
                pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp and isEnabled then
                        local charX, charZ = hrp.Position.X, hrp.Position.Z
                        if floorPart and floorPart.Parent then floorPart.CFrame = CFrame.new(charX, 63, charZ) end
                        if charX < 549 then
                            if wallLeft and wallLeft.Parent then wallLeft.CFrame = CFrame.new(charX, -500, -433) end
                            if wallRight and wallRight.Parent then wallRight.CFrame = CFrame.new(charX, -500, -295.5) end
                        else
                            if wallLeft and wallLeft.Parent then wallLeft.CFrame = CFrame.new(charX, 94, -433) end
                            if wallRight and wallRight.Parent then wallRight.CFrame = CFrame.new(charX, 94, -295.5) end
                        end
                    end
                end)
            end)
        end

        enableSystem()
    end)
end

MiscTab:AddToggle("Delete Map", false, function(state)
    deleteMapActive = state
    if state then
        runDeleteMapLogic()
        deleteMapLoopThread = task.spawn(function()
            while deleteMapActive do
                task.wait(300)
                if deleteMapActive then runDeleteMapLogic() end
            end
        end)
    else
        if deleteMapLoopThread then task.cancel(deleteMapLoopThread) deleteMapLoopThread = nil end
        if getgenv().DynamicFloorCleanup then getgenv().DynamicFloorCleanup() end
    end
end)

MiscTab:AddButton("Server NhiiiX-HopSV", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Nhoiii/NhoiiiX-Hub-Dev/refs/heads/main/NhoiiiHopSv.lua"))()
    end)
end)

print("[DragonNova] Loaded | Full iOS26 UI + Minimize fix")