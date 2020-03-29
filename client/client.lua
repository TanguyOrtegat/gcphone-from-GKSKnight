--====================================================================================
-- #Author: Jonathan D @ Gannon
--====================================================================================
 local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}
-- Configuration
local KeyToucheCloseEvent = {
  { code = 172, event = 'ArrowUp' },
  { code = 173, event = 'ArrowDown' },
  { code = 174, event = 'ArrowLeft' },
  { code = 175, event = 'ArrowRight' },
  { code = 176, event = 'Enter' },
  { code = 177, event = 'Backspace' },
}
local KeyOpenClose = Keys["F2"] -- F2
local KeyTakeCall = Keys["E"] -- E
local KeySimMenu = Keys["N9"] -- N9
local menuIsOpen = false
local contacts = {}
local messages = {}
local myPhoneNumber = ''
local isDead = false
local USE_RTC = false
local useMouse = false
local ignoreFocus = false
local takePhoto = false
local hasFocus = false

local PhoneInCall = {}
local currentPlaySound = false
local soundDistanceMax = 8.0
local TokoVoipID = nil

--[[
  Ouverture du téphone lié a un item
  Un solution ESC basé sur la solution donnée par HalCroves
  https://forum.fivem.net/t/tutorial-for-gcphone-with-call-and-job-message-other/177904
--]]

ESX = nil
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
  end
end)
--====================================================================================
--  
--====================================================================================
AddEventHandler('gcphone:OpenSimMenu', function()
	OpenSimMenu()
end)

local simmenuopen = false
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if takePhoto ~= true then
      if IsControlJustPressed(1, KeyOpenClose) and GetLastInputMethod(2) and not simmenuopen then
		CheckPhone()
      -- elseif IsControlJustPressed(1, KeySimMenu) and GetLastInputMethod(2) and not menuIsOpen then
		-- OpenSimMenu()
			  
								
			 
			
      end
      if menuIsOpen == true then
        for _, value in ipairs(KeyToucheCloseEvent) do
          if IsControlJustPressed(1, value.code) and GetLastInputMethod(2) then
            SendNUIMessage({keyUp = value.event})
          end
        end
        if useMouse == true and hasFocus == ignoreFocus then
          local nuiFocus = not hasFocus
          SetNuiFocus(nuiFocus, nuiFocus)
          hasFocus = nuiFocus
        elseif useMouse == false and hasFocus == true then
          SetNuiFocus(false, false)
          hasFocus = false
        end
      else
        if hasFocus == true then
          SetNuiFocus(false, false)
          hasFocus = false
        end
      end
    end
  end
end)



--====================================================================================
--  Active ou Deactive une application (appName => config.json)
--====================================================================================
RegisterNetEvent('gcPhone:setEnableApp')
AddEventHandler('gcPhone:setEnableApp', function(appName, enable)
  SendNUIMessage({event = 'setEnableApp', appName = appName, enable = enable })
end)

--====================================================================================
--  Gestion des appels fixe
--====================================================================================
function startFixeCall (fixeNumber)
  local number = ''
  DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 10)
  while (UpdateOnscreenKeyboard() == 0) do
    DisableAllControlActions(0);
    Wait(0);
  end
  if (GetOnscreenKeyboardResult()) then
    number =  GetOnscreenKeyboardResult()
  end
  if number ~= '' then
    TriggerEvent('gcphone:autoCall', number, {
      useNumber = fixeNumber
    })
    PhonePlayCall(true)
  end
end

function TakeAppel (infoCall)
  TriggerEvent('gcphone:autoAcceptCall', infoCall)
end

RegisterNetEvent("gcPhone:notifyFixePhoneChange")
AddEventHandler("gcPhone:notifyFixePhoneChange", function(_PhoneInCall)
  PhoneInCall = _PhoneInCall
end)

--[[
  Affiche les imformations quant le joueurs est proche d'un fixe
--]]
function showFixePhoneHelper (coords)
  for number, data in pairs(FixePhone) do
    local dist = GetDistanceBetweenCoords(
      data.coords.x, data.coords.y, data.coords.z,
      coords.x, coords.y, coords.z, 1)
    if dist <= 2.0 then
      SetTextComponentFormat("STRING")
      AddTextComponentString("~g~" .. data.name .. ' ~o~' .. number .. '~n~~INPUT_PICKUP~~w~ Utiliser')
      DisplayHelpTextFromStringLabel(0, 0, 0, -1)
      if IsControlJustPressed(1, KeyTakeCall) and GetLastInputMethod(2) then
        startFixeCall(number)
      end
      break
    end
  end
