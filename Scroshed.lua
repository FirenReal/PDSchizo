-- RSWA Scorched Earth | ESP + Zoom + Aimbot
-- Basado en modelos replicados con Humanoid + Head (R6/R15/custom).
-- Sin funciones de evasión ni modificaciones de armas.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local me = Players.LocalPlayer
if not me then return end

local draw = Drawing and Drawing.new
if type(draw) ~= "function" then
    warn("RSWA: este entorno no dispone de Drawing API.")
    return
end

local V2, V3, RGB = Vector2.new, Vector3.new, Color3.fromRGB
local clamp = math.clamp
local CFG = {
    ESP = true, Players = true, NPC = false,
    Names = true, Health = true, Distance = true,
    Boxes = true, HeadDot = true, HealthBar = true,
    TeamFilter = true, MaxDistance = 2200, UpdateHz = 25,
    Zoom = true, ZoomFOV = 25, ZoomKey = Enum.KeyCode.Z, ZoomMode = "Hold",
    Aimbot = false, AimPlayers = true, AimNPC = false, AimEnemyOnly = true,
    AimKey = Enum.KeyCode.P, AimTrigger = "Key", AimMode = "Hold",
    AimBone = "Head", AimSelect = "Cursor", AimSmooth = 0.35,
    AimFOV = true, AimFOVRadius = 155, AimMaxDistance = 1900,
}
local COLOR = {
    Player = RGB(255, 205, 75), NPC = RGB(60, 204, 255),
    Ally = RGB(96, 235, 140), Text = RGB(240, 245, 250),
    UI = RGB(13, 17, 24), Panel = RGB(21, 27, 38),
    Accent = RGB(65, 214, 191), Muted = RGB(160, 172, 187),
}

