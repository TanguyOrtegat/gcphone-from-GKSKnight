ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function MarketGetItem (accountId, cb)
  local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll([===[
      SELECT *
      FROM phone_shops
      ]===], {}, cb)
  end 


RegisterServerEvent('gcPhone:market_getItem')
AddEventHandler('gcPhone:market_getItem', function(phone_number, firstname)
  local sourcePlayer = tonumber(source)
    MarketGetItem(nil, function (markets)
      TriggerClientEvent('gcPhone:market_getItem', sourcePlayer, markets)
    end)
end)

RegisterServerEvent('gcPhone:buyMarket')
AddEventHandler('gcPhone:buyMarket', function(itemName, amount, price)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	amount = ESX.Math.Round(amount)

	-- is the player trying to exploit?
	if amount < 0 then
		print('gcphone: ' .. xPlayer.identifier .. ' is trying to exploit market..', itemName, amount, price)
		return
	end

	-- get price
	local itemLabel = ''

	price = price * amount

	-- can the player afford this item?
	if xPlayer.getBank() >= price then
		-- can the player carry the said amount of x item?
		-- if sourceItem.weight ~= -1 and (sourceItem.count + amount) > sourceItem.weight then
		if (sourceItem.count + amount) > sourceItem.limit then
			TriggerClientEvent('esx:showNotification', _source, "Vous n'avez pas assez d'inventaire!")
		else
			xPlayer.removeAccountMoney('bank', price)
            -- local time = 10 -- 10 seconds
            -- while (time ~= 0) do -- Whist we have time to wait
               -- Wait( 1000 ) -- Wait a second
               -- time = time - 1
		       -- TriggerClientEvent('esx:showNotification', _source, "Dolazi za " .. time)
               -- 1 Second should have past by now
            -- end
			xPlayer.addInventoryItem(itemName, amount)
			TriggerClientEvent('esx:showNotification', _source, "Compte déduit de: " .. price .. " $ ")
		end
	else
		local missingMoney = price - xPlayer.getBank()
		TriggerClientEvent('esx:showNotification', _source, "Vous n'avez pas assez d'argent, vous manque " .. missingMoney .. "$~s~!")
	end
end)