end
 

Citizen.CreateThread(function ()
  local mod = 0
  while true do 
    local playerPed   = PlayerPedId()
    local coords      = GetEntityCoords(playerPed)
    local inRangeToActivePhone = false
    local inRangedist = 0
    for i, _ in pairs(PhoneInCall) do 
        local dist = GetDistanceBetweenCoords(
          PhoneInCall[i].coords.x, PhoneInCall[i].coords.y, PhoneInCall[i].coords.z,
          coords.x, coords.y, coords.z, 1)
        if (dist <= soundDistanceMax) then
          DrawMarker(1, PhoneInCall[i].coords.x, PhoneInCall[i].coords.y, PhoneInCall[i].coords.z,
              0,0,0, 0,0,0, 0.1,0.1,0.1, 0,255,0,255, 0,0,0,0,0,0,0)
          inRangeToActivePhone = true
          inRangedist = dist
          if (dist <= 1.5) then 
            SetTextComponentFormat("STRING")
            AddTextComponentString("~INPUT_PICKUP~ Décrocher")
            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
            if IsControlJustPressed(1, KeyTakeCall) and GetLastInputMethod(2) then
              PhonePlayCall(true)
              TakeAppel(PhoneInCall[i])
              PhoneInCall = {}
              StopSoundJS('ring2.ogg')
            end
          end
          break
        end
    end
    if inRangeToActivePhone == false then
      showFixePhoneHelper(coords)
    end
    if inRangeToActivePhone == true and currentPlaySound == false then
      PlaySoundJS('ring2.ogg', 0.2 + (inRangedist - soundDistanceMax) / -soundDistanceMax * 0.8 )
      currentPlaySound = true
    elseif inRangeToActivePhone == true then
      mod = mod + 1
      if (mod == 15) then
        mod = 0
        SetSoundVolumeJS('ring2.ogg', 0.2 + (inRangedist - soundDistanceMax) / -soundDistanceMax * 0.8 )
      end
    elseif inRangeToActivePhone == false and currentPlaySound == true then
      currentPlaySound = false
      StopSoundJS('ring2.ogg')
    end
    Citizen.Wait(0)
  end
end)


function PlaySoundJS (sound, volume)
  SendNUIMessage({ event = 'playSound', sound = sound, volume = volume })
end

function SetSoundVolumeJS (sound, volume)
  SendNUIMessage({ event = 'setSoundVolume', sound = sound, volume = volume})
end

function StopSoundJS (sound)
  SendNUIMessage({ event = 'stopSound', sound = sound})
end












RegisterNetEvent("gcPhone:forceOpenPhone")
AddEventHandler("gcPhone:forceOpenPhone", function(_myPhoneNumber)
  if menuIsOpen == false then
    TooglePhone()
  end
end)
 
--====================================================================================
--  Events
--====================================================================================
RegisterNetEvent("gcPhone:myPhoneNumber")
AddEventHandler("gcPhone:myPhoneNumber", function(_myPhoneNumber)
  myPhoneNumber = _myPhoneNumber
  SendNUIMessage({event = 'updateMyPhoneNumber', myPhoneNumber = myPhoneNumber})
end)

RegisterNetEvent("gcPhone:contactList")
AddEventHandler("gcPhone:contactList", function(_contacts)
  SendNUIMessage({event = 'updateContacts', contacts = _contacts})
  contacts = _contacts
end)

RegisterNetEvent("gcPhone:allMessage")
AddEventHandler("gcPhone:allMessage", function(allmessages)
  SendNUIMessage({event = 'updateMessages', messages = allmessages})
  messages = allmessages
end)

RegisterNetEvent("gcPhone:getBourse")
AddEventHandler("gcPhone:getBourse", function(bourse)
  SendNUIMessage({event = 'updateBourse', bourse = bourse})
end)



