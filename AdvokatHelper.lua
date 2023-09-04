script_name("Advokat Helper")
script_author("romanespit")
SCR_VERSION = "1.0"
script_version(SCR_VERSION)
script_description('Периодическая проверка заключенных')

local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
local inicfg = require 'inicfg'

encoding.default = 'CP1251'

local inicfg = require 'inicfg'
local settings = inicfg.load({
    main = {
        sendOriginalMessage = true,
		autoUpdate = true
    }
}, 'Advokat Helper\\settings')

COLOR_WHITE = '{FFFFFF}'
initcolor = '{3B66C5}'
msgcolor = '{FFD700}'
colorinit = 0xFF3B66C5
colormsg = 0xFFFFD700
zeki = {}
font = renderCreateFont('Tahoma', 10, 5)
timer = -1
zeksText = 'Пусто'
function main()
    while not isSampAvailable() do wait(0) end
    if not doesDirectoryExist(getWorkingDirectory()..'/config/Advokat Helper') then createDirectory('moonloader\\config\\Advokat Helper') end
    if not doesFileExist('moonloader/config/Advokat Helper/settings.ini') then inicfg.save(settings, 'Advokat Helper\\settings') end

	userscreenX, userscreenY = getScreenResolution()
	if settings.main.autoUpdate then
		local nowTime = os.time()
		timer = nowTime + 30
	end
	wait(1000)
    sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: Успешная загрузка скрипта. Используйте: '..initcolor..'/adh{FFFFFF}. Автор: '..initcolor..'romanespit', colorinit)
	sampRegisterChatCommand('adh', function( )
        sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: Версия скрипта: '..initcolor..SCR_VERSION..'{FFFFFF}. Автор: '..initcolor..'romanespit{FFFFFF}. Telegram: '..initcolor..'@arzadh', colorinit)	
        sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: /adh_chat - включить/выключить ответы сервера на команду /zeks', colorinit)	
        sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: /adh_autoupdate - включить/выключить автоматическое обновление КПЗ', colorinit)
    end)
    sampRegisterChatCommand('adh_chat', function( )
        if settings.main.sendOriginalMessage then
			settings.main.sendOriginalMessage = false
			inicfg.save(settings, 'Advokat Helper\\settings')
			sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: Серверные ответы на команду /zeks выключены', colorinit)
		else 
			settings.main.sendOriginalMessage = true
			inicfg.save(settings, 'Advokat Helper\\settings')
			sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: Серверные ответы на команду /zeks включены', colorinit)
		end
    end)
    sampRegisterChatCommand('adh_autoupdate', function( )
        if settings.main.autoUpdate then
			settings.main.autoUpdate = false
			inicfg.save(settings, 'Advokat Helper\\settings')
			timer = -1
			sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: Автообновление КПЗ выключено', colorinit)
		else 
			settings.main.autoUpdate = true
			inicfg.save(settings, 'Advokat Helper\\settings')
			local nowTime = os.time()
			timer = nowTime + 5
			sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: Автообновление КПЗ включено', colorinit)
		end
    end)
	while true do
		if sampIsLocalPlayerSpawned() then
			while true do
				kpztext = 'КПЗ'
				UpdateTD(zeki)
				if settings.main.autoUpdate then
					local nowTime = os.time()
					kpztext = 'КПЗ (до автообновления '..timer-nowTime..' сек.)'
					if nowTime >= timer then
						sampSendChat("/zeks")
					end
				end
				local l = #zeki-1
				if l == -1 then l = 0 end
				renderFontDrawText(font, kpztext, userscreenX/3 + 30, (userscreenY - 60) - l*15, 0xFFFFFFFF)
				wait(0)
			end
		end
		wait(0)
	end
    wait(-1)
end

function UpdateTD(table)
	if #table == 0 then
		zeksText = '{919191}Пусто'
		renderFontDrawText(font, zeksText, userscreenX/3 + 30, userscreenY - 45, colormsg)
	else
		for i = 1, #table do
			zeksText = table[i][5] ..table[i][1] .. " | " .. table[i][3] .. "зв. | " .. table[i][4] .. " (" .. table[i][2] .. ")\n"
			renderFontDrawText(font, zeksText, userscreenX/3 + 30, (userscreenY - 45) - (i-1)*15, colormsg)
		end
	end
end

function sampev.onSendCommand(command) -- При ручном вводе команды - очищаем таблицу зеков для ее последующего обновления + обновляем таймер
	if command == "/zeks" then 
		zeki = {}
		if settings.main.autoUpdate then -- Даже если ввод будет ручной, таймер обновляем, чтобы не спамить
			local nowTime = os.time()
			timer = nowTime + 30
		else
			timer = -1
		end
	end
end

function sampev.onServerMessage(color,text) -- Ловим полученный ответ на команду /zeks
	if IsZeksResponse(text) then
		if not settings.main.sendOriginalMessage then return false end -- Если false, блокируем пакет
	elseif text:match("Вы не адвокат") and (settings.main.autoUpdate == true or settings.main.sendOriginalMessage == false) then
		settings.main.autoUpdate = false
		settings.main.sendOriginalMessage = true
		inicfg.save(settings, 'Advokat Helper\\settings')
		timer = -1
		sampAddChatMessage('[ Advokat Helper ]{FFFFFF}: Вы не адвокат! Автообновление выключено и серверные ответы включены.', colorinit)
		return false
	end			
end

function IsZeksResponse(text)
	if text:find("В данный момент в КПЗ отсутствуют заключенные!") then -- Получили ответ на /zeks
		zeki = {} -- Очищаем таблицу зеков
		return true
	elseif (text:find("Время") and text:find("Залог") and text:find("КПЗ")) then -- Поймали сообщение - нужно добавить в таблицу
		nameid = string.sub(text, string.find(text, '.+%(%d+%)')) -- Ivan_Pupkin(123)
		id = math.floor(tonumber(nameid:match("%d+"))) -- 123
		time = string.sub(text, string.find(text, '%d+%sмин')) -- Сколько осталось сидеть
		zalog = string.sub(text, string.find(text, '%$[%d+%p]+')):gsub("%p", "") -- Сумма залога, если есть MoneySeparator, удаляем знаки пунктуации
		wanted = math.floor(tonumber(zalog/4000)) -- Звезды = Залог / 4000
		kpz = string.sub(text, string.find(text, 'КПЗ:%s.+')) -- В каком КПЗ
		if kpz then kpz = GetShortKPZName(kpz) else kpz = "???" end -- Сокращаем КПЗ
		if string.find(text, 'Адвокат:%s.+') then advokat = "{919191}[".. text:match("Адвокат:%s.+") .."] " color = 0xFF919191  -- Если находим, значит есть адвокат
		elseif string.find(text, 'В ожидании адвоката') then advokat = "{FFD700}[ЖДЁТ АДВОКАТА] " color = colormsg -- Если находим, значит адвоката нет
		end 
		table.insert(zeki, #zeki+1,{nameid,time,wanted,kpz,advokat}) -- Пуляем в таблицу	
		return true
	end
	
end

function GetShortKPZName(kpz) -- Сокращаем ПД
	if kpz:match("Las Venturas PD") then kpz = "LVPD"
	elseif kpz:match("San Fierro PD") then kpz = "SFPD"
	elseif kpz:match("Los Santos PD") then kpz = "LSPD"
	elseif kpz:match("Red County PD") then kpz = "RCPD"
	elseif kpz:match("Неизвестно") then kpz = "???"
	end
	return kpz
end
