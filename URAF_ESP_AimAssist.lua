--[=[
URAF ESP & AIM ASSIST - SINGLE FILE
Uso: LocalScript em StarterPlayerScripts (Roblox Studio).
Para permitir que um personagem seja alvo de QA, defina:
  Character:SetAttribute("URAF_QA_Target", true)
ou Player:SetAttribute("URAF_QA_Target", true)
O filtro QA é intencional: o sistema não marca nem mira jogadores aleatórios.
Compatível com R6/R15; usa APIs oficiais do Roblox.
]=]

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Configuration
local Config = {
    Enabled = true,
    Box = true,
    Name = true,
    Distance = true,
    HealthBar = true,
    HealthText = true,
    Skeleton = true,
    Tracer = true,
    Head = true,
    Highlight = true,
    AimEnabled = false,
    ShowFOV = true,
    FOV = 140,
    Smoothness = 0.18,
    MaxDistance = 1500,
    AimPart = "Head",
    AimKey = Enum.KeyCode.Q,
    BoxColor = Color3.fromRGB(190, 120, 255),
    NameColor = Color3.fromRGB(245, 235, 255),
    LineColor = Color3.fromRGB(190, 120, 255),
    SkeletonColor = Color3.fromRGB(210, 170, 255),
    HighlightColor = Color3.fromRGB(155, 75, 230),
    TextSize = 13,
    LineThickness = 1.5,
    Transparency = 0.15,
}

local Logger = {}
function Logger:Info(message) print("[URAF] " .. tostring(message)) end
function Logger:Warn(message) warn("[URAF] " .. tostring(message)) end

local function isQATarget(player, character)
    if not player or player == LocalPlayer or not character then return false end
    return player:GetAttribute("URAF_QA_Target") == true
        or character:GetAttribute("URAF_QA_Target") == true
end

--// GUI root
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local old = PlayerGui:FindFirstChild("URAF_SingleFile")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "URAF_SingleFile"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local Overlay = make("Frame", {
    Name = "Overlay", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
}, Gui)

local function newLine(parent, color, thickness, z)
    local line = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
        BackgroundColor3 = color, Size = UDim2.fromOffset(1, thickness),
        Visible = false, ZIndex = z or 2,
    }, parent)
    return line
end

local FOVCircle = make("Frame", {
    Name = "FOV", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(Config.FOV * 2, Config.FOV * 2),
    BackgroundTransparency = 1, Visible = Config.ShowFOV, ZIndex = 5,
}, Overlay)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, FOVCircle)
make("UIStroke", { Color = Config.HighlightColor, Thickness = 1.5, Transparency = 0.2 }, FOVCircle)

--// UI
local Window = make("Frame", {
    Name = "Main", Size = UDim2.fromOffset(330, 390), Position = UDim2.fromOffset(25, 160),
    BackgroundColor3 = Color3.fromRGB(19, 17, 25), BorderSizePixel = 0, ZIndex = 20,
}, Gui)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, Window)
make("UIStroke", { Color = Color3.fromRGB(115, 65, 160), Thickness = 1.2 }, Window)
local Top = make("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.fromRGB(35, 25, 48), BorderSizePixel = 0, ZIndex = 21 }, Window)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, Top)
make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(13, 0), Size = UDim2.new(1, -95, 1, 0), Font = Enum.Font.GothamBold, Text = "URAF  /  QA VISUALS", TextColor3 = Color3.fromRGB(235, 220, 255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22 }, Top)
local MinButton = make("TextButton", { Position = UDim2.new(1, -68, 0, 8), Size = UDim2.fromOffset(25, 25), Text = "—", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(76, 48, 100), ZIndex = 22 }, Top)
local CloseButton = make("TextButton", { Position = UDim2.new(1, -36, 0, 8), Size = UDim2.fromOffset(25, 25), Text = "×", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(120, 45, 75), ZIndex = 22 }, Top)
for _, b in ipairs({MinButton, CloseButton}) do make("UICorner", { CornerRadius = UDim.new(0, 6) }, b) end
local Content = make("ScrollingFrame", { Position = UDim2.fromOffset(10, 52), Size = UDim2.new(1, -20, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, 0), ZIndex = 21 }, Window)
local List = make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Content)
List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Content.CanvasSize = UDim2.fromOffset(0, List.AbsoluteContentSize.Y + 8) end)

