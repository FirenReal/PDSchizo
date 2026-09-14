-- RSWA
-- Servicios
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
-- Atajos
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
local Library = {}
local UI_THEME = { Background = RGB(10, 13, 19), Surface = RGB(16, 20, 28), Card = RGB(22, 27, 37), CardHover = RGB(27, 33, 44), Border = RGB(42, 50, 66), Accent = RGB(64, 214, 190), AccentSoft = RGB(35, 112, 105), Text = RGB(239, 244, 249), Muted = RGB(145, 155, 172), Dim = RGB(93, 103, 120), Danger = RGB(232, 84, 97), }
local function new(className, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    return object
end
local function addCorner(parent, radius)
return new("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent, })
end
local function addStroke(parent, color, transparency, thickness)
return new("UIStroke", { Color = color or UI_THEME.Border, Transparency = transparency or 0, Thickness = thickness or 1, Parent = parent, })
end
local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.14,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )
    animation:Play()
    return animation
end
local function formatNumber(value, decimals)
    decimals = decimals or 0
    if decimals <= 0 then
        return tostring(round(value))
    end
    return string.format("%." .. tostring(decimals) .. "f", value)
end
function Library.NewWindow(title, options)
    options = options or {}
    local oldGui = CoreGui:FindFirstChild(title)
    if oldGui then
        oldGui:Destroy()
    end
local gui = new("ScreenGui", { Name = title, ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = CoreGui, })
    local initialSize = options.window_size or V2(720, 520)
local root = new("Frame", { Name = "Main_Window", AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(initialSize.X, initialSize.Y), BackgroundColor3 = UI_THEME.Background, BorderSizePixel = 0, ClipsDescendants = true, Parent = gui, })
    addCorner(root, 12)
    addStroke(root, UI_THEME.Border, 0.18, 1)
local shadow = new("ImageLabel", { Name = "Shadow", AnchorPoint = V2(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 42, 1, 42), BackgroundTransparency = 1, Image = "rbxassetid://6015897843", ImageColor3 = RGB(0, 0, 0), ImageTransparency = 0.52, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = 0, Parent = root, })
local topBar = new("Frame", { Name = "Top_Bar", Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = UI_THEME.Surface, BorderSizePixel = 0, ZIndex = 4, Parent = root, })
local accent = new("Frame", { Name = "Accent", Position = UDim2.fromOffset(0, 47), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = UI_THEME.Accent, BorderSizePixel = 0, ZIndex = 5, Parent = topBar, })
local titleLabel = new("TextLabel", { Name = "Top_Bar_Title", Position = UDim2.fromOffset(16, 7), Size = UDim2.new(0, 120, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = title, TextColor3 = UI_THEME.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = topBar, })
local subtitle = new("TextLabel", { Position = UDim2.fromOffset(16, 26), Size = UDim2.new(0, 180, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = "control panel", TextColor3 = UI_THEME.Muted, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = topBar, })
local minimizeButton = new("TextButton", { Name = "Minimize_Button", AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -50, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = UI_THEME.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "−", TextColor3 = UI_THEME.Muted, TextSize = 18, ZIndex = 7, Parent = topBar, })
    addCorner(minimizeButton, 7)
local closeButton = new("TextButton", { Name = "Close_Button", AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = UI_THEME.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold, Text = "×", TextColor3 = UI_THEME.Muted, TextSize = 17, ZIndex = 7, Parent = topBar, })
    addCorner(closeButton, 7)
local dragZone = new("TextButton", {
    Name = "Drag_Zone",
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, -78, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
    Active = true,
    ZIndex = 5,
    Parent = topBar,
})
local body = new("Frame", { Name = "Body", Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -48), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = root, })
local sidebar = new("Frame", { Name = "Sidebar", Size = UDim2.new(0, 142, 1, 0), BackgroundColor3 = UI_THEME.Surface, BorderSizePixel = 0, Parent = body, })
local sidebarPadding = new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = sidebar, })
local sidebarLayout = new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar, })
local pages = new("Frame", { Name = "Pages", Position = UDim2.fromOffset(142, 0), Size = UDim2.new(1, -142, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = body, })
local resizeHandle = new("TextButton", { Name = "Resize_Handle", AnchorPoint = V2(1, 1), Position = UDim2.new(1, -3, 1, -3), Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "◢", Font = Enum.Font.Gotham, TextColor3 = UI_THEME.Dim, TextSize = 14, ZIndex = 8, Parent = root, })
    local window = {}
    local pageObjects = {}
    local currentPage = nil
    local hidden = false
    local minimized = false
    local compactEnabled = true
    local compactWidth = 180
    local expandedSize = root.Size
    local expandedPosition = root.Position
    local expandedTopLeft = nil
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local dragStartPosition = nil
    local dragStartTopLeft = nil
    local resizing = false
    local resizeStart = nil
    local resizeStartSize = nil
    local function selectPage(pageObject)
        for _, page in ipairs(pageObjects) do
            local active = page == pageObject
            page.Container.Visible = active
tween(page.Button, 0.12, { BackgroundColor3 = active and UI_THEME.AccentSoft or UI_THEME.Card, TextColor3 = active and UI_THEME.Text or UI_THEME.Muted, })
        end
        currentPage = pageObject
    end
    local function getViewportSize()
        local camera = Workspace.CurrentCamera
        return camera and camera.ViewportSize or V2(1920, 1080)
    end

    local function getSizePixels(size)
        local viewport = getViewportSize()
        return V2(
            size.X.Offset + viewport.X * size.X.Scale,
            size.Y.Offset + viewport.Y * size.Y.Scale
        )
    end

    local function topLeftToPosition(topLeft, size)
        local pixels = getSizePixels(size)
        return UDim2.fromOffset(
            topLeft.X + pixels.X * root.AnchorPoint.X,
            topLeft.Y + pixels.Y * root.AnchorPoint.Y
        )
    end

    local function clampTopLeft(topLeft, size)
        local viewport = getViewportSize()
        local pixels = getSizePixels(size)
        local maxX = math.max(0, viewport.X - math.min(pixels.X, viewport.X))
        local maxY = math.max(0, viewport.Y - 48)
        return V2(
            clamp(topLeft.X, 0, maxX),
            clamp(topLeft.Y, 0, maxY)
        )
    end

    local function getCurrentTopLeft()
        return V2(root.AbsolutePosition.X, root.AbsolutePosition.Y)
    end

    local function restoreWindow()
        if not minimized then
            return
        end

        local topLeft = expandedTopLeft or getCurrentTopLeft()
        topLeft = clampTopLeft(topLeft, expandedSize)
        expandedTopLeft = topLeft
        expandedPosition = topLeftToPosition(topLeft, expandedSize)

        minimized = false
        body.Visible = true
        resizeHandle.Visible = true
        minimizeButton.Text = "−"

        tween(root, 0.16, {
            Size = expandedSize,
            Position = expandedPosition,
        })
    end

    local function minimizeWindow()
        if minimized then
            restoreWindow()
            return
        end

        expandedSize = root.Size
        expandedTopLeft = clampTopLeft(getCurrentTopLeft(), expandedSize)
        expandedPosition = topLeftToPosition(expandedTopLeft, expandedSize)

        minimized = true
        body.Visible = false
        resizeHandle.Visible = false
        minimizeButton.Text = "+"

        local width = compactEnabled and compactWidth or math.max(260, root.AbsoluteSize.X)
        local compactSize = UDim2.fromOffset(width, 48)
        local compactTopLeft = clampTopLeft(expandedTopLeft, compactSize)

        tween(root, 0.16, {
            Size = compactSize,
            Position = topLeftToPosition(compactTopLeft, compactSize),
        })
    end
    minimizeButton.MouseButton1Click:Connect(minimizeWindow)
    minimizeButton.MouseEnter:Connect(function()
        tween(minimizeButton, 0.1, {BackgroundColor3 = UI_THEME.CardHover})
    end)
    minimizeButton.MouseLeave:Connect(function()
        tween(minimizeButton, 0.1, {BackgroundColor3 = UI_THEME.Card})
    end)
    closeButton.MouseEnter:Connect(function()
tween(closeButton, 0.1, { BackgroundColor3 = UI_THEME.Danger, TextColor3 = UI_THEME.Text, })
    end)
    closeButton.MouseLeave:Connect(function()
tween(closeButton, 0.1, { BackgroundColor3 = UI_THEME.Card, TextColor3 = UI_THEME.Muted, })
    end)
    closeButton.MouseButton1Click:Connect(function()
        if options.exit_func then
            pcall(options.exit_func)
        end
        gui:Destroy()
    end)
    dragZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            dragStartPosition = root.Position
            dragStartTopLeft = getCurrentTopLeft()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                    dragStartTopLeft = nil
                end
            end)
        end
    end)

    dragZone.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not minimized then
            resizing = true
            resizeStart = input.Position
            resizeStartSize = root.AbsoluteSize
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging
            and dragInput
            and input == dragInput
            and dragStart
            and dragStartTopLeft
        then
            local delta = input.Position - dragStart
            local currentSize = root.Size
            local newTopLeft = clampTopLeft(
                dragStartTopLeft + V2(delta.X, delta.Y),
                currentSize
            )

            root.Position = topLeftToPosition(newTopLeft, currentSize)

            if minimized then
                expandedTopLeft = newTopLeft
                expandedPosition = topLeftToPosition(newTopLeft, expandedSize)
            else
                expandedTopLeft = newTopLeft
                expandedPosition = root.Position
            end

            return
        end

        if resizing
            and input.UserInputType == Enum.UserInputType.MouseMovement
            and resizeStart
            and resizeStartSize
        then
            local delta = input.Position - resizeStart
            local width = clamp(resizeStartSize.X + delta.X, 560, 980)
            local height = clamp(resizeStartSize.Y + delta.Y, 380, 760)
            root.Size = UDim2.fromOffset(width, height)
            expandedSize = root.Size

            if options.window_size_func then
                pcall(options.window_size_func, V2(width, height))
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            dragInput = nil
            dragStartTopLeft = nil
            resizing = false
        end
    end)
    function window.NewPage(name)
        local page = {}
