local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local PixelFont = true
local TextSize = PixelFont and 13 or 12

local Lucide
pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local function LoadFont()
	local Fallback = Font.fromEnum(Enum.Font.Code)
	if not PixelFont then
		return Font.fromEnum(Enum.Font.RobotoMono)
	end
	if typeof(writefile) ~= "function" or typeof(getcustomasset) ~= "function" or typeof(isfile) ~= "function" or typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then
		return Fallback
	end
	local Ok, Result = pcall(function()
		if not isfolder("Zero") then
			makefolder("Zero")
		end
		if not isfile("Zero/ProggyClean.ttf") then
			local Data
			for _, Url in {
				"https://raw.githubusercontent.com/ocornut/imgui/cc4b1f9e47c830103b94ec6e1596be31cf14fd44/misc/fonts/ProggyClean.ttf",
				"https://raw.githubusercontent.com/ocornut/imgui/master/misc/fonts/ProggyClean.ttf",
			} do
				local Got, Body = pcall(game.HttpGet, game, Url)
				if Got and type(Body) == "string" and #Body > 10000 and Body:sub(1, 4) == "\0\1\0\0" then
					Data = Body
					break
				end
			end
			if not Data then
				error("font download failed")
			end
			writefile("Zero/ProggyClean.ttf", Data)
		end
		writefile("Zero/ProggyClean.json", HttpService:JSONEncode({
			name = "ProggyClean",
			faces = { { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset("Zero/ProggyClean.ttf") } },
		}))
		return Font.new(getcustomasset("Zero/ProggyClean.json"))
	end)
	if Ok and Result then
		return Result
	end
	return Fallback
end

local Zero = {
	Font = LoadFont(),
	Flags = {},
	Options = {},
	Themed = {},
	Refreshers = {},
	Connections = {},
	Ticks = {},
	UnloadHooks = {},
	Windows = {},
	Scale = 1,
	Z = 2,
	Folder = "Zero",
	Popup = nil,
	Visible = true,
	Mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	Theme = {
		Accent = Color3.fromRGB(96, 112, 190),
		Background = Color3.fromRGB(8, 9, 14),
		Panel = Color3.fromRGB(12, 13, 20),
		Field = Color3.fromRGB(17, 18, 27),
		Inline = Color3.fromRGB(36, 39, 56),
		Glow = Color3.fromRGB(60, 65, 92),
		Outline = Color3.fromRGB(2, 2, 4),
		Text = Color3.fromRGB(212, 216, 230),
		DimText = Color3.fromRGB(122, 128, 152),
	},
}

Zero.PlaceName = game.Name
task.spawn(function()
	local Ok, Info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if Ok and type(Info) == "table" and Info.Name then
		Zero.PlaceName = Info.Name
	end
end)

local Elements = {}
Elements.__index = Elements

local function Connect(Signal, Callback)
	local Connection = Signal:Connect(Callback)
	table.insert(Zero.Connections, Connection)
	return Connection
end

local function Tween(Obj, Props, Time, Style, Direction, Delay)
	local Info = TweenInfo.new(Time or 0.2, Style or Enum.EasingStyle.Quint, Direction or Enum.EasingDirection.Out, 0, false, Delay or 0)
	local Tw = TweenService:Create(Obj, Info, Props)
	Tw:Play()
	return Tw
end

local function Morph(Obj, Props, Time)
	if Time and Time > 0 then
		return Tween(Obj, Props, Time)
	end
	for Key, Value in Props do
		Obj[Key] = Value
	end
end

local function Theme(Obj, Prop, Key)
	Obj[Prop] = Zero.Theme[Key]
	table.insert(Zero.Themed, { Obj, Prop, Key })
end

function Zero:SetTheme(Key, Color)
	self.Theme[Key] = Color
	for Index = #self.Themed, 1, -1 do
		local Entry = self.Themed[Index]
		if not Entry[1].Parent then
			table.remove(self.Themed, Index)
		elseif Entry[3] == Key then
			Entry[1][Entry[2]] = Color
		end
	end
	for _, Refresh in self.Refreshers do
		pcall(Refresh)
	end
end

local function New(Class, Props, Themes)
	local Obj = Instance.new(Class)
	local IsText = Class == "TextLabel" or Class == "TextButton" or Class == "TextBox"
	if Obj:IsA("GuiObject") then
		Obj.BorderSizePixel = 0
		if Class == "TextLabel" or Class == "ImageLabel" then
			Obj.BackgroundTransparency = 1
		end
	end
	if Obj:IsA("GuiButton") then
		Obj.AutoButtonColor = false
	end
	if IsText then
		Obj.FontFace = Zero.Font
		Obj.TextSize = TextSize
		if Class ~= "TextBox" then
			Obj.Text = ""
		end
		if not (Props and Props.TextColor3) and not (Themes and Themes.TextColor3) then
			Themes = Themes or {}
			Themes.TextColor3 = "Text"
		end
	end
	local Parent
	for Key, Value in Props or {} do
		if Key == "Parent" then
			Parent = Value
		else
			Obj[Key] = Value
		end
	end
	for Key, Value in Themes or {} do
		Theme(Obj, Key, Value)
	end
	Obj.Parent = Parent
	return Obj
end

local function Stroke(Parent, Key, Thickness)
	return New("UIStroke", {
		Thickness = Thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = Parent,
	}, { Color = Key })
end

local function Glow(Parent, Top, Bottom, Rotation)
	local Overlay = New("Frame", { Size = UDim2.fromScale(1, 1) }, { BackgroundColor3 = "Glow" })
	New("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0)),
		Transparency = NumberSequence.new(Top or 0.45, Bottom or 0.3),
		Rotation = Rotation or 90,
		Parent = Overlay,
	})
	Overlay.Parent = Parent
	return Overlay
end

local function Fade(Frame)
	New("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.18, 0.18, 0.18)), Parent = Frame })
	return Frame
end

local function Halo(Parent, Size, Transparency)
	local Container = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Parent })
	local Reach = math.min(Size, 4)
	for Index = 1, 4 do
		local Grow = math.ceil(Reach * Index / 4)
		local Layer = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, Grow * 2, 1, Grow * 2),
			BackgroundTransparency = 1,
			Parent = Container,
		}, { BackgroundColor3 = "Accent" })
		New("UICorner", { CornerRadius = UDim.new(0, Grow), Parent = Layer })
	end
	for _, Layer in Container:GetChildren() do
		Layer.BackgroundTransparency = 1 - (1 - (Transparency or 0.5)) * 0.25
	end
	return Container
end

local function HaloSet(Container, Transparency, Time)
	local Value = 1 - (1 - Transparency) * 0.25
	for _, Layer in Container:GetChildren() do
		Morph(Layer, { BackgroundTransparency = Value }, Time)
	end
end

local function TextWidth(Text)
	local Ok, Bounds = pcall(function()
		local Params = Instance.new("GetTextBoundsParams")
		Params.Text = Text
		Params.Font = Zero.Font
		Params.Size = TextSize
		Params.Width = 1000
		return TextService:GetTextBoundsAsync(Params)
	end)
	if Ok and Bounds then
		return Bounds.X
	end
	return #Text * 7
end

local function Pad(Parent, L, T, R, B)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, L),
		PaddingTop = UDim.new(0, T or L),
		PaddingRight = UDim.new(0, R or L),
		PaddingBottom = UDim.new(0, B or T or L),
		Parent = Parent,
	})
end

local function List(Parent, Padding, Horizontal)
	return New("UIListLayout", {
		Padding = UDim.new(0, Padding or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Parent = Parent,
	})
end

local function Bordered(Parent, Props, Key, Class)
	Props.Parent = Parent
	local Outer = New(Class or "Frame", Props, { BackgroundColor3 = "Outline" })
	Pad(Outer, 1)
	local Mid = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = Outer }, { BackgroundColor3 = "Inline" })
	Pad(Mid, 1)
	local Inner = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = Mid }, { BackgroundColor3 = Key })
	Glow(Inner, 0.35, 0.55)
	return Outer, Inner
end

local function Scroller(Props, Themes)
	Props.CanvasSize = UDim2.new()
	Props.AutomaticCanvasSize = Enum.AutomaticSize.X
	Props.ScrollingDirection = Enum.ScrollingDirection.X
	Props.ScrollBarThickness = 0
	Props.ElasticBehavior = Enum.ElasticBehavior.Never
	Props.VerticalScrollBarInclusion = Enum.ScrollBarInclusion.Never
	Props.HorizontalScrollBarInclusion = Enum.ScrollBarInclusion.Never
	return New("ScrollingFrame", Props, Themes)
end

local function Floor(Button, Width)
	New("UISizeConstraint", { MinSize = Vector2.new(Width, 0), Parent = Button })
end

local function Reveal(Holder, Button)
	local Factor = Holder.AbsoluteSize.Y / math.max(Holder.Size.Y.Offset, 1)
	if Factor <= 0 then
		return
	end
	local Slack = (Holder.AbsoluteCanvasSize.X - Holder.AbsoluteSize.X) / Factor
	if Slack <= 0 then
		return
	end
	local Start = (Button.AbsolutePosition.X - Holder.AbsolutePosition.X) / Factor + Holder.CanvasPosition.X
	local Middle = (Holder.AbsoluteSize.X - Button.AbsoluteSize.X) / 2 / Factor
	Tween(Holder, { CanvasPosition = Vector2.new(math.clamp(Start - Middle, 0, Slack), 0) }, 0.25)
end

local function Commit(Opt, Value, Silent)
	if Opt.Flag then
		Zero.Flags[Opt.Flag] = Value
	end
	if not Silent and Opt.Callback then
		task.spawn(Opt.Callback, Value)
	end
end

local function Track(Handle, OnStart, OnMove, OnEnd)
	Handle.InputBegan:Connect(function(Input)
		local Type = Input.UserInputType
		if Type ~= Enum.UserInputType.MouseButton1 and Type ~= Enum.UserInputType.Touch then
			return
		end
		local Origin = Vector2.new(Input.Position.X, Input.Position.Y)
		local Active = true
		if OnStart then
			OnStart(Input)
		end
		local Move, Ended
		Move = UserInputService.InputChanged:Connect(function(Changed)
			if not Active then
				return
			end
			if Changed == Input or Changed.UserInputType == Enum.UserInputType.MouseMovement then
				local Delta = (Vector2.new(Changed.Position.X, Changed.Position.Y) - Origin) / Zero.Scale
				if OnMove then
					OnMove(Delta, Changed)
				end
			end
		end)
		Ended = Input.Changed:Connect(function()
			if Input.UserInputState == Enum.UserInputState.End then
				Active = false
				Move:Disconnect()
				Ended:Disconnect()
				if OnEnd then
					OnEnd()
				end
			end
		end)
	end)
end

local Gui = Instance.new("ScreenGui")
Gui.Name = HttpService:GenerateGUID(false)
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = false
Gui.DisplayOrder = 999
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if typeof(syn) == "table" and syn.protect_gui then
	pcall(syn.protect_gui, Gui)
end

local function Mount()
	if typeof(gethui) == "function" then
		local Ok, Hui = pcall(gethui)
		if Ok and Hui then
			Gui.Parent = Hui
			return
		end
	end
	if not pcall(function() Gui.Parent = CoreGui end) or not Gui.Parent then
		Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end
Mount()

local UIScale = Instance.new("UIScale")
UIScale.Parent = Gui
Zero.Gui = Gui

function Zero:Viewport()
	local Size = Gui.AbsoluteSize
	if Size.X < 1 or Size.Y < 1 then
		Size = Camera.ViewportSize
	end
	return Size / self.Scale
end

function Zero:Clamp(Entry, Center)
	local Frame = Entry.Frame
	local View = self:Viewport()
	local W = math.floor(math.min(Frame:GetAttribute("W"), View.X - 8))
	local H = math.floor(math.min(Frame:GetAttribute("H"), View.Y - 8))
	Frame.Size = UDim2.fromOffset(W, H)
	local X, Y
	if Center and not Entry.Moved then
		X, Y = math.floor((View.X - W) / 2), math.floor((View.Y - H) / 2)
	else
		X = math.floor(math.clamp(Frame.Position.X.Offset, 4, math.max(4, View.X - W - 4)))
		Y = math.floor(math.clamp(Frame.Position.Y.Offset, 4, math.max(4, View.Y - H - 4)))
	end
	if Entry.Animating then
		Entry.Base = UDim2.fromOffset(X, Y)
	else
		Frame.Position = UDim2.fromOffset(X, Y)
	end
end

local function Rescale()
	local Size = Gui.AbsoluteSize
	if Size.X < 1 or Size.Y < 1 then
		Size = Camera.ViewportSize
	end
	local Value = 1
	if not Zero.Mobile then
		Value = math.max(1, math.floor(math.min(Size.X / 1400, Size.Y / 900)))
	end
	UIScale.Scale = Value
	Zero.Scale = Value
	for _, Entry in Zero.Windows do
		Zero:Clamp(Entry, Entry.Center)
	end
end

Connect(Gui:GetPropertyChangedSignal("AbsoluteSize"), Rescale)
Connect(Camera:GetPropertyChangedSignal("ViewportSize"), Rescale)
Rescale()
task.defer(Rescale)

Zero.Popups = New("Frame", { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, ZIndex = 100, Parent = Gui })

function Zero:Raise(Frame)
	self.Z = math.min(self.Z + 1, 90)
	Frame.ZIndex = self.Z
end

