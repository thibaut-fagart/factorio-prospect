local logger = require 'logger'
local l = logger.new_logger()

function debug(msg)
    if isdebug then
--        game.player.print(msg)
        l:log(msg)
    end
end

function debugDepositTiles(list)
    if isdebug then
        for _, pos in ipairs(list) do
            --            l:log("[x="..pos.x..", y="..pos.y.."]")
            local overlay = surface().create_entity { name = "overlay", position = pos }
            overlay.minable = false
            overlay.destructible = false
            if glob.overlayStack == nil then glob.overlayStack = {} end
            table.insert(glob.overlayStack, overlay)
        end
    end
end
function table.val_to_str(v)
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    else
        return "table" == type(v) and table.tostring(v) or
                tostring(v)
    end
end

function table.key_to_str(k)
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    else
        return "[" .. table.val_to_str(k) .. "]"
    end
end

function table.tostring(tbl)
    local result, done = {}, {}
    for k, v in ipairs(tbl) do
        table.insert(result, table.val_to_str(v))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result,
                table.key_to_str(k) .. "=" .. table.val_to_str(v))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end