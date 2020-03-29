ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function FaturaGetBilling (accountId, cb)
  local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll([===[
      SELECT * FROM billing WHERE identifier = @identifier
      ]===], { ['@identifier'] = xPlayer.identifier }, cb)
  end 

function getUserFatura(phone_number, firstname, cb)
  MySQL.Async.fetchAll("SELECT firstname, phone_number FROM users WHERE users.firstname = @firstname AND users.phone_number = @phone_number", {
    ['@phone_number'] = phone_number,
	['@firstname'] = firstname
  }, function (data)
    cb(data[1])
  end)
end

RegisterServerEvent('gcPhone:fatura_getBilling')
AddEventHandler('gcPhone:fatura_getBilling', function(phone_number, firstname)
  local sourcePlayer = tonumber(source)
  if phone_number ~= nil and phone_number ~= "" and firstname ~= nil and firstname ~= "" then
    getUserFatura(phone_number, firstname, function (user)
      local accountId = user and user.id
      FaturaGetBilling(accountId, function (billingg)
        TriggerClientEvent('gcPhone:fatura_getBilling', sourcePlayer, billingg)
      end)
    end)
  else
    FaturaGetBilling(nil, function (billingg)
      TriggerClientEvent('gcPhone:fatura_getBilling', sourcePlayer, billingg)
    end)
  end
end)


RegisterServerEvent("gcPhone:faturapayBill")
AddEventHandler("gcPhone:faturapayBill", function(id, sender, amount, target, sharedAccountName)
	local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromIdentifier(sender)
	local xPlayers    = ESX.GetPlayers()
	local foundPlayer = nil
	for i=1, #xPlayers, 1 do
		local xPlayer2 = ESX.GetPlayerFromId(xPlayers[i])		
		if xPlayer2.identifier == sender then
			foundPlayer = xPlayer2
			break
		end
	end
	if string.sub(target, 0, 6) == "steam:" then
		if foundPlayer ~= nil then
			if xPlayer.getMoney() >= amount then
				MySQL.Async.execute(
					'DELETE from billing WHERE id = @id',
					{
						['@id'] = id
					},
					function(rowsChanged)
						xPlayer.removeMoney(amount)
						foundPlayer.addMoney(amount)
						TriggerClientEvent('esx:showNotification', xPlayer.source, "vous avez ~g~payé~s~ une facture de ~r~$" .. amount)
						TriggerClientEvent('esx:showNotification', foundPlayer.source, 'vous avez ~g~reçu~s~ un paiement de ~g~$' .. amount)
					end
				)
			else
				TriggerClientEvent('esx:showNotification', xPlayer.source, "Tu n'as pas assez d'argent pour payer cette facture")
				if foundPlayer ~= nil then
					TriggerClientEvent('esx:showNotification', foundPlayer.source, "Le joueur ~r~n'a pas~w~ assez d'argent pour payer la facture!")
				end
			end
		else
			TriggerClientEvent('esx:showNotification', xPlayer.source, 'le joueur n\'est pas connecté')
		end
	else
		TriggerEvent('esx_addonaccount:getSharedAccount', target, function(account)
			if xPlayer.getAccount('bank').money >= amount then
				MySQL.Async.execute(
					'DELETE from billing WHERE id = @id',
					{
						['@id'] = id
					},
					function(rowsChanged)
						xPlayer.removeAccountMoney('bank', amount)
						account.addMoney(amount)
						TriggerClientEvent('esx:showNotification', xPlayer.source, "vous avez ~g~payé~s~ une facture de ~r~$" .. amount)
						if foundPlayer ~= nil then
							TriggerClientEvent('esx:showNotification', foundPlayer.source, 'vous avez ~g~reçu~s~ un paiement de ~g~$' .. amount)
						end
					end
				)
			else
				TriggerClientEvent('esx:showNotification', xPlayer.source, "Tu n'as pas assez d'argent pour payer cette facture")
				if foundPlayer ~= nil then
					TriggerClientEvent('esx:showNotification', foundPlayer.source, "Le joueur ~r~n'a pas~w~ assez d'argent pour payer la facture!")
				end
			end
		end)
	end
end)
