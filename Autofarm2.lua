print("Loading")
repeat
    task.wait()
until game.Players.LocalPlayer
task.wait(5)
--\\ Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")


--// Modules
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/AverageFarmer/animeAdv/main/Library.lua"))()
local SolarisLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/AverageFarmer/Silent/master/library.lua"))()

local src = ReplicatedStorage:WaitForChild("src")
local Data = src:WaitForChild("Data")
local Loader = require(src:WaitForChild("Loader"));
local EndpointsClient = Loader.load_client_service(script, "EndpointsClient");
local UnitsInfo = require(Data.Units)
local Items = require(Data:WaitForChild("ItemsForSale"))

--//Remotes
local ClientToServer = ReplicatedStorage:WaitForChild("endpoints"):WaitForChild("client_to_server")

--// Const
local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = Player:GetMouse()
local PlayerGui = Player:WaitForChild("PlayerGui")
local Units = game:GetService("Workspace")["_UNITS"]

local url = "https://discord.com/api/webhooks/999000287664676927/W0O5Dbs4OEUkuUYlkjpdU8aYlonN3Qs1d2bXy2ULbTNRF9VrrFJK95rGYukTfgpmWY11"

local FileName = "AAFarm "..tostring(Player.UserId)

-- AutoLaunch
syn.queue_on_teleport(game:HttpGet("https://raw.githubusercontent.com/AverageFarmer/animeAdv/main/Autofarm2.lua"))

--// Vars
local Lobby = "_lobbytemplategreen1"
local ctrl = false
local SavedSettings = (isfile(FileName .. ".lua") and readfile(FileName .. ".lua")) or {}
local Settings = {
    Map = "namek",
    MapNumber = "1",
    Difficulty = "Normal",
    IsInf = false,
    Pause = true,
    SellAt = 23,
    
    AutoBuy = {
        Enabled =  false,
        ToBuy = {"summon_ticket"}
    },
    
    Maps = {
        namek = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
        },

        aot = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
        },

        marineford = {
            Units = {},
            Upgrades = {},
            SpawnCaps = {},
        },
    },

    AntiAFK = false,
    AntiAFKv2 = true,

    AutoDelete = {
        Enabled = false, 
        Rarities = {"Rare"}, 
        KeepTraits = true,
    },

    AutoSummon = {
        Enabled = false, 
        x10 = false,
    },
}

--// Setup
for i,v in pairs(HttpService:JSONDecode(SavedSettings)) do
    Settings[i] = v
end

Settings.AutoDelete.Enabled = false

