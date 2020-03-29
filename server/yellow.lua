function YellowGetPagess (accountId, cb)
  if accountId == nil then
    MySQL.Async.fetchAll([===[
      SELECT *
      FROM yellow_tweets
      ORDER BY time DESC LIMIT 30
      ]===], {}, cb)
  end
end

function getUserYellow(phone_number, firstname, cb)
  MySQL.Async.fetchAll("SELECT firstname, phone_number FROM users WHERE users.firstname = @firstname AND users.phone_number = @phone_number", {
    ['@phone_number'] = phone_number,
	['@firstname'] = firstname
  }, function (data)
    cb(data[1])
  end)
end


function YellowPostPages (phone_number, firstname, lastname, message, sourcePlayer, cb)
    getUserYellow(phone_number, firstname, function (user)
    if user == nil then
      if sourcePlayer ~= nil then
        TwitterShowError(sourcePlayer, 'Twitter Info', 'APP_TWITTER_NOTIF_LOGIN_ERROR')
      end
      return
    end
    MySQL.Async.insert("INSERT INTO yellow_tweets (`phone_number`, `firstname`, `lastname`, `message`) VALUES(@phone_number, @firstname, @lastname, @message);", {
	  ['@phone_number'] = phone_number,
	  ['@firstname'] = firstname,
	  ['@lastname'] = lastname,
      ['@message'] = message
    }, function (id)
      MySQL.Async.fetchAll('SELECT * from yellow_tweets WHERE id = @id', {
        ['@id'] = id
      }, function (pagess)
        pages = pagess[1]
        pages['firstname'] = user.firstname
        pages['phone_number'] = user.phone_number
        TriggerClientEvent('gcPhone:yellow_newPagess', -1, pages)
        TriggerEvent('gcPhone:yellow_newPagess', pages)
      end)
    end)
  end)
end


function YellowShowError (sourcePlayer, title, message)
  TriggerClientEvent('gcPhone:yellow_showError', sourcePlayer, message)
end
function YellowShowSuccess (sourcePlayer, title, message)
  TriggerClientEvent('gcPhone:yellow_showSuccess', sourcePlayer, title, message)
end

RegisterServerEvent('gcPhone:yellow_getPagess')
AddEventHandler('gcPhone:yellow_getPagess', function(phone_number, firstname)
  local sourcePlayer = tonumber(source)
    YellowGetPagess(nil, function (pagess)
      TriggerClientEvent('gcPhone:yellow_getPagess', sourcePlayer, pagess)
    end)
end)

function getIdentity(source)
	local identifier = GetPlayerIdentifiers(source)[1]
	local result = MySQL.Sync.fetchAll("SELECT * FROM users WHERE identifier = @identifier", {['@identifier'] = identifier})
	if result[1] ~= nil then
		local identity = result[1]

		return {
			identifier = identity['identifier'],
			firstname = identity['firstname'],
			lastname = identity['lastname'],
			phone_number = identity['phone_number'],
		}
	else
		return nil
	end
end

RegisterServerEvent('gcPhone:yellow_postPagess')
AddEventHandler('gcPhone:yellow_postPagess', function(firstname, phone_number, lastname, message)
  local sourcePlayer = tonumber(source)
  local name = getIdentity(source)
  YellowPostPages(name.phone_number, name.firstname, name.lastname, message, sourcePlayer)
end)

function deleteYellow(id)
    MySQL.Sync.execute("DELETE FROM yellow_tweets WHERE `id` = @id", {
        ['@id'] = id
    })
end

RegisterServerEvent('gcphone:deleteYellow')
AddEventHandler('gcphone:deleteYellow', function(id)
    deleteYellow(id)
end)

