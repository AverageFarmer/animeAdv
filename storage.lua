local src = game.ReplicatedStorage:WaitForChild("src")
local data = src:WaitForChild("Data")
local Loader = require(src:WaitForChild("Loader"));

local EndpointsClient = Loader.load_client_service(script, "EndpointsClient");
local QuestsClass = EndpointsClient.session.quest_handler.quest_profile_data.quests
--quest_info
--quest_progress

for i,v in pairs(QuestsClass) do

    print(i, v)

    if typeof(v) == "table" then
        for i, v in pairs(v.quest_info) do
            print(i, v)
        end
    end
end