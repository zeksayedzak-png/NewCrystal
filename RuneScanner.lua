-- ReplicatedStorage Rune Model Scanner & Distance Tracker
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- تحديد المجلد المستهدف داخل ReplicatedStorage
local targetFolder = ReplicatedStorage:WaitForChild("RuneModels")

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

-- 3. دالة تحديد موقع الجزء الفعلي المرتبط بـ RuneBillboard
local function getTargetPart(obj)
    if obj:IsA("BasePart") then return obj end
    
    -- إذا كان BillboardGui وله Adornee
    if obj:IsA("BillboardGui") and obj.Adornee then
        return obj.Adornee
    end

    -- البحث عن أول BasePart داخله أو عند الأب
    local foundPart = obj:FindFirstChildWhichIsA("BasePart", true)
    if foundPart then return foundPart end

    if obj.Parent and obj.Parent:IsA("BasePart") then
        return obj.Parent
    end

    return nil
end

-- 4. تطبيق العلامة وحساب المسافة
local function applyRuneTrack(target)
    if not target or trackedRunes[target] then return end

    local adornPart = getTargetPart(target)
    if not adornPart then return end

    -- إضاءة Highlight على المجسم
    local highlight = Instance.new("Highlight")
    highlight.Adornee = adornPart
    highlight.FillColor = Color3.fromRGB(0, 255, 150)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.Parent = adornPart

    -- لوحة إشارة مع المسافة فوق الكائن
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = adornPart
    billboard.Size = UDim2.new(0, 140, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = adornPart

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = "Rune [0m]"
    textLabel.Parent = billboard

    trackedRunes[target] = {
        Part = adornPart,
        Highlight = highlight,
        Billboard = billboard,
        Label = textLabel
    }
end

-- 5. تنظيف جميع العلامات
local function clearAllTracks()
    for target, data in pairs(trackedRunes) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    trackedRunes = {}
end

-- 6. فحص ReplicatedStorage.RuneModels فقط
local function scanReplicatedStorage()
    for _, desc in pairs(targetFolder:GetDescendants()) do
        if desc.Name == "RuneBillboard" then
            applyRuneTrack(desc)
        end
    end
end

-- 7. بدء المراقبة المستمرة داخل ReplicatedStorage
local function startScanning()
    scanReplicatedStorage()

    -- مراقبة ظهور RuneBillboard جديد داخل ReplicatedStorage.RuneModels فوراً أثناء تحركك
    addedConnection = targetFolder.DescendantAdded:Connect(function(desc)
        if isScannerActive and desc.Name == "RuneBillboard" then
            task.wait(0.1)
            applyRuneTrack(desc)
        end
    end)

    -- تحديث مسافة اقترابك منه باستمرار [Xm]
    globalConnection = RunService.Heartbeat:Connect(function()
        if not isScannerActive then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for target, data in pairs(trackedRunes) do
            if target and target.Parent and data.Part and data.Part.Parent then
                local dist = math.floor((root.Position - data.Part.Position).Magnitude)
                data.Label.Text = "Rune [" .. tostring(dist) .. "m]"
            else
                if data.Highlight then data.Highlight:Destroy() end
                if data.Billboard then data.Billboard:Destroy() end
                trackedRunes[target] = nil
            end
        end
    end)
end

local function stopScanning()
    if addedConnection then addedConnection:Disconnect() end
    if globalConnection then globalConnection:Disconnect() end
    clearAllTracks()
end

-- 8. زر On/Off
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
