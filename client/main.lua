local QBCore = exports['qb-core']:GetCoreObject()


local HQTurf = nil
local Turfs = {}
local CurrentTurf = nil
local IsListeningForPlayerDeath = false
local PlayerGang = nil


-- functions
local function createGangHQZone()
    if HQTurf then
        return
    end

    if not PlayerGang or not IsGangAllowed(PlayerGang) then
        return
    end

    if not Config.GangHQZones[PlayerGang.name] then
        return
    end

    CreateThread(function()
        Wait(500)

        local gang = PlayerGang.name
        local gangHQ = Config.GangHQZones[gang]
        
        local zoneBlip = AddBlipForRadius(gangHQ.coords.x, gangHQ.coords.y, gangHQ.coords.z, gangHQ.radius)
        SetBlipAlpha(zoneBlip, 100)
        SetBlipColour(zoneBlip, Config.GangColors[gang])

        local mapIcon = AddBlipForCoord(gangHQ.coords.x, gangHQ.coords.y, gangHQ.coords.z)
        SetBlipSprite(mapIcon, gangHQ.mapSprite)
        SetBlipDisplay(mapIcon, 4)
        SetBlipAsShortRange(mapIcon, true)
        SetBlipColour(mapIcon, Config.GangColors[gang])
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(gangHQ.mapLabel)
        EndTextCommandSetBlipName(mapIcon)

        local targetZone = CircleZone:Create(gangHQ.coords, gangHQ.radius, {
            name = 'gangHQ:' .. gang,
            debugPoly = Config.Debug,
        })
        targetZone:onPlayerInOut(function(isPointInside)
            if isPointInside then
                QBCore.Functions.Notify('You feel powerful...', 'success')
            else
                QBCore.Functions.Notify('You feel unsafe...', 'error')
            end
        end)

        HQTurf = {}
        HQTurf['zoneBlip'] = zoneBlip
        HQTurf['mapIcon'] = mapIcon
        HQTurf['targetZone'] = targetZone
    end)
end

local function ListenForPlayerDeath()
    CreateThread(function()
        while true and IsListeningForPlayerDeath do
            if not PlayerGang or not IsGangAllowed(PlayerGang) then
                return
            end

            sleep = 1000
            if CurrentTurf then
                if IsEntityDead(PlayerPedId()) then
                    TriggerServerEvent('dz-qb-turfs:server:UpdateTurfResidents', CurrentTurf.ID, true, {isAlive = false})
                    IsListeningForPlayerDeath = false
                end
            end
            Wait(sleep)
        end
    end)
end

local function createTurfs()
    if not PlayerGang or not IsGangAllowed(PlayerGang) then
        return
    end

    CreateThread(function()
        Wait(500)

        QBCore.Functions.TriggerCallback('dz-qb-turfs:func:server:GetTurfs', function(turfs)
            if turfs and next(turfs) then
                for _, data in pairs(turfs) do
                    if data.coords then
                        local zoneBlip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, data.radius)
                        SetBlipAlpha(zoneBlip, 100)
                        SetBlipColour(zoneBlip, Config.GangColors[data.controlledBy])
                
                        local mapIcon = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
                        if data.controlledBy == PlayerGang.name then
                            SetBlipSprite(mapIcon, Config.ControlledSprite)
                        else
                            SetBlipSprite(mapIcon, Config.HostileSprite)
                        end
                        
                        SetBlipDisplay(mapIcon, 4)
                        SetBlipAsShortRange(mapIcon, true)
                        SetBlipColour(mapIcon, Config.GangColors[data.controlledBy])
                        BeginTextCommandSetBlipName('STRING')
                        AddTextComponentSubstringPlayerName('Gang Turf ' .. data.label)
                        EndTextCommandSetBlipName(mapIcon)
                
                        local targetZone = CircleZone:Create(data.coords, data.radius, {
                            name = 'turf:' .. data.label,
                            debugPoly = Config.Debug,
                        })
                        targetZone:onPlayerInOut(function(isPointInside)
                            if isPointInside then
                                if data.controlledBy == PlayerGang.name then
                                    QBCore.Functions.Notify('You feel powerful...', 'success')
                                else
                                    QBCore.Functions.Notify('You feel threatened...', 'error')
                                end
                                TriggerServerEvent('dz-qb-turfs:server:UpdateTurfResidents', data.ID, true, {isAlive = true})
                                CurrentTurf = data
                                IsListeningForPlayerDeath = true
                                ListenForPlayerDeath()
                            else
                                TriggerServerEvent('dz-qb-turfs:server:UpdateTurfResidents', data.ID, false)
                                CurrentTurf = nil
                                IsListeningForPlayerDeath = false
                            end
                        end)
                
                        Turfs[#Turfs+1] = {
                            ['zoneBlip'] = zoneBlip,
                            ['mapIcon'] = mapIcon,
                            ['targetZone'] = targetZone,
                            ['ID'] = data.ID,
                            ['warStage'] = data.warStage,
                        }
                    end
                end
            end
        end)
    end)
