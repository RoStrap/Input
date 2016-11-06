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
local gsub = string.gsub
local match = string.match
local remove = table.remove
local error, type, select, setmetatable, rawset, tostring, tick = error, type, select, setmetatable, rawset, tostring, tick

-- Client
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PlayerMouse = Player:GetMouse()

-- Pseudo Objects
local Disconnector = {}
Disconnector.__index = Disconnector

function Disconnector:Disconnect()
	local func = self.func
	local Connections = self.Connections
	for a = 1, #Connections do
		if Connections[a] == func then
			remove(Connections, a)
		end
	end
end

local function ConnectSignal(self, func)
	if not func then error("Connect(nil)", 2) end
	local Connections = self.Connections
	Connections[#Connections + 1] = func
	return setmetatable({Connections = Connections; func = func}, Disconnector)
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
		Connection = DisconnectSignal(Connection)
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
	local KeyCodes = a.KeyCode
	local Combination
	if type(KeyCodes) == "table" then
		Combination = {unpack(KeyCodes)}
		Combination[#Combination + 1] = b.KeyCode
	else
		Combination = {KeyCodes, b.KeyCode}
	end

	local Combo = newSignal(Combination)
	Combo.InternalConnection = b:Connect(function()
		if #Combo.Connections > 0 then -- Save on gas mileage
			local KeysPressed = GetKeysPressed(InputService)
			local NumberOfKeysPressed = #KeysPressed
			local AllButtonsArePressed = true

			if type(KeyCodes) == "table" then
				for c = 1, #KeyCodes do
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
				FireSignal(Combo)
			end
		end
	end)

	return Combo
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
	local Connections = {
		KeyUp = newSignal(Enum.KeyCode[v]);
		KeyDown = newSignal(Enum.KeyCode[v]);
	}
	self[v] = setmetatable(Connections, Key)
	RegisteredKeys[v] = true
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
					return FireSignal(Stored, PlayerMouse)
				end)
			end
		end
		return Stored
	else
		return PlayerMouse[v]
	end
end

local function KeyInputHandler(KeyEvent, Boolean)
	local RegisteredKeys, FireSignal, Keys = RegisteredKeys, FireSignal, Keys
	return function(KeyName, processed)
		if not processed then
			KeyName = KeyName.KeyCode.Name
--			KeysPressed[KeyName] = Boolean
			if RegisteredKeys[KeyName] then
				FireSignal(Keys[KeyName][KeyEvent])
			end
		end
	end
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
	PlayerGuiBackup = Instance.new("Folder", Player)
	PlayerGuiBackup.Name = "GuiBackup"
end

local function WindowFocusReleased()
	TimeAbsent = time()
end

local function WindowFocused()
	local TimeAbsent = time() - TimeAbsent
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
	local Variable = InputService[i] or error(i .. " is not a valid member of UserInputService")
	if type(Variable) == "function" then
		local func = Variable
		function Variable(...) -- We need to wrap functions to mimic ":" syntax
			return func(InputService, select(2, ...))
		end
	end
	return Variable
end

Connect(InputService.InputBegan, KeyInputHandler("KeyDown", true)) -- InputBegan listener
Connect(InputService.InputEnded, KeyInputHandler("KeyUp")) -- InputEnded listener
Connect(InputService.WindowFocusReleased, WindowFocusReleased)
Connect(InputService.WindowFocused, WindowFocused)
ConnectSignal(Keys.Underscore.KeyDown, HideGui)

return setmetatable(Input, Input)
