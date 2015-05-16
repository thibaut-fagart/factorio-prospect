data:extend({
    {
        type = "recipe",
        name = "geology-lab",
        category = "geology",
        enabled = "false",
        ingredients =
        {
            { "copper-ore", 1 },
        },
        result = "geology-lab",
    },})
for _, resource in ipairs(glob.oretypes) do
    if data.raw.resource[resource] then
        data:extend({
            {
                type = "recipe",
                name = ""..resource .. "-map",
                category = "geology",
                --        subgroup = "geology",
                enabled = "false",
                ingredients =
                {
                    { "copper-ore", 10 },
                },
                result = ""..resource .. "-map",
            },
        })
    end
end
