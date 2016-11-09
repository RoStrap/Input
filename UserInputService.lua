-- @author Narrev
-- @original ScriptGuider
-- UserInputService wrapper

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
local GetChildren = game.GetChildren

local sub = string.sub
local time = os.time
local find = string.find
local remove = table.remove
local newInstance = Instance.new
local type, select, setmetatable, rawset, tostring, tick = type, select, setmetatable, rawset, tostring, tick

-- Client
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PlayerMouse = Player:GetMouse()

local function DisconnectConnector(self)
	local func = self.func
	local Connections = self.Connections
	for a = 1, #Connections do
		if Connections[a] == func then
			remove(Connections, a)
		end
	end
end

local Disconnector = {Disconnect = DisconnectConnector}
Disconnector.__index = Disconnector

local function ConnectSignal(self, func)
	if func then
		local Connections = self.Connections
		Connections[#Connections + 1] = func
		return setmetatable({Connections = Connections; func = func}, Disconnector)
	end
end

local function DisconnectSignal(self)
	local Connections = self.Connections
	for a = 1, #Connections do
		Connections[a] = nil
	end
end

local function WaitSignal(self)
	local Connection
	Connection = ConnectSignal(self, function()
		Connection = DisconnectConnector(Connection)
	end)
	repeat until not Connection or not Wait(Heartbeat)
end

local function FireSignal(self, ...)
	local Connections = self.Connections
	for a = 1, #Connections do
		Connections[a](...)
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
	return setmetatable({Connections = {}; KeyCode = KeyCode}, Signal)
end

local function AddSignals(a, b) -- This looks way scarier than it is
	local KeyCodes, Combination = a.KeyCode
	local KeyCodeIsTable = type(KeyCodes) == "table"
	local NumberOfKeyCodes

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
	local Combos = Combination.Connections

	Combination.InternalConnection = b:Connect(function()
		if #Combos > 0 then -- Save on gas mileage
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
		end
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
	return self.KeyDown[i]
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
	if type(v) == "string" then
		local Stored = newSignal()
		rawset(self, v, Stored)
		if find(v, "^Double") then
			local LastClicked = 0
			Connect(PlayerMouse[sub(v, 7)], function()
				local ClickedTime = tick()
				if ClickedTime - LastClicked < 0.5 then
					FireSignal(Stored, PlayerMouse)
					LastClicked = 0
				else
					LastClicked = ClickedTime
				end
			end)
		else
			local Mickey = PlayerMouse[v]
			if find(tostring(Mickey), "Signal") then
				Connect(Mickey, function()
					FireSignal(Stored, PlayerMouse)
				end)
			end
		end
		return Stored
	else
		return PlayerMouse[v]
	end
end

local function HandleInput(InputEvent, KeyEvent)
	local RegisteredKeys, FireSignal, Keys = RegisteredKeys, FireSignal, Keys
	Connect(InputService[InputEvent], function(KeyName, GuiInput)
		if not GuiInput then
			local RegisteredKey = RegisteredKeys[KeyName.KeyCode.Name]
			if RegisteredKey then
				FireSignal(RegisteredKey[KeyEvent])
			end
		end
	end)
end

local Enabled = false
local TimeAbsent = time() + 10
local WelcomeBack = newSignal()
local PlayerGuiBackup = Player:FindFirstChild("PlayerGuiBackup")
local NameDisplayDistance = Player.NameDisplayDistance
local HealthDisplayDistance = Player.HealthDisplayDistance
local Input = {
	AbsentThreshold = 14;
	CreateEvent = newSignal; -- Create a new event signal
	WelcomeBack = WelcomeBack;
	__newindex = InputService;
	Keys = setmetatable(Keys, Keys);
	Mouse = setmetatable(Mouse, Mouse);
}

if not PlayerGuiBackup then
	PlayerGuiBackup = newInstance("Folder", Player)
	PlayerGuiBackup.Name = "GuiBackup"
end

local function WindowFocusReleased()
	TimeAbsent = time()
end

local function WindowFocused()
	TimeAbsent = time() - TimeAbsent
	if TimeAbsent > Input.AbsentThreshold then
		FireSignal(WelcomeBack, TimeAbsent)
	end
end

local function HideGui()
	if not Enabled then
		Enabled = true
		InputService.MouseIconEnabled = false
		SetCore(StarterGui, "TopbarEnabled", false)
		Player.HealthDisplayDistance = 0
		Player.NameDisplayDistance = 0
		local Guis = GetChildren(PlayerGui)
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
		local Guis = GetChildren(PlayerGuiBackup)
		for a = 1, #Guis do
			Guis[a].Parent = PlayerGuiBackup
		end
	end
end

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

HandleInput("InputBegan", "KeyDown")
HandleInput("InputEnded", "KeyUp")
Connect(InputService.WindowFocusReleased, WindowFocusReleased)
Connect(InputService.WindowFocused, WindowFocused)
ConnectSignal(Keys.Underscore.KeyDown, HideGui)

return setmetatable(Input, Input)
