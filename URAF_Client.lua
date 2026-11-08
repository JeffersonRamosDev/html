-- URAF Client - single-file client loader for YOUR Roblox experience.
-- Install the matching server endpoints in your own game before use.
-- This script does not bypass server checks or simulate protected server actions.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local old = playerGui:FindFirstChild("URAF_GUI")
if old then old:Destroy() end

local CONFIG = {
    FarmTargetId = "sample_ore",       -- change to a target ID registered by your server
    FarmInterval = 1.0,
    RaidDifficulty = "Normal",         -- must be allowed by your server
    RaidStageIds = { "stage_1" },      -- stage IDs registered by your server
    ItemId = "sword_wood",             -- must belong to the player; server must verify ownership
    ClickInterval = 0.10,
}

local running = { farm = false, raid = false, click = false }
local connections = {}
local remotesFolder
local function getRemote(name)
    remotesFolder = remotesFolder or ReplicatedStorage:FindFirstChild("URAF")
    remotesFolder = remotesFolder and remotesFolder:FindFirstChild("Remotes")
    return remotesFolder and remotesFolder:FindFirstChild(name)
end

local function invoke(name, ...)
    local remote = getRemote(name)
    if not remote or not remote:IsA("RemoteFunction") then
        return false, "RemoteFunction ausente: " .. name
    end
    local args = table.pack(...)
    local ok, result = pcall(function()
        return remote:InvokeServer(table.unpack(args, 1, args.n))
    end)
    if not ok then return false, tostring(result) end
    return result == true, result
end

local gui = Instance.new("ScreenGui")
gui.Name = "URAF_GUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.fromOffset(330, 390)
frame.Position = UDim2.new(0.5, -165, 0.5, -195)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(105, 75, 190)
stroke.Thickness = 1.5
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -44, 0, 42)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "URAF  |  CONTROL PANEL"
title.TextColor3 = Color3.fromRGB(235, 225, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 28)
close.Position = UDim2.new(1, -38, 0, 7)
close.BackgroundColor3 = Color3.fromRGB(150, 55, 65)
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 14
close.Parent = frame
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 34)
status.Position = UDim2.fromOffset(12, 46)
status.BackgroundColor3 = Color3.fromRGB(33, 33, 44)
status.Text = "Status: aguardando remotes do servidor"
status.TextColor3 = Color3.fromRGB(205, 205, 215)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextWrapped = true
status.Parent = frame
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)

local function setStatus(msg, ok)
    status.Text = "Status: " .. tostring(msg)
    status.TextColor3 = ok and Color3.fromRGB(140, 235, 165) or Color3.fromRGB(255, 170, 150)
end

local function makeLabel(text, y)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.fromOffset(12, y)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(185, 180, 200)
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    return label
end

local function makeInput(placeholder, value, y)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -24, 0, 30)
    box.Position = UDim2.fromOffset(12, y)
    box.BackgroundColor3 = Color3.fromRGB(38, 38, 51)
    box.TextColor3 = Color3.fromRGB(245, 245, 250)
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 155)
    box.PlaceholderText = placeholder
    box.Text = value
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.Parent = frame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    return box
end

local function makeButton(text, x, y, width, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(width, 32)
    button.Position = UDim2.fromOffset(x, y)
    button.BackgroundColor3 = Color3.fromRGB(92, 65, 160)
    button.TextColor3 = Color3.new(1,1,1)
    button.Text = text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    button.MouseButton1Click:Connect(callback)
    return button
end

makeLabel("FARM TARGET ID", 88)
local farmInput = makeInput("ID cadastrado no servidor", CONFIG.FarmTargetId, 106)
makeButton("START FARM", 12, 142, 148, function()
    CONFIG.FarmTargetId = farmInput.Text
    if CONFIG.FarmTargetId == "" then setStatus("Informe um target ID", false); return end
    running.farm = not running.farm
    if running.farm then
        setStatus("Autofarm ligado", true)
        task.spawn(function()
            while running.farm do
                local ok, result = invoke("RequestFarmAction", CONFIG.FarmTargetId)
                if not ok then setStatus("Farm recusado/erro: " .. tostring(result), false) end
                task.wait(math.max(0.25, CONFIG.FarmInterval))
            end
        end)
    else
        setStatus("Autofarm desligado", true)
    end
end)
makeButton("STOP FARM", 170, 142, 148, function()
    running.farm = false
    setStatus("Autofarm desligado", true)
end)

makeLabel("RAID DIFFICULTY", 182)
local raidInput = makeInput("Dificuldade permitida", CONFIG.RaidDifficulty, 200)
makeButton("START RAID", 12, 236, 148, function()
    CONFIG.RaidDifficulty = raidInput.Text
    if running.raid then setStatus("Raid já está ativa", false); return end
    running.raid = true
    task.spawn(function()
        local ok, result = invoke("RequestRaidEnter", CONFIG.RaidDifficulty)
        if not ok then running.raid = false; setStatus("Entrada na raid recusada: " .. tostring(result), false); return end
        for _, stageId in ipairs(CONFIG.RaidStageIds) do
            if not running.raid then break end
            local stageOk, stageResult = invoke("RequestRaidStage", stageId)
            if not stageOk then setStatus("Etapa recusada: " .. tostring(stageResult), false); running.raid = false; return end
            task.wait(0.5)
        end
        if running.raid then
            local finishOk, finishResult = invoke("RequestRaidFinish")
            setStatus(finishOk and "Solicitação de conclusão enviada" or ("Finalização recusada: " .. tostring(finishResult)), finishOk)
        end
        running.raid = false
    end)
    setStatus("Solicitação de raid enviada", true)
end)
makeButton("STOP RAID", 170, 236, 148, function()
    running.raid = false
    setStatus("Raid interrompida no cliente", true)
end)

makeLabel("ITEM ID (SETITEM / EQUIPAR)", 276)
local itemInput = makeInput("ID do item que pertence ao jogador", CONFIG.ItemId, 294)
makeButton("EQUIP ITEM", 12, 334, 148, function()
    CONFIG.ItemId = itemInput.Text
    local ok, result = invoke("RequestEquipItem", CONFIG.ItemId)
    setStatus(ok and "Pedido de equipamento aceito" or ("Equip recusado: " .. tostring(result)), ok)
end)
makeButton("AUTOCLICK TICK", 170, 334, 148, function()
    if running.click then running.click = false; setStatus("AutoClick desligado", true); return end
    if not getRemote("RequestClick") then
        setStatus("Falta RequestClick no servidor; não há clique sintético oficial", false)
        return
    end
    running.click = true
    setStatus("AutoClick lógico ligado", true)
    task.spawn(function()
        while running.click do
            local ok, result = invoke("RequestClick")
            if not ok then setStatus("Click recusado: " .. tostring(result), false) end
            task.wait(math.max(0.05, CONFIG.ClickInterval))
        end
    end)
end)

-- Drag window
local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

close.MouseButton1Click:Connect(function()
    running.farm = false; running.raid = false; running.click = false
    gui:Destroy()
end)

print("[URAF] Client carregado. Configure os IDs e os endpoints no servidor do seu jogo.")