function Zero:ClosePopup()
	local Popup = self.Popup
	if not Popup then
		return
	end
	self.Popup = nil
	for _, Connection in Popup.Cleanup do
		Connection:Disconnect()
	end
	local Frame = Popup.Frame
	local Closing = Tween(Frame, { Size = UDim2.fromOffset(Popup.Width, 0) }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	Closing.Completed:Connect(function()
		Frame:Destroy()
	end)
	if Popup.OnClose then
		Popup.OnClose()
	end
end

function Zero:OpenPopup(Owner, Width, Height)
	self:ClosePopup()
	local Abs = Owner.AbsolutePosition
	local View = self:Viewport()
	local X = Abs.X / self.Scale
	local Y = (Abs.Y + Owner.AbsoluteSize.Y) / self.Scale + 2
	local Up = false
	if Y + Height > View.Y then
		Up = true
		Y = Abs.Y / self.Scale - 2
	end
	X = math.clamp(X, 2, math.max(2, View.X - Width - 2))
	local Frame = New("Frame", {
		AnchorPoint = Vector2.new(0, Up and 1 or 0),
		Position = UDim2.fromOffset(X, Y),
		Size = UDim2.fromOffset(Width, 0),
		ClipsDescendants = true,
		Parent = self.Popups,
	}, { BackgroundColor3 = "Field" })
	Stroke(Frame, "Accent")
	local Body = New("Frame", {
		AnchorPoint = Vector2.new(0, Up and 1 or 0),
		Position = UDim2.fromScale(0, Up and 1 or 0),
		Size = UDim2.fromOffset(Width, Height),
		BackgroundTransparency = 1,
		Parent = Frame,
	})
	Tween(Frame, { Size = UDim2.fromOffset(Width, Height) }, 0.24, Enum.EasingStyle.Quint)
	self.Popup = { Frame = Frame, Body = Body, Owner = Owner, Width = Width, Cleanup = {} }
	return self.Popup
end

Connect(UserInputService.InputBegan, function(Input)
	local Type = Input.UserInputType
	if Type ~= Enum.UserInputType.MouseButton1 and Type ~= Enum.UserInputType.Touch then
		return
	end
	local Popup = Zero.Popup
	if not Popup then
		return
	end
	local Pos = Input.Position
	local function Inside(Object)
		local A, S = Object.AbsolutePosition, Object.AbsoluteSize
		return Pos.X >= A.X and Pos.X <= A.X + S.X and Pos.Y >= A.Y and Pos.Y <= A.Y + S.Y
	end
	if not Inside(Popup.Frame) and not Inside(Popup.Owner) then
		Zero:ClosePopup()
	end
end)

function Zero:Present(Entry, State, Delay)
	Entry.Token = (Entry.Token or 0) + 1
	local Token = Entry.Token
	local Frame = Entry.Frame
	if Entry.Drive then
		Entry.Drive:Cancel()
		Entry.Drive = nil
	end
	local function Render(Alpha)
		Entry.Alpha = Alpha
		local Scale = 0.95 + 0.05 * Alpha
		local W, H = Frame.Size.X.Offset, Frame.Size.Y.Offset
		if Frame:IsA("CanvasGroup") then
			Frame.GroupTransparency = 1 - Alpha
		end
		Entry.Scale.Scale = Scale
		Frame.Position = UDim2.fromOffset(
			Entry.Base.X.Offset + (1 - Scale) * W / 2,
			Entry.Base.Y.Offset + (1 - Scale) * H / 2 + (1 - Alpha) * 10
		)
	end
	local function Start()
		if Token ~= Entry.Token then
			return
		end
		if not Entry.Animating then
			Entry.Base = Frame.Position
			Entry.Animating = true
		end
		local From = Entry.Alpha or (State and 0 or 1)
		local To = State and 1 or 0
		Render(From)
		if State then
			Frame.Visible = true
		end
		local Value = Instance.new("NumberValue")
		Value.Value = From
		local Changed = Value.Changed:Connect(Render)
		local Info = TweenInfo.new(
			State and 0.38 or 0.2,
			State and Enum.EasingStyle.Quint or Enum.EasingStyle.Quad,
			State and Enum.EasingDirection.Out or Enum.EasingDirection.In
		)
		local Tw = TweenService:Create(Value, Info, { Value = To })
		Entry.Drive = Tw
		Tw.Completed:Connect(function(Status)
			Changed:Disconnect()
			Value:Destroy()
			if Token ~= Entry.Token or Status ~= Enum.PlaybackState.Completed then
				return
			end
			Entry.Drive = nil
			Entry.Animating = false
			Entry.Scale.Scale = 1
			if Frame:IsA("CanvasGroup") then
				Frame.GroupTransparency = 0
			end
			Frame.Position = Entry.Base
			if not State then
				Frame.Visible = false
			end
		end)
		Tw:Play()
	end
	if Delay and Delay > 0 then
		task.delay(Delay, Start)
	else
		Start()
	end
end

function Zero:SetVisible(State)
	self.Visible = State
	self:ClosePopup()
	for Index, Entry in self.Windows do
		self:Present(Entry, State, (Index - 1) * 0.05)
	end
end

function Zero:Dragify(Handle, Entry)
	local Origin
	Track(Handle, function()
		Zero:ClosePopup()
		Zero:Raise(Entry.Frame)
		Origin = Entry.Frame.Position
		Entry.Moved = true
	end, function(Delta)
		Entry.Frame.Position = UDim2.fromOffset(math.floor(Origin.X.Offset + Delta.X), math.floor(Origin.Y.Offset + Delta.Y))
	end, function()
		Zero:Clamp(Entry)
	end)
end

function Zero:Resizer(Parent, Entry, MinX, MinY)
	local Handle = New("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = Parent,
	})
	New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 1, 0.5, 1), Size = UDim2.fromOffset(10, 1), Rotation = -45, Parent = Handle }, { BackgroundColor3 = "DimText" })
	New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 4, 0.5, 4), Size = UDim2.fromOffset(5, 1), Rotation = -45, Parent = Handle }, { BackgroundColor3 = "DimText" })
	local W0, H0
	Track(Handle, function()
		Zero:ClosePopup()
		W0, H0 = Entry.Frame:GetAttribute("W"), Entry.Frame:GetAttribute("H")
	end, function(Delta)
		local View = Zero:Viewport()
		local Pos = Entry.Frame.Position
		local W = math.floor(math.clamp(W0 + Delta.X, MinX, math.max(MinX, View.X - Pos.X.Offset - 4)))
		local H = math.floor(math.clamp(H0 + Delta.Y, MinY, math.max(MinY, View.Y - Pos.Y.Offset - 4)))
		Entry.Frame:SetAttribute("W", W)
		Entry.Frame:SetAttribute("H", H)
		Entry.Frame.Size = UDim2.fromOffset(W, H)
	end)
end

