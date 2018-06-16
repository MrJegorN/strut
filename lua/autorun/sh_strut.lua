strut = {}

print("[Strut] Initializing core files...")

local path = "autorun/strut/"

for _, file in pairs(file.Find(path.."client/*", "LUA")) do
    local filepath = path.."client/"..file

    print("    [Strut] Adding clientside file "..filepath)

    if SERVER then
        AddCSLuaFile(filepath)
    else
        include(filepath)
    end
end

for _, file in pairs(file.Find("autorun/strut/shared/*", "LUA")) do
    local filepath = path.."shared/"..file

    print("    [Strut] Adding shared file "..filepath)

    AddCSLuaFile(filepath)
    include(filepath)
end

for _, file in pairs(file.Find("autorun/strut/server/*", "LUA")) do
    local filepath = path.."server/"..file

    print("    [Strut] Adding serverside file "..filepath)

    if SERVER then include(filepath) end
end