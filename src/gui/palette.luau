--!strict

export type PaletteFlavor = "latte" | "macchiato" | "frappe" | "mocha"

export type PaletteColor =
	"flamingo"
	| "sapphire"
	| "mauve"
	| "crust"
	| "mantle"
	| "base"
	| "lavender"
	| "surface1"
	| "maroon"
	| "red"
	| "surface2"
	| "overlay1"
	| "blue"
	| "overlay0"
	| "text"
	| "teal"
	| "subtext0"
	| "pink"
	| "subtext1"
	| "overlay2"
	| "sky"
	| "green"
	| "surface0"
	| "yellow"
	| "peach"
	| "rosewater"

export type PaletteTheme = {
	flamingo: Color3,
	sapphire: Color3,
	mauve: Color3,
	crust: Color3,
	mantle: Color3,
	base: Color3,
	lavender: Color3,
	surface1: Color3,
	maroon: Color3,
	red: Color3,
	surface2: Color3,
	overlay1: Color3,
	blue: Color3,
	overlay0: Color3,
	text: Color3,
	teal: Color3,
	subtext0: Color3,
	pink: Color3,
	subtext1: Color3,
	overlay2: Color3,
	sky: Color3,
	green: Color3,
	surface0: Color3,
	yellow: Color3,
	peach: Color3,
	rosewater: Color3,
}

export type Palette = { latte: PaletteTheme, macchiato: PaletteTheme, frappe: PaletteTheme, mocha: PaletteTheme }

local palette: Palette = {
	latte = {
		flamingo = Color3.fromHex("#dd7878"),
		sapphire = Color3.fromHex("#209fb5"),
		mauve = Color3.fromHex("#8839ef"),
		crust = Color3.fromHex("#dce0e8"),
		mantle = Color3.fromHex("#e6e9ef"),
		base = Color3.fromHex("#eff1f5"),
		lavender = Color3.fromHex("#7287fd"),
		surface1 = Color3.fromHex("#bcc0cc"),
		maroon = Color3.fromHex("#e64553"),
		red = Color3.fromHex("#d20f39"),
		surface2 = Color3.fromHex("#acb0be"),
		overlay1 = Color3.fromHex("#8c8fa1"),
		blue = Color3.fromHex("#1e66f5"),
		overlay0 = Color3.fromHex("#9ca0b0"),
		text = Color3.fromHex("#4c4f69"),
		teal = Color3.fromHex("#179299"),
		subtext0 = Color3.fromHex("#6c6f85"),
		pink = Color3.fromHex("#ea76cb"),
		subtext1 = Color3.fromHex("#5c5f77"),
		overlay2 = Color3.fromHex("#7c7f93"),
		sky = Color3.fromHex("#04a5e5"),
		green = Color3.fromHex("#40a02b"),
		surface0 = Color3.fromHex("#ccd0da"),
		yellow = Color3.fromHex("#df8e1d"),
		peach = Color3.fromHex("#fe640b"),
		rosewater = Color3.fromHex("#dc8a78"),
	},
	macchiato = {
		flamingo = Color3.fromHex("#f0c6c6"),
		sapphire = Color3.fromHex("#7dc4e4"),
		mauve = Color3.fromHex("#c6a0f6"),
		crust = Color3.fromHex("#181926"),
		mantle = Color3.fromHex("#1e2030"),
		base = Color3.fromHex("#24273a"),
		lavender = Color3.fromHex("#b7bdf8"),
		surface1 = Color3.fromHex("#494d64"),
		maroon = Color3.fromHex("#ee99a0"),
		red = Color3.fromHex("#ed8796"),
		surface2 = Color3.fromHex("#5b6078"),
		overlay1 = Color3.fromHex("#8087a2"),
		blue = Color3.fromHex("#8aadf4"),
		overlay0 = Color3.fromHex("#6e738d"),
		text = Color3.fromHex("#cad3f5"),
		teal = Color3.fromHex("#8bd5ca"),
		subtext0 = Color3.fromHex("#a5adcb"),
		pink = Color3.fromHex("#f5bde6"),
		subtext1 = Color3.fromHex("#b8c0e0"),
		overlay2 = Color3.fromHex("#939ab7"),
		sky = Color3.fromHex("#91d7e3"),
		green = Color3.fromHex("#a6da95"),
		surface0 = Color3.fromHex("#363a4f"),
		yellow = Color3.fromHex("#eed49f"),
		peach = Color3.fromHex("#f5a97f"),
		rosewater = Color3.fromHex("#f4dbd6"),
	},
	frappe = {
		flamingo = Color3.fromHex("#eebebe"),
		sapphire = Color3.fromHex("#85c1dc"),
		mauve = Color3.fromHex("#ca9ee6"),
		crust = Color3.fromHex("#232634"),
		mantle = Color3.fromHex("#292c3c"),
		base = Color3.fromHex("#303446"),
		lavender = Color3.fromHex("#babbf1"),
		surface1 = Color3.fromHex("#51576d"),
		maroon = Color3.fromHex("#ea999c"),
		red = Color3.fromHex("#e78284"),
		surface2 = Color3.fromHex("#626880"),
		overlay1 = Color3.fromHex("#838ba7"),
		blue = Color3.fromHex("#8caaee"),
		overlay0 = Color3.fromHex("#737994"),
		text = Color3.fromHex("#c6d0f5"),
		teal = Color3.fromHex("#81c8be"),
		subtext0 = Color3.fromHex("#a5adce"),
		pink = Color3.fromHex("#f4b8e4"),
		subtext1 = Color3.fromHex("#b5bfe2"),
		overlay2 = Color3.fromHex("#949cbb"),
		sky = Color3.fromHex("#99d1db"),
		green = Color3.fromHex("#a6d189"),
		surface0 = Color3.fromHex("#414559"),
		yellow = Color3.fromHex("#e5c890"),
		peach = Color3.fromHex("#ef9f76"),
		rosewater = Color3.fromHex("#f2d5cf"),
	},
	mocha = {
		flamingo = Color3.fromHex("#f2cdcd"),
		sapphire = Color3.fromHex("#74c7ec"),
		mauve = Color3.fromHex("#cba6f7"),
		crust = Color3.fromHex("#11111b"),
		mantle = Color3.fromHex("#181825"),
		base = Color3.fromHex("#1e1e2e"),
		lavender = Color3.fromHex("#b4befe"),
		surface1 = Color3.fromHex("#45475a"),
		maroon = Color3.fromHex("#eba0ac"),
		red = Color3.fromHex("#f38ba8"),
		surface2 = Color3.fromHex("#585b70"),
		overlay1 = Color3.fromHex("#7f849c"),
		blue = Color3.fromHex("#89b4fa"),
		overlay0 = Color3.fromHex("#6c7086"),
		text = Color3.fromHex("#cdd6f4"),
		teal = Color3.fromHex("#94e2d5"),
		subtext0 = Color3.fromHex("#a6adc8"),
		pink = Color3.fromHex("#f5c2e7"),
		subtext1 = Color3.fromHex("#bac2de"),
		overlay2 = Color3.fromHex("#9399b2"),
		sky = Color3.fromHex("#89dceb"),
		green = Color3.fromHex("#a6e3a1"),
		surface0 = Color3.fromHex("#313244"),
		yellow = Color3.fromHex("#f9e2af"),
		peach = Color3.fromHex("#fab387"),
		rosewater = Color3.fromHex("#f5e0dc"),
	},
}

return palette
