-- Neverdies.me - versión reorganizada
-- Mantiene ESP + aimbot + guardado de configuración.
-- No contiene prints/warns ni lógica de evasión de anti-cheat.

--========================================================
-- SERVICIOS
--========================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--========================================================
-- ATAJOS
--========================================================

local clamp = math.clamp
local round = math.round
local abs = math.abs
local huge = math.huge
local random = math.random

local V2 = Vector2.new
local V3 = Vector3.new
local CF = CFrame.new
local RGB = Color3.fromRGB

local DrawingNew = Drawing.new

--========================================================
-- CARGA REMOTA
--========================================================

local function loadRemote(url)
    local ok, result = pcall(function()
        local source = game:HttpGet(url)
        local chunk = loadstring(source)

        if not chunk then
            return nil
        end

        return chunk()
    end)

    if ok then
        return result
    end

    return nil
end

local Library = loadRemote(
    "https://raw.githubusercontent.com/MORTEX8/LuaMenu/refs/heads/main/RBLX-Menu"
)

if not Library then
    return
end

--========================================================
-- DRAWING API
--========================================================

local ESP_API = {}

function ESP_API.NewText(info)
    info = info or {}

    local object = DrawingNew("Text")
    object.Visible = info.Visible == true
    object.Transparency = info.Transparency or 1
    object.Color = info.Color or RGB(0, 0, 0)
    object.Text = info.Text or ""
    object.Size = info.Size or 14
    object.Center = info.Center == true
    object.Outline = info.Outline == true
    object.OutlineColor = info.OutlineColor or RGB(0, 0, 0)
    object.Font = info.Font or 3

    return object
end

function ESP_API.NewLine(info)
    info = info or {}

    local object = DrawingNew("Line")
    object.Visible = info.Visible == true
    object.Transparency = info.Transparency or 1
    object.Color = info.Color or RGB(0, 0, 0)
    object.Thickness = info.Thickness or 1

    return object
end

--========================================================
-- CONFIGURACIÓN
--========================================================

local DESTROY = false

local RCX = {
    ESP = {
        Toggle = true,

        Info = false,
        Max_Info_Distance = 100,
        Hover_Info = false,

        Names = false,
        Health = false,
        Distance = false,

        Boxes = false,
        Boxes_Mode = "Corners",
        Boxes_Distance = 100,
        Health_Bar = false,
        Health_Bar_Distance = 100,

        Color = {R = 255, G = 255, B = 0},

        Show_Target = false,
        Target_Color = {R = 255, G = 255, B = 255},

        Team_Check = false,
        Team_Color = {R = 255, G = 255, B = 0},
        Enemy_Color = {R = 255, G = 0, B = 0},

        View_Tracer = false,
        View_Tracer_Length = 10,
        View_Tracer_Distance = 100,
    },

    AIMBOT = {
        Toggle = false,
        Bone = "Head",
        Smoothness = 0.5,

        Distance_Type = "Mouse",
        Aim_Key = "Q",
        Aim_Mode = "Key",

        Team_Check = false,

        FOV = false,
        FOV_Radius = 50,
        FOV_Color = {R = 255, G = 255, B = 0},
    },

    UI = {
        UI_Toggle_Key = "End",
        Save_Settings_Key = "Home",
        Window_Size = {X = 750, Y = 550},
    },
}

local RCXFile = "coolprohax.dat"

local function mergeSavedSettings(target, saved)
    if type(saved) ~= "table" then
        return
    end

    for key, defaultValue in pairs(target) do
        local savedValue = saved[key]

        if savedValue ~= nil then
            if type(defaultValue) == "table" and type(savedValue) == "table" then
                mergeSavedSettings(defaultValue, savedValue)
            elseif type(savedValue) == type(defaultValue) then
                target[key] = savedValue
            end
        end
    end
end

