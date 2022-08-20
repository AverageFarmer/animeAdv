if _G.Loaded then return end
_G.Loaded =  true

pcall(function()
    getgenv().hookfunction = gdfg
end) 

repeat
    task.wait()
until game.Players.LocalPlayer

--\\ Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

repeat
    task.wait(1)
until game.Players.LocalPlayer:FindFirstChild("_stats")
--// Modules
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/AverageFarmer/Silent/master/Library2.lua"))()
local SolarisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/AverageFarmer/Silent/master/library.lua"))()
local Emojis = loadstring(game:HttpGet("https://raw.githubusercontent.com/AverageFarmer/Silent/master/Emojis.lua"))()

local src = ReplicatedStorage:WaitForChild("src")
local Data = src:WaitForChild("Data")
local Loader = require(src:WaitForChild("Loader"));
local EndpointsClient = Loader.load_client_service(script, "EndpointsClient");
local GUIService = Loader.load_client_service(script, "GUIService");
local UnitsInfo = require(Data.Units)
local Items = require(Data:WaitForChild("ItemsForSale"))

--//Remotes
local ClientToServer = ReplicatedStorage:WaitForChild("endpoints"):WaitForChild("client_to_server")

--// Const
local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = Player:GetMouse()
local PlayerGui = Player:WaitForChild("PlayerGui")
local Units = game:GetService("Workspace")["_UNITS"]

local EvoItems = {
    "aot_blade",
    "black_king",
    "shining_extract",
    "broly_necklace",
    "cupcake",
    "straw_hat",
    "gura_fruit",
    "magu_fruit",
    "rinnegan_eye",
    "eto_shards",
    "forbidden_candy",
    "tatara_scales",
    "weapon_briefcase",
    "starrk_helmet",
    "uryu_star",
    "ulquiorra_spear",
    "kisuke_stitches",
    "aizen_cube",
}
local OtherItems = {
    "summon_ticket",
    "StarFruit",
    "StarFruitEpic",
    "LuckPotion",
    "star_remnant",
}

local FileNameOld = "AAFarm "..tostring(Player.UserId)
local FileName = "AAFarm2 "..tostring(Player.UserId)

if (isfile(FileNameOld .. ".lua")) then
    delfile(FileNameOld .. ".lua")
end

-- AutoLaunch
syn.queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/AverageFarmer/animeAdv/main/Autofarm2.lua"))

--// Vars
local Lobby = "_lobbytemplategreen1"
local ctrl = false
local SavedSettings = (isfile(FileName .. ".lua") and readfile(FileName .. ".lua")) or {}
local PlayerHolder = {}
local Settings = {
    Map = "namek",
    MapNumber = "1",
    Difficulty = "Normal",
    IsInf = true,
    WaitForBoss = false,
    Pause = true,
    
    AutoBuy = {
        Enabled =  true,
        OtherItems = {"summon_ticket"},
        EvoItems = {},
        Duplicates = false -- Only applies to EvoItems
    },
    
    Maps = {
        namek = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
            SellAt = 23,
        },

        aot = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
            SellAt = 23,
        },

        marineford = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
            SellAt = 23,
        },

        tokyoghoul = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
            SellAt = 23,
        },

        hueco = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
            SellAt = 23,
        },
    },

    AntiAFK = false,

    AutoDelete = {
        Enabled = false, 
        Rarities = {"Rare"}, 
        KeepTraits = true,
        KeepShiny = true
    },

    AutoSummon = {
        Enabled = false, 
        x10 = false,
    },

    PlayerOptions = {
        ["Show Gems"] = false
    },

    Webhooks = "",
    WebhookOptions = {
        TotalGems = true,
        TimeCompletedAt = true,
        Map = true,
        Gamemode = false,
        BossesKilled = false
    },
}

local DefaultWebhookOptions = {
    TotalGems = true,
    TimeCompletedAt = true,
    Map = true,
    Gamemode = false,
    BossesKilled = false
}

--// Setup
local currentSettings = HttpService:JSONDecode(SavedSettings)

for i,v in pairs(currentSettings) do
    if i == "Maps" then
        for mapName, info in pairs(Settings.Maps) do
            if not v[mapName] then
                currentSettings["Maps"][mapName] = info
            end
        end
    end
    Settings[i] = v
end

Settings.AutoDelete.Enabled = false
Settings.AutoBuy.Enabled = true


if Settings.AntiAFKv2 then
    Settings.AntiAFKv2 = nil
end
if Settings.Maps["bleach"] then
    Settings.Maps["bleach"] = nil
end

-- Anti Afkv2
Player.Idled:Connect(function(time)
    if Settings.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        task.wait(.1)
        VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    end
end)

--//
--// Global Functions

function Save()
    writefile(FileName.. ".lua", HttpService:JSONEncode(Settings))
end

function MakeList(num)
    local list = {}
    for i = 1, num do
        table.insert(list, i)
    end
    return list
end

function GetUnitInfo(UnitName)
    if not UnitName or UnitName == "None" then return end
    for i, Info in pairs(UnitsInfo) do
        if i == UnitName then
            return Info
        end
    end

    return 
end

function GetMythics()
    local Mythics = {}
    for i, Info in pairs(UnitsInfo) do
        if Info.rarity and Info.rarity == "Mythic" and not string.match(i,"_evolved") then
            if Info.hide_from_banner then continue end
            table.insert(Mythics, i)
        end
    end

    return Mythics
