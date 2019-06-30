script_name('Satiety-Addon')
script_author("Serhiy_Rubin")
script_version("30/06/2019")
local sampev, inicfg = require 'lib.samp.events', require 'inicfg'
local posICO, posTEXT = false, false
local idICO, idTEXT = 106, 2048
local satiety, nottime = -1, os.clock() * 1000
local sendFishEat, sendGribEat = 0, 0

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	_, MyID = sampGetPlayerIdByCharHandle(PLAYER_PED)
	MyNick = sampGetPlayerNickname(MyID)
	ini = inicfg.load({ 
		ico = {
			x = 600.0,
			y = 135.244
		},
		text = {
			x = 614.50030517578,
			y = 134.24440002441,
			color = false
		},
		[MyNick] = {
			grib = 0,
			fish = 0,
			auto = 0
		}
	}, 'Satiety')
	inicfg.save(ini, 'Satiety')
	while true do
		wait(0)
		if (ini[MyNick].auto == 1 or ini[MyNick].auto == 2) then
			if not sampIsDialogActive() and not sampIsChatInputActive() then
				if sendFishEat == 0 and ini[MyNick].auto == 1 and tonumber(satiety) == 0 then
					sendFishEat = 1
				end
				if sendGribEat == 0 and ini[MyNick].auto == 2 and tonumber(satiety) == 0 then
					sendGribEat = 1
				end
				if (os.clock() * 1000 - nottime) > 200 then
					if sendFishEat == 1 then
						if (os.clock() * 1000 - sleep) >= 1500 then
							sendFishEat = 2
							sampSendChat("/fish eat") 
						end
					end
					if sendGribEat == 1 then
						sampfuncsLog(os.clock() * 1000 - sleep)
						if (os.clock() * 1000 - sleep) >= 1500 then
							sendGribEat = 2
							sampSendChat("/grib eat") 
						end
					end
				end
			else
				nottime = os.clock() * 1000
			end
		end
		if sampTextdrawIsExists(idTEXT) and sampTextdrawIsExists(idICO) then
			strTEXT = sampTextdrawGetString(idTEXT)
			strICO = sampTextdrawGetString(idICO)
			if strTEXT ~= nil then
				local X, Y = sampTextdrawGetPos(idTEXT)
				if X ~= ini.text.x and Y ~= ini.text.y then
					sampTextdrawSetPos(idTEXT, ini.text.x, ini.text.y)
				end
				scolor, satiet = string.match(strTEXT, '~(.+)~(%d+)')
				if satiet ~= nil then
					satiety = satiet
					if ini.text.color and not strTEXT:find('y') then
						sampTextdrawSetString(idTEXT, '~y~'..satiety)
					end
				end
			end
			if strICO ~= nil then
				local X, Y = sampTextdrawGetPos(idICO)
				if X ~= ini.ico.x and Y ~= ini.ico.y then
					sampTextdrawSetPos(idICO, ini.ico.x, ini.ico.y)
				end
			end
		end
		if posTEXT or posICO then
			sampSetCursorMode(3)
			local X, Y = getCursorPos()
			local key = (posTEXT and 'text' or 'ico')
			local id = (posTEXT and idTEXT or idICO)
			local posX, posY = convertWindowScreenCoordsToGameScreenCoords(X, Y)
			ini[key].x, ini[key].y = posX, posY
			sampTextdrawSetPos(id, ini[key].x, ini[key].y)
			if isKeyJustPressed(1) then 
				posTEXT, posICO = false, false
				sampSetCursorMode(0)
				inicfg.save(ini, 'Satiety')
				ShowDialog(1)
			end
		end
	end
end

function sampev.onSendChat(message) sleep = os.clock() * 1000 end
function sampev.onSendCommand(cmd)
	sleep = os.clock() * 1000
	local command, params = string.match(cmd, "^%/([^ ]*)(.*)")
	if command:lower() == "satiety" and params:lower() == " menu" then
		lua_thread.create(function() ShowDialog(1) end)
		return false
	end
end