local function loadSettings()
    local okRead, contents = pcall(readfile, RCXFile)

    if not okRead or type(contents) ~= "string" then
        return
    end

    local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, contents)

    if okDecode then
        mergeSavedSettings(RCX, decoded)
    end
end

local function saveSettings()
    pcall(function()
        writefile(RCXFile, HttpService:JSONEncode(RCX))
    end)
end

loadSettings()

--========================================================
-- INTERFAZ
--========================================================

local RCX_Window = Library.NewWindow("Neverdies.me", {
    window_size = V2(RCX.UI.Window_Size.X, RCX.UI.Window_Size.Y),

    window_size_func = function(newSize)
        RCX.UI.Window_Size = {
            X = newSize.X,
            Y = newSize.Y,
        }
    end,

    scalable = true,

    exit_func = function()
        DESTROY = true
    end,
})

-- VISUALS
local ESP_Page = RCX_Window.NewPage("Visuals")

local MAIN_ESP_Category = ESP_Page.NewCategory("Main")

MAIN_ESP_Category.NewToggle("Master Switch", function(value)
    RCX.ESP.Toggle = value
end, {
    default = RCX.ESP.Toggle,
})

do
    local color = RCX.ESP.Color

    MAIN_ESP_Category.NewColorpicker("Color", function(newColor)
        RCX.ESP.Color = {
            R = newColor.R * 255,
            G = newColor.G * 255,
            B = newColor.B * 255,
        }
    end, {
        default = RGB(color.R, color.G, color.B),
    })
end

MAIN_ESP_Category.NewToggle("Team Check", function(value)
    RCX.ESP.Team_Check = value
end, {
    default = RCX.ESP.Team_Check,
})

do
    local color = RCX.ESP.Team_Color

    MAIN_ESP_Category.NewColorpicker("Team", function(newColor)
        RCX.ESP.Team_Color = {
            R = newColor.R * 255,
            G = newColor.G * 255,
            B = newColor.B * 255,
        }
    end, {
        default = RGB(color.R, color.G, color.B),
    })
end

do
    local color = RCX.ESP.Enemy_Color

    MAIN_ESP_Category.NewColorpicker("Enemies", function(newColor)
        RCX.ESP.Enemy_Color = {
            R = newColor.R * 255,
            G = newColor.G * 255,
            B = newColor.B * 255,
        }
    end, {
        default = RGB(color.R, color.G, color.B),
    })
end

MAIN_ESP_Category.NewToggle("Show Target", function(value)
    RCX.ESP.Show_Target = value
end, {
    default = RCX.ESP.Show_Target,
})

do
    local color = RCX.ESP.Target_Color

    MAIN_ESP_Category.NewColorpicker("Target", function(newColor)
        RCX.ESP.Target_Color = {
            R = newColor.R * 255,
            G = newColor.G * 255,
            B = newColor.B * 255,
        }
    end, {
        default = RGB(color.R, color.G, color.B),
    })
end

local PLR_INFO_Category = ESP_Page.NewCategory("Player Info")

PLR_INFO_Category.NewToggle("Toggle", function(value)
    RCX.ESP.Info = value
end, {
    default = RCX.ESP.Info,
})

PLR_INFO_Category.NewSlider("Max Info Distance", function(value)
    RCX.ESP.Max_Info_Distance = value
end, {
    default = RCX.ESP.Max_Info_Distance,
    min = 50,
    max = 5000,
    decimals = 0,
    suffix = " studs",
})

PLR_INFO_Category.NewToggle("Hover Only", function(value)
    RCX.ESP.Hover_Info = value
end, {
    default = RCX.ESP.Hover_Info,
})

PLR_INFO_Category.NewToggle("Names", function(value)
    RCX.ESP.Names = value
end, {
    default = RCX.ESP.Names,
})

PLR_INFO_Category.NewToggle("Health", function(value)
    RCX.ESP.Health = value
end, {
    default = RCX.ESP.Health,
})

