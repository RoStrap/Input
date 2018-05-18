# Keys
A light-weight library for simplifying Key input.
## API
### Keys
The library returns a table `Keys`. Within this table, Keys from Enum.KeyCode can be indexed.
```lua
local Resources = require(game:GetService("ReplicatedStorage"):WaitForChild("Resources"))
local Keys = Resources:LoadLibrary("Keys")

-- Each of these can be called with either a '.' or a ':', as it doesn't need 'self'
Keys:Pause() -- Disconnects this module's InputEnded and InputBegan connections to UserInputService
Keys:Resume() -- Reconnects what Pause disconnects

local Q = Keys.Q -- returns a Key Object
```
### Key
These table objects contain two custom Signals (technically, they are interfaces). `KeyDown` and `KeyUp`
```lua
local Q = Keys.Q -- returns a Key Object

Q.KeyDown:Connect(function()
	print("Q was pressed!")
end)

Q.KeyUp:Connect(function()
	print("Q was let go!")
end)
```

### Signals
In this module, `KeyDown` and `KeyUp` Signals have the following functions:
```lua
local Shift = Keys.Shift.KeyDown
local E = Keys.E.KeyDown

E:Connect(function() -- Connects a function
	print("E!")
end)

E:Press() -- Fires open connections
E:Fire() -- Same as Press()
E:Wait() -- Yields until event fires

local Shift_E = (Shift + E):Connect(function() -- You can add 2 Keys together to get a combo event!
	-- NOTE: Neither Shift nor E fire when (Shift + E) fires
	-- If you want to fire one or both of them, do Shift:Press() or E:Press()
end)
```

## Overhead
This is an extremely light library. The tables within `Keys` are merely interface tables, and are not directly involved with calling connected Functions. The tables interface with a system that mostly looks like this:
```lua
local KeyUps = {
	Q = function()
		print("Q was let up")
	end;

	E = function()
		print("E was let up")
	end
}

UserInputService.InputEnded:Connect(function(Data, GuiInput)
	if not GuiInput and Data.KeyCode ~= Enum.KeyCode.Unknown then
		local Function = KeyUps[Data.KeyCode.Name]
		if Function then
			Function()
		end
	end
end)
```
