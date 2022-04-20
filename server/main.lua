local QBCore = exports['qb-core']:GetCoreObject()


local Turfs = nil


 -- functions
local function loadTurfs()
    Turfs = nil
    Turfs = MySQL.Sync.fetchAll('SELECT * FROM `gang_turfs`', {})
    if Turfs and next(Turfs) then
        for _, data in pairs(Turfs) do
            if Config.Turfs[data.scriptID] then
                data.coords = Config.Turfs[data.scriptID].coords
                data.radius = Config.Turfs[data.scriptID].radius
                data.label = Config.Turfs[data.scriptID].label
                data.residents = {}
                for gang, allowed in pairs(Config.AllowedGangs) do
                    if allowed then
                        data.residents[gang] = {}
                    end
                end
            end
        end

        TriggerClientEvent('dz-qb-turfs:client:LoadTurfs', -1)
    end
end

local function lockTurf(turfID)
    local currentTime = os.time()
    local lockExpirationTime = currentTime + Config.TurfLockedTime
    MySQL.Async.execute('UPDATE gang_turfs SET lockedAtTime = ?, lockExpirationTime = ? WHERE ID = ?',{
        currentTime,
        lockExpirationTime,
        turfID
    }, function(rowsChanged)
        if rowsChanged == 1 then
            loadTurfs()
        end
    end)
end

local function unlockTurf(turfID)
    MySQL.Async.execute('UPDATE gang_turfs SET lockedAtTime = ?, lockExpirationTime = ? WHERE ID = ?',{
        0,
        0,
        turfID
    }, function(rowsChanged)
        if rowsChanged == 1 then
            loadTurfs()
        end
    end)
end

local function updateTurfControlledBy(turfID, newGang)
    MySQL.Async.execute('UPDATE gang_turfs SET controlledBy = ? WHERE ID = ?', {
        newGang,
        turfID
    }, function(rowsChanged)
        if rowsChanged == 1 then
            loadTurfs()
        end
    end)
end

local function updateTurfControlledByAndLock(turfID, newGang)
    local currentTime = os.time()
    local lockExpirationTime = currentTime + Config.TurfLockedTime
    MySQL.Async.execute('UPDATE gang_turfs SET warStage = ?, controlledBy = ?, lockedAtTime = ?, lockExpirationTime = ? WHERE ID = ?', {
        Config.WarStages.IDLE,
        newGang,
        currentTime,
        lockExpirationTime,
        turfID
    }, function(rowsChanged)
        if rowsChanged == 1 then
            loadTurfs()
        end
    end)
end