local alive, connections = true, {}
local playerCache, npcCache = {}, {}
local function listen(signal, fn)
    local c = signal:Connect(fn)
    connections[#connections + 1] = c
    return c
end
local function humanoid(model)
    return model and model:FindFirstChildOfClass("Humanoid")
end
local function head(model)
    local h = model and model:FindFirstChild("Head")
    return h and h:IsA("BasePart") and h or nil
end
local function rootPart(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
        or head(model)
end
local function projected(cam, position)
    local p, visible = cam:WorldToViewportPoint(position)
    local size = cam.ViewportSize
    if not visible or p.Z <= 0 or p.X < 0 or p.Y < 0
        or p.X > size.X or p.Y > size.Y then
        return nil
    end
    return V2(p.X, p.Y)
end
local function teamRelation(p)
    if not p then return nil end
    if me.Team and p.Team then return p.Team == me.Team end
    if not me.Neutral and not p.Neutral then
        return p.TeamColor == me.TeamColor
    end
    return nil -- Equipo desconocido: no marcar como rival
end
local function sameTeam(p)
    return teamRelation(p) == true
end
local function isEnemy(p)
    return teamRelation(p) == false
end

local function makeDrawings()
    local d = {
        box = draw("Square"), name = draw("Text"),
        status = draw("Text"), dot = draw("Circle"),
        barBg = draw("Line"), bar = draw("Line"),
    }
    d.box.Filled, d.box.Thickness = false, 1.5
    d.dot.Filled, d.dot.Radius, d.dot.NumSides = true, 4, 20
    d.barBg.Thickness, d.bar.Thickness = 4, 2
    d.barBg.Color, d.barBg.Transparency = RGB(6, 8, 11), 0.8
    for _, t in ipairs({d.name, d.status}) do
        t.Center, t.Outline = true, true
        t.OutlineColor, t.Color = RGB(0, 0, 0), COLOR.Text
        t.Font, t.Transparency = 3, 1
    end
    d.name.Size, d.status.Size = 13, 11
    for _, obj in pairs(d) do obj.Visible = false end
    return d
end
local function hide(d)
    if not d then return end
    for _, obj in pairs(d) do obj.Visible = false end
end
local function removeDrawings(d)
    if not d then return end
    for _, obj in pairs(d) do pcall(function() obj:Remove() end) end
end
local function addPlayer(p)
    if p ~= me and not playerCache[p] then playerCache[p] = {d = nil} end
end
local function removePlayer(p)
    local e = playerCache[p]
    if e then removeDrawings(e.d); playerCache[p] = nil end
end
local function isNPC(model)
    return model and model:IsA("Model") and humanoid(model) ~= nil
        and head(model) ~= nil and not Players:GetPlayerFromCharacter(model)
end
local function addNPC(model)
    if alive and not npcCache[model] and isNPC(model) then
        npcCache[model] = {d = nil}
    end
end
local function removeNPC(model)
    local e = npcCache[model]
    if e then removeDrawings(e.d); npcCache[model] = nil end
end

for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
listen(Players.PlayerAdded, addPlayer)
listen(Players.PlayerRemoving, removePlayer)
-- Un solo escaneo inicial; los nuevos modelos entran por eventos.
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Humanoid") then addNPC(obj.Parent) end
end
listen(Workspace.DescendantAdded, function(obj)
    local model
    if obj:IsA("Humanoid") then model = obj.Parent
    elseif obj:IsA("BasePart") and obj.Name == "Head" then model = obj.Parent end
    if model and model:IsA("Model") then
        task.delay(0.12, function() if alive then addNPC(model) end end)
    end
end)

local function updateESP(e, model, p, npc, cam, origin)
    local d = e.d
    if not CFG.ESP or (npc and not CFG.NPC) or (not npc and not CFG.Players)
        or not model or not model.Parent
        or (p and CFG.TeamFilter and not isEnemy(p))
        or (npc and Players:GetPlayerFromCharacter(model)) then
        hide(d)
        return
    end
    local hum, h, r = humanoid(model), head(model), rootPart(model)
    if not hum or hum.Health <= 0 or not h or not r then hide(d); return end
    local dist = (r.Position - origin).Magnitude
    if dist > CFG.MaxDistance then hide(d); return end
    local top = projected(cam, h.Position + V3(0, h.Size.Y * 0.5, 0))
    local bottom = projected(cam, r.Position - V3(0, 2.8, 0))
    local head2d = projected(cam, h.Position)
    if not top or not bottom or not head2d then hide(d); return end

    local upper, lower = math.min(top.Y, bottom.Y), math.max(top.Y, bottom.Y)
    local height = math.max(lower - upper, 14)
    local width = height * 0.46
    local center = (top.X + bottom.X) * 0.5
    local left = center - width / 2
    local hp = clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local c = npc and COLOR.NPC or (p and sameTeam(p) and COLOR.Ally or COLOR.Player)
    if not d then
        d = makeDrawings()
        e.d = d
    end
    if CFG.Boxes then
        d.box.Position, d.box.Size = V2(left, upper), V2(width, height)
        d.box.Color, d.box.Visible = c, true
    else d.box.Visible = false end
    if CFG.Names then
        d.name.Text = npc and model.Name or (p.DisplayName or p.Name)
        d.name.Position, d.name.Color = V2(center, upper - 18), c
        d.name.Visible = true
    else d.name.Visible = false end
    if CFG.Health or CFG.Distance then
        local hpText = tostring(math.floor(hp * 100 + 0.5)) .. "%"
        local distanceText = tostring(math.floor(dist + 0.5)) .. " studs"
        d.status.Text = CFG.Health and CFG.Distance and (hpText .. " | " .. distanceText)
            or (CFG.Health and hpText or distanceText)
        d.status.Position, d.status.Visible = V2(center, lower + 4), true
    else d.status.Visible = false end
    if CFG.HeadDot then
        d.dot.Position, d.dot.Color, d.dot.Visible = head2d, c, true
    else d.dot.Visible = false end
    if CFG.HealthBar then
        local x = left - 6
        d.barBg.From, d.barBg.To = V2(x, upper), V2(x, lower)
        d.bar.From, d.bar.To = V2(x, lower), V2(x, lower - height * hp)
        d.bar.Color = RGB(245, 70, 70):Lerp(RGB(65, 245, 100), hp)
        d.barBg.Visible, d.bar.Visible = true, true
    else d.barBg.Visible, d.bar.Visible = false, false end
end

-- Aimbot opcional, separado del ESP.
local aimActive, captureAimKey, selectedTarget = false, false, nil
local aimAccumulator = 0
local fovCircle = draw("Circle")
fovCircle.Visible, fovCircle.Filled = false, false
fovCircle.Thickness, fovCircle.NumSides = 1.5, 64
fovCircle.Color, fovCircle.Transparency = COLOR.Accent, 0.86

local function cursorPos(cam)
    local size = cam.ViewportSize
    -- Los FPS con cursor bloqueado apuntan al centro.
    if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return V2(size.X * 0.5, size.Y * 0.5)
    end
    local loc = UIS:GetMouseLocation()
    return V2(loc.X, loc.Y)
end

local function aimWorldPosition(model)
    local r = rootPart(model)
    if not r then return nil end
    local h = head(model)
    if CFG.AimBone == "Head" and h then return h.Position end
    if CFG.AimBone == "Neck" and h then
        return h.Position - V3(0, h.Size.Y * 0.5, 0)
    end
    if CFG.AimBone == "Feet" then return r.Position - V3(0, 2.5, 0) end
    return r.Position
end

local function findAimTarget(cam, origin, cursor)
    local best, bestDistance = nil, math.huge
    local function consider(model)
        if not model or not model.Parent then return end
        local hum, r = humanoid(model), rootPart(model)
        if not hum or hum.Health <= 0 or not r then return end
        local world = aimWorldPosition(model)
        if not world then return end
        local worldDistance = (r.Position - origin).Magnitude
        if worldDistance > CFG.AimMaxDistance then return end
        local screen = projected(cam, world)
        if not screen then return end
        local mouseDistance = (screen - cursor).Magnitude
        if CFG.AimFOV and mouseDistance > CFG.AimFOVRadius then return end
        local distance = CFG.AimSelect == "Character" and worldDistance or mouseDistance
        if distance < bestDistance then
            best, bestDistance = model, distance
        end
    end

    if CFG.AimPlayers then
        for p in pairs(playerCache) do
            if not CFG.AimEnemyOnly or isEnemy(p) then
                consider(p.Character)
            end
        end
    end
    if CFG.AimNPC then
        for model in pairs(npcCache) do
            if not Players:GetPlayerFromCharacter(model) then
                consider(model)
            end
        end
    end
    return best
end

local function resetAim()
    aimActive, selectedTarget, aimAccumulator = false, nil, 0
end

-- Zoom con FOV, tecla y modo configurables.
local zoomActive, savedFOV, savedCamera = false, nil, nil
local function zoomOff()
    if savedCamera and savedCamera.Parent and savedFOV then
        pcall(function() savedCamera.FieldOfView = savedFOV end)
    end
    zoomActive, savedCamera, savedFOV = false, nil, nil
end
local function zoomOn()
    if not CFG.Zoom then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if not zoomActive then
        savedFOV, savedCamera = cam.FieldOfView, cam
    end
    zoomActive = true
end
local captureKey = false
listen(UIS.InputBegan, function(input, consumed)
    if not alive then return end
    if captureKey or captureAimKey then return end
    if consumed or UIS:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == CFG.ZoomKey and CFG.Zoom then
        if CFG.ZoomMode == "Toggle" then
            if zoomActive then zoomOff() else zoomOn() end
        else zoomOn() end
    end
    if not CFG.Aimbot then return end
    local pressed = (CFG.AimTrigger == "Mouse2"
            and input.UserInputType == Enum.UserInputType.MouseButton2)
        or (CFG.AimTrigger == "Key"
            and input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == CFG.AimKey)
    if pressed then
        if CFG.AimMode == "Toggle" then
            aimActive = not aimActive
        else
            aimActive = true
        end
    end
end)
listen(UIS.InputEnded, function(input)
    if not alive then return end
    if CFG.ZoomMode == "Hold" and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == CFG.ZoomKey then zoomOff() end
    if CFG.AimMode == "Hold" then
        local released = (CFG.AimTrigger == "Mouse2"
                and input.UserInputType == Enum.UserInputType.MouseButton2)
            or (CFG.AimTrigger == "Key"
                and input.UserInputType == Enum.UserInputType.Keyboard
                and input.KeyCode == CFG.AimKey)
        if released then resetAim() end
    end
end)

-- UI compacta RSWA.
local oldGui = CoreGui:FindFirstChild("RSWA_ScorchedEarth")
if oldGui then oldGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "RSWA_ScorchedEarth", true, false
gui.Parent = CoreGui
local function make(class, props)
    local item = Instance.new(class)
    for k, v in pairs(props) do item[k] = v end
    return item
end
local function roundBox(item, n)
    make("UICorner", {CornerRadius = UDim.new(0, n or 6), Parent = item})
end
local panel = make("Frame", {
    Name = "Panel", Position = UDim2.fromOffset(44, 65), Size = UDim2.fromOffset(345, 530),
    BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, ClipsDescendants = true, Parent = gui,
})
roundBox(panel, 10)
local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = COLOR.Panel,
    BorderSizePixel = 0, Parent = panel,
})
local title = make("TextLabel", {
    Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -95, 1, 0),
    BackgroundTransparency = 1, Text = "RSWA | SCORCHED EARTH", Font = Enum.Font.GothamBold,
    TextSize = 13, TextColor3 = COLOR.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
})
local minBtn = make("TextButton", {
    Position = UDim2.new(1, -70, 0, 8), Size = UDim2.fromOffset(28, 26),
    Text = "−", Font = Enum.Font.GothamBold, TextSize = 17,
    TextColor3 = COLOR.Text, BackgroundColor3 = COLOR.UI, BorderSizePixel = 0,
    ZIndex = 7, Parent = header,
})
roundBox(minBtn)
local closeBtn = make("TextButton", {
    Position = UDim2.new(1, -36, 0, 8), Size = UDim2.fromOffset(28, 26),
    Text = "×", Font = Enum.Font.GothamBold, TextSize = 15,
    TextColor3 = COLOR.Text, BackgroundColor3 = COLOR.UI, BorderSizePixel = 0,
    ZIndex = 7, Parent = header,
})
roundBox(closeBtn)
local dragZone = make("TextButton", {
    Size = UDim2.new(1, -80, 1, 0), BackgroundTransparency = 1,
    BorderSizePixel = 0, Text = "", Active = true,
    ZIndex = 6, Parent = header,
})
local scroll = make("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -42),
    BorderSizePixel = 0, BackgroundTransparency = 1, ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLOR.Accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0), Parent = panel,
})
make("UIPadding", {PaddingTop = UDim.new(0, 9), PaddingLeft = UDim.new(0, 9),
    PaddingRight = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), Parent = scroll})