local function addSection(text)
    make("TextLabel", { Size = UDim2.new(1, -4, 0, 25), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(190, 145, 235), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22 }, Content)
end
local function addToggle(label, key)
    local button = make("TextButton", { Size = UDim2.new(1, -4, 0, 29), BackgroundColor3 = Color3.fromRGB(39, 34, 48), Text = "", AutoButtonColor = true, ZIndex = 22 }, Content)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
    local txt = make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -65, 1, 0), Text = label, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(235, 230, 242), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23 }, button)
    local state = make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -53, 0, 0), Size = UDim2.fromOffset(45, 29), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Config[key] and Color3.fromRGB(180, 255, 190) or Color3.fromRGB(255, 150, 150), Text = Config[key] and "ON" or "OFF", ZIndex = 23 }, button)
    button.Activated:Connect(function()
        Config[key] = not Config[key]
        state.Text = Config[key] and "ON" or "OFF"
        state.TextColor3 = Config[key] and Color3.fromRGB(180, 255, 190) or Color3.fromRGB(255, 150, 150)
    end)
end
local function addAdjust(label, key, minValue, maxValue, step)
    local row = make("Frame", { Size = UDim2.new(1, -4, 0, 32), BackgroundColor3 = Color3.fromRGB(39, 34, 48), ZIndex = 22 }, Content)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -125, 1, 0), Text = label, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(235, 230, 242), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23 }, row)
    local value = make("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -82, 0, 0), Size = UDim2.fromOffset(35, 32), Text = tostring(Config[key]), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(215, 180, 255), ZIndex = 23 }, row)
    local minus = make("TextButton", { Position = UDim2.new(1, -45, 0, 4), Size = UDim2.fromOffset(18, 24), Text = "−", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(80, 55, 105), ZIndex = 23 }, row)
    local plus = make("TextButton", { Position = UDim2.new(1, -23, 0, 4), Size = UDim2.fromOffset(18, 24), Text = "+", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.new(1,1,1), BackgroundColor3 = Color3.fromRGB(80, 55, 105), ZIndex = 23 }, row)
    local function change(direction)
        Config[key] = math.clamp(math.floor((Config[key] + direction * step) * 100 + 0.5) / 100, minValue, maxValue)
        value.Text = tostring(Config[key])
    end
    minus.Activated:Connect(function() change(-1) end)
    plus.Activated:Connect(function() change(1) end)
end

addSection("PLAYER ESP  ·  QA TARGETS ONLY")
addToggle("Sistema visual", "Enabled")
addToggle("Box ESP", "Box")
addToggle("Name ESP", "Name")
addToggle("Distance ESP", "Distance")
addToggle("Health bar", "HealthBar")
addToggle("Health text", "HealthText")
addToggle("Skeleton ESP", "Skeleton")
addToggle("Tracer ESP", "Tracer")
addToggle("Head highlight", "Head")
addToggle("Character highlight", "Highlight")
addSection("AIM ASSIST  ·  QA TARGETS ONLY")
addToggle("Aim Assist", "AimEnabled")
addToggle("FOV circle", "ShowFOV")
addAdjust("FOV radius", "FOV", 30, 500, 10)
addAdjust("Smoothness", "Smoothness", 0.02, 1, 0.02)
addAdjust("Max distance", "MaxDistance", 100, 5000, 100)

local minimized = false
MinButton.Activated:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    Window.Size = minimized and UDim2.fromOffset(330, 42) or UDim2.fromOffset(330, 390)
end)
CloseButton.Activated:Connect(function() Gui.Enabled = false end)

-- Drag window
local dragging, dragStart, startPos
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Window.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// Tracker / render records
local Records = {}
local SkeletonLinks = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6Links = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}

