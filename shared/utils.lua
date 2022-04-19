local QBCore = exports['qb-core']:GetCoreObject()

-- function to return the number of elements in a table
local function getTableLength(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1 
    end
    return count
  end


-- function to check if a gang is whitelisted
function IsGangAllowed(PlayerGang)
    if not PlayerGang or not PlayerGang.name then
        return false
    end

    if not Config.AllowedGangs[PlayerGang.name] then
        return false
    end

    return true
end

-- function to check of a turf was recently captured and is currenlty locked
function IsTurfLocked(turf) 
    if not turf then
        return false
    end

    if turf.lockExpirationTime == 0 then
        return false
    end

    if turf.lockExpirationTime == -1 then
        return true
    end

    return os.time() <= turf.lockExpirationTime
end

-- function to add a resident gang member to a turf
function AddResidentToTurf(turf, playerID, playerGang, data)
    if not turf.residents or not turf.residents[playerGang.name] then
        return
    end

    turf.residents[playerGang.name][playerID] = data
end

-- function to find a turf by a resident gang member ID
function GetTurfByResidentID(turfs, playerID, playerGang)
    if turfs and next(turfs) then
        for index, turf in pairs(turfs) do
            if turf.residents and turf.residents[playerGang.name] and turf.residents[playerGang.name][playerID] then
                return turf, index
            end
        end
    end

    return nil, nil
end

-- function to find a turf by a given ID
function GetTurfByID(turfs, turfID)
    if not turfs or not next(turfs) then
        return nil, nil
    end

    for index, turf in pairs(turfs) do
        if turf.ID == turfID then
            return turf, index
        end
    end

    return nil, nil
end 

-- function to get all the resident gang memebrs that are alive in a turf
function GetTurfResidetsWithMembersAlive(turf)
    if not turf or not turf.residents or not next(turf.residents) then
        return {}
    end

    local residetsAliveMap = {}
    for gang, residents in pairs(turf.residents) do
        
        if residents and next(residents) then
            for _, gangMember in pairs(residents) do
                if gangMember.isAlive then
                    if not residetsAliveMap[gang] then
                        residetsAliveMap[gang] = 1
                    else
                        residetsAliveMap[gang] += 1
                    end
                end
            end
        end
    end

    return residetsAliveMap
end

-- function to remove a resident gang member from a turf
function RemoveResidentFromTurf(turf, playerID, playerGang)
    if not turf.residents or not turf.residents[playerGang.name] then
        return
    end

    if turf.residents[playerGang.name][playerID]  then
        turf.residents[playerGang.name][playerID] = nil
        table.remove(turf.residents[playerGang.name], playerID)
    end
end

-- function to remove a resident gang member from all turfs
function RemoveResidentFromAllTurfs(turfs, playerID)
    if turfs and next(turfs) then
        for _, turf in pairs(turfs) do
            if turf.residents and next(turf.residents) then
                for _, residentData in pairs(turf.residents) do
                    if residentData[playerID] then
                        residentData[playerID] = nil
                    end
                end
            end
        end
    end
end

-- function to determine if a war can be started on a turf
function CanStartWar(turf, playerID, playerGang)
    if IsTurfLocked(turf) then
        return false
    end

    if turf.warStage ~= Config.WarStages.IDLE then
        return false
    end

    if not playerGang or not playerGang.grade or not playerGang.grade.level then
        return false
    end

    if playerGang.grade.level <= Config.RequiredGangMemberRank then
        return false
    end

    local gangMembersCountMap = {}

    for _, id in pairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(id)
        if player and player.PlayerData and player.PlayerData.gang then
            local gang = player.PlayerData.gang
            if Config.AllowedGangs[player.PlayerData.gang.name] and turf.controlledBy ~= gang.name then
                if not gangMembersCountMap[gang.name] then 
                    gangMembersCountMap[gang.name] = 1
                else
                    gangMembersCountMap[gang.name] += 1
                end

                if gangMembersCountMap[gang.name] >= Config.RequiredGangMembers then
                    return true
                end
            end
        end
    end

    return false
end

-- function to check the tur war progress and determine a winner
function CheckBattleProgress(residetsAliveMap, turfControlledByGangName)
    local winner = ''
    local numberOfResidentGroupsAlive = getTableLength(residetsAliveMap)

    if not residetsAliveMap or not next(residetsAliveMap) or numberOfResidentGroupsAlive == 0 then
        return true, true, ''
    end
    
    -- only one gang group left alive - they are the winners
    if numberOfResidentGroupsAlive == 1 then
        for winningGang, _ in pairs(residetsAliveMap) do
            winner = winningGang
            break
        end
        return true, false, winner
    end

    return false, false, ''
end
