--====================================================================================
-- #Author: Jonathan D @ Gannon
--====================================================================================

RegisterNetEvent("gcPhone:yellow_getPagess")
AddEventHandler("gcPhone:yellow_getPagess", function(pagess)
  SendNUIMessage({event = 'yellow_pagess', pagess = pagess})
end)

RegisterNetEvent("gcPhone:yellow_newPagess")
AddEventHandler("gcPhone:yellow_newPagess", function(pages)
  SendNUIMessage({event = 'yellow_newPages', pages = pages})
end)

RegisterNetEvent("gcPhone:yellow_showError")
AddEventHandler("gcPhone:yellow_showError", function(title, message)
  SendNUIMessage({event = 'yellow_showError', message = message, title = title})
end)

RegisterNetEvent("gcPhone:yellow_showSuccess")
AddEventHandler("gcPhone:yellow_showSuccess", function(title, message)
  SendNUIMessage({event = 'yellow_showSuccess', message = message, title = title})
end)

RegisterNUICallback('yellow_getPagess', function(data, cb)
  TriggerServerEvent('gcPhone:yellow_getPagess', data.firstname, data.phone_number)
end)

RegisterNUICallback('yellow_postPages', function(data, cb)
  TriggerServerEvent('gcPhone:yellow_postPagess', data.firstname or '', data.phone_number or '', data.lastname or '', data.message)
end)

RegisterNUICallback('deleteYellow', function(data)
  TriggerServerEvent('gcPhone:deleteYellow', data.id)
end)



