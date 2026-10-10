-- RSWA Cold War | Enemy ESP Lite
-- Solo jugadores del bando opuesto. Si no se conoce el equipo, no se muestra.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local me = Players.LocalPlayer
local V2, V3, RGB = Vector2.new, Vector3.new, Color3.fromRGB
local clamp = math.clamp
local draw = Drawing and Drawing.new
if not me or not draw then return end

-- Cold War (Grip Studios): universo 4750561026, lugar principal 13687899540.
-- No se bloquea la ejecucion en sublugares del mismo universo.
local CFG = {
    Enabled = true,
    Names = true,
    Health = true,
    Distance = true,
    Boxes = true,
    HealthBar = true,
    HeadDot = true,
    MaxDistance = 1500,
    UpdateRate = 30,
}
local THEME = {
    Enemy = RGB(255, 87, 91),
    Text = RGB(237, 242, 249),
    Accent = RGB(62, 210, 187),
    Dark = RGB(13, 17, 24),
    Surface = RGB(21, 27, 37),
}

local function isEnemy(player)
    if not player or player == me then return false end
    -- Preferir Team: soporta el cambio automatico de OTAN/Pacto.
    if me.Team and player.Team then
        return me.Team ~= player.Team
    end
    -- Si uno de los dos aun no tiene equipo asignado, ocultarlo.
    if me.Team or player.Team then return false end

    -- Compatibilidad con juegos que replican el bando como atributo.
    for _, key in ipairs({"Faction", "TeamName", "Side", "Alliance"}) do
        local a, b = me:GetAttribute(key), player:GetAttribute(key)
        if a ~= nil and b ~= nil then
            if tostring(a) == "" or tostring(b) == "" then return false end
            return tostring(a) ~= tostring(b)
        end
    end
    -- Ultimo recurso: TeamColor, pero nunca tratar neutrales como enemigos.
    if me.Neutral or player.Neutral then return false end
    return me.TeamColor ~= player.TeamColor
end