end

function ShopItems(Type)
    local items = {}
    local EItems = {}
    local OItems = {}

    for i,v in pairs(Items) do
        table.insert(items, i)

        if table.find(OtherItems, i) then
            table.insert(OItems, i)
        elseif table.find(EvoItems, i) then
            table.insert(EItems, i) 
        end
    end

    if Type == "Evolution" then
        return EItems
    else
        return OItems
    end
end

function DisplayGems(Character)
    task.spawn(function()
        local Plr = game.Players:GetPlayerFromCharacter(Character)
        local Stats = Plr:WaitForChild("_stats")
        if not Stats then return end
        local gems = Stats.gem_amount.Value

        local Head = Character:WaitForChild("Head")
        local Bilboard = Head:WaitForChild("_overhead").Frame
        local Frame = game:GetObjects("rbxassetid://10600690885")[1]
        
        Frame.Parent = Bilboard
        Frame.Name_Text.Text = string.format("Gems %s", gems)

        PlayerHolder[Plr.UserId] = Frame
    end)
end

if game.PlaceId == 8304191830 then
    --// Lobby

    task.spawn(function()
        local CurrentTime = os.time()

        repeat
            if Settings.Pause then
                CurrentTime = os.time()
            end
            task.wait(1)
        until os.time() - CurrentTime >= 60 * 2

        TeleportService:Teleport(8304191830)
    end)
    --// Local Const
    local Lobbies = game:GetService("Workspace")["_LOBBIES"].Story

    local Maps = {
        "namek",
        "aot",
        --"demonslayer",
        --"naruto",
        "marineford",
        "tokyoghoul",
        "hueco"
    }

    local Numbers = {
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
    }

    local Difficulties = {
        "Normal",
        "Hard"
    }

    local Rarities = {
        "Rare",
        "Epic",
        "Legendary"
    }

    --// functions

    function DeleteRarityCheck(rarity)
        for _, v in pairs(Settings.AutoDelete.Rarities) do
            if rarity == v then
                return true
            end
        end
        return false
    end


    function AutoDelete()
        if Settings.AutoDelete.Enabled then
            local UnitsToDelete = {}
            local allUnits = EndpointsClient.session.collection.collection_profile_data.owned_units
            --equipped_slot
            for _, v in pairs(allUnits) do
                local Info = GetUnitInfo(v.unit_id)
                if v.xp ~= 0 then continue end
                if Info.limited or Info.hide_from_banner then continue end
                if Settings.AutoDelete.KeepTraits and #v.traits > 0 then continue end
                if DeleteRarityCheck(Info.rarity) and not v.equipped_slot then
                    if not Settings.AutoDelete.KeepShiny then
                        table.insert(UnitsToDelete, v.uuid)
                    else
                        if not v.shiny then
                            table.insert(UnitsToDelete, v.uuid)
                        end
                    end
                end
            end
            
            ClientToServer.sell_units:InvokeServer(UnitsToDelete)
        end
    end

    function GetShopItems()
        local Items = {}
        local itemShop = PlayerGui:WaitForChild("ItemShop")
        task.wait(1)
        local ItemHolder = itemShop.Window.Outer.ItemFrames:GetChildren()

        for i,v in pairs(ItemHolder) do
            if v:IsA("ImageButton") then
                table.insert(Items, v.Name)
            end
        end

        return Items
    end

    --// UI
    local Window = Library.CreateWindow("DizHub beta1.2c", 6510338924)

    local AutoFarmTab = Window:Tab("AutoFarm", 6087485864)
    local UnitTab = Window:Tab("Units")
    local SummonTab = Window:Tab("Summoning")
    local MiscTab = Window:Tab("Misc")
    local WebhookTab = Window:Tab("Webhooks")

    local MapSettings = AutoFarmTab:Section("Map Settings")
    local TeleportSettings = AutoFarmTab:Section("Teleport Settings")

    local AutoSummonSection = SummonTab:Section("AutoSummon")
    local AutoDeleteSection = SummonTab:Section("AutoDelete")
    local AutoBuySection = SummonTab:Section("AutoBuy")

    local AFKSection = MiscTab:Section("AFK")
    local PlayerSection = MiscTab:Section("Players")

    local WebHookSection = WebhookTab:Section("Webhook Settings")

    local Map = MapSettings:DropDown("Map", Settings.Map, Maps, function(val)
        Settings.Map = val
        Save()
    end)

    local MapNumber = MapSettings:DropDown("MapNumber", Settings.MapNumber, Numbers, function(val)
        Settings.MapNumber = val
        Save()
    end)

    local Difficulty = MapSettings:DropDown("Difficulty", Settings.Difficulty, Difficulties, function(val)
        Settings.Difficulties = val
        Save()
    end)

    local InfMode = MapSettings:Toggle("Infinite", Settings.IsInf, function(val)
        Settings.IsInf = val
        Save()
    end)

    local Pause = TeleportSettings:Toggle("Pause", Settings.Pause, function(val)
        Settings.Pause = val
        Save()
    end)

    AutoSummonSection:Toggle("Enabled", Settings.AutoSummon.Enabled, function(val)
        Settings.AutoSummon.Enabled = val
        Save()
    end)

    AutoSummonSection:Toggle("UseTickets", Settings.AutoSummon.UseTickets or false, function(val)
        Settings.AutoSummon.UseTickets = val
        Save()
    end)

    AutoSummonSection:Toggle("x10", Settings.AutoSummon.x10, function(val)
        Settings.AutoSummon.x10 = val
        Save()
    end)

    local URMOM 
    URMOM = AutoDeleteSection:Toggle("Enabled", Settings.AutoDelete.Enabled, function(val)
        Settings.AutoDelete.Enabled = val
        Save()
    end)

    AutoDeleteSection:Toggle("Keep Traits", Settings.AutoDelete.KeepTraits, function(val)
        Settings.AutoDelete.KeepTraits = val
        Save()
    end)

    AutoDeleteSection:MultiDropDown("Rarities", Settings.AutoDelete.Rarities, Rarities, function(val)
        Settings.AutoDelete.Rarities = val
        URMOM:Set(false)
        Settings.AutoDelete.Enabled = false
        Save()
    end)

    AutoDeleteSection:Button("Detele all units (Click it if u dare)", function()
        SolarisLib:Notification("Units", "All your units have been deleted.", 5)
        ClientToServer.unequip_all:InvokeServer()
        local text = PlayerGui.collection.grid.List.Top.Capacity.Text
        local split = string.split(text, "/")


        PlayerGui.collection.grid.List.Top.Capacity.Text = string.format("%s/%s", 0, split[2])
        for i,v in pairs(PlayerGui.collection.grid.List.Outer.UnitFrames:GetChildren()) do
            if v:IsA("ImageButton") then
                v:Destroy()
            end
        end
    end)

    AutoBuySection:Toggle("Enable", Settings.AutoBuy.Enabled, function(val)
        Settings.AutoBuy.Enabled = val
        Save()
    end)
    
    AutoBuySection:MultiDropDown("Evolution Items", Settings.AutoBuy.EvoItems or {}, ShopItems("Evolution"), function(NewDiff)
        Settings.AutoBuy.EvoItems = NewDiff
        Save()
    end)
    
    AutoBuySection:MultiDropDown("Other Items", Settings.AutoBuy.OtherItems or {"summon_ticket"}, ShopItems("Other"), function(NewDiff)
        Settings.AutoBuy.OtherItems = NewDiff
        Save()
    end)
    
    AFKSection:Toggle("Anti-AFK", Settings.AntiAFK, function(val)
        Settings.AntiAFK = val
        Save()
    end)

    PlayerSection:Toggle("Show Gems", Settings.PlayerOptions["Show Gems"], function(val)
        Settings.PlayerOptions["Show Gems"] = val
        Save()

        if not val then
            for i,v in pairs(PlayerHolder) do
                if game.Players:GetPlayerByUserId(i) then
                    v:Destroy()
                    PlayerHolder[i] = nil
                end
            end
        else
            for i,v in pairs(game.Players:GetPlayers()) do
                if workspace:FindFirstChild(v.Name) then
                    DisplayGems(v.Character)
                end
            end
        end
    end)

    WebhookLabel = WebHookSection:Label(Settings.Webhooks)
    WebHookSection:TextBox("Your Webhook", Settings.Webhooks, function(val)
        Settings.Webhooks = val
        WebhookLabel:Set(val)
        Save()
    end)

    for index,Value in pairs(DefaultWebhookOptions) do
        if not Settings.WebhookOptions[index] then
            Settings.WebhookOptions[index] = Value
        end
        local Setting = Settings.WebhookOptions
        WebHookSection:Toggle(index, Setting[index], function(val)
            Settings.WebhookOptions[index] = val
            Save()
        end) 
    end

    for i,v in pairs(game.Players:GetPlayers()) do
        if Settings.PlayerOptions["Show Gems"] then
            task.spawn(function()
                local Character = v.Character or v.CharacterAdded:Wait() 
                DisplayGems(Character)
            end)
        end
    end
    
    PlayerGui:WaitForChild("LeftUI_test").Buttons.Play.Visible = true
    local ButtonFolder = game:GetObjects("rbxassetid://10504063278")[1]
    
    for i,v in pairs(ButtonFolder:GetChildren()) do
        v.Parent = PlayerGui:WaitForChild("LeftUI_test").Buttons
        
        v.MouseButton1Click:Connect(function()
            if v.Name == "Evolve" then
                GUIService.evolve_ui:toggle()
            else
                GUIService.trait_reroll_ui:toggle();
            end
        end)
    end
    
    local MaxSlots = 7
    local Pets = {}

    repeat
        task.wait()
    until EndpointsClient.session

    task.wait(2)

    function SetupUnits()
        Pets = {}
        local equipped = EndpointsClient.session.collection.collection_profile_data.equipped_units
        local AllUnits = EndpointsClient.session.collection.collection_profile_data.owned_units

        for Index, uuid in pairs(equipped) do
            if AllUnits[uuid] then
                local info = AllUnits[uuid]
                
                Pets[Index] = string.format("%s:%s", info.unit_id, uuid)
            end
        end
        table.insert(Pets, "None")
    end

    SetupUnits()
    
    for Index, Map in pairs(Maps) do
        Map = Map:lower()
        local MapInfo = Settings["Maps"][Map]
        local MapSlot = UnitTab:Section(Map)

        local MapDropHolder = {}
        local UpgradeDropHolder = {}
        local PlacementDropHolder = {}

        if not MapInfo["SellAt"] then
            MapInfo["SellAt"] = 23
        else
            if typeof(MapInfo["SellAt"]) == "table" then
                MapInfo["SellAt"] = 23
            end
        end

        MapSlot:Button("Refresh Units", function()
            SetupUnits()
            for i,v in pairs(MapDropHolder) do
                print(i)
                local CurrentUnit = MapInfo.Units[i] or "None"
                v:Set(CurrentUnit)
                v:Refresh(Pets)
            end
        end)

        local SellAt
        SellAt = MapSlot:TextBox("Sell At Wave:", MapInfo["SellAt"], function(val)
            val = tonumber(val) or 1
            SellAt:Set(val)
            MapInfo["SellAt"] = val
            Save()
        end)

        for SlotNumber = 1, MaxSlots do
            local CurrentUnit = MapInfo.Units[SlotNumber] or "None"
            local UnitName = (CurrentUnit ~= "None" and  string.split(MapInfo.Units[SlotNumber], ":")[1]) or nil
            local UnitData = GetUnitInfo(UnitName)
            local Spawn_Cap = (UnitData and UnitData.spawn_cap or 1)
            local UpgradeNum = (UnitData and #UnitData.upgrade) or 3

            MapSlot:Label("Unit#" .. SlotNumber)
            MapDropHolder[SlotNumber] = MapSlot:DropDown("", CurrentUnit, Pets, function(val)
                MapInfo.Units[SlotNumber] = val 

                CurrentUnit = val
                UnitName = (CurrentUnit ~= "None" and  string.split(val, ":")[1]) or nil
                UnitData = GetUnitInfo(UnitName)
                Spawn_Cap = (CurrentUnit ~= "None" and UnitData.spawn_cap or 3)

                if UpgradeDropHolder[SlotNumber] then
                    UpgradeNum = (UnitData and #UnitData.upgrade) or 3
                    UpgradeDropHolder[SlotNumber]:Set(UpgradeNum)
                    UpgradeDropHolder[SlotNumber]:Refresh(MakeList(UpgradeNum))

                    PlacementDropHolder[SlotNumber]:Set(Spawn_Cap)
                    PlacementDropHolder[SlotNumber]:Refresh(MakeList(Spawn_Cap))
                end

                Save()
            end)
            
            UpgradeDropHolder[SlotNumber] = MapSlot:DropDown("UpgradeCap", MapInfo.Upgrades[SlotNumber] or 3, (UnitData and MakeList(#UnitData.upgrade)) or {}, function(val)
                MapInfo.Upgrades[SlotNumber] = val
                Save()
            end)
            
            PlacementDropHolder[SlotNumber] = MapSlot:DropDown("SpawnCap", MapInfo.SpawnCaps[SlotNumber] or 1, (CurrentUnit ~= "None" and MakeList(Spawn_Cap)) or {}, function(val)
                MapInfo.SpawnCaps[SlotNumber] = val
                Save()
            end)
        end
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and ctrl then
            local Character = Player.Character
            local Humanoid = Character.Humanoid
            
            Character:SetPrimaryPartCFrame(CFrame.new(Mouse.Hit.Position) * CFrame.new(0, 3, 0))
        end
        
        if input.KeyCode == Enum.KeyCode.LeftControl then
            ctrl = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if input.KeyCode == Enum.KeyCode.LeftControl then
            ctrl = false
        end
    end)

    function FindOpenLobby()
        for i,v in pairs(Lobbies:GetChildren()) do
            if not v.Owner.Value and not v.Active.Value and not v.Locked.Value then
                return v.Name
            end
        end
    end

    function join() -- join teleporter
        local args = {
            [1] = Lobby
        }
        
        local InLobby

        repeat
            InLobby = ClientToServer.request_join_lobby:InvokeServer(unpack(args))
            task.wait(2)
        until InLobby
    end
        
    function Create() -- Creates the map
        local map = (Settings.IsInf and string.format("%s_infinite", Settings.Map)) or string.format("%s_level_%s", Settings.Map, tostring(Settings.MapNumber))
        local args = {
            [1] = Lobby,
            [2] = map, 
            [3] = true,
            [4] = (Settings.IsInf and "Hard") or Settings.Difficulty
        }
        
        ClientToServer.request_lock_level:InvokeServer(unpack(args))
    end
        
    function start2() -- Starts the teleport
        local args = {
            [1] = Lobby
        }
        
        ClientToServer.request_start_game:InvokeServer(unpack(args))
    end

    function LastCheck()
        for i,v in pairs(Lobbies:GetChildren()) do
            if v.Owner.Value == Player then
                return
            end
        end

        TeleportToMap()

        return true
    end

    function TeleportToMap()
        Lobby = FindOpenLobby()
        task.wait()
        join()
        task.wait(.5)
        Create()
        task.wait(1)
        start2()
        task.wait(1)

        repeat
            LastCheck()
            task.wait(3)
        until false
    end

    function teleport()
        task.wait(5)

        repeat
            task.wait()
        until not Settings.Pause
        EquipFarmUnits()
        TeleportToMap()
    end

    local function localTeleportWithRetry(_, retryTime)
        local connection
        connection = TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
            if player == Player then
                print("Teleport failed, TeleportResult: "..teleportResult.Name)
                -- check the teleportResult to ensure it is appropriate to retry
                if teleportResult == Enum.TeleportResult.GameEnded or teleportResult == Enum.TeleportResult.Flooded or teleportResult == Enum.TeleportResult.Failure then
                    ClientToServer.request_leave_lobby:InvokeServer(Lobby)
                    print("Teleportfailed L")
                    task.delay(retryTime, function()
                        print("Reattempting teleport")
                        TeleportToMap()
                    end)
                elseif Enum.TeleportResult.Unauthorized then
                    TeleportService:Teleport(game.PlaceId)
                end
            end
        end)
    end

    function AutoBuyItems()
        local shopitems = GetShopItems()

        for _,ShopitemName in pairs(shopitems) do
            for _,ItemToBuy in pairs(Settings.AutoBuy.OtherItems or {"summon_ticket"}) do
                if string.match(ShopitemName, "%a+[%p %a]+") == ItemToBuy then
                    game:GetService("ReplicatedStorage").endpoints.client_to_server.buy_travelling_merchant_item:InvokeServer(ShopitemName)
                end
            end

            for _,ItemToBuy in pairs(Settings.AutoBuy.EvoItems or {}) do
                if string.match(ShopitemName, "%a+[%p %a]+") == ItemToBuy then
                    game:GetService("ReplicatedStorage").endpoints.client_to_server.buy_travelling_merchant_item:InvokeServer(ShopitemName)
                end
            end
        end
    end

    function AutoSummon()
        if Settings.AutoSummon.Enabled then
            local summonnum = "gems"
            if Settings.AutoSummon.UseTickets then 
                summonnum = "ticket" 
            elseif Settings.AutoSummon.x10 then 
                summonnum = "gems10" 
            end
            
            game:GetService("ReplicatedStorage").endpoints.client_to_server.buy_random_fighter:InvokeServer("dbz_fighter", summonnum)
        end
    end

    function ClaimQuest()
        local QuestsClass = EndpointsClient.session.quest_handler.quest_profile_data.quests

        for i,v in pairs(QuestsClass) do
            if not v.quest_progress then continue end
            local QuestUUID = i
            local Needed = v.quest_info.quest_class["amount"]
            local Progress = v.quest_progress["amount"] or 0
            
            if (Needed and Progress) then
                if Progress >= Needed then
                    ClientToServer.redeem_quest:InvokeServer(QuestUUID)
                end
            end
        end
    end

    function EquipFarmUnits()
        local AllUnits = EndpointsClient.session.collection.collection_profile_data.owned_units
        local EquippedUnits = EndpointsClient.session.collection.collection_profile_data.equipped_units
        local UnitsToEquip = {}

        for Index, name_uuid in pairs(Settings.Maps[Settings.Map].Units) do
            local split = string.split(name_uuid, ":")
            local name = split[1]
            local uuid = split[2]

            if AllUnits[uuid] then
                if not table.find(UnitsToEquip, uuid) then
                    table.insert(UnitsToEquip, uuid)
                end
            end
        end

        task.wait(.5)

        local function MakeSpace()
            local Indexes = {}
            local unitsNotThere = UnitsToEquip
            local spaceneeded = #UnitsToEquip
            for i,uuid in pairs(EquippedUnits) do
                local Index = table.find(UnitsToEquip, uuid)
                if not Index then
                    table.insert(Indexes, uuid)
                else
                    table.remove(unitsNotThere, Index)
                    spaceneeded = math.clamp(spaceneeded - 1, 0, #UnitsToEquip)
                end
            end

            for i = 1, spaceneeded do
                local uuid = Indexes[i]
                ClientToServer.unequip_unit:InvokeServer(uuid)
            end

            for _, uuid in pairs(unitsNotThere) do
                ClientToServer.equip_unit:InvokeServer(uuid)
                task.wait(.2)
            end
        end
        

        MakeSpace()
    end

    localTeleportWithRetry(game.PlaceId, 5)

    task.spawn(function()
        repeat
            if Settings.AutoBuy.Enabled then
                task.spawn(function()
                    AutoBuyItems()
                end)
            end
            task.wait(1)
        until false
    end)

    task.spawn(function()
        repeat
            AutoDelete()
            AutoSummon()
            ClaimQuest()
            task.wait(1)
        until false
    end)

    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(Character)
            if Settings.PlayerOptions["Show Gems"] then
                repeat
                    task.wait(1)
                until player.Character
                
                DisplayGems(Character)
            end
        end)
    end)

    teleport()
elseif game.PlaceId == 8349889591 then
    
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
        local BossesKilled = 0
        local Break = false
    
        request = http_request or request or HttpPost or syn.request
    
        local headers = {
            ["content-type"] = "application/json"
        }
    
        if Settings.Pause then
            return
        end
    
        task.spawn(function()
            repeat
                task.wait()
                if game:GetService("Workspace"):WaitForChild("_DATA"):WaitForChild("GameFinished").Value then --Checks if reward is ready to claim and claims it
                    task.wait(5)
                    task.spawn(function()
                        SendWebhook()
                    end)
                    task.wait(.5)
                    teleport()
                    break
                end
            until false
        end)

        Units.ChildAdded:Connect(function(Unit)
            task.wait(.5)
            if Unit:FindFirstChild("_stats") then
                local _stats = Unit:FindFirstChild("_stats")
                local _threat = _stats:FindFirstChild("threat")

                if (_threat and _threat.Value >= 3) then
                    repeat
                        task.wait(1)
                    until not Unit.Parent

                    BossesKilled = BossesKilled + 1
                end
            end
        end)

        local FarmUnits = {
            
        }
    
        local SpawnNum = 1
        local hillSpawnNum = 1
    
        local Maps = {
            ["namek"] = {
                ["Ground"] = {
                    CFrame.new(-2948.09, 93.0863, -710.218),
                    CFrame.new(-2938.52, 93.0863, -700.306),
                    CFrame.new(-2947.92, 93.0863, -699.637),
                    CFrame.new(-2948.45, 93.0863, -705.009),
                    CFrame.new(-2944.91, 93.7245, -702.243),
                    CFrame.new(-2945.11, 93.0863, -707.568),
                    CFrame.new(-2943.05, 93.7245, -699.922),
                    CFrame.new(-2943.33, 93.7245, -704.45),
                    CFrame.new(-2943.34, 93.7245, -709.403),
                    CFrame.new(-2938.24, 93.0863, -704.334),
                    CFrame.new(-2938.08, 93.0863, -708.257),
                    CFrame.new(-2938.08, 93.0863, -714.257),
                    CFrame.new(-2953.14, 93.0863, -699.354),
                    CFrame.new(-2953.25, 93.0863, -703.934),
                    CFrame.new(-2953.28, 93.08, -708.07)
                },
    
                ["Hill"] = {
                    CFrame.new(-2948.11, 95.6987, -715.501),
                    CFrame.new(-2950.38, 95.6987, -715.032),
                    CFrame.new(-2949.47, 95.6987, -717.193),
                    CFrame.new(-2951.92, 95.6987, -716.304)
                }
            },
            ["aot"] = {
                ["Ground"] = {
                    CFrame.new(-3011.31, 35.0219, -684.4),
                    CFrame.new(-3010.96, 35.0219, -680.458),
                    CFrame.new(-3014.6, 35.0219, -683.096),
                    CFrame.new(-3014.27, 35.0219, -680.199),
                    CFrame.new(-3016.96, 35.6601, -680.319),
                    CFrame.new(-3017.01, 35.0219, -683.823),
                    CFrame.new(-3019.64, 35.6601, -683.609),
                    CFrame.new(-3020.02, 35.6601, -680.326),
                    CFrame.new(-3022.27, 35.0219, -683.67),
                    CFrame.new(-3022.59, 35.6601, -681.008),
                    CFrame.new(-3026.02, 35.0219, -681.037),
                    CFrame.new(-3026.02, 35.0219, -681.037),
                    CFrame.new(-3026.5, 35.0219, -684.633)
                }
            },
            ["demonslayer"] = CFrame.new(-2876.57, 35.643, -135.408),
            ["naruto"] = CFrame.new(-890.466, 26.577, 313.911),
            ["marineford"] = {
                ["Ground"] = {
                    CFrame.new(-2555.5, 26.5069, -34.7715),
                    CFrame.new(-2554.21, 26.4909, -38.005),
                    CFrame.new(-2557.89, 26.4909, -40.7217),
                    CFrame.new(-2559.47, 26.5069, -36.8724),
                    CFrame.new(-2560.72, 26.7268, -45.002),
                    CFrame.new(-2562.53, 26.7268, -40.3499),
                    CFrame.new(-2564.53, 26.4909, -45.5189),
                    CFrame.new(-2554.32, 26.4909, -42.6333),
                    CFrame.new(-2562.45, 27.1292, -36.9791),
                    CFrame.new(-2557.22, 27.1292, -46.057),
                    CFrame.new(-2566.13, 26.5069, -42.2897),
                    CFrame.new(-2560.84, 26.4909, -49.0243),
                    CFrame.new(-2555.5, 29.5069, -34.7715),
                    CFrame.new(-2554.21, 29.4909, -38.005),
                    CFrame.new(-2557.89, 29.4909, -40.7217),
                    CFrame.new(-2559.47, 29.5069, -36.8724),
                },
    
                ["Hill"] = {
                    CFrame.new(-2573.74, 30.781, -51.5541),
                    CFrame.new(-2576.48, 30.781, -53.3122),
                    CFrame.new(-2578.58, 29.6381, -56.3211),
                    CFrame.new(-2576.05, 29.638, -57.737),
                }
            },
            ["tokyoghoul"] = {
                Ground = {
                    CFrame.new(-2997.21, 60.5035, -47.1209),
                    CFrame.new(-3000.55, 59.9314, -46.6402),
                    CFrame.new(-2999.92, 59.8652, -50.5599),
                    CFrame.new(-3003.55, 60.5035, -41.9474),
                    CFrame.new(-3005.39, 60.5035, -43.884),
                    CFrame.new(-3005.97, 60.5035, -47.6503),
                    CFrame.new(-3008.6, 60.5035, -50.928),
                    CFrame.new(-3004.11, 60.5035, -51.7732),
                    CFrame.new(-3006.1, 60.5035, -55.2905),
                    CFrame.new(-2996.56, 59.9314, -43.364),
                    CFrame.new(-3010.4, 59.8652, -53.6865),
                    CFrame.new(-3011.62, 59.8652, -56.6442),
                    CFrame.new(-3006.53, 59.8652, -59.0677),
                }
            },

            ["hueco"] = {
                Ground = {
                    CFrame.new(-196.752, 133.956, -779.957),
                    CFrame.new(-191.422, 133.956, -780.237),
                    CFrame.new(-191.443, 133.956, -777.782),
                    CFrame.new(-196.495, 133.956, -777.436),
                    CFrame.new(-191.311, 133.956, -775.101),
                    CFrame.new(-196.513, 133.956, -774.458),
                    CFrame.new(-192.452, 133.956, -772.384),
                    CFrame.new(-193.005, 133.956, -769.891),
                    CFrame.new(-197.025, 133.956, -771.517),
                    CFrame.new(-197.615, 133.956, -768.226),
                    CFrame.new(-181.761, 127.851, -778.069),
                    CFrame.new(-198.855, 133.956, -765.302),
                    CFrame.new(-193.55, 133.944, -764.9),
                    CFrame.new(-188.986, 133.955, -769.329),
                }
            }
        }
    
        local Log = {
    
        }
    
        local CurrentMap = Settings.Map
        local MapInfo = Settings.Maps[CurrentMap]
    
        function SendWebhook()
            task.wait(.5)

            local holder = {
                ["TotalGems"] = {
                    ["name"] = "Total Gems:",
                    ["value"] = (tostring(Player._stats.gem_amount.Value)) .. Emojis.Diamond,
                    ["inline"] = true
                },

                ["TimeCompletedAt"] = {
                    ["name"] = "Completed At Time:",
                    ["value"] = string.format("<t:%s:t>", os.time()) .. Emojis.Time,
                    ["inline"] = true
                },

                ["Map"] = {
                    ["name"] = "Map:",
                    ["value"] = Settings.Map .. Emojis.Map,
                    ["inline"] = true
                },

                ["BossesKilled"] = {
                    ["name"] = "Bosses Killed:",
                    ["value"] = tostring(BossesKilled) .. Emojis.Skull,
                    ["inline"] = true
                }
            }

            local field = {
                {
                    ["name"] = "Gems recived:",
                    ["value"] = string.match(PlayerGui.ResultsUI.Holder.GoldGemXP.GemReward.Main.Amount.Text, "%d+") .. Emojis.Diamond,
                    ["inline"] = true
                },
    
                {
                    ["name"] = "Wave ended:",
                    ["value"] = tostring(game:GetService("Workspace")["_wave_num"].Value) .. Emojis.Wave,
                    ["inline"] = true
                },

                {
                    ["name"] = "Time Finished:",
                    ["value"] = (string.match(PlayerGui.ResultsUI.Holder.Middle.Timer.Text, "%d+%p%d+")) .. Emojis.Time,
                    ["inline"] = true
                },
            }

            for i, v in pairs(Settings.WebhookOptions) do
                if v then
                    table.insert(field, holder[i])
                end
            end


            local data = {
                ["embeds"] = {
                    {
                        ["author"] = {
                            ["name"] = string.format("%s: Lv %s", Player.DisplayName, tostring(GetPlayersLevel())),
                        },
                
                        ["description"] = "Match finished",
                        ["color"] = tostring(0xFF2449),
                        ["thumbnail"] = {
                            url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=420&height=420&format=png"
                        },
                    }
                }
            }

            data.embeds[1]["fields"] = field
            local newdata = game:GetService("HttpService"):JSONEncode(data)
            
            local abcdef = {Url = Settings.Webhooks, Body = newdata, Method = "POST", Headers = headers}
            if Settings.Webhooks ~= "" then
                request(abcdef)
            end
        end
    
        function addUnits()
            for i,v in pairs(MapInfo.Units) do
                if i == 7 then return end
                if v == "None" then continue end
                local split = string.split(v, ":") -- uuid:name
                local UnitName = split[1]
                local uuid = split[2]
    
                FarmUnits[i] = {
                    ["Name"] = UnitName, 
                    ["uuid"] = uuid,
                };
            end
        end
    
        function GetUpgrades(UnitName)
            for Index, uuid_name in pairs(MapInfo.Units) do
                if uuid_name == "None" then continue end
                local split = string.split(uuid_name, ":")
                local name = split[1]
                local uuid = split[2]
    
                if name == UnitName then
                    return MapInfo.Upgrades[Index]
                end
            end
        end
    
        function GetSpawnCap(UnitName)
            for Index, uuid_name in pairs(MapInfo.Units) do
                local split = string.split(uuid_name, ":") -- name:uuid
                local unitname = split[1]
                local uuid = split[2]
    
                if unitname == UnitName then
                    return MapInfo.SpawnCaps[Index]
                end
            end
        end
    
        function spawnUnit(Index)
            local UnitName = FarmUnits[Index]["Name"]
            local Cap = GetSpawnCap(UnitName)
            local Type = "Ground"
            if Log[Index] and Log[Index] == Cap then return end
            if not Maps[Settings.Map][Type][SpawnNum] then return end

            if Player.UserId == 68728334 then --sexy perhapz
                Maps["namek"]["Ground"][1] = Maps["namek"]["Ground"][2]
                Maps["namek"]["Ground"][2] = CFrame.new(-2945.90723, 92.3062057, -693.054199, 1, 0, 0, 0, 1, 0, 0, 0, 0.999999821) 
            elseif Player.UserId == 94158016 then
                local old2 = Maps["namek"]["Ground"][2]

                Maps["namek"]["Ground"][1] = old2
                Maps["namek"]["Ground"][2] = CFrame.new(-2948.09, 93.0863, -710.218)
            end

            local args = {
                [1] = FarmUnits[Index]["uuid"],
                [2] = Maps[Settings.Map][Type][SpawnNum]
            }
            
            local placed
            
            repeat
                placed = ClientToServer:WaitForChild("spawn_unit"):InvokeServer(unpack(args))
                task.wait(1)
            until placed
    
            if placed then
                if not Log[Index] then
                    Log[Index] = 1
                else
                    Log[Index] = Log[Index] + 1
                end
    
                SpawnNum = SpawnNum + 1
            end
        end
    
        function upgradeUnits()
            for i, v in pairs(Units:GetChildren()) do
                if not v:FindFirstChild("_stats") then continue end
                if v._stats:FindFirstChild("player") and  v._stats:FindFirstChild("player").Value == Player then
                    if v._stats:FindFirstChild("parent_unit") and v._stats:FindFirstChild("parent_unit").Value then continue end
                    local MaxUpgrade = GetUpgrades(v._stats.id.Value) or 5
                    print(MaxUpgrade, v.Name)
                    if v._stats.upgrade.Value ~= MaxUpgrade then 
    
                        local Upgraded 
    
                        repeat
                            task.wait(2)
                            Upgraded = ClientToServer:WaitForChild("upgrade_unit_ingame"):InvokeServer(v)
                        until Upgraded or Break
    
                        if Break then return end
                        continue
                    end
                end
            end
            task.wait(.1)
            upgradeUnits()
        end
    
        function GetPlayersLevel()
            local exp = Player._stats.player_xp.Value
    
            return math.floor(0.07142857142857142 * (-179 + math.sqrt(56 * exp + 37249)));
        end
    
        function SellAll()
            Break = true
            for i, v in pairs(game:GetService("Workspace")["_UNITS"]:GetChildren()) do
                if not v:FindFirstChild("_stats") or v.Name == "aot_generic" then continue end
                if v._stats.player.Value == Player then
                    ClientToServer:WaitForChild("sell_unit_ingame"):InvokeServer(v)
                    task.wait(.1)
                end
            end
        end
    
        function start()
            addUnits()
            task.wait(2)
            local Seconds = 0
            SolarisLib:Notification("Gems", string.format("You have %s GEMS", tostring(Player:WaitForChild("_stats"):WaitForChild("gem_amount").Value)), 60 * 50)
            local timelapse = SolarisLib:Notification("Timelapse", string.format("%s:%s", math.floor(Seconds/60%60), Seconds%60), 60 * 60)
            task.spawn(function()
                ClientToServer:WaitForChild("vote_start"):InvokeServer()

                repeat
                    timelapse.Text = string.format("%sm:%ss", math.floor(Seconds/60%60), Seconds%60)
                    task.wait(1)
                    Seconds = Seconds + 1
                until nil
            end)
    
            for Index, Info in pairs(FarmUnits) do
                local Name = Info["Name"]
                print(Name)
                local Cap = GetSpawnCap(Name) -- Spawn Cap
                print(Cap)
                for i = 1, Cap do
                    task.wait(1)
                    spawnUnit(Index)
                end
            end
    
            game:GetService("Workspace")["_wave_num"].Changed:Connect(function()
                if game:GetService("Workspace")["_wave_num"].Value >= Settings.Maps[Settings.Map].SellAt then
                    SellAll()
                end
            end)
    
            task.spawn(function()
                repeat
                    for i,v in pairs(Units:GetChildren()) do
                        if v.Name == "erwin" or v.Name == "shanks" then
                            if not v:FindFirstChild("_stats") then continue end
                            if v._stats:FindFirstChild("player") then
                                if v._stats.player.Value == Player then
                                    ClientToServer.use_active_attack:InvokeServer(v)
                                    task.wait(20)
                                end
                            end
                        end
                    end
                    task.wait()
                until Break
            end)
    
            upgradeUnits()       
        end
    
        function teleport()
            ClientToServer.teleport_back_to_lobby:InvokeServer()
            task.wait(10)
            TeleportService:Teleport(8304191830)
        end
    
        local function localTeleportWithRetry(placeid, retryTime)
            local connection
            connection = TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
                if player == Player then
                    print("Teleport failed, TeleportResult: "..teleportResult.Name)
                    -- check the teleportResult to ensure it is appropriate to retry
                    if teleportResult == Enum.TeleportResult.GameEnded or teleportResult == Enum.TeleportResult.Flooded or teleportResult == Enum.TeleportResult.Failure then
                        game:GetService("ReplicatedStorage").endpoints.client_to_server.request_leave_lobby:InvokeServer(Lobby)
                        print("Teleportfailed L")
                        task.delay(retryTime, function()
                            print("Reattempting teleport")
                            TeleportService:Teleport(placeid)
                        end)
                    end
                end
            end)
        end
    
        localTeleportWithRetry(8304191830, 5)
    
        task.wait(8)
        start()
    end