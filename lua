--!strict
-- This script creates a GUI for a pet egg randomizer in Roblox.
-- It displays potential pets from eggs and includes an auto-stop feature.

-- Services
local players = game:GetService("Players")
local collectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local localPlayer = players.LocalPlayer or players:GetPlayers()[1] -- Fallback for Studio testing

-- UI Colors
local BROWN_BG = Color3.fromRGB(118, 61, 25)
local BROWN_LIGHT = Color3.fromRGB(164, 97, 43)
local BROWN_BORDER = Color3.fromRGB(51, 25, 0)
local ACCENT_GREEN = Color3.fromRGB(110, 196, 99)
local BUTTON_YELLOW = Color3.fromRGB(255, 214, 61)
local BUTTON_RED = Color3.fromRGB(255, 62, 62)
local BUTTON_GRAY = Color3.fromRGB(190, 190, 190)
local BUTTON_BLUE = Color3.fromRGB(66, 150, 255)
local BUTTON_BLUE_HOVER = Color3.fromRGB(85, 180, 255)
local BUTTON_GREEN = Color3.fromRGB(85, 200, 85)
local BUTTON_GREEN_HOVER = Color3.fromRGB(120, 230, 120)
local BUTTON_RED_HOVER = Color3.fromRGB(255, 100, 100)

-- UI Font and Image
local FONT = Enum.Font.FredokaOne
local TILE_IMAGE = "rbxassetid://15910695828"

-- Pet Egg Chances (Key: Egg Name, Value: Table of Pet Names and their Chances)
-- Note: Pets with 0% chance will not be selected by the weightedRandom function.
local eggChances = {
    ["Common Egg"] = {["Dog"] = 33, ["Bunny"] = 33, ["Golden Lab"] = 33},
    ["Uncommon Egg"] = {["Black Bunny"] = 25, ["Chicken"] = 25, ["Cat"] = 25, ["Deer"] = 25},
    ["Rare Egg"] = {["Orange Tabby"] = 33.33, ["Spotted Deer"] = 25, ["Pig"] = 16.67, ["Rooster"] = 16.67, ["Monkey"] = 8.33},
    ["Legendary Egg"] = {["Cow"] = 42.55, ["Silver Monkey"] = 42.55, ["Sea Otter"] = 10.64, ["Turtle"] = 2.13, ["Polar Bear"] = 2.13},
    ["Mythic Egg"] = {["Grey Mouse"] = 37.5, ["Brown Mouse"] = 26.79, ["Squirrel"] = 26.79, ["Red Giant Ant"] = 8.93, ["Red Fox"] = 0},
    ["Bug Egg"] = {["Snail"] = 40, ["Giant Ant"] = 35, ["Caterpillar"] = 25, ["Praying Mantis"] = 0, ["Dragon Fly"] = 0},
    ["Night Egg"] = {["Hedgehog"] = 47, ["Mole"] = 23.5, ["Frog"] = 21.16, ["Echo Frog"] = 8.35, ["Night Owl"] = 0, ["Raccoon"] = 0},
    ["Bee Egg"] = {["Bee"] = 65, ["Honey Bee"] = 20, ["Bear Bee"] = 10, ["Petal Bee"] = 5, ["Queen Bee"] = 0},
    ["Anti Bee Egg"] = {["Wasp"] = 55, ["Tarantula Hawk"] = 31, ["Moth"] = 14, ["Butterfly"] = 0, ["Disco Bee"] = 0},
    ["Common Summer Egg"] = {["Starfish"] = 50, ["Seagull"] = 25, ["Crab"] = 25},
    ["Rare Summer Egg"] = {["Flamingo"] = 30, ["Toucan"] = 25, ["Sea Turtle"] = 20, ["Orangutan"] = 15, ["Seal"] = 10},
    ["Paradise Egg"] = {["Ostrich"] = 43, ["Peacock"] = 33, ["Capybara"] = 24, ["Scarlet Macaw"] = 3, ["Mimic Octopus"] = 1},
    ["Premium Night Egg"] = {["Hedgehog"] = 50, ["Mole"] = 26, ["Frog"] = 14, ["Echo Frog"] = 10},
    ["Oasis Egg"] = {["Meerkat"] = 45, ["Sand Snake"] = 34.5, ["Axolotl"] = 15, ["Hyacinth Macaw"] = 5, ["Fennec Fox"] = 0},
    ["Dinosaur Egg"] = {["Raptor"] = 35, ["Triceratops"] = 32.5, ["Stegosaurus"] = 28, ["Pterodactyl"] = 3, ["Brontosaurus"] = 0, ["T-Rex"] = 0},
    ["Primal Egg"] = {["Parasaurolophus"] = 35, ["Iguanodon"] = 32.5, ["Pachycephalosaurus"] = 28, ["Dilophosaurus"] = 3, ["Ankylosaurus"] = 0, ["Spinosaurus"] = 0},
    ["Premium Primal Egg"] = {["Parasaurolophus"] = 35, ["Iguanodon"] = 32.5, ["Pachycephalosaurus"] = 28, ["Dilophosaurus"] = 3, ["Ankylosaurus"] = 0, ["Spinosaurus"] = 0}
}