local function getRoot(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
end
local function getHead(model)
    local part = model and model:FindFirstChild("Head")
    return part and part:IsA("BasePart") and part or nil
end
local function projected(camera, position)
    local p, visible = camera:WorldToViewportPoint(position)
    if not visible or p.Z <= 0 then return nil end
    local size = camera.ViewportSize
    if p.X < 0 or p.Y < 0 or p.X > size.X or p.Y > size.Y then return nil end
    return V2(p.X, p.Y)
end

local function makeDrawings()
    local d = {}
    d.box = draw("Square")
    d.box.Filled = false
    d.box.Thickness = 1.5
    d.box.Color = THEME.Enemy
    d.box.Transparency = 1

    d.name = draw("Text")
    d.status = draw("Text")
    for _, t in ipairs({d.name, d.status}) do
        t.Center, t.Outline = true, true
        t.Font = 3
        t.OutlineColor = RGB(0, 0, 0)
        t.Color = THEME.Text
        t.Transparency = 1
    end
    d.name.Size, d.status.Size = 13, 11
    d.name.Color = THEME.Enemy

    d.dot = draw("Circle")
    d.dot.Filled = true
    d.dot.Radius = 3.5
    d.dot.NumSides = 16
    d.dot.Color = THEME.Enemy
    d.dot.Transparency = 1

    d.barBG, d.bar = draw("Line"), draw("Line")
    d.barBG.Thickness, d.bar.Thickness = 4, 2
    d.barBG.Color = RGB(8, 8, 8)
    d.barBG.Transparency, d.bar.Transparency = 0.75, 1

    for _, object in pairs(d) do object.Visible = false end
    return d
end
local function hide(d)
    if not d then return end
    for _, object in pairs(d) do object.Visible = false end
end
local function clear(d)
    if not d then return end
    for _, object in pairs(d) do pcall(function() object:Remove() end) end
end

-- Cache de jugadores; los dibujos se crean solo cuando hay enemigos visibles.
local cache = {}
local connections = {}
local function listen(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end
local function addPlayer(player)
    if player ~= me and not cache[player] then
        cache[player] = {drawings = nil, displayName = nil}
    end
end
local function removePlayer(player)
    local entry = cache[player]
    if not entry then return end
    clear(entry.drawings)
    cache[player] = nil
end
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
listen(Players.PlayerAdded, addPlayer)
listen(Players.PlayerRemoving, removePlayer)

local function updatePlayer(player, entry, camera, fromPosition)
    local d = entry.drawings
    if not CFG.Enabled or not isEnemy(player) then
        hide(d)
        return
    end
    local model = player.Character
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local root, head = getRoot(model), getHead(model)
    if not humanoid or humanoid.Health <= 0 or not root or not head then
        hide(d)
        return
    end

    local dist = (root.Position - fromPosition).Magnitude
    if dist > CFG.MaxDistance then
        hide(d)
        return
    end
    -- Compatible con modelos R6 y personajes con torso alternativo.
    local top = projected(camera, head.Position + V3(0, head.Size.Y * 0.5, 0))
    local bottom = projected(camera, root.Position - V3(0, 2.8, 0))
    local head2d = projected(camera, head.Position)
    if not top or not bottom or not head2d then
        hide(d)
        return
    end

    local height = math.max(math.abs(bottom.Y - top.Y), 14)
    local width = height * 0.46
    local center = (top.X + bottom.X) * 0.5
    local left = center - width * 0.5
    local upper = math.min(top.Y, bottom.Y)
    local lower = math.max(top.Y, bottom.Y)
    local hp = clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)

    if not d then
        d = makeDrawings()
        entry.drawings = d
    end

    if CFG.Boxes then
        d.box.Position = V2(left, upper)
        d.box.Size = V2(width, height)
        d.box.Visible = true
    else d.box.Visible = false end

    if CFG.Names then
        local display = player.DisplayName
        if entry.displayName ~= display then
            entry.displayName = display
            d.name.Text = display
        end
        d.name.Position = V2(center, upper - 17)
        d.name.Visible = true
    else d.name.Visible = false end

    if CFG.Health or CFG.Distance then
        local hpText = CFG.Health and (tostring(math.floor(hp * 100 + 0.5)) .. "%") or ""
        local rangeText = CFG.Distance and (tostring(math.floor(dist + 0.5)) .. " studs") or ""
        d.status.Text = CFG.Health and CFG.Distance and (hpText .. " | " .. rangeText)
            or (CFG.Health and hpText or rangeText)
        d.status.Position = V2(center, lower + 4)
        d.status.Visible = true
    else d.status.Visible = false end

    if CFG.HeadDot then
        d.dot.Position = head2d
        d.dot.Visible = true
    else d.dot.Visible = false end

    if CFG.HealthBar then
        local x = left - 6
        d.barBG.From, d.barBG.To = V2(x, upper), V2(x, lower)
        d.bar.From, d.bar.To = V2(x, lower), V2(x, lower - height * hp)
        d.bar.Color = RGB(245, 70, 80):Lerp(RGB(70, 242, 122), hp)
        d.barBG.Visible, d.bar.Visible = true, true
    else d.barBG.Visible, d.bar.Visible = false, false end
end

-- UI compacta, sin librerias ni solicitudes web.
local gui = Instance.new("ScreenGui")
gui.Name = "RSWA_ColdWar_EnemyESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local root = Instance.new("Frame")
root.Name = "Panel"
root.Size = UDim2.fromOffset(265, 333)
root.Position = UDim2.fromOffset(36, 75)
root.BackgroundColor3 = THEME.Dark
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = gui
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 9)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = THEME.Surface
header.BorderSizePixel = 0
header.Parent = root
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -74, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Text = "RSWA | Cold War | Enemies"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3, title.TextSize, title.Font = THEME.Text, 11, Enum.Font.GothamBold
title.ZIndex = 2
title.Parent = header

local function makeButton(label, rightOffset)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(27, 24)
    b.Position = UDim2.new(1, rightOffset, 0, 8)
    b.BackgroundColor3 = RGB(38, 45, 59)
    b.BorderSizePixel = 0
    b.Text = label
    b.TextColor3 = THEME.Text
    b.TextSize = 14
    b.Font = Enum.Font.GothamBold
    b.ZIndex = 5
    b.Parent = header
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end
local minimize = makeButton("−", -63)
local close = makeButton("×", -31)

local dragZone = Instance.new("TextButton")
dragZone.Size = UDim2.new(1, -70, 1, 0)
dragZone.Position = UDim2.fromOffset(0, 0)
dragZone.BackgroundTransparency = 1
dragZone.Text = ""
dragZone.Active = true
dragZone.ZIndex = 4
dragZone.Parent = header

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
padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
local layout = Instance.new("UIListLayout", body)
layout.Padding = UDim.new(0, 5)

