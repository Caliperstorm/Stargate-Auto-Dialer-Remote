local monitor = peripheral.find("monitor")
local nOption = 1
local editor = false
local modem = peripheral.find("modem") or error("No modem attached", 0)
local port = 304 -- change these if you want to only control certain stargates
local responsePort = 303

-- Function to save the Address List to AddressList.lua
function saveItemList()
    local file = io.open("AddressList.lua", "w")
    if file then
        file:write("return {\n")
        for _, item in ipairs(itemList) do
            file:write(string.format("\t{locName=\"%s\", address={%s}},\n", item.locName, table.concat(item.address, ",")))
        end
        file:write("}\n")
        file:close()
    end
end

-- Function to load the Address List from AddressList.lua
function loadItemList()
    local file = io.open("AddressList.lua", "r")
    if file then
        local content = file:read("*all")
        file:close()
        local success, loadedItemList = pcall(load(content))
        if success and type(loadedItemList) == "table" then
            itemList = loadedItemList
        end
    end
end

-- Function to switch to edit mode
function editorMode()
    if editor == true then
        editor = false
    elseif editor == false then
        editor = true
    end
end

-- Function to add a new item to the Address List
function addNewLocation()
    term.setTextColor(colors.white)
    sleep(0.1)
    loadItemList()
    term.clear()
    term.setCursorPos(1,1)
    io.write("Enter Gate Name: ")
    local newLocName = io.read()
    io.write("Enter Gate Address: ")
    local newAddressInput = io.read()
    local newAddress = {}
    if newAddressInput ~= "" then
        for num in newAddressInput:gmatch("%d+") do
            table.insert(newAddress, tonumber(num))
        end
        if newAddress[#newAddress] ~= 0 then
            table.insert(newAddress, 0)
        end
    else
        newAddress = {0}
    end
    table.insert(itemList, {locName = newLocName, address = newAddress})
    saveItemList()
end

-- Function to remove an item from the Address List
function removeItem(index)
    loadItemList()
    if itemList[index] then
        table.remove(itemList, index)
        saveItemList()
    end
    if nOption >= #itemList then
        nOption = #itemList
    end
end

-- Function to edit an existing item on the Address List
function editLocationDetails()
    term.setTextColor(colors.white)
    loadItemList()
    term.clear()
    term.setCursorPos(1,1)
    local selectedLocation = itemList[nOption]
    print("\nCurrent Name:\n" .. selectedLocation.locName)
    print("\nCurrent Address: -" .. table.concat(selectedLocation.address, "-") .. "-\n")
    io.write("Please Enter new Gate Name\nor Press Enter to keep current:\n")
    local newLocName = io.read()
    if newLocName == "" then
        newLocName = selectedLocation.locName
    end
    io.write("\nPlease Enter new Gate Address\nor Press Enter to keep current:\n")
    local newAddressInput = io.read()
    local newAddress = {}
    if newAddressInput ~= "" then
        for num in newAddressInput:gmatch("%d+") do
            table.insert(newAddress, tonumber(num))
        end
        if newAddress[#newAddress] ~= 0 then
            table.insert(newAddress, 0)
        end
    else
        newAddress = selectedLocation.address
    end
    itemList[nOption].locName = newLocName
    itemList[nOption].address = newAddress
    saveItemList()
end

-- Function to move an item up in the Address List
function moveItemUp(index)
    loadItemList()
    if index > 1 then
        itemList[index], itemList[index - 1] = itemList[index - 1], itemList[index]
        saveItemList()
        nOption = nOption - 1
    end
end

-- Function to move an item down in the Address List
function moveItemDown(index)
    loadItemList()
    if index < #itemList then
        itemList[index], itemList[index + 1] = itemList[index + 1], itemList[index]
        saveItemList()
        nOption = nOption + 1
    end
end

-- Function to Dial the Milky-Way Stargate
function dial(address)
	modem.open(port)
	modem.transmit(port, responsePort, "dial")
	sleep(0.1)
	modem.transmit(port, responsePort, address)
	repeat
		event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
	until channel == port
	if message == "dialing" then
		gateIsDialing = true
		repeat
			event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
		until channel == responsePort
	end
    gateIsDialing = false
	modem.close(port)
end

-- Function to set the cursor the the center of the screen and print the line
function printCenter(display, y, s)
    local w,h = display.getSize()
    local w = ((w - string.len(s))/2)+1
    display.setCursorPos(w,y)
    display.clearLine()
    display.write(s)
end

-- Function to draw the scrollable address list on screen
function drawBackEnd(display, h, w)
    display.setTextColor(colors.white)
    local function drawOption(index)
        return ((nOption == index) and "\187 " .. itemList[index].locName .. " \171") or itemList[index].locName
    end
    local curs = 6
    if #itemList < (h-10)+1 then
        for i, t in ipairs(itemList) do
            printCenter(display, curs, drawOption(i))
            curs = curs + 1
        end
    else
        local start, stop
        if nOption < (math.floor((h-10)/2))+2 then
            start, stop = 1, (h-10)
        elseif nOption > (math.floor(h-10)/2)+1 and nOption < #itemList - (math.floor((h-10)/2)) then
            start, stop = nOption - (math.floor((h-10)/2)), nOption + (math.floor((h-10)/2))
        else
            start, stop = #itemList - ((h-10)-1), #itemList
        end
        for i = start, stop do
            printCenter(display, curs, drawOption(i))
            curs = curs + 1
        end
        if nOption < #itemList - math.floor((h-10)/2) then
            printCenter(display, h-4, "\131\131\131 \25 \131\131\131")
        end
        if nOption > math.floor((h-10)/2)+1 then
            printCenter(display, 5, "\140\140\140 \24 \140\140\140")
        end
    end
end

-- Function to ask server if Stargate is connected
function isStargateConnected()
	modem.open(port)
	modem.transmit(port, responsePort, "isStargateConnected")
	repeat
		event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
	until channel == responsePort
	if message == "connected" then
		return true
	else
		return false
	end
end

-- Function to disconnect Stargate
function disconnectStargate()
	modem.transmit(port, responsePort, "disconnect")
end

-- Function to draw the Main Menu
function drawFrontEnd(display, h, w)
    loadItemList()
    display.clear()
    if isStargateConnected() == true then
        display.setTextColor(colors.red)
        printCenter(display, h/2, "\187 Disconnect Wormhole \171")
        if event == "stargate_disconnected" or event == "stargate_reset" then end
    elseif gateIsDialing == true then
        display.setTextColor(colors.yellow)
        printCenter(display, h/2, "Dialing Stargate Address")
        printCenter(display, h/2+1, "Please Wait...")
    elseif editor == false then
        term.setTextColor(colors.green)
        printCenter(term, 2, "\24 or \25 to Select a Destination")
        printCenter(term, 3, "[Enter] to start Dialing")
        printCenter(term, h-1, "Move \27 or \26 to enter EDIT MODE")
        drawBackEnd(display, h, w)
        if monitor ~= nil then
            monitor.setTextColor(colors.green)
            -- TOP
            monitor.setCursorPos(3,3)
            monitor.write("[DIAL]")
            monitor.setCursorPos(w/2-4,3)
            monitor.write("[SCROLL UP]")
            monitor.setCursorPos(w-7,3)
            monitor.write("[HOME]")
            -- MID
            monitor.setCursorPos(3,h/2+1)
            monitor.write("\27EDIT\27")
            monitor.setCursorPos(w/2-2,h/2+1)
            monitor.write("")
            monitor.setCursorPos(w-7,h/2+1)
            monitor.write("\26EDIT\26")
            -- BOT
            monitor.setCursorPos(3,h-2)
            monitor.write("")
            monitor.setCursorPos(w/2-5,h-2)
            monitor.write("[SCROLL DOWN]")
            monitor.setCursorPos(w-7,h-2)
            monitor.write("[END]")
        end
    elseif editor == true then
        term.setTextColor(colors.orange)
        printCenter(term, 2, "[Enter] to Edit Selected Destination")
        printCenter(term, 3, "[Insert] to Add or [Delete] to Remove")
        printCenter(term, h-2, "Use [PageUp] or [PageDown] to Move Items")
        printCenter(term, h-1, "Move \27 or \26 to enter DIAL MODE")
        drawBackEnd(display, h, w)
        if monitor ~= nil then
            monitor.setTextColor(colors.orange)
            -- TOP
            monitor.setCursorPos(3,3)
            monitor.write("")
            monitor.setCursorPos(w/2-4,3)
            monitor.write("[SCROLL UP]")
            monitor.setCursorPos(w-7,3)
            monitor.write("[PGUP]")
            -- MID
            monitor.setCursorPos(3,h/2+1)
            monitor.write("\27DIAL\27")
            monitor.setCursorPos(w/2-2,h/2+1)
            monitor.write("")
            monitor.setCursorPos(w-7,h/2+1)
            monitor.write("\26DIAL\26")
            -- BOT
            monitor.setCursorPos(3,h-2)
            monitor.write("")
            monitor.setCursorPos(w/2-5,h-2)
            monitor.write("[SCROLL DOWN]")
            monitor.setCursorPos(w-7,h-2)
            monitor.write("[PGDN]")
        end
    end
end

-- Function to display on the terminal
function terminalSetup()
    tw,th = term.getSize()
    drawFrontEnd(term,th,tw)
end

-- Function to display on the monitor
function monitorSetup()
    monitor.setTextScale(.5)
    mw,mh = monitor.getSize()
    drawFrontEnd(monitor,mh,mw)
end

-- Script Actually Starts Here
while true do
    loadItemList()
    terminalSetup()
    if monitor ~= nil then
        monitorSetup()
    end
    sleep(0.1)
    local event, key, x, y = os.pullEvent()
    if event == "key" and gateIsDialing ~= true then
        if key == keys.up or key == keys.w or key == keys.numPad8 then
            if nOption > 1 then
                nOption = nOption - 1
            end
        elseif key == keys.down or key == keys.s or key == keys.numPad2 then
            if nOption < #itemList then
                nOption = nOption + 1
            end
        elseif key == keys.enter or key == keys.numPadEnter then
            if #itemList < 1 then
                addNewLocation()
            elseif isStargateConnected() == true then
                disconnectStargate()
            elseif editor == true then
                editLocationDetails()
            elseif editor == false then
                dial(itemList[nOption])
            end
        elseif key == keys.insert and editor == true then
            addNewLocation()
        elseif key == keys.delete and editor == true then
            removeItem(nOption)
        elseif key == keys.d or key == keys.right or key == keys.numPad4 then
            editorMode()
        elseif key == keys.a or key == keys.left or key == keys.numPad6 then
            editorMode()
        elseif key == keys.pageUp and editor == true then
            moveItemUp(nOption)
        elseif key == keys.pageDown and editor == true then
            moveItemDown(nOption)
        elseif key == keys.home then
            nOption = 1
        elseif key == keys['end'] then
            nOption = #itemList
        end
    elseif event == "mouse_scroll" and gateIsDialing ~= true then
        if key == -1 then
            if nOption > 1 then
                nOption = nOption - 1
            end
        elseif key == 1 then
            if nOption < #itemList then
                nOption = nOption + 1
            end
        end
    elseif event == "mouse_click" and gateIsDialing ~= true then
        if #itemList < 1 then
            addNewLocation()
        elseif isStargateConnected() == true then
            disconnectStargate()
        elseif editor == true then
            editLocationDetails()
        elseif editor == false then
            dial(itemList[nOption])
        end
    elseif monitor ~= nil and event == "monitor_touch" and gateIsDialing ~= true then
        if (y < 1000) and isStargateConnected() == true then
            disconnectStargate()
        -- Top Third of the Monitor
        elseif ((y < mh/3) and (x < mw/3)) then
            if editor == true then
                -- addNewLocation()
            else
                dial(itemList[nOption])
            end
        elseif ((y < mh/3) and (x > mw/3) and (x < (mw/3)*2) ) then
            if nOption > 1 then
                nOption = nOption - 1
            end
        elseif ((y < mh/3) and (x > (mw/3)*2)) then
            if editor == true then 
                moveItemUp(nOption)
            else
                nOption = 1
            end
        -- Middle Third of the Monitor
        elseif ((y > mh/3) and (y < (mh/3)*2)) and ((x < mw/3) or (x > (mw/3)*2)) then
            editorMode()
        elseif ((y > mh/3) and (y < (mh/3)*2)) and ((x > mw/3) and (x < (mw/3)*2)) then
            if editor == true then
                -- editLocationDetails()
            else
                -- dial(itemList[nOption])
            end
        -- Bottom Third of the Monitor
        elseif ((y > (mh/3)*2) and (x < mw/3)) and editor == true then
            removeItem(nOption)
        elseif ((y > (mh/3)*2) and (x > mw/3) and (x < (mw/3)*2)) then
            if nOption < #itemList then
                nOption = nOption + 1
            end
        elseif ((y > (mh/3)*2) and (x > (mw/3)*2)) then
            if editor == true then
                moveItemDown(nOption)
            else
                nOption = #itemList
            end
        end
    end
end
