-- Vehicles to enable/disable air control
local vehicleClassDisableControl = {
    [0] = true,     --compacts
    [1] = true,     --sedans
    [2] = true,     --SUV's
    [3] = true,     --coupes
    [4] = true,     --muscle
    [5] = true,     --sport classic
    [6] = true,     --sport
    [7] = true,     --super
    [8] = true,     --motorcycle
    [9] = true,     --offroad
    [10] = true,    --industrial
    [11] = true,    --utility
    [12] = true,    --vans
    [13] = true,    --bicycles
    [14] = false,   --boats
    [15] = false,   --helicopter
    [16] = false,   --plane
    [17] = true,    --service
    [18] = true,    --emergency
    [19] = true     --military
}

-- QBCore initialization
local QBCore = exports['qb-core']:GetCoreObject()

-- Main control thread
CreateThread(function()
    while true do
        Wait(0)

        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        -- Only check if player is in a valid vehicle
        if vehicle ~= 0 and vehicle ~= nil then
            local vehicleClass = GetVehicleClass(vehicle)
            
            -- Check if player is driver and vehicle class should have controls disabled
            if GetPedInVehicleSeat(vehicle, -1) == playerPed and vehicleClassDisableControl[vehicleClass] then
                local isInAir = IsEntityInAir(vehicle)
                local vehicleRoll = GetEntityRoll(vehicle)
                local vehicleSpeed = GetEntitySpeed(vehicle) * 3.6 -- Convert to km/h
                
                -- Combined condition for both scenarios:
                -- 1. Vehicle is in the air
                -- 2. OR vehicle is rolled over and almost stopped
                if isInAir or ((vehicleRoll > 75.0 or vehicleRoll < -75.0) and vehicleSpeed < 2.0) then
                    -- Disable left/right and up/down vehicle controls
                    DisableControlAction(0, 59, true) -- VehicleMoveLeftRight (A/D)
                    DisableControlAction(0, 60, true) -- VehicleMoveUpDown (W/S)
                    
                    -- Optional: Also disable arrow keys for vehicle control
                    DisableControlAction(0, 63, true) -- VehicleTurnLeftRight (LEFT/RIGHT)
                    DisableControlAction(0, 64, true) -- VehicleMoveUpDownOnly (UP/DOWN)
                end
            end
        end
    end
end)