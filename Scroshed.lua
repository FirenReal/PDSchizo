-- RSWA | CENTAURA ESP + Aimbot
-- CENTAURA original (8735521924). Solo jugadores enemigos; sin dependencia externa.
-- Requiere un entorno que disponga de Drawing.new y mousemoverel.

local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local GuiService = game:GetService('GuiService')
local CoreGui = game:GetService('CoreGui')
local Me = Players.LocalPlayer
local Mouse = Me:GetMouse()
local V2, RGB = Vector2.new, Color3.fromRGB
local clamp = math.clamp

if not Drawing or type(Drawing.new) ~= 'function' then
    warn('[RSWA Centaura] Se requiere Drawing.new.')
    return
end

-- Detener una instancia anterior para evitar dibujos y conexiones duplicados.
local env = (type(getgenv) == 'function' and getgenv()) or _G
if type(env.RSWA_Centaura_Stop) == 'function' then
    pcall(env.RSWA_Centaura_Stop)
end

local cfg = {
    ESP = true,
    Names = true,
    Boxes = true,
    Health = true,
    Distance = true,
    HeadDots = true,
    MaxDistance = 1300,
    ESP_Hz = 25,
    Aim = false,
    AimKey = Enum.KeyCode.P,
    AimMode = 'Hold', -- Hold / Toggle
    AimBone = 'Head', -- Head / Torso
    SelectBy = 'Mouse', -- Mouse / Character
    AimFOV = true,
    AimRadius = 160,
    Smoothness = 0.38, -- 0 = rápido; 0.9 = lento
}

local COLORS = {
    bg = RGB(15, 19, 28), panel = RGB(24, 30, 41), row = RGB(32, 39, 53),
    accent = RGB(74, 213, 188), text = RGB(235, 241, 247),
    enemy = RGB(255, 105, 80), outline = RGB(0, 0, 0),
}

local alive = true
local connections = {}
local entities = {}
local aimHeld = false
local aimTarget = nil
local listening = false