local button = new("TextButton", { Name = name .. "_Tab", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = UI_THEME.Card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, Text = name, TextColor3 = UI_THEME.Muted, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = sidebar, })
        addCorner(button, 7)
new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = button, })
local container = new("ScrollingFrame", { Name = name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = UI_THEME.Accent, CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = pages, })
new("UIPadding", { PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = container, })
new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = container, })
        page.Button = button
        page.Container = container
        table.insert(pageObjects, page)
        button.MouseButton1Click:Connect(function()
            selectPage(page)
        end)
        button.MouseEnter:Connect(function()
            if currentPage ~= page then
                tween(button, 0.1, {BackgroundColor3 = UI_THEME.CardHover})
            end
        end)
        button.MouseLeave:Connect(function()
            if currentPage ~= page then
                tween(button, 0.1, {BackgroundColor3 = UI_THEME.Card})
            end
        end)
        function page.NewCategory(categoryName)
            local category = {}
local card = new("Frame", { Name = categoryName, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = UI_THEME.Surface, BorderSizePixel = 0, Parent = container, })
            addCorner(card, 9)
            addStroke(card, UI_THEME.Border, 0.3, 1)
local categoryTitle = new("TextLabel", { Name = "Category_Title", Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = categoryName, TextColor3 = UI_THEME.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = card, })
new("UIPadding", { PaddingLeft = UDim.new(0, 12), Parent = categoryTitle, })
local optionsHolder = new("Frame", { Name = "Options_Holder", Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card, })
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = optionsHolder, })
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = optionsHolder, })
            local function createRow(labelText, height)
local row = new("Frame", { Name = labelText, Size = UDim2.new(1, 0, 0, height or 36), BackgroundColor3 = UI_THEME.Card, BorderSizePixel = 0, Parent = optionsHolder, })
                addCorner(row, 7)
local label = new("TextLabel", { Name = "Label", Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.5, -10, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = labelText, TextColor3 = UI_THEME.Text, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, })
                return row, label
            end
            function category.NewToggle(labelText, callback, config)
                config = config or {}
                local value = config.default == true
                local row = createRow(labelText, 36)
local switch = new("TextButton", { AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(38, 20), BackgroundColor3 = value and UI_THEME.AccentSoft or RGB(47, 54, 68), BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = row, })
                addCorner(switch, 10)
local knob = new("Frame", { AnchorPoint = V2(0.5, 0.5), Position = value and UDim2.new(1, -10, 0.5, 0) or UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = value and UI_THEME.Accent or UI_THEME.Muted, BorderSizePixel = 0, Parent = switch, })
                addCorner(knob, 7)
                local function render()
tween(switch, 0.12, { BackgroundColor3 = value and UI_THEME.AccentSoft or RGB(47, 54, 68), })
tween(knob, 0.12, { Position = value and UDim2.new(1, -10, 0.5, 0) or UDim2.fromOffset(10, 10), BackgroundColor3 = value and UI_THEME.Accent or UI_THEME.Muted, })
                end
                switch.MouseButton1Click:Connect(function()
                    value = not value
                    render()
                    pcall(callback, value)
                end)
                return {
                    Set = function(_, newValue)
                        value = newValue == true
                        render()
                        pcall(callback, value)
                    end,
                    Get = function()
                        return value
                    end,
                }
            end
            function category.NewSlider(labelText, callback, config)
                config = config or {}
                local minimum = config.min or 0
                local maximum = config.max or 100
                local decimals = config.decimals or 0
                local suffix = config.suffix or ""
                local value = clamp(config.default or minimum, minimum, maximum)
                local row = createRow(labelText, 48)
