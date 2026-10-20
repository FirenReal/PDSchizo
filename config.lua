-- RSWA Project Delta | ESP + Zoom + Aimbot con bloqueo de objetivo
-- El aimbot NO cambia a otro objetivo al morir el seleccionado.
-- Compatibilidad: modelos replicados con Humanoid + Head (R6/R15/custom).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
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
    ESP = true, Players = true, NPC = true,
    Names = true, Health = true, Distance = true,
    Boxes = true, HeadDot = true, HealthBar = true,
    TeamFilter = false, MaxDistance = 2200, UpdateHz = 25,
    BoxMode = "Corners", TextSize = 13, DotSize = 4,
    PlayerPalette = "Yellow", NPCPalette = "Blue", DeadPalette = "Gray",
    DistanceFade = true, ShowBodies = true, HighlightTarget = true,
    AutoSave = true,
    Zoom = true, ZoomFOV = 25, ZoomKey = Enum.KeyCode.C, ZoomMode = "Hold",
    Aimbot = false, AimPlayers = true, AimNPC = true, AimEnemyOnly = false,
    AimKey = Enum.KeyCode.P, AimTrigger = "Key", AimMode = "Hold",
    AimBone = "Head", AimSelect = "Cursor", AimSmooth = 0.35,
    AimFOV = true, AimFOVRadius = 160, AimMaxDistance = 2200,
}
local COLOR = {
    Player = RGB(255, 205, 75), NPC = RGB(60, 204, 255),
    Ally = RGB(96, 235, 140), Text = RGB(240, 245, 250),
    UI = RGB(13, 17, 24), Panel = RGB(21, 27, 38),
    Accent = RGB(65, 214, 191), Muted = RGB(160, 172, 187),
    Dead = RGB(159, 162, 174), Target = RGB(255, 255, 255),
}

local PALETTE = {
    Yellow = COLOR.Player, Blue = COLOR.NPC, Red = RGB(248, 87, 95),
    Green = COLOR.Ally, Purple = RGB(188, 116, 252),
    White = COLOR.Target, Gray = COLOR.Dead,
}

-- Configuración persistente (opcional: requiere readfile/writefile).
local SETTINGS_FILE = "RSWA_ProjectDelta_config.json"
local SETTINGS_LIMITS = {
    MaxDistance = {200, 5000}, UpdateHz = {10, 60},
    TextSize = {10, 20}, DotSize = {2, 10},
    ZoomFOV = {5, 90}, AimFOVRadius = {20, 500},
    AimMaxDistance = {200, 5000}, AimSmooth = {0.05, 0.95},
}
local SETTINGS_OPTIONS = {
    BoxMode = {Full = true, Corners = true},
    PlayerPalette = {Yellow=true,Blue=true,Red=true,Green=true,Purple=true,White=true,Gray=true},
    NPCPalette = {Yellow=true,Blue=true,Red=true,Green=true,Purple=true,White=true,Gray=true},
    DeadPalette = {Yellow=true,Blue=true,Red=true,Green=true,Purple=true,White=true,Gray=true},
    ZoomMode = {Hold = true, Toggle = true},
    AimTrigger = {Key = true, Mouse2 = true},
    AimMode = {Hold = true, Toggle = true},
    AimBone = {Head = true, Neck = true, Torso = true, Feet = true},
    AimSelect = {Cursor = true, Character = true},
}
local function snapshotSettings()
    local values = {}
    for key, value in pairs(CFG) do
        if typeof(value) == "EnumItem" then
            values[key] = value.Name
        else
            values[key] = value
        end
    end
    return values
end
local function saveSettings()
    if type(writefile) ~= "function" then
        return false, "No disponible: writefile"
    end
    local ok, err = pcall(function()
        writefile(SETTINGS_FILE, HttpService:JSONEncode(snapshotSettings()))
    end)
    return ok, ok and "Configuración guardada" or tostring(err)
