-- Delta X - iOS 26 Liquid Glass UI (Dragon Nova Hub - Full Tween & Teleport Engine)

local iOS26Glass = {}

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

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
local drScrambleActive = false

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
-- MINI ARENA 2x4
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
    { id = "Base",     icon = "🏠",   col = 0, row = 0, xyz = baseCFrame or CFrame.new(519.01, 70.27, -362.74) },
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

    local currentPos = hrp.Position
    local targetPos = targetCF.Position
    local distance = (targetPos - currentPos).Magnitude

    if moveMode == "Teleport" then
        task.spawn(function()
            while activeTeleportToken == currentToken and targetCF do
                pcall(function()
                    local cChar = LocalPlayer.Character
                    if cChar then
                        local cHrp = cChar:FindFirstChild("HumanoidRootPart")
                        if cHrp then
                            local cPos = cHrp.Position
                            local tPos = targetCF.Position
                            local dir = (tPos - cPos)
                            local dist = dir.Magnitude
                            local stepDist = chunkVal or 12

                            if dist > stepDist then
                                cHrp.CFrame = CFrame.new(cPos + (dir.Unit * stepDist))
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

                local speed = speedVal or 600
                local delayTime = math.clamp(1 / (speed / 15), 0.001, 0.1)
                task.wait(delayTime)
            end
        end)
    elseif moveMode == "Tween" then
        local flySpeed = math.max(speedVal, 10)
        local timeToReach = distance / flySpeed

        local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

        activeTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCF})
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
-- DR SCRAMBLE - CHỈ CHẠY KHI TOGGLE BẬT
-- Kích hoạt tại 30:03 hoặc 00:03 (giờ VN +7)
-- =================================================================
local SCRAMBLE_SPEED  = 400
local STATIC_TIMEOUT  = 1.0
local MOVE_THRESHOLD  = 0.1

local VOLCANO_CF      = CFrame.new(1878, 70, -395)
local VOLCANO_ARRIVE  = 5

local drToken         = 0
local drTween         = nil
local lockedTarget    = nil

local cycleActive     = false
local volcanoArrived  = false
local lastCycleMinute = -1

local targetStates = {}

local function getObjectCFrame(targetObj)
    if not targetObj then return nil end
    if targetObj:IsA("Model") then
        return targetObj:GetPivot()
    elseif targetObj:IsA("BasePart") then
        return targetObj.CFrame
    end
    return nil
end

local function isScrambleTargetValid(obj)
    if not obj then return false end
    if not obj.Parent then return false end
    if not obj:IsDescendantOf(workspace) then return false end
    return true
end

local function updateTargetState(obj)
    if not obj then return false end
    local state = targetStates[obj]
    local currentCF = getObjectCFrame(obj)
    if not currentCF then return false end

    if not state then
        targetStates[obj] = { lastCFrame = currentCF, lastMoveTime = os.clock() }
        return true
    end

    local posDiff = (currentCF.Position - state.lastCFrame.Position).Magnitude
    local rotDiff = (currentCF.LookVector - state.lastCFrame.LookVector).Magnitude

    if posDiff > MOVE_THRESHOLD or rotDiff > 0.01 then
        state.lastCFrame = currentCF
        state.lastMoveTime = os.clock()
        return true
    end

    if (os.clock() - state.lastMoveTime) > STATIC_TIMEOUT then
        return false
    end
    return true
end