local valueLabel = new("TextLabel", { AnchorPoint = V2(1, 0), Position = UDim2.new(1, -10, 0, 5), Size = UDim2.fromOffset(120, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextColor3 = UI_THEME.Accent, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = row, })
local bar = new("TextButton", { Position = UDim2.new(0, 10, 1, -13), Size = UDim2.new(1, -20, 0, 5), BackgroundColor3 = RGB(43, 49, 62), BorderSizePixel = 0, AutoButtonColor = false, Text = "", Parent = row, })
                addCorner(bar, 3)
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI_THEME.Accent, BorderSizePixel = 0, Parent = bar, })
                addCorner(fill, 3)
                local sliding = false
                local function setValue(newValue, fire)
                    newValue = clamp(newValue, minimum, maximum)
                    local factor = (newValue - minimum) / math.max(maximum - minimum, 0.0001)
                    value = newValue
                    valueLabel.Text = formatNumber(value, decimals) .. suffix
                    fill.Size = UDim2.fromScale(factor, 1)
                    if fire then
                        pcall(callback, value)
                    end
                end
                local function valueFromX(x)
                    local factor = clamp(
                        (x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1),
                        0,
                        1
                    )
                    local raw = minimum + (maximum - minimum) * factor
                    local precision = 10 ^ decimals
                    return round(raw * precision) / precision
                end
                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        setValue(valueFromX(input.Position.X), true)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setValue(valueFromX(input.Position.X), true)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
                setValue(value, false)
                return {
                    Set = function(_, newValue)
                        setValue(newValue, true)
                    end,
                    Get = function()
                        return value
                    end,
                }
            end
            function category.NewDropdown(labelText, callback, config)
                config = config or {}
                local optionsList = config.options or {}
                local index = clamp(config.default or 1, 1, math.max(#optionsList, 1))
                local row = createRow(labelText, 36)
local selector = new("TextButton", { AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(138, 24), BackgroundColor3 = RGB(31, 37, 49), BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, Text = optionsList[index] or "None", TextColor3 = UI_THEME.Accent, TextSize = 10, Parent = row, })
                addCorner(selector, 6)
                addStroke(selector, UI_THEME.Border, 0.35, 1)
                selector.MouseButton1Click:Connect(function()
                    if #optionsList == 0 then
                        return
                    end
                    index = index % #optionsList + 1
                    selector.Text = optionsList[index]
                    pcall(callback, optionsList[index])
                end)
                return selector
            end
            function category.NewColorpicker(labelText, callback, config)
                config = config or {}
                local color = config.default or RGB(255, 255, 255)
                local row = createRow(labelText, 36)
local preview = new("Frame", { AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = color, BorderSizePixel = 0, Parent = row, })
                addCorner(preview, 6)
                addStroke(preview, UI_THEME.Border, 0.15, 1)
                local boxes = {}
                local channels = {"R", "G", "B"}
local initial = { round(color.R * 255), round(color.G * 255), round(color.B * 255), }
                for i, channel in ipairs(channels) do
local box = new("TextBox", { AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -40 - ((3 - i) * 44), 0.5, 0), Size = UDim2.fromOffset(40, 24), BackgroundColor3 = RGB(31, 37, 49), BorderSizePixel = 0, ClearTextOnFocus = false, Font = Enum.Font.Gotham, PlaceholderText = channel, Text = tostring(initial[i]), TextColor3 = UI_THEME.Text, TextSize = 9, Parent = row, })
                    addCorner(box, 5)
                    addStroke(box, UI_THEME.Border, 0.35, 1)
                    boxes[i] = box
                end
                local function updateColor()
                    local r = clamp(tonumber(boxes[1].Text) or initial[1], 0, 255)
                    local g = clamp(tonumber(boxes[2].Text) or initial[2], 0, 255)
                    local b = clamp(tonumber(boxes[3].Text) or initial[3], 0, 255)
                    color = RGB(r, g, b)
                    preview.BackgroundColor3 = color
                    pcall(callback, color)
                end
                for _, box in ipairs(boxes) do
                    box.FocusLost:Connect(updateColor)
                end
                return preview
            end
            function category.NewButton(labelText, callback)
                local row = createRow(labelText, 36)
local button = new("TextButton", { AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(100, 24), BackgroundColor3 = UI_THEME.AccentSoft, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamSemibold, Text = "RUN", TextColor3 = UI_THEME.Text, TextSize = 9, Parent = row, })
                addCorner(button, 6)
                button.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
                button.MouseEnter:Connect(function()
                    tween(button, 0.1, {BackgroundColor3 = UI_THEME.Accent})
                end)
                button.MouseLeave:Connect(function()
                    tween(button, 0.1, {BackgroundColor3 = UI_THEME.AccentSoft})
                end)
                return button
            end
            function category.NewKeybind(labelText, callback, changedCallback, config)
                config = config or {}
                local key = config.default or Enum.KeyCode.Unknown
                local listening = false
                local row = createRow(labelText, 36)
local button = new("TextButton", { AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(100, 24), BackgroundColor3 = RGB(31, 37, 49), BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamMedium, Text = key.Name, TextColor3 = UI_THEME.Accent, TextSize = 9, Parent = row, })
                addCorner(button, 6)
                addStroke(button, UI_THEME.Border, 0.35, 1)
                button.MouseButton1Click:Connect(function()
                    listening = true
                    button.Text = "..."
                end)
                UserInputService.InputBegan:Connect(function(input, processed)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            key = input.KeyCode
                            listening = false
                            button.Text = key.Name
                            if changedCallback then
                                pcall(changedCallback, key)
                            end
                        end
                        return
                    end
                    if not processed
                        and input.UserInputType == Enum.UserInputType.Keyboard
                        and input.KeyCode == key
                    then
                        pcall(callback)
                    end
                end)
                return button
            end
            function category.NewTextbox(labelText, callback, config)
                config = config or {}
                local row = createRow(labelText, 38)
local input = new("TextBox", { Name = "Input", AnchorPoint = V2(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.62, 0, 0, 26), BackgroundColor3 = RGB(31, 37, 49), BorderSizePixel = 0, ClearTextOnFocus = false, Font = Enum.Font.Gotham, PlaceholderText = config.placeholder or "", PlaceholderColor3 = UI_THEME.Dim, Text = config.default or "", TextColor3 = UI_THEME.Text, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, })
                addCorner(input, 6)
                addStroke(input, UI_THEME.Border, 0.35, 1)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = input, })
                input:GetPropertyChangedSignal("Text"):Connect(function()
                    pcall(callback, input.Text)
                end)
                return {
                    Object = input,
                    Set = function(_, value)
                        input.Text = value or ""
                    end,
                    Get = function()
                        return input.Text
                    end,
                }
            end
            return category
        end
        if not currentPage then
            selectPage(page)
        end
        return page
    end
    function window.Hide()
        hidden = not hidden
        root.Visible = not hidden
    end
    function window.SetCompactEnabled(value)
        compactEnabled = value == true
    end
    function window.SetCompactWidth(value)
        compactWidth = clamp(tonumber(value) or 180, 120, 360)
        if minimized then
            root.Size = UDim2.fromOffset(compactWidth, 48)
        end
    end
    function window.Restore()
        hidden = false
        root.Visible = true
        restoreWindow()
    end
    function window.Destroy()
        if gui and gui.Parent then
            gui:Destroy()
        end
    end
    window.Gui = gui
    window.Root = root
    return window
end
-- Drawing API
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
function ESP_API.NewCircle(info)
    info = info or {}
    local object = DrawingNew("Circle")
    object.Visible = info.Visible == true
    object.Transparency = info.Transparency or 1
    object.Color = info.Color or RGB(255, 255, 255)
    object.Radius = info.Radius or 4
    object.NumSides = info.NumSides or 24
    object.Thickness = info.Thickness or 1
    object.Filled = info.Filled == true
    return object
end
-- Configuración
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
        Head_Dot = true,
        Fade = true,
        Show_Bodies = true,
        Dead_Color = {R = 160, G = 160, B = 160},
        Text_Size = 13,
        Dot_Size = 4,
    },
AI_ESP = { Toggle = true, Max_Distance = 500, Names = true, Health = true, Distance = true, Head_Dot = true, Boxes = true, Health_Bar = true, Fade = true, Show_Bodies = true, Color = {R = 0, G = 210, B = 255}, Dead_Color = {R = 160, G = 160, B = 160}, Text_Size = 13, Dot_Size = 4, },
AIMBOT = { Toggle = false, Bone = "Head", Smoothness = 0.5, Distance_Type = "Mouse", Aim_Key = "Q", Aim_Mode = "Key", Team_Check = false, Ignore_Players = "", FOV = false, FOV_Radius = 50, FOV_Color = {R = 255, G = 255, B = 0}, },
COMBAT = { Recoil_Modifier = false, Recoil_Percent = 0, },
CAMERA = { Zoom = true, Zoom_Key = "C", Zoom_Mode = "Hold", Zoom_FOV = 20, },
PERFORMANCE = { Remove_Grass = false, },
UI = { UI_Toggle_Key = "End", Save_Settings_Key = "Home", Window_Size = {X = 750, Y = 550}, Compact_Minimize = true, Compact_Width = 180, },
}
local RCXFile = "RSWA_settings.json"
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

-- Recoil
local RecoilOriginals = setmetatable({}, {__mode = "k"})
local RecoilFolderConnection = nil

local function getAmmoFolder()
    return ReplicatedStorage:FindFirstChild("AmmoTypes")
end

local function rememberRecoil(object)
    if RecoilOriginals[object] ~= nil then
        return
    end

    local value = object:GetAttribute("RecoilStrength")
    if value ~= nil then
        RecoilOriginals[object] = value
    end
end

local function applyRecoilObject(object)
    local current = object:GetAttribute("RecoilStrength")
    if current == nil and RecoilOriginals[object] == nil then
        return
    end

    rememberRecoil(object)
    local original = RecoilOriginals[object]
    if original == nil then
        return
    end

    if not RCX.COMBAT.Recoil_Modifier then
        pcall(function()
            object:SetAttribute("RecoilStrength", original)
        end)
        return
    end

    local numeric = tonumber(original)
    if numeric then
        local value = numeric * clamp(RCX.COMBAT.Recoil_Percent, 0, 100) / 100
        pcall(function()
            object:SetAttribute("RecoilStrength", value)
        end)
    elseif RCX.COMBAT.Recoil_Percent <= 0 then
        pcall(function()
            object:SetAttribute("RecoilStrength", "0")
        end)
    end
end

local function applyRecoilSettings()
    local folder = getAmmoFolder()
    if not folder then
        return
    end

    applyRecoilObject(folder)
    for _, object in ipairs(folder:GetDescendants()) do
        applyRecoilObject(object)
    end
end

local function restoreRecoil()
    for object, original in pairs(RecoilOriginals) do
        if object and object.Parent then
            pcall(function()
                object:SetAttribute("RecoilStrength", original)
            end)
        end
    end
end

local function setupRecoilWatcher()
    local folder = getAmmoFolder()
    if not folder then
        return
    end

    if RecoilFolderConnection and RecoilFolderConnection.Connected then
        RecoilFolderConnection:Disconnect()
    end

    RecoilFolderConnection = folder.DescendantAdded:Connect(function(object)
        task.defer(function()
            if not DESTROY then
                applyRecoilObject(object)
            end
        end)
    end)

    applyRecoilSettings()
end

setupRecoilWatcher()

-- Zoom
local ZoomActive = false
local ZoomOriginalFOV = nil
local ZoomInputBeganConnection = nil
local ZoomInputEndedConnection = nil
local ZoomCameraConnection = nil

local function getZoomKey()
    return Enum.KeyCode[RCX.CAMERA.Zoom_Key] or Enum.KeyCode.C
end

local function setZoomState(enabled)
    local camera = Workspace.CurrentCamera
    if not camera then
        ZoomActive = false
        ZoomOriginalFOV = nil
        return
    end

    if enabled then
        if not RCX.CAMERA.Zoom then
            return
        end

        if not ZoomActive then
            ZoomOriginalFOV = camera.FieldOfView
        end

        ZoomActive = true
        camera.FieldOfView = clamp(RCX.CAMERA.Zoom_FOV, 5, 120)
    else
        if ZoomActive and ZoomOriginalFOV then
            camera.FieldOfView = ZoomOriginalFOV
        end

        ZoomActive = false
        ZoomOriginalFOV = nil
    end
