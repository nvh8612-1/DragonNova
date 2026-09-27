-- Delta X - iOS 26 Liquid Glass UI (Dragon Nova Hub)

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
local jailBypassActive = false        -- ⭐ Anti Kẻ Giam Giữ

local tpWalkActive = false
local tpWalkSpeed = 16

local moveMode = "Teleport"
local speedVal = 600
local chunkVal = 12
local baseCFrame = CFrame.new(519.01, 70.27, -362.74)

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
-- MINI ARENA 2x4 - Ở 20% MÀN HÌNH
-- =================================================================
local MiniGui = Instance.new("ScreenGui")
MiniGui.Name = "iOS26_MiniArenaGui"
if gethui then MiniGui.Parent = gethui() else MiniGui.Parent = CoreGui end

local ArenaContainer = Instance.new("Frame")
ArenaContainer.Name = "ArenaContainer"
ArenaContainer.Size = UDim2.new(0, 180, 0, 85)
ArenaContainer.AnchorPoint = Vector2.new(1, 0)
ArenaContainer.Position = UDim2.new(1, -20, 0.2, 0)
ArenaContainer.BackgroundTransparency = 1
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
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end
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
                                    TweenService:Create(miniStrokes[sourceBtn], TweenInfo.new(0.2), {
                                        Color = Color3.fromRGB(255, 255, 255)
                                    }):Play()
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
                TweenService:Create(miniStrokes[sourceBtn], TweenInfo.new(0.2), {
                    Color = Color3.fromRGB(255, 255, 255)
                }):Play()
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
        TweenService:Create(otherStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(255, 255, 255)
        }):Play()
    end
    buttonStates[obj.btn] = true
    TweenService:Create(obj.stroke, TweenInfo.new(0.2), {
        Color = Color3.fromRGB(48, 209, 88)
    }):Play()
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
    miniButtonObjects[data.id] = { btn = btn, stroke = stroke, data = data }

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
            startMovement(data.xyz, btn)
        else
            TweenService:Create(stroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(255, 255, 255)
            }):Play()
            stopTeleport()
        end
    end)
end

-- =================================================================
-- AUTO SECRET / ETERNAL / DIVINE
-- =================================================================
local rareEggActive = false

local RARE_EGG_LIST = {
    ["King Snake"] = "Secret", ["Yeti"] = "Secret", ["Cerberus"] = "Secret",
    ["Kraken"] = "Secret", ["T-Rex"] = "Secret", ["Tralaledon"] = "Secret",
    ["Cosmic Skeleton Boss"] = "Secret", ["Cosmic Dragon"] = "Secret",
    ["Stag"] = "Secret", ["Mutant Shark"] = "Secret", ["Pure Jellyfish"] = "Secret",
    ["Centaur"] = "Secret",
    ["Ice Dragon"] = "Eternal", ["Phoenix"] = "Eternal", ["Lava Dragon"] = "Eternal",
    ["El Maja"] = "Eternal", ["Mosasaurus"] = "Eternal", ["Eternal Lunar Dragon"] = "Eternal",
    ["Oni Tiger"] = "Eternal", ["Gorilla King"] = "Eternal", ["Pegasus"] = "Eternal",
    ["Unicorn"] = "Divine", ["Kitsune"] = "Divine", ["Nightflame"] = "Divine",
    ["ArchAngel"] = "Divine", ["World Burner"] = "Divine",
}

local RARE_RANK = { ["Divine"] = 3, ["Eternal"] = 2, ["Secret"] = 1 }
local RARE_SPEED = 400
local RARE_ARRIVE = 5
local MATCH_RADIUS = 10
local WAIT_BEFORE_SECOND = 2.7
local STUN_TIMEOUT = 5

local rareEggList = {}
local rareLocked = nil
local rareProcessing = nil
local rareProcessed = {}
local rareActiveToken = 0
local rareActiveTween = nil
local originalStates = {}

local function findRemoteByName(keyword, classType)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if classType and obj:IsA(classType) then
            if obj.Name:find(keyword, 1, true) then return obj end
        elseif not classType and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
            if obj.Name:find(keyword, 1, true) then return obj end
        end
    end
    return nil
end

local RareSnapshot = findRemoteByName("AskFieldEggSnapshot", "RemoteFunction")
local RareShifted  = findRemoteByName("FieldEggShifted", "RemoteEvent")
local RareCarry    = findRemoteByName("FieldEggCarry", "RemoteEvent")
local RareGone     = findRemoteByName("FieldEggGone", "RemoteEvent")
local RareBatch    = findRemoteByName("FieldEggBatchShifted", "RemoteEvent")