-- Eggs for which the ESP should display the actual pet (if known by the server)
-- Otherwise, the randomizer will display a simulated pet.
local realESP = {
    ["Common Egg"] = true,
    ["Uncommon Egg"] = true,
    ["Rare Egg"] = true,
    ["Legendary Egg"] = true,
    ["Mythic Egg"] = true,
    ["Bug Egg"] = true,
    ["Night Egg"] = true,
    ["Bee Egg"] = true,
    ["Anti Bee Egg"] = true,
    ["Common Summer Egg"] = true,
    ["Rare Summer Egg"] = true,
    ["Paradise Egg"] = true,
    ["Premium Night Egg"] = true,
    ["Oasis Egg"] = true,
    ["Dinosaur Egg"] = true,
    ["Primal Egg"] = true,
    ["Premium Primal Egg"] = true
}

-- Internal state variables
local displayedEggs = {} -- Stores info about currently displayed egg ESPs
local autoStopOn = false -- State for the auto-stop feature

-- List of pets that trigger auto-stop when found (either real or simulated)
local AUTO_STOP_PETS = {
    "Raccoon", "Dragonfly", "Queen Bee", "Red Fox", "Disco Bee", "Butterfly",
    "Praying Mantis", "Night Owl", "Fennec Fox", "Brontosaurus", "T-Rex",
    "Ankylosaurus", "Spinosaurus"
}

--- Selects a random item from a table based on weighted chances.
-- @param options A table where keys are items and values are their weights/chances.
-- @return The selected item, or nil if no valid options.
local function weightedRandom(options: { [string]: number }): string?
    local valid = {}
    for pet, chance in pairs(options) do
        if chance > 0 then
            table.insert(valid, {pet = pet, chance = chance})
        end
    end

    if #valid == 0 then return nil end

    local total = 0
    for _, v in ipairs(valid) do
        total += v.chance
    end

    local roll = math.random() * total
    local cumulative = 0

    for _, v in ipairs(valid) do
        cumulative += v.chance
        if roll <= cumulative then
            return v.pet
        end
    end

    -- Fallback in case of floating point inaccuracies, though unlikely with proper weights
    return valid[1].pet
end

--- Gets a non-repeating random pet from an egg's pool.
-- It attempts to avoid repeating the last pet, but allows it occasionally.
-- @param eggName The name of the egg.
-- @param lastPet The name of the previously displayed pet for this egg.
-- @return The selected pet name, or nil if the eggName is invalid or no pets can be rolled.
local function getNonRepeatingRandomPet(eggName: string, lastPet: string?): string?
    local pool = eggChances[eggName]
    if not pool then return nil end

    local tries = 0
    local selectedPet: string? = lastPet

    while tries < 5 do -- Try up to 5 times to get a different pet
        local pet = weightedRandom(pool)
        if not pet then return nil end

        -- Allow repeat with 30% chance, or if it's a different pet
        if pet ~= lastPet or math.random() < 0.3 then
            selectedPet = pet
            break
        end
        tries += 1
    end
    return selectedPet
end

--- Creates a BillboardGui for displaying ESP information above an object.
-- @param object The Roblox object to adorn the BillboardGui to.
-- @param labelText The initial text to display on the BillboardGui.
-- @return The created BillboardGui instance.
local function createEspGui(object: Instance, labelText: string): BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FakePetESP"
    -- Adorn to a BasePart or PrimaryPart, fallback to the object itself
    billboard.Adornee = object:FindFirstChildWhichIsA("BasePart") or object.PrimaryPart or object
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.ExtentsOffset = Vector3.new(0, object.Size.Y / 2, 0) -- Adjust offset based on object size

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.Text = labelText
    label.Parent = billboard

    billboard.Parent = object
    return billboard