end

local function setPlayerGang()
    if IsGangAllowed(QBCore.Functions.GetPlayerData().gang) then
        PlayerGang = QBCore.Functions.GetPlayerData().gang
    else
        PlayerGang = nil
    end
end

local function cleanUp()
    if HQTurf then
        RemoveBlip(HQTurf.zoneBlip)
        RemoveBlip(HQTurf.mapIcon)
        HQTurf.targetZone:destroy()
    end

    HQTurf = nil
    PlayerGang = nil
end

local function deleteTurfs()
    if Turfs and next(Turfs) then
        for _, data in pairs(Turfs) do
            RemoveBlip(data.zoneBlip)
            RemoveBlip(data.mapIcon)
            data.targetZone:destroy()
        end
    end
    Turfs = {}
end


-- events
AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() == resource then
        print('dz-qb-turfs started')
        cleanUp()
        setPlayerGang()
        createGangHQZone()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
        print('dz-qb-turfs stopped')
        cleanUp()
        deleteTurfs()
    end
end)


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    setPlayerGang()
    createGangHQZone()
    if not Turfs or not next(Turfs) then
        createTurfs()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    QBCore.Functions.TriggerCallback('dz-qb-turfs:func:server:RemovePlayerFromAllTurfs', function() 
        cleanUp()
        deleteTurfs()
    end)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(updatedGangData)
    QBCore.Functions.TriggerCallback('dz-qb-turfs:func:server:RemovePlayerFromAllTurfs', function()
        cleanUp()
        setPlayerGang()
        createGangHQZone()
        deleteTurfs()
        createTurfs()
    end)
end)

RegisterNetEvent('dz-qb-turfs:client:LoadTurfs', function()
    if not PlayerGang or not IsGangAllowed(PlayerGang) then
        return
    end
    deleteTurfs()
    createTurfs()
end)

RegisterNetEvent('dz-qb-turfs:client:UpdateTurfWarStage', function(turfID, warStage)
    if not PlayerGang or not IsGangAllowed(PlayerGang) then
        return
    end

    if not Turfs or not next(Turfs) then
        return
    end

    local turf, _ = GetTurfByID(Turfs, turfID)
    if not turf then
        return
    end

    turf.warStage = warStage
    if warStage == Config.WarStages.PREPARE then
        QBCore.Functions.Notify('A new turf is about to start. Prepare for battle.', 'success')
        SetBlipSprite(turf.mapIcon, Config.PrepareStageSprite)
    end

    if warStage == Config.WarStages.BATTLE then
        QBCore.Functions.Notify('A new turf war has started.', 'success')
        SetBlipColour(turf.zoneBlip, Config.BattleStageZoneColor)
        SetBlipSprite(turf.mapIcon, Config.BattleStageSprite)
        SetBlipColour(turf.mapIcon, Config.BattleStageSpriteColor)
    end

    if warStage == Config.WarStages.CAPTURE then
        QBCore.Functions.Notify('A turf has ended.', 'success')
        SetBlipSprite(turf.mapIcon, Config.CaptureStageSprite)
        SetBlipColour(turf.mapIcon, Config.CaptureStageSpriteColor)
    end
end)

RegisterNetEvent('dz-qb-turfs:client:NotifyTurfCaptureProgress', function(turfID, currentCheckpoint, gangName)
    if not PlayerGang or not IsGangAllowed(PlayerGang) then
        return
    end

    if PlayerGang.name ~= gangName then
        return
    end

    if CurrentTurf.ID ~= tonumber(turfID) then
        return
    end

    QBCore.Functions.Notify('You are taking control of this turf: ' .. tostring(currentCheckpoint) .. '/' .. tostring(Config.TurfTotalCaptureCheckpoints) .. '.', 'success')
end)

RegisterNetEvent('dz-qb-turfs:client:NotifyRewardsReceived', function()
    QBCore.Functions.Notify('You have received a reward for winning the war.', 'success')
end)


-- threads
CreateThread(function()
    local sleep = 5000
    while not LocalPlayer.state.isLoggedIn do
        -- do nothing
        Wait(sleep)
    end

    while true do
        sleep = 1000

        if not PlayerGang or not IsGangAllowed(PlayerGang) then
            return
        end

        for _, turf in pairs(Turfs) do
            if turf.warStage == Config.WarStages.PREPARE then
                SetBlipFlashes(turf.mapIcon, true)
                SetBlipFlashInterval(turf.mapIcon, 1000)
            end

            if turf.warStage == Config.WarStages.BATTLE then
                SetBlipFlashes(turf.mapIcon, true)
                SetBlipFlashInterval(turf.mapIcon, 500)
            end

            if turf.warStage == Config.WarStages.CAPTURE then
                SetBlipFlashes(turf.mapIcon, true)
                SetBlipFlashInterval(turf.mapIcon, 1000)
            end
        end

        Wait(sleep)
    end
end)