local function updateRareRecord(data)
    if typeof(data) ~= "table" or not data.Uid then return end
    rareEggList[data.Uid] = rareEggList[data.Uid] or {}
    rareEggList[data.Uid].category = data.AssetCategory
    rareEggList[data.Uid].state = data.State
    rareEggList[data.Uid].cframe = data.BoundsCFrame
end

local function takeRareSnapshot()
    if not RareSnapshot then return end
    local ok, result = pcall(function() return RareSnapshot:InvokeServer() end)
    if not ok or typeof(result) ~= "table" then return end
    local records = result.Records
    if typeof(records) ~= "table" then return end
    for _, rec in ipairs(records) do updateRareRecord(rec) end
end

if RareShifted then RareShifted.OnClientEvent:Connect(updateRareRecord) end
if RareBatch then
    RareBatch.OnClientEvent:Connect(function(batch)
        if typeof(batch) == "table" then
            for _, rec in ipairs(batch) do updateRareRecord(rec) end
        end
    end)
end
if RareCarry then
    RareCarry.OnClientEvent:Connect(function(data)
        if typeof(data) == "table" and data.Uid and rareEggList[data.Uid] then
            rareEggList[data.Uid].state = data.IsCarrying and "Carried" or nil
        end
    end)
end
if RareGone then
    RareGone.OnClientEvent:Connect(function(uid)
        if uid then rareEggList[uid] = nil rareProcessed[uid] = nil end
    end)
end

local function getRareRank(cat)
    if not cat then return nil end
    return RARE_EGG_LIST[cat]
end

local function isRareTarget(uid)
    local info = rareEggList[uid]
    if not info then return false end
    if info.state == "Carried" or info.state == "GuardCarried" then return false end
    if not info.cframe then return false end
    if rareProcessed[uid] then return false end
    if not getRareRank(info.category) then return false end
    return true
end

local function pickRareEgg()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end

    local myPos = hrp.Position
    local candidates = {}
    for uid, info in pairs(rareEggList) do
        if isRareTarget(uid) and info.cframe then
            local d = (info.cframe.Position - myPos).Magnitude
            local prio = RARE_RANK[getRareRank(info.category)] or 0
            table.insert(candidates, { uid = uid, cf = info.cframe, dist = d, prio = prio })
        end
    end
    if #candidates == 0 then return nil, nil end
    table.sort(candidates, function(a, b)
        if a.prio ~= b.prio then return a.prio > b.prio end
        return a.dist < b.dist
    end)
    return candidates[1].uid, candidates[1].cf
end

local function cancelRareTween()
    rareActiveToken = rareActiveToken + 1
    if rareActiveTween then
        pcall(function() rareActiveTween:Cancel() end)
        rareActiveTween = nil
    end
    rareLocked = nil
end

local function tweenRare(targetCF)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not targetCF then return end
    local dist = (targetCF.Position - hrp.Position).Magnitude
    if dist < RARE_ARRIVE then rareActiveTween = nil return end

    rareActiveToken = rareActiveToken + 1
    local myToken = rareActiveToken
    rareActiveTween = TweenService:Create(hrp, TweenInfo.new(dist / RARE_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = targetCF})
    rareActiveTween:Play()
    rareActiveTween.Completed:Connect(function()
        if rareActiveToken == myToken then rareActiveTween = nil end
    end)
end

local function fireRarePrompt(eggCF)
    local nearest, minD = nil, MATCH_RADIUS
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Name == "CarryAreaEgg" then
            local p = obj.Parent
            if p and p:IsA("BasePart") then
                local d = (p.Position - eggCF.Position).Magnitude
                if d < minD then minD = d nearest = obj end
            end
        end
    end
    if not nearest then return end
    nearest.Enabled = true
    if fireproximityprompt then pcall(fireproximityprompt, nearest) end
end

local function waitForStun(timeout)
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local startTime = os.clock()
    while os.clock() - startTime < timeout do
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.PlatformStanding then
            return true
        end
        task.wait(0.05)
    end
    return false
end