end
local function loadSettings()
    if type(readfile) ~= "function" then
        return false, "No disponible: readfile"
    end
    local readOK, content = pcall(readfile, SETTINGS_FILE)
    if not readOK or type(content) ~= "string" then
        return false, "No existe una configuración guardada"
    end
    local decodeOK, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not decodeOK or type(data) ~= "table" then
        return false, "Archivo de configuración inválido"
    end
    for key, default in pairs(CFG) do
        local value = data[key]
        if typeof(default) == "EnumItem" and type(value) == "string" then
            local ok, code = pcall(function() return Enum.KeyCode[value] end)
            if ok and code and code ~= Enum.KeyCode.Unknown then CFG[key] = code end
        elseif type(value) == type(default) then
            local limits = SETTINGS_LIMITS[key]
            local options = SETTINGS_OPTIONS[key]
            if limits and type(value) == "number" and value == value
                and value ~= math.huge and value ~= -math.huge then
                CFG[key] = math.clamp(value, limits[1], limits[2])
            elseif options and options[value] then
                CFG[key] = value
            elseif not limits and not options then
                CFG[key] = value
            end
        end
    end
    return true, "Configuración cargada"
end
local configLoaded, configMessage = loadSettings()

local alive, connections = true, {}
local saveRevision = 0
local setSaveStatus = function() end
local function scheduleSave()
    saveRevision = saveRevision + 1
    local revision = saveRevision
    if not CFG.AutoSave or type(writefile) ~= "function" then return end
    task.delay(1, function()
        if alive and revision == saveRevision then
            local ok, message = saveSettings()
            setSaveStatus(ok and "Guardado automáticamente" or message)
        end
    end)
end
local playerCache, npcCache, corpseCache = {}, {}, {}
local watchedDeath, recentDeaths = setmetatable({}, {__mode = "k"}), {}
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
local function sameTeam(p)
    return me.Team ~= nil and p.Team ~= nil and p.Team == me.Team
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
    for key, obj in pairs(d) do
        if key == "corners" then
            for _, line in ipairs(obj) do line.Visible = false end
        else
            obj.Visible = false
        end
    end
end
local function removeDrawings(d)
    if not d then return end
    for key, obj in pairs(d) do
        if key == "corners" then
            for _, line in ipairs(obj) do pcall(function() line:Remove() end) end
        else
            pcall(function() obj:Remove() end)
        end
    end
end
local function updateCorners(d, x, y, width, height, color, transparency)
    if not d.corners then
        d.corners = {}
        for i = 1, 8 do
            local l = draw("Line")
            l.Thickness, l.Visible = 1.6, false
            d.corners[i] = l
        end
    end
    local rx, ry = math.min(22, math.max(5, width * 0.26)),
        math.min(22, math.max(5, height * 0.20))
    local right, bottom = x + width, y + height
    local coords = {
        {x, y, x + rx, y}, {x, y, x, y + ry},
        {right, y, right - rx, y}, {right, y, right, y + ry},
        {x, bottom, x + rx, bottom}, {x, bottom, x, bottom - ry},
        {right, bottom, right - rx, bottom},
        {right, bottom, right, bottom - ry},
    }
    for i, line in ipairs(d.corners) do
        local a = coords[i]
        line.From, line.To = V2(a[1], a[2]), V2(a[3], a[4])
        line.Color, line.Transparency, line.Visible = color, transparency, true
    end
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

-- Registro propio de cuerpos: sigue funcionando tras el respawn o
-- cuando el juego crea un ragdoll sin Humanoid.
local function bodyPart(model)
    return head(model)
        or rootPart(model)
        or model:FindFirstChildWhichIsA("BasePart", true)
end
local function corpseName(model)
    local name = model.Name:lower()
    return name:find("corpse", 1, true)
        or name:find("ragdoll", 1, true)
        or name:find("deadbody", 1, true)
        or name:find("dead_body", 1, true)
        or name:find("dead body", 1, true)
        or name:find("cadaver", 1, true)
        or name:find("cuerpo", 1, true)
        or name == "body"
        or model:GetAttribute("IsCorpse") == true
        or model:GetAttribute("IsDead") == true
        or model:GetAttribute("Dead") == true