end

ZoomInputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if DESTROY or gameProcessed or not RCX.CAMERA.Zoom then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= getZoomKey() then
        return
    end

    if RCX.CAMERA.Zoom_Mode == "Toggle" then
        setZoomState(not ZoomActive)
    else
        setZoomState(true)
    end
end)

ZoomInputEndedConnection = UserInputService.InputEnded:Connect(function(input)
    if DESTROY or RCX.CAMERA.Zoom_Mode ~= "Hold" then
        return
    end

    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == getZoomKey() then
        setZoomState(false)
    end
end)

ZoomCameraConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if not ZoomActive then
        return
    end

    task.defer(function()
        local camera = Workspace.CurrentCamera
        if camera then
            ZoomOriginalFOV = camera.FieldOfView
            camera.FieldOfView = clamp(RCX.CAMERA.Zoom_FOV, 5, 120)
        end
    end)
end)

-- Rendimiento
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local OriginalTerrainDecoration = true
if Terrain then
    pcall(function()
        OriginalTerrainDecoration = Terrain.Decoration
    end)
end
local function setTerrainDecoration(enabled)
    if not Terrain then
        return false
    end
    local changed = pcall(function()
        Terrain.Decoration = enabled
    end)
    if not changed and type(sethiddenproperty) == "function" then
        changed = pcall(function()
            sethiddenproperty(Terrain, "Decoration", enabled)
        end)
    end
    return changed
end
local function applyGrassSetting()
    setTerrainDecoration(not RCX.PERFORMANCE.Remove_Grass)
end
applyGrassSetting()
-- Interfaz
local RCX_Window = Library.NewWindow("RSWA", {
    window_size = V2(RCX.UI.Window_Size.X, RCX.UI.Window_Size.Y),
    window_size_func = function(newSize)
RCX.UI.Window_Size = { X = newSize.X, Y = newSize.Y, }
    end,
    exit_func = function()
        DESTROY = true
    end,
})
RCX_Window.SetCompactEnabled(RCX.UI.Compact_Minimize)
RCX_Window.SetCompactWidth(RCX.UI.Compact_Width)
-- Visuales
local ESP_Page = RCX_Window.NewPage("Visuals")
local MAIN_ESP_Category = ESP_Page.NewCategory("Main")
MAIN_ESP_Category.NewToggle("Master Switch", function(value)
    RCX.ESP.Toggle = value
end, { default = RCX.ESP.Toggle, })
do
    local color = RCX.ESP.Color
    MAIN_ESP_Category.NewColorpicker("Color", function(newColor)
RCX.ESP.Color = { R = newColor.R * 255, G = newColor.G * 255, B = newColor.B * 255, }
end, { default = RGB(color.R, color.G, color.B), })
end
MAIN_ESP_Category.NewToggle("Team Check", function(value)
    RCX.ESP.Team_Check = value
end, { default = RCX.ESP.Team_Check, })
do
    local color = RCX.ESP.Team_Color
    MAIN_ESP_Category.NewColorpicker("Team", function(newColor)
RCX.ESP.Team_Color = { R = newColor.R * 255, G = newColor.G * 255, B = newColor.B * 255, }
end, { default = RGB(color.R, color.G, color.B), })
end
do
    local color = RCX.ESP.Enemy_Color
    MAIN_ESP_Category.NewColorpicker("Enemies", function(newColor)
RCX.ESP.Enemy_Color = { R = newColor.R * 255, G = newColor.G * 255, B = newColor.B * 255, }
end, { default = RGB(color.R, color.G, color.B), })
end
MAIN_ESP_Category.NewToggle("Show Target", function(value)
    RCX.ESP.Show_Target = value
end, { default = RCX.ESP.Show_Target, })
do
    local color = RCX.ESP.Target_Color
    MAIN_ESP_Category.NewColorpicker("Target", function(newColor)
RCX.ESP.Target_Color = { R = newColor.R * 255, G = newColor.G * 255, B = newColor.B * 255, }
end, { default = RGB(color.R, color.G, color.B), })
end
local PLR_INFO_Category = ESP_Page.NewCategory("Player Info")
PLR_INFO_Category.NewToggle("Toggle", function(value)
    RCX.ESP.Info = value
end, { default = RCX.ESP.Info, })
PLR_INFO_Category.NewSlider("Max Info Distance", function(value)
    RCX.ESP.Max_Info_Distance = value
end, { default = RCX.ESP.Max_Info_Distance, min = 50, max = 5000, decimals = 0, suffix = " studs", })
PLR_INFO_Category.NewToggle("Hover Only", function(value)
    RCX.ESP.Hover_Info = value
end, { default = RCX.ESP.Hover_Info, })
PLR_INFO_Category.NewToggle("Names", function(value)
    RCX.ESP.Names = value
end, { default = RCX.ESP.Names, })
PLR_INFO_Category.NewToggle("Health", function(value)
    RCX.ESP.Health = value
end, { default = RCX.ESP.Health, })
PLR_INFO_Category.NewToggle("Distance", function(value)
    RCX.ESP.Distance = value
end, { default = RCX.ESP.Distance, })
PLR_INFO_Category.NewToggle("Head Dot", function(value)
    RCX.ESP.Head_Dot = value
end, { default = RCX.ESP.Head_Dot, })
PLR_INFO_Category.NewToggle("Distance Fade", function(value)
    RCX.ESP.Fade = value
end, { default = RCX.ESP.Fade, })
PLR_INFO_Category.NewToggle("Show Bodies", function(value)
    RCX.ESP.Show_Bodies = value
end, { default = RCX.ESP.Show_Bodies, })

do
    local color = RCX.ESP.Dead_Color
    PLR_INFO_Category.NewColorpicker("Dead Color", function(newColor)
        RCX.ESP.Dead_Color = {
            R = newColor.R * 255,
            G = newColor.G * 255,
            B = newColor.B * 255,
        }
    end, { default = RGB(color.R, color.G, color.B), })
end
PLR_INFO_Category.NewSlider("Text Size", function(value)
    RCX.ESP.Text_Size = value
end, { default = RCX.ESP.Text_Size, min = 10, max = 20, decimals = 0, suffix = " px", })
PLR_INFO_Category.NewSlider("Dot Size", function(value)
    RCX.ESP.Dot_Size = value
end, { default = RCX.ESP.Dot_Size, min = 2, max = 9, decimals = 0, suffix = " px", })
local BOXES_Category = ESP_Page.NewCategory("Boxes")
BOXES_Category.NewToggle("Toggle", function(value)
    RCX.ESP.Boxes = value
end, { default = RCX.ESP.Boxes, })
do
    local options = {"Corners", "Outline"}
    local defaultOption = table.find(options, RCX.ESP.Boxes_Mode) or 1
    BOXES_Category.NewDropdown("Box Type", function(option)
        RCX.ESP.Boxes_Mode = option
end, { options = options, default = defaultOption, })
end
BOXES_Category.NewSlider("Max Box Distance", function(value)
    RCX.ESP.Boxes_Distance = value
end, { default = RCX.ESP.Boxes_Distance, min = 50, max = 5000, decimals = 0, suffix = " studs", })
BOXES_Category.NewToggle("Health Bar", function(value)
    RCX.ESP.Health_Bar = value
end, { default = RCX.ESP.Health_Bar, })
BOXES_Category.NewSlider("Max Bar Distance", function(value)
    RCX.ESP.Health_Bar_Distance = value
end, { default = RCX.ESP.Health_Bar_Distance, min = 50, max = 5000, decimals = 0, suffix = " studs", })
local VIEW_TRACER_Category = ESP_Page.NewCategory("View Tracers")
VIEW_TRACER_Category.NewToggle("Toggle", function(value)
    RCX.ESP.View_Tracer = value
end, { default = RCX.ESP.View_Tracer, })
VIEW_TRACER_Category.NewSlider("Length", function(value)
    RCX.ESP.View_Tracer_Length = value
end, { default = RCX.ESP.View_Tracer_Length, min = 1, max = 50, decimals = 0, suffix = " studs", })
VIEW_TRACER_Category.NewSlider("Max Tracer Distance", function(value)
    RCX.ESP.View_Tracer_Distance = value
end, { default = RCX.ESP.View_Tracer_Distance, min = 50, max = 5000, decimals = 0, suffix = " studs", })
local AI_ESP_Category = ESP_Page.NewCategory("AI / NPC")
AI_ESP_Category.NewToggle("AI ESP", function(value)
    RCX.AI_ESP.Toggle = value
end, { default = RCX.AI_ESP.Toggle, })
do
    local color = RCX.AI_ESP.Color
    AI_ESP_Category.NewColorpicker("AI Color", function(newColor)
RCX.AI_ESP.Color = { R = newColor.R * 255, G = newColor.G * 255, B = newColor.B * 255, }
end, { default = RGB(color.R, color.G, color.B), })
end
AI_ESP_Category.NewSlider("Max Distance", function(value)
    RCX.AI_ESP.Max_Distance = value
end, { default = RCX.AI_ESP.Max_Distance, min = 50, max = 5000, decimals = 0, suffix = " studs", })
AI_ESP_Category.NewToggle("Head Dot", function(value)
    RCX.AI_ESP.Head_Dot = value
end, { default = RCX.AI_ESP.Head_Dot, })
AI_ESP_Category.NewToggle("Corner Box", function(value)
    RCX.AI_ESP.Boxes = value
end, { default = RCX.AI_ESP.Boxes, })
AI_ESP_Category.NewToggle("Health Bar", function(value)
    RCX.AI_ESP.Health_Bar = value
end, { default = RCX.AI_ESP.Health_Bar, })
AI_ESP_Category.NewToggle("Name", function(value)
    RCX.AI_ESP.Names = value
end, { default = RCX.AI_ESP.Names, })
AI_ESP_Category.NewToggle("Health Text", function(value)
    RCX.AI_ESP.Health = value
end, { default = RCX.AI_ESP.Health, })
AI_ESP_Category.NewToggle("Distance Text", function(value)
    RCX.AI_ESP.Distance = value
end, { default = RCX.AI_ESP.Distance, })
AI_ESP_Category.NewToggle("Distance Fade", function(value)
    RCX.AI_ESP.Fade = value
end, { default = RCX.AI_ESP.Fade, })
AI_ESP_Category.NewToggle("Show Bodies", function(value)
    RCX.AI_ESP.Show_Bodies = value
end, { default = RCX.AI_ESP.Show_Bodies, })

