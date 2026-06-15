-- ================================================
--   CLIENT UI
-- ================================================

-- Close UI on Escape
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustReleased(0, 200) and isUIOpen then -- Escape
            isUIOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'closeUI' })
        end
    end
end)
