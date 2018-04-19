```lua
-- UserInputService wrapper
-- @readme https://github.com/RoStrap/Input/blob/master/README.md
-- @author Narrev
-- @original ScriptGuider

-- Services
local GetService = game.GetService
local InputService = GetService(game, "UserInputService")
local RunService = GetService(game, "RunService")
local StarterGui = GetService(game, "StarterGui")
local Players = GetService(game, "Players")

-- Optimize
local GetKeysPressed = InputService.GetKeysPressed
local Connect = InputService.InputBegan.Connect
local Heartbeat = RunService.Heartbeat
local Wait = Heartbeat.Wait
local SetCore = StarterGui.SetCore
local Destroy = game.Destroy
local GetChildren = game.GetChildren

local sub = string.sub
local time = os.time
local find = string.find
local remove = table.remove
local newInstance = Instance.new
local type, select, setmetatable, rawset, tostring, tick = type, select, setmetatable, rawset, tostring, tick

local Fire, Disconnect do
	local Bindable = newInstance("BindableEvent")
	local Connection = Connect(Bindable.Event, function() end)
	Fire, Disconnect = Bindable.Fire, Connection.Disconnect
	Disconnect(Connection)
	Destroy(Bindable)
end

-- Client
local Player repeat Player = Players.LocalPlayer until Player or not wait()
local PlayerGui = Player:WaitForChild("PlayerGui")
local PlayerMouse = Player:GetMouse()

local function DisconnectConnector(self)
	self.Signal.Main = nil
end

local Disconnector = {Disconnect = DisconnectConnector}
Disconnector.__index = Disconnector

local function ConnectSignal(self, func)
	-- Bind first function to this thread
	-- Bind additional functions to bindable

	if self.Main then
		local Bindable = self.Bindable
		if Bindable then
			local Connections = self.Connections
			local Connection = Connect(Bindable.Event, func)
			if Connections then
				Connections[#Connections + 1] = Connection
			else
				self.Connections = {Connection}
			end
			return Connection
		else
			local Bindable = newInstance("BindableEvent")
			self.Bindable = Bindable
			local Connection = Connect(Bindable.Event, func)
			self.Connections = {Connection}
			return Connection
		end
	else
		self.Main = func
		return setmetatable({Signal = self}, Disconnector)
	end
end

local function DisconnectSignal(self)
	self.Main = nil
	local Connections = self.Connections
	if Connections then
		for a = 1, #Connections do
			Disconnect(Connections[a])
		end
		self.Connections = nil
	end
end

local function WaitSignal(self)
	local Bindable = self.Bindable
	if Bindable then
		Wait(Bindable.Event)
	else
		Bindable = newInstance("BindableEvent")
		self.Bindable = Bindable
		Wait(Bindable.Event)
		if not self.Connections then
			self.Bindable = Destroy(Bindable)
		end
	end
end

local function FireSignal(self)
	local Main, Bindable = self.Main, self.Bindable
	if Bindable then
		Fire(Bindable)
	end
	if Main then
		Main()
	end
end

local Signal = {
	Wait = WaitSignal;
	Fire = FireSignal;
	Press = FireSignal;
	Connect = ConnectSignal;
	Disconnect = DisconnectSignal;
}

local function newSignal(KeyCode)
	return setmetatable({KeyCode = KeyCode}, Signal)
end

local function AddSignals(a, b) -- This looks way scarier than it is
	a, b = a.KeyDown or a, b.KeyDown or b
	local KeyCodes, Combination, NumberOfKeyCodes = a.KeyCode
	local KeyCodeIsTable = type(KeyCodes) == "table"

	if KeyCodeIsTable then
		Combination = {}
		NumberOfKeyCodes = #KeyCodes
		for a = 1, NumberOfKeyCodes do
			Combination[a] = KeyCodes[a]
		end
		Combination[NumberOfKeyCodes + 1] = b.KeyCode
	else
		Combination = {KeyCodes, b.KeyCode}
	end

	Combination = newSignal(Combination)
	ConnectSignal(b, function()
--		if #Combination > 0 then -- Save on gas mileage
			local KeysPressed = GetKeysPressed(InputService)
			local NumberOfKeysPressed = #KeysPressed
			local AllButtonsArePressed = true

			if KeyCodeIsTable then
				for c = 1, NumberOfKeyCodes do
					if AllButtonsArePressed then
						AllButtonsArePressed = false
						local KeyCode = KeyCodes[c]
						for d = 1, NumberOfKeysPressed do
							if KeysPressed[d].KeyCode == KeyCode then
								AllButtonsArePressed = true
								break
							end
						end
					else break
					end
				end
			else
				AllButtonsArePressed = false
				for e = 1, NumberOfKeysPressed do
					if KeysPressed[e].KeyCode == KeyCodes then
						AllButtonsArePressed = true
						break
					end
				end
			end

			if AllButtonsArePressed then
				FireSignal(Combination)
			end
--		end
	end)

	return Combination
end
Signal.__add = AddSignals
Signal.__index = Signal

-- Library & Input
local RegisteredKeys = {}
local Keys  = {}
local Mouse = {__newindex = PlayerMouse}
local Key = {__add = AddSignals}

function Key:__index(i)
	-- Make KeyDown the default if they don't put `.KeyDown`
	local KeyDown = self.KeyDown
	local Method = KeyDown[i]
	local function Wrap(_, a)
		return Method(KeyDown, a)
	end
	self[i] = Wrap
	return Wrap
end

function Keys:__index(v)
	assert(type(v) == "string", "Table Keys should be indexed by a string")
	local Connections = setmetatable({
		KeyUp = newSignal(Enum.KeyCode[v]);
		KeyDown = newSignal(Enum.KeyCode[v]);
	}, Key)
	RegisteredKeys[v] = Connections
	self[v] = Connections
	return Connections
end

function Mouse:__index(v)
	local Event = newSignal()
	rawset(self, v, Event)

	if v == "DoubleButton1Up" then
		local LastClicked = 0
		Connect(PlayerMouse.Button1Up, function()
			local ClickedTime = tick()
			if ClickedTime - LastClicked < 0.5 then
				FireSignal(Event)
				LastClicked = 0
			else
				LastClicked = ClickedTime
			end
		end)
	elseif v == "DoubleButton2Up" then
		local LastClicked = 0
		Connect(PlayerMouse.Button2Up, function()
			local ClickedTime = tick()
			if ClickedTime - LastClicked < 0.5 then
				FireSignal(Event)
				LastClicked = 0
			else
				LastClicked = ClickedTime
			end
		end)
	--[[ No use yet
	elseif v == "HoldButton1" or v == "HoldButton1Down" then
		local ConnectSignal = Event.Connect
		Event.Connect = function(a, b, c)
			ConnectSignal(a, b)
			local Duration = c or 1
			local Held = -1
			local MainConnection

			local function Down()
				local HeldSave = Held + 1
				Held = HeldSave

				FireSignal(Event)
				while wait(Duration) and Held == HeldSave do
					FireSignal(Event)
				end
			end

			local function Up()
				Held = Held + 1
				Disconnect(MainConnection)
				MainConnection = Connect(PlayerMouse.Button1Down, Down)
			end

			MainConnection = Connect(PlayerMouse.Button1Down, Down)
			Connect(PlayerMouse.Button1Up, Up)
		end
	elseif v == "HoldButton2" or v == "HoldButton2Down" then
		local ConnectSignal = Event.Connect
		Event.Connect = function(a, b, c)
			ConnectSignal(a, b)
			local Duration = c or 1
			local Held = -1
			local MainConnection

			local function Down()
				local HeldSave = Held + 1
				Held = HeldSave

				FireSignal(Event)
				while wait(Duration) and Held == HeldSave do
					FireSignal(Event)
				end
			end

			local function Up()
				Held = Held + 1
				Disconnect(MainConnection)
				MainConnection = Connect(PlayerMouse.Button2Down, Down)
			end

			MainConnection = Connect(PlayerMouse.Button2Down, Down)
			Connect(PlayerMouse.Button2Up, Up)
		end]]
	else
		local Mickey = PlayerMouse[v]
		if typeof(Mickey) == "RBXScriptSignal" then
			Connect(Mickey, function()
				FireSignal(Event)
			end)
		end
		return Mickey
	end
	return Event
end

local Enabled = false
local TimeAbsent = time() + 10
local WelcomeBack = newSignal()
local PlayerGuiBackup = Player:FindFirstChild("PlayerGuiBackup")
local NameDisplayDistance = Player.NameDisplayDistance
local HealthDisplayDistance = Player.HealthDisplayDistance

if not PlayerGuiBackup then
	PlayerGuiBackup = newInstance("Folder", Player)
	PlayerGuiBackup.Name = "GuiBackup"
end

local Input = {
	AbsentThreshold = 14;
	CreateEvent = newSignal; -- Create a new event signal
	WelcomeBack = WelcomeBack;
	__newindex = InputService;
	Keys = setmetatable(Keys, Keys);
	Mouse = setmetatable(Mouse, Mouse);
}

function Input:__index(i)
	local Variable = InputService[i]
	if type(Variable) == "function" then
		local func = Variable
		function Variable(...) -- We need to wrap functions to mimic ":" syntax
			return func(InputService, select(2, ...))
		end
		rawset(self, i, Variable)
	end
	return Variable
end

-- Connections
Connect(InputService.InputBegan, function(KeyName, GuiInput)
	if not GuiInput then
		local RegisteredKey = RegisteredKeys[KeyName.KeyCode.Name]
		if RegisteredKey then
			FireSignal(RegisteredKey.KeyDown)
		end
	end
end)

Connect(InputService.InputEnded, function(KeyName, GuiInput)
	if not GuiInput then
		local RegisteredKey = RegisteredKeys[KeyName.KeyCode.Name]
		if RegisteredKey then
			FireSignal(RegisteredKey.KeyUp)
		end
	end
end)

Connect(InputService.WindowFocusReleased, function()
	TimeAbsent = time()
end)

Connect(InputService.WindowFocused, function()
	if time() - TimeAbsent > Input.AbsentThreshold then
		FireSignal(WelcomeBack, TimeAbsent)
	end
end)

local PlayerGuiChildren
ConnectSignal(Keys.Minus.KeyDown, function()
	if not Enabled then
		Enabled = true
		InputService.MouseIconEnabled = false
		SetCore(StarterGui, "TopbarEnabled", false)
		Player.HealthDisplayDistance = 0
		Player.NameDisplayDistance = 0
		local Guis = GetChildren(PlayerGui)
		PlayerGuiChildren = Guis
		for a = 1, #Guis do
			local Gui = Guis[a]
			if Gui.ClassName == "ScreenGui" then
				Gui.Parent = PlayerGuiBackup
			end
		end
	else
		Enabled = false
		InputService.MouseIconEnabled = true
		SetCore(StarterGui, "TopbarEnabled", true)
		Player.HealthDisplayDistance = HealthDisplayDistance
		Player.NameDisplayDistance = NameDisplayDistance
		for a = 1, #PlayerGuiChildren do
			PlayerGuiChildren[a].Parent = PlayerGui
		end
	end
end)

return setmetatable(Input, Input)
```