local function doRareSequence(uid, eggCF)
    rareProcessing = uid
    rareProcessed[uid] = true

    local cam = workspace.CurrentCamera
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then rareProcessing = nil return end

    local savedPos = hrp.Position
    local saveType = cam.CameraType
    local saveCF = cam.CFrame
    local saveSubj = cam.CameraSubject
    local saveFOV = cam.FieldOfView

    local eyePos = eggCF.Position + Vector3.new(0, 8, 0)
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(eyePos, eggCF.Position)
    cam.FieldOfView = 40

    task.wait(0.2)
    fireRarePrompt(eggCF)
    waitForStun(STUN_TIMEOUT)

    local cChar = LocalPlayer.Character
    if cChar then
        local cHrp = cChar:FindFirstChild("HumanoidRootPart")
        if cHrp then cHrp.CFrame = CFrame.new(savedPos) end
    end

    task.wait(WAIT_BEFORE_SECOND)
    fireRarePrompt(eggCF)

    if cam and cam.Parent then
        cam.CameraType = saveType
        cam.CameraSubject = saveSubj
        cam.CFrame = saveCF
        cam.FieldOfView = saveFOV
    end

    task.wait(0.2)
    task.spawn(function() triggerMiniButtonByName("Base") end)
    task.wait(0.3)
    rareProcessing = nil
    rareLocked = nil
end

local function rareStep()
    if rareProcessing then return true end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if rareActiveTween and rareActiveTween.PlaybackState == Enum.PlaybackState.Playing then
        if rareLocked and rareEggList[rareLocked] then return true end
        cancelRareTween()
    end

    local uid, cf = pickRareEgg()
    if not uid or not cf then
        if rareLocked then cancelRareTween() end
        return false
    end

    local dist = (cf.Position - hrp.Position).Magnitude
    if dist < RARE_ARRIVE + 4 then
        task.spawn(function() doRareSequence(uid, cf) end)
        return true
    end

    rareLocked = uid
    tweenRare(cf)
    return true
end

-- =================================================================
-- ANTI KẺ GIAM GIỮ (SPEED CARRY BYPASS)
-- =================================================================
local JAIL_BASE_CF = CFrame.new(519.01, 70.27, -362.74)
local JAIL_STEP = 5000
local JAIL_MAX_ITER = 21
local JAIL_HOLD_TIME = 2.0
local JAIL_MAX_RETRY = 2
local JAIL_RETRY_DELAY = 0.4

local jailIsCarrying = false
local jailBypassRunning = false
local jailPhysicsLocked = false
local jailSavedCamType = nil
local jailSavedCamSubject = nil
local jailSavedPhysics = {}

local function findJailRemote(keyword, class)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA(class) and obj.Name:find(keyword, 1, true) then
            return obj
        end
    end
    return nil
end

local JailCarryRE = findJailRemote("FieldEggCarry", "RemoteEvent")

local function jailLockCamera()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if jailSavedCamType then return end
    jailSavedCamType = cam.CameraType
    jailSavedCamSubject = cam.CameraSubject
    cam.CameraType = Enum.CameraType.Scriptable
end

local function jailUnlockCamera()
    if not jailSavedCamType then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    cam.CameraType = jailSavedCamType or Enum.CameraType.Custom
    cam.CameraSubject = jailSavedCamSubject
    jailSavedCamType = nil
    jailSavedCamSubject = nil
end

local function jailDisablePhysics(char, hum, hrp)
    if not hum or not hrp or jailPhysicsLocked then return end
    jailPhysicsLocked = true
    jailSavedPhysics = {
        walkSpeed = hum.WalkSpeed,
        jumpPower = hum.JumpPower,
        platformStand = hum.PlatformStand,
        autoRotate = hum.AutoRotate,
    }
    pcall(function()
        hum.PlatformStand = true
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        hum.AutoRotate = false
    end)
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    end)
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end)
end

local function jailRestorePhysics(hum)
    if not jailPhysicsLocked then return end
    jailPhysicsLocked = false
    if not hum then return end
    pcall(function()
        hum.PlatformStand = jailSavedPhysics.platformStand or false
        hum.WalkSpeed = jailSavedPhysics.walkSpeed or 16
        hum.JumpPower = jailSavedPhysics.jumpPower or 50
        hum.AutoRotate = jailSavedPhysics.autoRotate or true
    end)
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    end)
end

local function jailZeroVelocity(hrp)
    if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
end

local function jailTeleportOnce(char, hrp)
    local iter = 0
    while iter < JAIL_MAX_ITER do
        iter = iter + 1
        jailZeroVelocity(hrp)
        local myPos = hrp.Position
        local dir = JAIL_BASE_CF.Position - myPos
        local d = dir.Magnitude
        if d < 5 then
            hrp.CFrame = JAIL_BASE_CF
            break
        end
        hrp.CFrame = CFrame.new(myPos + dir.Unit * math.min(d, JAIL_STEP))
        RunService.Heartbeat:Wait()
    end
    return iter
