return {
	Name = "finale",
	Aliases = { "fin" },
	Description = "Skips straight to the finale",
	Group = "Admin",
	Args = {
		{
			Type = "number",
			Name = "matches",
			Description = "Matches left, 0 for sacrifice",
			Optional = true,
		},
	},
}
