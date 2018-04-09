-- A cleaner way of connecting functions to key-presses
-- @readme https://github.com/RoStrap/Input/blob/master/README.md
-- @author Validark

local UserInputService = game:GetService("UserInputService")
local Combinations = {}
local KeyUps = {}
local KeyDowns = {}
local Unknown = Enum.KeyCode.Unknown

local Ambiguous = {
	LeftShift = "Shift";
	RightShift = "Shift";
	LeftAlt = "Alt";
	RightAlt = "Alt";
	LeftControl = "Control";
	RightControl = "Control";
}

local DeclarationAmbiguous = {
	Ctrl = "Control";
	Cmd = "Control";
	Command = "Control";
}

local function KeyDown(Data, GuiInput)
	if not GuiInput and Data.KeyCode ~= Unknown then
		local KeyName = Data.KeyCode.Name
		KeyName = Ambiguous[KeyName] or KeyName

		local Combinations = Combinations[KeyName]
		if Combinations then
			local KeysPressed = UserInputService:GetKeysPressed()
			for b = 1, #KeysPressed do
				local KeyName = KeysPressed[b].KeyCode.Name
				local Function = Combinations[Ambiguous[KeyName] or KeyName]
				if Function then
					return Function()
				end
			end
		end

		local Function = KeyDowns[KeyName]
		if Function then
			return Function()
		end
	end
end

local function KeyUp(Data, GuiInput)
	if not GuiInput and Data.KeyCode ~= Unknown then
		local KeyName = Data.KeyCode.Name
		local Function = KeyUps[Ambiguous[KeyName] or KeyName]
		if Function then
			return Function()
		end
	end
end

local Connection1 = UserInputService.InputBegan:Connect(KeyDown)
local Connection2 = UserInputService.InputEnded:Connect(KeyUp)

local Keys = {}

function Keys:Pause()
	Connection1:Disconnect()
	Connection2:Disconnect()
end

function Keys:Resume()
	Connection1 = UserInputService.InputBegan:Connect(KeyDown)
	Connection2 = UserInputService.InputEnded:Connect(KeyUp)
end

local Multicaller = {} -- Shhhh, we use this in two different ways. Just don't call your RbxScriptSignal xP
Multicaller.__index = Multicaller

function Multicaller:__call()
	self.Bindable:Fire()
	local Function = self[1]
	if Function then
		Function()
	end
end

function Multicaller:Disconnect()
	local Storage = self.KeyEvent.Storage
	local KeyName = self.KeyEvent.KeyName
	local Existing = Storage[KeyName]

	if type(Existing) == "table" then
		Existing[1] = function() end
	else
		Storage[KeyName] = nil
	end
end

local KeyEvent = {}
KeyEvent.__index = KeyEvent

function KeyEvent.__add(a, b)
	assert(a and b and a.Storage == KeyDowns and b.Storage == KeyDowns, "You can only chain 2 KeyDown events")

	local Storage = Combinations[b.KeyName]
	if not Storage then
		Storage = {}
		Combinations[b.KeyName] = Storage
	end

	return setmetatable({
		KeyName = a.KeyName;
		Storage = Storage;
	}, KeyEvent)
end

function KeyEvent:Connect(Function)
	local Storage = self.Storage
	local KeyName = self.KeyName
	local Existing = Storage[KeyName]
	if Existing then
		if type(Existing) == "table" then
			local Connection = Existing.Bindable.Event:Connect(Function)
			Existing.Connections[#Existing.Connections + 1] = Connection
			return Connection
		else
			local Bindable = Instance.new("BindableEvent")
			local Connection = Bindable.Event:Connect(Function)
			Storage[KeyName] = setmetatable({
				Existing;
				Bindable = Bindable;
				Connections = {Connection};
			}, Multicaller)
			return Connection
		end
	else
		Storage[KeyName] = Function
		return setmetatable({KeyEvent = self}, Multicaller)
	end
end

function KeyEvent:Disconnect()
	local Existing = self.Storage[self.KeyName]
	if type(Existing) == "table" then
		local Connections = Existing.Connections
		for a = 1, #Connections do
			Connections[a]:Disconnect()
			Connections[a] = nil
		end
		Existing.Bindable, Existing.Connections, Existing[1] = Existing.Bindable:Destroy()
	end
	self.Storage[self.KeyName] = nil
end

function KeyEvent:Press()
	self.Storage[self.KeyName]()
end
KeyEvent.Fire = KeyEvent.Press

function KeyEvent:Wait()
	local Existing = self.Storage[self.KeyName]

	if type(Existing) == "table" then
		Existing.Bindable.Event:Wait()
	else
		local Caller = setmetatable({
			Existing;
			Bindable = Instance.new("BindableEvent");
			Connections = {};
		}, Multicaller)

		self.Storage[self.KeyName] = Caller
		Caller.Bindable.Event:Wait()

		if #Caller.Connections == 0 then
			self.Storage[self.KeyName] = Existing
			Caller.Bindable, Caller.Connections, Caller[1] = Caller.Bindable:Destroy()
		end
	end
end

return setmetatable(Keys, {
	__index = function(self, KeyName)
		KeyName = DeclarationAmbiguous[KeyName] or KeyName
		local NewKey = {
			KeyUp = setmetatable({
				KeyName = KeyName;
				Storage = KeyUps;
			}, KeyEvent);

			KeyDown = setmetatable({
				KeyName = KeyName;
				Storage = KeyDowns;
			}, KeyEvent);
		}

		self[KeyName] = NewKey
		return NewKey
	end
})
