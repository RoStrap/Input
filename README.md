# UserInputService
This module is table wrapper designed to simplify dealing with user input. This module allows you to connect functions to certain events without the need
to actually call the `UserInputService`, or compare any Enum codes to input
objects. This is both faster to reference, and considerably more readable
to the writer.

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

Note: KeyUp and KeyDown events do not run off of the deprecated methods of PlayerMouse.

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

#### Small optimization note that most people don't need to worry about
The Event/Signal functions of the same name as the Roblox functions are not the Roblox functions, so localizing `Connect`, for example, from `game.ChildAdded.Connect` will not allow for use with custom Events. However, you can localize the functions from a single custom event from this module, as it utilizes metatables.

If you didn't understand any of that, just go with the prescribed syntax shown in the demos above.