make("UIListLayout", {Padding = UDim.new(0, 5), Parent = scroll})
local function row(label)
    local f = make("Frame", {Size = UDim2.new(1, -3, 0, 32), BackgroundColor3 = COLOR.Panel,
        BorderSizePixel = 0, Parent = scroll})
    roundBox(f)
    make("TextLabel", {Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -115, 1, 0),
        BackgroundTransparency = 1, Text = label, Font = Enum.Font.Gotham,
        TextSize = 10, TextColor3 = COLOR.Text, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f})
    return f
end
local function toggle(label, key, action)
    local f = row(label)
    local b = make("TextButton", {Position = UDim2.new(1, -66, 0.5, -11), Size = UDim2.fromOffset(56, 22),
        BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 10, Parent = f})
    roundBox(b)
    local function refresh()
        b.Text = CFG[key] and "ON" or "OFF"
        b.BackgroundColor3 = CFG[key] and RGB(32, 113, 102) or RGB(42, 48, 59)
        b.TextColor3 = CFG[key] and COLOR.Accent or COLOR.Muted
    end
    listen(b.MouseButton1Click, function()
        CFG[key] = not CFG[key]
        if action then action(CFG[key]) end
        refresh()
    end)
    refresh()
end
local function numberRow(label, key, minValue, maxValue, step, suffix)
    local f = row(label)
    local bMinus = make("TextButton", {Position = UDim2.new(1, -114, 0.5, -11),
        Size = UDim2.fromOffset(24, 22), Text = "−", TextColor3 = COLOR.Text,
        BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, Parent = f})
    roundBox(bMinus)
    local value = make("TextLabel", {Position = UDim2.new(1, -88, 0.5, -11),
        Size = UDim2.fromOffset(56, 22), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = COLOR.Accent, Parent = f})
    local bPlus = make("TextButton", {Position = UDim2.new(1, -30, 0.5, -11),
        Size = UDim2.fromOffset(24, 22), Text = "+", TextColor3 = COLOR.Text,
        BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, Parent = f})
    roundBox(bPlus)
    local function change(delta)
        CFG[key] = clamp(CFG[key] + delta, minValue, maxValue)
        if key == "AimSmooth" then CFG[key] = math.floor(CFG[key] * 100 + 0.5) / 100 end
        value.Text = tostring(CFG[key]) .. (suffix or "")
        if key == "ZoomFOV" and zoomActive then
            local cam = Workspace.CurrentCamera
            if cam then cam.FieldOfView = CFG.ZoomFOV end
        end
    end
    listen(bMinus.MouseButton1Click, function() change(-step) end)
    listen(bPlus.MouseButton1Click, function() change(step) end)
    change(0)