local function Swatch(Parent, Position, Default, Opt)
	Opt = Opt or {}
	local H, S, V = Default:ToHSV()
	local Button = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = Position,
		Size = UDim2.fromOffset(20, 10),
		BackgroundColor3 = Default,
		Parent = Parent,
	})
	local SwatchStroke = Stroke(Button, "Outline")
	Button.MouseEnter:Connect(function()
		Tween(SwatchStroke, { Color = Zero.Theme.Text }, 0.15)
	end)
	Button.MouseLeave:Connect(function()
		Tween(SwatchStroke, { Color = Zero.Theme.Outline }, 0.2)
	end)
	local Object = {}
	local Sync
	local function Apply(Silent)
		local Color = Color3.fromHSV(H, S, V)
		Button.BackgroundColor3 = Color
		if Sync then
			Sync()
		end
		Commit(Opt, Color, Silent)
	end
	function Object:Get()
		return Color3.fromHSV(H, S, V)
	end
	function Object:Set(Color, Silent)
		H, S, V = Color:ToHSV()
		Apply(Silent)
	end
	if Opt.Flag then
		Zero.Options[Opt.Flag] = Object
	end
	Commit(Opt, Default, true)
	Button.Activated:Connect(function()
		if Zero.Popup and Zero.Popup.Owner == Button then
			Zero:ClosePopup()
			return
		end
		local Popup = Zero:OpenPopup(Button, 172, 146)
		local Frame = Popup.Body
		local SV = New("TextButton", { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(130, 110), Parent = Frame })
		local White = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = SV })
		New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = White })
		local Black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = SV })
		New("UIGradient", { Transparency = NumberSequence.new(1, 0), Rotation = 90, Parent = Black })
		local SVCursor = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = SV })
		Stroke(SVCursor, "Outline")
		local HueBar = New("TextButton", { Position = UDim2.fromOffset(142, 6), Size = UDim2.fromOffset(14, 110), BackgroundColor3 = Color3.new(1, 1, 1), Parent = Frame })
		New("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
			Parent = HueBar,
		})
		local HueCursor = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = HueBar })
		Stroke(HueCursor, "Outline")
		local Hex = New("TextBox", { Position = UDim2.fromOffset(6, 122), Size = UDim2.fromOffset(160, 18), ClearTextOnFocus = false, Parent = Frame }, { BackgroundColor3 = "Background" })
		Stroke(Hex, "Inline")
		Sync = function()
			SV.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
			SVCursor.Position = UDim2.fromScale(S, 1 - V)
			HueCursor.Position = UDim2.fromScale(0, H)
			Hex.Text = "#" .. Color3.fromHSV(H, S, V):ToHex()
		end
		Sync()
		Popup.OnClose = function()
			Sync = nil
		end
		local function SetSV(Pos)
			S = math.clamp((Pos.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X, 0, 1)
			V = 1 - math.clamp((Pos.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y, 0, 1)
			Apply()
		end
		local function SetHue(Pos)
			H = math.clamp((Pos.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
			Apply()
		end
		Track(SV, function(Input) SetSV(Input.Position) end, function(_, Changed) SetSV(Changed.Position) end)
		Track(HueBar, function(Input) SetHue(Input.Position) end, function(_, Changed) SetHue(Changed.Position) end)
		Hex.FocusLost:Connect(function()
			local Ok, Color = pcall(Color3.fromHex, Hex.Text)
			if Ok and Color then
				Object:Set(Color)
			else
				Sync()
			end
		end)
	end)
	return Object, Button
end

local KeyShort = {
	LeftControl = "LCtrl", RightControl = "RCtrl", LeftShift = "LShift", RightShift = "RShift",
	LeftAlt = "LAlt", RightAlt = "RAlt", Return = "Enter", Backspace = "Bksp", CapsLock = "Caps",
	Delete = "Del", Insert = "Ins", PageUp = "PgUp", PageDown = "PgDn", Escape = "Esc",
	MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3",
	One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6", Seven = "7", Eight = "8", Nine = "9", Zero = "0",
}

local BindModes = { "Toggle", "Hold", "Always" }

local function LookupKey(Name)
	if type(Name) ~= "string" then
		return nil
	end
	local Ok, Item = pcall(function()
		return Enum.KeyCode[Name]
	end)
	if Ok and Item and Item ~= Enum.KeyCode.Unknown then
		return Item
	end
	Ok, Item = pcall(function()
		return Enum.UserInputType[Name]
	end)
	if Ok and Item and Item ~= Enum.UserInputType.None then
		return Item
	end
	return nil
end

local function Binder(Parent, Position, Opt)
	Opt = Opt or {}
	local Bind
	local Mode = "Toggle"
	local Active = false
	local Listening = false
	local Hover = false
	local Object = {}
	local Button = New("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = Position, Size = UDim2.fromOffset(44, 14), Parent = Parent }, { BackgroundColor3 = "Field" })
	local ButtonStroke = Stroke(Button, "Glow")
	local Label = New("TextLabel", { Size = UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd, Parent = Button })

	local function Paint()
		Label.Text = Listening and "..." or (Bind and (KeyShort[Bind.Name] or Bind.Name) or "None")
		Label.TextColor3 = Listening and Zero.Theme.Accent or (Active and Zero.Theme.Text or Zero.Theme.DimText)
		ButtonStroke.Color = (Listening or Hover) and Zero.Theme.Accent or Zero.Theme.Glow
	end
	table.insert(Zero.Refreshers, Paint)

	local function SetActive(State, Silent)
		if Active == State then
			return
		end
		Active = State
		Paint()
		Commit(Opt, Active, Silent)
	end

	local function Changed(Silent)
		SetActive(Mode == "Always", Silent)
		Paint()
		if not Silent and Opt.Changed then
			task.spawn(Opt.Changed, Object:Get())
		end
	end

	function Object:Get()
		return { Key = Bind and Bind.Name or "None", Mode = Mode }
	end
	function Object:IsActive()
		return Active
	end
	function Object:SetMode(NewMode, Silent)
		if table.find(BindModes, NewMode) then
			Mode = NewMode
			Active = false
			Changed(Silent)
		end
	end
	function Object:Set(Value, Silent)
		local NewKey, NewMode = Value, nil
		if type(Value) == "table" then
			NewKey, NewMode = Value.Key, Value.Mode
		end
		if typeof(NewKey) == "EnumItem" then
			Bind = NewKey
		else
			Bind = LookupKey(NewKey)
		end
		if table.find(BindModes, NewMode) then
			Mode = NewMode
		end
		Active = false
		Changed(Silent)
	end

	if Opt.Flag then
		Zero.Options[Opt.Flag] = Object
	end
	Object:Set({ Key = Opt.Default, Mode = Opt.Mode }, true)
	Commit(Opt, Active, true)

	Connect(UserInputService.InputBegan, function(Input)
		if Listening then
			local Item
			if Input.UserInputType == Enum.UserInputType.Keyboard then
				Item = Input.KeyCode
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 or Input.UserInputType == Enum.UserInputType.MouseButton3 then
				Item = Input.UserInputType
			else
				return
			end
			Listening = false
			Bind = Item ~= Enum.KeyCode.Escape and Item or nil
			Active = false
			Changed()
			return
		end
		if not Bind or Mode == "Always" or UserInputService:GetFocusedTextBox() then
			return
		end
		if Input.KeyCode == Bind or Input.UserInputType == Bind then
			if Mode == "Hold" then
				SetActive(true)
			else
				SetActive(not Active)
			end
		end
	end)
	Connect(UserInputService.InputEnded, function(Input)
		if Mode == "Hold" and Active and Bind and (Input.KeyCode == Bind or Input.UserInputType == Bind) then
			SetActive(false)
		end
	end)

	Button.MouseEnter:Connect(function()
		Hover = true
		Paint()
	end)
	Button.MouseLeave:Connect(function()
		Hover = false
		Paint()
	end)
	Button.Activated:Connect(function()
		Zero:ClosePopup()
		Listening = not Listening
		Paint()
	end)
	Button.MouseButton2Click:Connect(function()
		if Listening then
			return
		end
		local Index = table.find(BindModes, Mode) or 1
		Object:SetMode(BindModes[Index % #BindModes + 1])
		Zero:Notify((Opt.Name or "Keybind") .. ": " .. Mode, 2)
	end)
	Paint()
	return Object
end

function Elements:Toggle(Name, Opt)
	Opt = Opt or {}
	local Value = false
	local Hover = false
	local Ready = false
	local Row = New("TextButton", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = self.Content })
	local Box = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		Parent = Row,
	}, { BackgroundColor3 = "Field" })
	local BoxStroke = Stroke(Box, "Glow")
	local Press = New("UIScale", { Parent = Box })
	local BoxGlow = Halo(Box, 5, 1)
	local Mark = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0, 0),
		Parent = Box,
	}, { BackgroundColor3 = "Accent" })
	New("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 152, 172)), Rotation = 90, Parent = Mark })
	New("TextLabel", {
		Text = Name,
		Position = UDim2.fromOffset(19, PixelFont and 1 or 0),
		Size = UDim2.new(1, -19, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Row,
	})
	local function Target()
		return (Value or Hover) and Zero.Theme.Accent or Zero.Theme.Glow
	end
	local function Paint()
		if not Ready then
			BoxStroke.Color = Target()
			HaloSet(BoxGlow, Value and 0.45 or 1)
			Mark.Size = Value and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 0)
			return
		end
		Tween(BoxStroke, { Color = Target() }, 0.18)
		HaloSet(BoxGlow, Value and 0.45 or 1, 0.3)
		if Value then
			Tween(Mark, { Size = UDim2.fromScale(1, 1) }, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		else
			Tween(Mark, { Size = UDim2.fromScale(0, 0) }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end
	end
	table.insert(Zero.Refreshers, function()
		BoxStroke.Color = Target()
	end)
	Row.MouseEnter:Connect(function()
		Hover = true
		Tween(BoxStroke, { Color = Target() }, 0.15)
	end)
	Row.MouseLeave:Connect(function()
		Hover = false
		Tween(BoxStroke, { Color = Target() }, 0.2)
		Tween(Press, { Scale = 1 }, 0.2)
	end)
	Row.MouseButton1Down:Connect(function()
		Tween(Press, { Scale = 0.82 }, 0.08)
	end)
	Row.MouseButton1Up:Connect(function()
		Tween(Press, { Scale = 1 }, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	local Object = { Swatches = 0 }
	function Object:Get()
		return Value
	end
	function Object:Set(State, Silent)
		Value = State and true or false
		Paint()
		Commit(Opt, Value, Silent)
	end
	function Object:Colorpicker(Default, PickerOpt)
		self.Swatches += 1
		local Picker = Swatch(Row, UDim2.new(1, -((self.Swatches - 1) * 24), 0.5, 0), Default, PickerOpt)
		return Picker
	end
	function Object:Keybind(BindOpt)
		BindOpt = BindOpt or {}
		BindOpt.Name = BindOpt.Name or Name
		local Offset = self.Swatches * 24
		self.Swatches += 2
		return Binder(Row, UDim2.new(1, -Offset, 0.5, 0), BindOpt)
	end
	if Opt.Flag then
		Zero.Options[Opt.Flag] = Object
	end
	Object:Set(Opt.Default, true)
	Ready = true
	Row.Activated:Connect(function()
		Object:Set(not Value)
	end)
	return Object
end

function Elements:Slider(Name, Opt)
	Opt = Opt or {}
	local Min, Max, Step = Opt.Min or 0, Opt.Max or 100, Opt.Increment or 1
	local Decimals = 0
	local StepText = tostring(Step)
	local Dot = StepText:find("%.")
	if Dot then
		Decimals = #StepText - Dot
	end
	local Value = Min
	local Ready = false
	local Hover, Dragging = false, false
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = self.Content })
	New("TextLabel", { Text = Name, Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder }, { TextColor3 = "DimText" })
	local ValueLabel = New("TextLabel", { Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Right, Parent = Holder }, { TextColor3 = "DimText" })
	local Bar = New("TextButton", { Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 9), Parent = Holder }, { BackgroundColor3 = "Field" })
	local BarStroke = Stroke(Bar, "Inline")
	Glow(Bar, 0.6, 0.4)
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = Bar }, { BackgroundColor3 = "Accent" })
	local FillHalo = Halo(Fill, 6, 0.45)
	New("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 152, 172)), Rotation = 90, Parent = Fill })
	local function Focus()
		local Active = Hover or Dragging
		Tween(BarStroke, { Color = Active and Zero.Theme.Accent or Zero.Theme.Inline }, 0.2)
		HaloSet(FillHalo, Dragging and 0.2 or 0.45, 0.2)
		Tween(ValueLabel, { TextColor3 = Active and Zero.Theme.Text or Zero.Theme.DimText }, 0.2)
	end
	local Object = {}
	function Object:Get()
		return Value
	end
	function Object:Set(Number, Silent)
		Number = math.clamp(math.floor((Number - Min) / Step + 0.5) * Step + Min, Min, Max)
		Value = tonumber(string.format("%." .. Decimals .. "f", Number))
		local Goal = UDim2.fromScale((Value - Min) / math.max(Max - Min, 1e-9), 1)
		if Ready then
			Tween(Fill, { Size = Goal }, 0.14, Enum.EasingStyle.Quad)
		else
			Fill.Size = Goal
		end
		ValueLabel.Text = string.format("%." .. Decimals .. "f", Value) .. (Opt.Suffix or "")
		Commit(Opt, Value, Silent)
	end
	local function FromX(X)
		local Ratio = math.clamp((X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
		Object:Set(Min + (Max - Min) * Ratio)
	end
	Bar.MouseEnter:Connect(function()
		Hover = true
		Focus()
	end)
	Bar.MouseLeave:Connect(function()
		Hover = false
		Focus()
	end)
	Track(Bar, function(Input)
		Dragging = true
		Focus()
		if self.Scroll then
			self.Scroll.ScrollingEnabled = false
		end
		FromX(Input.Position.X)
	end, function(_, Changed)
		FromX(Changed.Position.X)
	end, function()
		Dragging = false
		Focus()
		if self.Scroll then
			self.Scroll.ScrollingEnabled = true
		end
	end)
	if Opt.Flag then
		Zero.Options[Opt.Flag] = Object
	end
	Object:Set(Opt.Default or Min, true)
	Ready = true
	return Object
end

function Elements:Dropdown(Name, Opt)
	Opt = Opt or {}
	local Options = Opt.Options or {}
	local Multi = Opt.Multi
	local Selected = {}
	local Single
	if Multi then
		for _, Item in Opt.Default or {} do
			Selected[Item] = true
		end
	else
		Single = Opt.Default or Options[1]
	end
	local Open, Hover = false, false
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = self.Content })
	New("TextLabel", { Text = Name, Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder }, { TextColor3 = "DimText" })
	local Field = New("TextButton", { Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 0, 21), Parent = Holder }, { BackgroundColor3 = "Field" })
	local FieldStroke = Stroke(Field, "Inline")
	Glow(Field, 0.6, 0.4)
	local Display = New("TextLabel", {
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.new(1, -22, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Field,
	})
	local Plus = New("TextLabel", {
		Text = "+",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 21),
		Position = UDim2.new(1, -8, 0.5, 0),
		Parent = Field,
	}, { TextColor3 = "DimText" })
	local function Look()
		local Active = Open or Hover
		Tween(FieldStroke, { Color = Active and Zero.Theme.Accent or Zero.Theme.Inline }, 0.18)
		Tween(Plus, { Rotation = Open and 45 or 0, TextColor3 = Active and Zero.Theme.Text or Zero.Theme.DimText }, 0.28)
	end
	Field.MouseEnter:Connect(function()
		Hover = true
		Look()
	end)
	Field.MouseLeave:Connect(function()
		Hover = false
		Look()
	end)
	local function Value()
		if Multi then
			local Out = {}
			for _, Item in Options do
				if Selected[Item] then
					table.insert(Out, Item)
				end
			end
			return Out
		end
		return Single
	end
	local function Show()
		if Multi then
			local Current = Value()
			Display.Text = #Current > 0 and table.concat(Current, ", ") or "none"
		else
			Display.Text = tostring(Single or "none")
		end
	end
	local Object = {}
	function Object:Get()
		return Value()
	end
	function Object:Set(NewValue, Silent)
		if Multi then
			Selected = {}
			for _, Item in NewValue or {} do
				Selected[Item] = true
			end
		else
			Single = NewValue
		end
		Show()
		Commit(Opt, Value(), Silent)
	end
	function Object:SetOptions(NewOptions)
		Options = NewOptions
		Zero:ClosePopup()
		if Multi then
			for Item in Selected do
				if not table.find(Options, Item) then
					Selected[Item] = nil
				end
			end
		elseif not table.find(Options, Single) then
			Single = Options[1]
		end
		Show()
	end
	Field.Activated:Connect(function()
		if Zero.Popup and Zero.Popup.Owner == Field then
			Zero:ClosePopup()
			return
		end
		local Count = math.min(#Options, 6)
		local Top = Opt.Search and 22 or 0
		local Popup = Zero:OpenPopup(Field, Field.AbsoluteSize.X / Zero.Scale, Count * 18 + 2 + Top)
		Open = true
		Look()
		Popup.OnClose = function()
			Open = false
			Look()
		end
		local Scroll = New("ScrollingFrame", {
			Position = UDim2.fromOffset(0, Top),
			Size = UDim2.new(1, 0, 1, -Top),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 2,
			BackgroundTransparency = 1,
			Parent = Popup.Body,
		}, { ScrollBarImageColor3 = "Accent" })
		List(Scroll, 0)
		local Buttons = {}
		local function On(Item)
			return (Multi and Selected[Item] or (not Multi and Single == Item)) and true or false
		end
		local function Paint(Instant)
			for Item, Button in Buttons do
				local Active = On(Item)
				Morph(Button, {
					BackgroundTransparency = Active and 0 or 1,
					TextColor3 = Active and Zero.Theme.Text or Zero.Theme.DimText,
				}, not Instant and 0.15 or 0)
			end
		end
		for _, Item in Options do
			local Button = New("TextButton", { Size = UDim2.new(1, 0, 0, 18), Text = Item, TextXAlignment = Enum.TextXAlignment.Left, Parent = Scroll }, { BackgroundColor3 = "Inline" })
			Pad(Button, 6, 0)
			Buttons[Item] = Button
			Button.MouseEnter:Connect(function()
				if not On(Item) then
					Tween(Button, { BackgroundTransparency = 0.6, TextColor3 = Zero.Theme.Text }, 0.12)
				end
			end)
			Button.MouseLeave:Connect(function()
				if not On(Item) then
					Tween(Button, { BackgroundTransparency = 1, TextColor3 = Zero.Theme.DimText }, 0.18)
				end
			end)
			Button.Activated:Connect(function()
				if Multi then
					Selected[Item] = not Selected[Item]
					Show()
					Commit(Opt, Value())
					Paint()
				else
					Single = Item
					Show()
					Commit(Opt, Value())
					Zero:ClosePopup()
				end
			end)
		end
		Paint(true)
		if Opt.Search then
			local Box = New("TextBox", {
				Position = UDim2.fromOffset(3, 3),
				Size = UDim2.new(1, -6, 0, 16),
				PlaceholderText = "search...",
				Text = "",
				ClearTextOnFocus = false,
				ClipsDescendants = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Popup.Body,
			}, { BackgroundColor3 = "Background", PlaceholderColor3 = "DimText" })
			Pad(Box, 5, 0)
			Stroke(Box, "Inline")
			Box:GetPropertyChangedSignal("Text"):Connect(function()
				local Query = Box.Text:lower()
				for _, Item in Options do
					Buttons[Item].Visible = Query == "" or tostring(Item):lower():find(Query, 1, true) ~= nil
				end
				Scroll.CanvasPosition = Vector2.zero
			end)
			if not Zero.Mobile then
				Box:CaptureFocus()
			end
		end
	end)
	if Opt.Flag then
		Zero.Options[Opt.Flag] = Object
	end
	Show()
	Commit(Opt, Value(), true)
	return Object
end

function Elements:SearchDropdown(Name, Opt)
	Opt = Opt or {}
	Opt.Search = true
	return self:Dropdown(Name, Opt)
end

function Elements:ButtonRow(Items)
	local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = self.Content })
	List(Row, 4, true)
	local Count = #Items
	for _, Item in Items do
		local Button = New("TextButton", {
			Size = UDim2.new(1 / Count, -4 * (Count - 1) / Count, 1, 0),
			Parent = Row,
		}, { BackgroundColor3 = "Field" })
		local Outline = Stroke(Button, "Inline")
		Glow(Button, 0.6, 0.4)
		New("TextLabel", { Text = Item[1], Size = UDim2.fromScale(1, 1), Parent = Button })
		local Over = false
		Button.MouseEnter:Connect(function()
			Over = true
			Tween(Button, { BackgroundColor3 = Zero.Theme.Inline }, 0.15)
			Tween(Outline, { Color = Zero.Theme.Accent }, 0.15)
		end)
		Button.MouseLeave:Connect(function()
			Over = false
			Tween(Button, { BackgroundColor3 = Zero.Theme.Field }, 0.22)
			Tween(Outline, { Color = Zero.Theme.Inline }, 0.22)
		end)
		Button.MouseButton1Down:Connect(function()
			Tween(Button, { BackgroundColor3 = Zero.Theme.Field:Lerp(Zero.Theme.Accent, 0.4) }, 0.08)
			Tween(Outline, { Color = Zero.Theme.Accent }, 0.08)
		end)
		Button.MouseButton1Up:Connect(function()
			Tween(Button, { BackgroundColor3 = Over and Zero.Theme.Inline or Zero.Theme.Field }, 0.3)
		end)
		Button.Activated:Connect(function()
			task.spawn(Item[2])
		end)
	end
	return Row