local function giveRewardsToTurfWinners(turf, newGang)
    local drugRewards = {
        [1] = 'cokebaggy',
        [2] = 'meth',
        [3] = 'weed_ak47',
    }
    local drugQuantity = math.random(25, 50)
    local drugIndex = math.random(1, #drugRewards)
    
    if not turf or not turf.residents or not turf.residents[newGang] then
        return
    end
    local residents = turf.residents[newGang]
    if not residents or not next(residents) then
        return
    end
    for id, _ in pairs(residents) do
        local Player = QBCore.Functions.GetPlayer(id)
        if Player then
            Player.Functions.AddItem(drugRewards[drugIndex], drugQuantity)
            Player.Functions.AddItem('markedbills', math.random(5, 10))
            TriggerClientEvent('dz-qb-turfs:client:NotifyRewardsReceived', id)
        end
    end
end

local function handleTurfWarDraw(turf)
    CreateThread(function()
        MySQL.Async.execute('UPDATE gang_turfs SET warStage = ? WHERE ID = ?', {
            Config.WarStages.IDLE,
            turf.ID
        }, function(rowsChanged)
            if rowsChanged == 1 then
                loadTurfs()
            end
        end)
    end)
end

local function handleTurfWarStarted(turf)
    CreateThread(function()
        local warStage = Config.WarStages.PREPARE
        local winnerGangName = nil
        
        while warStage ~= Config.WarStages.IDLE do   
            if warStage ~= turf.warStage then
                MySQL.Async.execute('UPDATE gang_turfs SET warStage = ? WHERE ID = ?', {
                    warStage,
                    turf.ID
                }, function(rowsChanged)
                    if rowsChanged == 1 then
                        turf.warStage = warStage
                        TriggerClientEvent('dz-qb-turfs:client:UpdateTurfWarStage', -1, turf.ID, turf.warStage)
                    end
                end)
            end

            Wait(1000)

            if turf.warStage == Config.WarStages.PREPARE then
                Wait(Config.TurfPrepareTime * 1000)
                warStage = Config.WarStages.BATTLE
            end

            if turf.warStage == Config.WarStages.BATTLE then
                if not winnerGangName then
                    local residetsAliveMap = GetTurfResidetsWithMembersAlive(turf)
                    local isBattleDone, isBattleDraw, winner = CheckBattleProgress(residetsAliveMap, turf.controlledBy)
                    if isBattleDone then
                        Wait(10000)
                        if isBattleDraw then
                            handleTurfWarDraw(turf)
                            warStage = Config.WarStages.IDLE
                        else
                            warStage = Config.WarStages.CAPTURE
                            winnerGangName = winner
                        end
                    end
                end
            end

            if turf.warStage == Config.WarStages.CAPTURE then
                local capturedCheckpoints = 1
                while capturedCheckpoints < Config.TurfTotalCaptureCheckpoints do
                    TriggerClientEvent('dz-qb-turfs:client:NotifyTurfCaptureProgress', -1, turf.ID, capturedCheckpoints, winnerGangName)
                    Wait(Config.TurfTimeToCaptureCheckpoint * 1000)
                    capturedCheckpoints += 1
                end
                updateTurfControlledByAndLock(turf.ID, winnerGangName)
                giveRewardsToTurfWinners(turf, winnerGangName)
                break
            end
        end
    end)
end


-- callback functions
QBCore.Functions.CreateCallback('dz-qb-turfs:func:server:GetTurfs', function(source, cb)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player or not player.PlayerData or not player.PlayerData.gang then
        return cb(nil)
    end
    if not IsGangAllowed(player.PlayerData.gang) then
        return cb(nil)
    end

	cb(Turfs)
end)

QBCore.Functions.CreateCallback('dz-qb-turfs:func:server:RemovePlayerFromAllTurfs', function(source, cb)
    local src = source

    RemoveResidentFromAllTurfs(Turfs, src)
    cb()
end)


-- commands
QBCore.Commands.Add('challengeTurf', 'Start a war to capture this gang turf', {}, false, function(source)
    local player = QBCore.Functions.GetPlayer(source)
    local playerGang = player.PlayerData.gang
    
    if not playerGang or not IsGangAllowed(playerGang) then
        TriggerClientEvent('QBCore:Notify', source, 'Something is wrong...', 'error')
        return
    end

    local turf, _ = GetTurfByResidentID(Turfs, source, playerGang)
    if not turf then
        TriggerClientEvent('QBCore:Notify', source, 'Something is wrong...', 'error')
        return
    end

    if not Config.AllowMultipleWars then
        for _, turf in pairs(Turfs) do
            if turf.warStage ~= Config.WarStages.IDLE then
                TriggerClientEvent('QBCore:Notify', source, 'A war is already in progress...', 'error')
                return
            end
        end
    end

    if not CanStartWar(turf, source, playerGang) then
        TriggerClientEvent('QBCore:Notify', source, 'You can\'t do this...', 'error')
        return
    end

    handleTurfWarStarted(turf)
end, 'user')

QBCore.Commands.Add('reloadTurfs', 'Reload all gang turfs and resying the data', {}, false, function(source)
    loadTurfs();
    TriggerClientEvent('QBCore:Notify', source, 'Gang turfs reloaded', 'success')
end, 'admin')

QBCore.Commands.Add('lockTurf', 'Lock down a turf', { { name = 'id', help = 'Turf ID' } }, true, function(source, args)
    if not args or not args[1] then
        return
    end

    lockTurf(args[1])
    TriggerClientEvent('QBCore:Notify', source, 'Gang turf locked', 'success')
end, 'admin')

QBCore.Commands.Add('unlockTurf', 'Unlock a turf', { { name = 'id', help = 'Turf ID' } }, true, function(source, args)
    if not args or not args[1] then
        return
    end
    
    unlockTurf(args[1])
    TriggerClientEvent('QBCore:Notify', source, 'Gang turf unlocked', 'success')
end, 'admin')

QBCore.Commands.Add('updateTurfControlledBy', 'Update which gang controls a turf', { { name = 'id', help = 'Turf ID' }, { name = 'gang', help = 'Gang Name' }}, true, function(source, args)
    if not args or not args[1] or not args[2] then
        return
    end

    if not Config.AllowedGangs[args[2]] then
        return
    end

    updateTurfControlledBy(args[1], args[2])
    TriggerClientEvent('QBCore:Notify', source, 'Gang turf updated', 'success')
end, 'admin')


-- events
AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        print('dz-qb-turfs started')
        CreateThread(function()
            Wait(5000)
            loadTurfs()
        end)
    end
end)

AddEventHandler('playerDropped', function()
    CreateThread(function()
        Wait(500)
        local src = source
        RemoveResidentFromAllTurfs(Turfs, src)
    end)
end)

RegisterNetEvent('dz-qb-turfs:server:UpdateTurfResidents', function(turfID, isInside, data)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if not player or not player.PlayerData or not player.PlayerData.gang then
        return
    end
    if not IsGangAllowed(player.PlayerData.gang) then
        return
    end
   
    local playerGang = player.PlayerData.gang
    local turf, _ = GetTurfByID(Turfs, turfID)
    if not turf then
        return
    end
    if isInside then
        AddResidentToTurf(turf, src, playerGang, data)
    else
        RemoveResidentFromTurf(turf, src, playerGang)
    end
end)