-- Anti Afkv2
Player.Idled:Connect(function(time)
    if Settings.AntiAFKv2 then
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

function ShopItems()
    local items = {}

    for i,v in pairs(Items) do
        table.insert(items, i)
    end

    return items
end

if game.PlaceId == 8304191830 then
    --// Lobby

    --// Local Const
    local Lobbies = game:GetService("Workspace")["_LOBBIES"].Story

    local Maps = {
        "namek",
        "aot",
        --"demonslayer",
        --"naruto",
        "marineford"
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
    local Window = Library.CreateWindow("DizFarm v1.1a")

    local AutoFarmTab = Window:Tab("AutoFarm", 6087485864)
    local UnitTab = Window:Tab("Units")
    local SummonTab = Window:Tab("Summoning")
    local MiscTab = Window:Tab("Misc")

    local MapSettings = AutoFarmTab:Section("Map Settings")
    local TeleportSettings = AutoFarmTab:Section("Teleport Settings")

    local AutoDeleteSection = SummonTab:Section("AutoDelete")

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

    local SellAt
    SellAt = MapSettings:TextBox("Sell At Wave:", Settings.SellAt, function(val)
        val = tonumber(val) or 1
        SellAt:Set(val)
        Save()
    end)

    local Pause = TeleportSettings:Toggle("Pause", Settings.Pause, function(val)
        Settings.Pause = val
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

    local MaxSlots = 5
    local Pets = {}

    repeat
        task.wait()
    until EndpointsClient

    repeat
        task.wait()
    until EndpointsClient.session

    repeat
        task.wait()
    until EndpointsClient.session.collection
    task.wait(3)
    local equipped = EndpointsClient.session.collection.collection_profile_data.equipped_units
    local AllUnits = EndpointsClient.session.collection.collection_profile_data.owned_units

    for Index, uuid in pairs(equipped) do
        if AllUnits[uuid] then
            local info = AllUnits[uuid]
            
            Pets[Index] = string.format("%s:%s", info.unit_id, uuid)
        end
    end
    table.insert(Pets, "None")

    for Index, Map in pairs(Maps) do
        Map = Map:lower()
        local MapInfo = Settings["Maps"][Map]
        local MapSlot = UnitTab:Section(Map)

        local UpgradeDropHolder = {}
        local PlacementDropHolder = {}

        for SlotNumber = 1, MaxSlots do
            local CurrentUnit = MapInfo.Units[SlotNumber] or "None"
            local UnitName = (CurrentUnit ~= "None" and  string.split(MapInfo.Units[SlotNumber], ":")[1]) or nil
            local UnitData = GetUnitInfo(UnitName)
            local Spawn_Cap = (UnitData and UnitData.spawn_cap or 1)
        
            MapSlot:Label("Unit#" .. SlotNumber)
            MapSlot:DropDown("", CurrentUnit, Pets, function(val)
                MapInfo.Units[SlotNumber] = val 

                CurrentUnit = val
                UnitName = (CurrentUnit ~= "None" and  string.split(val, ":")[1]) or nil
                UnitData = GetUnitInfo(UnitName)
                Spawn_Cap = (CurrentUnit ~= "None" and UnitData.spawn_cap or 3)

                if UpgradeDropHolder[SlotNumber] then
                    local UpgradeNum = (UnitData and #UnitData.upgrade) or 3
                    
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
            
            PlacementDropHolder[SlotNumber] = MapSlot:DropDown("SpawnCap", MapInfo.Units.SpawnCaps or 1, (CurrentUnit ~= "None" and MakeList(Spawn_Cap)) or {}, function(val)
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
        task.wait(2)
        start2()
        task.wait(1)

        repeat
            LastCheck()
            task.wait(3)
        until false
    end

    function teleport()
        task.wait(10)

        repeat
            task.wait()
        until not Settings.Pause
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
            for _,ItemToBuy in pairs(Settings.AutoBuy.ToBuy) do
                if string.match(ShopitemName, ItemToBuy) then
                    game:GetService("ReplicatedStorage").endpoints.client_to_server.buy_travelling_merchant_item:InvokeServer(ShopitemName)
                end
            end
        end
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
            task.wait(1)
        until false
    end)

    teleport()
elseif game.PlaceId == 8349889591 then
    
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------
    
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
                if PlayerGui:WaitForChild("ResultsUI").Enabled == true  then --Checks if reward is ready to claim and claims it
                    local button = PlayerGui.ResultsUI.Holder.Buttons.Next
                    
                    local events = {"MouseButton1Click", "MouseButton1Down", "MouseButton1Up"}
                    for i,v in pairs(events) do
                        for i,v in pairs(getconnections(button[v])) do
                            task.wait()
                            v:Fire()
                        end
                    end
                    print("asd")
                    task.wait(1)
                    SendWebhook()
                    task.wait(1)
                    teleport()
                    break
                end
            until false
        end)
    
        if Settings.AntiAFK then
            repeat
                task.wait()
            until Player.Character
            task.wait(2)
            Player.Character.Parent = game.Lighting
        end
    
        local FarmUnits = {
            
        }
    
        local SpawnNum = 1
        local hillSpawnNum = 1
    
        local Maps = {
            ["namek"] = {
                ["Ground"] = {
                    CFrame.new(-2948.09, 93.0863, -710.218),
                    CFrame.new(-2944.91, 93.7245, -702.243),
                    CFrame.new(-2938.52, 93.0863, -700.306),
                    CFrame.new(-2947.92, 93.0863, -699.637),
                    CFrame.new(-2948.45, 93.0863, -705.009),
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
        }
    
        local Log = {
    
        }
    
        local CurrentMap = Settings.Map
        local MapInfo = Settings.Maps[CurrentMap]
    
        function SendWebhook()
            task.wait(.5)
            local data = {
                ["embeds"] = {{
                    ["author"] = {
                        ["name"] = string.format("%s @%s: Lv %s", Player.DisplayName, Player.Name, tostring(GetPlayersLevel())),
                        ["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. Player.UserId .. "&width=420&height=420&format=png"
                    },
            
                    ["description"] = "Match finished",
                    ["color"] = tostring(0xFF2449),
                    ["fields"] = {
                        {
                            ["name"] = "Gems recived:",
                            ["value"] = string.match(PlayerGui.ResultsUI.Holder.GoldGemXP.GemReward.Main.Amount.Text, "%d+"),
                            ["inline"] = true
                        },
            
                        {
                            ["name"] = "Wave ended:",
                            ["value"] = game:GetService("Workspace")["_wave_num"].Value,
                            ["inline"] = true
                        },
    
                        {
                            ["name"] = "Map:",
                            ["value"] = Settings.Map,
                            ["inline"] = true
                        },
    
                        {
                            ["name"] = "Time Finished:",
                            ["value"] = string.match(PlayerGui.ResultsUI.Holder.Middle.Timer.Text, "%d+%p%d+"),
                            ["inline"] = true
                        },
    
                        {
                            ["name"] = "Total Gems:",
                            ["value"] = Player._stats.gem_amount.Value,
                            ["inline"] = true
                        },
                    }
                }}
            }
            local newdata = game:GetService("HttpService"):JSONEncode(data)
            
            local abcdef = {Url = url, Body = newdata, Method = "POST", Headers = headers}
            request(abcdef)
        end
    
        function addUnits()
            for i,v in pairs(MapInfo.Units) do
                if i == 6 then return end
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
                if not v:FindFirstChild("_stats") or v.Name == "aot_generic" then continue end
                if v._stats:FindFirstChild("player") and  v._stats:FindFirstChild("player").Value == Player then
                    local MaxUpgrade = GetUpgrades(v._stats.id.Value) or 5
                    print(MaxUpgrade, v.Name)
                    if v._stats.upgrade.Value ~= MaxUpgrade then 
    
                        local Upgraded 
    
                        repeat
                            task.wait(3)
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
    
        function start() -- starts the game
            addUnits()
            task.wait(1.5)
    
            SolarisLib:Notification("Gems", string.format("You have %s GEMS", tostring(Player._stats.gem_amount.Value)), 60 * 20)
            task.spawn(function()
                ClientToServer:WaitForChild("vote_start"):InvokeServer()
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
                if game:GetService("Workspace")["_wave_num"].Value >= Settings.SellAt then
                    SellAll()
                end
            end)
    
            task.spawn(function()
                repeat
                    for i,v in pairs(Units:GetChildren()) do
                        if not v:FindFirstChild("_stats") then continue end
                        if v.Name == "erwin" or v.Name == "shanks" then
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
    
        task.wait(10)
        start()
    end