require "defines"
require "config"

local isdebug = false
if isdebug then require "libs/debug" end
local maxProspectionRadius = 1000
local MAX_PROSPECT_PER_REQUEST = 30
local CHUNK_SIZE = 32

script.on_init(function()
    initGeologyGlobals()
    --    startingItems()
end)
script.on_load(function()
    initGeologyGlobals()
    --    if isdebug and game.player.getinventory(defines.inventory.playermain).getcontents()["copper-ore-map"] == nil then
    --        game.player.insert{name="copper-ore-map", count=10 }
    --    end
end)


function initGeologyGlobals()
    if glob.flags == nil then
        glob.flags = {}
    end
    if glob.prospectionresults == nil then
        glob.prospectionresults = {}
    end
    if glob.failedprospections == nil then
        glob.failedprospections = {}
    end
    if glob.overlayStack == nil then
        glob.overlayStack = {}
    end
    if glob.flags.resultsVisible == nil then
        glob.flags.resultsVisible = 0
    end
    if glob.flags.updateFreq == nil then
        glob.flags.updateFreq = 600
    end
    if glob.flags.prospectFreq == nil then
        glob.flags.prospectFreq = 60
    end

    if glob.running_prospections == nil then
        glob.running_prospections = {} --  {origin:position, max_chunk_radius, current_chunk_radius,requestedChunks}
    end
    if glob.prospect_index == nil then
        glob.prospect_index = 1
    end
    if glob.performance  == nil then
        glob.performance = {}
    end
    if glob.performance.prospectCount  == nil then
        glob.performance.prospectCount = 0
    end
    if glob.performance.maxProspectPerBatch  == nil then
        glob.performance.maxProspectPerBatch = MAX_PROSPECT_PER_REQUEST
    end

end

function startingItems()
    -- only useable from console
    game.player.force.research_all_technologies()
    game.player.insert { name = "solar-panel", count = 10 }
    game.player.insert { name = "medium-electric-pole", count = 10 }
    game.player.insert { name = "copper-ore", count = 500 }

    game.player.insert { name = "coal", count = 100 }
    game.player.insert { name = "steel-axe", count = 10 }
    game.player.insert { name = "geology-lab", count = 10 }
    game.player.insert { name = "copper-ore-map", count = 10 }
    game.player.insert { name = "iron-ore-map", count = 10 }
    game.player.insert { name = "rutile-ore-map", count = 10 }
    game.player.insert { name = "tin-ore-map", count = 10 }
    game.player.insert { name = "tungsten-ore-map", count = 10 }
    game.player.insert { name = "bauxite-ore-map", count = 10 }
    game.player.insert { name = "gem-ore-map", count = 10 }
    game.player.insert { name = "gold-ore-map", count = 10 }
    game.player.insert { name = "silver-ore-map", count = 10 }
    game.player.insert { name = "lead-ore-map", count = 10 }
    game.player.insert { name = "zinc-ore-map", count = 10 }
    game.player.insert { name = "cobalt-ore-map", count = 10 }
    game.player.insert { name = "nickel-ore-map", count = 10 }
    game.player.insert { name = "quartz-map", count = 10 }
    game.player.insert { name = "resource-monitor", count = 1 }
end

function surface()
    return game.player.surface
end
function isTableEmpty (table)
    table.empty = nil
    for k,v in pairs(table) do
        if v ~=nil then return false end
    end
    return true
end
script.on_event(defines.events.on_chunk_generated, function(event)
    --    debug("chunk generated "..table.tostring(event.area))
    glob.performance.prospectCount = 0
    local chunk = { x = event.area.left_top.x / CHUNK_SIZE, y = event.area.left_top.y / CHUNK_SIZE }
    local chunk_key = table.tostring(chunk)
        for idx,request in pairs(glob.running_prospections) do
            if request.requestedChunks[chunk_key]~=nil then
                if isdebug then debug("checking new generated chunk " .. chunk_key) end
                prospectChunk(request,{},chunk)
                request.requestedChunks[chunk_key] = nil
            end
        end
end)

