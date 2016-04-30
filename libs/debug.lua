local logger = require 'libs/logger'
local l = logger.new_logger()

function debug(msg)
--    game.player.print(msg)
    l:log(msg)
end

function debugDepositTiles(list)
    for _, pos in ipairs(list) do
        --            l:log("[x="..pos.x..", y="..pos.y.."]")
        local overlay = surface().create_entity { name = "overlay", position = pos }
        overlay.minable = false
        overlay.destructible = false
        if glob.overlayStack == nil then glob.overlayStack = {} end
        table.insert(glob.overlayStack, overlay)
    end
end