end
local function addCorpse(model, label)
    if not alive or not model or not model:IsA("Model")
        or not model:IsDescendantOf(Workspace) or not bodyPart(model) then return end
    local existing = corpseCache[model]
    if existing then
        if label then existing.label = label end
        return
    end
    corpseCache[model] = {d = nil, model = model, dead = true, label = label or model.Name}
end
local function removeCorpse(model)
    local e = corpseCache[model]
    if e then removeDrawings(e.d); corpseCache[model] = nil end
end
local function maybeCorpse(model)
    if not model or not model:IsA("Model") or not bodyPart(model) then return end
    local hum = humanoid(model)
    if hum and hum.Health > 0 then return end
    local lastDeath = recentDeaths[model.Name:lower()]
    local associatedWithDeath = lastDeath and (os.clock() - lastDeath < 120)
    if corpseName(model) or associatedWithDeath or (hum and hum.Health <= 0) then
        addCorpse(model)
    end
end
local function watchDeath(model, hum)
    if not hum or watchedDeath[hum] then return end
    watchedDeath[hum] = true
    listen(hum.Died, function()
        if not alive then return end
        recentDeaths[model.Name:lower()] = os.clock()
        addCorpse(model)
    end)
    if hum.Health <= 0 then addCorpse(model) end
end
local function inspectCharacterModel(model)
    if not model or not model:IsA("Model") then return end
    local hum = humanoid(model)
    if hum then watchDeath(model, hum) end
    if not Players:GetPlayerFromCharacter(model) then addNPC(model) end
    maybeCorpse(model)
end

for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
listen(Players.PlayerAdded, addPlayer)
listen(Players.PlayerRemoving, removePlayer)
-- Escaneo inicial una sola vez; después usamos eventos, sin barrido por frame.
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Humanoid") then
        inspectCharacterModel(obj.Parent)
    elseif obj:IsA("Model") and corpseName(obj) then
        maybeCorpse(obj)
    end
end
listen(Workspace.DescendantAdded, function(obj)
    local model
    if obj:IsA("Model") then model = obj
    elseif obj:IsA("Humanoid") then model = obj.Parent
    elseif obj:IsA("BasePart") then
        if obj.Name == "Head" or obj.Name == "Torso" or obj.Name == "UpperTorso"
            or obj.Name == "HumanoidRootPart" then model = obj.Parent end
    end
    if model and model:IsA("Model") then
        task.delay(0.12, function()
            if alive and model:IsDescendantOf(Workspace) then inspectCharacterModel(model) end
        end)
    end
end)
-- Registrar muerte en jugadores incluso si sus Character ya estaban creados.
local function watchPlayerCharacter(p, model)
    if not model then return end
    local hum = humanoid(model)
    if hum then watchDeath(model, hum) end
    listen(model.ChildAdded, function(child)
        if child:IsA("Humanoid") then watchDeath(model, child) end
    end)
end
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then watchPlayerCharacter(p, p.Character) end
    listen(p.CharacterAdded, function(model) watchPlayerCharacter(p, model) end)
end
listen(Players.PlayerAdded, function(p)
    listen(p.CharacterAdded, function(model) watchPlayerCharacter(p, model) end)
end)