end

local function jailHoldAtBase(char)
    local holdStart = os.clock()
    local serverKicked = false
    while os.clock() - holdStart < JAIL_HOLD_TIME do
        RunService.Heartbeat:Wait()
        local cHrp = char:FindFirstChild("HumanoidRootPart")
        if not cHrp then break end
        jailZeroVelocity(cHrp)
        if (cHrp.Position - JAIL_BASE_CF.Position).Magnitude > 100 then
            serverKicked = true
            break
        end
        cHrp.CFrame = JAIL_BASE_CF
    end
    return not serverKicked
end

local function jailSpeedCarryBypass()
    if jailBypassRunning then return end
    jailBypassRunning = true
    if not jailIsCarrying then jailBypassRunning = false return end

    local char = LocalPlayer.Character
    if not char then jailBypassRunning = false return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then jailBypassRunning = false return end

    jailLockCamera()
    jailDisablePhysics(char, hum, hrp)

    for retry = 1, JAIL_MAX_RETRY do
        if not jailIsCarrying then break end
        char = LocalPlayer.Character
        hrp = char and char:FindFirstChild("HumanoidRootPart")
        hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then break end

        jailTeleportOnce(char, hrp)
        if jailHoldAtBase(char) then break end
        task.wait(JAIL_RETRY_DELAY)
    end

    hum = char and char:FindFirstChildOfClass("Humanoid")
    jailRestorePhysics(hum)
    hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then jailZeroVelocity(hrp) end
    jailUnlockCamera()
    jailBypassRunning = false
end

if JailCarryRE then
    JailCarryRE.OnClientEvent:Connect(function(data)
        if typeof(data) ~= "table" then return end
        if data.IsCarrying == true and data.Uid then
            jailIsCarrying = true
            if jailBypassActive and not jailBypassRunning then
                task.spawn(jailSpeedCarryBypass)
            end
        elseif data.IsCarrying == false then
            jailIsCarrying = false
        end
    end)
end