end

--- Adds ESP (Extra Sensory Perception) display to a pet egg.
-- This function determines whether to show the real egg name or a randomized pet name.
-- It also checks for auto-stop conditions.
-- @param egg The pet egg instance.
local function addESP(egg: Instance)
    -- Only show ESP for eggs owned by the local player
    if egg:GetAttribute("OWNER") ~= localPlayer.Name then return end

    local eggName = egg:GetAttribute("EggName")
    local objectId = egg:GetAttribute("OBJECT_UUID")

    -- Ensure required attributes exist and ESP isn't already displayed for this egg
    if not eggName or not objectId or displayedEggs[objectId] then return end

    local labelText: string
    local firstPet: string? = nil

    if realESP[eggName] then
        -- If real ESP is enabled for this egg type, just display the egg name
        labelText = eggName
    else
        -- Otherwise, simulate a random pet and display it
        firstPet = getNonRepeatingRandomPet(eggName, nil)
        labelText = eggName .. " | " .. (firstPet or "???") -- Use '???' if no pet can be rolled
    end

    local espGui = createEspGui(egg, labelText)
    displayedEggs[objectId] = {
        egg = egg,
        gui = espGui,
        label = espGui:FindFirstChild("TextLabel"),
        eggName = eggName,
        lastPet = firstPet -- Store the first simulated pet for rerolls
    }

    -- Check for auto-stop if the feature is enabled and a target pet is found
    if autoStopOn and firstPet and table.find(AUTO_STOP_PETS, firstPet) then
        -- You might want to add a visual cue or a message box here
        -- For example: print("Auto-stopped! Found: " .. firstPet)
        -- Or trigger an in-game event to stop auto-hatching.
        warn("Auto-stop triggered! Found: " .. firstPet .. " from " .. eggName .. " (Simulated)")
        -- Consider adding logic here to interact with the game's auto-hatch system if it exists.
    end
end

--- Removes the ESP display from a pet egg.
-- @param egg The pet egg instance.
local function removeESP(egg: Instance)
    local objectId = egg:GetAttribute("OBJECT_UUID")
    if objectId and displayedEggs[objectId] then
        displayedEggs[objectId].gui:Destroy()
        displayedEggs[objectId] = nil
    end
end

-- Connect to CollectionService signals for existing and new eggs
for _, egg in collectionService:GetTagged("PetEggServer") do
    task.spawn(addESP, egg) -- Use task.spawn to avoid blocking if many eggs exist
end
collectionService:GetInstanceAddedSignal("PetEggServer"):Connect(addESP)
collectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(removeESP)

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "RandomizerStyledGUI"
gui.ResetOnSpawn = false -- Keep GUI visible across character spawns
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 120)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -60) -- Center the frame
mainFrame.BackgroundColor3 = BROWN_BG
mainFrame.Parent = gui
mainFrame.Active = true
mainFrame.Draggable = true -- Allow dragging the GUI
local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 10)
local frameStroke = Instance.new("UIStroke", mainFrame)
frameStroke.Thickness = 2
frameStroke.Color = BROWN_BORDER

-- Background texture for the main frame
local brownTexture = Instance.new("ImageLabel")
brownTexture.Name = "BrownTexture"
brownTexture.Size = UDim2.new(1, 0, 1, 0)
brownTexture.Position = UDim2.new(0, 0, 0, 0)
brownTexture.BackgroundTransparency = 1
brownTexture.Image = TILE_IMAGE
brownTexture.ImageTransparency = 0
brownTexture.ScaleType = Enum.ScaleType.Tile
brownTexture.TileSize = UDim2.new(0, 96, 0, 96)
brownTexture.ZIndex = 1
brownTexture.Parent = mainFrame

-- Top bar of the GUI
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 26)
topBar.BackgroundColor3 = ACCENT_GREEN
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
local topBarCorner = Instance.new("UICorner", topBar)
topBarCorner.CornerRadius = UDim.new(0, 10) -- Rounded corners for top bar