end

function Elements:Button(Name, Callback)
	return self:ButtonRow({ { Name, Callback } })
end

function Elements:Textbox(Placeholder, Opt)
	Opt = Opt or {}
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 20), Parent = self.Content }, { BackgroundColor3 = "Field" })
	local HolderStroke = Stroke(Holder, "Inline")
	Glow(Holder, 0.6, 0.4)
	local Box = New("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		PlaceholderText = Placeholder or "",
		PlaceholderColor3 = Color3.fromRGB(84, 90, 114),
		Text = Opt.Default or "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Holder,
	})
	Pad(Box, 6, 0)
	local Object = {}
	function Object:Get()
		return Box.Text
	end
	function Object:Set(Text, Silent)
		Box.Text = Text
		Commit(Opt, Text, Silent)
	end
	Box.Focused:Connect(function()
		Tween(HolderStroke, { Color = Zero.Theme.Accent }, 0.2)
	end)
	Box.FocusLost:Connect(function()
		Tween(HolderStroke, { Color = Zero.Theme.Inline }, 0.25)
		Commit(Opt, Box.Text)
	end)
	if Opt.Flag then
		Zero.Options[Opt.Flag] = Object
	end
	Commit(Opt, Box.Text, true)
	return Object
end

function Elements:Label(Text, Opt)
	Opt = Opt or {}
	local Props = {
		Text = Text or "",
		Size = UDim2.new(1, 0, 0, 12),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Content,
	}
	local Label
	if Opt.Color then
		Props.TextColor3 = Opt.Color
		Label = New("TextLabel", Props)
	else
		Label = New("TextLabel", Props, { TextColor3 = "DimText" })
	end
	local Object = {}
	function Object:Set(NewText)
		Label.Text = tostring(NewText)
	end
	function Object:Get()
		return Label.Text
	end
	function Object:SetColor(Color)
		Label.TextColor3 = Color
	end
	return Object
end

function Elements:Keybind(Name, Opt)
	Opt = Opt or {}
	Opt.Name = Opt.Name or Name
	local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = self.Content })
	New("TextLabel", { Text = Name, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left, Parent = Row })
	return Binder(Row, UDim2.new(1, 0, 0.5, 0), Opt)
end

function Elements:Divider()
	return New("Frame", { Size = UDim2.new(1, 0, 0, 1), Parent = self.Content }, { BackgroundColor3 = "Inline" })
end

function Elements:Colorpicker(Name, Default, Opt)
	local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Parent = self.Content })
	New("TextLabel", { Text = Name, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left, Parent = Row })
	local Picker = Swatch(Row, UDim2.new(1, 0, 0.5, 0), Default, Opt)
	return Picker
end

function Elements:Listbox(Opt)
	Opt = Opt or {}
	local Selected
	local Holder = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, Opt.Height or 90),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		Parent = self.Content,
	}, { BackgroundColor3 = "Field", ScrollBarImageColor3 = "Accent" })
	Stroke(Holder, "Inline")
	List(Holder, 0)
	local Buttons = {}
	local Object = {}
	local function Paint(Instant)
		for Name, Button in Buttons do
			local On = Name == Selected
			Morph(Button, {
				BackgroundTransparency = On and 0 or 1,
				TextColor3 = On and Zero.Theme.Text or Zero.Theme.DimText,
			}, not Instant and 0.15 or 0)
		end
	end
	table.insert(Zero.Refreshers, function()
		Paint(true)
	end)
	function Object:Get()
		return Selected
	end
	function Object:Set(Name, Silent)
		Selected = Name
		Paint()
		Commit(Opt, Name, Silent)
	end
	function Object:SetItems(Items)
		for _, Button in Buttons do
			Button:Destroy()
		end
		table.clear(Buttons)
		for _, Name in Items do
			local Button = New("TextButton", { Size = UDim2.new(1, 0, 0, 18), Text = Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder }, { BackgroundColor3 = "Inline" })
			Pad(Button, 6, 0)
			Buttons[Name] = Button
			Button.MouseEnter:Connect(function()
				if Name ~= Selected then
					Tween(Button, { BackgroundTransparency = 0.6, TextColor3 = Zero.Theme.Text }, 0.12)
				end
			end)
			Button.MouseLeave:Connect(function()
				if Name ~= Selected then
					Tween(Button, { BackgroundTransparency = 1, TextColor3 = Zero.Theme.DimText }, 0.18)
				end
			end)
			Button.Activated:Connect(function()
				Object:Set(Name)
			end)
		end
		if not Buttons[Selected] then
			Selected = nil
		end
		Paint(true)
	end
	Object:SetItems(Opt.Items or {})
	return Object
end

function Elements:SubSection(Name)
	local Host = self.SubHost
	if not Host then
		local Strip = Scroller({ Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 1, Parent = self.Content })
		List(Strip, 2, true)
		local Pages = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2, Parent = self.Content })
		List(Pages, 0)
		Host = { Strip = Strip, Pages = Pages, Items = {} }
		function Host.Select(Target, Instant)
			if Host.Active == Target then
				return
			end
			Host.Active = Target
			for _, Other in Host.Items do
				Other.Page.Visible = Other == Target
				Other.Update(Instant)
			end
			if not Instant then
				Reveal(Host.Strip, Target.Button)
			end
		end
		self.SubHost = Host
	end

	local Item = {}
	local Hover = false
	local Button = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = Host.Strip }, { BackgroundColor3 = "Field" })
	Floor(Button, 56)
	Stroke(Button, "Inline")
	local ButtonGlow = Glow(Button, 0.5, 0.3)
	ButtonGlow.BackgroundTransparency = 1
	local Label = New("TextLabel", { Text = Name, Size = UDim2.fromScale(1, 1), Parent = Button })
	local Line = Fade(New("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 1, Parent = Button }, { BackgroundColor3 = "Accent" }))
	local Page = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, Parent = Host.Pages })
	List(Page, 5)

	Item.Page = Page
	Item.Button = Button
	function Item.Update(Instant)
		local On = Host.Active == Item
		local Time = Instant and 0 or 0.22
		local Idle = Hover and Zero.Theme.DimText:Lerp(Zero.Theme.Text, 0.6) or Zero.Theme.DimText
		Morph(Button, { BackgroundColor3 = On and Zero.Theme.Background or Zero.Theme.Field }, Time)
		Morph(Label, { TextColor3 = On and Zero.Theme.Text or Idle }, Time)
		Morph(ButtonGlow, { BackgroundTransparency = On and 0 or 1 }, Time)
		Morph(Line, { BackgroundTransparency = On and 0 or 1 }, Time)
	end
	table.insert(Zero.Refreshers, function()
		Item.Update(true)
	end)

	table.insert(Host.Items, Item)
	local Count = #Host.Items
	for _, Other in Host.Items do
		Other.Button.Size = UDim2.new(1 / Count, -(Count - 1) * 2 / Count, 1, 0)
	end

	Button.MouseEnter:Connect(function()
		Hover = true
		if Host.Active ~= Item then
			Item.Update()
		end
	end)
	Button.MouseLeave:Connect(function()
		Hover = false
		if Host.Active ~= Item then
			Item.Update()
		end
	end)
	Button.Activated:Connect(function()
		Zero:ClosePopup()
		Host.Select(Item)
	end)

	if Count == 1 then
		Host.Select(Item, true)
	else
		Item.Update(true)
	end
	return setmetatable({ Content = Page, Scroll = self.Scroll }, Elements)
end

local function Spin(View)
	local Model
	local Angle = 0
	local function Build()
		if Model then
			Model:Destroy()
			Model = nil
		end
		local Character = LocalPlayer.Character
		if not Character then
			return
		end
		local Ok, Clone = pcall(function()
			Character.Archivable = true
			return Character:Clone()
		end)
		if not Ok or not Clone then
			return
		end
		for _, Descendant in Clone:GetDescendants() do
			if Descendant:IsA("BaseScript") then
				Descendant:Destroy()
			end
		end
		local Root = Clone:FindFirstChild("HumanoidRootPart")
		if not Root then
			Clone:Destroy()
			return
		end
		Root.Anchored = true
		local Humanoid = Clone:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		Clone.Parent = View
		Model = Clone
	end
	Build()
	Connect(LocalPlayer.CharacterAdded, function()
		task.wait(1)
		Build()
	end)
	Connect(RunService.Heartbeat, function(Delta)
		if Model and Model.Parent then
			Angle += Delta * 0.9
			Model:PivotTo(CFrame.Angles(0, Angle, 0))
		end
	end)
end

function Elements:Preview(Height, Opt)
	Opt = Opt or {}
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, Height or 180), ClipsDescendants = true, Parent = self.Content }, { BackgroundColor3 = "Background" })
	Stroke(Holder, "Inline")
	local View = New("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(160, 164, 188),
		LightColor = Color3.fromRGB(255, 255, 255),
		Parent = Holder,
	})
	local Cam = Instance.new("Camera")
	Cam.FieldOfView = 35
	Cam.CFrame = CFrame.lookAt(Vector3.new(0, 0, 10), Vector3.new(0, -0.3, 0))
	Cam.Parent = View
	View.CurrentCamera = Cam
	if Opt.Box ~= false then
		local Box = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.52, 0.86), BackgroundTransparency = 1, Parent = Holder })
		Stroke(Box, "Text")
	end
	New("TextLabel", { Text = Zero.Anonymous and "Anonymous" or LocalPlayer.DisplayName, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, 2), Parent = Holder })
	Spin(View)
	return Holder
end

function Elements:EspPreview(Height, Config)
	Height = Height or 240
	local Black = Color3.new(0, 0, 0)
	local White = Color3.new(1, 1, 1)
	local Low = Color3.fromRGB(255, 50, 50)
	local High = Color3.fromRGB(90, 255, 90)
	local Ratio = 0.72
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, Height), ClipsDescendants = true, Parent = self.Content }, { BackgroundColor3 = "Background" })
	Stroke(Holder, "Inline")
	local View = New("ViewportFrame", {
		Position = UDim2.fromScale(0.12, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(160, 164, 188),
		LightColor = Color3.fromRGB(255, 255, 255),
		Parent = Holder,
	})
	local Cam = Instance.new("Camera")
	Cam.FieldOfView = 35
	Cam.CFrame = CFrame.lookAt(Vector3.new(0, -0.2, 14.8), Vector3.new(0, -0.2, 0))
	Cam.Parent = View
	View.CurrentCamera = Cam

	local function Rect(Props)
		if Props.BackgroundTransparency == nil then
			Props.BackgroundTransparency = 1
		end
		Props.Visible = false
		Props.ZIndex = 2
		Props.Parent = Holder
		return New("Frame", Props)
	end
	local function Border(Frame, Color)
		return New("UIStroke", {
			Color = Color,
			Thickness = 1,
			LineJoinMode = Enum.LineJoinMode.Miter,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = Frame,
		})
	end
	local function Label(Anchor, Width)
		return New("TextLabel", {
			AnchorPoint = Anchor,
			Size = UDim2.fromOffset(Width, 14),
			TextColor3 = White,
			TextStrokeColor3 = Black,
			TextStrokeTransparency = 0,
			Visible = false,
			ZIndex = 2,
			Parent = Holder,
		})
	end

	local Fill = Rect({ BackgroundTransparency = 0, BackgroundColor3 = Config.FillColor })
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.85) }),
		Parent = Fill,
	})
	local Outer = Rect({})
	Border(Outer, Black)
	local Main = Rect({})
	local MainStroke = Border(Main, Config.BoxColor)
	local Inner = Rect({})
	Border(Inner, Black)
	local HealthBack = Rect({ BackgroundTransparency = 0.2, BackgroundColor3 = Black })
	local HealthFill = Rect({ BackgroundTransparency = 0, AnchorPoint = Vector2.new(0, 1) })
	local HealthText = Label(Vector2.new(1, 0.5), 30)
	HealthText.TextXAlignment = Enum.TextXAlignment.Right
	local Tracer = Rect({ BackgroundTransparency = 0, AnchorPoint = Vector2.new(0.5, 0.5) })
	local NameLabel = Label(Vector2.new(0.5, 0.5), 120)
	local InfoLabel = Label(Vector2.new(0.5, 0.5), 120)
	local ToolLabel = Label(Vector2.new(0.5, 0.5), 120)
	NameLabel.Text = Zero.Anonymous and "Anonymous" or LocalPlayer.DisplayName
	InfoLabel.Text = "42m"
	ToolLabel.Text = "Tool"
	HealthText.Text = tostring(math.floor(Ratio * 100))

	local function Refresh()
		local Size = Holder.AbsoluteSize
		if Size.Y <= 0 then
			return
		end
		local Factor = Size.Y / Height
		local Width = Size.X / Factor
		local H = math.floor(Height * 0.62)
		local W = math.floor(H * 0.56)
		local CenterX = math.floor(Width * 0.62)
		local Left = CenterX - math.floor(W / 2)
		local Top = math.floor(Height * 0.19)
		local InnerW = math.max(W - 2, 0)
		local InnerH = math.max(H - 2, 0)

		local ShowBox = Config.Box
		Outer.Visible = ShowBox
		Main.Visible = ShowBox
		Inner.Visible = ShowBox
		if ShowBox then
			Outer.Position = UDim2.fromOffset(Left - 1, Top - 1)
			Outer.Size = UDim2.fromOffset(W + 2, H + 2)
			Main.Position = UDim2.fromOffset(Left, Top)
			Main.Size = UDim2.fromOffset(W, H)
			MainStroke.Color = Config.BoxColor
			Inner.Position = UDim2.fromOffset(Left + 1, Top + 1)
			Inner.Size = UDim2.fromOffset(InnerW, InnerH)
		end

		local ShowFill = ShowBox and Config.BoxFill
		Fill.Visible = ShowFill
		if ShowFill then
			Fill.Position = UDim2.fromOffset(Left + 1, Top + 1)
			Fill.Size = UDim2.fromOffset(InnerW, InnerH)
			Fill.BackgroundColor3 = Config.FillColor
			Fill.BackgroundTransparency = Config.FillTransparency
		end

		local HealthColor = Low:Lerp(High, Ratio)
		local FillHeight = math.max(math.floor(H * Ratio), 1)
		local ShowHealth = Config.Health
		HealthBack.Visible = ShowHealth
		HealthFill.Visible = ShowHealth
		HealthText.Visible = ShowHealth
		if ShowHealth then
			HealthBack.Position = UDim2.fromOffset(Left - 6, Top - 1)
			HealthBack.Size = UDim2.fromOffset(4, H + 2)
			HealthFill.Position = UDim2.fromOffset(Left - 5, Top + H)
			HealthFill.Size = UDim2.fromOffset(2, FillHeight)
			HealthFill.BackgroundColor3 = HealthColor
			HealthText.TextColor3 = HealthColor
			HealthText.Position = UDim2.fromOffset(Left - 8, Top + H - FillHeight)
		end

		NameLabel.Visible = Config.Name
		if Config.Name then
			NameLabel.TextColor3 = Config.NameColor
			NameLabel.Position = UDim2.fromOffset(CenterX, Top - 9)
		end

		local OffsetY = Top + H + 8
		InfoLabel.Visible = Config.Distance
		if Config.Distance then
			InfoLabel.TextColor3 = Config.InfoColor
			InfoLabel.Position = UDim2.fromOffset(CenterX, OffsetY)
			OffsetY += 11
		end
		ToolLabel.Visible = Config.Tool
		if Config.Tool then
			ToolLabel.TextColor3 = Config.InfoColor
			ToolLabel.Position = UDim2.fromOffset(CenterX, OffsetY)
		end

		Tracer.Visible = Config.Tracer
		if Config.Tracer then
			local FromX = Width / 2
			local FromY = Height
			local DX = CenterX - FromX
			local DY = Top + H - FromY
			Tracer.Position = UDim2.fromOffset(FromX + DX / 2, FromY + DY / 2)
			Tracer.Size = UDim2.fromOffset(math.sqrt(DX * DX + DY * DY), 1)
			Tracer.Rotation = math.deg(math.atan2(DY, DX))
			Tracer.BackgroundColor3 = Config.TracerColor
		end
	end

	Spin(View)
	Connect(RunService.RenderStepped, Refresh)
	Refresh()
	return Holder
