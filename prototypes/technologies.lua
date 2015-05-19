local unlockedrecipes = {
    {
        type = "unlock-recipe",
        recipe = "geology-lab"
    }
}
for _, resource in ipairs(glob.oretypes) do
    if data.raw.resource[resource] then
        table.insert(unlockedrecipes,
            {
                type = "unlock-recipe",
                recipe = ""..resource .. "-map"
            }
        )
    end
end
data:extend({
    {
        type = "technology",
        name = "geology",
        icon = "__base__/graphics/icons/assembling-machine-1.png",
        prerequisites =
        {},
        effects = unlockedrecipes
,
        unit =
            {
              count = 100,
              ingredients =
              {
                {"science-pack-1", 1},
                {"science-pack-2", 1},
              },
              time = 30
            },
    },
})