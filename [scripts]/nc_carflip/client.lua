local Core = nil
local framework = nil
local PlayerJob = nil
local PlayerData = nil
lib.locale()

CreateThread(function()
    Wait(5)
    if GetResourceState(Config.ESXCoreName) == 'starting' or GetResourceState(Config.ESXCoreName) == 'started' then 
        framework = "ESX"
    end
    
    if GetResourceState(Config.QBFramework) == 'starting' or GetResourceState(Config.QBFramework) == 'started' then 
        framework = "QB"
    end
end)

CreateThread(function()
    Wait(5)

    if framework == "QB" then
        Core = exports[Config.QBFramework]:GetCoreObject()
        
        -- Initialize player data
        PlayerData = Core.Functions.GetPlayerData()
        PlayerJob = PlayerData.job
        
        -- Listen for job updates
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
            PlayerJob = job
        end)
        
        -- Register /flip command
        RegisterCommand('flip', function()
            if not HasPermission() then return end
            FlipCarOver()
        end, false)
        
        -- Also allow the original event for compatibility
        RegisterNetEvent('nc_carflip:flipcar')
        AddEventHandler('nc_carflip:flipcar', function()
            if not HasPermission() then return end
            FlipCarOver()
        end)

    elseif framework == "ESX" then
        -- ESX version
        ESX = exports[Config.ESXCoreName]:getSharedObject()
        
        -- Initialize player data
        PlayerData = ESX.GetPlayerData()
        PlayerJob = PlayerData.job
        
        -- Listen for job updates
        RegisterNetEvent('esx:setJob', function(job)
            PlayerJob = job
        end)
        
        -- Register /flip command
        RegisterCommand('flip', function()
            if not HasPermission() then return end
            FlipCarOver()
        end, false)
        
        -- Also allow the original event for compatibility
        RegisterNetEvent('nc_carflip:flipcar')
        AddEventHandler('nc_carflip:flipcar', function()
            if not HasPermission() then return end
            FlipCarOver()
        end)
    end
end)

-- Function to check if player has permission
function HasPermission()
    if not Config.whitelisted then
        return true -- Anyone can flip if whitelist is disabled
    end
    
    if not PlayerJob then return false end
    
    if PlayerJob.name == Config.whitelistedJob then
        if framework == "QB" then
            if PlayerJob.grade.level >= Config.whitelistedGrade then
                return true
            else
                lib.notify({
                    title = locale('notify.title'),
                    description = locale('notify.no_grade'),
                    type = 'error'
                })
                return false
            end
        elseif framework == "ESX" then
            if PlayerJob.grade >= Config.whitelistedGrade then
                return true
            else
                lib.notify({
                    title = locale('notify.title'),
                    description = locale('notify.no_grade'),
                    type = 'error'
                })
                return false
            end
        end
    else
        lib.notify({
            title = locale('notify.title'),
            description = locale('notify.no_permission'),
            type = 'error'
        })
        return false
    end
end

-- Main function to flip the car
function FlipCarOver()
    if not HasPermission() then return end
    
    local ped = PlayerPedId()
    local pedcoords = GetEntityCoords(ped)
    
    -- Get the closest vehicle
    local VehicleData = nil
    if framework == "QB" then
        VehicleData = Core.Functions.GetClosestVehicle()
    else
        VehicleData = GetClosestVehicle(pedcoords)
    end
    
    if not VehicleData or VehicleData == 0 then
        lib.notify({
            title = locale('notify.title'),
            description = locale('notify.no_vehicle'),
            type = 'error'
        })
        return
    end
    
    local finalDur = math.random(Config.minDuration or 5000, Config.maxDuration or 10000)
    local dist = #(pedcoords - GetEntityCoords(VehicleData))
    
    -- Check if player is close enough to the vehicle
    if dist > Config.maxFlipDistance then
        lib.notify({
            title = locale('notify.title'),
            description = locale('notify.too_far'),
            type = 'error'
        })
        return
    end
    
    -- Check if vehicle is already on all wheels
    if IsVehicleOnAllWheels(VehicleData) then
        lib.notify({
            title = locale('notify.title'),
            description = locale('notify.already_upright'),
            type = 'error'
        })
        return
    end
    
-- Start skill check
local success = lib.skillCheck({
    {areaSize = Config.areaSize, speedMultiplier = Config.speedMultiplier},   -- First check: Very easy and slow
    {areaSize = Config.areaSize, speedMultiplier = Config.speedMultiplier}    -- Second check: Easy and slow
}, {'x', 'x'})  

    if success then
        RequestAnimDict('missfinale_c2ig_11')
        while not HasAnimDictLoaded("missfinale_c2ig_11") do
            Wait(10)
        end
        
        lib.progressCircle({
            label = locale('notify.fliping'),
            duration = finalDur,
            position = Config.position,
            useWhileDead = Config.useWhileDead,
            canCancel = Config.canCancel,
            disable = {
                car = Config.disable,
            },
            anim = {
                dict = 'missfinale_c2ig_11',
                clip = 'pushcar_offcliff_m'
            },
        })
        
        -- Flip the vehicle
        local carCoords = GetEntityRotation(VehicleData, 2)
        SetEntityRotation(VehicleData, carCoords[1], 0, carCoords[3], 2, true)
        SetVehicleOnGroundProperly(VehicleData)
        
        lib.notify({
            id = '1',
            title = locale('notify.title'),
            description = locale('notify.desc'),
            position = Config.position,
            style = {
                backgroundColor = '#243661',
                color = '#909296'
            },
            icon = 'car',
            iconColor = '#C53030'
        })
        ClearPedTasks(ped)
    else
        -- Skill check failed
        lib.notify({
            title = locale('notify.title'),
            description = locale('notify.skill_fail'),
            type = 'error'
        })
    end
end

-- Helper function for ESX to get closest vehicle
function GetClosestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    
    for _, vehicle in pairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicle
            closestDistance = distance
        end
    end
    
    return closestVehicle
end