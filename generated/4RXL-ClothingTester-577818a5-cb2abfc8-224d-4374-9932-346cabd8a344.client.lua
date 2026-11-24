--========================================================
-- 4RXL CLOTHING TESTER
-- LocalScript - Roblox Studio
-- Installation : StarterPlayer > StarterPlayerScripts
-- Fonctionnement : local uniquement, sur le personnage du joueur.
--========================================================

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("4RXLClothingTester")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "4RXLClothingTester"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function corner(object, radius)
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, radius)
    uiCorner.Parent = object
end

local function makeButton(parent, name, text, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.AutoButtonColor = true
    button.Parent = parent
    corner(button, 7)
    return button
end

local function makeBox(parent, name, placeholder, y)
    local box = Instance.new("TextBox")
    box.Name = name
    box.Position = UDim2.fromOffset(14, y)
    box.Size = UDim2.new(1, -28, 0, 38)
    box.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
    box.TextColor3 = Color3.new(1, 1, 1)
    box.PlaceholderColor3 = Color3.fromRGB(155, 155, 155)
    box.PlaceholderText = placeholder
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.Parent = parent
    corner(box, 6)
    return box
end

local openButton = makeButton(
    gui,
    "OpenButton",
    "4RXL OPEN",
    UDim2.new(0, 18, 0.5, -20),
    UDim2.fromOffset(112, 40),
    Color3.fromRGB(45, 45, 45)
)

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(310, 245)
panel.Position = UDim2.new(0.5, -155, 0.5, -122)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
panel.Visible = false
panel.Parent = gui
corner(panel, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 0, 34)
title.Position = UDim2.fromOffset(14, 7)
title.BackgroundTransparency = 1
title.Text = "4RXL CLOTHING TESTER"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local closeButton = makeButton(
    panel,
    "CloseButton",
    "X",
    UDim2.new(1, -43, 0, 8),
    UDim2.fromOffset(32, 28),
    Color3.fromRGB(130, 48, 48)
)

local shirtBox = makeBox(panel, "ShirtID", "Shirt asset ID", 52)
local pantsBox = makeBox(panel, "PantsID", "Pants asset ID", 98)

local applyButton = makeButton(
    panel,
    "ApplyButton",
    "APPLY CLOTHING",
    UDim2.fromOffset(14, 148),
    UDim2.new(1, -28, 0, 38),
    Color3.fromRGB(58, 125, 82)
)

local resetButton = makeButton(
    panel,
    "ResetButton",
    "RESET CLOTHING",
    UDim2.fromOffset(14, 194),
    UDim2.new(1, -28, 0, 34),
    Color3.fromRGB(85, 85, 85)
)

local function cleanAssetId(value)
    local cleaned = value:gsub("%s+", ""):gsub("^rbxassetid://", "")
    if cleaned == "" then
        return nil
    end
    if not cleaned:match("^%d+$") then
        return false
    end
    return cleaned
end

local originalShirtTemplate
local originalPantsTemplate

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function rememberOriginalClothing(character)
    local shirt = character:FindFirstChildOfClass("Shirt")
    local pants = character:FindFirstChildOfClass("Pants")
    originalShirtTemplate = shirt and shirt.ShirtTemplate or nil
    originalPantsTemplate = pants and pants.PantsTemplate or nil
end

local function applyClothing()
    local shirtId = cleanAssetId(shirtBox.Text)
    local pantsId = cleanAssetId(pantsBox.Text)

    if shirtId == false or pantsId == false then
        warn("[4RXL] Les IDs doivent contenir uniquement des chiffres.")
        return
    end

    if not shirtId and not pantsId then
        warn("[4RXL] Entre au moins un Shirt ID ou Pants ID.")
        return
    end

    local character = getCharacter()

    if shirtId then
        local shirt = character:FindFirstChildOfClass("Shirt")
        if not shirt then
            shirt = Instance.new("Shirt")
            shirt.Parent = character
        end
        shirt.ShirtTemplate = "rbxassetid://" .. shirtId
    end

    if pantsId then
        local pants = character:FindFirstChildOfClass("Pants")
        if not pants then
            pants = Instance.new("Pants")
            pants.Parent = character
        end
        pants.PantsTemplate = "rbxassetid://" .. pantsId
    end
end

local function resetClothing()
    local character = getCharacter()

    local shirt = character:FindFirstChildOfClass("Shirt")
    local pants = character:FindFirstChildOfClass("Pants")

    if shirt and originalShirtTemplate then
        shirt.ShirtTemplate = originalShirtTemplate
    elseif shirt then
        shirt:Destroy()
    end

    if pants and originalPantsTemplate then
        pants.PantsTemplate = originalPantsTemplate
    elseif pants then
        pants:Destroy()
    end
end

openButton.Activated:Connect(function()
    panel.Visible = not panel.Visible
    openButton.Text = panel.Visible and "4RXL CLOSE" or "4RXL OPEN"
end)

closeButton.Activated:Connect(function()
    panel.Visible = false
    openButton.Text = "4RXL OPEN"
end)

applyButton.Activated:Connect(applyClothing)
resetButton.Activated:Connect(resetClothing)

player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    rememberOriginalClothing(character)
end)

if player.Character then
    rememberOriginalClothing(player.Character)
end

print("[4RXL] Clothing Tester chargé en LocalScript.")