-- Background texture for the top bar
local greenTexture = Instance.new("ImageLabel")
greenTexture.Name = "GreenTexture"
greenTexture.Size = UDim2.new(1, 0, 1, 0)
greenTexture.Position = UDim2.new(0, 0, 0, 0)
greenTexture.BackgroundTransparency = 1
greenTexture.Image = TILE_IMAGE
greenTexture.ImageTransparency = 0
greenTexture.ScaleType = Enum.ScaleType.Tile
greenTexture.TileSize = UDim2.new(0, 96, 0, 96)
greenTexture.ZIndex = 1
greenTexture.Parent = topBar

-- Title label for the GUI
local topLabel = Instance.new("TextLabel")
topLabel.Size = UDim2.new(1, -62, 1, 0)
topLabel.Position = UDim2.new(0, 8, 0, 0)
topLabel.BackgroundTransparency = 1
topLabel.Text = "🐣 Randomizer"
topLabel.Font = FONT
topLabel.TextColor3 = Color3.new(1, 1, 1)
topLabel.TextStrokeTransparency = 0
topLabel.TextStrokeColor3 = Color3.fromRGB(45, 66, 0)
topLabel.TextScaled = true
topLabel.TextXAlignment = Enum.TextXAlignment.Left
topLabel.ZIndex = 1
topLabel.Parent = topBar

-- Info Button
local infoBtn = Instance.new("TextButton")
infoBtn.Size = UDim2.new(0, 18, 0, 18)
infoBtn.Position = UDim2.new(1, -50, 0.5, -9) -- Position relative to topBar
infoBtn.BackgroundColor3 = BUTTON_GRAY
infoBtn.Text = "?"
infoBtn.Font = FONT
infoBtn.TextColor3 = Color3.fromRGB(65, 65, 65)
infoBtn.TextScaled = true
infoBtn.TextStrokeTransparency = 0.1
infoBtn.Parent = topBar
infoBtn.ZIndex = 2
local infoStroke = Instance.new("UIStroke", infoBtn)
infoStroke.Color = Color3.fromRGB(120,120,120)
infoStroke.Thickness = 1
-- Hover effects for info button
infoBtn.MouseEnter:Connect(function()
    infoBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
end)
infoBtn.MouseLeave:Connect(function()
    infoBtn.BackgroundColor3 = BUTTON_GRAY
end)

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -25, 0.5, -9) -- Position relative to topBar
closeBtn.BackgroundColor3 = BUTTON_RED
closeBtn.Text = "X"
closeBtn.Font = FONT
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.TextStrokeTransparency = 0.3
closeBtn.Parent = topBar
closeBtn.ZIndex = 2
local closeStroke = Instance.new("UIStroke", closeBtn)
closeStroke.Color = Color3.fromRGB(107, 0, 0)
closeStroke.Thickness = 1
-- Hover effects for close button
closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 62, 62)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = BUTTON_RED
end)
-- Connect close button to destroy the GUI
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Content frame for buttons
local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -8, 1, -38) -- Adjusted size to fit within mainFrame
contentFrame.Position = UDim2.new(0, 4, 0, 32)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 2
contentFrame.Parent = mainFrame

--- Updates the visual state (color and text) of the auto-stop button.
-- @param btn The TextButton instance to update.
local function updateStopBtnColors(btn: TextButton)
    if autoStopOn then
        btn.BackgroundColor3 = BUTTON_GREEN
        btn.Text = "[A] Auto Stop: ON"
        btn.TextColor3 = Color3.new(1,1,1)
    else
        btn.BackgroundColor3 = BUTTON_RED
        btn.Text = "[A] Auto Stop: OFF"
        btn.TextColor3 = Color3.new(1,1,1)
    end
end

--- Creates a styled TextButton with common properties.
-- @param text The text to display on the button.
-- @param yPos The Y position offset within the parent frame.
-- @param color The default background color of the button.
-- @param hoverColor The background color when the mouse hovers over the button.
-- @param onHover Optional function to call on mouse enter, receives the button.
-- @param onUnhover Optional function to call on mouse leave, receives the button.
-- @return The created TextButton instance.
local function makeStyledButton(
    text: string,
    yPos: number,
    color: Color3,
    hoverColor: Color3,
    onHover: ((btn: TextButton) -> ())? = nil,
    onUnhover: ((btn: TextButton) -> ())? = nil
): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 26)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = FONT
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextScaled = true
    btn.TextStrokeTransparency = 0.25
    btn.ZIndex = 2
    btn.Parent = contentFrame
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 7)
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = BROWN_BORDER
    btnStroke.Thickness = 1

    btn.MouseEnter:Connect(function()
        if onHover then
            onHover(btn)
        else
            btn.BackgroundColor3 = hoverColor
        end
    end)
    btn.MouseLeave:Connect(function()
        if onUnhover then
            onUnhover(btn)
        else
            btn.BackgroundColor3 = color
        end
    end)
    return btn