local function createRecord(player)
    local folder = make("Folder", { Name = "P_" .. player.UserId }, Overlay)
    local box = make("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 2 }, folder)
    make("UIStroke", { Color = Config.BoxColor, Thickness = Config.LineThickness, Transparency = Config.Transparency }, box)
    local name = make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(180, 18), AnchorPoint = Vector2.new(0.5, 1), Font = Enum.Font.GothamBold, TextSize = Config.TextSize, TextColor3 = Config.NameColor, TextStrokeTransparency = 0.35, Visible = false, ZIndex = 3 }, folder)
    local healthBG = make("Frame", { BackgroundColor3 = Color3.fromRGB(35, 35, 40), BorderSizePixel = 0, Visible = false, ZIndex = 3 }, folder)
    local healthFill = make("Frame", { BackgroundColor3 = Color3.fromRGB(80, 220, 120), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, healthBG)
    local healthText = make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(80, 16), Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.new(1,1,1), TextStrokeTransparency = 0.3, Visible = false, ZIndex = 3 }, folder)
    local tracer = newLine(folder, Config.LineColor, Config.LineThickness, 2)
    local bones = {}
    for i = 1, 20 do bones[i] = newLine(folder, Config.SkeletonColor, Config.LineThickness, 2) end
    local headDot = make("Frame", { AnchorPoint = Vector2.new(0.5,0.5), Size = UDim2.fromOffset(10,10), BackgroundColor3 = Config.HighlightColor, BorderSizePixel = 0, Visible = false, ZIndex = 4 }, folder)
    make("UICorner", { CornerRadius = UDim.new(1,0) }, headDot)
    local highlight = Instance.new("Highlight")
    highlight.Name = "URAF_QA_Highlight"
    highlight.FillColor = Config.HighlightColor
    highlight.OutlineColor = Config.HighlightColor
    highlight.FillTransparency = 0.82
    highlight.OutlineTransparency = 0.05
    highlight.Enabled = false
    highlight.Parent = folder
    return { Player = player, Folder = folder, Box = box, Name = name, HealthBG = healthBG, HealthFill = healthFill, HealthText = healthText, Tracer = tracer, Bones = bones, HeadDot = headDot, Highlight = highlight }
end

local function cleanupRecord(player)
    local record = Records[player]
    if record then
        record.Folder:Destroy()
        Records[player] = nil
    end
end

