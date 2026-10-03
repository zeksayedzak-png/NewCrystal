-- Rune Scanner with Toggle, Live Tracking, Distance Meter & Touch Dragging
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- متغيرة حالة التشغيل
local isScannerActive = false
local trackedRunes = {} -- تخزين العناصر المراقبة حالياً
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

-- 3. دالة إضافة العلامة والمسافة على الرون (ESP & Distance Meter)
local function applyRuneTrack(target)
    if not target or trackedRunes[target] then return end

    -- البحث عن أفضل جزء لإلصاق العلامة عليه
    local adornPart = nil
    if target:IsA("BasePart") then
        adornPart = target
    elseif target:IsA("Model") then
        adornPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
    elseif target.Parent and target.Parent:IsA("BasePart") then
        adornPart = target.Parent
    end

    if not adornPart then return end

    -- إنشاء إضاءة خفيفة (Highlight)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = target:IsA("Model") and target or adornPart
    highlight.FillColor = Color3.fromRGB(0, 255, 150)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.Parent = adornPart

    -- إنشاء لوحة الملاحظة والمسافة (BillboardGui)
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
    textLabel.Text = target.Name .. " [0m]"
    textLabel.Parent = billboard

    trackedRunes[target] = {
        Part = adornPart,
        Highlight = highlight,
        Billboard = billboard,
        Label = textLabel
    }
end

-- 4. إزالة العلامات عند الإيقاف
local function clearAllTracks()
    for target, data in pairs(trackedRunes) do
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
    end
    trackedRunes = {}
end

-- 5. فحص الماب بانتظام ومتابعة الرونات الجديدة
local function scanAllRunes()
    for _, desc in pairs(Workspace:GetDescendants()) do
        if desc.Name == "RuneBillboard" or desc.Name == "RuneModels" then
            applyRuneTrack(desc)
        end
    end
end

-- 6. تشغيل وإيقاف المراقبة الفورية
local function startScanning()
    scanAllRunes()

    -- مراقبة ظهور أي كائن جديد أثناء التحرك
    addedConnection = Workspace.DescendantAdded:Connect(function(desc)
        if isScannerActive and (desc.Name == "RuneBillboard" or desc.Name == "RuneModels") then
            task.wait(0.1)
            applyRuneTrack(desc)
        end
    end)

    -- تحديث مسافات الرونات لحظة بلحظة أثناء المشي [Xm]
    globalConnection = RunService.Heartbeat:Connect(function()
        if not isScannerActive then return end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        for target, data in pairs(trackedRunes) do
            if target and target.Parent and data.Part and data.Part.Parent then
                local dist = math.floor((root.Position - data.Part.Position).Magnitude)
                data.Label.Text = target.Name .. " [" .. tostring(dist) .. "m]"
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

-- 7. زر التشغيل والإيقاف On/Off
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