PLR_INFO_Category.NewToggle("Distance", function(value)
    RCX.ESP.Distance = value
end, {
    default = RCX.ESP.Distance,
})

local BOXES_Category = ESP_Page.NewCategory("Boxes")

BOXES_Category.NewToggle("Toggle", function(value)
    RCX.ESP.Boxes = value
end, {
    default = RCX.ESP.Boxes,
})

do
    local options = {"Corners", "Outline"}
    local defaultOption = table.find(options, RCX.ESP.Boxes_Mode) or 1

    BOXES_Category.NewDropdown("Box Type", function(option)
        RCX.ESP.Boxes_Mode = option
    end, {
        options = options,
        default = defaultOption,
    })
end

BOXES_Category.NewSlider("Max Box Distance", function(value)
    RCX.ESP.Boxes_Distance = value
end, {
    default = RCX.ESP.Boxes_Distance,
    min = 50,
    max = 5000,
    decimals = 0,
    suffix = " studs",
})

BOXES_Category.NewToggle("Health Bar", function(value)
    RCX.ESP.Health_Bar = value
end, {
    default = RCX.ESP.Health_Bar,
})

BOXES_Category.NewSlider("Max Bar Distance", function(value)
    RCX.ESP.Health_Bar_Distance = value
end, {
    default = RCX.ESP.Health_Bar_Distance,
    min = 50,
    max = 5000,
    decimals = 0,
    suffix = " studs",
})

local VIEW_TRACER_Category = ESP_Page.NewCategory("View Tracers")

VIEW_TRACER_Category.NewToggle("Toggle", function(value)
    RCX.ESP.View_Tracer = value
end, {
    default = RCX.ESP.View_Tracer,
})

VIEW_TRACER_Category.NewSlider("Length", function(value)
    RCX.ESP.View_Tracer_Length = value
end, {
    default = RCX.ESP.View_Tracer_Length,
    min = 1,
    max = 50,
    decimals = 0,
    suffix = " studs",
})

VIEW_TRACER_Category.NewSlider("Max Tracer Distance", function(value)
    RCX.ESP.View_Tracer_Distance = value
end, {
    default = RCX.ESP.View_Tracer_Distance,
    min = 50,
    max = 5000,
    decimals = 0,
    suffix = " studs",
})

-- AIMBOT
local AIMBOT_Page = RCX_Window.NewPage("Aimbot")
local MAIN_AIMBOT_Category = AIMBOT_Page.NewCategory("Main")

MAIN_AIMBOT_Category.NewToggle("Toggle", function(value)
    RCX.AIMBOT.Toggle = value
end, {
    default = RCX.AIMBOT.Toggle,
})

do
    local options = {"Key", "Mouse"}
    local defaultOption = table.find(options, RCX.AIMBOT.Aim_Mode) or 1

    MAIN_AIMBOT_Category.NewDropdown("Aim Mode", function(option)
        RCX.AIMBOT.Aim_Mode = option
    end, {
        options = options,
        default = defaultOption,
    })
end

MAIN_AIMBOT_Category.NewKeybind("Aim Key", function()
end, function(newKey)
    RCX.AIMBOT.Aim_Key = tostring(newKey):gsub("Enum.KeyCode.", "")
end, {
    default = Enum.KeyCode[RCX.AIMBOT.Aim_Key],
})

MAIN_AIMBOT_Category.NewSlider("Smoothness", function(value)
    RCX.AIMBOT.Smoothness = value
end, {
    default = RCX.AIMBOT.Smoothness,
    min = 0.01,
    max = 1,
    decimals = 2,
    suffix = " factor",
})

do
    local options = {"Head", "Neck", "Torso", "Feet", "Random"}
    local defaultOption = table.find(options, RCX.AIMBOT.Bone) or 1

    MAIN_AIMBOT_Category.NewDropdown("Bone", function(option)
        RCX.AIMBOT.Bone = option
    end, {
        options = options,
        default = defaultOption,
    })
