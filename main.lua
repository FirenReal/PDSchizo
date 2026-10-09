-- RSWA ESP UltraLite
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local DrawingNew = Drawing and Drawing.new
if not DrawingNew then return end

local V2, RGB = Vector2.new, Color3.fromRGB
local clamp = math.clamp

local CFG = {
    Enabled = true,
    Players = true,
    AI = true,
    Names = true,
    Health = true,
    Distance = true,
    Boxes = true,
    HealthBar = true,
    HeadDot = true,
    TeamCheck = false,
    MaxDistance = 1200,
    UpdateRate = 30,
}

local COLORS = {
    Player = RGB(255, 220, 80),
    Enemy = RGB(255, 85, 85),
    Team = RGB(80, 235, 130),
    AI = RGB(65, 205, 255),
    Text = RGB(235, 240, 246),
    Black = RGB(0, 0, 0),
    HealthLow = RGB(255, 65, 65),
    HealthHigh = RGB(70, 255, 105),
}

local function getHumanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end

local function getHead(model)
    local head = model and model:FindFirstChild("Head")
    return head and head:IsA("BasePart") and head or nil
end

local function getRoot(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
end

local function isOnScreen(camera, point, visible)
    if not camera or not point or not visible or point.Z <= 0 then return false end
    local size = camera.ViewportSize
    return point.X >= 0 and point.X <= size.X and point.Y >= 0 and point.Y <= size.Y
end

local function sameTeam(player)
    return player and player.TeamColor == LocalPlayer.TeamColor
end

local function newText(size)
    local d = DrawingNew("Text")
    d.Visible = false
    d.Center = true
    d.Outline = true
    d.OutlineColor = COLORS.Black
    d.Font = 3
    d.Size = size
    d.Color = COLORS.Text
    d.Transparency = 1
    return d
end

local function newLine(thickness)
    local d = DrawingNew("Line")
    d.Visible = false
    d.Thickness = thickness or 1
    d.Transparency = 1
    return d
end

local function newCircle()
    local d = DrawingNew("Circle")
    d.Visible = false
    d.Filled = true
    d.Radius = 4
    d.NumSides = 18
    d.Transparency = 1
    return d
end

local function createDrawings()
    local d = {
        name = newText(13),
        status = newText(11),
        dot = newCircle(),
        barBG = newLine(4),
        bar = newLine(2),
        box = {},
    }
    d.barBG.Color = RGB(6, 6, 6)
    d.barBG.Transparency = 0.65
    for i = 1, 8 do d.box[i] = newLine(1) end
    return d
end

local function hideDrawings(d)
    d.name.Visible = false
    d.status.Visible = false
    d.dot.Visible = false
    d.barBG.Visible = false
    d.bar.Visible = false
    for _, line in ipairs(d.box) do line.Visible = false end
end

local function destroyDrawings(d)
    if not d then return end
    d.name:Remove()
    d.status:Remove()
    d.dot:Remove()
    d.barBG:Remove()
    d.bar:Remove()
    for _, line in ipairs(d.box) do line:Remove() end
end

local PlayerCache, AICache = {}, {}

local function addPlayer(player)
    if player == LocalPlayer or PlayerCache[player] then return end
    PlayerCache[player] = {drawings = createDrawings()}
end

local function removePlayer(player)
    local data = PlayerCache[player]
    if not data then return end
    destroyDrawings(data.drawings)
    PlayerCache[player] = nil
end

local function isAI(model)
    if not model or not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    return getHumanoid(model) ~= nil and getHead(model) ~= nil
end

local function addAI(model)
    if not isAI(model) or AICache[model] then return end
    AICache[model] = {drawings = createDrawings()}
end

local function removeAI(model)
    local data = AICache[model]
    if not data then return end
    destroyDrawings(data.drawings)
    AICache[model] = nil
end

for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Humanoid") and obj.Parent then addAI(obj.Parent) end
end

Workspace.DescendantAdded:Connect(function(obj)
    local model
    if obj:IsA("Humanoid") then
        model = obj.Parent
    elseif obj:IsA("BasePart") and obj.Name == "Head" then
        model = obj.Parent
    end
    if model and model:IsA("Model") then
        task.defer(function()
            task.wait(0.08)
            addAI(model)
        end)
    end
end)

local function getColor(player, aiModel)
    if aiModel then return COLORS.AI end
    if CFG.TeamCheck then return sameTeam(player) and COLORS.Team or COLORS.Enemy end
    return COLORS.Player
end

local function setCornerBox(lines, minX, minY, maxX, maxY, color)
    local width, height = maxX - minX, maxY - minY
    local cx, cy = clamp(width * 0.23, 5, 20), clamp(height * 0.18, 5, 22)
    local p = {
        {V2(minX, minY), V2(minX + cx, minY)},
        {V2(minX, minY), V2(minX, minY + cy)},
        {V2(maxX, minY), V2(maxX - cx, minY)},
        {V2(maxX, minY), V2(maxX, minY + cy)},
        {V2(minX, maxY), V2(minX + cx, maxY)},
        {V2(minX, maxY), V2(minX, maxY - cy)},
        {V2(maxX, maxY), V2(maxX - cx, maxY)},
        {V2(maxX, maxY), V2(maxX, maxY - cy)},
    }
    for i, line in ipairs(lines) do
        line.From, line.To = p[i][1], p[i][2]
        line.Color = color
        line.Visible = true
    end
end

local function updateEntity(data, model, player, aiModel, localRoot, camera)
    local d = data.drawings

    if not CFG.Enabled or (aiModel and not CFG.AI) or (not aiModel and not CFG.Players) then
        hideDrawings(d)
        return
    end

    if not model or not model.Parent then
        hideDrawings(d)
        return "remove"
    end

    if aiModel and Players:GetPlayerFromCharacter(model) then
        hideDrawings(d)
        return "remove"
    end

    local humanoid, root, head = getHumanoid(model), getRoot(model), getHead(model)
    if not humanoid or humanoid.Health <= 0 or not root or not head or not localRoot then
        hideDrawings(d)
        return
    end

    local distance = (root.Position - localRoot.Position).Magnitude
    if distance > CFG.MaxDistance then
        hideDrawings(d)
        return
    end

    local rootPoint, rootVisible = camera:WorldToViewportPoint(root.Position)
    local headPoint, headVisible = camera:WorldToViewportPoint(head.Position)
    if not isOnScreen(camera, rootPoint, rootVisible) or not isOnScreen(camera, headPoint, headVisible) then
        hideDrawings(d)
        return
    end

    local headRoot = math.max(math.abs(rootPoint.Y - headPoint.Y), 6)
    local minY = headPoint.Y - headRoot * 0.65
    local maxY = rootPoint.Y + headRoot * 2.1
    local height = maxY - minY
    local halfWidth = height * 0.24
    local centerX = rootPoint.X
    local minX, maxX = centerX - halfWidth, centerX + halfWidth

    local color = getColor(player, aiModel)
    local health = clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)

    if CFG.Names then
        if aiModel then
            d.name.Text = model.Name
        else
            d.name.Text = player.DisplayName ~= player.Name and (player.DisplayName .. " [" .. player.Name .. "]") or player.Name
        end
        d.name.Position = V2(centerX, minY - 17)
        d.name.Color = color
        d.name.Visible = true
    else
        d.name.Visible = false
    end

    local info = {}
    if CFG.Health then info[#info + 1] = tostring(math.floor(health * 100 + 0.5)) .. "%" end
    if CFG.Distance then info[#info + 1] = tostring(math.floor(distance + 0.5)) .. " studs" end
    d.status.Text = table.concat(info, "  •  ")
    d.status.Position = V2(centerX, maxY + 3)
    d.status.Visible = #info > 0

    if CFG.HeadDot then
        d.dot.Position = V2(headPoint.X, headPoint.Y)
        d.dot.Color = color
        d.dot.Visible = true
    else
        d.dot.Visible = false
    end

    if CFG.Boxes then
        setCornerBox(d.box, minX, minY, maxX, maxY, color)
    else
        for _, line in ipairs(d.box) do line.Visible = false end
    end

    if CFG.HealthBar then
        local x = minX - 6
        d.barBG.From, d.barBG.To = V2(x, minY), V2(x, maxY)
        d.bar.From = V2(x, maxY - height * health)
        d.bar.To = V2(x, maxY)
        d.bar.Color = COLORS.HealthLow:Lerp(COLORS.HealthHigh, health)
        d.barBG.Visible, d.bar.Visible = true, true
    else
        d.barBG.Visible, d.bar.Visible = false, false
    end
end

-- UI
local old = CoreGui:FindFirstChild("RSWA_ESP_Lite")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RSWA_ESP_Lite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local root = Instance.new("Frame")
root.Size = UDim2.fromOffset(300, 390)
root.Position = UDim2.fromOffset(35, 70)
root.BackgroundColor3 = RGB(13, 17, 24)
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = gui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 9)

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 40)
top.BackgroundColor3 = RGB(18, 23, 32)
top.BorderSizePixel = 0
top.Active = true
top.Parent = root

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "RSWA ESP Lite"
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = RGB(235, 240, 246)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = top