RegisterNetEvent("gcPhone:receiveMessage")
AddEventHandler("gcPhone:receiveMessage", function(message)
  -- SendNUIMessage({event = 'updateMessages', messages = messages})
  SendNUIMessage({event = 'newMessage', message = message})
  table.insert(messages, message)
  if message.owner == 0 then
    local text = '~o~Nouveau message'
    if ShowNumberNotification == true then
      text = '~o~Nouveau message du ~y~'.. message.transmitter
      for _,contact in pairs(contacts) do
        if contact.number == message.transmitter then
          text = '~o~Nouveau message de ~g~'.. contact.display
          break
        end
      end
    end
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
    PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
    Citizen.Wait(300)
    PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
    Citizen.Wait(300)
    PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
  end
end)

--====================================================================================
--  Function client | Contacts
--====================================================================================
function addContact(display, num) 
    TriggerServerEvent('gcPhone:addContact', display, num)
end

function deleteContact(num) 
    TriggerServerEvent('gcPhone:deleteContact', num)
end
--====================================================================================
--  Function client | Messages
--====================================================================================
function sendMessage(num, message)
  TriggerServerEvent('gcPhone:sendMessage', num, message)
end

function deleteMessage(msgId)
  TriggerServerEvent('gcPhone:deleteMessage', msgId)
  for k, v in ipairs(messages) do 
    if v.id == msgId then
      table.remove(messages, k)
      SendNUIMessage({event = 'updateMessages', messages = messages})
      return
    end
  end
end

function deleteMessageContact(num)
  TriggerServerEvent('gcPhone:deleteMessageNumber', num)
end

function deleteAllMessage()
  TriggerServerEvent('gcPhone:deleteAllMessage')
end

function setReadMessageNumber(num)
  TriggerServerEvent('gcPhone:setReadMessageNumber', num)
  for k, v in ipairs(messages) do 
    if v.transmitter == num then
      v.isRead = 1
    end
  end
end

function requestAllMessages()
  TriggerServerEvent('gcPhone:requestAllMessages')
end

function requestAllContact()
  TriggerServerEvent('gcPhone:requestAllContact')
end

RegisterNetEvent("gcPhone:getlicense")
AddEventHandler("gcPhone:getlicense", function(license)
	print(ESX.DumpTable(license))
  SendNUIMessage({event = 'updateLicense', license = license})
end)

--====================================================================================
--  Function client | Appels
--====================================================================================
local aminCall = false
local inCall = false

RegisterNetEvent("gcPhone:waitingCall")
AddEventHandler("gcPhone:waitingCall", function(infoCall, initiator)
  SendNUIMessage({event = 'waitingCall', infoCall = infoCall, initiator = initiator})
  if initiator == true then
    PhonePlayCall()
    if menuIsOpen == false then
      TooglePhone()
    end
  end
end)

RegisterNetEvent("gcPhone:acceptCall")
AddEventHandler("gcPhone:acceptCall", function(infoCall, initiator)
  if inCall == false and USE_RTC == false then
    inCall = true
    -- NetworkSetVoiceChannel(infoCall.id + 1)
    -- NetworkSetTalkerProximity(0.0)
	local number = tonumber("9999"..infoCall.id + 120)
	exports.tokovoip_script:addPlayerToRadio(number)
	TokoVoipID = number				
  end
  if menuIsOpen == false then 
    TooglePhone()
  end
  PhonePlayCall()
  SendNUIMessage({event = 'acceptCall', infoCall = infoCall, initiator = initiator})
end)

RegisterNetEvent("gcPhone:rejectCall")
AddEventHandler("gcPhone:rejectCall", function(infoCall)
  if inCall == true then
    inCall = false
    Citizen.InvokeNative(0xE036A705F989E049)
    -- NetworkSetTalkerProximity(2.5)
	exports.tokovoip_script:removePlayerFromRadio(TokoVoipID)
	TokoVoipID = nil		 
  end
  PhonePlayText()
  SendNUIMessage({event = 'rejectCall', infoCall = infoCall})
end)


RegisterNetEvent("gcPhone:historiqueCall")
AddEventHandler("gcPhone:historiqueCall", function(historique)
  SendNUIMessage({event = 'historiqueCall', historique = historique})
end)


function startCall (phone_number, rtcOffer, extraData)
  TriggerServerEvent('gcPhone:startCall', phone_number, rtcOffer, extraData)
end