end

do
    local options = {"Mouse", "Character"}
    local defaultOption = table.find(options, RCX.AIMBOT.Distance_Type) or 1

    MAIN_AIMBOT_Category.NewDropdown("Distance Type", function(option)
        RCX.AIMBOT.Distance_Type = option
    end, {
        options = options,
        default = defaultOption,
    })
end

MAIN_AIMBOT_Category.NewToggle("Team Check", function(value)
    RCX.AIMBOT.Team_Check = value
end, {
    default = RCX.AIMBOT.Team_Check,
})

local FOV_Category = AIMBOT_Page.NewCategory("FOV")

FOV_Category.NewToggle("Toggle", function(value)
    RCX.AIMBOT.FOV = value
end, {
    default = RCX.AIMBOT.FOV,
})

FOV_Category.NewSlider("Radius", function(value)
    RCX.AIMBOT.FOV_Radius = value
end, {
    default = RCX.AIMBOT.FOV_Radius,
    min = 0,
    max = 500,
    decimals = 0,
    suffix = " px",
})

do
    local color = RCX.AIMBOT.FOV_Color

    FOV_Category.NewColorpicker("Color", function(newColor)
        RCX.AIMBOT.FOV_Color = {
            R = newColor.R * 255,
            G = newColor.G * 255,
            B = newColor.B * 255,
        }
    end, {
        default = RGB(color.R, color.G, color.B),
    })
end

-- SETTINGS
local SETTINGS_Page = RCX_Window.NewPage("Settings")
local MAIN_SETTINGS_Category = SETTINGS_Page.NewCategory("Main")

MAIN_SETTINGS_Category.NewKeybind("Hide Key", function()
    RCX_Window.Hide()
end, function(newKey)
    RCX.UI.UI_Toggle_Key = tostring(newKey):gsub("Enum.KeyCode.", "")
end, {
    default = Enum.KeyCode[RCX.UI.UI_Toggle_Key],
})

MAIN_SETTINGS_Category.NewButton("Save Settings", saveSettings)

MAIN_SETTINGS_Category.NewKeybind("Save Settings Keybind", saveSettings, function(newKey)
    RCX.UI.Save_Settings_Key = tostring(newKey):gsub("Enum.KeyCode.", "")
end, {
    default = Enum.KeyCode[RCX.UI.Save_Settings_Key],
})

--========================================================
-- ESTADO COMPARTIDO
--========================================================

local Aiming = false
local random_part = 0
local Selected_Player = nil

--========================================================
-- UTILIDADES
--========================================================

local GuiInset = GuiService:GetGuiInset()

local function getCamera()
    return Workspace.CurrentCamera
end

local function getMousePosition()
    return V2(Mouse.X, Mouse.Y + GuiInset.Y)
end

local function getCharacter(player)
    if not player then
        return nil
    end

    if player.Character and player.Character.Parent then
        return player.Character
    end

    return Workspace:FindFirstChild(player.Name, true)
end