local minButton = Instance.new("TextButton")
minButton.Size = UDim2.fromOffset(28, 24)
minButton.Position = UDim2.new(1, -64, 0, 8)
minButton.BackgroundColor3 = RGB(28, 34, 45)
minButton.BorderSizePixel = 0
minButton.Text = "−"
minButton.TextColor3 = RGB(180, 190, 205)
minButton.Font = Enum.Font.GothamBold
minButton.TextSize = 14
minButton.Parent = top
Instance.new("UICorner", minButton).CornerRadius = UDim.new(0, 5)

local closeButton = minButton:Clone()
closeButton.Position = UDim2.new(1, -32, 0, 8)
closeButton.Text = "×"
closeButton.Parent = top

local body = Instance.new("ScrollingFrame")
body.Position = UDim2.fromOffset(0, 40)
body.Size = UDim2.new(1, 0, 1, -40)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 3
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.CanvasSize = UDim2.fromOffset(0, 0)
body.Parent = root

local padding = Instance.new("UIPadding", body)
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)

local layout = Instance.new("UIListLayout", body)
layout.Padding = UDim.new(0, 5)

local function row(label)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = RGB(21, 26, 36)
    f.BorderSizePixel = 0
    f.Parent = body
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -78, 1, 0)
    l.Position = UDim2.fromOffset(10, 0)
    l.BackgroundTransparency = 1
    l.Text = label
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.TextColor3 = RGB(225, 232, 240)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    return f
end