task.spawn(function()
    local wasCarrying = false
    while true do
        task.wait(0.05)
        if jailBypassActive and jailIsCarrying and not wasCarrying and not jailBypassRunning then
            task.spawn(jailSpeedCarryBypass)
        end
        wasCarrying = jailIsCarrying
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
    if descendant:IsA("ProximityPrompt") then
        bypassPrompt(descendant, 25)
    end
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
        if string.lower(part.Name) == "hitbox" then
            part.Size = Vector3.new(0.001, 0.001, 0.001)
        end
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
        for _, desc in ipairs(child:GetDescendants()) do
            if desc:IsA("BasePart") then disableTrapPart(desc) end
        end
        if child:IsA("BasePart") then disableTrapPart(child) end
    end
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
-- SPEED CARRY GUI (ẨN MẶC ĐỊNH, HIỆN KHI BẬT TOGGLE)
-- =================================================================
local speedCarryGui = Instance.new("ScreenGui")
speedCarryGui.Name = "SpeedCarryGUI"
speedCarryGui.ResetOnSpawn = false
if gethui then speedCarryGui.Parent = gethui() else speedCarryGui.Parent = CoreGui end

local SCFrame = Instance.new("Frame")
SCFrame.Name = "SpeedCarryFrame"
SCFrame.Size = UDim2.new(0, 280, 0, 130)
SCFrame.Position = UDim2.new(0, 20, 0.5, -65)
SCFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
SCFrame.BorderSizePixel = 0
SCFrame.Visible = false                     -- ⭐ Ẩn mặc định
SCFrame.Parent = speedCarryGui

local SC_FC = Instance.new("UICorner")
SC_FC.CornerRadius = UDim.new(0, 12)
SC_FC.Parent = SCFrame

local SC_FS = Instance.new("UIStroke")
SC_FS.Thickness = 2
SC_FS.Color = Color3.fromRGB(100, 200, 255)
SC_FS.Parent = SCFrame

local SCToggle = Instance.new("TextButton")
SCToggle.Size = UDim2.new(1, -12, 0, 44)
SCToggle.Position = UDim2.new(0, 6, 0, 6)
SCToggle.BackgroundColor3 = Color3.fromRGB(48, 209, 88)
SCToggle.Text = "ANTI KẺ GIAM GIỮ [V]"
SCToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SCToggle.Font = Enum.Font.GothamBold
SCToggle.TextSize = 12
SCToggle.AutoButtonColor = false
SCToggle.Parent = SCFrame

local SC_BC = Instance.new("UICorner")
SC_BC.CornerRadius = UDim.new(0, 8)
SC_BC.Parent = SCToggle

local SCStatus = Instance.new("TextLabel")
SCStatus.Size = UDim2.new(1, -12, 0, 16)
SCStatus.Position = UDim2.new(0, 6, 1, -60)
SCStatus.BackgroundTransparency = 1
SCStatus.Text = "OFF"
SCStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
SCStatus.Font = Enum.Font.GothamBold
SCStatus.TextSize = 10
SCStatus.Parent = SCFrame

local SCCarry = Instance.new("TextLabel")
SCCarry.Size = UDim2.new(1, -12, 0, 16)
SCCarry.Position = UDim2.new(0, 6, 1, -42)
SCCarry.BackgroundTransparency = 1
SCCarry.Text = "Chờ cầm trứng..."
SCCarry.TextColor3 = Color3.fromRGB(150, 200, 255)
SCCarry.Font = Enum.Font.Gotham
SCCarry.TextSize = 10
SCCarry.Parent = SCFrame

local SCInfo = Instance.new("TextLabel")
SCInfo.Size = UDim2.new(1, -12, 0, 16)
SCInfo.Position = UDim2.new(0, 6, 1, -24)
SCInfo.BackgroundTransparency = 1
SCInfo.Text = "Khóa physics 2s + Retry x" .. JAIL_MAX_RETRY
SCInfo.TextColor3 = Color3.fromRGB(255, 220, 150)
SCInfo.Font = Enum.Font.Gotham
SCInfo.TextSize = 9
SCInfo.Parent = SCFrame

local SCWarn = Instance.new("TextLabel")
SCWarn.Size = UDim2.new(1, -12, 0, 14)
SCWarn.Position = UDim2.new(0, 6, 1, -8)
SCWarn.BackgroundTransparency = 1
SCWarn.Text = "Tự mở khóa sau 2s"
SCWarn.TextColor3 = Color3.fromRGB(255, 150, 100)
SCWarn.Font = Enum.Font.Gotham
SCWarn.TextSize = 8
SCWarn.Parent = SCFrame

task.spawn(function()
    while true do
        task.wait(0.3)
        if jailBypassRunning then
            SCCarry.Text = "ĐANG BYPASS..."
            SCCarry.TextColor3 = Color3.fromRGB(255, 200, 100)
        elseif jailIsCarrying then
            SCCarry.Text = "ĐANG CẦM TRỨNG"
            SCCarry.TextColor3 = Color3.fromRGB(48, 209, 88)
        else
            SCCarry.Text = "Chờ cầm trứng..."
            SCCarry.TextColor3 = Color3.fromRGB(150, 200, 255)
        end
    end
end)

SCToggle.MouseButton1Click:Connect(function()
    jailBypassActive = not jailBypassActive
    if jailBypassActive then
        SCToggle.Text = "STOP [V]"
        SCToggle.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        SCStatus.Text = "ON - Khóa physics 2s"
        SCStatus.TextColor3 = Color3.fromRGB(48, 209, 88)
    else
        SCToggle.Text = "ANTI KẺ GIAM GIỮ [V]"
        SCToggle.BackgroundColor3 = Color3.fromRGB(48, 209, 88)
        SCStatus.Text = "OFF"
        SCStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
        jailUnlockCamera()
        jailRestorePhysics(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"))
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.V then
        if SCFrame.Visible then SCToggle.MouseButton1Click:Fire() end
    end
end)

local scDragging, scDragStart, scStartPos
SCFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        scDragging = true
        scDragStart = input.Position
        scStartPos = SCFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then scDragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if scDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - scDragStart
        SCFrame.Position = UDim2.new(scStartPos.X.Scale, scStartPos.X.Offset + delta.X, scStartPos.Y.Scale, scStartPos.Y.Offset + delta.Y)
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
    local openPosition = UDim2.new(0.5, -261, 0.1, 0)
    local islandSize = UDim2.new(0, 160, 0, 34)
    local islandPosition = UDim2.new(0.5, -80, 0.05, 0)

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

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(1, 0)
    MinCorner.Parent = MinimizeBtn

    enableDragging(TopBar, MainFrame)
    enableDragging(MainFrame, MainFrame)

    local Sidebar = Instance.new("Frame")
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

    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = AvatarImage

    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Thickness = 1
    AvatarStroke.Color = Color3.fromRGB(255, 255, 255)
    AvatarStroke.Transparency = 0.65
    AvatarStroke.Parent = AvatarImage

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
            { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0.5, -9, 0.05, 0) })

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
            { Size = UDim2.new(0, 176, 0, 44), Position = UDim2.new(0.5, -88, 0.05, 0) })

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

            local PCorner = Instance.new("UICorner")
            PCorner.CornerRadius = UDim.new(0, 10)
            PCorner.Parent = ProfileFrame

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

            local CircleCorner = Instance.new("UICorner")
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = CircleAvatar

            local CircleStroke = Instance.new("UIStroke")
            CircleStroke.Thickness = 1.5
            CircleStroke.Color = Color3.fromRGB(255, 255, 255)
            CircleStroke.Transparency = 0.5
            CircleStroke.Parent = CircleAvatar

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

            local Corner = Instance.new("UICorner")
            Corner.CornerRadius = UDim.new(0, 10)
            Corner.Parent = BtnFrame

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
            SwitchTrack.BackgroundColor3 = toggled and Color3.fromRGB(48, 209, 88) or Color3.fromRGB(220, 220, 225)
            SwitchTrack.BackgroundTransparency = toggled and 0.25 or 0.6
            SwitchTrack.Parent = ToggleFrame

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = SwitchTrack

            local Knob = Instance.new("Frame")
            Knob.AnchorPoint = Vector2.new(0.5, 0.5)
            Knob.Size = UDim2.new(0, 18, 0, 18)
            Knob.Position = toggled and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
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
            Fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
            Fill.BackgroundTransparency = 0.25
            Fill.Parent = Track

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = Fill

            local Thumb = Instance.new("Frame")
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.Size = UDim2.new(0, 14, 0, 14)
            Thumb.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Thumb.BackgroundTransparency = 0.15
            Thumb.Parent = Track

            local ThumbCorner = Instance.new("UICorner")
            ThumbCorner.CornerRadius = UDim.new(1, 0)
            ThumbCorner.Parent = Thumb

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