end

local function Tick(Callback)
	if not Zero.TickLoop then
		Zero.TickLoop = true
		Zero.FPS = 60
		local Frames, Last = 0, os.clock()
		Connect(RunService.RenderStepped, function()
			Frames += 1
			local Now = os.clock()
			if Now - Last >= 0.5 then
				Zero.FPS = math.floor(Frames / (Now - Last) + 0.5)
				Frames = 0
				Last = Now
			end
		end)
		task.spawn(function()
			while Gui.Parent do
				task.wait(1)
				for _, Run in Zero.Ticks do
					pcall(Run)
				end
			end
		end)
	end
	table.insert(Zero.Ticks, Callback)
	pcall(Callback)
end

function Elements:Stat(Name, Source)
	local Row = New("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Parent = self.Content })
	New("TextLabel", { Text = Name, Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Row }, { TextColor3 = "DimText" })
	local Value = New("TextLabel", { Position = UDim2.fromScale(0.4, 0), Size = UDim2.fromScale(0.6, 1), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Row })
	local Object = {}
	function Object:Set(Text)
		Value.Text = tostring(Text)
	end
	if type(Source) == "function" then
		Tick(function()
			Object:Set(Source())
		end)
	else
		Object:Set(Source)
	end
	return Object
end

function Elements:Profile(Opt)
	Opt = Opt or {}
	local Holder = New("Frame", { Size = UDim2.new(1, 0, 0, 92), ClipsDescendants = true, Parent = self.Content }, { BackgroundColor3 = "Field" })
	Stroke(Holder, "Inline")
	Glow(Holder, 0.6, 0.4)
	local Banner = New("Frame", { Size = UDim2.new(1, 0, 0, 46), Parent = Holder }, { BackgroundColor3 = "Accent" })
	New("UIGradient", { Transparency = NumberSequence.new(0.5, 1), Rotation = 90, Parent = Banner })
	local Avatar = New("ImageLabel", {
		Position = UDim2.fromOffset(10, 14),
		Size = UDim2.fromOffset(64, 64),
		BackgroundTransparency = 0,
		Parent = Holder,
	}, { BackgroundColor3 = "Background" })
	Stroke(Avatar, "Accent")
	local Online = New("Frame", { Position = UDim2.fromOffset(66, 70), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = Color3.fromRGB(88, 200, 120), Parent = Holder })
	Stroke(Online, "Field")
	New("TextLabel", { Text = Zero.Anonymous and "Anonymous" or LocalPlayer.DisplayName, Position = UDim2.fromOffset(84, 14), Size = UDim2.new(1, -90, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Holder })
	New("TextLabel", { Text = Zero.Anonymous and "@hidden" or ("@" .. LocalPlayer.Name), Position = UDim2.fromOffset(84, 30), Size = UDim2.new(1, -90, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Holder }, { TextColor3 = "DimText" })
	New("TextLabel", { Text = Opt.Tag or "User", Position = UDim2.fromOffset(84, 46), Size = UDim2.new(1, -90, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder }, { TextColor3 = "Accent" })
	local GameLabel = New("TextLabel", { Position = UDim2.fromOffset(84, 62), Size = UDim2.new(1, -90, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Holder }, { TextColor3 = "DimText" })
	Tick(function()
		GameLabel.Text = "Game: " .. Zero.PlaceName
	end)
	task.spawn(function()
		if Zero.Anonymous then
			return
		end
		local Ok, Image = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if Ok and Image then
			Avatar.Image = Image
		end
	end)
	return Holder
end

function Elements:ConfigManager()
	local Name = self:Textbox("config name...")
	local Configs = self:Listbox({ Height = 96 })
	local Status = self:Label("")
	local function Reload()
		Configs:SetItems(Zero:ListConfigs())
	end
	local function Pick()
		local Text = Name:Get()
		if Text == "" then
			Text = Configs:Get() or ""
		end
		return (Text:gsub("[^%w%-_ ]", ""))
	end
	self:ButtonRow({
		{ "save", function()
			local Config = Pick()
			if Config == "" then
				Status:Set("enter a name")
				return
			end
			if Zero:SaveConfig(Config) then
				Status:Set("saved " .. Config)
				Reload()
				Configs:Set(Config, true)
			else
				Status:Set("file access missing")
			end
		end },
		{ "load", function()
			local Config = Configs:Get() or Pick()
			Status:Set(Zero:LoadConfig(Config) and ("loaded " .. Config) or "config not found")
		end },
	})
	self:ButtonRow({
		{ "delete", function()
			local Config = Configs:Get()
			if Config and Zero:DeleteConfig(Config) then
				Status:Set("deleted " .. Config)
				Reload()
			else
				Status:Set("select a config")
			end
		end },
		{ "set autoload", function()
			local Config = Configs:Get()
			if Config and Zero:SetAutoload(Config) then
				Status:Set("autoload " .. Config)
			else
				Status:Set("select a config")
			end
		end },
	})
	self:Button("refresh", Reload)
	Reload()
end

local function CanFile()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfolder) == "function" and typeof(makefolder) == "function" and typeof(isfile) == "function"
end

function Zero:Path(Name)
	return self.Folder .. "/configs/" .. Name .. ".json"
end

function Zero:Prepare()
	if not CanFile() then
		return false
	end
	for _, Path in { self.Folder, self.Folder .. "/configs" } do
		if not isfolder(Path) then
			makefolder(Path)
		end
	end
	return true
end

function Zero:Encode()
	local Data = {}
	for Flag, Option in self.Options do
		local Value = Option:Get()
		if typeof(Value) == "Color3" then
			Value = { __color = { math.floor(Value.R * 255 + 0.5), math.floor(Value.G * 255 + 0.5), math.floor(Value.B * 255 + 0.5) } }
		end
		Data[Flag] = Value
	end
	return HttpService:JSONEncode(Data)
end

function Zero:Decode(Json)
	local Ok, Data = pcall(HttpService.JSONDecode, HttpService, Json)
	if not Ok or type(Data) ~= "table" then
		return false
	end
	for Flag, Value in Data do
		local Option = self.Options[Flag]
		if Option then
			if type(Value) == "table" and Value.__color then
				Value = Color3.fromRGB(Value.__color[1], Value.__color[2], Value.__color[3])
			end
			pcall(Option.Set, Option, Value)
		end
	end
	return true
end

function Zero:SaveConfig(Name)
	if not self:Prepare() then
		return false
	end
	writefile(self:Path(Name), self:Encode())
	return true
end

function Zero:LoadConfig(Name)
	if not self:Prepare() or not isfile(self:Path(Name)) then
		return false
	end
	return self:Decode(readfile(self:Path(Name)))
end

function Zero:DeleteConfig(Name)
	if not self:Prepare() or typeof(delfile) ~= "function" or not isfile(self:Path(Name)) then
		return false
	end
	delfile(self:Path(Name))
	return true
end

function Zero:ListConfigs()
	local Out = {}
	if self:Prepare() and typeof(listfiles) == "function" then
		for _, Path in listfiles(self.Folder .. "/configs") do
			local Name = Path:match("([^/\\]+)%.json$")
			if Name then
				table.insert(Out, Name)
			end
		end
	end
	table.sort(Out)
	return Out
end

function Zero:SetAutoload(Name)
	if not self:Prepare() then
		return false
	end
	writefile(self.Folder .. "/autoload.txt", Name)
	return true
end

function Zero:Autoload()
	if not self:Prepare() or not isfile(self.Folder .. "/autoload.txt") then
		return
	end
	local Name = readfile(self.Folder .. "/autoload.txt")
	if Name ~= "" then
		self:LoadConfig(Name)
	end
end

local function BuildEsp()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")

	local LocalPlayer = Players.LocalPlayer
	local Camera = workspace.CurrentCamera

	local FONT_URL = "https://github.com/bluescan/proggyfonts/raw/master/ProggyOriginal/ProggyClean.ttf"
	local BIND_NAME = "EspUpdate"

	local Config = {
		Enabled = true,
		TeamCheck = false,
		MaxDistance = 2000,
		Box = true,
		BoxFill = true,
		Name = true,
		Health = true,
		Distance = true,
		Tool = true,
		Tracer = true,
		TextSize = 13,
		BoxColor = Color3.fromRGB(255, 255, 255),
		FillColor = Color3.fromRGB(120, 140, 255),
		TracerColor = Color3.fromRGB(255, 255, 255),
		NameColor = Color3.fromRGB(255, 255, 255),
		InfoColor = Color3.fromRGB(200, 200, 200),
		FillTransparency = 0.45
	}

	local function loadFont()
		local ok, result = pcall(function()
			if not (writefile and isfile and getcustomasset) then
				error("unsupported")
			end
			if not isfile("ProggyClean.ttf") then
				writefile("ProggyClean.ttf", game:HttpGet(FONT_URL))
			end
			writefile("ProggyFont.json", HttpService:JSONEncode({
				name = "Proggy",
				faces = {
					{
						name = "Regular",
						weight = 400,
						style = "normal",
						assetId = getcustomasset("ProggyClean.ttf")
					}
				}
			}))
			return Font.new(getcustomasset("ProggyFont.json"))
		end)
		if ok and result then
			return result
		end
		return Font.fromEnum(Enum.Font.Code)
	end

	local ProggyFont = loadFont()

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "EspGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 999

	local parentOk = pcall(function()
		ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not parentOk or not ScreenGui.Parent then
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local TOP_OFFSET = Vector3.new(0, 2.7, 0)
	local BOTTOM_OFFSET = Vector3.new(0, 3.1, 0)
	local BLACK = Color3.new(0, 0, 0)
	local HEALTH_LOW = Color3.fromRGB(255, 50, 50)
	local HEALTH_HIGH = Color3.fromRGB(90, 255, 90)

	local function setVisible(inst, value)
		if inst.Visible ~= value then
			inst.Visible = value
		end
	end

	local function setText(label, text)
		if label.Text ~= text then
			label.Text = text
		end
	end

	local function newFrame(parent)
		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.Parent = parent
		return frame
	end

	local function newStroke(frame, color)
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = 1
		stroke.LineJoinMode = Enum.LineJoinMode.Miter
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = frame
		return stroke
	end

	local function newLabel(parent)
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.FontFace = ProggyFont
		label.TextSize = Config.TextSize
		label.TextStrokeColor3 = BLACK
		label.TextStrokeTransparency = 0
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Size = UDim2.fromOffset(200, 14)
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Text = ""
		label.Visible = false
		label.Parent = parent
		return label
	end

	local Objects = {}

	local function createEsp(player)
		if Objects[player] then
			return
		end

		local holder = Instance.new("Folder")
		holder.Name = player.Name
		holder.Parent = ScreenGui

		local obj = {Holder = holder, Hidden = true, Frame = 0}

		obj.Fill = newFrame(holder)
		obj.Fill.BackgroundColor3 = Config.FillColor
		obj.Fill.BackgroundTransparency = Config.FillTransparency
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 0.85)
		})
		gradient.Parent = obj.Fill

		obj.Outer = newFrame(holder)
		newStroke(obj.Outer, BLACK)

		obj.Main = newFrame(holder)
		obj.MainStroke = newStroke(obj.Main, Config.BoxColor)

		obj.Inner = newFrame(holder)
		newStroke(obj.Inner, BLACK)

		obj.HealthBack = newFrame(holder)
		obj.HealthBack.BackgroundColor3 = BLACK
		obj.HealthBack.BackgroundTransparency = 0.2

		obj.HealthFill = newFrame(holder)
		obj.HealthFill.BackgroundTransparency = 0
		obj.HealthFill.AnchorPoint = Vector2.new(0, 1)

		obj.HealthText = newLabel(holder)
		obj.HealthText.Size = UDim2.fromOffset(30, 14)
		obj.HealthText.TextXAlignment = Enum.TextXAlignment.Right
		obj.HealthText.AnchorPoint = Vector2.new(1, 0.5)

		obj.Tracer = newFrame(holder)
		obj.Tracer.AnchorPoint = Vector2.new(0.5, 0.5)
		obj.Tracer.BackgroundTransparency = 0
		obj.Tracer.BackgroundColor3 = Config.TracerColor

		obj.Name = newLabel(holder)
		obj.Info = newLabel(holder)
		obj.ToolLabel = newLabel(holder)

		Objects[player] = obj
	end

	local function removeEsp(player)
		local obj = Objects[player]
		if obj then
			obj.Holder:Destroy()
			Objects[player] = nil
		end
	end

	local function hide(obj)
		if obj.Hidden then
			return
		end
		obj.Hidden = true
		obj.Outer.Visible = false
		obj.Main.Visible = false
		obj.Inner.Visible = false
		obj.Fill.Visible = false
		obj.HealthBack.Visible = false
		obj.HealthFill.Visible = false
		obj.HealthText.Visible = false
		obj.Tracer.Visible = false
		obj.Name.Visible = false
		obj.Info.Visible = false
		obj.ToolLabel.Visible = false
	end

	local function refreshCharacter(obj, player)
		local character = player.Character
		if character ~= obj.Character then
			obj.Character = character
			obj.Humanoid = character and character:FindFirstChildOfClass("Humanoid")
			obj.Root = character and character:FindFirstChild("HumanoidRootPart")
			obj.Tool = nil
		end
		if character and (not obj.Humanoid or not obj.Humanoid.Parent) then
			obj.Humanoid = character:FindFirstChildOfClass("Humanoid")
		end
		if character and (not obj.Root or not obj.Root.Parent) then
			obj.Root = character:FindFirstChild("HumanoidRootPart")
		end
	end

	local function update(player, obj, cameraPosition, viewport)
		if not Config.Enabled then
			hide(obj)
			return
		end

		if Config.TeamCheck and player.Team ~= nil and player.Team == LocalPlayer.Team then
			hide(obj)
			return
		end

		refreshCharacter(obj, player)

		local humanoid = obj.Humanoid
		local root = obj.Root

		if not humanoid or not root or humanoid.Health <= 0 then
			hide(obj)
			return
		end

		local rootPosition = root.Position
		local distance = (cameraPosition - rootPosition).Magnitude
		if distance > Config.MaxDistance then
			hide(obj)
			return
		end

		local topPos, topVisible = Camera:WorldToViewportPoint(rootPosition + TOP_OFFSET)
		if not topVisible or topPos.Z <= 0 then
			hide(obj)
			return
		end
		local bottomPos = Camera:WorldToViewportPoint(rootPosition - BOTTOM_OFFSET)

		obj.Hidden = false

		local height = math.abs(bottomPos.Y - topPos.Y)
		local centerX = topPos.X
		local w = math.floor(height * 0.56)
		local h = math.floor(height)
		local left = math.floor(centerX - w / 2)
		local top = math.floor(topPos.Y)
		local innerW = math.max(w - 2, 0)
		local innerH = math.max(h - 2, 0)

		local showBox = Config.Box
		setVisible(obj.Outer, showBox)
		setVisible(obj.Main, showBox)
		setVisible(obj.Inner, showBox)
		if showBox then
			obj.Outer.Position = UDim2.fromOffset(left - 1, top - 1)
			obj.Outer.Size = UDim2.fromOffset(w + 2, h + 2)
			obj.Main.Position = UDim2.fromOffset(left, top)
			obj.Main.Size = UDim2.fromOffset(w, h)
			obj.MainStroke.Color = Config.BoxColor
			obj.Inner.Position = UDim2.fromOffset(left + 1, top + 1)
			obj.Inner.Size = UDim2.fromOffset(innerW, innerH)
		end

		local showFill = showBox and Config.BoxFill
		setVisible(obj.Fill, showFill)
		if showFill then
			obj.Fill.Position = UDim2.fromOffset(left + 1, top + 1)
			obj.Fill.Size = UDim2.fromOffset(innerW, innerH)
			obj.Fill.BackgroundColor3 = Config.FillColor
			obj.Fill.BackgroundTransparency = Config.FillTransparency
		end

		local healthRatio = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		local healthColor = HEALTH_LOW:Lerp(HEALTH_HIGH, healthRatio)
		local fillHeight = math.max(math.floor(h * healthRatio), 1)

		local showHealth = Config.Health
		setVisible(obj.HealthBack, showHealth)
		setVisible(obj.HealthFill, showHealth)
		if showHealth then
			obj.HealthBack.Position = UDim2.fromOffset(left - 6, top - 1)
			obj.HealthBack.Size = UDim2.fromOffset(4, h + 2)
			obj.HealthFill.Position = UDim2.fromOffset(left - 5, top + h)
			obj.HealthFill.Size = UDim2.fromOffset(2, fillHeight)
			obj.HealthFill.BackgroundColor3 = healthColor
		end

		local showHealthText = showHealth and healthRatio < 1
		setVisible(obj.HealthText, showHealthText)
		if showHealthText then
			setText(obj.HealthText, tostring(math.floor(humanoid.Health)))
			obj.HealthText.TextColor3 = healthColor
			obj.HealthText.Position = UDim2.fromOffset(left - 8, top + h - fillHeight)
		end

		local showName = Config.Name
		setVisible(obj.Name, showName)
		if showName then
			setText(obj.Name, player.DisplayName)
			obj.Name.TextColor3 = Config.NameColor
			obj.Name.Position = UDim2.fromOffset(centerX, top - 9)
		end

		local offsetY = top + h + 8

		local showDistance = Config.Distance
		setVisible(obj.Info, showDistance)
		if showDistance then
			setText(obj.Info, math.floor(distance) .. "m")
			obj.Info.TextColor3 = Config.InfoColor
			obj.Info.Position = UDim2.fromOffset(centerX, offsetY)
			offsetY = offsetY + 11
		end

		obj.Frame = obj.Frame + 1
		if obj.Frame % 8 == 0 and obj.Character then
			obj.Tool = obj.Character:FindFirstChildOfClass("Tool")
		end

		local tool = obj.Tool
		local showTool = Config.Tool and tool ~= nil and tool.Parent == obj.Character
		setVisible(obj.ToolLabel, showTool)
		if showTool then
			setText(obj.ToolLabel, tool.Name)
			obj.ToolLabel.TextColor3 = Config.InfoColor
			obj.ToolLabel.Position = UDim2.fromOffset(centerX, offsetY)
		end

		local showTracer = Config.Tracer
		setVisible(obj.Tracer, showTracer)
		if showTracer then
			local fromX = viewport.X / 2
			local fromY = viewport.Y
			local toY = top + h
			local dx = centerX - fromX
			local dy = toY - fromY
			obj.Tracer.Position = UDim2.fromOffset(fromX + dx / 2, fromY + dy / 2)
			obj.Tracer.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 1)
			obj.Tracer.Rotation = math.deg(math.atan2(dy, dx))
			obj.Tracer.BackgroundColor3 = Config.TracerColor
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			createEsp(player)
		end
	end

	local addedConnection = Players.PlayerAdded:Connect(function(player)
		if player ~= LocalPlayer then
			createEsp(player)
		end
	end)

	local removingConnection = Players.PlayerRemoving:Connect(removeEsp)

	pcall(function()
		RunService:UnbindFromRenderStep(BIND_NAME)
	end)
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
		Camera = workspace.CurrentCamera
		if not Camera then
			return
		end
		local cameraPosition = Camera.CFrame.Position
		local viewport = Camera.ViewportSize
		for player, obj in pairs(Objects) do
			update(player, obj, cameraPosition, viewport)
		end
	end)

	local Esp = {Config = Config}

	function Esp.Unload()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
		RunService:UnbindFromRenderStep(BIND_NAME)
		for player in pairs(Objects) do
			removeEsp(player)
		end
		ScreenGui:Destroy()
	end

	return Esp