-- Compartido por la selección fija del aimbot y el ESP.
local lockedTarget = nil
local function updateESP(e, model, p, npc, cam, origin)
    local d = e.d
    if not CFG.ESP or (npc and not e.dead and not CFG.NPC) or (not npc and not CFG.Players)
        or not model or not model.Parent
        or (p and CFG.TeamFilter and sameTeam(p))
        or (npc and not e.dead and Players:GetPlayerFromCharacter(model)) then
        hide(d)
        return
    end
    -- Las referencias se actualizan al reaparecer el personaje.
    if e.model ~= model then
        e.model, e.hum, e.head, e.root = model, nil, nil, nil
    end
    if not e.hum or not e.hum:IsDescendantOf(model) then e.hum = humanoid(model) end
    if not e.head or not e.head:IsDescendantOf(model) then e.head = head(model) end
    if not e.root or not e.root:IsDescendantOf(model) then e.root = rootPart(model) end
    local hum, h, r = e.hum, e.head, e.root
    local isDead = e.dead or (hum and hum.Health <= 0)
    if (isDead and not CFG.ShowBodies) or (not isDead and not hum)
        or (not isDead and (not h or not r)) then
        hide(d)
        return
    end
    if isDead and not r then r = bodyPart(model) end
    if not r then hide(d); return end
    local dist = (r.Position - origin).Magnitude
    if dist > CFG.MaxDistance then hide(d); return end

    local upper, lower, height, width, center, left, head2d
    if isDead then
        -- Se calculan los límites del ragdoll completo, incluso si yace en el suelo.
        local ok, cf, bounds = pcall(function() return model:GetBoundingBox() end)
        if not ok then hide(d); return end
        local half = bounds * 0.5
        local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
        local count = 0
        for _, x in ipairs({-1, 1}) do
            for _, y in ipairs({-1, 1}) do
                for _, z in ipairs({-1, 1}) do
                    local wp = cf:PointToWorldSpace(V3(x * half.X, y * half.Y, z * half.Z))
                    local pt = cam:WorldToViewportPoint(wp)
                    if pt.Z > 0 then
                        count = count + 1
                        minX, maxX = math.min(minX, pt.X), math.max(maxX, pt.X)
                        minY, maxY = math.min(minY, pt.Y), math.max(maxY, pt.Y)
                    end
                end
            end
        end
        local viewport = cam.ViewportSize
        if count == 0 or maxX < 0 or minX > viewport.X
            or maxY < 0 or minY > viewport.Y then hide(d); return end
        left = clamp(minX, 0, viewport.X)
        local right = clamp(maxX, 0, viewport.X)
        upper, lower = clamp(minY, 0, viewport.Y), clamp(maxY, 0, viewport.Y)
        width, height = math.max(right - left, 9), math.max(lower - upper, 14)
        center = left + width * 0.5
        local headPoint = h and projected(cam, h.Position)
        head2d = headPoint or projected(cam, cf.Position) or V2(center, upper + height * 0.5)
    else
        local top = projected(cam, h.Position + V3(0, h.Size.Y * 0.5, 0))
        local bottom = projected(cam, r.Position - V3(0, 2.8, 0))
        head2d = projected(cam, h.Position)
        if not top or not bottom or not head2d then hide(d); return end
        upper, lower = math.min(top.Y, bottom.Y), math.max(top.Y, bottom.Y)
        height = math.max(lower - upper, 14)
        width = height * 0.46
        center = (top.X + bottom.X) * 0.5
        left = center - width / 2
    end

    local hp = isDead and 0 or clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local c = npc and PALETTE[CFG.NPCPalette]
        or (p and sameTeam(p) and COLOR.Ally or PALETTE[CFG.PlayerPalette])
    if isDead then
        c = PALETTE[CFG.DeadPalette]
    elseif CFG.HighlightTarget and model == lockedTarget then
        c = COLOR.Target
    end
    local opacity = CFG.DistanceFade
        and clamp(1 - 0.72 * (dist / math.max(CFG.MaxDistance, 1)) ^ 2, 0.28, 1)
        or 1
    if not d then
        d = makeDrawings()
        e.d = d
    end
    if CFG.Boxes then
        if CFG.BoxMode == "Corners" then
            d.box.Visible = false
            updateCorners(d, left, upper, width, height, c, opacity)
        else
            if d.corners then
                for _, line in ipairs(d.corners) do line.Visible = false end
            end
            d.box.Position, d.box.Size = V2(left, upper), V2(width, height)
            d.box.Color, d.box.Transparency, d.box.Visible = c, opacity, true
        end
    else
        d.box.Visible = false
        if d.corners then
            for _, line in ipairs(d.corners) do line.Visible = false end
        end
    end
    if CFG.Names then
        d.name.Text = isDead and ("[CUERPO] " .. (e.label or model.Name))
            or (npc and model.Name or (p.DisplayName or p.Name))
        d.name.Position, d.name.Color = V2(center, upper - 18), c
        d.name.Size, d.name.Transparency, d.name.Visible = CFG.TextSize, opacity, true
    else d.name.Visible = false end
    if CFG.Health or CFG.Distance then
        local hpText = isDead and "MUERTO" or (tostring(math.floor(hp * 100 + 0.5)) .. "%")
        local distanceText = tostring(math.floor(dist + 0.5)) .. " studs"
        d.status.Text = CFG.Health and CFG.Distance and (hpText .. " | " .. distanceText)
            or (CFG.Health and hpText or distanceText)
        d.status.Position, d.status.Visible = V2(center, lower + 4), true
        d.status.Size = math.max(9, CFG.TextSize - 2)
        d.status.Transparency = opacity
    else d.status.Visible = false end
    if CFG.HeadDot then
        d.dot.Position, d.dot.Color, d.dot.Visible = head2d, c, true
        d.dot.Radius, d.dot.Transparency = CFG.DotSize, opacity
    else d.dot.Visible = false end
    if CFG.HealthBar then
        local x = left - 6
        d.barBg.From, d.barBg.To = V2(x, upper), V2(x, lower)
        d.bar.From, d.bar.To = V2(x, lower), V2(x, lower - height * hp)
        d.bar.Color = isDead and PALETTE[CFG.DeadPalette]
            or RGB(245, 70, 70):Lerp(RGB(65, 245, 100), hp)
        d.bar.Transparency = opacity
        d.barBg.Visible, d.bar.Visible = true, true
    else d.barBg.Visible, d.bar.Visible = false, false end
