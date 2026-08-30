--[[
    🔥 DELTA TROLL LOCK
    =========================
    🔒 Khóa di chuyển
    📷 Khóa xoay camera
    🚫 Khóa input
    😂 Spam icon vĩnh viễn
    🚨 Chuông báo cháy
]]

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ==========================================
-- CONFIG
-- ==========================================

local ICON_DELAY = 0.12
local ALARM_VOLUME = 2

-- ==========================================
-- XÓA GUI CŨ
-- ==========================================

local OldGUI = PlayerGui:FindFirstChild("TrollLockGUI")

if OldGUI then
    OldGUI:Destroy()
end

-- ==========================================
-- GUI
-- ==========================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "TrollLockGUI"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999999
GUI.Parent = PlayerGui

-- ==========================================
-- CHỮ TROLL
-- ==========================================

local TrollText = Instance.new("TextLabel")

TrollText.Name = "TrollText"
TrollText.Size = UDim2.fromOffset(500, 60)
TrollText.Position = UDim2.fromScale(0.5, 0.08)
TrollText.AnchorPoint = Vector2.new(0.5, 0.5)

TrollText.BackgroundTransparency = 1
TrollText.Text = "🚨 BÁO CHÁY!!! BỊ KHÓA THAO TÁC 😂"
TrollText.TextScaled = true
TrollText.Font = Enum.Font.GothamBold
TrollText.TextStrokeTransparency = 0
TrollText.ZIndex = 999999

TrollText.Parent = GUI

-- ==========================================
-- 🚫 BLOCK INPUT
-- ==========================================

local function BlockInput()
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindActionAtPriority(
    "TROLL_BLOCK_INPUT",
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
-- 🔒 KHÓA NHÂN VẬT
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
-- 📷 KHÓA CAMERA
-- ==========================================

local Camera = workspace.CurrentCamera
local LockedCameraCFrame

if Camera then
    LockedCameraCFrame = Camera.CFrame
end

RunService:BindToRenderStep(
    "TROLL_LOCK_CAMERA",
    Enum.RenderPriority.Camera.Value + 1,
    function()

        Camera = workspace.CurrentCamera

        if Camera and LockedCameraCFrame then
            Camera.CFrame = LockedCameraCFrame
        end

    end
)

-- ==========================================
-- 😂 ICON LIST
-- ==========================================

local Icons = {

    "🔒",
    "😂",
    "💀",
    "🚨",
    "🔥",
    "🚫",
    "😈",
    "🔐",
    "🤡",
    "🗿",
    "❌",
    "🤣",
    "😭",
    "😎",
    "👹",
    "👺",
    "🙃",
    "😵",
    "🤯",
    "😏",
    "😱",
    "🤪",
    "🥶",
    "🥴",
    "💩",
    "👀",
    "⚠️",
    "🚒"

}

-- ==========================================
-- 💥 SPAM ICON VĨNH VIỄN
-- ==========================================

task.spawn(function()

    while GUI.Parent do

        local Icon = Instance.new("TextLabel")

        Icon.Name = "PermanentIcon"

        local Size = math.random(35, 70)

        Icon.Size = UDim2.fromOffset(Size, Size)

        Icon.Position = UDim2.fromScale(
            math.random(3, 97) / 100,
            math.random(5, 95) / 100
        )

        Icon.AnchorPoint = Vector2.new(0.5, 0.5)

        Icon.BackgroundTransparency = 1

        Icon.Text =
            Icons[math.random(1, #Icons)]

        Icon.TextScaled = true
        Icon.TextStrokeTransparency = 0
        Icon.ZIndex = 100

        Icon.Parent = GUI

        -- ❗ KHÔNG Destroy
        -- ❗ Icon cũ giữ nguyên

        task.wait(ICON_DELAY)

    end

end)

-- ==========================================
-- 🚨 CHUÔNG BÁO CHÁY
-- ==========================================

local Alarm = Instance.new("Sound")

Alarm.Name = "FireAlarm"

-- Roblox audio ID
Alarm.SoundId = "rbxassetid://9118823101"

Alarm.Volume = ALARM_VOLUME
Alarm.Looped = false
Alarm.Parent = GUI

-- ==========================================
-- 🚨 ALARM LOOP
-- ==========================================

task.spawn(function()

    while GUI.Parent do

        Alarm:Play()

        task.wait(3)

        Alarm:Stop()

        task.wait(0.5)

    end

end)

-- ==========================================
-- 🔥 FLASH CHỮ
-- ==========================================

task.spawn(function()

    while GUI.Parent do

        TrollText.Text =
            "🚨 BÁO CHÁY!!! Tài Khoản Của Bạn Bị Lock😂"

        task.wait(2)

        TrollText.Text =
            "🔥 Đốt Bộ Nhơz🔥"

        task.wait(0.5)

        TrollText.Text =
            "💀 KHÔNG THỂ DI CHUYỂN 💀"

        task.wait(0.5)

    end

end)

-- ==========================================
-- CONSOLE
-- ==========================================

print("================================")
print("🔥 TROLL LOCK ACTIVATED")
print("🔒 Movement: LOCKED")
print("📷 Camera: LOCKED")
print("🚫 Input: BLOCKED")
print("😂 Icons: PERMANENT")
print("🚨 Fire Alarm: ON")
print("================================")
