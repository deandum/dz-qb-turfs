Config = {
    Debug = false, -- this shows the PZ around each turf

    CreateCheckpointAroundBattleZones = true, -- this will show a yellow checkpoint arround the battle zone for each turf
    CheckpointType = 47, -- the type of the checkpoint to be created
    CheckpointNearHeight = 0.1,
    CheckpointFarHeight = 0.1,

    AllowMultipleWars = false, -- enable this to allow more than just 1 turf war at a time

    RequiredGangMembers = 1, -- the min number of gang members required to start a war
    RequiredGangMemberRank = 2, -- the min rank level for a gang member to start a war

    TurfLockedTime = 300, -- 5 minutes lock after a turf is captured
    TurfPrepareTime = 60, -- 1 minute to prepare for a turf war
    TurfTotalCaptureCheckpoints = 10, -- the number of checkpoints to be completed before a turf is caputred and locked
    TurfTimeToCaptureCheckpoint = 5, -- 5 seconds between each capture checkpoint interval

    ControlledSprite = 674, -- blip sprite for controlled turfs
    HostileSprite = 84, -- blip sprite for hostile turfs
    
    PrepareStageSprite = 436, -- blip sprite for war prepare phase
    
    BattleStageSprite = 543, -- blip sprite for war battle phase
    BattleStageZoneColor = 4, -- blip zone color for war battle phase
    BattleStageSpriteColor = 1, -- blip sprite color for war battle phase
    
    CaptureStageSprite = 40, -- blip sprite for war captrue phase
    CaptureStageSpriteColor = 40, -- blip sprite color for war captrue phase

    -- table for whitelisted gangs
    AllowedGangs = {
        ['vagos'] = true,
        ['ballas'] = true,
    },

    -- table for gang colors
    GangColors = {
        ['vagos'] = 73,
        ['ballas'] = 83,
    },

    -- table for the HQ turf of each gang
    GangHQZones = {
        ['vagos'] = {
            coords = vector3(325.98, -2032.24, 20.92),
            radius = 100.0,
            mapSprite = 176,
            mapLabel = 'Vagos HQ'
        },
        ['ballas'] = {
            coords = vector3(101.22, -1939.02, 20.8),
            radius = 90.0,
            mapSprite = 176,
            mapLabel = 'Ballas HQ'
        },
    },

    -- table for avaiLabel gang turfs
    Turfs = {
        ['turf1'] = {
            coords = vector3(188.64, -1679.68, 29.67),
            fixer = {
                coords = vector4(182.92, -1688.83, 29.67, 231.51),
                model = 'g_m_y_ballasout_01',
                animation = 'WORLD_HUMAN_STAND_IMPATIENT',
            },
            radius = 90.0,
            checkpointZOffset = -1.0,
            label = 'Bishop\'s',
        },
        ['turf2'] = {
            coords = vector3(-474.54, -1706.93, 18.71),
            fixer = {
                coords = vector4(-456.61, -1734.28, 16.76, 287.1),
                model = 'g_m_y_ballasout_01',
                animation = 'WORLD_HUMAN_STAND_IMPATIENT',
            },
            radius = 100.0,
            checkpointZOffset = 0.0,
            label = 'Scrap Yard',
        },
    },

    -- table to sync the different war stages for each turf
    -- # DO NOT MODIFY THIS UNLESS YOU KNOW WHAT YOU ARE DOING.
    WarStages = {
        ['IDLE'] = 'idle',
        ['PREPARE'] = 'prepare',
        ['BATTLE'] = 'battle',
        ['CAPTURE'] = 'capture',
    },
}
