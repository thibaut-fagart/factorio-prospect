
require "defines"
require "config"

local logger = require 'libs/logger'
local l = logger.new_logger()
local isdebug = false
game.oninit(function()
    initGeologyGlobals()
--    startingItems()

end)
game.onload(function()
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


end
function startingItems()

    game.player.force.researchalltechnologies()
    game.player.insert{name="solar-panel", count=10}
    game.player.insert{name="medium-electric-pole", count=10}
    game.player.insert{name="copper-ore", count=500}

    game.player.insert{name="coal", count=100}
    game.player.insert{name="steel-axe", count=10}
    game.player.insert{name="geology-lab", count=10}
    game.player.insert{name="copper-ore-map", count=100}
    game.player.insert{name="resource-monitor", count=1}
end



-- returns the CLOSEST deposit of the given ore in an square area of the given radius around origin
function finddeposit(ore, origin, maxradius)
    local searched = ore
    local result
    local closest = 0
    debug("finddeposit("..ore..",".. posToString(origin)..", "..maxradius..")")
--    start small, then widen out
    local radius = 50
    repeat
        radius = math.min(maxradius, 2*radius)
        debug("searching, radius = ".. radius)
        local findResults = game.findentitiesfiltered{area = {{origin.x - radius, origin.y - radius}, {origin.x + radius,origin.y + radius}}, name=searched }
        debug(" #found ".. #findResults)
         for _, entity in ipairs(findResults) do
             local currentDist = distance(entity.position, origin)
             if closest == 0 then
                 closest = currentDist
                 result = entity
             elseif closest > currentDist then
                 closest = currentDist
                 result = entity
             end
    	end
    	if result ~=nil then break
    	end
    until radius == maxradius
    return result
end
game.onevent(defines.events.onbuiltentity, function(event)
    if nil ~= string.find(event.createdentity.name , "-map") then
        local searchedResource = string.sub(event.createdentity.name, 1, string.find (event.createdentity.name, "-map")-1)
        local pos ={x = event.createdentity.position.x, y = event.createdentity.position.y}

        local deposit = finddeposit(searchedResource,pos,maxProspectionRadius)
        if deposit ~=nil then
            if game.player.gui.left.geology ~= nil then game.player.gui.left.geology.destroy() end
            if game.player.gui.left.geologyMinimized ~= nil then game.player.gui.left.geologyMinimized.destroy() end
            glob.flags.resultsVisible = 0
            addProspectionResults(deposit)
        else
            game.player.print('no deposit found')
            addFailedProspection(searchedResource,pos)
        end
--        consume the map after use
		event.createdentity.destroy()
	end
end)

-- returns the distance between the 2 positions
function distance(position1, position2)
    local dx= position2.x-position1.x
    local dy= position2.y-position1.y
    return math.sqrt(dx*dx+dy*dy)
end


-- returns the direction of position2 relative to position1
function getDir(position1, position2)
    local dx = position2.x-position1.x
    local dy = -1* (position2.y-position1.y) -- invert because factorio y axis is downward (S is > N)
    local dir = '' -- presentable direction N, NE, ...
    local theta -- angle in polar coordinates, in ]0, 2pi[
    local pi8 = math.pi/8
    if not(dy ==0 and dx <0 ) then
        theta = math.atan2(dy, dx)+math.pi
        if theta < 0 then theta = theta +2*math.pi end
        local dirs = {'E', 'NE','NE','N','N','NW','NW','W','W','SW','SW','S','S','SE','SE','E' }
        dir = dirs[1+math.floor(theta/pi8)] --[[tables are 1 based]]
    else
        dir = 'E'
    end
    return dir
end

function debug(msg)
    if isdebug then
        l:log(msg)
        game.player.print(msg)
    end
end
function debugDepositTiles(list)
    if isdebug then
        for _, pos in ipairs(list) do
            l:log("[x="..pos.x..", y="..pos.y.."]")
            local overlay = game.createentity{name="rm_overlay", position = pos}
                overlay.minable = false
                overlay.destructible = false
            if glob.overlayStack == nil then glob.overlayStack = {} end
            table.insert(glob.overlayStack, overlay)
        end
    end

end
function posToString(pos)
    return "[x="..pos.x..", y="..pos.y.."]"
end
function addProspectionResults(deposit)
    if nil ~= deposit then
        debug(deposit.name .. ' deposit position ' .. posToString(deposit.position))
    else
        debug ('addProspectionResults deposit==nil')
        return
    end
    local alreadySurveyed = false

    for index,entity in  ipairs(glob.prospectionresults) do
        debug("previously surveyed deposit ".. index .. ", name=".. entity.name)
--         do not check other resources deposits
        if entity.name == deposit.name  then
            local depositTiles =getDepositTiles(entity.position, entity.name)
            debug("previously surveyed deposit ".. index)
--            checking for presence of deposit.positon in the list doesn't work because of coords being floats
            for _,position in ipairs(depositTiles) do
--                 worst case, dist of 2 diagonal cells would be < 2 * sqrt(2)
                if distance(position, deposit.position) < 2.28 then
                    debug("deposit already surveyed ")
                    alreadySurveyed = true
                    break;
                end
            end
            if alreadySurveyed then break end
        end
    end
    if not(alreadySurveyed) then
        table.insert(glob.prospectionresults, deposit)
        debugDepositTiles(getDepositTiles(deposit.position, deposit.name))
--        force showing the results is they were not shown
    else
        debug("deposit already prospected")
    end
--    if the UI was previously closed, make it visible
    if glob.flags.resultsVisible == 0 then
        glob.flags.resultsVisible = 1
    end
    if isdebug then l:dump("logs/deposit_".. game.tick ) end
    
    showProspectionGUI()
end
function addFailedProspection(resource, position)
    table.insert(glob.failedprospections, {name=resource, position=position})
    if  glob.flags.resultsVisible == 0 then  glob.flags.resultsVisible = 1 end
    showProspectionGUI()
end

function showProspectionGUI()
	if glob.flags.resultsVisible == 1 then
		if game.player.gui.left.geologyFrame ~= nil then game.player.gui.left.geologyFrame.destroy() end
		local rootFrame = game.player.gui.left.add{type = "frame", name = "geologyFrame", caption = {"geologyCaption"}, direction = "vertical"}
		rootFrame.add{type = "flow", name = "geologyFlow", direction = "horizontal"}
		rootFrame.geologyFlow.add{type = "button", name = "geologyMin", caption = {"minButtonCaption"}, style = "smallerButtonFont"}
		rootFrame.geologyFlow.add{type = "button", name = "geologyClose", caption = {"geologyClose"}, style = "smallerButtonFont"}

		local opt = glob.flags
		if (#glob.prospectionresults > 0) then
			local sum = 1 --[[ resource ]] +1 --[[direction]] +1 --[[distance]] +1 --[[ remove button]]
			local depositsFrame = rootFrame.add{type ="frame", name = "depositTable", caption = {"deposits"}}
            depositsFrame.add{type ="table", name = "depositsTable", colspan = sum}
            depositsFrame.depositsTable.add{type = "label", name = "depositTypeLabelHead", caption = {"depositTypeLabelHead"}}
            depositsFrame.depositsTable.add{type = "label", name = "depositDirectionLabelHead", caption = {"depositDirectionLabelHead"}}
            depositsFrame.depositsTable.add{type = "label", name = "depositDistanceLabelHead", caption = {"depositDistanceLabelHead"}}
            depositsFrame.depositsTable.add{type = "label", name = "geologyDummy", caption = " "} --[[remove button]]
            for i,deposit in ipairs(glob.prospectionresults) do
                depositsFrame.depositsTable.add{type = "label", name = "depositTypeLabel"..i, caption = game.getlocalisedentityname(deposit.name) }
                depositsFrame.depositsTable.add{type = "label", name = "depositDirectionLabel"..i, caption = getDir(deposit.position, game.player.position)}
                depositsFrame.depositsTable.add{type = "label", name = "depositDistanceLabel"..i, caption = "".. math.floor(distance (deposit.position, game.player.position))}
                depositsFrame.depositsTable.add{type = "button", name = "depositRemoveButton"..i, caption = {"depositRemoveButtonCaption"}, style = "smallerButtonFont"}
            end
        end
        if #glob.failedprospections > 0 then
            local sum = 1 --[[ resource ]] +1 --[[direction]] +1 --[[distance]] +1 --[[ remove button]]
            local failedFrame = rootFrame.add{type ="frame", name = "failedTable", caption = {"failed"}}
             failedFrame.add{type ="table", name = "prospectionsTable", colspan = sum}
             failedFrame.prospectionsTable.add{type = "label", name = "depositTypeLabelHead", caption = {"failedTypeLabelHead"}}
             failedFrame.prospectionsTable.add{type = "label", name = "depositDirectionLabelHead", caption = {"depositDirectionLabelHead"}}
             failedFrame.prospectionsTable.add{type = "label", name = "depositDistanceLabelHead", caption = {"depositDistanceLabelHead"}}
             failedFrame.prospectionsTable.add{type = "label", name = "geologyDummy", caption = " "} --[[remove button]]
             for i,resourceVsPosition in pairs(glob.failedprospections) do
                 failedFrame.prospectionsTable.add{type = "label", name = "depositTypeLabel"..i, caption = game.getlocalisedentityname(resourceVsPosition.name) }
                 failedFrame.prospectionsTable.add{type = "label", name = "depositDirectionLabel"..i, caption = getDir(resourceVsPosition.position, game.player.position)}
                 failedFrame.prospectionsTable.add{type = "label", name = "depositDistanceLabel"..i, caption = "".. math.floor(distance (resourceVsPosition.position, game.player.position))}
                 failedFrame.prospectionsTable.add{type = "button", name = "failedRemoveButton"..i, caption = {"depositRemoveButtonCaption"}, style = "smallerButtonFont"}
             end
        end
    elseif glob.flags.resultsVisible == 2 then
   		if game.player.gui.left.geologyFrame ~= nil then game.player.gui.left.geologyFrame.destroy() end
   		if game.player.gui.left.geologyFrameMinimized ~= nil then game.player.gui.left.geologyFrameMinimized.destroy() end
   		game.player.gui.left.add{type="button", name="geologyFrameMinimized", caption="G"}
   		game.player.gui.left.geologyFrameMinimized.style.fontcolor = {r = 0, b = 1, g = 0}
   	elseif glob.flags.resultsVisible == 0 then
   		-- do nothing
   	end
end
game.onevent(defines.events.onguiclick, function(event)
    if string.find (event.element.name, "depositRemoveButton") ~= nil then
        local txt, cnt = string.gsub (event.element.name, "depositRemoveButton" , "")
        debug("removing index ".. cnt)
        table.remove(glob.prospectionresults, tonumber(cnt))
        for _,overlay in ipairs(glob.overlayStack) do
            if overlay.valid then
                overlay.destroy()
            end
        end
        showProspectionGUI()
    elseif string.find (event.element.name, "failedRemoveButton") ~= nil then
        local txt, cnt = string.gsub (event.element.name, "depositRemoveButton" , "")
        debug("removing failed at index ".. cnt)
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
game.onevent(defines.events.ontick, function(event)
    if game.tick % glob.flags.updateFreq == 11 then
        debug("updating prospection")
            showProspectionGUI()
   end
end)

function getDepositTiles(startPos, resType)
	local listA = {}
	local listB = {}
	local tmpPos = {x = math.floor(startPos.x) + 0.5, y = math.floor(startPos.y) + 0.5}
	local tmpEntry = {}

	table.insert(listA, {x = tmpPos.x, y = tmpPos.y})

	while (#listA > 0) do
		tmpEntry = {x = listA[#listA].x, y = listA[#listA].y }
		table.remove(listA)
		table.insert(listB, tmpEntry)
		if checkTile({x = tmpEntry.x, y = tmpEntry.y - 1}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x, y = tmpEntry.y - 1})
		end
		if checkTile({x = tmpEntry.x, y = tmpEntry.y + 1}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x, y = tmpEntry.y + 1})
		end
		if checkTile({x = tmpEntry.x - 1, y = tmpEntry.y}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x - 1, y = tmpEntry.y})
		end
		if checkTile({x = tmpEntry.x + 1, y = tmpEntry.y}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x + 1, y = tmpEntry.y})
		end
		if checkTile({x = tmpEntry.x + 1, y = tmpEntry.y + 1}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x + 1, y = tmpEntry.y + 1})
		end
		if checkTile({x = tmpEntry.x - 1, y = tmpEntry.y - 1}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x - 1, y = tmpEntry.y - 1})
		end
		if checkTile({x = tmpEntry.x + 1, y = tmpEntry.y - 1}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x + 1, y = tmpEntry.y - 1})
		end
		if checkTile({x = tmpEntry.x - 1, y = tmpEntry.y + 1}, resType, listA, listB) == true then
			table.insert(listA, {x = tmpEntry.x - 1, y = tmpEntry.y + 1})
		end
	end

	return listB
end

function checkTile(pos, resType , listA, listB)
	local tmpTile = game.findentitiesfiltered{area = {{pos.x - 0.01, pos.y - 0.01}, {pos.x + 0.01, pos.y + 0.01}}, name = resType}
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
