local enabled = true -- disable the script with true or false
local GMonly = false -- determine whether you want only GMs to be able to use said command

local function getPlayerCharacterGUID(player)
    return player:GetGUIDLow()
end

local function GMONLY(player)
    -- player:SendBroadcastMessage("|cffff0000You don't have permission to use this command.|r")
end

local function OnLogin(event, player)
    local PUID = getPlayerCharacterGUID(player)
    local Q = CharDBQuery(string.format("SELECT RepRate FROM custom_rep_rates WHERE CharID=%i", PUID))

    if Q then
        local RepRate = Q:GetUInt32(0)
        player:SendBroadcastMessage(string.format("|cff5af304Your reputation rate is currently set to %dx|r", RepRate))
    end
end

local function SetRepRate(event, player, command)
    local mingmrank = 3
    local PUID = getPlayerCharacterGUID(player)

    if command:find("rep") then
        local rate = tonumber(command:sub(5))

        if command == "rep" then
            player:SendBroadcastMessage("|cff5af304To set your reputation rate, type '.rep X' where X is a value between 1 and 10.|r")
            return false
        end

        if rate and rate >= 1 and rate <= 10 then
            if GMonly and player:GetGMRank() < mingmrank then
                GMONLY(player)
                return false
            else
                CharDBExecute(string.format("REPLACE INTO custom_rep_rates (CharID, RepRate) VALUES (%i, %d)", PUID, rate))
                player:SendBroadcastMessage(string.format("|cff5af304You changed your reputation rate to %dx|r", rate))
                return false
            end
        else
            player:SendBroadcastMessage("|cffff0000Invalid reputation rate. Please enter a value between 1 and 10.|r")
            return false
        end
    end
end

local function onReputationChange(event, player, factionId, standing, incremental)
    local PUID = getPlayerCharacterGUID(player)
    local Q = CharDBQuery(string.format("SELECT RepRate FROM custom_rep_rates WHERE CharID=%i", PUID))
    local RepRate = 1

    if Q then
        RepRate = Q:GetUInt32(0)
    end

    -- Prevent the default reputation gain
    if standing > 0 and incremental then
        player:SetReputation(factionId, player:GetReputation(factionId) * RepRate)
        return -1
    end
end

local function createRepRatesTable()
    CharDBExecute([[
        CREATE TABLE IF NOT EXISTS custom_rep_rates (
            CharID INT PRIMARY KEY,
            RepRate INT DEFAULT 1
        );
    ]])
end

if enabled then
    createRepRatesTable()
    RegisterPlayerEvent(3, OnLogin)
    RegisterPlayerEvent(15, onReputationChange)
    RegisterPlayerEvent(42, SetRepRate)
end
