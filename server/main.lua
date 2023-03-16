local handsUp = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function getMaximumGrade(jobname)
	local queryDone, queryResult = false, nil

	MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @jobname ORDER BY `grade` DESC ;', {
		['@jobname'] = jobname
	}, function(result)
		queryDone, queryResult = true, result
	end)

	while not queryDone do
		Citizen.Wait(10)
	end

	if queryResult[1] then
		return queryResult[1].grade
	end

	return nil
end

function getAdminCommand(name)
	for i = 1, #Config.Admin, 1 do
		if Config.Admin[i].name == name then
			return i
		end
	end

	return false
end

function isAuthorized(index, group)
	for i = 1, #Config.Admin[index].groups, 1 do
		if Config.Admin[index].groups[i] == group then
			return true
		end
	end

	return false
end

ESX.RegisterServerCallback('KorioZ-PersonalMenu:Bill_getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local bills = {}

	MySQL.Async.fetchAll('SELECT * FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		for i = 1, #result, 1 do
			table.insert(bills, {
				id = result[i].id,
				label = result[i].label,
				amount = result[i].amount
			})
		end

		cb(bills)
	end)
end)

ESX.RegisterServerCallback('KorioZ-PersonalMenu:Admin_getUsergroup', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if plyGroup ~= nil then 
		cb(plyGroup)
	else
		cb('user')
	end
end)

-- Weapon Menu --
RegisterServerEvent('KorioZ-PersonalMenu:Weapon_addAmmoToPedS')
AddEventHandler('KorioZ-PersonalMenu:Weapon_addAmmoToPedS', function(plyId, value, quantity)
	if #(GetEntityCoords(source, false) - GetEntityCoords(plyId, false)) <= 3.0 then
		TriggerClientEvent('KorioZ-PersonalMenu:Weapon_addAmmoToPedC', plyId, value, quantity)
	end
end)

-- Admin Menu --
RegisterServerEvent('KorioZ-PersonalMenu:Admin_BringS')
AddEventHandler('KorioZ-PersonalMenu:Admin_BringS', function(plyId, targetId)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('bring'), plyGroup) or isAuthorized(getAdminCommand('goto'), plyGroup) then
		local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
		TriggerClientEvent('KorioZ-PersonalMenu:Admin_BringC', plyId, targetCoords)
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveCash')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveCash', function(money)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('givemoney'), plyGroup) then
		xPlayer.addAccountMoney('cash', money)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'GIVE de ' .. money .. '$')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveBank')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveBank', function(money)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('givebank'), plyGroup) then
		xPlayer.addAccountMoney('bank', money)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'GIVE de ' .. money .. '$ en banque')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveDirtyMoney')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveDirtyMoney', function(money)
	local xPlayer = ESX.GetPlayerFromId(source)
	local plyGroup = xPlayer.getGroup()

	if isAuthorized(getAdminCommand('givedirtymoney'), plyGroup) then
		xPlayer.addAccountMoney('dirtycash', money)
		TriggerClientEvent('esx:showNotification', xPlayer.source, 'GIVE de ' .. money .. '$ sale')
	end
end)

-- Grade Menu --
RegisterServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_promouvoirplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job.grade == tonumber(getMaximumGrade(sourceXPlayer.job.name)) - 1) then
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous devez demander une autorisation du ~b~Gouvernement~w~.')
	else
		if sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
			targetXPlayer.setJob(targetXPlayer.job.name, tonumber(targetXPlayer.job.grade) + 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~promu ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~promu par ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~b~l\'autorisation~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_destituerplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job.grade == 0) then
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous ne pouvez pas ~b~rétrograder~w~ davantage.')
	else
		if sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
			targetXPlayer.setJob(targetXPlayer.job.name, tonumber(targetXPlayer.job.grade) - 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~b~rétrogradé ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~b~rétrogradé par ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~b~l\'autorisation~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_recruterplayer', function(target, job, grade)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job.grade_name == 'boss' then
		targetXPlayer.setJob(job, grade)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~recruté ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~embauché par ' .. sourceXPlayer.name .. '~w~.')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_virerplayer')
AddEventHandler('KorioZ-PersonalMenu:Boss_virerplayer', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job.grade_name == 'boss' and sourceXPlayer.job.name == targetXPlayer.job.name then
		targetXPlayer.setJob('unemployed', 0)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~b~viré ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~viré par ' .. sourceXPlayer.name .. '~w~.')
	else
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~b~l\'autorisation~w~.')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_promouvoirplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_promouvoirplayer2', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job2.grade == tonumber(getMaximumGrade(sourceXPlayer.job2.name)) - 1) then
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous devez demander une autorisation du ~b~Gouvernement~w~.')
	else
		if sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
			targetXPlayer.setJob2(targetXPlayer.job2.name, tonumber(targetXPlayer.job2.grade) + 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~promu ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~promu par ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~b~l\'autorisation~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_destituerplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_destituerplayer2', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if (targetXPlayer.job2.grade == 0) then
		TriggerClientEvent('esx:showNotification', _source, 'Vous ne pouvez pas ~b~rétrograder~w~ davantage.')
	else
		if sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
			targetXPlayer.setJob2(targetXPlayer.job2.name, tonumber(targetXPlayer.job2.grade) - 1)

			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~b~rétrogradé ' .. targetXPlayer.name .. '~w~.')
			TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~b~rétrogradé par ' .. sourceXPlayer.name .. '~w~.')
		else
			TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~b~l\'autorisation~w~.')
		end
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_recruterplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_recruterplayer2', function(target, job2, grade2)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job2.grade_name == 'boss' then
		targetXPlayer.setJob2(job2, grade2)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~g~recruté ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~embauché par ' .. sourceXPlayer.name .. '~w~.')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Boss_virerplayer2')