do
    local color = RCX.AI_ESP.Dead_Color
    AI_ESP_Category.NewColorpicker("Dead Color", function(newColor)
        RCX.AI_ESP.Dead_Color = {
            R = newColor.R * 255,
            G = newColor.G * 255,
            B = newColor.B * 255,
        }
    end, { default = RGB(color.R, color.G, color.B), })
end
AI_ESP_Category.NewSlider("Text Size", function(value)
    RCX.AI_ESP.Text_Size = value
end, { default = RCX.AI_ESP.Text_Size, min = 10, max = 20, decimals = 0, suffix = " px", })
AI_ESP_Category.NewSlider("Dot Size", function(value)
    RCX.AI_ESP.Dot_Size = value
end, { default = RCX.AI_ESP.Dot_Size, min = 2, max = 9, decimals = 0, suffix = " px", })
-- Aimbot UI
local AIMBOT_Page = RCX_Window.NewPage("Aimbot")
local MAIN_AIMBOT_Category = AIMBOT_Page.NewCategory("Main")
MAIN_AIMBOT_Category.NewToggle("Toggle", function(value)
    RCX.AIMBOT.Toggle = value
end, { default = RCX.AIMBOT.Toggle, })
do
    local options = {"Key", "Mouse"}
    local defaultOption = table.find(options, RCX.AIMBOT.Aim_Mode) or 1
    MAIN_AIMBOT_Category.NewDropdown("Aim Mode", function(option)
        RCX.AIMBOT.Aim_Mode = option
end, { options = options, default = defaultOption, })
end
MAIN_AIMBOT_Category.NewKeybind("Aim Key", function()
end, function(newKey)
    RCX.AIMBOT.Aim_Key = tostring(newKey):gsub("Enum.KeyCode.", "")
end, { default = Enum.KeyCode[RCX.AIMBOT.Aim_Key], })
MAIN_AIMBOT_Category.NewSlider("Smoothness", function(value)
    RCX.AIMBOT.Smoothness = value
end, { default = RCX.AIMBOT.Smoothness, min = 0.01, max = 1, decimals = 2, suffix = " factor", })
do
    local options = {"Head", "Neck", "Torso", "Feet", "Random"}
    local defaultOption = table.find(options, RCX.AIMBOT.Bone) or 1
    MAIN_AIMBOT_Category.NewDropdown("Bone", function(option)
        RCX.AIMBOT.Bone = option
end, { options = options, default = defaultOption, })
end
do
    local options = {"Mouse", "Character"}
    local defaultOption = table.find(options, RCX.AIMBOT.Distance_Type) or 1
    MAIN_AIMBOT_Category.NewDropdown("Distance Type", function(option)
        RCX.AIMBOT.Distance_Type = option
end, { options = options, default = defaultOption, })
end
MAIN_AIMBOT_Category.NewToggle("Team Check", function(value)
    RCX.AIMBOT.Team_Check = value
end, { default = RCX.AIMBOT.Team_Check, })
local FOV_Category = AIMBOT_Page.NewCategory("FOV")
FOV_Category.NewToggle("Toggle", function(value)
    RCX.AIMBOT.FOV = value
end, { default = RCX.AIMBOT.FOV, })
FOV_Category.NewSlider("Radius", function(value)
    RCX.AIMBOT.FOV_Radius = value
end, { default = RCX.AIMBOT.FOV_Radius, min = 0, max = 500, decimals = 0, suffix = " px", })
do
    local color = RCX.AIMBOT.FOV_Color
    FOV_Category.NewColorpicker("Color", function(newColor)
RCX.AIMBOT.FOV_Color = { R = newColor.R * 255, G = newColor.G * 255, B = newColor.B * 255, }
end, { default = RGB(color.R, color.G, color.B), })
end
local IGNORE_AIMBOT_Category = AIMBOT_Page.NewCategory("Ignore Players")
local IgnorePlayersInput = IGNORE_AIMBOT_Category.NewTextbox(
    "Ignored names",
    function(value)
        RCX.AIMBOT.Ignore_Players = value
    end,
{ default = RCX.AIMBOT.Ignore_Players or "", placeholder = "Name1, Name2...", }
)
IGNORE_AIMBOT_Category.NewButton("Clear Ignore List", function()
    RCX.AIMBOT.Ignore_Players = ""
    IgnorePlayersInput:Set("")
end)
-- Combat
local COMBAT_Page = RCX_Window.NewPage("Combat")

local RECOIL_Category = COMBAT_Page.NewCategory("Recoil")
RECOIL_Category.NewToggle("Recoil Modifier", function(value)
    RCX.COMBAT.Recoil_Modifier = value
    applyRecoilSettings()
end, { default = RCX.COMBAT.Recoil_Modifier, })

RECOIL_Category.NewSlider("Recoil", function(value)
    RCX.COMBAT.Recoil_Percent = value
    applyRecoilSettings()
end, {
    default = RCX.COMBAT.Recoil_Percent,
    min = 0,
    max = 100,
    decimals = 0,
    suffix = "%",
})

local ZOOM_Category = COMBAT_Page.NewCategory("Zoom")
ZOOM_Category.NewToggle("Zoom", function(value)
    RCX.CAMERA.Zoom = value
    if not value then
        setZoomState(false)
    end
end, { default = RCX.CAMERA.Zoom, })

ZOOM_Category.NewKeybind("Zoom Key", function()
end, function(newKey)
    RCX.CAMERA.Zoom_Key = tostring(newKey):gsub("Enum.KeyCode.", "")
end, { default = Enum.KeyCode[RCX.CAMERA.Zoom_Key] or Enum.KeyCode.C, })

do
    local options = {"Hold", "Toggle"}
    local defaultOption = table.find(options, RCX.CAMERA.Zoom_Mode) or 1

    ZOOM_Category.NewDropdown("Zoom Mode", function(option)
        if ZoomActive then
            setZoomState(false)
        end
        RCX.CAMERA.Zoom_Mode = option
    end, { options = options, default = defaultOption, })
end

ZOOM_Category.NewSlider("Zoom FOV", function(value)
    RCX.CAMERA.Zoom_FOV = value

    if ZoomActive and Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = value
    end
end, {
    default = RCX.CAMERA.Zoom_FOV,
    min = 5,
    max = 90,
    decimals = 0,
    suffix = "°",
})

