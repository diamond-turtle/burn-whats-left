return {
	Name = "settime",
	Aliases = { "st" },
	Description = "Sets the time of day in hours",
	Group = "Admin",
	Args = {
		{
			Type = "number",
			Name = "hours",
			Description = "Hours like 18.5",
		},
	},
}