end

-- Aimbot: objetivo fijo durante cada pulsación/activación.
-- Al morir, desaparecer o cambiar de modelo NO se selecciona otro
-- hasta soltar y volver a pulsar (o desactivar/reactivar Toggle).
local aimActive = false
local captureAimKey = false
local targetSpent = false
local fovCircle = draw("Circle")
fovCircle.Visible, fovCircle.Filled = false, false
fovCircle.NumSides, fovCircle.Thickness = 64, 1.5
fovCircle.Transparency, fovCircle.Color = 0.86, COLOR.Accent

local function aimCursor(cam)
    local size = cam.ViewportSize
    if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return V2(size.X * 0.5, size.Y * 0.5)
    end
    local p = UIS:GetMouseLocation()
    return V2(p.X, p.Y)
end

local function aimPoint(model)
    local r, h = rootPart(model), head(model)
    if not r then return nil end
    if CFG.AimBone == "Head" and h then return h.Position end
    if CFG.AimBone == "Neck" and h then
        return h.Position - V3(0, h.Size.Y / 2, 0)
    end
    if CFG.AimBone == "Feet" then return r.Position - V3(0, 2.5, 0) end
    return r.Position
end

local function findAimTarget(cam, origin, cursor)
    local best, bestDist = nil, math.huge
    local function consider(model)
        if not model or not model.Parent then return end
        local h, r = humanoid(model), rootPart(model)
        if not h or h.Health <= 0 or not r then return end
        local pos = aimPoint(model)
        if not pos then return end
        local distWorld = (r.Position - origin).Magnitude
        if distWorld > CFG.AimMaxDistance then return end
        local screen = projected(cam, pos)
        if not screen then return end
        local distCursor = (screen - cursor).Magnitude
        if CFG.AimFOV and distCursor > CFG.AimFOVRadius then return end
        local score = CFG.AimSelect == "Character" and distWorld or distCursor
        if score < bestDist then
            bestDist, best = score, model
        end
    end
    if CFG.AimPlayers then
        for player in pairs(playerCache) do
            if not CFG.AimEnemyOnly or not sameTeam(player) then
                consider(player.Character)
            end
        end
    end
    if CFG.AimNPC then
        for model in pairs(npcCache) do
            if not Players:GetPlayerFromCharacter(model) then consider(model) end
        end
    end
    return best
end