local function getRootPart(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function getHumanoid(character)
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

local function sameTeam(player)
    if not RCX.AIMBOT.Team_Check then
        return false
    end

    return player.TeamColor == LocalPlayer.TeamColor
end

local function espColorFor(player, character)
    local selectedColor

    if RCX.ESP.Team_Check then
        if player.TeamColor == LocalPlayer.TeamColor then
            selectedColor = RCX.ESP.Team_Color
        else
            selectedColor = RCX.ESP.Enemy_Color
        end
    else
        selectedColor = RCX.ESP.Color
    end

    if RCX.ESP.Show_Target and Selected_Player == character then
        selectedColor = RCX.ESP.Target_Color
    end

    return RGB(selectedColor.R, selectedColor.G, selectedColor.B)
end

local function getAimWorldPosition(character, rootPart)
    if not character or not rootPart then
        return nil
    end

    local bone = RCX.AIMBOT.Bone
    local head = character:FindFirstChild("Head")

    if bone == "Head" and head then
        return head.Position
    end

    if bone == "Neck" and head then
        return head.Position - V3(0, head.Size.Y / 2, 0)
    end

    if bone == "Feet" then
        return rootPart.Position - V3(0, 2.5, 0)
    end

    if bone == "Random" then
        if random_part == 1 and head then
            return head.Position
        elseif random_part == 3 then
            return rootPart.Position - V3(0, 2.5, 0)
        end
    end

    return rootPart.Position
end

local function hideDrawing(drawings)
    drawings.info.Visible = false
    drawings.bar.Visible = false
    drawings.healthBar.Visible = false
    drawings.tracer.Visible = false

    for _, line in ipairs(drawings.boxLines) do
        line.Visible = false
    end
end

local function setBoxVisibility(lines, visible, count)
    for index, line in ipairs(lines) do
        line.Visible = visible and index <= count
    end
end

--========================================================
-- AIMBOT STATE
--========================================================

local aimInputBegan
local aimInputEnded

aimInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if DESTROY then
        aimInputBegan:Disconnect()
        return
    end

    if gameProcessed or not RCX.AIMBOT.Toggle then
        return
    end

    if RCX.AIMBOT.Aim_Mode == "Key"
        and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Enum.KeyCode[RCX.AIMBOT.Aim_Key]
    then
        random_part = random(1, 3)
        Aiming = true
    elseif RCX.AIMBOT.Aim_Mode == "Mouse"
        and input.UserInputType == Enum.UserInputType.MouseButton2
    then
        random_part = random(1, 3)
        Aiming = true
    end
end)

aimInputEnded = UserInputService.InputEnded:Connect(function(input)
    if DESTROY then
        aimInputEnded:Disconnect()
        Aiming = false
        return
    end

    if RCX.AIMBOT.Aim_Mode == "Key"
        and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Enum.KeyCode[RCX.AIMBOT.Aim_Key]
    then
        random_part = 0
        Aiming = false
    elseif RCX.AIMBOT.Aim_Mode == "Mouse"
        and input.UserInputType == Enum.UserInputType.MouseButton2
    then
        random_part = 0
        Aiming = false
    end
end)

--========================================================
-- FOV
--========================================================

local FOV = DrawingNew("Circle")
FOV.Visible = false
FOV.Transparency = 0.6
FOV.NumSides = 75
FOV.Filled = false
FOV.Thickness = 1

local function updateFOV()
    if not RCX.AIMBOT.Toggle then
        FOV.Visible = false
        return
    end

    local color = RCX.AIMBOT.FOV_Color

    FOV.Color = RGB(color.R, color.G, color.B)
    FOV.Position = getMousePosition()
    FOV.Radius = RCX.AIMBOT.FOV_Radius
    FOV.Visible = RCX.AIMBOT.FOV
end

--========================================================
-- SELECCIÓN DE OBJETIVO
--========================================================

local function getClosestTarget()
    if not RCX.AIMBOT.Toggle then
        return nil
    end

    local camera = getCamera()

    if not camera then
        return nil
    end

    local localCharacter = getCharacter(LocalPlayer)
    local localRoot = getRootPart(localCharacter)
    local mousePosition = getMousePosition()

    if RCX.AIMBOT.Distance_Type == "Character" and not localRoot then
        return nil
    end

    local closestCharacter = nil
    local closestDistance = huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not sameTeam(player) then
            local character = getCharacter(player)
            local humanoid = getHumanoid(character)
            local rootPart = getRootPart(character)

            if character and humanoid and humanoid.Health > 0 and rootPart then
                local aimWorldPosition = getAimWorldPosition(character, rootPart)

                if aimWorldPosition then
                    local screenPoint, visible = camera:WorldToViewportPoint(aimWorldPosition)

                    if visible then
                        local screenPosition = V2(screenPoint.X, screenPoint.Y)

                        if not RCX.AIMBOT.FOV
                            or (screenPosition - FOV.Position).Magnitude <= RCX.AIMBOT.FOV_Radius
                        then
                            local distance

                            if RCX.AIMBOT.Distance_Type == "Character" then
                                distance = (localRoot.Position - rootPart.Position).Magnitude
                            else
                                distance = (mousePosition - screenPosition).Magnitude
                            end

                            if distance < closestDistance then
                                closestDistance = distance
                                closestCharacter = character
                            end
                        end
                    end
                end
            end
        end
    end

    return closestCharacter