-- =================================================================
-- TAB MAIN
-- ⭐ ANTI KẺ GIAM GIỮ ĐẦU TIÊN
-- =================================================================
MainTab:AddToggle("Anti Kẻ Giam Giữ", false, function(val)
    jailBypassActive = val
    -- Chỉ ẩn/hiện menu Speed Carry, không hủy chức năng
    SCFrame.Visible = val
    print("[JailBypass] Menu " .. (val and "HIỆN" or "ẨN"))
end)

MainTab:AddToggle("Auto Secret/Eternal/Divine", false, function(val)
    rareEggActive = val
    if val then
        rareProcessed = {}
        rareEggList = {}
        task.spawn(takeRareSnapshot)
        task.spawn(function()
            local startTime = os.clock()
            local idleCount = 0
            while rareEggActive do
                if os.clock() - startTime > 600 then break end
                pcall(takeRareSnapshot)
                local has = false
                pcall(function() has = rareStep() end)
                if not has and not rareProcessing and not rareActiveTween then
                    idleCount = idleCount + 1
                    if idleCount >= 60 then break end
                else
                    idleCount = 0
                end
                task.wait(0.5)
            end
            rareEggActive = false
            cancelRareTween()
            rareProcessing = nil
        end)
    else
        cancelRareTween()
        rareProcessing = nil
    end
end)

MainTab:AddToggle("Auto Steal", autoSteal, function(val) autoSteal = val end)
MainTab:AddToggle("Auto Zone", autoZoneActive, function(val)
    autoZoneActive = val
    if not val then autoZoneState = 0 end
end)

-- TAB ARENA
ArenaTab:AddToggle("Hiện cụm nút Arena", true, function(state) ArenaContainer.Visible = state end)
for _, data in ipairs(miniButtonsData) do
    ArenaTab:AddToggle(data.icon .. " " .. data.id, true, function(state)
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

MiscTab:AddButton("Server NhiiiX-HopSV", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Nhoiii/NhoiiiX-Hub-Dev/refs/heads/main/NhoiiiHopSv.lua"))()
    end)
end)

print("[DragonNova] Loaded | Anti Jail bypass menu | No Dr Scramble")
