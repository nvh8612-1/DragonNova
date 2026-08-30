--[[
    💻 DELTA TROLL SCREEN
    =========================
    💻 Hacking... 
    🔒 Lock Movement
    📷 Lock Camera
    😂 Permanent Icons
    🚨 Alarm / Beep
    🖥️ Fake Terminal
]]

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ==========================================
-- CONFIG
-- ==========================================

local ICON_DELAY = 0.18

-- ==========================================
-- CLEAN OLD GUI
-- ==========================================

local Old = PlayerGui:FindFirstChild("TrollHackGUI")

if Old then
    Old:Destroy()
end

-- ==========================================
-- SCREEN GUI
-- ==========================================

local GUI = Instance.new("ScreenGui")

GUI.Name = "TrollHackGUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999999

GUI.Parent = PlayerGui

-- ==========================================
-- 💻 HACKING TEXT
-- ==========================================

local HackText = Instance.new("TextLabel")

HackText.Size = UDim2.fromScale(0.9, 0.1)
HackText.Position = UDim2.fromScale(0.5, 0.08)
HackText.AnchorPoint = Vector2.new(0.5, 0.5)

HackText.BackgroundTransparency = 1

HackText.Text = "💻 Hacking..."
HackText.TextScaled = true
HackText.Font = Enum.Font.Code

HackText.TextStrokeTransparency = 0
HackText.ZIndex = 999999

HackText.Parent = GUI

-- ==========================================
-- 🖥️ FAKE TERMINAL
-- ==========================================

local Terminal = Instance.new("TextLabel")

Terminal.Size = UDim2.fromScale(0.85, 0.35)
Terminal.Position = UDim2.fromScale(0.5, 0.55)
Terminal.AnchorPoint = Vector2.new(0.5, 0.5)

Terminal.BackgroundTransparency = 0.25

Terminal.TextColor3 = Color3.fromRGB(255,255,255)

Terminal.TextXAlignment = Enum.TextXAlignment.Left
Terminal.TextYAlignment = Enum.TextYAlignment.Top

Terminal.TextScaled = false
Terminal.TextSize = 17

Terminal.Font = Enum.Font.Code

Terminal.Text =
[[> INITIALIZING...
> CONNECTING...
> BYPASSING PLAYER INPUT...
> LOCKING MOVEMENT...
> CAMERA CONTROL: LOCKED
> ACCESS: ██████████
> PROCESSING...
> HACKING... 💻]]

Terminal.ZIndex = 999998
Terminal.Parent = GUI

-- ==========================================
-- 🚫 BLOCK INPUT
-- ==========================================

local function BlockInput()
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
    "TROLL_HACK_INPUT",
    BlockInput,
    false,
    Enum.ContextActionPriority.High.Value,

    Enum.KeyCode.W,
    Enum.KeyCode.A,
    Enum.KeyCode.S,
    Enum.KeyCode.D,

    Enum.KeyCode.Up,
    Enum.KeyCode.Down,
    Enum.KeyCode.Left,
    Enum.KeyCode.Right,

    Enum.KeyCode.Space
)

-- ==========================================
-- 🔒 LOCK CHARACTER
-- ==========================================

local function LockCharacter()

    local Character = Player.Character

    if not Character then
        return
    end

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    if not Humanoid then
        return
    end

    Humanoid.WalkSpeed = 0
    Humanoid.JumpPower = 0
    Humanoid.JumpHeight = 0
    Humanoid.AutoRotate = false

    Humanoid:Move(Vector3.zero, false)

end

LockCharacter()

Player.CharacterAdded:Connect(function()

    task.wait(0.5)

    LockCharacter()

end)

RunService.Heartbeat:Connect(function()

    LockCharacter()

end)

-- ==========================================
-- 📷 LOCK CAMERA
-- ==========================================

local Camera = workspace.CurrentCamera
local LockedCamera

if Camera then
    LockedCamera = Camera.CFrame
end

RunService:BindToRenderStep(
    "TROLL_LOCK_CAMERA",
    Enum.RenderPriority.Camera.Value + 1,
    function()

        Camera = workspace.CurrentCamera

        if Camera and LockedCamera then
            Camera.CFrame = LockedCamera
        end

    end
)

-- ==========================================
-- 😂 ICONS
-- ==========================================

local Icons = {

    "💻",
    "🔒",
    "🚨",
    "🔥",
    "💀",
    "😂",
    "🤡",
    "⚠️",
    "🚫",
    "👾",
    "🖥️",
    "🔐",
    "😈",
    "💩",
    "🗿",
    "❌",
    "⚡",
    "👀"

}

-- ==========================================
-- 💥 PERMANENT ICON SPAM
-- ==========================================

task.spawn(function()

    while GUI.Parent do

        local Icon = Instance.new("TextLabel")

        local Size = math.random(30,65)

        Icon.Size =
            UDim2.fromOffset(Size,Size)

        Icon.Position =
            UDim2.fromScale(
                math.random(3,97)/100,
                math.random(5,95)/100
            )

        Icon.AnchorPoint =
            Vector2.new(0.5,0.5)

        Icon.BackgroundTransparency = 1

        Icon.Text =
            Icons[math.random(1,#Icons)]

        Icon.TextScaled = true
        Icon.TextStrokeTransparency = 0

        Icon.ZIndex = 500

        Icon.Parent = GUI

        -- ❗ KHÔNG XÓA ICON

        task.wait(ICON_DELAY)

    end

end)

-- ==========================================
-- 💻 HACKING ANIMATION
-- ==========================================

task.spawn(function()

    local dots = {
        "💻 Hacking.",
        "💻 Hacking..",
        "💻 Hacking...",
        "💻 Hacking...."
    }

    local i = 1

    while GUI.Parent do

        HackText.Text = dots[i]

        i += 1

        if i > #dots then
            i = 1
        end

        task.wait(0.35)

    end

end)

-- ==========================================
-- 🖥️ TERMINAL ANIMATION
-- ==========================================

task.spawn(function()

    local Messages = {

        "> INITIALIZING...",
        "> CONNECTING...",
        "> SCANNING PLAYER...",
        "> LOCKING INPUT...",
        "> CAMERA CONTROL: LOCKED",
        "> MOVEMENT: DISABLED",
        "> PROCESSING...",
        "> ACCESS ██████████",
        "> INJECTING...",
        "> HACKING... 💻",
        "> LOL 😂",
        "> SYSTEM TROLLED 🤡"

    }

    while GUI.Parent do

        Terminal.Text =
            Messages[math.random(1,#Messages)]

        task.wait(0.35)

    end

end)

-- ==========================================
-- 🔊 TROLL BEEP
-- ==========================================

local Beep = Instance.new("Sound")

Beep.Name = "TrollBeep"

-- Generic Roblox audio
Beep.SoundId = "rbxassetid://9118823101"

Beep.Volume = 1
Beep.Looped = false
Beep.Parent = GUI

task.spawn(function()

    while GUI.Parent do

        Beep:Play()

        task.wait(2)

        Beep:Stop()

        task.wait(0.3)

    end

end)

-- ==========================================
-- 💀 FINAL MESSAGE
-- ==========================================

print("====================================")
print("💻 TROLL HACK SCREEN ACTIVATED")
print("🔒 MOVEMENT LOCKED")
print("📷 CAMERA LOCKED")
print("😂 PERMANENT ICONS")
print("🚨 TROLL SOUND")
print("====================================")