-- Rendimiento UI
local PERFORMANCE_Page = RCX_Window.NewPage("Performance")
local WORLD_PERFORMANCE_Category = PERFORMANCE_Page.NewCategory("World")
WORLD_PERFORMANCE_Category.NewToggle("Remove Grass", function(value)
    RCX.PERFORMANCE.Remove_Grass = value
    applyGrassSetting()
end, { default = RCX.PERFORMANCE.Remove_Grass, })
local INTERFACE_PERFORMANCE_Category = PERFORMANCE_Page.NewCategory("Interface")
INTERFACE_PERFORMANCE_Category.NewToggle("Compact Minimize", function(value)
    RCX.UI.Compact_Minimize = value
    RCX_Window.SetCompactEnabled(value)
end, { default = RCX.UI.Compact_Minimize, })
INTERFACE_PERFORMANCE_Category.NewSlider("Compact Width", function(value)
    RCX.UI.Compact_Width = value
    RCX_Window.SetCompactWidth(value)
end, { default = RCX.UI.Compact_Width, min = 140, max = 300, decimals = 0, suffix = " px", })
-- Ajustes
local SETTINGS_Page = RCX_Window.NewPage("Settings")
local MAIN_SETTINGS_Category = SETTINGS_Page.NewCategory("Main")
MAIN_SETTINGS_Category.NewKeybind("Hide Key", function()
    RCX_Window.Hide()
end, function(newKey)
    RCX.UI.UI_Toggle_Key = tostring(newKey):gsub("Enum.KeyCode.", "")
end, { default = Enum.KeyCode[RCX.UI.UI_Toggle_Key], })
MAIN_SETTINGS_Category.NewButton("Save Settings", saveSettings)
MAIN_SETTINGS_Category.NewKeybind("Save Settings Keybind", saveSettings, function(newKey)
    RCX.UI.Save_Settings_Key = tostring(newKey):gsub("Enum.KeyCode.", "")
end, { default = Enum.KeyCode[RCX.UI.Save_Settings_Key], })
-- Estado
local Aiming = false
local AimActivation = nil
local random_part = 0
local Selected_Player = nil
-- Utilidades
local GuiInset = GuiService:GetGuiInset()
local function getCamera()
    return Workspace.CurrentCamera
end
local function getMousePosition()
    return V2(Mouse.X, Mouse.Y + GuiInset.Y)
end

local function isOnViewport(camera, screenPoint, visibleFlag)
    if not camera or not screenPoint or not visibleFlag or screenPoint.Z <= 0 then
        return false
    end
    local size = camera.ViewportSize
    return screenPoint.X >= 0
        and screenPoint.X <= size.X
        and screenPoint.Y >= 0
        and screenPoint.Y <= size.Y
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
local function getIgnoredPlayerSet()
    local ignored = {}
    local source = RCX.AIMBOT.Ignore_Players or ""
    for name in source:gmatch("[^,;\n]+") do
        local clean =
            name:gsub("^%s+", ""):gsub("%s+$", ""):lower()
        if clean ~= "" then
            ignored[clean] = true
        end
    end
    return ignored
end
local function isAimbotIgnored(player)
    if not player then
        return false
    end
    local ignored = getIgnoredPlayerSet()
    if ignored[player.Name:lower()] then
        return true
    end
    if player.DisplayName
        and ignored[player.DisplayName:lower()]
    then
        return true
    end
    return false
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
    if drawings.status then
        drawings.status.Visible = false
    end
    if drawings.dotOutline then
        drawings.dotOutline.Visible = false
    end
    if drawings.dot then
        drawings.dot.Visible = false
    end
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
-- Estado del aimbot
local aimInputBegan
local aimInputEnded
aimInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if DESTROY then
        if aimInputBegan and aimInputBegan.Connected then
            aimInputBegan:Disconnect()
        end
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
        AimActivation = "Key"
        Aiming = true
    elseif RCX.AIMBOT.Aim_Mode == "Mouse"
        and input.UserInputType == Enum.UserInputType.MouseButton2
    then
        random_part = random(1, 3)
        AimActivation = "Mouse"
        Aiming = true
    end
end)
aimInputEnded = UserInputService.InputEnded:Connect(function(input)
    if DESTROY then
        if aimInputEnded and aimInputEnded.Connected then
            aimInputEnded:Disconnect()
        end
        AimActivation = nil
        Aiming = false
        return
    end
    local releasedActivation = false
    if AimActivation == "Key"
        and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Enum.KeyCode[RCX.AIMBOT.Aim_Key]
    then
        releasedActivation = true
    elseif AimActivation == "Mouse"
        and input.UserInputType == Enum.UserInputType.MouseButton2
    then
        releasedActivation = true
    end
    if releasedActivation then
        random_part = 0
        AimActivation = nil
        Aiming = false
    end
end)
-- FOV
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
-- Selección de objetivo
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
        if player ~= LocalPlayer
            and not sameTeam(player)
            and not isAimbotIgnored(player)
        then
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
-- ESP de jugadores
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
    if data.status then
        data.status:Remove()
    end
    if data.dotOutline then
        data.dotOutline:Remove()
    end
    if data.dot then
        data.dot:Remove()
    end
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
local drawings = { info = ESP_API.NewText({ Center = true, Outline = true, Size = RCX.ESP.Text_Size, }), status = ESP_API.NewText({ Center = true, Outline = true, Size = math.max(RCX.ESP.Text_Size - 1, 9), }), dotOutline = ESP_API.NewCircle({ Color = RGB(0, 0, 0), Filled = false, Radius = RCX.ESP.Dot_Size + 2, NumSides = 24, Thickness = 2, }), dot = ESP_API.NewCircle({ Filled = true, Radius = RCX.ESP.Dot_Size, NumSides = 24, }), bar = ESP_API.NewLine({ Color = RGB(10, 10, 10), Thickness = 3, Transparency = 0.4, }), healthBar = ESP_API.NewLine({ Color = RGB(0, 255, 0), Thickness = 1, }), tracer = ESP_API.NewLine({ Color = RGB(0, 255, 0), Thickness = 1, }), boxLines = {}, }
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
            or (humanoid.Health <= 0 and not RCX.ESP.Show_Bodies)
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
            if isOnViewport(camera, headPosition, headVisible) then
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
        if not isOnViewport(camera, rootPosition, onScreen) then
            hideDrawing(drawings)
            restoreHumanoidName()
            return
        end
        local currentColor
        local isDead = humanoid.Health <= 0

        if isDead then
            local dead = RCX.ESP.Dead_Color
            currentColor = RGB(dead.R, dead.G, dead.B)
        else
            currentColor = espColorFor(player, character)
        end
        local visualTransparency = 1
        if RCX.ESP.Fade then
            visualTransparency = clamp(
                1 - (
                    distance
                    / math.max(
                        math.max(
                            RCX.ESP.Max_Info_Distance,
                            RCX.ESP.Boxes_Distance,
                            RCX.ESP.Health_Bar_Distance,
                            RCX.ESP.View_Tracer_Distance
                        ),
                        1
                    )
                ) * 0.55,
                0.4,
                1
            )
        end
        drawings.info.Color = currentColor
        drawings.info.Size = RCX.ESP.Text_Size
        drawings.info.Transparency = visualTransparency
        drawings.status.Color = RGB(230, 230, 235)
        drawings.status.Size = math.max(RCX.ESP.Text_Size - 1, 9)
        drawings.status.Transparency = visualTransparency
        drawings.tracer.Color = currentColor
        drawings.tracer.Transparency = visualTransparency
        drawings.dot.Color = currentColor
        drawings.dot.Radius = RCX.ESP.Dot_Size
        drawings.dot.Transparency = visualTransparency
        drawings.dotOutline.Radius = RCX.ESP.Dot_Size + 2
        drawings.dotOutline.Transparency = visualTransparency
        for _, line in ipairs(drawings.boxLines) do
            line.Color = currentColor
            line.Transparency = visualTransparency
        end
        local head = character:FindFirstChild("Head")
        if RCX.ESP.Head_Dot and head and head:IsA("BasePart") then
            local headScreen, headVisible =
                camera:WorldToViewportPoint(head.Position)
            local maxDotDistance = math.max(
                RCX.ESP.Max_Info_Distance,
                RCX.ESP.Boxes_Distance,
                RCX.ESP.Health_Bar_Distance,
                RCX.ESP.View_Tracer_Distance
            )
            local showHeadDot =
                distance <= maxDotDistance
                and isOnViewport(camera, headScreen, headVisible)
            if showHeadDot then
                drawings.dot.Position =
                    V2(headScreen.X, headScreen.Y)
                drawings.dotOutline.Position =
                    V2(headScreen.X, headScreen.Y)
            end
            drawings.dot.Visible = showHeadDot
            drawings.dotOutline.Visible = showHeadDot
        else
            drawings.dot.Visible = false
            drawings.dotOutline.Visible = false
        end
        local ratio = 2500 / rootPosition.Z
        local halfWidth = ratio / 2
        local halfHeight = ratio * 1.75 / 2
        local rootX = rootPosition.X
        local rootY = rootPosition.Y
        local topLeft = V2(rootX - halfWidth, rootY - halfHeight)
        local topRight = V2(rootX + halfWidth, rootY - halfHeight)
        local bottomLeft = V2(rootX - halfWidth, rootY + halfHeight)
        local bottomRight = V2(rootX + halfWidth, rootY + halfHeight)
        if RCX.ESP.Health_Bar
            and distance < RCX.ESP.Health_Bar_Distance
        then
            local healthRatio = clamp(
                humanoid.Health / math.max(humanoid.MaxHealth, 1),
                0,
                1
            )
            local offsetX = clamp(round(200 / rootPosition.Z), 4, 8)
            local right = rootX + halfWidth
            local top = rootY - halfHeight
            local bottom = rootY + halfHeight
            local barX = right + offsetX
            drawings.bar.From = V2(barX, top)
            drawings.bar.To = V2(barX, bottom)
            local length = abs((bottom - 1) - (top + 1))
            local healthLength = length * healthRatio
            drawings.healthBar.From =
                V2(barX, bottom - 1 - healthLength)
            drawings.healthBar.To =
                V2(barX, bottom - 1)
            if humanoid.Health ~= previousHealth then
                if isDead then
                    local dead = RCX.ESP.Dead_Color
                    drawings.healthBar.Color = RGB(dead.R, dead.G, dead.B)
                else
                    drawings.healthBar.Color =
                        RGB(255, 0, 0):Lerp(
                            RGB(0, 255, 0),
                            healthRatio
                        )
                end
                previousHealth = humanoid.Health
            end
            drawings.bar.Visible = true
            drawings.healthBar.Visible = true
        else
            drawings.bar.Visible = false
            drawings.healthBar.Visible = false
        end
        if RCX.ESP.Boxes
            and distance < RCX.ESP.Boxes_Distance
        then
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
                local topY = rootY - halfHeight
                local bottomY = rootY + halfHeight
                if RCX.ESP.Names then
                    drawings.info.Text = player.Name
                    if player.DisplayName
                        and player.DisplayName ~= player.Name
                    then
                        drawings.info.Text =
                            player.DisplayName
                            .. "  ["
                            .. player.Name
                            .. "]"
                    end
                    drawings.info.Position =
                        V2(rootX, topY - drawings.info.TextBounds.Y - 2)
                    drawings.info.Visible = true
                else
                    drawings.info.Visible = false
                end
                local statusParts = {}
                if RCX.ESP.Health then
                    table.insert(
                        statusParts,
                        tostring(
                            round(
                                humanoid.Health
                                / math.max(humanoid.MaxHealth, 1)
                                * 100
                            )
                        ) .. "%"
                    )
                end
                if RCX.ESP.Distance then
                    table.insert(
                        statusParts,
                        tostring(round(distance)) .. " studs"
                    )
                end
                drawings.status.Text =
                    table.concat(statusParts, "  •  ")
                drawings.status.Position =
                    V2(rootX, bottomY + 3)
                drawings.status.Visible = #statusParts > 0
                setHumanoidNameHidden(
                    humanoid,
                    drawings.info.Visible
                )
            else
                drawings.info.Visible = false
                drawings.status.Visible = false
                setHumanoidNameHidden(humanoid, false)
            end
        else
            drawings.info.Visible = false
            drawings.status.Visible = false
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
local ActiveAIESP = {}
local function isAIModel(model)
    if not model or not model:IsA("Model") then
        return false
    end
    if Players:GetPlayerFromCharacter(model) then
        return false
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local head = model:FindFirstChild("Head")
    return humanoid ~= nil
        and head ~= nil
        and head:IsA("BasePart")
