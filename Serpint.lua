--[[ 
    Serpit - Aimbot universal y ESP modular para Roblox
    Integración con Rayfield UI, Sense (Sirius) y Aimbot-V3 (Exunys)
--]]

-- Cargar librerías externas
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Sense = loadstring(game:HttpGet("https://sirius.menu/sense"))()
local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V3/main/src/Aimbot.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Estado
local ScriptEnabled = false

-- ===== Configurar ESP Sense =====
local function SetupESP()
    Sense.teamSettings.enemy.enabled = true
    Sense.teamSettings.enemy.box = true
    Sense.teamSettings.enemy.name = true
    Sense.teamSettings.enemy.boxColor = Color3.new(1, 0, 0)
    Sense.Load()
end

local function DisableESP()
    Sense.Unload()
end

-- ===== Wrappers Aimbot =====
local AimbotWrapper = {}

function AimbotWrapper:Init()
    Aimbot.Load()
    -- Config valores por defecto
    Aimbot.Settings.FOVRadius = 100
    Aimbot.Settings.ThirdPerson = false
    Aimbot.Settings.TeamCheck = true
    -- El AimPart debe estar aquí para evitar nil
    Aimbot.Settings.AimPart = "Head"
    Aimbot.Settings.Smoothness = 5
    Aimbot.Settings.Prediction = false
end

function AimbotWrapper:SetEnabled(flag)
    if flag then
        Aimbot.Load()
    else
        Aimbot.Exit()
    end
end

function AimbotWrapper:SetFOV(fov)
    Aimbot.Settings.FOVRadius = fov
end

function AimbotWrapper:SetSmooth(value)
    Aimbot.Settings.Smoothness = value
end

function AimbotWrapper:SetAimPart(part)
    Aimbot.Settings.AimPart = part
end

function AimbotWrapper:TogglePrediction(enabled)
    Aimbot.Settings.Prediction = enabled
end

function AimbotWrapper:Blacklist(name)
    Aimbot.Blacklist(name)
end

return AimbotWrapper

-- Si necesitas funciones adicionales, agregar aquí --

-- ===== Crear ventana Rayfield y UI =====
local Window = Rayfield:CreateWindow({
    Name = "Serpit - Universal Aimbot & ESP",
    LoadingTitle = "Cargando Serpit...",
    LoadingSubtitle = "Espere un momento",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SerpitConfigs",
        FileName = "config"
    }
})

-- Pestañas principales
local CombatTab = Window:CreateTab("Combate")
local VisualsTab = Window:CreateTab("Visuales")

-- Sección Combate
CombatTab:CreateSection("Aimbot")

-- Toggle activar Aimbot
local AimbotToggle = CombatTab:CreateToggle({
    Name = "Activar Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(state)
        ScriptEnabled = state
        AimbotWrapper:SetEnabled(state)
        Rayfield:Notify({
            Title = state and "Aimbot Activado" or "Aimbot Desactivado",
            Content = "Serpit está " .. (state and "funcionando" or "detenido"),
            Duration = 3
        })
    end
})

-- Dropdown para parte objetivo
local AimPartDropdown = CombatTab:CreateDropdown({
    Name = "Parte objetivo",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    Flag = "AimPart",
    Callback = function(option)
        AimbotWrapper:SetAimPart(option[1])
    end
})

-- Keybind para activar aimbot (hold/toggle opcional)
local AimKeybind = CombatTab:CreateKeybind({
    Name = "Tecla Aimbot",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Flag = "AimKeybind",
    Callback = function(key)
        Aimbot.Settings.AimbotKey = key
    end
})

-- Slider FOV
local FOVSlider = CombatTab:CreateSlider({
    Name = "Radio FOV",
    Range = {15, 350},
    Increment = 1,
    Suffix = " px",
    CurrentValue = 100,
    Flag = "FOVSlider",
    Callback = function(val)
        AimbotWrapper:SetFOV(val)
    end
})

-- Slider Suavizado
local SmoothSlider = CombatTab:CreateSlider({
    Name = "Suavizado",
    Range = {1, 30},
    Increment = 1,
    Suffix = " smooth",
    CurrentValue = 5,
    Flag = "SmoothSlider",
    Callback = function(val)
        AimbotWrapper:SetSmooth(val)
    end
})

-- Toggle Predicción
local PredictionToggle = CombatTab:CreateToggle({
    Name = "Predicción ON/OFF",
    CurrentValue = false,
    Flag = "Prediction",
    Callback = function(enabled)
        AimbotWrapper:TogglePrediction(enabled)
    end
})

-- Blacklist Input
local BlacklistInput = CombatTab:CreateInput({
    Name = "Blacklist (Nombre)",
    PlaceholderText = "Ingrese nombre para bloquear...",
    Flag = "BlacklistInput",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        if text and text ~= "" then
            AimbotWrapper:Blacklist(text)
            Rayfield:Notify({
                Title = "Blacklist Modificada",
                Content = text .. " agregado a la blacklist.",
                Duration = 3
            })
        end
    end
})

-- Sección Visuales ESP
VisualsTab:CreateSection("ESP")

-- Toggle ESP
local ESPToggle = VisualsTab:CreateToggle({
    Name = "Activar ESP",
    CurrentValue = true,
    Flag = "ESPON",
    Callback = function(state)
        if state then
            SetupESP()
        else
            DisableESP()
        end
    end
})

-- Selector de color para cajas enemigas
local BoxColorPicker = VisualsTab:CreateColorPicker({
    Name = "Color cajas enemigo",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "BoxColor",
    Callback = function(color)
        Sense.teamSettings.enemy.boxColor = color
        Sense.Load()
    end
})

-- Slider distancia máxima ESP (reconfigurable en Sense.settings)
local MaxDistanceSlider = VisualsTab:CreateSlider({
    Name = "Distancia máxima ESP",
    Range = {50, 1000},
    Increment = 50,
    Suffix = " studs",
    CurrentValue = 500,
    Flag = "MaxESPDist",
    Callback = function(val)
        if Sense.settings then
            Sense.settings.maxDistance = val
        end
    end
})

-- Botón recargar ESP
local ReloadESPButton = VisualsTab:CreateButton({
    Name = "Recargar ESP",
    Callback = function()
        Sense.Unload()
        wait(0.1)
        Sense.Load()
        Rayfield:Notify({
            Title = "ESP Recargado",
            Content = "Sense ESP fue recargado correctamente.",
            Duration = 3
        })
    end
})

-- Inicializar componentes
AimbotWrapper:Init()
SetupESP()

-- Bind para limpiar al cerrar juego
game:BindToClose(function()
    Aimbot.Exit()
    Sense.Unload()
end)

-- Notificación inicio completo
Rayfield:Notify({
    Title = "Serpit cargado",
    Content = "Aimbot & ESP listos para usar.",
    Duration = 4
})

--[[ FIN DEL SCRIPT ]]
