-- Worming ESP
-- Made for Delta

local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

-- الواجهة
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WormingESP"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- الإطار الرئيسي
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 120)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -60)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 140, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- العنوان
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Worming ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- زر On/Off
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 0, 45)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
ToggleBtn.Text = "OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = MainFrame

local TCorner = Instance.new("UICorner")
TCorner.CornerRadius = UDim.new(0, 8)
TCorner.Parent = ToggleBtn

-- متغيرات
local espEnabled = false
local espObjects = {}

-- دالة إنشاء ESP
local function createESP(target)
    if not target or not target:IsA("BasePart") then return end

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "WormingHighlight"
    highlight.Adornee = target
    highlight.FillColor = Color3.fromRGB(255, 140, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = target

    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WormingBillboard"
    billboard.Adornee = target
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = target

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 25)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = target.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0, 25)
    distanceLabel.Position = UDim2.new(0, 0, 0, 25)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextScaled = true
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = billboard

    table.insert(espObjects, {
        target = target,
        highlight = highlight,
        billboard = billboard,
        distanceLabel = distanceLabel
    })
end

-- دالة مسح ESP
local function clearESP()
    for _, obj in pairs(espObjects) do
        if obj.highlight then obj.highlight:Destroy() end
        if obj.billboard then obj.billboard:Destroy() end
    end
    espObjects = {}
end

-- دالة تشغيل ESP
local function enableESP()
    clearESP()
    local boulders = workspace:FindFirstChild("Boulders")
    if not boulders then
        ToggleBtn.Text = "No Boulders"
        wait(2)
        ToggleBtn.Text = "OFF"
        espEnabled = false
        return
    end
    for _, obj in pairs(boulders:GetDescendants()) do
        if obj:IsA("BasePart") then
            createESP(obj)
        end
    end
end

-- تحديث المسافات
RunService.RenderStepped:Connect(function()
    if not espEnabled then return end
    for _, obj in pairs(espObjects) do
        if obj.target and obj.target.Parent then
            local distance = (obj.target.Position - Camera.CFrame.Position).Magnitude
            obj.distanceLabel.Text = string.format("%.0fm", distance)
        end
    end
end)

-- زر On/Off
ToggleBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    if espEnabled then
        ToggleBtn.Text = "ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        enableESP()
    else
        ToggleBtn.Text = "OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        clearESP()
    end
end)
