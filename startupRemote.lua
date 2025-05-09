-- Make AddressList if it doesnt exist
if not fs.exists("AddressList.lua") then
    local f = io.open("AddressList.lua", "w")
    f:write("return {\n\t{locName=\"Home\", address={1,2,3,4,5,6,7,8,0}}\n}")
end

-- Main Menu Go!
shell.run("remote")