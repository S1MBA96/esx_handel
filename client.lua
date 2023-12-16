

ESX = nil


CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) 
			ESX = obj 
		end)
		
		while ESX.GetPlayerData().job == nil do
			Citizen.Wait(10)
		end

		Wait(250)
	end
end)


RegisterNetEvent("NotRP:OpenHandel")
AddEventHandler("NotRP:OpenHandel", function(who, name)
    local elements = {
        { label = 'Tak', value = 'yes' },
        { label = 'Nie', value = 'no' }
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'handel_decision', {
        title    = 'Czy chcesz rozpocząć handel?',
        align    = 'center',
        elements = elements
    }, function(data, menu)
        if data.current.value then
            if data.current.value == 'yes' then
                OpenHandelMenu(who, name)
            else
                TriggerServerEvent("NotRP:HandelDecline")
                menu.close()
            end
        end
    end, function(data, menu)
        TriggerServerEvent("NotRP:HandelDecline")
        menu.close()
    end)
end)


RegisterNetEvent("NotRP:CloseHandel")
AddEventHandler("NotRP:CloseHandel", function()
	ESX.UI.Menu.CloseAll()
end)

local handelAcceptedByYou = false
local handelAcceptedByPartner = false

OpenHandelMenu = function(who, name)
	ESX.UI.Menu.CloseAll()
	local get = false
	local elements = {
		{ label = 'Handel z '..name..' ('..who..')', value = ''},
		{ label = '==============', value = ''},
		{ label = '<span style="color: blue;">Odswiez</span>', value = 'refresh' },
		{ label = 'Włóż przedmiot', value = 'add_object' },
		{ label = '<span style="color: green;">Akceptuj Handel</span>', value = 'accept_handel' },
		{ label = '<span style="color: red;">Anuluj Handel</span>', value = 'cancel_handel' },
		{ label = '==============', value = ''},
		{ label = '<span style="color: green;">Twoje przedmioty:</span>', value = ''},
	}

	ESX.TriggerServerCallback('NotRP:HandelGetItems', function(ItemYour, ItemGet)
		for k,v in pairs(ItemYour) do
			local item = v

			if item.count > 0 then 
				if item.type == 'item_standard' then
					table.insert(elements, {
						label = item.label .. ' x' .. item.count,
						type  = 'item_standard',
						value = item.name
					})
				elseif item.type == 'item_account' then
					table.insert(elements, {
						label = item.label .. ' x' .. item.count,
						type  = 'item_account',
						value = item.name
					})
				end
			end
		end

		table.insert(elements, {label = '<span style="color: orange;">Oferowane przedmioty:</span>', value = ''})

		for k,v in pairs(ItemGet) do
			local item = v

			if item.count > 0 then
				if item.type == 'item_standard' then
					table.insert(elements, {
						label = item.label .. ' x' .. item.count,
						type  = 'item_standard',
						value = item.name
					})
				elseif item.type == 'item_account' then
					table.insert(elements, {
						label = item.label .. ' x' .. item.count,
						type  = 'item_account',
						value = item.name
					})
				end
			end
		end
		get = true
	end)

	while not get do
		Citizen.Wait(200)
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'handel', {
		title    = 'Handel',
		align    = 'center',
		elements = elements
	}, function(data, menu)
		if data.current.value then
			if data.current.value == 'refresh' then
				OpenHandelMenu(who, name)
			elseif data.current.value == 'add_object' then
				AddItemToHandel(who, name)
			elseif data.current.value == 'cancel_handel' then
				TriggerServerEvent("NotRP:HandelDecline")
                menu.close()
            elseif data.current.value == 'accept_handel' then
                handelAcceptedByYou = true
                TriggerServerEvent("NotRP:RequestHandelAccept", who)
                CheckHandelAcceptance(who)
            end
		end
	end, function(data, menu)
		TriggerServerEvent("NotRP:HandelDecline")
		menu.close()
	end)
end