end
local function modeRow()
    local f = row("Zoom Mode")
    local b = make("TextButton", {Position = UDim2.new(1, -96, 0.5, -11), Size = UDim2.fromOffset(86, 22),
        BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, TextColor3 = COLOR.Accent,
        Font = Enum.Font.GothamMedium, TextSize = 10, Text = CFG.ZoomMode, Parent = f})
    roundBox(b)
    listen(b.MouseButton1Click, function()
        zoomOff()
        CFG.ZoomMode = CFG.ZoomMode == "Hold" and "Toggle" or "Hold"
        b.Text = CFG.ZoomMode
    end)
end
local function keyRow()
    local f = row("Zoom Key")
    local b = make("TextButton", {Position = UDim2.new(1, -96, 0.5, -11), Size = UDim2.fromOffset(86, 22),
        BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, TextColor3 = COLOR.Accent,
        Font = Enum.Font.GothamMedium, TextSize = 10, Text = CFG.ZoomKey.Name, Parent = f})
    roundBox(b)
    listen(b.MouseButton1Click, function()
        zoomOff()
        captureKey = true
        b.Text = "PULSA..."
    end)
    listen(UIS.InputBegan, function(input)
        if not alive or not captureKey then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Escape then CFG.ZoomKey = input.KeyCode end
            b.Text = CFG.ZoomKey.Name
            captureKey = false
        end
    end)