end

--========================================================
-- ESP
--========================================================

local ActiveESP = {}

local function removeESP(player)
    local data = ActiveESP[player]

    if not data then
        return
    end

    if data.connection and data.connection.Connected then
        data.connection:Disconnect()
    end

    if data.restoreHumanoidName then
        data.restoreHumanoidName()
    end

    data.info:Remove()
    data.bar:Remove()
    data.healthBar:Remove()
    data.tracer:Remove()

    for _, line in ipairs(data.boxLines) do
        line:Remove()
    end

    ActiveESP[player] = nil
end

local function addESP(player)
    if player == LocalPlayer or ActiveESP[player] then
        return
    end

    local drawings = {
        info = ESP_API.NewText({
            Center = true,
        }),

        bar = ESP_API.NewLine({
            Color = RGB(10, 10, 10),
            Thickness = 3,
            Transparency = 0.4,
        }),

        healthBar = ESP_API.NewLine({
            Color = RGB(0, 255, 0),
            Thickness = 1,
        }),

        tracer = ESP_API.NewLine({
            Color = RGB(0, 255, 0),
            Thickness = 1,
        }),

        boxLines = {},
    }

    for index = 1, 8 do
        drawings.boxLines[index] = ESP_API.NewLine({})
    end

    local previousHealth = nil
    local lastHumanoid = nil
    local originalDisplayType = nil

    local function restoreHumanoidName()
        if lastHumanoid and lastHumanoid.Parent and originalDisplayType then
            lastHumanoid.DisplayDistanceType = originalDisplayType
        end

        lastHumanoid = nil
        originalDisplayType = nil
    end

    local function setHumanoidNameHidden(humanoid, hidden)
        if lastHumanoid ~= humanoid then
            restoreHumanoidName()
            lastHumanoid = humanoid
            originalDisplayType = humanoid.DisplayDistanceType
        end

        if hidden then
            humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        elseif originalDisplayType then
            humanoid.DisplayDistanceType = originalDisplayType
        end
    end

    local connection

    connection = RunService.RenderStepped:Connect(function()
        if DESTROY or not player.Parent then
            restoreHumanoidName()
            removeESP(player)
            return
        end

        if not RCX.ESP.Toggle then
            hideDrawing(drawings)
            restoreHumanoidName()
            return
        end

        local camera = getCamera()
        local localCharacter = getCharacter(LocalPlayer)
        local character = getCharacter(player)

        local localRoot = getRootPart(localCharacter)
        local rootPart = getRootPart(character)
        local humanoid = getHumanoid(character)

        if not camera
            or not localRoot
            or not rootPart
            or not humanoid
            or humanoid.Health <= 0
        then
            hideDrawing(drawings)
            restoreHumanoidName()
            return
        end

        local distance = (rootPart.Position - localRoot.Position).Magnitude
        local rootPosition, onScreen = camera:WorldToViewportPoint(rootPart.Position)

        if RCX.ESP.View_Tracer
            and distance < RCX.ESP.View_Tracer_Distance
            and character:FindFirstChild("Head")
        then
            local head = character.Head
            local headPosition, headVisible = camera:WorldToViewportPoint(head.Position)

            if headVisible then
                local directionPosition = camera:WorldToViewportPoint(
                    (head.CFrame * CF(0, 0, -RCX.ESP.View_Tracer_Length)).Position
                )

                drawings.tracer.From = V2(headPosition.X, headPosition.Y)
                drawings.tracer.To = V2(directionPosition.X, directionPosition.Y)
                drawings.tracer.Visible = true
            else
                drawings.tracer.Visible = false
            end
        else
            drawings.tracer.Visible = false
        end

        if not onScreen or rootPosition.Z <= 0 then
            drawings.info.Visible = false
            drawings.bar.Visible = false
            drawings.healthBar.Visible = false
            drawings.tracer.Visible = false
            setBoxVisibility(drawings.boxLines, false, 0)
            restoreHumanoidName()
            return
        end

        local currentColor = espColorFor(player, character)

        drawings.info.Color = currentColor
        drawings.tracer.Color = currentColor

        for _, line in ipairs(drawings.boxLines) do
            line.Color = currentColor
        end

        local ratio = 2500 / rootPosition.Z
        local halfWidth = ratio / 2
        local halfHeight = ratio * 1.75 / 2

        local rootX = rootPosition.X
        local rootY = rootPosition.Y

        if RCX.ESP.Boxes and distance < RCX.ESP.Boxes_Distance then
            local topLeft = V2(rootX - halfWidth, rootY - halfHeight)
            local topRight = V2(rootX + halfWidth, rootY - halfHeight)
            local bottomLeft = V2(rootX - halfWidth, rootY + halfHeight)
            local bottomRight = V2(rootX + halfWidth, rootY + halfHeight)

            if RCX.ESP.Health_Bar and distance < RCX.ESP.Health_Bar_Distance then
                local healthRatio = clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                local offsetX = clamp(round(200 / rootPosition.Z), 4, 8)

                local right = rootX + halfWidth
                local top = rootY - halfHeight
                local bottom = rootY + halfHeight
                local barX = right + offsetX

                drawings.bar.From = V2(barX, top)
                drawings.bar.To = V2(barX, bottom)

                local length = abs((bottom - 1) - (top + 1))
                local healthLength = length * healthRatio

                drawings.healthBar.From = V2(barX, bottom - 1 - healthLength)
                drawings.healthBar.To = V2(barX, bottom - 1)

                if humanoid.Health ~= previousHealth then
                    drawings.healthBar.Color =
                        RGB(255, 0, 0):Lerp(RGB(0, 255, 0), healthRatio)

                    previousHealth = humanoid.Health
                end

                drawings.bar.Visible = true
                drawings.healthBar.Visible = true
            else
                drawings.bar.Visible = false
                drawings.healthBar.Visible = false
            end

            if RCX.ESP.Boxes_Mode == "Corners" then
                local horizontal = V2(ratio / 4, 0)
                local vertical = V2(0, ratio / 4)

                drawings.boxLines[1].From = topLeft
                drawings.boxLines[1].To = topLeft + horizontal

                drawings.boxLines[2].From = topLeft
                drawings.boxLines[2].To = topLeft + vertical

                drawings.boxLines[3].From = topRight
                drawings.boxLines[3].To = topRight - horizontal

                drawings.boxLines[4].From = topRight
                drawings.boxLines[4].To = topRight + vertical

                drawings.boxLines[5].From = bottomLeft
                drawings.boxLines[5].To = bottomLeft + horizontal

                drawings.boxLines[6].From = bottomLeft
                drawings.boxLines[6].To = bottomLeft - vertical

                drawings.boxLines[7].From = bottomRight
                drawings.boxLines[7].To = bottomRight - horizontal

                drawings.boxLines[8].From = bottomRight
                drawings.boxLines[8].To = bottomRight - vertical

                setBoxVisibility(drawings.boxLines, true, 8)
            else
                drawings.boxLines[1].From = topRight
                drawings.boxLines[1].To = topLeft

                drawings.boxLines[2].From = topLeft
                drawings.boxLines[2].To = bottomLeft

                drawings.boxLines[3].From = bottomLeft
                drawings.boxLines[3].To = bottomRight

                drawings.boxLines[4].From = bottomRight
                drawings.boxLines[4].To = topRight

                setBoxVisibility(drawings.boxLines, true, 4)
            end
        else
            drawings.bar.Visible = false
            drawings.healthBar.Visible = false
            setBoxVisibility(drawings.boxLines, false, 0)
        end

        if RCX.ESP.Info and distance < RCX.ESP.Max_Info_Distance then
            local showInfo = true

            if RCX.ESP.Hover_Info then
                local mousePosition = getMousePosition()
                local playerPosition = V2(rootX, rootY)

                showInfo =
                    (mousePosition - playerPosition).Magnitude
                    < clamp(ratio * 1.25, 5, huge)
            end

            if showInfo then
                local parts = {}

                if RCX.ESP.Health then
                    table.insert(
                        parts,
                        tostring(round(humanoid.Health / humanoid.MaxHealth * 100)) .. "%"
                    )
                end

                if RCX.ESP.Names then
                    table.insert(parts, player.Name)
                end

                if RCX.ESP.Distance then
                    table.insert(parts, "(" .. tostring(round(distance)) .. ")")
                end

                drawings.info.Text = table.concat(parts, " ")
                drawings.info.Position =
                    V2(rootX, rootY - halfHeight - drawings.info.TextBounds.Y)

                drawings.info.Visible = #parts > 0

                setHumanoidNameHidden(humanoid, drawings.info.Visible)
            else
                drawings.info.Visible = false
                setHumanoidNameHidden(humanoid, false)
            end
        else
            drawings.info.Visible = false
            setHumanoidNameHidden(humanoid, false)
        end
    end)

    drawings.connection = connection
    drawings.restoreHumanoidName = restoreHumanoidName

    ActiveESP[player] = drawings