end
local function getAIRoot(model)
    if not model then
        return nil
    end
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("UpperTorso")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
        or model:FindFirstChild("Head")
end
local function removeAIESP(model)
    local data = ActiveAIESP[model]
    if not data then
        return
    end
    data.nameText:Remove()
    data.statusText:Remove()
    data.dotOutline:Remove()
    data.dot:Remove()
    data.healthBackground:Remove()
    data.healthBar:Remove()
    for _, line in ipairs(data.boxLines) do
        line:Remove()
    end
    ActiveAIESP[model] = nil
end
local function hideAIESP(data)
    data.nameText.Visible = false
    data.statusText.Visible = false
    data.dotOutline.Visible = false
    data.dot.Visible = false
    data.healthBackground.Visible = false
    data.healthBar.Visible = false
    for _, line in ipairs(data.boxLines) do
        line.Visible = false
    end
end
local function addAIESP(model)
    if ActiveAIESP[model] or not isAIModel(model) then
        return
    end
local data = { nameText = ESP_API.NewText({ Center = true, Outline = true, Size = RCX.AI_ESP.Text_Size, }), statusText = ESP_API.NewText({ Center = true, Outline = true, Size = RCX.AI_ESP.Text_Size - 1, }), dotOutline = ESP_API.NewCircle({ Color = RGB(0, 0, 0), Filled = false, Radius = RCX.AI_ESP.Dot_Size + 2, NumSides = 24, Thickness = 2, }), dot = ESP_API.NewCircle({ Color = RGB( RCX.AI_ESP.Color.R, RCX.AI_ESP.Color.G, RCX.AI_ESP.Color.B ), Filled = true, Radius = RCX.AI_ESP.Dot_Size, NumSides = 24, }), healthBackground = ESP_API.NewLine({ Color = RGB(5, 5, 5), Thickness = 4, Transparency = 0.7, }), healthBar = ESP_API.NewLine({ Color = RGB(0, 255, 0), Thickness = 2, }), boxLines = {}, }
    for index = 1, 8 do
data.boxLines[index] = ESP_API.NewLine({ Thickness = 1.25, })
    end
    ActiveAIESP[model] = data
end
local function getModelScreenBounds(model, camera)
    local ok, boxCFrame, boxSize = pcall(function()
        local cf, size = model:GetBoundingBox()
        return cf, size
    end)
    if not ok or not boxCFrame or not boxSize then
        return nil
    end
    local half = boxSize * 0.5
    local minX, minY = huge, huge
    local maxX, maxY = -huge, -huge
    local pointsInFront = 0
    for x = -1, 1, 2 do
        for y = -1, 1, 2 do
            for z = -1, 1, 2 do
                local worldPoint = boxCFrame:PointToWorldSpace(
                    V3(
                        half.X * x,
                        half.Y * y,
                        half.Z * z
                    )
                )
                local screenPoint = camera:WorldToViewportPoint(worldPoint)
                if screenPoint.Z > 0 then
                    pointsInFront = pointsInFront + 1
                    minX = math.min(minX, screenPoint.X)
                    minY = math.min(minY, screenPoint.Y)
                    maxX = math.max(maxX, screenPoint.X)
                    maxY = math.max(maxY, screenPoint.Y)
                end
            end
        end
    end
    if pointsInFront == 0 then
        return nil
    end
    local width = maxX - minX
    local height = maxY - minY
    if width < 2 or height < 2 then
        return nil
    end
    local viewport = camera.ViewportSize
    if width > viewport.X * 0.9
        or height > viewport.Y * 0.95
    then
        return nil
    end
    return minX, minY, maxX, maxY
end
local function updateAICornerBox(lines, minX, minY, maxX, maxY)
    local width = maxX - minX
    local height = maxY - minY
    local cornerX = clamp(width * 0.23, 5, 22)
    local cornerY = clamp(height * 0.18, 5, 22)
    lines[1].From = V2(minX, minY)
    lines[1].To = V2(minX + cornerX, minY)
    lines[2].From = V2(minX, minY)
    lines[2].To = V2(minX, minY + cornerY)
    lines[3].From = V2(maxX, minY)
    lines[3].To = V2(maxX - cornerX, minY)
    lines[4].From = V2(maxX, minY)
    lines[4].To = V2(maxX, minY + cornerY)
    lines[5].From = V2(minX, maxY)
    lines[5].To = V2(minX + cornerX, maxY)
    lines[6].From = V2(minX, maxY)
    lines[6].To = V2(minX, maxY - cornerY)
    lines[7].From = V2(maxX, maxY)
    lines[7].To = V2(maxX - cornerX, maxY)
    lines[8].From = V2(maxX, maxY)
    lines[8].To = V2(maxX, maxY - cornerY)
end
local function setAITransparency(data, transparency)
    data.nameText.Transparency = transparency
    data.statusText.Transparency = transparency
    data.dotOutline.Transparency = transparency
    data.dot.Transparency = transparency
    data.healthBackground.Transparency = transparency * 0.65
    data.healthBar.Transparency = transparency
    for _, line in ipairs(data.boxLines) do
        line.Transparency = transparency
    end
