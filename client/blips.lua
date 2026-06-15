-- ================================================
--   CLIENT BLIPS
-- ================================================

CreateThread(function()
    if not Config.Blips.enabled then return end

    for _, blip in ipairs(Config.Blips) do
        local b = AddBlipForCoord(blip.coords.x, blip.coords.y, blip.coords.z)
        SetBlipSprite(b, blip.sprite)
        SetBlipColour(b, blip.color)
        SetBlipScale(b, blip.scale)
        SetBlipAsShortRange(b, true)
        SetBlipDisplay(b, blip.display)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(blip.label)
        EndTextCommandSetBlipName(b)
    end
end)