local function bind(signal, fn)
    local connection = signal:Connect(fn)
    connections[#connections + 1] = connection
    return connection
end

local function rootOf(model)
    if not model then return nil end
    return model:FindFirstChild('HumanoidRootPart')
        or model:FindFirstChild('UpperTorso')
        or model:FindFirstChild('Torso')
        or model.PrimaryPart
        or model:FindFirstChild('Head')
end

local function humanoidOf(model)
    return model and model:FindFirstChildOfClass('Humanoid')
end

local function headOf(model)
    local head = model and model:FindFirstChild('Head')
    return (head and head:IsA('BasePart')) and head or nil
end

-- Filtro estricto: si aún no conocemos ambos equipos, no dibujar ni apuntar.
local function isEnemy(player)
    if not player or player == Me then return false end
    local myTeam, otherTeam = Me.Team, player.Team
    if myTeam ~= nil and otherTeam ~= nil then
        return myTeam ~= otherTeam
    end
    if not Me.Neutral and not player.Neutral then
        return Me.TeamColor ~= player.TeamColor
    end
    return false
end

local function isAliveCharacter(model)
    if not model or not model.Parent then return false end
    local hum = humanoidOf(model)
    return hum ~= nil and hum.Health > 0 and rootOf(model) ~= nil
end

local function viewportPoint(camera, position)
    local p, visible = camera:WorldToViewportPoint(position)
    local s = camera.ViewportSize
    return p, visible and p.Z > 0 and p.X >= 0 and p.X <= s.X and p.Y >= 0 and p.Y <= s.Y
end

local function mouseViewport()
    local topLeft = GuiService:GetGuiInset()
    -- Se alinea el cursor con las coordenadas de WorldToViewportPoint.
    return V2(Mouse.X, Mouse.Y + topLeft.Y)
end

local function textDrawing(size)
    local d = Drawing.new('Text')
    d.Visible = false
    d.Center = true
    d.Outline = true
    d.OutlineColor = COLORS.outline
    d.Color = COLORS.text
    d.Transparency = 1
    d.Font = 2
    d.Size = size
    return d
end

local function createMarks()
    local box = Drawing.new('Square')
    box.Visible = false
    box.Filled = false
    box.Thickness = 1.5
    box.Color = COLORS.enemy
    box.Transparency = 1
    local dot = Drawing.new('Circle')
    dot.Visible = false
    dot.Filled = true
    dot.Radius = 3
    dot.NumSides = 16
    dot.Color = COLORS.enemy
    dot.Transparency = 1
    return {box = box, dot = dot, name = textDrawing(13), info = textDrawing(11)}
end

local function hide(m)
    m.box.Visible = false
    m.dot.Visible = false
    m.name.Visible = false
    m.info.Visible = false
end

local function removeMarks(m)
    if not m then return end
    hide(m)
    for _, drawing in pairs(m) do pcall(function() drawing:Remove() end) end
end

local function addPlayer(player)
    if player == Me or entities[player] then return end
    entities[player] = createMarks()
end

local function removePlayer(player)
    local marks = entities[player]
    if marks then removeMarks(marks); entities[player] = nil end
    if aimTarget == player then aimTarget = nil end
end

for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
bind(Players.PlayerAdded, addPlayer)
bind(Players.PlayerRemoving, removePlayer)

local fov = Drawing.new('Circle')
fov.Visible = false
fov.Filled = false
fov.NumSides = 48
fov.Thickness = 1
fov.Color = COLORS.accent
fov.Transparency = 0.8

local function targetPart(model)
    if cfg.AimBone == 'Head' then
        return headOf(model) or rootOf(model)
    end
    return model and (model:FindFirstChild('UpperTorso')
        or model:FindFirstChild('Torso') or rootOf(model))
end

local function acquireTarget()
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    local myRoot = rootOf(Me.Character)
    if cfg.SelectBy == 'Character' and not myRoot then return nil end
    local cursor = mouseViewport()
    local winner, bestScore = nil, math.huge
    for player in pairs(entities) do
        if isEnemy(player) then
            local model = player.Character
            if isAliveCharacter(model) then
                local part = targetPart(model)
                if part then
                    local point, visible = viewportPoint(camera, part.Position)
                    if visible then
                        local screen = V2(point.X, point.Y)
                        if not cfg.AimFOV or (screen - cursor).Magnitude <= cfg.AimRadius then
                            local score = cfg.SelectBy == 'Character'
                                and (part.Position - myRoot.Position).Magnitude
                                or (screen - cursor).Magnitude
                            if score < bestScore then
                                bestScore, winner = score, player
                            end
                        end
                    end
                end
            end
        end
    end
    return winner
end

local function startAim()
    if not cfg.Aim then return end
    aimHeld = true
    aimTarget = acquireTarget()  -- Se selecciona una sola vez por activación.
end
local function stopAim()
    aimHeld = false
    aimTarget = nil
end

-- UI mínima. No usa bibliotecas externas.
local existing = CoreGui:FindFirstChild('RSWA_Centaura_UI')
if existing then existing:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'RSWA_Centaura_UI'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local function make(class, props, parent)
    local o = Instance.new(class)
    for key, value in pairs(props) do o[key] = value end
    o.Parent = parent
    return o
end
local function round(frame, radius)
    make('UICorner', {CornerRadius = UDim.new(0, radius or 7)}, frame)
end
local panel = make('Frame', {
    Size = UDim2.fromOffset(330, 435), Position = UDim2.fromOffset(35, 75),
    BackgroundColor3 = COLORS.bg, BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
round(panel, 10)
local bar = make('Frame', {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0, Active = true,
}, panel)
local title = make('TextLabel', {
    BackgroundTransparency = 1, Size = UDim2.new(1, -94, 1, 0),
    Position = UDim2.fromOffset(12, 0), Text = 'RSWA  |  CENTAURA',
    TextColor3 = COLORS.text, Font = Enum.Font.GothamBold, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, bar)
local minimize = make('TextButton', {
    Position = UDim2.new(1, -69, 0, 7), Size = UDim2.fromOffset(28, 28),
    Text = '−', TextColor3 = COLORS.text, Font = Enum.Font.GothamBold,
    TextSize = 16, BackgroundColor3 = COLORS.row, BorderSizePixel = 0,
}, bar)
round(minimize)
local close = make('TextButton', {
    Position = UDim2.new(1, -36, 0, 7), Size = UDim2.fromOffset(28, 28),
    Text = '×', TextColor3 = COLORS.text, Font = Enum.Font.GothamBold,
    TextSize = 16, BackgroundColor3 = COLORS.row, BorderSizePixel = 0,
}, bar)
round(close)

local body = make('ScrollingFrame', {
    Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -42),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.fromOffset(0, 0),
}, panel)
make('UIPadding', {
    PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
}, body)
make('UIListLayout', {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, body)

local function makeRow(label)
    local row = make('Frame', {Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = COLORS.panel, BorderSizePixel = 0}, body)
    round(row, 6)
    make('TextLabel', {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -135, 1, 0), Text = label,
        TextColor3 = COLORS.text, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    return row
end
local function actionButton(row, x, width, text)
    local b = make('TextButton', {
        Size = UDim2.fromOffset(width, 23), Position = UDim2.new(1, x, 0.5, -11),
        Text = text, TextColor3 = COLORS.accent, Font = Enum.Font.GothamMedium,
        TextSize = 11, BackgroundColor3 = COLORS.row, BorderSizePixel = 0,
    }, row)
    round(b, 5)
    return b
end
local function toggle(label, key, changed)
    local row = makeRow(label)
    local b = actionButton(row, -72, 62, '')
    local function update()
        b.Text = cfg[key] and 'ON' or 'OFF'
        b.TextColor3 = cfg[key] and COLORS.accent or COLORS.text
    end
    bind(b.MouseButton1Click, function()
        cfg[key] = not cfg[key]
        if changed then changed(cfg[key]) end
        update()
    end)
    update()
end
local function choice(label, key, options, changed)
    local row = makeRow(label)
    local b = actionButton(row, -116, 106, cfg[key])
    bind(b.MouseButton1Click, function()
        local index = table.find(options, cfg[key]) or 1
        cfg[key] = options[index % #options + 1]
        b.Text = cfg[key]
        if changed then changed(cfg[key]) end
    end)
end
local function stepper(label, key, low, high, step)
    local row = makeRow(label)
    local minus = actionButton(row, -115, 22, '−')
    local value = actionButton(row, -90, 58, '')
    local plus = actionButton(row, -29, 21, '+')
    local function update() value.Text = tostring(math.floor(cfg[key] * 100 + 0.5) / 100) end
    bind(minus.MouseButton1Click, function() cfg[key] = clamp(cfg[key] - step, low, high); update() end)
    bind(plus.MouseButton1Click, function() cfg[key] = clamp(cfg[key] + step, low, high); update() end)
    update()
end

toggle('ESP enemigos', 'ESP')
toggle('Nombres', 'Names')
toggle('Cajas', 'Boxes')
toggle('Vida', 'Health')
toggle('Distancia', 'Distance')
toggle('Punto en cabeza', 'HeadDots')
stepper('Distancia máxima', 'MaxDistance', 100, 3500, 100)
toggle('Aimbot', 'Aim', function(enabled) if not enabled then stopAim() end end)
choice('Modo de apuntado', 'AimMode', {'Hold', 'Toggle'}, stopAim)
choice('Objetivo', 'AimBone', {'Head', 'Torso'})
choice('Prioridad', 'SelectBy', {'Mouse', 'Character'})
toggle('Limitar por FOV', 'AimFOV')
stepper('Radio de FOV', 'AimRadius', 40, 600, 20)
stepper('Suavizado', 'Smoothness', 0.05, 0.9, 0.05)
local keyRow = makeRow('Tecla de aimbot')
local keyBtn = actionButton(keyRow, -105, 95, cfg.AimKey.Name)
bind(keyBtn.MouseButton1Click, function()
    listening = true
    keyBtn.Text = 'Pulsa tecla'
end)

local expandedSize = panel.Size
local minimized = false
bind(minimize.MouseButton1Click, function()
    minimized = not minimized
    if minimized then
        expandedSize = panel.Size
        panel.Size = UDim2.fromOffset(185, 42)
        body.Visible = false
        minimize.Text = '+'
    else
        panel.Size = expandedSize
        body.Visible = true
        minimize.Text = '−'
    end
end)
-- Zona frontal del título para arrastrar incluso minimizado.
local dragZone = make('TextButton', {
    BackgroundTransparency = 1, Size = UDim2.new(1, -82, 1, 0),
    Position = UDim2.fromOffset(0, 0), Text = '', AutoButtonColor = false,
    BorderSizePixel = 0, Active = true, ZIndex = 10,
}, bar)
minimize.ZIndex, close.ZIndex = 11, 11
local dragging, dragStart, positionStart = false, nil, nil
bind(dragZone.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        positionStart = panel.Position
    end
end)
bind(UIS.InputChanged, function(input)
    if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local d = input.Position - dragStart
    local size = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or V2(1920, 1080)
    panel.Position = UDim2.fromOffset(
        clamp(positionStart.X.Offset + d.X, 0, math.max(0, size.X - panel.AbsoluteSize.X)),
        clamp(positionStart.Y.Offset + d.Y, 0, math.max(0, size.Y - 42))
    )
end)
bind(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

bind(UIS.InputBegan, function(input, processed)
    if listening then
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            cfg.AimKey = input.KeyCode
            keyBtn.Text = cfg.AimKey.Name
            listening = false
            stopAim()
        end
        return
    end
    if processed or not cfg.Aim then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == cfg.AimKey then
        if cfg.AimMode == 'Toggle' then
            if aimHeld then stopAim() else startAim() end
        elseif not aimHeld then
            startAim()
        end
    end
end)
bind(UIS.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == cfg.AimKey and cfg.AimMode == 'Hold' then
        stopAim()
    end
end)

local function stopAll()
    if not alive then return end
    alive = false
    stopAim()
    if env.RSWA_Centaura_Stop == stopAll then env.RSWA_Centaura_Stop = nil end
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for player in pairs(entities) do removePlayer(player) end
    pcall(function() fov:Remove() end)
    pcall(function() gui:Destroy() end)
end

env.RSWA_Centaura_Stop = stopAll
bind(close.MouseButton1Click, stopAll)

local function updateESP(camera)
    local ownRoot = rootOf(Me.Character)
    if not ownRoot or not cfg.ESP then
        for _, marks in pairs(entities) do hide(marks) end
        return
    end
    for player, marks in pairs(entities) do
        local model = player.Character
        if not isEnemy(player) or not isAliveCharacter(model) then
            hide(marks)
        else
            local root, head = rootOf(model), headOf(model)
            if not head then
                hide(marks)
            else
                local distance = (root.Position - ownRoot.Position).Magnitude
                if distance > cfg.MaxDistance then
                    hide(marks)
                else
                    local headP, headVisible = viewportPoint(camera, head.Position)
                    local rootP, rootVisible = viewportPoint(camera, root.Position)
                    if not headVisible or not rootVisible then
                        hide(marks)
                    else
                        local height = math.max(20, math.abs(rootP.Y - headP.Y) * 2.6)
                        local width = height * 0.48
                        local x, y = rootP.X - width / 2, headP.Y - height * 0.13
                        marks.box.Position = V2(x, y)
                        marks.box.Size = V2(width, height)
                        marks.box.Visible = cfg.Boxes
                        marks.name.Text = player.DisplayName
                        marks.name.Position = V2(rootP.X, y - 15)
                        marks.name.Visible = cfg.Names
                        local status = ''
                        if cfg.Health then
                            local hum = humanoidOf(model)
                            status = math.floor(hum.Health / math.max(hum.MaxHealth, 1) * 100 + 0.5) .. '%'
                        end
                        if cfg.Distance then
                            if #status > 0 then status = status .. ' | ' end
                            status = status .. math.floor(distance + 0.5) .. ' studs'
                        end
                        marks.info.Text = status
                        marks.info.Position = V2(rootP.X, y + height + 3)
                        marks.info.Visible = status ~= ''
                        marks.dot.Position = V2(headP.X, headP.Y)
                        marks.dot.Visible = cfg.HeadDots
                    end
                end
            end
        end
    end
end

-- Única conexión por frame. ESP a 25 Hz; la cámara de apuntado se suaviza a la tasa de render.
local elapsed = 0
bind(RunService.RenderStepped, function(dt)
    if not alive then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local cursor = mouseViewport()
    fov.Visible = cfg.Aim and cfg.AimFOV
    if fov.Visible then
        fov.Position = cursor
        fov.Radius = cfg.AimRadius
    end

    elapsed = elapsed + dt
    if elapsed >= 1 / cfg.ESP_Hz then
        elapsed = 0
        updateESP(camera)
    end

    if not cfg.Aim or not aimHeld or not aimTarget then return end
    local player = aimTarget
    local model = player.Character
    -- No adquirir un nuevo objetivo al morir el actual. Esperar nueva pulsación.
    if not isEnemy(player) or not isAliveCharacter(model) then
        aimTarget = nil
        return
    end
    local part = targetPart(model)
    if not part then aimTarget = nil; return end
    local point, visible = viewportPoint(camera, part.Position)
    if not visible then return end
    if cfg.AimFOV and (V2(point.X, point.Y) - cursor).Magnitude > cfg.AimRadius then return end
    if type(mousemoverel) ~= 'function' then return end
    local strength = clamp(1 - cfg.Smoothness, 0.05, 1)
    mousemoverel((point.X - cursor.X) * strength, (point.Y - cursor.Y) * strength)
end)