function acceptCall (infoCall, rtcAnswer)
  TriggerServerEvent('gcPhone:acceptCall', infoCall, rtcAnswer)
end

function rejectCall(infoCall)
  TriggerServerEvent('gcPhone:rejectCall', infoCall)
end

function ignoreCall(infoCall)
  TriggerServerEvent('gcPhone:ignoreCall', infoCall)
end

function requestHistoriqueCall() 
  TriggerServerEvent('gcPhone:getHistoriqueCall')
end

function appelsDeleteHistorique (num)
  TriggerServerEvent('gcPhone:appelsDeleteHistorique', num)
end

function appelsDeleteAllHistorique ()
  TriggerServerEvent('gcPhone:appelsDeleteAllHistorique')
end
  

--====================================================================================
--  Event NUI - Appels
--====================================================================================

RegisterNUICallback('startCall', function (data, cb)
  startCall(data.numero, data.rtcOffer, data.extraData)
  cb()
end)

RegisterNUICallback('acceptCall', function (data, cb)
  acceptCall(data.infoCall, data.rtcAnswer)
  cb()
end)
RegisterNUICallback('rejectCall', function (data, cb)
  rejectCall(data.infoCall)
  cb()
end)

RegisterNUICallback('ignoreCall', function (data, cb)
  ignoreCall(data.infoCall)
  cb()
end)

RegisterNUICallback('notififyUseRTC', function (use, cb)
  USE_RTC = use
  if USE_RTC == true and inCall == true then
    inCall = false
    -- Citizen.InvokeNative(0xE036A705F989E049)
    -- NetworkSetTalkerProximity(2.5)
	exports.tokovoip_script:removePlayerFromRadio(TokoVoipID)
	TokoVoipID = nil			 
  end
  cb()
end)


RegisterNUICallback('onCandidates', function (data, cb)
  TriggerServerEvent('gcPhone:candidates', data.id, data.candidates)
  cb()
end)

RegisterNetEvent("gcPhone:candidates")
AddEventHandler("gcPhone:candidates", function(candidates)
  SendNUIMessage({event = 'candidatesAvailable', candidates = candidates})
end)



RegisterNetEvent('gcphone:autoCall')
AddEventHandler('gcphone:autoCall', function(number, extraData)
  if number ~= nil then
    SendNUIMessage({ event = "autoStartCall", number = number, extraData = extraData})
  end
end)

RegisterNetEvent('gcphone:autoCallNumber')
AddEventHandler('gcphone:autoCallNumber', function(data)
  TriggerEvent('gcphone:autoCall', data.number)
end)

RegisterNetEvent('gcphone:autoAcceptCall')
AddEventHandler('gcphone:autoAcceptCall', function(infoCall)
  SendNUIMessage({ event = "autoAcceptCall", infoCall = infoCall})
end)





























































--====================================================================================
--  Gestion des evenements NUI
--==================================================================================== 
RegisterNUICallback('log', function(data, cb)
  print(data)
  cb()
end)
RegisterNUICallback('focus', function(data, cb)
  cb()
end)
RegisterNUICallback('blur', function(data, cb)
  cb()
end)
RegisterNUICallback('reponseText', function(data, cb)
  local limit = data.limit or 255
  local text = data.text or ''
  
  DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", text, "", "", "", limit)
  while (UpdateOnscreenKeyboard() == 0) do
      DisableAllControlActions(0);
      Wait(0);
  end
  if (GetOnscreenKeyboardResult()) then
      text = GetOnscreenKeyboardResult()
  end
  cb(json.encode({text = text}))
end)
--====================================================================================
--  Event - Messages
--====================================================================================
RegisterNUICallback('getMessages', function(data, cb)
  cb(json.encode(messages))
end)
RegisterNUICallback('sendMessage', function(data, cb)
  if data.message == '%pos%' then
    local myPos = GetEntityCoords(PlayerPedId())
    data.message = 'GPS: ' .. myPos.x .. ', ' .. myPos.y
  end
  TriggerServerEvent('gcPhone:sendMessage', data.phoneNumber, data.message)
end)
RegisterNUICallback('deleteMessage', function(data, cb)
  deleteMessage(data.id)
  cb()
end)
RegisterNUICallback('deleteMessageNumber', function (data, cb)
  deleteMessageContact(data.number)
  cb()
end)
RegisterNUICallback('deleteAllMessage', function (data, cb)
  deleteAllMessage()
  cb()
end)
RegisterNUICallback('setReadMessageNumber', function (data, cb)
  setReadMessageNumber(data.number)
  cb()
end)
--====================================================================================
--  Event - Contacts
--====================================================================================
RegisterNUICallback('addContact', function(data, cb) 
  TriggerServerEvent('gcPhone:addContact', data.display, data.phoneNumber)
end)
RegisterNUICallback('updateContact', function(data, cb)
  TriggerServerEvent('gcPhone:updateContact', data.id, data.display, data.phoneNumber)
end)
RegisterNUICallback('deleteContact', function(data, cb)
  TriggerServerEvent('gcPhone:deleteContact', data.id)
end)
RegisterNUICallback('getContacts', function(data, cb)
  cb(json.encode(contacts))
end)
RegisterNUICallback('setGPS', function(data, cb)
  SetNewWaypoint(tonumber(data.x), tonumber(data.y))
  cb()
end)