end

local function cycleRow(label, key, choices, callback)
    local f = row(label)
    local b = make("TextButton", {Position = UDim2.new(1, -112, 0.5, -11),
        Size = UDim2.fromOffset(102, 22), BackgroundColor3 = COLOR.UI,
        BorderSizePixel = 0, TextColor3 = COLOR.Accent,
        Font = Enum.Font.GothamMedium, TextSize = 10, Text = CFG[key], Parent = f})
    roundBox(b)
    listen(b.MouseButton1Click, function()
        local index = table.find(choices, CFG[key]) or 1
        CFG[key] = choices[index % #choices + 1]
        b.Text = CFG[key]
        if callback then callback() end
    end)
end
local function aimKeyRow()
    local f = row("Aimbot Key")
    local b = make("TextButton", {Position = UDim2.new(1, -112, 0.5, -11),
        Size = UDim2.fromOffset(102, 22), BackgroundColor3 = COLOR.UI,
        BorderSizePixel = 0, TextColor3 = COLOR.Accent,
        Font = Enum.Font.GothamMedium, TextSize = 10,
        Text = CFG.AimKey.Name, Parent = f})
    roundBox(b)
    listen(b.MouseButton1Click, function()
        resetAim()
        captureAimKey = true
        b.Text = "PULSA..."
    end)
    listen(UIS.InputBegan, function(input)
        if not alive or not captureAimKey then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Escape then
                CFG.AimKey = input.KeyCode
            end
            captureAimKey = false
            b.Text = CFG.AimKey.Name
        end
    end)
end

toggle("ESP", "ESP")
toggle("Jugadores", "Players")
toggle("NPC / Bots", "NPC")
toggle("Nombres", "Names")
toggle("Vida", "Health")
toggle("Distancia", "Distance")
toggle("Cajas", "Boxes")
toggle("Punto cabeza", "HeadDot")
toggle("Barra vida", "HealthBar")
toggle("Ocultar aliados (si Teams)", "TeamFilter")
numberRow("Distancia ESP", "MaxDistance", 200, 5000, 200, "")
numberRow("ESP Hz", "UpdateHz", 10, 60, 5, "")
toggle("Zoom", "Zoom", function(enabled) if not enabled then zoomOff() end end)
keyRow()
modeRow()
numberRow("Zoom FOV", "ZoomFOV", 5, 90, 5, "°")
-- Aimbot. Por defecto solo rivales que tengan equipo identificado.
toggle("Aimbot", "Aimbot", function(enabled) if not enabled then resetAim() end end)
toggle("Aim: jugadores", "AimPlayers")
toggle("Aim: NPC / Bots", "AimNPC")
toggle("Aim: solo rivales", "AimEnemyOnly", resetAim)
toggle("Aim FOV", "AimFOV")
numberRow("Aim FOV Radio", "AimFOVRadius", 30, 500, 10, " px")
numberRow("Aim Distancia", "AimMaxDistance", 200, 5000, 100, "")
-- Valor de suavidad 0.05 a 0.95, donde mayor = movimiento más suave.
numberRow("Aim Suavidad", "AimSmooth", 0.05, 0.95, 0.05, "")
cycleRow("Aim objetivo", "AimBone", {"Head", "Neck", "Torso", "Feet"}, resetAim)
cycleRow("Aim cercanía", "AimSelect", {"Cursor", "Character"}, resetAim)
cycleRow("Aim activar con", "AimTrigger", {"Key", "Mouse2"}, resetAim)
cycleRow("Aim modo", "AimMode", {"Hold", "Toggle"}, resetAim)
aimKeyRow()

local minim = false
listen(minBtn.MouseButton1Click, function()
    minim = not minim
    scroll.Visible = not minim
    panel.Size = minim and UDim2.fromOffset(230, 42) or UDim2.fromOffset(345, 530)
    minBtn.Text = minim and "+" or "−"
end)
local dragging, startMouse, startPosition = false, nil, nil
listen(dragZone.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        startMouse, startPosition = input.Position, panel.Position
    end
end)
listen(UIS.InputChanged, function(input)
    if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = input.Position - startMouse
    local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or V2(1920, 1080)
    local size = panel.AbsoluteSize
    panel.Position = UDim2.fromOffset(
        clamp(startPosition.X.Offset + delta.X, 0, math.max(0, viewport.X - size.X)),
        clamp(startPosition.Y.Offset + delta.Y, 0, math.max(0, viewport.Y - 42))
    )
end)
listen(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local function cleanup()
    if not alive then return end
    alive = false
    zoomOff()
    resetAim()
    fovCircle:Remove()
    pcall(function() RunService:UnbindFromRenderStep("RSWA_SE_Zoom") end)
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, e in pairs(playerCache) do removeDrawings(e.d) end
    for _, e in pairs(npcCache) do removeDrawings(e.d) end
    table.clear(playerCache)
    table.clear(npcCache)
    if gui.Parent then gui:Destroy() end
end
listen(closeBtn.MouseButton1Click, cleanup)

local okEnv, env = pcall(function()
    if type(getgenv) == "function" then return getgenv() end
    return _G
end)
if okEnv and type(env) == "table" then
    if type(env.RSWA_SE_Stop) == "function" then pcall(env.RSWA_SE_Stop) end
    env.RSWA_SE_Stop = cleanup
end

-- Zoom despues de la camara: se aplica cuando el juego modifica su FOV.
RunService:BindToRenderStep("RSWA_SE_Zoom", Enum.RenderPriority.Camera.Value + 1, function()
    if not alive or not zoomActive then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if savedCamera ~= cam then
        savedCamera, savedFOV = cam, cam.FieldOfView
    end
    if cam.FieldOfView ~= CFG.ZoomFOV then cam.FieldOfView = CFG.ZoomFOV end
end)

local elapsed = 0
listen(RunService.RenderStepped, function(dt)
    if not alive then return end
    local cam = Workspace.CurrentCamera
    if cam then
        local cursor = cursorPos(cam)
        fovCircle.Position = cursor
        fovCircle.Radius = CFG.AimFOVRadius
        fovCircle.Visible = CFG.Aimbot and CFG.AimFOV
        if CFG.Aimbot and aimActive then
            aimAccumulator = aimAccumulator + dt
            if aimAccumulator >= 0.04 then
                aimAccumulator = 0
                local myRoot = rootPart(me.Character)
                local origin = myRoot and myRoot.Position or cam.CFrame.Position
                selectedTarget = findAimTarget(cam, origin, cursor)
            end
            if selectedTarget and type(mousemoverel) == "function" then
                local hum = humanoid(selectedTarget)
                local world = hum and hum.Health > 0 and aimWorldPosition(selectedTarget)
                local target2d = world and projected(cam, world)
                if target2d then
                    local delta = target2d - cursor
                    local factor = clamp(1 - CFG.AimSmooth, 0.03, 0.95)
                    pcall(mousemoverel, delta.X * factor, delta.Y * factor)
                end
            end
        else
            selectedTarget = nil
        end
    else
        fovCircle.Visible = false
    end
    elapsed = elapsed + dt
    if elapsed < 1 / CFG.UpdateHz then return end
    elapsed = 0
    local cam = Workspace.CurrentCamera
    if not cam then
        for _, e in pairs(playerCache) do hide(e.d) end
        for _, e in pairs(npcCache) do hide(e.d) end
        return
    end
    local myRoot = rootPart(me.Character)
    local origin = myRoot and myRoot.Position or cam.CFrame.Position
    for p, e in pairs(playerCache) do
        updateESP(e, p.Character, p, false, cam, origin)
    end
    for model, e in pairs(npcCache) do
        if not model.Parent or Players:GetPlayerFromCharacter(model) then
            removeNPC(model)
        else
            updateESP(e, model, nil, true, cam, origin)
        end
    end
end)