end

function Zero:Esp()
	if not self.EspCore then
		self.EspCore = BuildEsp()
		table.insert(self.UnloadHooks, self.EspCore.Unload)
	end
	return self.EspCore
end

local TeleportService = game:GetService("TeleportService")

local function Clock(Seconds)
	Seconds = math.floor(Seconds)
	return string.format("%02d:%02d:%02d", math.floor(Seconds / 3600), math.floor(Seconds / 60) % 60, Seconds % 60)
end

local function ExecutorName()
	local Ok, Name = pcall(function()
		return identifyexecutor()
	end)
	return Ok and Name or "unknown"
end

local function Copy(Text, Label)
	if typeof(setclipboard) == "function" then
		setclipboard(Text)
		Zero:Notify("Copied " .. Label, 2)
	else
		Zero:Notify("Clipboard not supported", 2)
	end
end

local function Hop()
	Zero:Notify("Searching for a server...", 3)
	local Target
	pcall(function()
		local Data = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
		for _, Server in Data.data do
			if Server.id ~= game.JobId and Server.playing < Server.maxPlayers then
				Target = Server.id
				break
			end
		end
	end)
	if Target then
		TeleportService:TeleportToPlaceInstance(game.PlaceId, Target, LocalPlayer)
	else
		Zero:Notify("No server found", 3)
	end
end

local Managers = {}

function Managers:HomeManager()
	local Started = os.clock()
	local Hidden = Zero.Anonymous
	local Account = self:Section("Profile", "Left")
	Account:Profile({ Tag = (Zero.Title or "Library") .. " user" })
	Account:Stat("User ID", Hidden and "hidden" or tostring(LocalPlayer.UserId))
	Account:Stat("Account age", Hidden and "hidden" or (LocalPlayer.AccountAge .. " days"))
	Account:Stat("Session", function()
		return Clock(os.clock() - Started)
	end)
	local Actions = self:Section("Actions", "Left")
	Actions:ButtonRow({
		{ "Rejoin", function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end },
		{ "Server hop", Hop },
	})
	Actions:ButtonRow({
		{ "Copy place id", function() Copy(tostring(game.PlaceId), "place id") end },
		{ "Copy job id", function() Copy(game.JobId, "job id") end },
	})
	local Server = self:Section("Server", "Right")
	Server:Stat("Game", function()
		return Zero.PlaceName
	end)
	Server:Stat("Place ID", tostring(game.PlaceId))
	Server:Stat("Job ID", game.JobId ~= "" and string.sub(game.JobId, 1, 8) or "n/a")
	Server:Stat("Players", function()
		return #Players:GetPlayers() .. " / " .. Players.MaxPlayers
	end)
	Server:Stat("Ping", function()
		local Ok, Value = pcall(function()
			return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		return (Ok and Value or 0) .. " ms"
	end)
	Server:Stat("FPS", function()
		return Zero.FPS .. " fps"
	end)
	Server:Stat("Server uptime", function()
		return Clock(workspace.DistributedGameTime)
	end)
	local About = self:Section("Library", "Right")
	About:Stat("Name", Zero.Title or "Library")
	About:Stat("Executor", ExecutorName())
	About:Stat("Configs saved", tostring(#Zero:ListConfigs()))
end

function Managers:EspManager()
	local Core = Zero:Esp()
	local function Option(Flag, Key, Default, Extra)
		Core.Config[Key] = Default
		local Result = {
			Default = Default,
			Flag = Flag,
			Callback = function(Value)
				Core.Config[Key] = Value
			end,
		}
		for Name, Value in Extra or {} do
			Result[Name] = Value
		end
		return Result
	end
	local function Colored(Toggle, Flag, Key, Default)
		return Toggle:Colorpicker(Default, Option(Flag, Key, Default))
	end
	local Main = self:Section("ESP", "Left")
	Main:Toggle("Enabled", Option("esp_enabled", "Enabled", false))
	Main:Toggle("Team check", Option("esp_team", "TeamCheck", false))
	Colored(Main:Toggle("Box", Option("esp_box", "Box", true)), "esp_box_color", "BoxColor", Color3.fromRGB(255, 255, 255))
	Colored(Main:Toggle("Box fill", Option("esp_fill", "BoxFill", true)), "esp_fill_color", "FillColor", Color3.fromRGB(120, 140, 255))
	Colored(Main:Toggle("Name", Option("esp_name", "Name", true)), "esp_name_color", "NameColor", Color3.fromRGB(255, 255, 255))
	Main:Toggle("Health bar", Option("esp_health", "Health", true))
	Colored(Main:Toggle("Distance", Option("esp_show_distance", "Distance", true)), "esp_info_color", "InfoColor", Color3.fromRGB(200, 200, 200))
	Main:Toggle("Tool", Option("esp_tool", "Tool", true))
	Colored(Main:Toggle("Tracer", Option("esp_tracer", "Tracer", true)), "esp_tracer_color", "TracerColor", Color3.fromRGB(255, 255, 255))
	local Tuning = self:Section("Settings", "Left")
	Tuning:Slider("Max distance", Option("esp_distance", "MaxDistance", 2000, { Min = 50, Max = 2000, Suffix = "m" }))
	Tuning:Slider("Fill transparency", Option("esp_fill_transparency", "FillTransparency", 0.45, { Min = 0, Max = 1, Increment = 0.05 }))
	self:Section("Preview", "Right"):EspPreview(240, Core.Config)
	return Core
end

function Managers:ConfigManager(Side)
	local Section = self:Section("Configs", Side or "Right")
	Section:ConfigManager()
	return Section
end

local function BuildPage(Parent)
	local State = { LeftCount = 0, RightCount = 0 }
	State.Page = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		BackgroundTransparency = 1,
		Parent = Parent,
	}, { ScrollBarImageColor3 = "Accent" })
	Pad(State.Page, 2)
	List(State.Page, 6, true)
	State.Left = New("Frame", { Size = UDim2.new(0.5, -3, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = State.Page })
	List(State.Left, 6)
	State.Right = New("Frame", { Size = UDim2.new(0.5, -3, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = State.Page })
	List(State.Right, 6)
	return State
end

local function AddSection(State, SectionName, Side)
	Side = Side or (State.LeftCount <= State.RightCount and "Left" or "Right")
	local Column = Side == "Right" and State.Right or State.Left
	if Side == "Right" then
		State.RightCount += 1
	else
		State.LeftCount += 1
	end
	local Frame = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = Column }, { BackgroundColor3 = "Panel" })
	Stroke(Frame, "Inline")
	Glow(Frame, 0.55, 0.35)
	local Body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = Frame })
	List(Body, 0)
	local Header = New("TextLabel", { Text = SectionName, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, TextXAlignment = Enum.TextXAlignment.Left, Parent = Body })
	Pad(Header, 6, 0)
	Fade(New("Frame", { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 2, Parent = Body }, { BackgroundColor3 = "Accent" }))
	local Content = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 3, Parent = Body })
	Pad(Content, 6)
	List(Content, 5)
	return setmetatable({ Content = Content, Scroll = State.Page }, Elements)
