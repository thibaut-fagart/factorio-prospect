data:extend({
    {
        type = "recipe-category",
        name = "geology"
    },

    {
        type = "item-group",
        name = "geology",
        order = "g[geology]-a",
        inventory_order = "g[geology]-a",
        icon = "__prospect__/graphics/technology/geology.png",
    },
    {
      type = "item-subgroup",
      name = "prospection-maps",
      group = "geology",
      order = "m",
    },
    {
      type = "item-subgroup",
      name = "geology-labs",
      group = "geology",
      order = "a",
    },
})