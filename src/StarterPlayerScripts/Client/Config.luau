--== Multi-Tower Kit Client Config ==--

return {
	-- What does the win announcement look like?
	WinMessage = "{PlayerName} has beaten {EndingName} in {Time}",

	-- How will it display what boosts the player used?
	-- Setting this to an empty string effectively disables showing boosts used
	WinMessageBoostsUsed = "\nUsed: {BoostList}",

	--== MODERN CHAT SYSTEM CONFIG==--

	-- The XML tag to wrap the win message in for the modern chat system
	ChatFont = "<font color='{FontColor}' size='{FontSize}' face='{FontFace}'>{Message}</font>",

	-- The chat channel to use for system messages
	ChatChannel = "RBXSystem",

	-- The font to use for normal system messages
	ChatFontFace = "GothamBold",
	ChatFontSize = 14,

	-- The font to use for fancy system messages
	ChatFancyFontFace = "Bodoni",
	ChatFancyFontSize = 22,
}