end

function Zero:Window(Opt)
	Opt = Opt or {}
	self.Title = Opt.Title or "Zero"
	self.Anonymous = Opt.Anonymous == true
	if type(Opt.ConfigFolder) == "string" and Opt.ConfigFolder ~= "" then
		self.Folder = Opt.ConfigFolder
	end
	self:Prepare()
	if Opt.Loadscreen ~= false then
		self:Loadscreen({ Title = self.Title, Duration = Opt.LoadDuration or 2.4 })
	end
	local Size = Opt.Size or Vector2.new(620, 430)
	local Bottom = Opt.TabPosition == "Bottom"
	local FooterH = 18
	local Outer, Inner = Bordered(self.Gui, { Size = UDim2.fromOffset(Size.X, Size.Y), ZIndex = 2, Visible = false }, "Background")
	Inner.ClipsDescendants = true
	Outer:SetAttribute("W", Size.X)
	Outer:SetAttribute("H", Size.Y)
	local Entry = { Frame = Outer, Moved = false, Center = true, Alpha = 0, Scale = New("UIScale", { Parent = Outer }) }
	table.insert(self.Windows, Entry)

	local Title = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = Inner })
	Glow(Title, 0.4, 1)
	New("TextLabel", { Text = Opt.Title or "Zero", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Title }, { TextColor3 = "DimText" })
	Fade(New("Frame", { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 1), Parent = Inner }, { BackgroundColor3 = "Accent" }))
	local Bar = Scroller({
		Position = Bottom and UDim2.new(0, 0, 1, -25 - FooterH) or UDim2.fromOffset(0, 21),
		Size = UDim2.new(1, 0, 0, 24),
		Parent = Inner,
	}, { BackgroundColor3 = "Panel" })
	List(Bar, 0, true)
	New("Frame", {
		Position = Bottom and UDim2.new(0, 0, 1, -26 - FooterH) or UDim2.fromOffset(0, 45),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = Inner,
	}, { BackgroundColor3 = "Inline" })
	local Pages = New("Frame", {
		Position = Bottom and UDim2.fromOffset(0, 21) or UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 1, -47 - FooterH),
		ClipsDescendants = true,
		BackgroundTransparency = 1,
		Parent = Inner,
	})
	Pad(Pages, 6)

	local Footer = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, FooterH),
		Parent = Inner,
	}, { BackgroundColor3 = "Panel" })
	Glow(Footer, 1, 0.45)
	New("Frame", { Size = UDim2.new(1, 0, 0, 1), Parent = Footer }, { BackgroundColor3 = "Inline" })
	local FooterDot = New("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 1), Size = UDim2.fromOffset(4, 4), Parent = Footer }, { BackgroundColor3 = "Accent" })
	Halo(FooterDot, 3, 0.55)
	local FooterLeft = New("TextLabel", { Text = Opt.Footer or Zero.Title, Position = UDim2.fromOffset(18, 1), Size = UDim2.new(0.5, -18, 1, -1), TextXAlignment = Enum.TextXAlignment.Left, Parent = Footer }, { TextColor3 = "DimText" })
	local FooterRight = New("TextLabel", { Position = UDim2.new(0.5, 0, 0, 1), Size = UDim2.new(0.5, -22, 1, -1), TextXAlignment = Enum.TextXAlignment.Right, Parent = Footer }, { TextColor3 = "DimText" })
	local function Stamp()
		FooterRight.Text = (Zero.Anonymous and "Anonymous" or LocalPlayer.DisplayName) .. "  |  " .. os.date("%H:%M")
	end
	Stamp()
	task.spawn(function()
		while FooterRight.Parent do
			task.wait(1)
			Stamp()
		end
	end)

	local IndicatorY = Bottom and UDim2.new(0, 0, 1, -25 - FooterH) or UDim2.fromOffset(0, 44)
	local Indicator = New("Frame", {
		Position = IndicatorY,
		Size = UDim2.new(0, 0, 0, 1),
		ZIndex = 3,
		Parent = Inner,
	}, { BackgroundColor3 = "Accent" })
	Fade(Indicator)
	Halo(Indicator, 6, 0.35)

	self:Dragify(Title, Entry)
	self:Resizer(Inner, Entry, 360, 260)
	Outer.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Zero:Raise(Outer)
		end
	end)

	local Window = { Frame = Outer, Tabs = {}, Moving = 0 }

	function Window:SetFooter(Text)
		FooterLeft.Text = Text
	end

	function Window:MoveIndicator(Tab, Instant)
		local Button = Tab.Button
		local Factor = Bar.AbsoluteSize.Y / 24
		local Position, Width
		if Factor > 0 and Button.AbsoluteSize.X > 0 then
			local Limit = Bar.AbsoluteSize.X / Factor
			local Raw = (Button.AbsolutePosition.X - Bar.AbsolutePosition.X) / Factor
			local Left = math.clamp(Raw, 0, Limit)
			local Right = math.clamp(Raw + Button.AbsoluteSize.X / Factor, 0, Limit)
			Position = UDim2.new(0, Left, IndicatorY.Y.Scale, IndicatorY.Y.Offset)
			Width = UDim2.new(0, Right - Left, 0, 1)
		else
			local Count = #Window.Tabs
			local Index = table.find(Window.Tabs, Tab) or 1
			Position = UDim2.new((Index - 1) / Count, 0, IndicatorY.Y.Scale, IndicatorY.Y.Offset)
			Width = UDim2.new(1 / Count, 0, 0, 1)
		end
		local Overflow = Bar.AbsoluteCanvasSize.X > Bar.AbsoluteSize.X + 1
		if Instant or Overflow then
			Window.Moving = 0
			Indicator.Position = Position
			Indicator.Size = Width
		else
			Window.Moving = os.clock() + 0.45
			Tween(Indicator, { Position = Position, Size = Width }, 0.45, Enum.EasingStyle.Quint)
		end
	end

	local function Snap()
		if Window.Active and os.clock() >= Window.Moving then
			Window:MoveIndicator(Window.Active, true)
		end
	end
	Bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(Snap)
	Bar:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(Snap)
	Bar:GetPropertyChangedSignal("CanvasPosition"):Connect(Snap)

	function Window:Select(Tab, Instant)
		local Previous = Window.Active
		if Previous == Tab then
			return
		end
		Window.Active = Tab
		for _, Other in Window.Tabs do
			Other.Update(Instant)
		end
		if Previous then
			Previous.Hide(Instant)
		end
		Tab.Show(Instant)
		if not Instant then
			Reveal(Bar, Tab.Button)
		end
		Window:MoveIndicator(Tab, Instant)
	end

	function Window:Tab(Name, Icon)
		local Tab = { Token = 0 }
		for Name, Method in Managers do
			Tab[Name] = Method
		end
		local Button = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = Bar }, { BackgroundColor3 = "Panel" })
		Floor(Button, 72)
		Button:GetPropertyChangedSignal("AbsoluteSize"):Connect(Snap)
		local TabGlow = Glow(Button, 0.25, 1)
		TabGlow.BackgroundTransparency = 1
		local Holder = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(0, 12),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = Button,
		})
		local Layout = List(Holder, 4, true)
		Layout.VerticalAlignment = Enum.VerticalAlignment.Center
		Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		local IconLabel = New("ImageLabel", { Size = UDim2.fromOffset(12, 12), LayoutOrder = 1, Parent = Holder }, { ImageColor3 = "DimText" })
		ApplyIcon(IconLabel, Icon)
		IconLabel.Visible = Icon ~= nil and IconLabel.Image ~= "rbxassetid://0"
		local Label = New("TextLabel", { Text = Name, Size = UDim2.fromOffset(0, 12), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = 2, Parent = Holder })

		local Group = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = Pages,
		})
		local Body = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = Group })
		local Main = BuildPage(Body)
		local SubBar
		local Subtabs = {}
		local Current

		Tab.Page = Main.Page
		Tab.Group = Group
		Tab.Button = Button

		function Tab.Update(Instant)
			local On = Window.Active == Tab
			local Time = Instant and 0 or 0.24
			Morph(Button, { BackgroundColor3 = On and Zero.Theme.Background or Zero.Theme.Panel }, Time)
			Morph(Label, { TextColor3 = On and Zero.Theme.Text or Zero.Theme.DimText }, Time)
			Morph(IconLabel, { ImageColor3 = On and Zero.Theme.Accent or Zero.Theme.DimText }, Time)
			Morph(TabGlow, { BackgroundTransparency = On and 0 or 1 }, Time)
		end
		table.insert(Zero.Refreshers, function()
			Tab.Update(true)
		end)

		function Tab.Show(Instant)
			Tab.Token += 1
			if Instant then
				Group.Visible = true
				Group.Position = UDim2.new()
				return
			end
			if not Group.Visible then
				Group.Position = UDim2.fromOffset(0, 8)
				Group.Visible = true
			end
			Tween(Group, { Position = UDim2.new() }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		end

		function Tab.Hide(Instant)
			Tab.Token += 1
			Group.Visible = false
		end

		Button.MouseEnter:Connect(function()
			if Window.Active ~= Tab then
				Tween(Label, { TextColor3 = Zero.Theme.DimText:Lerp(Zero.Theme.Text, 0.6) }, 0.15)
				Tween(IconLabel, { ImageColor3 = Zero.Theme.DimText:Lerp(Zero.Theme.Text, 0.6) }, 0.15)
			end
		end)
		Button.MouseLeave:Connect(function()
			if Window.Active ~= Tab then
				Tween(Label, { TextColor3 = Zero.Theme.DimText }, 0.2)
				Tween(IconLabel, { ImageColor3 = Zero.Theme.DimText }, 0.2)
			end
		end)

		function Tab:Section(SectionName, Side)
			return AddSection(Main, SectionName, Side)
		end

		function Tab:Subtab(SubName)
			if not SubBar then
				SubBar = Scroller({ Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0, 22), Parent = Group }, { BackgroundColor3 = "Panel" })
				Stroke(SubBar, "Inline")
				List(SubBar, 0, true)
				Body.Position = UDim2.fromOffset(0, 30)
				Body.Size = UDim2.new(1, 0, 1, -30)
				Main.Page.Visible = false
			end

			local Sub = {}
			for Name, Method in Managers do
				Sub[Name] = Method
			end
			local State = BuildPage(Body)
			State.Page.Visible = false
			local Hover = false
			local SubButton = New("TextButton", { Size = UDim2.fromScale(1, 1), Parent = SubBar }, { BackgroundColor3 = "Panel" })
			Floor(SubButton, 64)
			local SubGlow = Glow(SubButton, 0.25, 1)
			SubGlow.BackgroundTransparency = 1
			local SubLabel = New("TextLabel", { Text = SubName, Size = UDim2.fromScale(1, 1), Parent = SubButton })
			local SubLine = Fade(New("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 1, Parent = SubButton }, { BackgroundColor3 = "Accent" }))

			Sub.Page = State.Page
			Sub.Button = SubButton
			function Sub.Update(Instant)
				local On = Current == Sub
				local Time = Instant and 0 or 0.22
				local Idle = Hover and Zero.Theme.DimText:Lerp(Zero.Theme.Text, 0.6) or Zero.Theme.DimText
				Morph(SubButton, { BackgroundColor3 = On and Zero.Theme.Background or Zero.Theme.Panel }, Time)
				Morph(SubLabel, { TextColor3 = On and Zero.Theme.Text or Idle }, Time)
				Morph(SubGlow, { BackgroundTransparency = On and 0 or 1 }, Time)
				Morph(SubLine, { BackgroundTransparency = On and 0 or 1 }, Time)
			end
			table.insert(Zero.Refreshers, function()
				Sub.Update(true)
			end)

			local function Select(Instant)
				if Current == Sub then
					return
				end
				Current = Sub
				for _, Other in Subtabs do
					Other.Page.Visible = Other == Sub
					Other.Update(Instant)
				end
				if not Instant then
					Reveal(SubBar, SubButton)
				end
			end

			function Sub:Section(SectionName, Side)
				return AddSection(State, SectionName, Side)
			end

			table.insert(Subtabs, Sub)
			local Count = #Subtabs
			for _, Other in Subtabs do
				Other.Button.Size = UDim2.new(1 / Count, 0, 1, 0)
			end

			SubButton.MouseEnter:Connect(function()
				Hover = true
				if Current ~= Sub then
					Sub.Update()
				end
			end)
			SubButton.MouseLeave:Connect(function()
				Hover = false
				if Current ~= Sub then
					Sub.Update()
				end
			end)
			SubButton.Activated:Connect(function()
				Zero:ClosePopup()
				Select()
			end)

			if Count == 1 then
				Select(true)
			else
				Sub.Update(true)
			end
			return Sub
		end

		table.insert(Window.Tabs, Tab)
		local Count = #Window.Tabs
		for _, Other in Window.Tabs do
			Other.Button.Size = UDim2.new(1 / Count, 0, 1, 0)
		end
		Button.Activated:Connect(function()
			Zero:ClosePopup()
			Window:Select(Tab)
		end)
		if Count == 1 then
			Window:Select(Tab, true)
		else
			Tab.Update(true)
			Window:MoveIndicator(Window.Active, true)
		end
		return Tab
	end

	self:Clamp(Entry, true)
	if self.Visible then
		self:Present(Entry, true)
	else
		Outer.Visible = false
	end
	return Window
end

function Zero:Panel(Opt)
	Opt = Opt or {}
	local Size = Opt.Size or Vector2.new(180, 220)
	local Position = Opt.Position or Vector2.new(40, 60)
	local Outer, Inner = Bordered(self.Gui, { Size = UDim2.fromOffset(Size.X, Size.Y), Position = UDim2.fromOffset(Position.X, Position.Y), ZIndex = 2, Visible = false }, "Background")
	Inner.ClipsDescendants = true
	Outer:SetAttribute("W", Size.X)
	Outer:SetAttribute("H", Size.Y)
	local Entry = { Frame = Outer, Moved = true, Center = false, Alpha = 0, Scale = New("UIScale", { Parent = Outer }) }
	table.insert(self.Windows, Entry)

	local Title = New("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = Inner })
	Glow(Title, 0.4, 1)
	New("TextLabel", { Text = Opt.Title or "panel", Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Title }, { TextColor3 = "DimText" })
	Fade(New("Frame", { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 1), Parent = Inner }, { BackgroundColor3 = "Accent" }))
	local Scroll = New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 21),
		Size = UDim2.new(1, 0, 1, -21),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		BackgroundTransparency = 1,
		Parent = Inner,
	}, { ScrollBarImageColor3 = "Accent" })
	Pad(Scroll, 6)
	List(Scroll, 5)

	self:Dragify(Title, Entry)
	self:Resizer(Inner, Entry, 140, 90)
	Outer.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Zero:Raise(Outer)
		end
	end)
	self:Clamp(Entry)
	if self.Visible then
		self:Present(Entry, true, 0.08)
	end
	return setmetatable({ Content = Scroll, Scroll = Scroll, Frame = Outer }, Elements)