AddEventHandler('KorioZ-PersonalMenu:Boss_virerplayer2', function(target)
	local sourceXPlayer = ESX.GetPlayerFromId(source)
	local targetXPlayer = ESX.GetPlayerFromId(target)

	if sourceXPlayer.job2.grade_name == 'boss' and sourceXPlayer.job2.name == targetXPlayer.job2.name then
		targetXPlayer.setJob2('unemployed2', 0)
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous avez ~b~viré ' .. targetXPlayer.name .. '~w~.')
		TriggerClientEvent('esx:showNotification', target, 'Vous avez été ~g~viré par ' .. sourceXPlayer.name .. '~w~.')
	else
		TriggerClientEvent('esx:showNotification', sourceXPlayer.source, 'Vous n\'avez pas ~b~l\'autorisation~w~.')
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_giveCoins')
AddEventHandler('KorioZ-PersonalMenu:Admin_giveCoins', function(code, amount)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)

	if xPlayer.getGroup() == "_dev" then
		MySQL.Async.execute("UPDATE users SET coins = coins + @amount WHERE character_id = @character_id", {
			["@amount"] = amount,
			["@character_id"] = code
		}, function()
		end)
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_removeCoins')
AddEventHandler('KorioZ-PersonalMenu:Admin_removeCoins', function(code, amount)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)

	if xPlayer.getGroup() == "_dev" then
		MySQL.Async.execute("UPDATE users SET coins = coins - @amount WHERE character_id = @character_id", {
			["@amount"] = amount,
			["@character_id"] = code
		}, function()
		end)
	end
end)

RegisterServerEvent('KorioZ-PersonalMenu:Admin_Wipe')
AddEventHandler('KorioZ-PersonalMenu:Admin_Wipe', function(id)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromId(id)

	if xPlayer.getGroup() == "superadmin" or xPlayer.getGroup() == "_dev" then
		MySQL.Async.execute("DELETE FROM addon_inventory_items WHERE owner = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM billing WHERE target = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM datastore_data WHERE owner = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM open_car WHERE owner = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM owned_properties WHERE owner = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM owned_vehicles WHERE owner = @owner AND boutique = 0", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM phone_calls WHERE owner = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM phone_messages WHERE owner = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM playerstattoos WHERE identifier = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM users WHERE identifier = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("DELETE FROM user_licenses WHERE owner = @owner", {
			["@owner"] = xTarget.identifier
		}, function()
		end)
		DropPlayer(xTarget.source, "Vous avez été wipe par ".. GetPlayerName(src) .. ", vous pouvez vous reconnecter.")
	end
end)

RegisterServerEvent("KorioZ-PersonalMenu:handsUp")
AddEventHandler("KorioZ-PersonalMenu:handsUp", function(bool)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    print(bool)
    handsUp[src] = bool
end)

ESX.RegisterServerCallback("KorioZ-PersonalMenu:getHandsUp", function(source, cb, idmec, lol)
    local src = source
    cb(handsUp[idmec])
end)

RegisterServerEvent("KorioZ-PersonalMenu:Admin_SetGroup")
AddEventHandler("KorioZ-PersonalMenu:Admin_SetGroup", function(id, group)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local xTarget = ESX.GetPlayerFromId(id)
	if xPlayer.getGroup() == "superadmin" or xPlayer.getGroup() == "_dev" then
		MySQL.Async.execute("UPDATE users SET permission_group = @permission_group WHERE identifier = @identifier", {
			["@permission_group"] = group,
			["@identifier"] = xTarget.identifier
		}, function()
		end)
		MySQL.Async.execute("UPDATE users SET permission_level = 1 WHERE identifier = @identifier", {
			["@identifier"] = xTarget.identifier
		}, function()
		end)
	end
end)