local function findScrambleTarget()
    local folder = workspace:FindFirstChild("ScrambleLocalVisuals")
    if not folder then return nil end

    local prefixes = { "PersonalDrone_", "DroneVisual_" }
    local candidates = {}

    for _, prefix in ipairs(prefixes) do
        for _, child in ipairs(folder:GetChildren()) do
            if child.Name ~= "DrScrambleVFX" then
                if child.Name:sub(1, #prefix) == prefix then
                    table.insert(candidates, child)
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    local dynamicTarget = nil
    local fallbackTarget = nil

    for _, obj in ipairs(candidates) do
        if updateTargetState(obj) then
            if not dynamicTarget then dynamicTarget = obj end
        else
            if not fallbackTarget then fallbackTarget = obj end
        end
    end

    return dynamicTarget or fallbackTarget
end

local function stopDrScramble()
    drToken = drToken + 1
    if drTween then
        pcall(function() drTween:Cancel() end)
        drTween = nil
    end
end

local function getCharHrp()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function tweenTo(targetCF)
    local hrp = getCharHrp()
    if not hrp or not targetCF then return nil end

    local dist = (hrp.Position - targetCF.Position).Magnitude
    if dist < 3 then return nil end

    drToken = drToken + 1
    local myToken = drToken

    local timeToReach = dist / math.max(SCRAMBLE_SPEED, 10)

    drTween = TweenService:Create(
        hrp,
        TweenInfo.new(timeToReach, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {CFrame = targetCF}
    )
    drTween:Play()

    drTween.Completed:Connect(function()
        if drToken == myToken then
            drTween = nil
        end
    end)

    return myToken
end

local function goToVolcano()
    local hrp = getCharHrp()
    if not hrp then return end

    local dist = (hrp.Position - VOLCANO_CF.Position).Magnitude
    if dist <= VOLCANO_ARRIVE then
        volcanoArrived = true
        return
    end

    if drTween and drTween.PlaybackState == Enum.PlaybackState.Playing then
        return
    end

    volcanoArrived = false
    tweenTo(VOLCANO_CF)
end

local function goToDrone()
    if lockedTarget and isScrambleTargetValid(lockedTarget) then
        if not updateTargetState(lockedTarget) then
            lockedTarget = nil
        end
    else
        lockedTarget = nil
    end

    if not lockedTarget then
        lockedTarget = findScrambleTarget()
        if not lockedTarget then return end
    end

    local targetCF = getObjectCFrame(lockedTarget)
    if not targetCF then return end

    tweenTo(targetCF)
end

-- Lấy giờ VN (+7), trả về min, sec
local function getTimeVN()
    local t = os.date("!*t", os.time() + 7 * 3600)
    return t.min, t.sec
end

task.spawn(function()
    while true do
        task.wait(0.1)

        if not drScrambleActive then
            if cycleActive or drTween or lockedTarget then
                stopDrScramble()
                lockedTarget = nil
                targetStates = {}
                cycleActive = false
                volcanoArrived = false
                lastCycleMinute = -1
            end
            task.wait(0.3)
            continue
        end

        pcall(function()
            local currentMin, currentSec = getTimeVN()

            -- Reset khi ra khỏi phút 30/0
            if currentMin ~= 30 and currentMin ~= 0 then
                cycleActive = false
                lastCycleMinute = -1
            end

            -- Phát hiện 30:03 hoặc 00:03
            if (currentMin == 30 or currentMin == 0) and currentSec == 3 and lastCycleMinute ~= currentMin then
                lastCycleMinute = currentMin
                cycleActive = true
                volcanoArrived = false
                stopDrScramble()
                lockedTarget = nil
                goToVolcano()
                return
            end

            if cycleActive then
                if not volcanoArrived then
                    goToVolcano()
                    return
                else
                    if drTween and drTween.PlaybackState == Enum.PlaybackState.Playing then
                        return
                    end
                    goToDrone()
                    return
                end
            end

            if drTween and drTween.PlaybackState == Enum.PlaybackState.Playing then
                if lockedTarget and isScrambleTargetValid(lockedTarget) then
                    updateTargetState(lockedTarget)
                end
                return
            end

            goToDrone()
        end)
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        for obj in pairs(targetStates) do
            if not obj or not obj.Parent then
                targetStates[obj] = nil
            end
        end
    end
end)

getgenv().DrScrambleKick = function()
    task.spawn(function()
        pcall(goToDrone)
    end)
end

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
        if newState == Enum.HumanoidStateType.Physics
            or newState == Enum.HumanoidStateType.Ragdoll
            or newState == Enum.HumanoidStateType.FallingDown
            or newState == Enum.HumanoidStateType.PlatformStanding then
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
-- GOD MODE
-- =================================================================
local godModeEnabled = false

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
    elseif parent:IsA("Model") then return parent:GetPivot().Position
    end
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
local knockbackRunning = false
local knockbackConn    = nil
local lastStableCFrame = nil

local function isBadState(state)
    return state == Enum.HumanoidStateType.Physics
        or state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.PlatformStanding
end

local function startAntiKnockback(char, hum, hrp)
    if knockbackRunning then return end
    knockbackRunning = true
    lastStableCFrame = hrp.CFrame

    knockbackConn = RunService.Heartbeat:Connect(function()
        if not char or not char.Parent then
            if knockbackConn then
                knockbackConn:Disconnect()
                knockbackConn = nil
            end
            knockbackRunning = false
            return
        end

        local cHrp = char:FindFirstChild("HumanoidRootPart")
        local cHum = char:FindFirstChildOfClass("Humanoid")
        if not cHrp or not cHum then return end

        cHrp.AssemblyLinearVelocity  = Vector3.zero
        cHrp.AssemblyAngularVelocity = Vector3.zero
        cHrp.Velocity    = Vector3.zero
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
            if motor:IsA("Motor6D") and not motor.Enabled then
                motor.Enabled = true
            end
        end
    end)
end

local function stopAntiKnockback()
    if knockbackConn then
        knockbackConn:Disconnect()
        knockbackConn = nil
    end
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
                if newState == Enum.HumanoidStateType.Running
                    or newState == Enum.HumanoidStateType.RunningNoPhysics
                    or newState == Enum.HumanoidStateType.Landed
                    or newState == Enum.HumanoidStateType.GettingUp then
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
                if motor:IsA("Motor6D") and not motor.Enabled then
                    motor.Enabled = true
                end
            end
            if hum.Sit then hum.Sit = false end
            if hum.PlatformStand then hum.PlatformStand = false end
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
        pcall(function()
            if highlight then highlight:Destroy() end
        end)
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
            if child:IsA("TouchTransmitter") or child.ClassName == "TouchInterest" then
                child:Destroy()
            end
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
-- AUTO BAT - CHUYỂN TOOL 0.3s + SPAM M1 0s
-- =================================================================
local function fireAutoBatM1(tool)
    if not tool or not tool.Parent then return end

    pcall(function() tool:Activate() end)

    if getconnections then
        for _, sig in ipairs({
            tool.Activated,
            tool.MouseButton1Click,
            tool.MouseButton1Down,
        }) do
            pcall(function()
                for _, conn in ipairs(getconnections(sig)) do
                    if conn.Fire then conn:Fire() end
                end
            end)
        end
    end

    for _, desc in ipairs(tool:GetDescendants()) do
        pcall(function()
            if desc:IsA("RemoteEvent") then
                desc:FireServer()
            elseif desc:IsA("RemoteFunction") then
                desc:InvokeServer()
            elseif desc:IsA("BindableEvent") then
                desc:Fire()
            elseif desc:IsA("ClickDetector") and getconnections then
                for _, conn in ipairs(getconnections(desc.MouseClick)) do
                    if conn.Fire then conn:Fire() end
                end
            end
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
            if tool:IsA("Tool") then
                if tool.Name == scramblerName or tool:FindFirstChild("HitAnim") then
                    table.insert(list, tool)
                end
            end
        end
    end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name == scramblerName or tool:FindFirstChild("HitAnim") then
                local dup = false
                for _, t in ipairs(list) do
                    if t == tool then dup = true break end
                end
                if not dup then table.insert(list, tool) end
            end
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
        if not humanoid or humanoid.Health <= 0 then
            task.wait(0.3)
            continue
        end

        local tools = collectAutoBatTools()
        if #tools == 0 then
            task.wait(0.4)
            continue
        end

        if currentIndex > #tools then currentIndex = 1 end

        local targetTool = tools[currentIndex]
        if not targetTool or not targetTool.Parent then
            currentIndex = 1
            task.wait(0.1)
            continue
        end

        local now = os.clock()

        if now - lastSwapTime >= SWAP_INTERVAL then
            lastSwapTime = now

            if targetTool.Parent ~= char then
                pcall(function()
                    humanoid:EquipTool(targetTool)
                end)
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

        if equippedTool then
            pcall(function()
                fireAutoBatM1(equippedTool)
            end)
        end

        RunService.Heartbeat:Wait()
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

    -- Title dùng RichText: chữ gốc + giờ VN inline 30%
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
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
        if isAnimating or isMinimized then return end
        isAnimating = true

        Sidebar.Visible = false
        ContentContainer.Visible = false
        TopBar.Visible = false

        local dotTween = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0.5, -9, 0, 15) }
        )

        TweenService:Create(MainCorner, TweenInfo.new(0.25), { CornerRadius = UDim.new(1, 0) }):Play()
        dotTween:Play()
        dotTween.Completed:Wait()

        local expandIsland = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = islandSize, Position = islandPosition }
        )

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

        local swellTween = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 176, 0, 44), Position = UDim2.new(0.5, -88, 0, 15) }
        )

        swellTween:Play()
        swellTween.Completed:Wait()

        local menuTween = TweenService:Create(
            MainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Size = originalSize, Position = openPosition }
        )

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

        if not Window.ActiveTab then
            activate()
            Window.ActiveTab = TabContent
        end

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
                local content, isLoaded = Players:GetUserThumbnailAsync(
                    LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size420x420
                )
                if isLoaded and content then CircleAvatar.Image = content end
            end)

            local NameLabelLine = Instance.new("TextLabel")
            NameLabelLine.Size = UDim2.new(1, -52, 0, 16)
            NameLabelLine.Position = UDim2.new(0, 48, 0, 8)
            NameLabelLine.BackgroundTransparency = 1
            NameLabelLine.Text = LocalPlayer.DisplayName
            NameLabelLine.TextColor3 = Color3.fromRGB(20, 20, 25)
            NameLabelLine.Font = Enum.Font.GothamBold
            NameLabelLine.TextSize = 11.5
            NameLabelLine.TextXAlignment = Enum.TextXAlignment.Left
            NameLabelLine.TextTruncate = Enum.TextTruncate.AtEnd
            NameLabelLine.Parent = ProfileFrame

            local UserLabelLine = Instance.new("TextLabel")
            UserLabelLine.Size = UDim2.new(1, -52, 0, 14)
            UserLabelLine.Position = UDim2.new(0, 48, 0, 24)
            UserLabelLine.BackgroundTransparency = 1
            UserLabelLine.Text = "@" .. LocalPlayer.Name
            UserLabelLine.TextColor3 = Color3.fromRGB(110, 115, 125)
            UserLabelLine.Font = Enum.Font.Gotham
            UserLabelLine.TextSize = 10
            UserLabelLine.TextXAlignment = Enum.TextXAlignment.Left
            UserLabelLine.TextTruncate = Enum.TextTruncate.AtEnd
            UserLabelLine.Parent = ProfileFrame
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

                TweenService:Create(Knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 24, 0, 14), Position = targetPos
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

        function Tab:AddScrambleToggle(defaultState, callback)
            local toggled = defaultState or false

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 46)
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

            local Line1 = Instance.new("TextLabel")
            Line1.Size = UDim2.new(1, -65, 0, 20)
            Line1.Position = UDim2.new(0, 10, 0, 4)
            Line1.BackgroundTransparency = 1
            Line1.Text = "DR SCRAMBLE's"
            Line1.TextColor3 = Color3.fromRGB(255, 255, 255)
            Line1.Font = Enum.Font.GothamBold
            Line1.TextSize = 13
            Line1.TextXAlignment = Enum.TextXAlignment.Left
            Line1.Parent = ToggleFrame

            local Line2 = Instance.new("TextLabel")
            Line2.Size = UDim2.new(1, -65, 0, 16)
            Line2.Position = UDim2.new(0, 10, 0, 24)
            Line2.BackgroundTransparency = 1
            Line2.Text = "EXPERIMENTS"
            Line2.TextColor3 = Color3.fromRGB(57, 255, 20)
            Line2.Font = Enum.Font.GothamBold
            Line2.TextSize = 6.5
            Line2.TextXAlignment = Enum.TextXAlignment.Left
            Line2.Parent = ToggleFrame

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

                TweenService:Create(Knob, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 24, 0, 14), Position = targetPos
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
            SliderFrame.Name = "Slider_" .. text
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
            Track.Name = "Track"
            Track.Size = UDim2.new(1, -20, 0, 7)
            Track.Position = UDim2.new(0, 10, 1, -14)
            Track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Track.BackgroundTransparency = 0.65
            Track.Parent = SliderFrame

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local Fill = Instance.new("Frame")
            Fill.Name = "Fill"
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

            local isLocked = false

            local function update(input)
                if isLocked then return end
                local relativeX = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local newValue = math.floor(min + (max - min) * relativeX)

                value = newValue
                ValLabel.Text = tostring(value)
                Fill.Size = UDim2.new(relativeX, 0, 1, 0)
                Thumb.Position = UDim2.new(relativeX, 0, 0.5, 0)

                if callback then callback(value) end
            end

            SliderFrame.InputBegan:Connect(function(input)
                if isLocked then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    TweenService:Create(Thumb, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 26, 0, 18), BackgroundTransparency = 0.05
                    }):Play()
                    TweenService:Create(Track, TweenInfo.new(0.2), { Size = UDim2.new(1, -20, 0, 9) }):Play()
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
                    TweenService:Create(Thumb, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0.15
                    }):Play()
                    TweenService:Create(Track, TweenInfo.new(0.25), { Size = UDim2.new(1, -20, 0, 7) }):Play()
                end
            end)

            return {
                SetLocked = function(locked)
                    isLocked = locked
                    if locked then
                        Fill.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
                        Label.TextColor3 = Color3.fromRGB(140, 140, 145)
                    else
                        Fill.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                        Label.TextColor3 = Color3.fromRGB(20, 20, 25)
                    end
                end
            }
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
MainTab:AddScrambleToggle(drScrambleActive, function(val)
    drScrambleActive = val
    if val then
        if getgenv().DrScrambleKick then getgenv().DrScrambleKick() end
    else
        stopTeleport()
        if stopDrScramble then stopDrScramble() end
        lockedTarget = nil
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

        if build:IsA("BasePart") then
            build.LocalTransparencyModifier = state and 1 or 0
        end

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

-- DELETE MAP
local deleteMapActive = false
local deleteMapLoopThread = nil

local function runDeleteMapLogic()
    pcall(function()
        if getgenv().DynamicFloorCleanup then
            getgenv().DynamicFloorCleanup()
        end

        local floorPart = nil
        local wallLeft = nil
        local wallRight = nil
        local wallFolder = nil
        local heartbeatConnection = nil
        local isEnabled = false

        local uiName = "FollowFloorUI_System"
        local oldUI = CoreGui:FindFirstChild(uiName) or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(uiName))
        if oldUI then oldUI:Destroy() end

        local function destroyBuildMap()
            pcall(function()
                local objects = workspace:FindFirstChild("__OBJECTS")
                if objects and objects:FindFirstChild("Build") then
                    objects.Build:Destroy()
                end
            end)
        end

        local function cleanup()
            isEnabled = false
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end
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
            floorPart.Name = "Dynamic_Floor"
            floorPart.Size = Vector3.new(200, 10, 200)
            floorPart.CanCollide = true
            floorPart.Anchored = true
            floorPart.Transparency = 1
            floorPart.Parent = wallFolder

            wallLeft = Instance.new("Part")
            wallLeft.Name = "Wall_Left_Dynamic"
            wallLeft.Size = Vector3.new(200, 52, 10)
            wallLeft.CanCollide = true
            wallLeft.Anchored = true
            wallLeft.Transparency = 1
            wallLeft.Parent = wallFolder

            wallRight = Instance.new("Part")
            wallRight.Name = "Wall_Right_Dynamic"
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
                        local charX = hrp.Position.X
                        local charZ = hrp.Position.Z

                        if floorPart and floorPart.Parent then
                            floorPart.CFrame = CFrame.new(charX, 63, charZ)
                        end

                        if charX < 549 then
                            if wallLeft and wallLeft.Parent then
                                wallLeft.CFrame = CFrame.new(charX, -500, -433)
                            end
                            if wallRight and wallRight.Parent then
                                wallRight.CFrame = CFrame.new(charX, -500, -295.5)
                            end
                        else
                            if wallLeft and wallLeft.Parent then
                                wallLeft.CFrame = CFrame.new(charX, 94, -433)
                            end
                            if wallRight and wallRight.Parent then
                                wallRight.CFrame = CFrame.new(charX, 94, -295.5)
                            end
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
        if deleteMapLoopThread then
            task.cancel(deleteMapLoopThread)
            deleteMapLoopThread = nil
        end
        if getgenv().DynamicFloorCleanup then
            getgenv().DynamicFloorCleanup()
        end
    end
end)

MiscTab:AddButton("Server NhiiiX-HopSV", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Nhoiii/NhoiiiX-Hub-Dev/refs/heads/main/NhoiiiHopSv.lua"))()
    end)
end)

-- =================================================================
-- PHÍM TẮT: C = TẮT DR SCRAMBLE
-- =================================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.C then
        drScrambleActive = false
        if stopDrScramble then stopDrScramble() end
        lockedTarget = nil
        print("[DrScramble] TẮT (C)")
    end
end)