end

function Zero:Watermark(Text)
	local Outer, Inner = Bordered(self.Gui, { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(120, 20), ZIndex = 60 }, "Background")
	Fade(New("Frame", { Size = UDim2.new(1, 0, 0, 1), Parent = Inner }, { BackgroundColor3 = "Accent" }))
	local Label = New("TextLabel", { Size = UDim2.fromScale(1, 1), Parent = Inner })
	local Frames, Last, FPS = 0, os.clock(), 60
	local Ready = false
	local function Update()
		local Ping = 0
		pcall(function()
			Ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		local Line = string.format("%s | %d fps | %d ms", Text, FPS, Ping)
		Label.Text = Line
		local Goal = UDim2.fromOffset(TextWidth(Line) + 18, 20)
		if Ready then
			Tween(Outer, { Size = Goal }, 0.3, Enum.EasingStyle.Quint)
		else
			Outer.Size = Goal
		end
	end
	Update()
	Ready = true
	Connect(RunService.RenderStepped, function()
		Frames += 1
		local Now = os.clock()
		if Now - Last >= 0.5 then
			FPS = math.floor(Frames / (Now - Last) + 0.5)
			Frames = 0
			Last = Now
			Update()
		end
	end)
	return Outer
end

Zero.Notes = New("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 60,
	Parent = Gui,
})
local NotesPad = Pad(Zero.Notes, 12)
local NotesList = List(Zero.Notes, 4)

Zero.NotifyPositions = { "Top Left", "Top Center", "Top Right", "Middle Left", "Middle Center", "Middle Right", "Bottom Left", "Bottom Center", "Bottom Right" }
Zero.NotifyPosition = "Top Left"

function Zero:SetNotifyPosition(Name)
	if not table.find(self.NotifyPositions, Name) then
		return
	end
	self.NotifyPosition = Name
	local Vertical, Horizontal = Name:match("^(%a+) (%a+)$")
	NotesList.VerticalAlignment = Enum.VerticalAlignment[Vertical == "Middle" and "Center" or Vertical]
	NotesList.HorizontalAlignment = Enum.HorizontalAlignment[Horizontal]
	local Corner = Name == "Top Left"
	NotesPad.PaddingLeft = UDim.new(0, Corner and 42 or 12)
	NotesPad.PaddingTop = UDim.new(0, Corner and 36 or 12)
	NotesPad.PaddingRight = UDim.new(0, 12)
	NotesPad.PaddingBottom = UDim.new(0, 12)
end
Zero:SetNotifyPosition("Top Left")

function Zero:Notify(Text, Time)
	Time = Time or 3
	local Width = TextWidth(Text) + 18
	local Wrap = New("Frame", { Size = UDim2.fromOffset(Width, 20), BackgroundTransparency = 1, Parent = self.Notes })
	local OffX, OffY = -28, 0
	local Horizontal = self.NotifyPosition:match("%a+ (%a+)")
	if Horizontal == "Right" then
		OffX = 28
	elseif Horizontal == "Center" then
		OffX, OffY = 0, self.NotifyPosition:find("Bottom") and 14 or -14
	end
	local Start = UDim2.fromOffset(OffX, OffY)
	local Outer, Inner = Bordered(Wrap, { Size = UDim2.fromScale(1, 1), Position = Start }, "Background", "CanvasGroup")
	Outer.GroupTransparency = 1
	New("Frame", { Size = UDim2.new(0, 2, 1, 0), Parent = Inner }, { BackgroundColor3 = "Accent" })
	New("TextLabel", { Text = Text, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -8, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Inner })
	local Progress = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundTransparency = 0.35,
		Parent = Inner,
	}, { BackgroundColor3 = "Accent" })
	Tween(Outer, { Position = UDim2.new(), GroupTransparency = 0 }, 0.5, Enum.EasingStyle.Quint)
	Tween(Progress, { Size = UDim2.new(0, 0, 0, 1) }, Time, Enum.EasingStyle.Linear)
	task.delay(Time, function()
		if not Wrap.Parent then
			return
		end
		local Out = Tween(Outer, { Position = Start, GroupTransparency = 1 }, 0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		Out.Completed:Connect(function()
			if not Wrap.Parent then
				return
			end
			local Collapse = Tween(Wrap, { Size = UDim2.fromOffset(Width, 0) }, 0.22, Enum.EasingStyle.Quad)
			Collapse.Completed:Connect(function()
				Wrap:Destroy()
			end)
		end)
	end)
end

do
	local Outer, Inner = Bordered(Gui, { Position = UDim2.fromOffset(10, 36), Size = UDim2.fromOffset(26, 26), ZIndex = 60 }, "Background")
	local Text = New("TextLabel", { Text = "Z", TextSize = 14, Size = UDim2.fromScale(1, 1), Parent = Inner }, { TextColor3 = "Accent" })
	local Icon = New("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Parent = Inner }, { ImageColor3 = "Accent" })
	ApplyIcon(Icon, "layout-grid")
	if Icon.Image == "rbxassetid://0" or Icon.Image == "" then
		Icon.Visible = false
	else
		Text.Visible = false
	end
	local Spin = 0
	local Origin, Moved = nil, 0
	Track(Inner, function()
		Origin = Outer.Position
		Moved = 0
	end, function(Delta)
		Moved = math.max(Moved, Delta.Magnitude)
		Outer.Position = UDim2.fromOffset(math.floor(Origin.X.Offset + Delta.X), math.floor(Origin.Y.Offset + Delta.Y))
	end, function()
		if Moved < 4 then
			Zero:SetVisible(not Zero.Visible)
			Spin += 90
			local Color = Zero.Visible and Zero.Theme.Accent or Zero.Theme.DimText
			Tween(Icon, { Rotation = Spin, ImageColor3 = Color }, 0.5, Enum.EasingStyle.Quint)
			Tween(Text, { TextColor3 = Color }, 0.3)
		end
	end)
end

function Zero:Loadscreen(Opt)
	Opt = Opt or {}
	local Steps = Opt.Steps or { "initializing", "loading font", "building interface", "loading configs", "ready" }
	local Duration = Opt.Duration or 2.4
	local Screen = Instance.new("ScreenGui")
	Screen.Name = HttpService:GenerateGUID(false)
	Screen.ResetOnSpawn = false
	Screen.IgnoreGuiInset = true
	Screen.DisplayOrder = 1000
	Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if typeof(syn) == "table" and syn.protect_gui then
		pcall(syn.protect_gui, Screen)
	end
	Screen.Parent = self.Gui.Parent
	local Group = New("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Active = true,
		ZIndex = 200,
		Parent = Screen,
	})
	New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, Parent = Group })
	local Outer, Inner = Bordered(Group, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 128) }, "Background")
	local Base = self.Scale
	local CardScale = New("UIScale", { Scale = 0.88 * Base, Parent = Outer })

	local Head = New("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Parent = Inner })
	Glow(Head, 0.4, 1)
	New("TextLabel", { Text = Opt.Title or "Zero", Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -60, 0, 20), TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left, Parent = Inner }, { TextColor3 = "Text" })
	New("TextLabel", { Text = Opt.Subtitle or "loading interface", Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -60, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = Inner }, { TextColor3 = "DimText" })
	Fade(New("Frame", { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 0, 1), Parent = Inner }, { BackgroundColor3 = "Accent" }))

	local Dots = {}
	for Index = 1, 3 do
		Dots[Index] = New("Frame", {
			Position = UDim2.new(1, -16 + (Index - 3) * 8, 0, 18),
			Size = UDim2.fromOffset(4, 4),
			Parent = Inner,
		}, { BackgroundColor3 = "Accent" })
	end

	local Status = New("TextLabel", { Text = Steps[1], Position = UDim2.fromOffset(12, 62), Size = UDim2.new(1, -70, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = Inner }, { TextColor3 = "DimText" })
	local Percent = New("TextLabel", { Text = "0%", Position = UDim2.new(1, -58, 0, 62), Size = UDim2.fromOffset(46, 12), TextXAlignment = Enum.TextXAlignment.Right, Parent = Inner }, { TextColor3 = "Text" })
	local Bar = New("Frame", { Position = UDim2.fromOffset(12, 80), Size = UDim2.new(1, -24, 0, 8), Parent = Inner }, { BackgroundColor3 = "Field" })
	Stroke(Bar, "Inline")
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = Bar }, { BackgroundColor3 = "Accent" })
	Halo(Fill, 4, 0.5)
	New("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 152, 172)), Rotation = 90, Parent = Fill })
	local Clip = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = Fill })
	local Shine = New("Frame", { Size = UDim2.fromScale(0.4, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = Clip })
	New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Shine,
	})

	New("Frame", { Position = UDim2.fromOffset(0, 98), Size = UDim2.new(1, 0, 0, 1), Parent = Inner }, { BackgroundColor3 = "Inline" })
	New("TextLabel", { Text = Opt.Footer or LocalPlayer.DisplayName, Position = UDim2.fromOffset(12, 104), Size = UDim2.new(0.6, -12, 0, 12), TextXAlignment = Enum.TextXAlignment.Left, Parent = Inner }, { TextColor3 = "DimText" })
	New("TextLabel", { Text = Opt.Version or "1.0", Position = UDim2.new(0.6, 0, 0, 104), Size = UDim2.new(0.4, -12, 0, 12), TextXAlignment = Enum.TextXAlignment.Right, Parent = Inner }, { TextColor3 = "DimText" })

	local Alive
	Alive = RunService.RenderStepped:Connect(function()
		if not Group.Parent then
			Alive:Disconnect()
			return
		end
		local Now = os.clock()
		for Index, Dot in Dots do
			local Wave = (math.sin(Now * 5 - Index * 1.1) + 1) / 2
			Dot.BackgroundTransparency = 1 - (0.2 + 0.8 * Wave)
		end
		Shine.Position = UDim2.fromScale((Now * 0.9) % 1.6 - 0.4, 0)
	end)

	local Object = { Closed = false }
	function Object:Set(Alpha, Text)
		Alpha = math.clamp(Alpha, 0, 1)
		Fill.Size = UDim2.fromScale(Alpha, 1)
		Percent.Text = math.floor(Alpha * 100) .. "%"
		if Text then
			Status.Text = Text
		end
	end
	function Object:Finish()
		if Object.Closed then
			return
		end
		Object.Closed = true
		Object:Set(1, Steps[#Steps])
		task.delay(0.3, function()
			Tween(CardScale, { Scale = 1.06 * Base }, 0.5, Enum.EasingStyle.Quad)
			local Out = Tween(Group, { GroupTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
			Out.Completed:Connect(function()
				Alive:Disconnect()
				Screen:Destroy()
				if Opt.Callback then
					task.spawn(Opt.Callback)
				end
			end)
		end)
	end

	Tween(Group, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)
	Tween(CardScale, { Scale = Base }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	if Opt.Duration ~= false then
		task.spawn(function()
			local Start = os.clock()
			repeat
				local Time = math.clamp((os.clock() - Start) / Duration, 0, 1)
				local Index = math.clamp(math.floor(Time * (#Steps - 1)) + 1, 1, #Steps)
				Object:Set(math.sin(Time * math.pi / 2), Steps[Index])
				task.wait()
			until Time >= 1 or Object.Closed
			Object:Finish()
		end)
	end
	return Object
end

function Zero:Unload()
	self:ClosePopup()
	for _, Hook in self.UnloadHooks do
		pcall(Hook)
	end
	for _, Connection in self.Connections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
	Gui:Destroy()
	table.clear(self.Options)
	table.clear(self.Flags)
end

return Zero