local function stopAim()
    aimActive, lockedTarget, targetSpent = false, nil, false
end

local function startAim()
    -- La búsqueda se hace SOLO al iniciar una nueva activación.
    aimActive = true
    lockedTarget = nil
    targetSpent = true
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local meRoot = rootPart(me.Character)
    local origin = meRoot and meRoot.Position or cam.CFrame.Position
    lockedTarget = findAimTarget(cam, origin, aimCursor(cam))
    targetSpent = lockedTarget == nil
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
    if not pressed then return end
    if CFG.AimMode == "Toggle" then
        if aimActive then stopAim() else startAim() end
    else
        if not aimActive then startAim() end
    end
end)
listen(UIS.InputEnded, function(input)
    if not alive then return end
    if CFG.ZoomMode == "Hold" and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == CFG.ZoomKey then zoomOff() end
    if CFG.AimMode ~= "Hold" then return end
    local released = (CFG.AimTrigger == "Mouse2"
            and input.UserInputType == Enum.UserInputType.MouseButton2)
        or (CFG.AimTrigger == "Key"
            and input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode == CFG.AimKey)
    if released then stopAim() end
end)

-- UI compacta RSWA.
local oldGui = CoreGui:FindFirstChild("RSWA_ProjectDelta")
if oldGui then oldGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn = "RSWA_ProjectDelta", true, false
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
    Name = "Panel", Position = UDim2.fromOffset(44, 65), Size = UDim2.fromOffset(320, 390),
    BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, ClipsDescendants = true, Parent = gui,
})
roundBox(panel, 10)
local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = COLOR.Panel,
    BorderSizePixel = 0, Parent = panel,
})
local title = make("TextLabel", {
    Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -95, 1, 0),
    BackgroundTransparency = 1, Text = "RSWA | Project Delta", Font = Enum.Font.GothamBold,
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
local refreshUI = {}
local function refreshAll()
    for _, fn in ipairs(refreshUI) do pcall(fn) end
end
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
        scheduleSave()
    end)
    refreshUI[#refreshUI + 1] = refresh
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
        value.Text = tostring(CFG[key]) .. (suffix or "")
        if key == "ZoomFOV" and zoomActive then
            local cam = Workspace.CurrentCamera
            if cam then cam.FieldOfView = CFG.ZoomFOV end
        end
        if delta ~= 0 then scheduleSave() end
    end
    refreshUI[#refreshUI + 1] = function()
        value.Text = tostring(CFG[key]) .. (suffix or "")
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
        scheduleSave()
    end)
    refreshUI[#refreshUI + 1] = function() b.Text = CFG.ZoomMode end
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
            if input.KeyCode ~= Enum.KeyCode.Escape
                and input.KeyCode ~= Enum.KeyCode.Unknown then CFG.ZoomKey = input.KeyCode end
            b.Text = CFG.ZoomKey.Name
            captureKey = false
            scheduleSave()
        end
    end)
    refreshUI[#refreshUI + 1] = function() b.Text = CFG.ZoomKey.Name end
end

local function aimCycleRow(label, key, values)
    local f = row(label)
    local b = make("TextButton", {Position = UDim2.new(1, -116, 0.5, -11), Size = UDim2.fromOffset(106, 22),
        BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, TextColor3 = COLOR.Accent,
        Font = Enum.Font.GothamMedium, TextSize = 10, Text = CFG[key], Parent = f})
    roundBox(b)
    listen(b.MouseButton1Click, function()
        if key:sub(1, 3) == "Aim" then stopAim() end
        local current = table.find(values, CFG[key]) or 1
        CFG[key] = values[current % #values + 1]
        b.Text = CFG[key]
        scheduleSave()
    end)
    refreshUI[#refreshUI + 1] = function() b.Text = CFG[key] end
end
local function aimKeyRow()
    local f = row("Aim Key")
    local b = make("TextButton", {Position = UDim2.new(1, -96, 0.5, -11), Size = UDim2.fromOffset(86, 22),
        BackgroundColor3 = COLOR.UI, BorderSizePixel = 0, TextColor3 = COLOR.Accent,
        Font = Enum.Font.GothamMedium, TextSize = 10, Text = CFG.AimKey.Name, Parent = f})
    roundBox(b)
    listen(b.MouseButton1Click, function()
        stopAim()
        zoomOff()
        captureAimKey = true
        b.Text = "PULSA..."
    end)
    listen(UIS.InputBegan, function(input)
        if not alive or not captureAimKey then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Escape
                and input.KeyCode ~= Enum.KeyCode.Unknown then CFG.AimKey = input.KeyCode end
            b.Text = CFG.AimKey.Name
            captureAimKey = false
            scheduleSave()
        end
    end)
    refreshUI[#refreshUI + 1] = function() b.Text = CFG.AimKey.Name end
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
toggle("Desvanecer por distancia", "DistanceFade")
toggle("Mostrar cuerpos", "ShowBodies")
toggle("Marcar objetivo seleccionado", "HighlightTarget")
aimCycleRow("Tipo de caja", "BoxMode", {"Corners", "Full"})
aimCycleRow("Color jugadores", "PlayerPalette", {"Yellow", "Blue", "Red", "Green", "Purple", "White", "Gray"})
aimCycleRow("Color NPC", "NPCPalette", {"Blue", "Red", "Green", "Purple", "Yellow", "White", "Gray"})
aimCycleRow("Color muertos", "DeadPalette", {"Gray", "Red", "Purple", "White", "Blue", "Yellow", "Green"})
numberRow("Tamaño nombre", "TextSize", 10, 20, 1, "")
numberRow("Tamaño punto", "DotSize", 2, 10, 1, "")
numberRow("Distancia ESP", "MaxDistance", 200, 5000, 200, "")
numberRow("ESP Hz", "UpdateHz", 10, 60, 5, "")
toggle("Zoom", "Zoom", function(enabled) if not enabled then zoomOff() end end)
keyRow()
modeRow()
numberRow("Zoom FOV", "ZoomFOV", 5, 90, 5, "°")
-- Aimbot: nunca cambia de objetivo dentro de una misma activación.
toggle("Aimbot", "Aimbot", function(enabled) if not enabled then stopAim() end end)
toggle("Aim jugadores", "AimPlayers", stopAim)
toggle("Aim NPC / Bots", "AimNPC", stopAim)
toggle("Aim solo enemigos", "AimEnemyOnly", stopAim)
toggle("Aim FOV", "AimFOV", stopAim)
numberRow("Aim radio FOV", "AimFOVRadius", 20, 500, 10, " px")
numberRow("Aim distancia", "AimMaxDistance", 200, 5000, 100, "")
numberRow("Aim suavidad", "AimSmooth", 0.05, 0.95, 0.05, "")
aimCycleRow("Aim punto", "AimBone", {"Head", "Neck", "Torso", "Feet"})
aimCycleRow("Aim cercanía", "AimSelect", {"Cursor", "Character"})
aimCycleRow("Aim botón", "AimTrigger", {"Key", "Mouse2"})
aimCycleRow("Aim modo", "AimMode", {"Hold", "Toggle"})
aimKeyRow()

-- Guardar / cargar sin depender de servicios externos.
toggle("Guardar automáticamente", "AutoSave")
local storageRow = row("Estado ajustes")
local storageLabel = make("TextLabel", {
    Position = UDim2.new(0.33, 0, 0, 0), Size = UDim2.new(0.67, -8, 1, 0),
    BackgroundTransparency = 1, Text = "", TextColor3 = COLOR.Accent,
    Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right,
    TextTruncate = Enum.TextTruncate.AtEnd, Parent = storageRow,
})
setSaveStatus = function(message)
    if storageLabel and storageLabel.Parent then
        storageLabel.Text = tostring(message)
    end
end
setSaveStatus(configMessage)
local function actionRow(label, buttonText, action)
    local f = row(label)
    local b = make("TextButton", {
        Position = UDim2.new(1, -94, 0.5, -11), Size = UDim2.fromOffset(84, 22),
        BackgroundColor3 = COLOR.UI, BorderSizePixel = 0,
        Text = buttonText, TextColor3 = COLOR.Accent,
        Font = Enum.Font.GothamSemibold, TextSize = 10, Parent = f,
    })
    roundBox(b)
    listen(b.MouseButton1Click, action)
end
actionRow("Guardar ahora", "GUARDAR", function()
    saveRevision = saveRevision + 1
    local ok, message = saveSettings()
    setSaveStatus(message)
end)
actionRow("Recuperar ajustes", "CARGAR", function()
    saveRevision = saveRevision + 1
    local ok, message = loadSettings()
    if ok then
        zoomOff()
        stopAim()
        refreshAll()
    end
    setSaveStatus(message)
end)

local minim = false
listen(minBtn.MouseButton1Click, function()
    minim = not minim
    scroll.Visible = not minim
    panel.Size = minim and UDim2.fromOffset(230, 42) or UDim2.fromOffset(320, 390)
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
    if CFG.AutoSave then saveSettings() end
    alive = false
    zoomOff()
    stopAim()
    pcall(function() fovCircle:Remove() end)
    pcall(function() RunService:UnbindFromRenderStep("RSWA_PD_Zoom") end)
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    for _, e in pairs(playerCache) do removeDrawings(e.d) end
    for _, e in pairs(npcCache) do removeDrawings(e.d) end
    for _, e in pairs(corpseCache) do removeDrawings(e.d) end
    table.clear(playerCache)
    table.clear(npcCache)
    table.clear(corpseCache)
    if gui.Parent then gui:Destroy() end
end
listen(closeBtn.MouseButton1Click, cleanup)

local okEnv, env = pcall(function()
    if type(getgenv) == "function" then return getgenv() end
    return _G
end)
if okEnv and type(env) == "table" then
    if type(env.RSWA_PD_Stop) == "function" then pcall(env.RSWA_PD_Stop) end
    env.RSWA_PD_Stop = cleanup
end

-- Zoom despues de la camara: se aplica cuando el juego modifica su FOV.
RunService:BindToRenderStep("RSWA_PD_Zoom", Enum.RenderPriority.Camera.Value + 1, function()
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
    -- Dibujo FOV y apuntado; la búsqueda ocurre únicamente en startAim().
    local aimCam = Workspace.CurrentCamera
    if aimCam then
        local cursor = aimCursor(aimCam)
        fovCircle.Position, fovCircle.Radius = cursor, CFG.AimFOVRadius
        fovCircle.Visible = CFG.Aimbot and CFG.AimFOV
        if CFG.Aimbot and aimActive and lockedTarget and not targetSpent then
            local hum = humanoid(lockedTarget)
            if not lockedTarget.Parent or not hum or hum.Health <= 0 then
                lockedTarget = nil
                targetSpent = true
            else
                local world = aimPoint(lockedTarget)
                local point = world and projected(aimCam, world)
                if point and type(mousemoverel) == "function" then
                    local delta = point - cursor
                    local factor = clamp(1 - CFG.AimSmooth, 0.03, 0.95)
                    pcall(mousemoverel, delta.X * factor, delta.Y * factor)
                end
            end
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
        for _, e in pairs(corpseCache) do hide(e.d) end
        return
    end
    local myRoot = rootPart(me.Character)
    local origin = myRoot and myRoot.Position or cam.CFrame.Position
    for p, e in pairs(playerCache) do
        if corpseCache[p.Character] then hide(e.d)
        else updateESP(e, p.Character, p, false, cam, origin) end
    end
    for model, e in pairs(npcCache) do
        if not model.Parent or Players:GetPlayerFromCharacter(model) then
            removeNPC(model)
        elseif corpseCache[model] then hide(e.d)
        else updateESP(e, model, nil, true, cam, origin) end
    end
    for model, e in pairs(corpseCache) do
        if not model:IsDescendantOf(Workspace) then removeCorpse(model)
        else updateESP(e, model, nil, true, cam, origin) end
    end
end)