end

-- Auto Stop Button
local stopBtn = makeStyledButton(
    "[A] Auto Stop: ON", -- Initial text, will be updated by updateStopBtnColors
    0, -- Y position
    BUTTON_GREEN, -- Default color
    BUTTON_GREEN_HOVER, -- Hover color (will be overridden by custom handler)
    function(btn) -- Custom onHover
        if autoStopOn then
            btn.BackgroundColor3 = BUTTON_GREEN_HOVER
        else
            btn.BackgroundColor3 = BUTTON_RED_HOVER
        end
    end,
    function(btn) -- Custom onUnhover
        if autoStopOn then
            btn.BackgroundColor3 = BUTTON_GREEN
        else
            btn.BackgroundColor3 = BUTTON_RED
        end
    end
)
updateStopBtnColors(stopBtn) -- Set initial colors and text

-- Reroll Pet Display Button
local rerollBtn = makeStyledButton(
    "[B] Reroll Pet Display",
    32, -- Y position
    BUTTON_BLUE,
    BUTTON_BLUE_HOVER
)

-- Connect functionality to buttons
stopBtn.MouseButton1Click:Connect(function()
    autoStopOn = not autoStopOn
    updateStopBtnColors(stopBtn)
end)

rerollBtn.MouseButton1Click:Connect(function()
    for objectId, data in pairs(displayedEggs) do
        -- Reroll only for eggs that are not "real ESP"
        if not realESP[data.eggName] then
            local pet = getNonRepeatingRandomPet(data.eggName, data.lastPet)
            if pet and data.label then
                data.label.Text = data.eggName .. " | " .. pet
                data.lastPet = pet -- Update last rolled pet for next reroll
            end
        end
    end
end)

-- Camera and Tweening for Info Modal
local camera = workspace.CurrentCamera
local originalFOV: number
local zoomFOV = 60
local tweenTime = 0.4
local currentTween: Tween?