RegisterNetEvent("NotRP:ClientRequestHandelAccept")
AddEventHandler("NotRP:ClientRequestHandelAccept", function(target)
	local src = source
	TriggerClientEvent('NotRP:AcceptHandelRequest', target, src, GetPlayerName(src))
end)

RegisterNetEvent("NotRP:SetHandelAcceptedByPartner")
AddEventHandler("NotRP:SetHandelAcceptedByPartner", function()
    handelAcceptedByPartner = true
end)


RegisterNetEvent('NotRP:AcceptHandelRequest')
AddEventHandler('NotRP:AcceptHandelRequest', function(target, name)
	local playerPed = PlayerPedId()
	local targetPed = GetPlayerPed(GetPlayerFromServerId(target))

	if targetPed ~= playerPed then
		ESX.ShowNotification('Gracz ~b~' .. name .. '~s~ zaakceptował handel.')
		handelAcceptedByPartner = true
		CheckHandelAcceptance(target)
	else
		ESX.ShowNotification('Nie możesz handlować z samym sobą.')
	end
end)

function CheckHandelAcceptance(target)
    print("handelAcceptedByYou: " .. tostring(handelAcceptedByYou)) -- Dodaj tę linię
    print("handelAcceptedByPartner: " .. tostring(handelAcceptedByPartner)) -- Dodaj tę linię
    if handelAcceptedByYou and handelAcceptedByPartner then
        TriggerServerEvent('NotRP:HandelAccept', target)
        handelAcceptedByYou = false
        handelAcceptedByPartner = false
    else
        ESX.ShowNotification('Czekam na akceptację handlu przez drugą stronę.')
    end
end




function AddItemToHandel(who, name)
	-- ESX.TriggerServerCallback('esx_property:getPlayerInventory', function(inventory)
		local elements = {}

		local playerData = ESX.GetPlayerData()
		local dirty_siano = 0
		local siano = 0
		for i=1, #playerData.accounts, 1 do
			if playerData.accounts[i].name == 'black_money' then
				dirty_siano = playerData.accounts[i].money
			elseif playerData.accounts[i].name == 'money' then
				siano = playerData.accounts[i].money
			end
		end

		if siano > 0 then
			table.insert(elements, {
				label = '<span style="color: green;">Gotowka: '..ESX.Math.GroupDigits(siano)..'$</span>',
				type  = 'item_account',
				value = 'money'
			})
		end

		if dirty_siano > 0 then
			table.insert(elements, {
				label = '<span style="color: red;">Brudna Gotowka: '..ESX.Math.GroupDigits(dirty_siano)..'$</span>',
				type  = 'item_account',
				value = 'black_money'
			})
		end

		for i=1, #playerData.inventory, 1 do
			local item = playerData.inventory[i]
			if item and item.count > 0 then
				if item.name ~= "brazowa" and item.name ~= "carchest" and item.name ~= "srebrna" and item.name ~= "minicarcase" and item.name ~= "fajerwerkowa" and item.name ~= "szampanowa" and item.name ~= "zlota" then
					table.insert(elements, {
						label = item.label .. ' x' .. item.count,
						type  = 'item_standard',
						value = item.name
					})
				end
			end
		end


		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'handel_eq', {
			title    = 'Ekwipunek',
			align    = 'center',
			elements = elements
		}, function(data, menu)
			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_handel_eq', {
				title = 'Wprowadz Ilosc'
			}, function(data2, menu2)
				local quantity = tonumber(data2.value)

				if quantity == nil or tonumber(quantity) < 1 then
					ESX.ShowNotification('Niepoprawna ilosc')
				else
					menu2.close()
					if not IsPedDeadOrDying(GetPlayerPed(-1)) then
						TriggerServerEvent('NotRP:AddItemToHandel', data.current.type, data.current.value, tonumber(data2.value), who)
						ESX.SetTimeout(300, function()
							OpenHandelMenu(who, name)
						end)
					else
						menu.close()
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	-- end)
end
