-- Workspace.SpawnedGems ESP & UI Tracker
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

-- 1. إنشاء الواجهة الشفافة
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GemsTrackerGUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175) -- منتصف الشاشة
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- واجهة سوداء
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- شريط العنوان (قابل للتحريك بالأصبع)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Gems Scanner (Drag)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- زر التحديث Refresh
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0, 55, 0, 26)
RefreshBtn.Position = UDim2.new(1, -60, 0.5, -13)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
RefreshBtn.Text = "Refresh"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.TextSize = 11
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.Parent = TitleBar

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 6)
RefreshCorner.Parent = RefreshBtn

-- قائمة التمرير (Scroll Frame)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -55)
ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollFrame

-- 2. تحريك الواجهة بالسحب من العنوان
local dragging = false
local dragStart = nil
local startPos = nil

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 3. نظام الـ ESP والتتبع
local activeESPs = {}

local function removeESP(gem)
    if activeESPs[gem] then
        if activeESPs[gem].Highlight then activeESPs[gem].Highlight:Destroy() end
        if activeESPs[gem].Billboard then activeESPs[gem].Billboard:Destroy() end
        if activeESPs[gem].Connection then activeESPs[gem].Connection:Disconnect() end
        activeESPs[gem] = nil
    end
end

local function createESP(gem)
    if activeESPs[gem] then
        removeESP(gem)
        return false
    end

    -- إضاءة الجوهرة خلف الجدران
    local highlight = Instance.new("Highlight")
    highlight.Adornee = gem
    highlight.FillColor = Color3.fromRGB(0, 255, 150)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.4
    highlight.Parent = gem

    -- نص المسافة فوق الجوهرة
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = gem
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = gem

    local distanceText = Instance.new("TextLabel")
    distanceText.Size = UDim2.new(1, 0, 1, 0)
    distanceText.BackgroundTransparency = 1
    distanceText.TextColor3 = Color3.fromRGB(0, 255, 150)
    distanceText.TextStrokeTransparency = 0
    distanceText.TextSize = 14
    distanceText.Font = Enum.Font.GothamBold
    distanceText.Text = gem.Name .. " [0m]"
    distanceText.Parent = billboard

    -- تحديث المسافة بشكل مستمر
    local connection = RunService.RenderStepped:Connect(function()
        if gem and gem.Parent and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = gem:IsA("Model") and (gem.PrimaryPart and gem.PrimaryPart.Position or gem:GetPivot().Position) or gem.Position
            local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude)
            distanceText.Text = gem.Name .. " [" .. tostring(dist) .. "m]"
        else
            removeESP(gem)
        end
    end)

    activeESPs[gem] = {
        Highlight = highlight,
        Billboard = billboard,
        Connection = connection
    }
    return true
end

-- 4. إظهار العناصر وتحديث القائمة
local function updateGemsList()
    -- مسح عناصر القائمة القديمة
    for _, child in pairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local spawnedGems = Workspace:FindFirstChild("SpawnedGems")
    if not spawnedGems then return end

    for _, gem in pairs(spawnedGems:GetChildren()) do
        local ItemFrame = Instance.new("Frame")
        ItemFrame.Size = UDim2.new(1, 0, 0, 40)
        ItemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        ItemFrame.BorderSizePixel = 0
        ItemFrame.Parent = ScrollFrame

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 6)
        ItemCorner.Parent = ItemFrame

        local GemName = Instance.new("TextLabel")
        GemName.Size = UDim2.new(1, -70, 1, 0)
        GemName.Position = UDim2.new(0, 10, 0, 0)
        GemName.BackgroundTransparency = 1
        GemName.Text = gem.Name
        GemName.TextColor3 = Color3.fromRGB(220, 220, 220)
        GemName.TextSize = 13
        GemName.Font = Enum.Font.Gotham
        GemName.TextXAlignment = Enum.TextXAlignment.Left
        GemName.Parent = ItemFrame

        local EspBtn = Instance.new("TextButton")
        EspBtn.Size = UDim2.new(0, 50, 0, 26)
        EspBtn.Position = UDim2.new(1, -55, 0.5, -13)
        EspBtn.Text = "ESP"
        EspBtn.TextSize = 12
        EspBtn.Font = Enum.Font.GothamBold
        EspBtn.Parent = ItemFrame

        local EspCorner = Instance.new("UICorner")
        EspCorner.CornerRadius = UDim.new(0, 6)
        EspCorner.Parent = EspBtn

        -- ضبط لون الزر المبدئي بناءً على حالة الـ ESP
        if activeESPs[gem] then
            EspBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            EspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            EspBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            EspBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end

        EspBtn.MouseButton1Click:Connect(function()
            local isEnabled = createESP(gem)
            if isEnabled then
                EspBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- أخضر عند التشغيل
                EspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                EspBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70) -- عودة للرمادي عند الإيقاف
                EspBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end)
    end
end

RefreshBtn.MouseButton1Click:Connect(updateGemsList)

-- تشغيل أول فحص لقائمة الكريستالات
updateGemsList()
