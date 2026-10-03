-- DroppedRunes Real-time Scanner & Distance Tracker
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- تحديد المجلد المستهدف داخل Workspace
local droppedRunesFolder = Workspace:WaitForChild("DroppedRunes")

-- متغيرات التحكم
local isScannerActive = false
local trackedRunes = {}
local globalConnection = nil
local addedConnection = nil

-- 1. إنشاء الواجهة الرسومية (GUI)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RuneScannerGUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- الإطار الرئيسي (الواجهة السوداء)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 110)
MainFrame.Position = UDim2.new(0.5, -120, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 255, 120)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- شريط العنوان
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Rune scanner"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

-- زر التفعيل On/Off
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 180, 0, 38)
ToggleBtn.Position = UDim2.new(0.5, -90, 0, 55)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
ToggleBtn.Text = "OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(200, 60, 60)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- 2. تحريك الواجهة بالأصبع (Touch) أو الماوس
local dragging = false
local dragStart = nil
local startPos = nil

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 3. دالة العثور على الجزء الفعلي (BasePart) لرسم العلامة عليه
local function getRuneBasePart(item)
    if item:IsA("BasePart") then
        return item
    elseif item:IsA("Model") then
        return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)
    end
    return item:FindFirstChildWhichIsA("BasePart", true)
end

-- 4. تطبيق العلامة وحساب المسافة
local function applyRuneTrack(runeItem)
    if not runeItem or trackedRunes[runeItem] then return end

    local part = getRuneBasePart(runeItem)
    if not part then return end

    -- إضاءة Highlight على المجسم
    local highlight = Instance.new("Highlight")
    highlight.Adornee = runeItem:IsA("Model") and runeItem or part
    highlight.FillColor = Color3.fromRGB(0, 255, 150)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.Parent = part

    -- لوحة إشارة تظهر اسم الرون والمسافة فوقه مباشرة
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 140, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = runeItem.Name .. " [0m]"
    textLabel.Parent = billboard

    trackedRunes[runeItem] = {
        Part = part,
        Highlight = highlight,
        Billboard = billboard,
        Label = textLabel
    }
end

-- 5. إزالة كل العلامات عند الإيقاف
local function clearAllTracks()
    for item, data in pairs(trackedRunes) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    trackedRunes = {}
end

-- 6. مسح مجلد DroppedRunes بالكامل
local function scanDroppedRunes()
    for _, child in pairs(droppedRunesFolder:GetChildren()) do
        applyRuneTrack(child)
    end
end

-- 7. بدء التشغيل والمراقبة الحية
local function startScanning()
    scanDroppedRunes()

    -- مراقبة ظهور أي Rune جديد يرسبن في المجلد أثناء تحركك
    addedConnection = droppedRunesFolder.ChildAdded:Connect(function(child)
        if isScannerActive then
            task.wait(0.1)
            applyRuneTrack(child)
        end
    end)

    -- تحديث مسافة الاقتراب باستمرار [Xm]
    globalConnection = RunService.Heartbeat:Connect(function()
        if not isScannerActive then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for item, data in pairs(trackedRunes) do
            if item and item.Parent and data.Part and data.Part.Parent then
                local dist = math.floor((root.Position - data.Part.Position).Magnitude)
                data.Label.Text = item.Name .. " [" .. tostring(dist) .. "m]"
            else
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
                trackedRunes[item] = nil
            end
        end
    end)
end

local function stopScanning()
    if addedConnection then addedConnection:Disconnect() end
    if globalConnection then globalConnection:Disconnect() end
    clearAllTracks()
end

-- 8. زر التشغيل والإيقاف On/Off
ToggleBtn.MouseButton1Click:Connect(function()
    isScannerActive = not isScannerActive

    if isScannerActive then
        ToggleBtn.Text = "ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        startScanning()
    else
        ToggleBtn.Text = "OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        ToggleBtn.TextColor3 = Color3.fromRGB(200, 60, 60)
        stopScanning()
    end
end)