-- return true (and removes request from glob) if prospect is successful
function prospectChunk(prospectionRequest,chunksToGenerate, chunk)
    if isdebug then debug('checking chunk ' .. table.tostring(chunk)) end
    glob.performance.prospectCount = glob.performance.prospectCount +1
    if surface().is_chunk_generated(chunk) then

        local findResults = surface().find_entities_filtered {
            area = {
                { CHUNK_SIZE * chunk.x, CHUNK_SIZE * chunk.y },
                { CHUNK_SIZE * (1+chunk.x), CHUNK_SIZE * (1 + chunk.y) }
            },
            name = prospectionRequest.prospecting
        }
        if #findResults > 0 then
            if isdebug then debug(" found " .. #findResults ..' ' .. prospectionRequest.prospecting .. ' in chunk' .. table.tostring(chunk)) end
            glob.running_prospections[prospectionRequest.index] = nil
            addProspectionResults(findResults[1])
            return true
        end
    else
        if isdebug then debug('chunk is NOT generated, adding for later prospection') end
        chunksToGenerate[table.tostring(chunk)] = chunk
        chunksToGenerate.empty=false
    end
    return false
end

-- first search generated chunks in the current radius (origin,current_chunk_radius)
-- if none found register the prospection request for async prospection and request generation of next radius chunks
function prospectNextRadius(prospectionRequest)
    local chunksToGenerate = {empty=true }
    local Ox = prospectionRequest.originChunk.x
    local Oy = prospectionRequest.originChunk.y
    if isdebug then debug('prospectNextRadius ' .. table.tostring(prospectionRequest)) end
    while chunksToGenerate.empty and glob.performance.prospectCount < glob.performance.maxProspectPerBatch do
        local r = prospectionRequest.current_chunk_radius
        if isdebug then debug('prospectNextRadius ' .. r .. ' chunksToGenerate '.. table.tostring(chunksToGenerate) .. ',request = ' .. table.tostring(prospectionRequest)) end
        if r == 0 then
            prospectChunk(prospectionRequest, chunksToGenerate,  { x = Ox, y = Oy })
            prospectionRequest.current_chunk_radius  = 1
        else
            if isdebug then  debug('iterating ' .. -r .. ' to ' .. r -1) end
            local start = prospectionRequest.currentRadiusProgress
            if start == nil then
                start = -r
                prospectionRequest.currentRadiusProgress = start
            else
                if isdebug then debug("resuming radius from " .. start) end
            end
            for i = start, r-1 do
                local chunk
                chunk = { x = Ox + i, y = Oy + r }
                if prospectChunk(prospectionRequest, chunksToGenerate, chunk) then return end
                chunk = { x = Ox + r, y = Oy -i }
                if prospectChunk(prospectionRequest, chunksToGenerate, chunk) then return end
                chunk = { x = Ox - i, y = Oy - r }
                if prospectChunk(prospectionRequest, chunksToGenerate, chunk) then return end
                chunk = { x = Ox - r, y = Oy + i }
                if prospectChunk(prospectionRequest, chunksToGenerate, chunk) then return end
                prospectionRequest.currentRadiusProgress = i+1
                if glob.performance.prospectCount >= glob.performance.maxProspectPerBatch then
                    if isdebug then debug("pausing, maxProspectPerBatch reached")end
                    break
                end
            end
            if prospectionRequest.currentRadiusProgress >= r-1 then
                if isdebug then debug ("radius complete, expanding, resetting currentRadius") end
                prospectionRequest.current_chunk_radius = prospectionRequest.current_chunk_radius + 1
                prospectionRequest.currentRadiusProgress = nil
            end
        end
    end
    if isdebug then debug("prospectNextRadius searched " .. glob.performance.prospectCount) end
    chunksToGenerate.empty = nil
    prospectionRequest.requestedChunks = chunksToGenerate
    if isdebug then debug('requesting to generate chunks for request ' .. table.tostring(prospectionRequest)) end
    for key, chunk in pairs(chunksToGenerate) do
        if isdebug then  debug('generate ' .. table.tostring(chunk)) end
        surface().request_to_generate_chunks({chunk.x*CHUNK_SIZE,chunk.y*CHUNK_SIZE}, 1)
    end
end

--on prospection request, prospect only GENERATED chunks (iterate in a square shaped, start N ->E ->S->W).
-- When out of generated blocks, register on_chunk_generated hook and ask for generating the next radius.
-- in the call back, look up current prospection requests, and if chunk belongs to them check it
script.on_event(defines.events.on_built_entity, function(event)
    glob.performance.prospectCount = 0
    if nil ~= string.find(event.created_entity.name, "-map") then
        local searchedResource = string.sub(event.created_entity.name, 1, string.find(event.created_entity.name, "-map") - 1)
        local pos = { x = event.created_entity.position.x, y = event.created_entity.position.y }
        local prospection = {
            index = glob.prospect_index,
            prospecting = searchedResource,
            origin = pos,
            originChunk = { x = math.floor(pos.x / CHUNK_SIZE), y = math.floor(pos.y / CHUNK_SIZE) },
            max_chunk_radius = maxProspectionRadius,
            current_chunk_radius = 0,
            requestedChunks = {},
        }
        glob.prospect_index = glob.prospect_index + 1
        if isdebug then debug('adding prospection ' .. table.tostring(prospection)) end
        glob.running_prospections[prospection.index] = prospection
        prospection.underProspection = true
        prospectNextRadius(prospection)
        prospection.underProspection = false
        addRunningProspection()

        --        consume the map after use
        event.created_entity.destroy()
    end
end)

-- returns the distance between the 2 positions
function distance(position1, position2)
    local dx = position2.x - position1.x
    local dy = position2.y - position1.y
    return math.sqrt(dx * dx + dy * dy)
end


-- returns the direction of position2 relative to position1
function getDir(position1, position2)
    local dx = position2.x - position1.x
    local dy = -1 * (position2.y - position1.y) -- invert because factorio y axis is downward (S is > N)
    local dir = '' -- presentable direction N, NE, ...
    local theta -- angle in polar coordinates, in ]0, 2pi[
    local pi8 = math.pi / 8
    if not (dy == 0 and dx < 0) then
        theta = math.atan2(dy, dx) + math.pi
        if theta < 0 then theta = theta + 2 * math.pi end
        local dirs = { 'E', 'NE', 'NE', 'N', 'N', 'NW', 'NW', 'W', 'W', 'SW', 'SW', 'S', 'S', 'SE', 'SE', 'E' }
        dir = dirs[1 + math.floor(theta / pi8)] --[[tables are 1 based]]
    else
        dir = 'E'
    end
    return dir
end


function addProspectionResults(deposit)
    if game.player.gui.left.geology ~= nil then game.player.gui.left.geology.destroy() end
    if game.player.gui.left.geologyMinimized ~= nil then game.player.gui.left.geologyMinimized.destroy() end
    glob.flags.resultsVisible = 0

    if nil ~= deposit then
        if isdebug then debug(deposit.name .. ' deposit position ' .. table.tostring(deposit.position)) end
    else
        if isdebug then debug('addProspectionResults deposit==nil') end
        return
    end
    local alreadySurveyed = false

    for index, entity in ipairs(glob.prospectionresults) do
        if isdebug then  debug("previously surveyed deposit " .. index .. ", name=" .. entity.name) end
        --         do not check other resources deposits
        if entity.name == deposit.name then
            local depositTiles = getDepositTiles(entity.position, entity.name)
            if isdebug then  debug("previously surveyed deposit " .. index) end
            --            checking for presence of deposit.positon in the list doesn't work because of coords being floats
            for _, position in ipairs(depositTiles) do
                --                 worst case, dist of 2 diagonal cells would be < 2 * sqrt(2)
                if distance(position, deposit.position) < 2.28 then
                    if isdebug then debug("deposit already surveyed ") end
                    alreadySurveyed = true
                    break;
                end
            end
            if alreadySurveyed then break end
        end
    end
    if not (alreadySurveyed) then
        table.insert(glob.prospectionresults, deposit)
        if isdebug then debugDepositTiles(getDepositTiles(deposit.position, deposit.name)) end
        --        force showing the results is they were not shown
    else
        if isdebug then debug("deposit already prospected") end
    end
    --    if the UI was previously closed, make it visible
    if glob.flags.resultsVisible == 0 then
        glob.flags.resultsVisible = 1
    end
--    if isdebug then l:dump("logs/deposit_" .. game.tick) end

    showProspectionGUI()
end

function addRunningProspection()
    if glob.flags.resultsVisible == 0 then glob.flags.resultsVisible = 1 end
    showProspectionGUI()
end

function addFailedProspection(resource, position)
    table.insert(glob.failedprospections, { name = resource, position = position })
    if glob.flags.resultsVisible == 0 then glob.flags.resultsVisible = 1 end
    showProspectionGUI()
end

script.on_event(defines.events.on_tick, function(event)
    glob.performance.prospectCount = 0
    if game.tick % glob.flags.updateFreq == 11 then
        if isdebug then debug("updating prospection") end
        showProspectionGUI()
    end
    if game.tick % glob.flags.prospectFreq == 11 then
        if isdebug then  debug("checking for prospections to resume") end
        for i,request in pairs(glob.running_prospections) do
            if  isTableEmpty(request.requestedChunks) and not request.underProspection then
                if isdebug then debug("found a prospection to resume") end
                request.underProspection = true
                prospectNextRadius(request)
                request.underProspection = false
                if glob.performance.prospectCount > glob.performance.maxProspectPerBatch then break end
            end
        end
    end
end)


function showProspectionGUI()
    if isdebug then debug(table.tostring(glob)) end
    if glob.flags.resultsVisible == 1 then
        if game.player.gui.left.geologyFrame ~= nil then game.player.gui.left.geologyFrame.destroy() end
        local rootFrame = game.player.gui.left.add { type = "frame", name = "geologyFrame", caption = { "geologyCaption" }, direction = "vertical" }
        rootFrame.add { type = "flow", name = "geologyFlow", direction = "horizontal" }
        rootFrame.geologyFlow.add { type = "button", name = "geologyMin", caption = { "minButtonCaption" }, style = "smallerButtonFont" }
        rootFrame.geologyFlow.add { type = "button", name = "geologyClose", caption = { "geologyClose" }, style = "smallerButtonFont" }
        rootFrame.geologyFlow.add { type = "button", name = "geologyIncProspects", caption = { "geologyIncProspects" }, style = "smallerButtonFont" }
        rootFrame.geologyFlow.add { type = "button", name = "geologyDecProspects", caption = { "geologyDecProspects" }, style = "smallerButtonFont" }
        rootFrame.geologyFlow.add { type = "label", name = "geologyMaxProspects", caption =  ''.. glob.performance.maxProspectPerBatch }

        local opt = glob.flags
        if (#glob.prospectionresults > 0) then
            local sum = 1 --[[ resource ]] + 1 --[[direction]] + 1 --[[distance]] + 1 --[[ remove button]]
            local depositsFrame = rootFrame.add { type = "frame", name = "depositTable", caption = { "deposits" } }
            depositsFrame.add { type = "table", name = "depositsTable", colspan = sum }
            depositsFrame.depositsTable.add { type = "label", name = "depositTypeLabelHead", caption = { "depositTypeLabelHead" } }
            depositsFrame.depositsTable.add { type = "label", name = "depositDirectionLabelHead", caption = { "depositDirectionLabelHead" } }
            depositsFrame.depositsTable.add { type = "label", name = "depositDistanceLabelHead", caption = { "depositDistanceLabelHead" } }
            depositsFrame.depositsTable.add { type = "label", name = "geologyDummy", caption = " " } --[[remove button]]
            for i, deposit in ipairs(glob.prospectionresults) do
                if isdebug then debug('adding deposit ' .. deposit.name .. ' to gui') end
                depositsFrame.depositsTable.add { type = "label", name = "depositTypeLabel" .. i, caption = game.get_item_prototype(deposit.name).localised_name }
                depositsFrame.depositsTable.add { type = "label", name = "depositDirectionLabel" .. i, caption = getDir(deposit.position, game.player.position) }
                depositsFrame.depositsTable.add { type = "label", name = "depositDistanceLabel" .. i, caption = "" .. math.floor(distance(deposit.position, game.player.position)) }
                depositsFrame.depositsTable.add { type = "button", name = "depositRemoveButton" .. i, caption = { "depositRemoveButtonCaption" }, style = "smallerButtonFont" }
            end
        end
        if #glob.failedprospections > 0 then
            local sum = 1 --[[ resource ]] + 1 --[[direction]] + 1 --[[distance]] + 1 --[[ remove button]]
            local failedFrame = rootFrame.add { type = "frame", name = "failedTable", caption = { "failed" } }
            failedFrame.add { type = "table", name = "prospectionsTable", colspan = sum }
            failedFrame.prospectionsTable.add { type = "label", name = "depositTypeLabelHead", caption = { "failedTypeLabelHead" } }
            failedFrame.prospectionsTable.add { type = "label", name = "depositDirectionLabelHead", caption = { "depositDirectionLabelHead" } }
            failedFrame.prospectionsTable.add { type = "label", name = "depositDistanceLabelHead", caption = { "depositDistanceLabelHead" } }
            failedFrame.prospectionsTable.add { type = "label", name = "geologyDummy", caption = " " } --[[remove button]]
            for i, resourceVsPosition in pairs(glob.failedprospections) do
                failedFrame.prospectionsTable.add { type = "label", name = "depositTypeLabel" .. i, caption = game.get_item_prototype(resourceVsPosition.name).localised_name }
                failedFrame.prospectionsTable.add { type = "label", name = "depositDirectionLabel" .. i, caption = getDir(resourceVsPosition.position, game.player.position) }
                failedFrame.prospectionsTable.add { type = "label", name = "depositDistanceLabel" .. i, caption = "" .. math.floor(distance(resourceVsPosition.position, game.player.position)) }
                failedFrame.prospectionsTable.add { type = "button", name = "failedRemoveButton" .. i, caption = { "depositRemoveButtonCaption" }, style = "smallerButtonFont" }
            end
        end
        if not isTableEmpty(glob.running_prospections) then
            local sum = 1 --[[ resource ]] + 1 --[[radius]] + 1 --[[ remove button]]
            local runningFrame = rootFrame.add { type = "frame", name = "runningTable", caption = { "running" } }
            runningFrame.add { type = "table", name = "prospectionsTable", colspan = sum }
            runningFrame.prospectionsTable.add { type = "label", name = "prospectionTypeLabelHead", caption = { "prospectionTypeLabelHead" } }
            runningFrame.prospectionsTable.add { type = "label", name = "prospectionRadiusLabelHead", caption = { "prospectionRadiusLabelHead" } }
            runningFrame.prospectionsTable.add { type = "label", name = "geologyDummy", caption = " " } --[[remove button]]
            for i, prospection in pairs(glob.running_prospections) do
                runningFrame.prospectionsTable.add { type = "label", name = "prospectionTypeLabel" .. i, caption = game.get_item_prototype(prospection.prospecting).localised_name }
                runningFrame.prospectionsTable.add { type = "label", name = "prospectionRadiusLabel" .. i, caption = "" .. CHUNK_SIZE*prospection.current_chunk_radius }
                runningFrame.prospectionsTable.add { type = "button", name = "runningRemoveButton" .. i, caption = { "cancelProspectionButtonCaption" }, style = "smallerButtonFont" }
            end
        end
    elseif glob.flags.resultsVisible == 2 then
        if game.player.gui.left.geologyFrame ~= nil then game.player.gui.left.geologyFrame.destroy() end
        if game.player.gui.left.geologyFrameMinimized ~= nil then game.player.gui.left.geologyFrameMinimized.destroy() end
        game.player.gui.left.add { type = "button", name = "geologyFrameMinimized", caption = "G" }
        game.player.gui.left.geologyFrameMinimized.style.font_color = { r = 0, b = 1, g = 0 }
    elseif glob.flags.resultsVisible == 0 then
        -- do nothing
    end
end

script.on_event(defines.events.on_gui_click, function(event)
    if string.find(event.element.name, "geologyIncProspects") ~= nil then
        glob.performance.maxProspectPerBatch = glob.performance.maxProspectPerBatch+10
    elseif string.find(event.element.name, "geologyDecProspects") ~= nil then
        glob.performance.maxProspectPerBatch = math.max(10,glob.performance.maxProspectPerBatch+10)
    elseif string.find(event.element.name, "depositRemoveButton") ~= nil then
        local txt, cnt = string.gsub(event.element.name, "depositRemoveButton", "")
        if isdebug then debug("removing index " .. cnt) end
        table.remove(glob.prospectionresults, tonumber(cnt))
        for _, overlay in ipairs(glob.overlayStack) do
            if overlay.valid then
                overlay.destroy()
            end
        end
        showProspectionGUI()
    elseif string.find(event.element.name, "runningRemoveButton") ~= nil then
        local txt, cnt = string.gsub(event.element.name, "runningRemoveButton", "")
        if isdebug then debug("removing index " .. cnt) end
        glob.running_prospections[cnt] = nil
        showProspectionGUI()
    elseif string.find(event.element.name, "failedRemoveButton") ~= nil then
        local txt, cnt = string.gsub(event.element.name, "depositRemoveButton", "")
        if isdebug then debug("removing failed at index " .. cnt) end
        table.remove(glob.failedprospections, tonumber(cnt))
        showProspectionGUI()
    elseif event.element.name == "geologyMin" then
        game.player.gui.left.geologyFrame.destroy()
        glob.flags.resultsVisible = 2
        showProspectionGUI()
    elseif event.element.name == "geologyFrameMinimized" then
        game.player.gui.left.geologyFrameMinimized.destroy()
        glob.flags.resultsVisible = 1
        showProspectionGUI()
    elseif event.element.name == "geologyClose" then
        game.player.gui.left.geologyFrame.destroy()
        --        glob.prospectionresults = {}
        glob.flags.resultsVisible = 0
    end
end)

function getDepositTiles(startPos, resType)
    local listA = {}
    local listB = {}
    local tmpPos = { x = math.floor(startPos.x) + 0.5, y = math.floor(startPos.y) + 0.5 }
    local tmpEntry = {}

    table.insert(listA, { x = tmpPos.x, y = tmpPos.y })

    while (#listA > 0) do
        tmpEntry = { x = listA[#listA].x, y = listA[#listA].y }
        table.remove(listA)
        table.insert(listB, tmpEntry)
        if checkTile({ x = tmpEntry.x, y = tmpEntry.y - 1 }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x, y = tmpEntry.y - 1 })
        end
        if checkTile({ x = tmpEntry.x, y = tmpEntry.y + 1 }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x, y = tmpEntry.y + 1 })
        end
        if checkTile({ x = tmpEntry.x - 1, y = tmpEntry.y }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x - 1, y = tmpEntry.y })
        end
        if checkTile({ x = tmpEntry.x + 1, y = tmpEntry.y }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x + 1, y = tmpEntry.y })
        end
        if checkTile({ x = tmpEntry.x + 1, y = tmpEntry.y + 1 }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x + 1, y = tmpEntry.y + 1 })
        end
        if checkTile({ x = tmpEntry.x - 1, y = tmpEntry.y - 1 }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x - 1, y = tmpEntry.y - 1 })
        end
        if checkTile({ x = tmpEntry.x + 1, y = tmpEntry.y - 1 }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x + 1, y = tmpEntry.y - 1 })
        end
        if checkTile({ x = tmpEntry.x - 1, y = tmpEntry.y + 1 }, resType, listA, listB) == true then
            table.insert(listA, { x = tmpEntry.x - 1, y = tmpEntry.y + 1 })
        end
    end

    return listB
end

function checkTile(pos, resType, listA, listB)
    local tmpTile = surface().find_entities_filtered { area = { { pos.x - 0.01, pos.y - 0.01 }, { pos.x + 0.01, pos.y + 0.01 } }, name = resType }
    if tmpTile[1] ~= nil then
        if not inList(pos, listA) and not inList(pos, listB) then
            return true
        else
            return false
        end
    else
        return false
    end
end
function inList(pos, list)
    for _, listTile in ipairs(list) do
        if (listTile.x == pos.x) and (listTile.y == pos.y) then
            return true
        end
    end
    return false
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