local function makeRow(label)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 31)
    line.BackgroundColor3 = THEME.Surface
    line.BorderSizePixel = 0
    line.Parent = body
    Instance.new("UICorner", line).CornerRadius = UDim.new(0, 5)
    local text = Instance.new("TextLabel")
    text.Text = label
    text.Size = UDim2.new(1, -90, 1, 0)
    text.Position = UDim2.fromOffset(9, 0)
    text.BackgroundTransparency = 1
    text.TextColor3, text.Font, text.TextSize = THEME.Text, Enum.Font.Gotham, 11
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Parent = line
    return line
end
local function makeToggle(label, field)
    local line = makeRow(label)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(50, 20)
    button.Position = UDim2.new(1, -58, 0.5, -10)
    button.BorderSizePixel = 0
    button.TextSize = 10
    button.Font = Enum.Font.GothamBold
    button.Parent = line
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 5)
    local function refresh()
        button.Text = CFG[field] and "ON" or "OFF"
        button.BackgroundColor3 = CFG[field] and RGB(35, 112, 105) or RGB(48, 54, 68)
        button.TextColor3 = CFG[field] and THEME.Accent or THEME.Text
    end
    button.MouseButton1Click:Connect(function()
        CFG[field] = not CFG[field]
        refresh()
    end)
    refresh()
end
local function makeNumber(label, field, min, max, step)
    local line = makeRow(label)
    local readout = Instance.new("TextLabel")
    readout.Size = UDim2.fromOffset(45, 20)
    readout.Position = UDim2.new(1, -75, 0.5, -10)
    readout.BackgroundTransparency = 1
    readout.TextSize, readout.Font, readout.TextColor3 = 10, Enum.Font.GothamMedium, THEME.Accent
    readout.Parent = line
    local function control(text, position, delta)
        local button = Instance.new("TextButton")
        button.Size = UDim2.fromOffset(19, 20)
        button.Position = UDim2.new(1, position, 0.5, -10)
        button.Text, button.TextSize = text, 12
        button.TextColor3, button.BackgroundColor3 = THEME.Text, RGB(38, 45, 59)
        button.BorderSizePixel = 0
        button.Parent = line
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
        button.MouseButton1Click:Connect(function()
            CFG[field] = clamp(CFG[field] + delta, min, max)
            readout.Text = tostring(CFG[field])
        end)
    end
    control("−", -98, -step)
    control("+", -25, step)
    readout.Text = tostring(CFG[field])
end

makeToggle("Enemy ESP", "Enabled")
makeToggle("Names", "Names")
makeToggle("Health", "Health")
makeToggle("Distance", "Distance")
makeToggle("Boxes", "Boxes")
makeToggle("Health Bar", "HealthBar")
makeToggle("Head Dot", "HeadDot")
makeNumber("Max Distance", "MaxDistance", 100, 3500, 100)
makeNumber("Refresh Hz", "UpdateRate", 10, 60, 5)

local minimized, expandedSize = false, root.Size
minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        expandedSize = root.Size
        body.Visible = false
        root.Size = UDim2.fromOffset(180, 40)
        minimize.Text = "+"
    else
        root.Size = expandedSize
        body.Visible = true
        minimize.Text = "−"
    end
end)
local dragging, startMouse, startPanel = false, nil, nil
listen(dragZone.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startMouse, startPanel = input.Position, root.Position
    end
end)
listen(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
listen(UIS.InputChanged, function(input)
    if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = input.Position - startMouse
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or V2(1280, 720)
    local px = clamp(startPanel.X.Offset + delta.X, 0, math.max(0, viewport.X - root.AbsoluteSize.X))
    local py = clamp(startPanel.Y.Offset + delta.Y, 0, math.max(0, viewport.Y - 40))
    root.Position = UDim2.fromOffset(px, py)
end)

local running = true
local function stop()
    if not running then return end
    running = false
    for _, c in ipairs(connections) do c:Disconnect() end
    for player in pairs(cache) do removePlayer(player) end
    if gui.Parent then gui:Destroy() end
end
close.MouseButton1Click:Connect(stop)
gui.Destroying:Connect(stop)

local accumulator = 0
listen(RunService.RenderStepped, function(dt)
    accumulator = accumulator + dt
    if accumulator < 1 / clamp(CFG.UpdateRate, 10, 60) then return end
    accumulator = 0
    local camera = Workspace.CurrentCamera
    if not camera then
        for _, e in pairs(cache) do hide(e.drawings) end
        return
    end
    local ownRoot = getRoot(me.Character)
    local reference = ownRoot and ownRoot.Position or camera.CFrame.Position
    for player, entry in pairs(cache) do
        updatePlayer(player, entry, camera, reference)
    end
end)