Documentation:
# UserInputService
This module is table wrapper designed to simplify dealing with user input. This module allows you to connect functions to certain events without the need to actually call the `UserInputService`, or compare any Enum codes to input objects. This is both faster to reference, and considerably more readable to the writer.

This module also allows Users to enter `Screenshot Mode` by pressing `-`. Internally, this temporarily moves all ScreenGui in PlayerGui to a Folder in `LocalPlayer` called `GuiBackup`, as well as disabling the TopBar, which in turn temporarily disables the Chat, Backpack, et cetera.

Note: As a wrapper, no functionality is removed from UserInputService. All of UserInputService's built-in properties, functions, and events are still accessible through this module. Access Roblox's full [UserInputService documentation by clicking here](http://wiki.roblox.com/?title=API:Class/UserInputService).
## API
```javascript
class UserInputService
	Properties

		table/PlayerMouse Mouse
//			returns the LocalPlayer's Mouse with added API (demonstrated below)

		table Keys
//			Similar to Mouse; you can access Keys from this table

		number AbsentThreshold = 14

		Event WelcomeBack(int TimeAbsent)
//			Event fired when a Player reopens the Roblox Window after closing it for more than @param AbsentThreshold seconds
```
## Key events
Key events are stored inside a table called "Keys", which you can access directly
from the module. Once you've accessed this table, you can index it for any input type that exists in the KeyCode Enum element. For example, if you wanted to create an event for the key "Q", you'd simply index it:
```lua
local UserInputService = require(UserInputServiceModule)
local Keys = UserInputService.Keys
local Q = Keys.Q.KeyDown
local E = Keys.E.KeyUp
local R = Keys.R -- Abbreviated form of Keys.R.KeyDown

local QPress = Q:Connect(function()
	print("Q was pressed")
end)

-- Manual Fire
Q:Press() -- Same as Q:Fire()
Q:Fire()

Q:Disconnect() -- disconnect everything binded to Q.KeyDown
QPress:Disconnect() -- disconnect one connection

-- Wait until the player KeyDown's Q
Q:Wait()
```
Each key has a "KeyUp" and "KeyDown" event that comes with it. If you don't specify, it will default to KeyDown.

Note: KeyUp and KeyDown events are unrelated (except by Name) to the deprecated methods of PlayerMouse.

### Chaining events
You can also chain events using the `+` operator. Be careful when using this in Studio though, as your operating system shortcuts take precedence over Roblox.
```lua
local Keys = UserInputService.Keys
local L = Keys.L.KeyDown
local F = Keys.F -- Defaults to KeyDown
local R = Keys.R

local MenuSelect = (L + F + R):Connect(function()
	print("User pressed L + F + R")
end)
```

Note: The Chained Event fires when you press the last key in a Chain. If the other keys are being held down the event fires.

Note: `Keys["KeyName"]` can be used as an abbreviation for `Keys["KeyName"].KeyDown`. Example given in code above with variable declaration `R`

## Mouse events
Mouse events remain the same as just creating them normally on the PlayerMouse object. For example, creating a Button1Down event would be done like so:

```lua
local UserInputService = require(UserInputServiceModule)
local Mouse = UserInputService.Mouse
local Button1Down = Mouse.Button1Down

local LeftClick = Button1Down:Connect(function()
	print("Button was clicked")
end)

-- And of course you could fire it manually, since it returns a custom event
Button1Down:Fire()

Button1Down:Disconnect() -- Disconnect all connections binded to this event
LeftClick:Disconnect() -- Disconnect the one connection

Button1Down:Wait() -- Wait for the Event to happen
```

Some added functionality is the ability to put `Double` before any PlayerMouse Event Name to detect double clicks.
```lua
local UserInputService = require(UserInputServiceModule)
local Mouse = UserInputService.Mouse
local DoubleClick = Mouse.DoubleButton1Up -- Fires when DoubleButton1Up is Fired twice within 0.5 seconds

DoubleClick:Connect(function()
	print("DoubleClick detected")
end)
```

## WelcomeBack Event
Fires when a player closes the Roblox window and then reopens it after more seconds than number `UserInputService.AbsentThreshold (default = 14)`
```lua
local UserInputService = require(UserInputServiceModule)
UserInputService.WelcomeBack:Connect(function(TimeAbsent)
	print("You were AFK for", TimeAbsent, "seconds.")
end)
```

