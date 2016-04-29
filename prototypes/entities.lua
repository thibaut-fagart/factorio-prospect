data:extend({
    {
        type = "item",
        name = "geology-lab",
        icon = "__base__/graphics/icons/assembling-machine-1.png",
        flags = { "goes-to-quickbar" },
       category="geology",
        group = "geology",
        subgroup ="geology-labs",
        order = "a[geology-lab]",
        place_result = "geology-lab",
        stack_size = 50
    },
    {
        type = "assembling-machine",
        name = "geology-lab",
        icon = "__base__/graphics/icons/assembling-machine-1.png",
        flags = {"placeable-neutral", "placeable-player", "player-creation"},
        minable = { hardness = 0.2, mining_time = 0.5, result = "geology-lab" },
        max_health = 200,
        corpse = "big-remnants",
        dying_explosion = "medium-explosion",
        resistances =
        {
            {
                type = "fire",
                percent = 70
            }
        },
        collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
        selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
        fast_replaceable_group = "geology",
        animation =
        {
            filename = "__base__/graphics/entity/assembling-machine-1/assembling-machine-1.png",
            priority="high",
            width = 99,
            height = 102,
            frame_count = 32,
            line_length = 8,
            shift = {0.25, -0.1}
        },
        crafting_categories = { "geology" },
        crafting_speed = 0.5,
        energy_source =
        {
            type = "electric",
            usage_priority = "secondary-input",
            emissions = 0.05 / 1.5
        },
        energy_usage = "90kW",
        ingredient_count = 2,
        open_sound = { filename = "__base__/sound/machine-open.ogg", volume = 0.85 },
        close_sound = { filename = "__base__/sound/machine-close.ogg", volume = 0.75 },
        working_sound =
        {
            sound = {
                {
                    filename = "__base__/sound/assembling-machine-t1-1.ogg",
                    volume = 0.8
                },
                {
                    filename = "__base__/sound/assembling-machine-t1-2.ogg",
                    volume = 0.8
                },
            },
            idle_sound = { filename = "__base__/sound/idle1.ogg", volume = 0.6 },
            apparent_volume = 1.5,
        }
    },
    {
    		type = "container",
    		name = "overlay",
    		icon = "__prospect__/graphics/overlay.png",
    		flags = {"placeable-neutral", "player-creation"},
    		minable = {mining_time = 1},
    		order = "b[overlay]",
    		collision_mask = {"resource-layer"},
    		max_health = 100,
    		corpse = "small-remnants",
    		resistances ={{type = "fire",percent = 80}},
    		collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    		selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
    		inventory_size = 1,
    		picture =
    		{
    			filename = "__prospect__/graphics/overlay.png",
    			priority = "extra-high",
    			width = 32,
    			height = 32,
    			shift = {0.0, 0.0}
    		}
    	},
})
for _,resource in ipairs(glob.oretypes) do
    if nil ~= data.raw.resource[resource] then
        data:extend({
            {
                type = "item",
                name = ""..resource.."-map",
                icon = "__prospect__/graphics/icons/"..resource.."-map.png",
                flags = { "goes-to-quickbar" },
                subgroup = "prospection-maps",
                order =  data.raw.resource[resource].order,
--                "c[geology-lab]",
                place_result = ""..resource.."-map-entity",
                stack_size = 50
            },
            {
                type = "container",
                name = "".. resource.."-map-entity",
                icon = "__prospect__/graphics/items/"..resource.."-map.png",
                flags = { "placeable-neutral", "player-creation" },
                minable = { mining_time = 1, result = ""..resource.."-map" },
                max_health = 100,
                corpse = "small-remnants",
                resistances = { { type = "fire", percent = 80 } },
                collision_box = { { -0.35, -0.35 }, { 0.35, 0.35 } },
                selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
                fast_replaceable_group = "container",
                inventory_size = 1,
                picture =
                {
                    filename = "__prospect__/graphics/icons/"..resource .."-map.png",
                    priority = "extra-high",
                    width = 32,
                    height = 32,
                    shift = { 0.0, 0.0 }
                }
            },
        })
    end
end