local function getCharacterParts(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local head = character and character:FindFirstChild("Head")
    return humanoid, root, head
end

local function project(worldPos)
    local point, visible = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(point.X, point.Y), visible and point.Z > 0, point.Z
end

local function setLine(line, a, b, color, thickness)
    local delta = b - a
    line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    line.Size = UDim2.fromOffset(delta.Magnitude, thickness or Config.LineThickness)
    line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    line.BackgroundColor3 = color
    line.Visible = true
end

local function hideRecord(r)
    r.Box.Visible = false; r.Name.Visible = false; r.HealthBG.Visible = false
    r.HealthText.Visible = false; r.Tracer.Visible = false; r.HeadDot.Visible = false
    r.Highlight.Enabled = false
    for _, line in ipairs(r.Bones) do line.Visible = false end
end

local function getBounds(character)
    local cf, size = character:GetBoundingBox()
    local corners = {}
    for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
        local p = cf:PointToWorldSpace(Vector3.new(size.X*x/2, size.Y*y/2, size.Z*z/2))
        local v, on = project(p)
        if on then table.insert(corners, v) end
    end end end
    if #corners < 2 then return nil end
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, p in ipairs(corners) do minX = math.min(minX,p.X); minY = math.min(minY,p.Y); maxX = math.max(maxX,p.X); maxY = math.max(maxY,p.Y) end
    return minX, minY, maxX, maxY
end

local function updateRecord(player, r)
    local character = player.Character
    if not Config.Enabled or not isQATarget(player, character) or not character then hideRecord(r); return end
    local humanoid, root, head = getCharacterParts(character)
    if not humanoid or humanoid.Health <= 0 or not root then hideRecord(r); return end
    local distance = (Camera.CFrame.Position - root.Position).Magnitude
    if distance > Config.MaxDistance then hideRecord(r); return end
    local minX, minY, maxX, maxY = getBounds(character)
    if not minX then hideRecord(r); return end
    local width, height = maxX-minX, maxY-minY
    r.Box.Position = UDim2.fromOffset(minX, minY)
    r.Box.Size = UDim2.fromOffset(width, height)
    r.Box.Visible = Config.Box
    local centerX = (minX + maxX) / 2
    r.Name.Position = UDim2.fromOffset(centerX, minY - 3)
    r.Name.Text = player.DisplayName .. (Config.Distance and ("  [" .. math.floor(distance) .. "m]") or "")
    r.Name.TextSize = Config.TextSize; r.Name.TextColor3 = Config.NameColor
    r.Name.Visible = Config.Name or Config.Distance
    local ratio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
    r.HealthBG.Position = UDim2.fromOffset(minX - 6, minY)
    r.HealthBG.Size = UDim2.fromOffset(4, height)
    r.HealthBG.Visible = Config.HealthBar
    r.HealthFill.Size = UDim2.new(1, 0, ratio, 0)
    r.HealthFill.Position = UDim2.new(0, 0, 1-ratio, 0)
    r.HealthFill.BackgroundColor3 = Color3.fromRGB(230*(1-ratio)+50, 210*ratio+40, 70)
    r.HealthText.Position = UDim2.fromOffset(maxX + 4, minY)
    r.HealthText.Text = string.format("%d/%d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
    r.HealthText.Visible = Config.HealthText
    if head then
        local hp, hv = project(head.Position)
        r.HeadDot.Position = UDim2.fromOffset(hp.X, hp.Y)
        r.HeadDot.Visible = Config.Head and hv
    else r.HeadDot.Visible = false end
    r.Tracer.Visible = false
    if Config.Tracer then
        local viewport = Camera.ViewportSize
        setLine(r.Tracer, Vector2.new(viewport.X/2, viewport.Y-2), Vector2.new(centerX, maxY), Config.LineColor, Config.LineThickness)
    end
    for _, line in ipairs(r.Bones) do line.Visible = false end
    if Config.Skeleton then
        local links = character:FindFirstChild("UpperTorso") and SkeletonLinks or R6Links
        for i, link in ipairs(links) do
            local aPart, bPart = character:FindFirstChild(link[1]), character:FindFirstChild(link[2])
            local line = r.Bones[i]
            if aPart and bPart and line then
                local a, av = project(aPart.Position); local b, bv = project(bPart.Position)
                if av and bv then setLine(line, a, b, Config.SkeletonColor, Config.LineThickness) end
            end
        end
    end
    r.Highlight.Adornee = character
    r.Highlight.Enabled = Config.Highlight
    r.Highlight.FillColor = Config.HighlightColor
    r.Highlight.OutlineColor = Config.HighlightColor
end

--// Aim assist (QA-tagged characters only)
local function getAimTarget()
    local mouse = UserInputService:GetMouseLocation()
    local best, bestDistance = nil, Config.FOV
    for player, record in pairs(Records) do
        local character = player.Character
        if isQATarget(player, character) and character then
            local humanoid, root, head = getCharacterParts(character)
            local part = character:FindFirstChild(Config.AimPart) or head or root
            if humanoid and humanoid.Health > 0 and part then
                local worldDistance = (Camera.CFrame.Position - part.Position).Magnitude
                if worldDistance <= Config.MaxDistance then
                    local screen, visible = project(part.Position)
                    if visible then
                        local screenDistance = (screen - mouse).Magnitude
                        if screenDistance <= bestDistance then bestDistance = screenDistance; best = part end
                    end
                end
            end
        end
    end
    return best
end

local aimHeld = false
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Config.AimKey then aimHeld = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Config.AimKey then aimHeld = false end
end)

--// Player lifecycle
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then Records[player] = createRecord(player) end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then Records[player] = createRecord(player) end
end)
Players.PlayerRemoving:Connect(cleanupRecord)

--// Main update loop
local connection
connection = RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Camera
    FOVCircle.Visible = Config.ShowFOV and Config.AimEnabled
    FOVCircle.Size = UDim2.fromOffset(Config.FOV*2, Config.FOV*2)
    FOVCircle.Position = UDim2.fromOffset(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    for player, record in pairs(Records) do updateRecord(player, record) end
    if Config.AimEnabled and aimHeld then
        local target = getAimTarget()
        if target then
            local camPos = Camera.CFrame.Position
            local desired = CFrame.lookAt(camPos, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(desired, Config.Smoothness)
        end
    end
end)

--// Cleanup
Gui.Destroying:Connect(function()
    if connection then connection:Disconnect() end
    for player in pairs(Records) do cleanupRecord(player) end
end)

Logger:Info("Inicializado. Somente personagens com atributo URAF_QA_Target = true são exibidos/selecionados.")
