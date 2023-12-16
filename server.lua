

ESX = nil


TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


RegisterCommand('handel', function(source, args, rawCommand)
	local src = source
	local target = tonumber(args[1])

	if target then
		local xPlayer = ESX.GetPlayerFromId(src)
		local tPlayer = ESX.GetPlayerFromId(target)

		if tPlayer then
			local name = tPlayer.getName()

			-- Sprawdzenie, czy gracze są blisko siebie
			local srcPos = GetEntityCoords(GetPlayerPed(src))
			local tgtPos = GetEntityCoords(GetPlayerPed(target))
			local distance = #(srcPos - tgtPos)
			local maxDistance = 10.0 -- maksymalna odległość między graczami, w której mogą handlować

			if distance <= maxDistance then
				TriggerClientEvent('NotRP:OpenHandel', src, target, name)
				TriggerClientEvent('NotRP:OpenHandel', target, src, xPlayer.getName())
			else
				TriggerClientEvent('esx:showNotification', src, 'Gracz jest zbyt daleko, aby handlować.')
			end
		else
			TriggerClientEvent('esx:showNotification', src, 'Nieprawidłowy ID gracza')
		end
	else
		TriggerClientEvent('esx:showNotification', src, 'Musisz podać ID gracza')
	end
end)


local Handel = {}



ESX.RegisterServerCallback('NotRP:HandelGetItems', function(source, cb)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local HandelData = Handel[src]

	if HandelData then
		local YourItems = {}
		local GetItems = {}

		for k, v in pairs(HandelData.you) do
			table.insert(YourItems, {
				label = v.label,
				count = v.count,
				type = v.type,
				name = v.name
			})
		end

		for k, v in pairs(HandelData.get) do
			table.insert(GetItems, {
				label = v.label,
				count = v.count,
				type = v.type,
				name = v.name
			})
		end

		cb(YourItems, GetItems)
	else
		cb({}, {})
	end
end)

RegisterServerEvent('NotRP:AddItemToHandel')
AddEventHandler('NotRP:AddItemToHandel', function(itemType, itemName, count, target)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local tPlayer = ESX.GetPlayerFromId(target)

	if xPlayer and tPlayer then
		if not Handel[src] then
			Handel[src] = {you = {}, get = {}}
		end

		if not Handel[target] then
			Handel[target] = {you = {}, get = {}}
		end

		local itemsYou = Handel[src].you
		local itemsGet = Handel[src].get

		if itemType == 'item_standard' then
			local item = xPlayer.getInventoryItem(itemName)

			if item.count >= count then
				xPlayer.removeInventoryItem(itemName, count)
				table.insert(itemsYou, {
					label = item.label,
					count = count,
					type = itemType,
					name = itemName
				})
			else
				TriggerClientEvent('esx:showNotification', src, 'Nie masz wystarczającej ilości przedmiotów.')
			end
		elseif itemType == 'item_account' then
			local account = xPlayer.getAccount(itemName)

			if account.money >= count then
				xPlayer.removeAccountMoney(itemName, count)
				table.insert(itemsYou, {
					label = account.label,
					count = count,
					type = itemType,
					name = itemName
				})
			else
				TriggerClientEvent('esx:showNotification', src, 'Nie masz wystarczającej ilości gotówki.')
			end
		end

		if ESX.Items[itemName] then
			local item = {
				label = ESX.Items[itemName].label,
				count = count,
				type = itemType,
				name = itemName
			}
		end

		table.insert(itemsGet, item)
		Handel[src].you = itemsYou
		Handel[src].get = itemsGet
		Handel[target].you = itemsGet
		Handel[target].get = itemsYou
	end
end)

RegisterServerEvent('NotRP:HandelDecline')
AddEventHandler('NotRP:HandelDecline', function()
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)

	if Handel[src] then
		for k, v in pairs(Handel[src].you) do
			if v.type == 'item_standard' then
				xPlayer.addInventoryItem(v.name, v.count)
			elseif v.type == 'item_account' then
				xPlayer.addAccountMoney(v.name, v.count)
			end
		end

		local target = nil
		for k, v in pairs(Handel) do
			if k ~= src then
				target = k
				break
			end
		end

		if target then
			local tPlayer = ESX.GetPlayerFromId(target)
			if tPlayer then
				for k, v in pairs(Handel[target].you) do
					if v.type == 'item_standard' then
						tPlayer.addInventoryItem(v.name, v.count)
					elseif v.type == 'item_account' then
						tPlayer.addAccountMoney(v.name, v.count)
					end
				end
			end
			TriggerClientEvent('NotRP:CloseHandel', target)
		end

		Handel[src] = nil
		Handel[target] = nil
	end
end)

RegisterServerEvent('NotRP:RequestHandelAccept')
AddEventHandler('NotRP:RequestHandelAccept', function(target)
	local src = source
	TriggerClientEvent('NotRP:AcceptHandelRequest', target, src, GetPlayerName(src))
end)

RegisterServerEvent('NotRP:HandelAccept')
AddEventHandler('NotRP:HandelAccept', function(target)
	local src = source
	TriggerClientEvent('NotRP:CloseHandel', src)
	TriggerClientEvent('NotRP:CloseHandel', target)

	if Handel[src] and Handel[target] then
		local xPlayer = ESX.GetPlayerFromId(src)
		local tPlayer = ESX.GetPlayerFromId(target)

		for k, v in pairs(Handel[src].you) do
			if v.type == 'item_standard' then
				tPlayer.addInventoryItem(v.name, v.count)
				print(string.format("[DEBUG] %s dal graczowi %s %d %s(s)", xPlayer.getName(), tPlayer.getName(), v.count, v.name))
			elseif v.type == 'item_account' then
				tPlayer.addAccountMoney(v.name, v.count)
				print(string.format("[DEBUG] %s dal graczowi %s $%d (%s)", xPlayer.getName(), tPlayer.getName(), v.count, v.name))
			end
		end
		
		for k, v in pairs(Handel[target].you) do
			if v.type == 'item_standard' then
				xPlayer.addInventoryItem(v.name, v.count)
				print(string.format("[DEBUG] %s dal graczowi %s %d %s(s)", tPlayer.getName(), xPlayer.getName(), v.count, v.name))
			elseif v.type == 'item_account' then
				xPlayer.addAccountMoney(v.name, v.count)
				print(string.format("[DEBUG] %s dal graczowi %s $%d (%s)", tPlayer.getName(), xPlayer.getName(), v.count, v.name))
			end
		end
		
		

		Handel[src] = nil
		Handel[target] = nil

		handelAcceptedByYou = false
		handelAcceptedByPartner = false
	end
end)