end

for _, player in ipairs(Players:GetPlayers()) do
    addESP(player)
end

local playerAddedConnection = Players.PlayerAdded:Connect(addESP)

local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

--========================================================
-- LOOP PRINCIPAL DEL AIMBOT
--========================================================

local aimbotConnection

aimbotConnection = RunService.RenderStepped:Connect(function()
    if DESTROY then
        Selected_Player = nil
        Aiming = false

        FOV:Remove()

        if aimInputBegan and aimInputBegan.Connected then
            aimInputBegan:Disconnect()
        end

        if aimInputEnded and aimInputEnded.Connected then
            aimInputEnded:Disconnect()
        end

        if playerAddedConnection and playerAddedConnection.Connected then
            playerAddedConnection:Disconnect()
        end

        if playerRemovingConnection and playerRemovingConnection.Connected then
            playerRemovingConnection:Disconnect()
        end

        local playersToRemove = {}

        for player in pairs(ActiveESP) do
            table.insert(playersToRemove, player)
        end

        for _, player in ipairs(playersToRemove) do
            removeESP(player)
        end

        aimbotConnection:Disconnect()
        return
    end

    updateFOV()

    if not RCX.AIMBOT.Toggle then
        Selected_Player = nil
        Aiming = false
        return
    end

    Selected_Player = getClosestTarget()

    if not Aiming or not Selected_Player then
        return
    end

    local camera = getCamera()
    local rootPart = getRootPart(Selected_Player)

    if not camera or not rootPart then
        return
    end

    local aimWorldPosition = getAimWorldPosition(Selected_Player, rootPart)

    if not aimWorldPosition then
        return
    end

    local screenPosition = camera:WorldToViewportPoint(aimWorldPosition)
    local sensitivity = clamp(1 - RCX.AIMBOT.Smoothness, 0.01, 1) / 1.5

    mousemoverel(
        (screenPosition.X - Mouse.X) * sensitivity,
        (screenPosition.Y - Mouse.Y - GuiInset.Y) * sensitivity
    )
end)
