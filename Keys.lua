-- @author Validark
-- @readme https://github.com/RoStrap/Input/blob/master/README.md

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
	self[1]()
end

function Multicaller:Disconnect()
	local Storage = self.Key.Storage
	local KeyName = self.Key.KeyName
	local Existing = Storage[KeyName]

	if type(Existing) == "table" then
		Existing[1] = function() end
	else
		Storage[KeyName] = nil
	end
end

local Key = {}
function Key:__index(i)
	return i == "KeyDown" and self or Key[i]
end

function Key.__add(a, b)
	assert(a and b and a.KeyDown and b.KeyDown and a.KeyDown == a and b.KeyDown == b, "You can only chain 2 KeyDown events")

	local Storage = Combinations[b.KeyName]
	if not Storage then
		Storage = {}
		Combinations[b.KeyName] = Storage
	end

	return setmetatable({
		KeyName = a.KeyName;
		Storage = Storage;
	}, Key)
end

function Key:Connect(Function)
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
		return setmetatable({Key = self}, Multicaller)
	end
end

function Key:Disconnect()
	local Existing = self.Storage[self.KeyName]
	if type(Existing) == "table" then
		local Connections = Existing.Connections
		for a = 1, #Connections do
			Connections[a]:Disconnect()
			Connections[a] = nil
		end
		Existing.Bindable, Existing.Connections, Existing[1] = Existing.Bindable:Destroy()
	end
	self.Storage[self.KeyName], Existing = nil
end

function Key:Press()
	self.Storage[self.KeyName]()
end
Key.Fire = Key.Press

function Key:Wait()
	local Existing = self.Storage[self.KeyName]
	if type(Existing) == "table" then
		Existing.Bindable.Event:Wait()
	else
		local Bindable = Instance.new("BindableEvent")
		local Caller = setmetatable({
			Existing;
			Bindable = Bindable;
			Connections = {};
		}, Multicaller)
		self.Storage[self.KeyName] = Caller
		Bindable.Event:Wait()
		if #Caller.Connections == 0 then
			self.Storage[self.KeyName], Caller = Existing
			Bindable:Destroy()
		end
	end
end

return setmetatable(Keys, {
	__index = function(self, KeyName)	
		local NewKey = setmetatable({
			KeyUp = setmetatable({
				KeyName = KeyName;
				Storage = KeyUps;
			}, Key);

			Storage = KeyDowns;
			KeyName = KeyName;
		}, Key)

		self[KeyName] = NewKey
		return NewKey
	end
})
