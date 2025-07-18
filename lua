local players = game:GetService("Players")
local collectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local localPlayer = players.LocalPlayer or players:GetPlayers()[1]

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
local FONT = Enum.Font.FredokaOne
local TILE_IMAGE = "rbxassetid://15910695828"

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

-- Removed the realESP table as it's no longer needed for initial display control.
-- If you later want certain eggs to ALWAYS show only their name (never reroll),
-- you'd reintroduce a similar table and logic in addESP and rerollBtn.

local displayedEggs = {}
local autoStopOn = false

local function weightedRandom(options)
    local valid = {}
    for pet, chance in pairs(options) do
        if chance > 0 then table.insert(valid, {pet = pet, chance = chance}) end
    end
    if #valid == 0 then return nil end
    local total = 0
    for _, v in ipairs(valid) do total += v.chance end
    local roll = math.random() * total
    local cumulative = 0
    for _, v in ipairs(valid) do
        cumulative += v.chance
        if roll <= cumulative then return v.pet end
    end
    return valid[1].pet
end

local function getNonRepeatingRandomPet(eggName, lastPet)
    local pool = eggChances[eggName]
    if not pool then return nil end
    local tries, selectedPet = 0, lastPet
    while tries < 5 do
        local pet = weightedRandom(pool)
        if not pet then return nil end
        if pet ~= lastPet or math.random() < 0.3 then
            selectedPet = pet
            break
        end
        tries += 1
    end
    return selectedPet
end

local function createEspGui(object, labelText)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FakePetESP"
    billboard.Adornee = object:FindFirstChildWhichIsA("BasePart") or object.PrimaryPart or object
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true

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

-- Modified addESP function
local function addESP(egg)
    if egg:GetAttribute("OWNER") ~= localPlayer.Name then return end
    local eggName = egg:GetAttribute("EggName")
    local objectId = egg:GetAttribute("OBJECT_UUID")
    if not eggName or not objectId or displayedEggs[objectId] then return end

    -- Initially, the label text is just the egg name
    local labelText = eggName
    -- No initial pet is selected yet, so lastPet is nil for now
    local firstPet = nil 

    local espGui = createEspGui(egg, labelText)
    displayedEggs[objectId] = {
        egg = egg,
        gui = espGui,
        label = espGui:FindFirstChild("TextLabel"),
        eggName = eggName,
        lastPet = firstPet -- lastPet is nil, will be set on first reroll
    }
end

local function removeESP(egg)
    local objectId = egg:GetAttribute("OBJECT_UUID")
    if objectId and displayedEggs[objectId] then
        displayedEggs[objectId].gui:Destroy()
        displayedEggs[objectId] = nil
    end
end

for _, egg in collectionService:GetTagged("PetEggServer") do
    addESP(egg)
end

collectionService:GetInstanceAddedSignal("PetEggServer"):Connect(addESP)
collectionService:GetInstanceRemovedSignal("PetEggServer"):Connect(removeESP)

local gui = Instance.new("ScreenGui")
gui.Name = "RandomizerStyledGUI"
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 120)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -60)
mainFrame.BackgroundColor3 = BROWN_BG
mainFrame.Parent = gui
mainFrame.Active = true
mainFrame.Draggable = true
local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 10)
local frameStroke = Instance.new("UIStroke", mainFrame)
frameStroke.Thickness = 2
frameStroke.Color = BROWN_BORDER

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

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 26)
topBar.BackgroundColor3 = ACCENT_GREEN
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame
local topBarCorner = Instance.new("UICorner", topBar)
topBarCorner.CornerRadius = UDim.new(0, 10)

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

local infoBtn = Instance.new("TextButton")
infoBtn.Size = UDim2.new(0, 18, 0, 18)
infoBtn.Position = UDim2.new(1, -50, 0.5, -9)
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
infoBtn.MouseEnter:Connect(function()
    infoBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
end)
infoBtn.MouseLeave:Connect(function()
    infoBtn.BackgroundColor3 = BUTTON_GRAY
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -25, 0.5, -9)
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
closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 62, 62)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = BUTTON_RED
end)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

local contentFrame = Instance.new("Frame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -8, 1, -38)
contentFrame.Position = UDim2.new(0, 4, 0, 32)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 2
contentFrame.Parent = mainFrame

local function updateStopBtnColors(btn)
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

local function makeStyledButton(text, yPos, color, hover, onHover, onUnhover)
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
        if onHover then onHover(btn) else btn.BackgroundColor3 = hover end
    end)
    btn.MouseLeave:Connect(function()
        if onUnhover then onUnhover(btn) else btn.BackgroundColor3 = color end
    end)
    return btn
end