-- Info Button Click Handler
infoBtn.MouseButton1Click:Connect(function()
    -- Prevent opening multiple info modals
    if gui:FindFirstChild("InfoModal") then
        return
    end

    -- Apply blur effect to the background
    local blur = Instance.new("BlurEffect")
    blur.Size = 16
    blur.Name = "ModalBlur"
    blur.Parent = game:GetService("Lighting")

    -- Tween camera FOV
    if camera then
        originalFOV = camera.FieldOfView
        if currentTween then currentTween:Cancel() end
        currentTween = TweenService:Create(camera, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            FieldOfView = zoomFOV
        })
        currentTween:Play()
    end

    -- Create modal frame
    local modal = Instance.new("Frame")
    modal.Name = "InfoModal"
    modal.Size = UDim2.new(0, 220, 0, 130) -- Adjusted size for more text
    modal.Position = UDim2.new(0.5, -110, 0.5, -65) -- Center the modal
    modal.BackgroundColor3 = BROWN_LIGHT
    modal.Active = true
    modal.ZIndex = 30 -- Ensure it's on top
    modal.Parent = gui
    local modalCorner = Instance.new("UICorner", modal)
    modalCorner.CornerRadius = UDim.new(0, 8)
    local modalStroke = Instance.new("UIStroke", modal)
    modalStroke.Color = BROWN_BORDER
    modalStroke.Thickness = 2

    -- Background texture for modal
    local modalTexture = Instance.new("ImageLabel")
    modalTexture.Name = "ModalBrownTexture"
    modalTexture.Size = UDim2.new(1, 0, 1, 0)
    modalTexture.Position = UDim2.new(0, 0, 0, 0)
    modalTexture.BackgroundTransparency = 1
    modalTexture.Image = TILE_IMAGE
    modalTexture.ImageTransparency = 0
    modalTexture.ScaleType = Enum.ScaleType.Tile
    modalTexture.TileSize = UDim2.new(0, 96, 0, 96)
    modalTexture.ZIndex = 30
    modalTexture.Parent = modal

    -- Top bar for modal
    local textTile = Instance.new("Frame")
    textTile.Size = UDim2.new(1, 0, 0, 22) -- Slightly taller for modal title
    textTile.Position = UDim2.new(0, 0, 0, 0)
    textTile.BackgroundColor3 = ACCENT_GREEN
    textTile.ZIndex = 30
    textTile.Parent = modal
    local textTileCorner = Instance.new("UICorner", textTile)
    textTileCorner.CornerRadius = UDim.new(0, 8)

    -- Modal title label
    local textTileLabel = Instance.new("TextLabel")
    textTileLabel.Size = UDim2.new(1, -20, 1, 0)
    textTileLabel.Position = UDim2.new(0, 8, 0, 0)
    textTileLabel.BackgroundTransparency = 1
    textTileLabel.Text = "Randomizer Info" -- More descriptive title
    textTileLabel.TextColor3 = Color3.fromRGB(255,255,255)
    textTileLabel.Font = FONT
    textTileLabel.TextScaled = true
    textTileLabel.ZIndex = 31
    textTileLabel.TextStrokeTransparency = 0
    textTileLabel.Parent = textTile

    -- Close button for modal
    local closeBtn2 = Instance.new("TextButton")
    closeBtn2.Size = UDim2.new(0, 18, 0, 18) -- Slightly larger for easier tapping
    closeBtn2.Position = UDim2.new(1, -20, 0, 2) -- Adjusted position
    closeBtn2.BackgroundColor3 = BUTTON_RED
    closeBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn2.Text = "✖"
    closeBtn2.TextScaled = true
    closeBtn2.Font = FONT
    closeBtn2.ZIndex = 32
    closeBtn2.Parent = textTile
    local closeStroke2 = Instance.new("UIStroke", closeBtn2)
    closeStroke2.Color = Color3.fromRGB(107, 0, 0)
    closeStroke2.Thickness = 2
    -- Hover effects for modal close button
    closeBtn2.MouseEnter:Connect(function()
        closeBtn2.BackgroundColor3 = Color3.fromRGB(200, 62, 62)
    end)
    closeBtn2.MouseLeave:Connect(function()
        closeBtn2.BackgroundColor3 = BUTTON_RED
    end)
    -- Connect modal close button to destroy modal and revert camera
    closeBtn2.MouseButton1Click:Connect(function()
        if blur then blur:Destroy() end
        if modal then modal:Destroy() end
        if camera and originalFOV then
            if currentTween then currentTween:Cancel() end
            currentTween = TweenService:Create(camera, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                FieldOfView = originalFOV
            })
            currentTween:Play()
        end
    end)

    -- Info content box
    local infoBox = Instance.new("Frame")
    infoBox.Size = UDim2.new(1, -10, 1, -28) -- Adjusted size to fit more text
    infoBox.Position = UDim2.new(0, 5, 0, 24) -- Adjusted position
    infoBox.BackgroundColor3 = Color3.fromRGB(196, 164, 132)
    infoBox.BackgroundTransparency = 0
    infoBox.ZIndex = 30
    infoBox.Parent = modal

    local infoBoxCorner = Instance.new("UICorner", infoBox)
    infoBoxCorner.CornerRadius = UDim.new(0, 7)

    local infoBoxGradient = Instance.new("UIGradient", infoBox)
    infoBoxGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(164, 97, 43)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(85, 43, 18))
    }

    -- Info text label
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -10, 1, -10) -- Added padding for text
    infoLabel.Position = UDim2.new(0, 5, 0, 5)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.Text = "This randomizer helps predict pets from eggs.\n\n" ..
                     "• [A] Auto Stop: When ON, the randomizer will warn you if it displays a target pet.\n" ..
                     "• [B] Reroll: Changes the displayed pet for eggs that don't have 'real' ESP.\n\n" ..
                     "Auto-stop pets: " .. table.concat(AUTO_STOP_PETS, ", ") .. "." -- Dynamically list auto-stop pets
    infoLabel.TextWrapped = true
    infoLabel.Font = FONT
    infoLabel.TextScaled = true
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center -- Center align for better readability
    infoLabel.TextYAlignment = Enum.TextYAlignment.Top -- Align text to the top
    infoLabel.ZIndex = 31
    infoLabel.TextStrokeTransparency = 0.5
    infoLabel.Parent = infoBox
end)
