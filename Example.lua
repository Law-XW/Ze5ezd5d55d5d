local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Law-XW/Ze5ezd5d55d5d/refs/heads/main/Source.lua"))()

local Window = Library:Window({
	Title = "Example Hub",
	Footer = "example.lua",
	Anonymous = false,
	ConfigFolder = "ExampleHub",
})

local function Say(Text)
	Library:Notify(Text, 2)
end

local Home = Window:Tab("Home", "home")
Home:HomeManager()

local Elements = Window:Tab("Elements", "wrench")
local Controls = Elements:Subtab("Controls")
local Display = Elements:Subtab("Display")

local Inputs = Controls:Section("Example Inputs", "Left")
Inputs:Toggle("Example Toggle", {
	Flag = "example_toggle",
	Callback = function(Value)
		Say("Toggle is " .. (Value and "on" or "off"))
	end,
})
Inputs:Toggle("Example Toggle With Color", { Default = true, Flag = "example_toggle_color" }):Colorpicker(Color3.fromRGB(96, 112, 190), { Flag = "example_toggle_picker" })
Inputs:Slider("Example Slider", {
	Min = 0,
	Max = 100,
	Default = 50,
	Suffix = "%",
	Flag = "example_slider",
	Callback = function(Value)
		Say("Slider set to " .. Value)
	end,
})
Inputs:Slider("Example Decimal Slider", { Min = 0, Max = 1, Default = 0.5, Increment = 0.05, Flag = "example_decimal" })
Inputs:Dropdown("Example Dropdown", {
	Options = { "First", "Second", "Third" },
	Default = "First",
	Flag = "example_dropdown",
	Callback = function(Value)
		Say("Picked " .. tostring(Value))
	end,
})
Inputs:Dropdown("Example Multi Dropdown", {
	Options = { "Head", "Torso", "Arms", "Legs" },
	Default = { "Head" },
	Multi = true,
	Flag = "example_multi",
})
Inputs:SearchDropdown("Example Search Dropdown", {
	Options = { "Apple", "Banana", "Cherry", "Grape", "Lemon", "Mango", "Orange", "Peach" },
	Default = "Apple",
	Flag = "example_search",
})
Inputs:Textbox("Example Textbox", {
	Flag = "example_textbox",
	Callback = function(Text)
		Say("Typed " .. Text)
	end,
})
Inputs:Colorpicker("Example Colorpicker", Color3.fromRGB(255, 120, 80), { Flag = "example_color" })

local Actions = Controls:Section("Example Actions", "Right")
local Status = Actions:Label("Example Label")
Actions:Button("Example Button", function()
	Status:Set("Button pressed at " .. os.date("%H:%M:%S"))
end)
Actions:ButtonRow({
	{ "Example Left", function() Say("Left pressed") end },
	{ "Example Right", function() Say("Right pressed") end },
})
Actions:Divider()
Actions:Listbox({
	Height = 90,
	Items = { "Example One", "Example Two", "Example Three", "Example Four", "Example Five" },
	Callback = function(Value)
		Status:Set("Selected " .. tostring(Value))
	end,
})

local Grouped = Controls:Section("Example Subsections", "Right")
local PageOne = Grouped:SubSection("One")
PageOne:Toggle("Example Page One Toggle", { Flag = "example_page_one" })
PageOne:Slider("Example Page One Slider", { Min = 0, Max = 10, Default = 5, Flag = "example_page_one_slider" })
local PageTwo = Grouped:SubSection("Two")
PageTwo:Toggle("Example Page Two Toggle", { Flag = "example_page_two" })
PageTwo:Button("Example Page Two Button", function()
	Say("Second page button")
end)

local Text = Display:Section("Example Text", "Left")
Text:Label("Example plain label that wraps onto a second line when the text is long enough")
Text:Label("Example colored label", { Color = Color3.fromRGB(255, 120, 80) })
Text:Divider()
Text:Stat("Example Stat", "Static value")
Text:Stat("Example Live Stat", function()
	return os.date("%H:%M:%S")
end)

local Shown = Display:Section("Example Preview", "Right")
Shown:Preview(180)

local Visuals = Window:Tab("Visuals", "eye")
Visuals:EspManager()

local Settings = Window:Tab("Settings", "settings")
local Menu = Settings:Section("Menu", "Left")
Menu:Dropdown("Notification position", {
	Options = Library.NotifyPositions,
	Default = "Top Left",
	Flag = "notify_position",
	Callback = function(Value)
		Library:SetNotifyPosition(Value)
	end,
})
Menu:Button("Test notification", function()
	Say("Notification test")
end)
Menu:Button("Unload menu", function()
	Library:Unload()
end)
Settings:ConfigManager("Right")

Library:Watermark("example hub")
Library:Autoload()
