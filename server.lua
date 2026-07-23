local function getConn()
    return exports.pav_mysql:getConn()
end

local topPlayersCache = {}
local UPDATE_INTERVAL = 30 * 60000 -- 30 minutes
local playerSpamCooldown = {}

function updateTopPlayers()
    dbQuery(function(qh)
        local result = dbPoll(qh, 0)
        if result then
            -- Clean up names
            for i, row in ipairs(result) do
                row.charactername = (row.charactername or "Bilinmeyen"):gsub("_", " ")
                row.hoursplayed = tonumber(row.hoursplayed) or 0
            end
            topPlayersCache = result
            triggerClientEvent(root, "pav_toptime:receiveData", root, topPlayersCache)
        end
    end, getConn(), "SELECT id, charactername, hoursplayed FROM characters WHERE hoursplayed > 0 ORDER BY hoursplayed DESC LIMIT 50")
end

addEventHandler("onResourceStart", resourceRoot, function()
    updateTopPlayers()
    setTimer(updateTopPlayers, UPDATE_INTERVAL, 0)
end)

addEvent("pav_toptime:requestData", true)
addEventHandler("pav_toptime:requestData", root, function()
    if not client then return end
    

    triggerClientEvent(client, "pav_toptime:receiveData", client, topPlayersCache)
    
    local now = getTickCount()
    if playerSpamCooldown[client] and now - playerSpamCooldown[client] < 10000 then 
        return 
    end
    playerSpamCooldown[client] = now
    
    local dbid = tonumber(exports.pav_secure:getData(client, "dbid"))
    local myHours = tonumber(exports.pav_secure:getData(client, "hoursplayed")) or 0
    if dbid then
        dbQuery(function(qh, p)
            if not isElement(p) then dbFree(qh) return end
            local res = dbPoll(qh, 0)
            if res and res[1] then
                local rank = tonumber(res[1].rank) or 0
                triggerClientEvent(p, "pav_toptime:receiveMyRank", p, rank + 1)
            end
        end, {client}, getConn(), "SELECT COUNT(*) as rank FROM characters WHERE hoursplayed > ? OR (hoursplayed = ? AND id < ?)", myHours, myHours, dbid)
    end
end)

addEventHandler("onPlayerQuit", root, function()
    playerSpamCooldown[source] = nil
end)