-- Add security for event (leuit#0100)
RegisterNUICallback('callEvent', function(data, cb)
  local eventName = data.eventName or ''
  if string.match(eventName, 'gcphone') then
    if data.data ~= nil then 
      TriggerEvent(data.eventName, data.data)
    else
      TriggerEvent(data.eventName)
    end
  else
    print('Event not allowed')
  end
  cb()
end)
RegisterNUICallback('callEvent', function(data, cb)
  local plyPos = GetEntityCoords(GetPlayerPed(-1), true)
  if data.eventName ~= 'cancel' then
	if data.data ~= nil then 
		--TriggerServerEvent("call:makeCall", "police", {x=plyPos.x,y=plyPos.y,z=plyPos.z},ResultMotifAdd,GetPlayerServerId(player))
		TriggerServerEvent("call:makeCall", data.eventName, {x=plyPos.x,y=plyPos.y,z=plyPos.z}, data.data, GetPlayerServerId(player))
		if data.eventName == "police" then
			TriggerServerEvent('phone:call', "police", data.data, plyPos['x'], plyPos['y'], plyPos['z'])
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé la ~b~Police","CHAR_CALL911","POLICE")
		elseif data.eventName == "taxi" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Taxi","CHAR_TAXI","TAXI")
		elseif data.eventName == "mecano" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Dépanneur","CHAR_CARSITE3","MECANO")
		elseif data.eventName == "ftnews" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Journaliste","CHAR_LIFEINVADER","FTNEWS") 
		elseif data.eventName == "ambulance" then
			TriggerServerEvent('phone:call', "ambulance", data.data, plyPos['x'], plyPos['y'], plyPos['z'])
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé les ~b~URGENCES","CHAR_CALL911","LSMC")
		elseif data.eventName == "foodtruck" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Foodtruck","CHAR_PROPERTY_BAR_COCKOTOOS","FOODTRUCK") 
		elseif data.eventName == "lawyer" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Avocat","CHAR_MINOTAUR","AVOCAT")
		elseif data.eventName == "airlines" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Pilote Airlines","CHAR_BOATSITE2","AIRLINES")  
		elseif data.eventName == "bus" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Chauffeur de Bus","CHAR_PEGASUS_DELIVERY","BUS")
		elseif data.eventName == "airdealer" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Concessionaire Avion","CHAR_BOATSITE2","CONCESSIONAIRE")
		elseif data.eventName == "brinks" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Transporteur de fond", "CHAR_BANK_FLEECA", "BRINKS")
		elseif data.eventName == "banker" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~banquier","CHAR_BANK_MAZE","BANQUE")
		elseif data.eventName == "dock" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Concessionaire Bateau","CHAR_BOATSITE","CONCESSIONAIRE")
		elseif data.eventName == "realestateagent" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Agent Immobilier","CHAR_ACTING_UP","IMMOBILIER")
		elseif data.eventName == "state" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Gouvernement","CHAR_EPSILON","MAIRIE")
		elseif data.eventName == "cardealer" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Concessionaire Voiture","CHAR_CARSITE","CONCESSIONAIRE") 
		elseif data.eventName == "biker" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Marchand Armes","CHAR_AMMUNATION","AMMUNATION")	
		elseif data.eventName == "fermier" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Fermier","CHAR_MP_MERRYWEATHER","FERMIER")			   
		elseif data.eventName == "unicorn" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Unicorn","CHAR_MP_STRIPCLUB_PR","UNICORN")			   
		elseif data.eventName == "brewer" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé les ~b~Brasseurs","CHAR_CHAT_CALL","BRASSEUR")	
		elseif data.eventName == "trucker" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Epicier","CHAR_CHAT_CALL","TRUCKER")			   
		elseif data.eventName == "firefighter" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé les ~b~Pompier","CHAR_CALL911","FIREFIGHTER")			   
		elseif data.eventName == "staff" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~staff","CHAR_CHAT_CALL","STAFF")	
		elseif data.eventName == "fuel" then
			TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~LSPI","CHAR_MICHAEL","LSPI")		   
		end	
	else
		local limit = data.limit or 255
		local text = data.text or ''
		if data.eventName ~= "RESPAWN" then
			DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", text, "", "", "", limit)
			while (UpdateOnscreenKeyboard() == 0) do
				DisableAllControlActions(0);
				Wait(0);
			end
			if (GetOnscreenKeyboardResult()) then
				text = GetOnscreenKeyboardResult()
			end
				TriggerServerEvent("call:makeCall", data.eventName, {x=plyPos.x,y=plyPos.y,z=plyPos.z}, text, GetPlayerServerId(player))
			if data.eventName == "police" then
				TriggerServerEvent('phone:call', "police", text, plyPos['x'], plyPos['y'], plyPos['z'])
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé la ~b~Police","CHAR_CALL911","POLICE")
			elseif data.eventName == "taxi" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Taxi","CHAR_TAXI","TAXI")
			elseif data.eventName == "mecano" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Dépanneur","CHAR_CARSITE3","MECANO")
			elseif data.eventName == "ftnews" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Journaliste","CHAR_LIFEINVADER","FTNEWS") 
			elseif data.eventName == "ambulance" then
				TriggerServerEvent('phone:call', "ambulance", text, plyPos['x'], plyPos['y'], plyPos['z'])
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé les ~b~URGENCES","CHAR_CALL911","LSMC")
			elseif data.eventName == "foodtruck" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Foodtruck","CHAR_PROPERTY_BAR_COCKOTOOS","FOODTRUCK") 
			elseif data.eventName == "lawyer" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Avocat","CHAR_MINOTAUR","AVOCAT")
			elseif data.eventName == "airlines" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Pilote Airlines","CHAR_BOATSITE2","AIRLINES")  
			elseif data.eventName == "bus" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Chauffeur de Bus","CHAR_PEGASUS_DELIVERY","BUS")
			elseif data.eventName == "airdealer" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Concessionaire Avion","CHAR_BOATSITE2","CONCESSIONAIRE")
			elseif data.eventName == "brinks" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Transporteur de fond", "CHAR_BANK_FLEECA", "BRINKS")
			elseif data.eventName == "banker" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~banquier","CHAR_BANK_MAZE","BANQUE")
			elseif data.eventName == "dock" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Concessionaire Bateau","CHAR_BOATSITE","CONCESSIONAIRE")
			elseif data.eventName == "realestateagent" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé un ~b~Agent Immobilier","CHAR_ACTING_UP","IMMOBILIER")
			elseif data.eventName == "state" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Gouvernement","CHAR_EPSILON","MAIRIE")
			elseif data.eventName == "cardealer" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Concessionaire Voiture","CHAR_CARSITE","CONCESSIONAIRE") 
			elseif data.eventName == "biker" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Marchand Armes","CHAR_AMMUNATION","AMMUNATION")	
			elseif data.eventName == "fermier" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Fermier","CHAR_MP_MERRYWEATHER","FERMIER")			   
			elseif data.eventName == "unicorn" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Unicorn","CHAR_MP_STRIPCLUB_PR","UNICORN")			   
			elseif data.eventName == "brewer" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~Tequilala","CHAR_PROPERTY_BAR_TEQUILALA","TEQUILA")	
			elseif data.eventName == "trucker" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé l' ~b~Epicier","CHAR_MP_MERRYWEATHER","TRUCKER")		   
			elseif data.eventName == "firefighter" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé les ~b~Pompiers","CHAR_CALL911","FIREFIGHTER")		   
			elseif data.eventName == "bahamas" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~bahamas","CHAR_MICHAEL","BAHAMAS")	
			elseif data.eventName == "fuel" then
				TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~LSPI","CHAR_MICHAEL","LSPI")			   
				-- elseif data.eventName == "staff" then
				-- TriggerEvent('esx_extended:showNotification',"~h~Vous avez appelé le ~b~staff","CHAR_CHAT_CALL","STAFF")		   
			end
		else
			TriggerEvent('esx_ambulancejob:respawnbutton')
		end
	end
    cb()
  end
end)



RegisterNUICallback('useMouse', function(um, cb)
  useMouse = um
end)
RegisterNUICallback('deleteALL', function(data, cb)
  TriggerServerEvent('gcPhone:deleteALL')
  cb()
end)



function TooglePhone() 
  menuIsOpen = not menuIsOpen
  SendNUIMessage({show = menuIsOpen})
  if menuIsOpen == true then 
    PhonePlayIn()
  else
    PhonePlayOut()
  end
end
RegisterNUICallback('faketakePhoto', function(data, cb)
  menuIsOpen = false
  SendNUIMessage({show = false})
  cb()
  TriggerEvent('camera:open')
end)

RegisterNUICallback('closePhone', function(data, cb)
  menuIsOpen = false
  SendNUIMessage({show = false})
  PhonePlayOut()
  SetNuiFocus(false, false)
  cb()
end)




----------------------------------
---------- GESTION APPEL ---------
----------------------------------
RegisterNUICallback('appelsDeleteHistorique', function (data, cb)
  appelsDeleteHistorique(data.numero)
  cb()
end)
RegisterNUICallback('appelsDeleteAllHistorique', function (data, cb)
  appelsDeleteAllHistorique(data.infoCall)
  cb()
end)


----------------------------------
---------- GESTION VIA WEBRTC ----
----------------------------------
AddEventHandler('onClientResourceStart', function(res)
  DoScreenFadeIn(300)
  if res == "gcphone" then
      TriggerServerEvent('gcPhone:allUpdate')
  end
end)


RegisterNUICallback('setIgnoreFocus', function (data, cb)
  ignoreFocus = data.ignoreFocus
  cb()
end)















RegisterNUICallback('takePhoto', function(data, cb)
	CreateMobilePhone(1)
  CellCamActivate(true, true)
  takePhoto = true
  Citizen.Wait(0)
  if hasFocus == true then
    hasFocus = false
  end
	while takePhoto do
    Citizen.Wait(0)

		if IsControlJustPressed(1, 27)  and GetLastInputMethod(2) then -- Toogle Mode
			frontCam = not frontCam
			CellFrontCamActivate(frontCam)
    elseif IsControlJustPressed(1, 177)  and GetLastInputMethod(2) then -- CANCEL
      DestroyMobilePhone()
      CellCamActivate(false, false)
      cb(json.encode({ url = nil }))
      takePhoto = false
      break
    elseif IsControlJustPressed(1, 176)  and GetLastInputMethod(2) then -- TAKE.. PIC
			exports['screenshot-basic']:requestScreenshotUpload(data.url, data.field, function(data)
        --local resp = json.decode(data)
        DestroyMobilePhone()
        CellCamActivate(false, false)
        cb(json.encode({ url = data }))
      end)
      takePhoto = false
		end
		HideHudComponentThisFrame(7)
		HideHudComponentThisFrame(8)
		HideHudComponentThisFrame(9)
		HideHudComponentThisFrame(6)
		HideHudComponentThisFrame(19)
    HideHudAndRadarThisFrame()
  end
  Citizen.Wait(1000)
  PhonePlayAnim('text', false, true)
end)



--  =======  sim

function table.empty (self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function OpenSimMenu()
	simmenuopen = true
	ESX.UI.Menu.CloseAll()
		ESX.TriggerServerCallback('esx_cartesim:GetList', function(sim)
		  local elements = {}
		  if not table.empty(sim) then
			for _,v in pairs(sim) do  
			  table.insert(elements, {label = tostring(v.label), value = v})			  
			end
		  else
		    table.insert(elements, {label = "Pas de carte sim enregistré", value = nil})
		  end
		
		  ESX.UI.Menu.Open(
		  'default', GetCurrentResourceName(), 'sim_list',
		  {
			  title    = 'Liste des cartes sim',
			  align    = 'top-left',
			  elements = elements,
		  },
		  function(data, menu)
			if data.current.value ~= nil then
				local elements2 = {
					{label = 'Utiliser', value = 'sim_use'},
					{label = 'Renommer', value = 'sim_rename'},
					{label = 'Donner', value = 'sim_give'},
					{label = 'Jeter', value = 'sim_delete'}
				  }
		  
				  ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'sim_change', {
					title    = "Que voulez vous faire de cette carte sim?",
					align    = 'top-left',
					elements = elements2,
		  
				  }, 
				  function(data2, menu2)
		  
					if data2.current.value == 'sim_use' then
						ESX.UI.Menu.CloseAll()
						TriggerServerEvent('esx_cartesim:sim_use', data.current.value.number)
						ESX.ShowNotification("Vous avez activé la carte sim ~o~" .. data.current.value.number)
						menu2.close()
						simmenuopen = false
					elseif data2.current.value == 'sim_rename' then
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'rename_simcard', {
							title = 'Nom de carte sim souhaité'
						}, function(data3, menu3)
							local text = tostring(data3.value)
							TriggerServerEvent("esx_cartesim:sim_rename", data.current.value.id, text)
							ESX.ShowNotification("Vous avez renommer "..data.current.value.label.." en "..text)
							TriggerServerEvent('gcphone:allUpdate')
							OpenSimMenu()
						end, function(data3, menu3)
							menu3.close()
						end)
					elseif data2.current.value == 'sim_give' then
						ESX.UI.Menu.CloseAll()
						local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
						if closestPlayer ~= -1 and closestDistance <= 3.0 then
						    if IsPedSittingInAnyVehicle(closestPlayer) then
								ESX.ShowNotification('~r~Vous ne pouvez pas donner quelque chose à quelqu\'un dans un véhicule')
								return
							end
							if myPhoneNumber == data.current.value.number then
								TriggerServerEvent('esx_cartesim:sim_give', data.current.value.id, GetPlayerServerId(closestPlayer), true)
							else
								TriggerServerEvent('esx_cartesim:sim_give', data.current.value.id, GetPlayerServerId(closestPlayer), false)
							end
						else
							ESX.ShowNotification('Aucun joueur à proximité')
						end
						TriggerServerEvent('gcphone:allUpdate')
						ESX.UI.Menu.CloseAll()
						OpenSimMenu()
					elseif data2.current.value == 'sim_delete' then
						TriggerServerEvent('esx_cartesim:sim_delete', data.current.value.id)
						ESX.ShowNotification("Vous avez supprimé la carte sim ~o~" .. data.current.value.label)
						TriggerServerEvent('gcphone:allUpdate')
						OpenSimMenu()
					end
				  end, function(data2, menu2)
					menu2.close()
					simmenuopen = false
				  end)
			  end
	  
			  end,
			  function(data, menu)
				  menu.close()
				  simmenuopen = false
			  end
		  )
	end)  
end

RegisterCommand('fairyphone', function()
  CheckPhone()
end, false)

function CheckPhone()
	if myPhoneNumber ~= 'nil' and myPhoneNumber ~= nil and tonumber(myPhoneNumber) ~= 0 and myPhoneNumber ~= '' then
	  ESX.TriggerServerCallback('gcphone:getItemAmount', function(qtty)
			  if qtty > 0 then
			TriggerServerEvent("gcphone:allUpdate")
			TooglePhone()
			--menuIsOpen = true
			-- k = ESX.GetPlayerData().accounts[1].money
			-- SendNUIMessage({event = 'updateBankbalance', banking = k})
		  else
			--UpMiniMapNotification("Pas de ~r~téléphone~s~")
			TriggerEvent('esx_extended:showNotification', "Pas de ~r~téléphone~s~", 'CHAR_CHAT_CALL','LS Telecom')
		  end
	  end, 'phone')
	else
	  -- UpMiniMapNotification("Pas de ~r~carte sim lié~s~, F1 ou en acheter une")
	  TriggerEvent('esx_extended:showNotification', "Pas de ~r~carte sim lié~s~, N9 ou en acheter une", 'CHAR_CHAT_CALL','LS Telecom')
	end
end