function ShowDialog(int)
	if int == 1 then
		stopThread = true
		line = {}
		line[#line + 1] = 'Авто поедание\t'..(ini[MyNick].auto == 0 and '{f50f35}OFF' or (ini[MyNick].auto == 1 and '{11a811}Рыба' or (ini[MyNick].auto == 2 and '{11a811}Грибы' or '{f50f35}OFF')))
		line[#line + 1] = 'Сменить позицию картинки\t'
		line[#line + 1] = 'Сменить позицию цифры\t'
		line[#line + 1] = 'Кукурузный цвет всегда\t'..(ini.text.color and '{11a811}ON' or '{f50f35}OFF')
		local text = ""
		for k,v in pairs(line) do text = text..v.."\n" end
		sampShowDialog(1894, "Satiety-Addon by Serhiy Rubin", text, "Выбрать", "Закрыть", 4)
		lua_thread.create(function()
			wait(100)
			stopThread = false
			repeat
				wait(0)
				local result, button, list, input = sampHasDialogRespond(1894)
				if result then
					if button == 1 then
						if line[list + 1] == 'Сменить позицию картинки\t' then
							lua_thread.create(function()
								wait(200)
								posICO = true
							end)
						end
						if line[list + 1] == 'Сменить позицию цифры\t' then
							lua_thread.create(function()
								wait(200)
								posTEXT = true
							end)
						end
						if line[list + 1] == 'Кукурузный цвет всегда\t'..(ini.text.color and '{11a811}ON' or '{f50f35}OFF') then
							ini.text.color = not ini.text.color
							inicfg.save(ini, 'Satiety')
							if sampTextdrawIsExists(idTEXT) and scolor ~= nil then
								sampTextdrawSetString(idTEXT, (ini.text.color and '~y~' or '~'..scolor..'~')..satiety)
							else
								sampAddChatMessage(' Ошибка. Выклчите и включите индикатор сытости и попробуйте снова.', 0xFFcfba69)
							end
							ShowDialog(1)
						end
						if line[list + 1] == 'Авто поедание\t'..(ini[MyNick].auto == 0 and '{f50f35}OFF' or (ini[MyNick].auto == 1 and '{11a811}Рыба' or (ini[MyNick].auto == 2 and '{11a811}Грибы' or '{f50f35}OFF'))) then
							ini[MyNick].auto = (ini[MyNick].auto == 0 and 1 or (ini[MyNick].auto == 1 and 2 or (ini[MyNick].auto == 2 and 0 or 0)))
							inicfg.save(ini, 'Satiety')
							ShowDialog(1)
						end
					end
				end
			until not sampIsDialogActive() or stopThread
		end)
	end
end

function sampev.onServerMessage(color, message)
	if message == " Не флуди!" or message == " В AFK ввод команд заблокирован" then
		if sendFishEat == 2 then sendFishEat = 1 return false end
		if sendGribEat == 2 then sendGribEat = 1 return false end
	end
	if string.find(message, " Сытость пополнена до (%d+). У вас осталось (%d+)/(%d+) готовых грибов") then
		local S2, S1 = string.match(message, " Сытость пополнена до (%d+). У вас осталось (%d+)/%d+ готовых грибов")
		satiety = S2
		if sendGribEat == 2 then
			if tonumber(S1) > 0 then 
				sendGribEat = ( tonumber(S2) >= 98 and 0 or 1 )
			else
				if ini[MyNick].auto == 2 then
					sampAddChatMessage(' Авто Поедание грибов выключено, грибы кончились.', 0xFFcfba69)
					ini[MyNick].auto = 0
					inicfg.save(ini, 'Satiety')
				end
			end
		end
	end
	if message == " Вы не проголодались" then
		sendGribEat = 0
	end
	if message == " Недостаточно готовых грибов" or message == " У вас недостаточно пачек рыбы" then 
		if sendGribEat == 2 or sendFishEat == 2 then
			sendGribEat = 0 
			sendFishEat = 0
			ini[MyNick].auto = 0
			inicfg.save(ini, 'Satiety')
			return {color, message..". Авто-Поедание отключено!"}
		end
	end
	if string.find(message, " Сытость пополнена до 100%. У вас осталось %d+ / %d+ пачек рыбы") then
		local fishPa = string.match(message, " Сытость пополнена до 100%. У вас осталось (%d+) / %d+ пачек рыбы")
		if tonumber(fishPa) == 0 then
			sampAddChatMessage(' Авто Поедание рыбы выключено, рыба кончилась.', 0xFFcfba69)
			ini[MyNick].auto = 0
			inicfg.save(ini, 'Satiety')
		end
		satiety = 100
		sendFishEat = 0 
	end
end