local function toggle(label, key)
    local f = row(label)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(52, 20)
    b.Position = UDim2.new(1, -62, 0.5, -10)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    local function render()
        local enabled = CFG[key]
        b.Text = enabled and "ON" or "OFF"
        b.BackgroundColor3 = enabled and RGB(35, 112, 105) or RGB(43, 49, 62)
        b.TextColor3 = enabled and RGB(110, 255, 225) or RGB(160, 170, 185)
    end
    b.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        render()
    end)
    render()
end

local function numberControl(label, key, minValue, maxValue, step)
    local f = row(label)
    local minus = Instance.new("TextButton")
    minus.Size = UDim2.fromOffset(22, 20)
    minus.Position = UDim2.new(1, -106, 0.5, -10)
    minus.BackgroundColor3 = RGB(31, 37, 49)
    minus.BorderSizePixel = 0
    minus.Text = "−"
    minus.TextColor3 = RGB(220, 225, 235)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 11
    minus.Parent = f
    Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 5)
    local value = Instance.new("TextLabel")
    value.Size = UDim2.fromOffset(52, 20)
    value.Position = UDim2.new(1, -82, 0.5, -10)
    value.BackgroundTransparency = 1
    value.TextColor3 = RGB(80, 220, 195)
    value.Font = Enum.Font.GothamMedium
    value.TextSize = 9
    value.Parent = f
    local plus = minus:Clone()
    plus.Position = UDim2.new(1, -26, 0.5, -10)
    plus.Text = "+"
    plus.Parent = f
    local function render() value.Text = tostring(CFG[key]) end
    minus.MouseButton1Click:Connect(function()
        CFG[key] = clamp(CFG[key] - step, minValue, maxValue)
        render()
    end)
    plus.MouseButton1Click:Connect(function()
        CFG[key] = clamp(CFG[key] + step, minValue, maxValue)
        render()
    end)
    render()
end

toggle("ESP", "Enabled")
toggle("Players", "Players")
toggle("AI / NPC", "AI")
toggle("Names", "Names")
toggle("Health", "Health")
toggle("Distance", "Distance")
toggle("Boxes", "Boxes")
toggle("Health Bar", "HealthBar")
toggle("Head Dot", "HeadDot")
toggle("Team Check", "TeamCheck")
numberControl("Max Distance", "MaxDistance", 100, 3000, 100)
numberControl("Update Rate", "UpdateRate", 10, 60, 5)

local minimized = false
local expandedSize = root.Size
minButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        expandedSize = root.Size
        body.Visible = false
        root.Size = UDim2.fromOffset(180, 40)
        minButton.Text = "+"
    else
        root.Size = expandedSize
        body.Visible = true
        minButton.Text = "−"
    end
end)

local running = true
closeButton.MouseButton1Click:Connect(function()
    running = false
    gui:Destroy()
    for _, data in pairs(PlayerCache) do destroyDrawings(data.drawings) end
    for _, data in pairs(AICache) do destroyDrawings(data.drawings) end
    table.clear(PlayerCache)
    table.clear(AICache)
end)

local dragging, dragStart, startPos = false, nil, nil
top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = root.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Update loop
local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
    if not running then return end
    accumulator += dt
    local interval = 1 / clamp(CFG.UpdateRate, 10, 60)
    if accumulator < interval then return end
    accumulator = 0

    local camera = Workspace.CurrentCamera
    local localRoot = getRoot(LocalPlayer.Character)
    if not camera or not localRoot then
        for _, data in pairs(PlayerCache) do hideDrawings(data.drawings) end
        for _, data in pairs(AICache) do hideDrawings(data.drawings) end
        return
    end

    local removePlayers = {}
    for player, data in pairs(PlayerCache) do
        if not player.Parent then
            removePlayers[#removePlayers + 1] = player
        else
            updateEntity(data, player.Character, player, false, localRoot, camera)
        end
    end
    for _, player in ipairs(removePlayers) do removePlayer(player) end

    local removeAIModels = {}
    for model, data in pairs(AICache) do
        local result = updateEntity(data, model, nil, true, localRoot, camera)
        if result == "remove" or not model.Parent then removeAIModels[#removeAIModels + 1] = model end
    end
    for _, model in ipairs(removeAIModels) do removeAI(model) end
end)
