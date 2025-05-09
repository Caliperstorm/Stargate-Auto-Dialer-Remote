local monitor = peripheral.find("monitor")
local nOption = 1
local editor = false
local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
stargateType = interface.getStargateType()
local modem = peripheral.find("modem") or error("No modem attached", 0)
local port = 304 -- change these if you want to only control certain stargates
local responsePort = 303

-- Check if the interface exists and find out what kind
if interface == nil then
    error("No interface attached", 0)
elseif peripheral.find("basic_interface") then
    iType = "basic"
elseif peripheral.find("crystal_interface") then
    iType = "crystal"
elseif peripheral.find("advanced_crystal_interface") then
    iType = "advanced"
end

-- Check and make sure that you are not using a basic interface on anything that isn't the milky way gate
if interface.getStargateType == nil then
    error("No Stargate attached", 0)
elseif interface.getStargateType() ~= "sgjourney:milky_way_stargate" and iType == "basic" then
    error("Error: this Stargate type requires a crystal interface to dial", 0)
end

-- Function to Dial the Milky-Way Stargate
function dial(address)
	modem.transmit(responsePort, port, "dialing")
    local start = interface.getChevronsEngaged() + 1
    local prevSymbol = 0
    for chevron = start,#address.address,1 do
        local symbol = address.address[chevron]
        if stargateType == "sgjourney:milky_way_stargate" and iType == "basic" then
            if (prevSymbol > symbol and (prevSymbol - symbol) < 19) or (prevSymbol < symbol and (symbol - prevSymbol) > 19) then
            -- if chevron % 2 == 0 then
                interface.rotateClockwise(symbol)
            else
                interface.rotateAntiClockwise(symbol)
            end
            while(not interface.isCurrentSymbol(symbol)) do sleep(0) end
            sleep(0.3)
            interface.openChevron()
            sleep(0.5)
            interface.closeChevron()
            sleep(0.5)
            prevSymbol = symbol
        else
            interface.engageSymbol(symbol)
            sleep(0.5)
        end
    end
	modem.transmit(responsePort, port, "complete")
end

-- Script Actually Starts Here
modem.open(responsePort)
while true do
    repeat
		event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
	until channel == port
	if message == "dial" then
		repeat
			event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
		until channel == port
		dial(message)
	elseif message == "isStargateConnected" then
		if interface.isStargateConnected() == true then
			modem.transmit(responsePort, port, "connected")
		else
			modem.transmit(responsePort, port, "not connected")
		end
	elseif message == "disconnect" then
		interface.disconnectStargate()
	end
end