end
local aiDescendantAddedConnection = Workspace.DescendantAdded:Connect(function(object)
    local model
    if object:IsA("Humanoid") then
        model = object.Parent
    elseif object:IsA("BasePart") and object.Name == "Head" then
        model = object.Parent
    end
    if model and model:IsA("Model") then
        task.defer(function()
            if not DESTROY then
                addAIESP(model)
            end
        end)
    end
end)
for _, object in ipairs(Workspace:GetDescendants()) do
    if object:IsA("Humanoid") then
        addAIESP(object.Parent)
    end
end
local aiRenderConnection
aiRenderConnection = RunService.RenderStepped:Connect(function()
    if DESTROY then
        if aiDescendantAddedConnection and aiDescendantAddedConnection.Connected then
            aiDescendantAddedConnection:Disconnect()
        end
        local modelsToRemove = {}
        for model in pairs(ActiveAIESP) do
            table.insert(modelsToRemove, model)
        end
        for _, model in ipairs(modelsToRemove) do
            removeAIESP(model)
        end
        aiRenderConnection:Disconnect()
        return
    end
    if not RCX.AI_ESP.Toggle then
        for _, data in pairs(ActiveAIESP) do
            hideAIESP(data)
        end
        return
    end
    local camera = getCamera()
    local localCharacter = getCharacter(LocalPlayer)
    local localRoot = getRootPart(localCharacter)
    if not camera or not localRoot then
        for _, data in pairs(ActiveAIESP) do
            hideAIESP(data)
        end
        return
    end
    local aiColor = RGB(
        RCX.AI_ESP.Color.R,
        RCX.AI_ESP.Color.G,
        RCX.AI_ESP.Color.B
    )
    local modelsToRemove = {}
    for model, data in pairs(ActiveAIESP) do
        if not model.Parent or Players:GetPlayerFromCharacter(model) then
            table.insert(modelsToRemove, model)
        else
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local head = model:FindFirstChild("Head")
            local rootPart = getAIRoot(model)
            if not humanoid
                or not head
                or not head:IsA("BasePart")
                or not rootPart
            then
                hideAIESP(data)
            elseif humanoid.Health <= 0 and not RCX.AI_ESP.Show_Bodies then
                hideAIESP(data)
            else
                local isDead = humanoid.Health <= 0
                local currentAIColor = aiColor

                if isDead then
                    local dead = RCX.AI_ESP.Dead_Color
                    currentAIColor = RGB(dead.R, dead.G, dead.B)
                end

                local distance = (rootPart.Position - localRoot.Position).Magnitude
                if distance > RCX.AI_ESP.Max_Distance then
                    hideAIESP(data)
                else
                    local rootScreen, rootOnScreen =
                        camera:WorldToViewportPoint(rootPart.Position)
                    if not isOnViewport(camera, rootScreen, rootOnScreen) then
                        hideAIESP(data)
                    else
                        local minX, minY, maxX, maxY =
                            getModelScreenBounds(model, camera)
                        if not minX then
                            hideAIESP(data)
                        else
                            local fade = 1
                            if RCX.AI_ESP.Fade then
                                fade = clamp(
                                    1 - (
                                        distance
                                        / math.max(RCX.AI_ESP.Max_Distance, 1)
                                    ) * 0.65,
                                    0.35,
                                    1
                                )
                            end
                            setAITransparency(data, fade)
                            data.nameText.Size = RCX.AI_ESP.Text_Size
                            data.statusText.Size =
                                math.max(RCX.AI_ESP.Text_Size - 1, 9)
                            data.nameText.Color = currentAIColor
                            data.statusText.Color = RGB(230, 230, 230)
                            if RCX.AI_ESP.Names then
                                data.nameText.Text = model.Name
                                data.nameText.Position =
                                    V2((minX + maxX) * 0.5, minY - 18)
                                data.nameText.Visible = true
                            else
                                data.nameText.Visible = false
                            end
                            local statusParts = {}
                            if RCX.AI_ESP.Health then
                                table.insert(
                                    statusParts,
                                    tostring(
                                        round(
                                            clamp(
                                                humanoid.Health
                                                    / math.max(
                                                        humanoid.MaxHealth,
                                                        1
                                                    ),
                                                0,
                                                1
                                            ) * 100
                                        )
                                    ) .. "%"
                                )
                            end
                            if RCX.AI_ESP.Distance then
                                table.insert(
                                    statusParts,
                                    tostring(round(distance)) .. " studs"
                                )
                            end
                            if #statusParts > 0 then
                                data.statusText.Text =
                                    "AI  •  "
                                    .. table.concat(statusParts, "  •  ")
                            else
                                data.statusText.Text = "AI"
                            end
                            data.statusText.Position =
                                V2((minX + maxX) * 0.5, maxY + 3)
                            data.statusText.Visible = true
                            local headScreen, headOnScreen =
                                camera:WorldToViewportPoint(head.Position)
                            data.dotOutline.Radius =
                                RCX.AI_ESP.Dot_Size + 2
                            data.dot.Radius = RCX.AI_ESP.Dot_Size
                            data.dotOutline.Position =
                                V2(headScreen.X, headScreen.Y)
                            data.dot.Position =
                                V2(headScreen.X, headScreen.Y)
                            data.dot.Color = currentAIColor
                            local showDot =
                                RCX.AI_ESP.Head_Dot
                                and distance <= RCX.AI_ESP.Max_Distance
                                and isOnViewport(
                                    camera,
                                    headScreen,
                                    headOnScreen
                                )
                            data.dotOutline.Visible = showDot
                            data.dot.Visible = showDot
                            if RCX.AI_ESP.Boxes then
                                updateAICornerBox(
                                    data.boxLines,
                                    minX,
                                    minY,
                                    maxX,
                                    maxY
                                )
                                for _, line in ipairs(data.boxLines) do
                                    line.Color = currentAIColor
                                    line.Visible = true
                                end
                            else
                                for _, line in ipairs(data.boxLines) do
                                    line.Visible = false
                                end
                            end
                            if RCX.AI_ESP.Health_Bar then
                                local healthRatio = clamp(
                                    humanoid.Health
                                        / math.max(humanoid.MaxHealth, 1),
                                    0,
                                    1
                                )
                                local barX = minX - 6
                                local barTop = minY
                                local barBottom = maxY
                                local barHeight = barBottom - barTop
                                data.healthBackground.From =
                                    V2(barX, barTop)
                                data.healthBackground.To =
                                    V2(barX, barBottom)
                                data.healthBar.From =
                                    V2(
                                        barX,
                                        barBottom
                                            - (barHeight * healthRatio)
                                    )
                                data.healthBar.To =
                                    V2(barX, barBottom)
                                if isDead then
                                    local dead = RCX.AI_ESP.Dead_Color
                                    data.healthBar.Color = RGB(dead.R, dead.G, dead.B)
                                else
                                    data.healthBar.Color =
                                        RGB(255, 55, 55):Lerp(
                                            RGB(70, 255, 100),
                                            healthRatio
                                        )
                                end
                                data.healthBackground.Visible = true
                                data.healthBar.Visible = true
                            else
                                data.healthBackground.Visible = false
                                data.healthBar.Visible = false
                            end
                        end
                    end
                end
            end
        end
    end
    for _, model in ipairs(modelsToRemove) do
        removeAIESP(model)
    end
end)
-- Aimbot
local aimbotConnection
aimbotConnection = RunService.RenderStepped:Connect(function()
    if DESTROY then
        Selected_Player = nil
        AimActivation = nil
        Aiming = false
        setTerrainDecoration(OriginalTerrainDecoration)
        restoreRecoil()
        setZoomState(false)

        if RecoilFolderConnection and RecoilFolderConnection.Connected then
            RecoilFolderConnection:Disconnect()
        end
        if ZoomInputBeganConnection and ZoomInputBeganConnection.Connected then
            ZoomInputBeganConnection:Disconnect()
        end
        if ZoomInputEndedConnection and ZoomInputEndedConnection.Connected then
            ZoomInputEndedConnection:Disconnect()
        end
        if ZoomCameraConnection and ZoomCameraConnection.Connected then
            ZoomCameraConnection:Disconnect()
        end

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
        AimActivation = nil
        Aiming = false
        return
    end
    Selected_Player = getClosestTarget()
    if Selected_Player then
        local selectedPlayer =
            Players:GetPlayerFromCharacter(Selected_Player)
        if selectedPlayer and isAimbotIgnored(selectedPlayer) then
            Selected_Player = nil
        end
    end
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
    if type(mousemoverel) == "function" then
        mousemoverel(
            (screenPosition.X - Mouse.X) * sensitivity,
            (screenPosition.Y - Mouse.Y - GuiInset.Y) * sensitivity
        )
    end
end)