local stopBtn = makeStyledButton(
    "[A] Auto Stop: ON",
    0,
    BUTTON_GREEN,
    BUTTON_GREEN_HOVER,
    function(btn)
        if autoStopOn then
            btn.BackgroundColor3 = BUTTON_GREEN_HOVER
        else
            btn.BackgroundColor3 = BUTTON_RED_HOVER
        end
    end,
    function(btn)
        if autoStopOn then
            btn.BackgroundColor3 = BUTTON_GREEN
        else
            btn.BackgroundColor3 = BUTTON_RED
        end
    end
)
updateStopBtnColors(stopBtn)

local rerollBtn = makeStyledButton(
    "[B] Reroll Pet Display",
    32,
    BUTTON_BLUE,
    BUTTON_BLUE_HOVER
)

stopBtn.MouseButton1Click:Connect(function()
    autoStopOn = not autoStopOn
    updateStopBtnColors(stopBtn)
end)

-- The Reroll button's logic is now responsible for showing the pet name
rerollBtn.MouseButton1Click:Connect(function()
    for objectId, data in pairs(displayedEggs) do
        -- Only reroll if the eggName exists in eggChances and is not already showing a pet name
        if eggChances[data.eggName] and (not data.lastPet or string.find(data.label.Text, " | ") == nil) then
            local pet = getNonRepeatingRandomPet(data.eggName, data.lastPet)
            if pet and data.label then
                data.label.Text = data.eggName .. " | " .. pet
                data.lastPet = pet
            end
        end
    end
end)

local camera = workspace.CurrentCamera
local originalFOV
local zoomFOV = 60
local tweenTime = 0.4
local currentTween

infoBtn.MouseButton1Click:Connect(function()
    if gui:FindFirstChild("InfoModal") then
        return
    end

    local blur = Instance.new("BlurEffect")
    blur.Size = 16
    blur.Name = "ModalBlur"
    blur.Parent = game:GetService("Lighting")

    if camera then
        originalFOV = camera.FieldOfView
        if currentTween then currentTween:Cancel() end
        currentTween = TweenService:Create(camera, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            FieldOfView = zoomFOV
        })
        currentTween:Play()
    end

    local modal = Instance.new("Frame")
    modal.Name = "InfoModal"
    modal.Size = UDim2.new(0, 180, 0, 70)
    modal.Position = UDim2.new(0.5, -90, 0.5, -35)
    modal.BackgroundColor3 = BROWN_LIGHT
    modal.Active = true
    modal.ZIndex = 30
    modal.Parent = gui
    local modalCorner = Instance.new("UICorner", modal)
    modalCorner.CornerRadius = UDim.new(0, 8)
    local modalStroke = Instance.new("UIStroke", modal)
    modalStroke.Color = BROWN_BORDER
    modalStroke.Thickness = 2

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

    local textTile = Instance.new("Frame")
    textTile.Size = UDim2.new(1, 0, 0, 18)
    textTile.Position = UDim2.new(0, 0, 0, 0)
    textTile.BackgroundColor3 = ACCENT_GREEN
    textTile.ZIndex = 30
    textTile.Parent = modal
    local textTileCorner = Instance.new("UICorner", textTile)
    textTileCorner.CornerRadius = UDim.new(0, 8)

    local textTileLabel = Instance.new("TextLabel")
    textTileLabel.Size = UDim2.new(1, -20, 1, 0)
    textTileLabel.Position = UDim2.new(0, 8, 0, 0)
    textTileLabel.BackgroundTransparency = 1
    textTileLabel.Text = "Info"
    textTileLabel.TextColor3 = Color3.fromRGB(255,255,255)
    textTileLabel.Font = FONT
    textTileLabel.TextScaled = true
    textTileLabel.ZIndex = 31
    textTileLabel.TextStrokeTransparency = 0
    textTileLabel.Parent = textTile

    local closeBtn2 = Instance.new("TextButton")
    closeBtn2.Size = UDim2.new(0, 16, 0, 16)
    closeBtn2.Position = UDim2.new(1, -18, 0, 1)
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
    closeBtn2.MouseEnter:Connect(function()
        closeBtn2.BackgroundColor3 = Color3.fromRGB(200, 62, 62)
    end)
    closeBtn2.MouseLeave:Connect(function()
        closeBtn2.BackgroundColor3 = BUTTON_RED
    end)
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

    local infoBox = Instance.new("Frame")
    infoBox.Size = UDim2.new(1, -10, 1, -21)
    infoBox.Position = UDim2.new(0, 5, 0, 16)
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

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 1, 0)
    infoLabel.Position = UDim2.new(0, 0, 0, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.Text = "Auto Stop when found:\nRaccoon, Dragonfly, Queen Bee, Red Fox, Disco Bee, Butterfly."
    infoLabel.TextWrapped = true
    infoLabel.Font = FONT
    infoLabel.TextScaled = true
    infoLabel.ZIndex = 31
    infoLabel.TextStrokeTransparency = 0.5
    infoLabel.Parent = infoBox
end)
