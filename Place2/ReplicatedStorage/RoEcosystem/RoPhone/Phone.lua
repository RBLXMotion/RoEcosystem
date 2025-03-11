-- @ScriptType: ModuleScript
local SIZE = UDim2.new(.2,0,.7,0)
local POSITION = UDim2.new(.5,0,.5,0)
local ANCHOR_POINT = Vector2.new(.5,.5)
local CORNER_RADIUS = UDim.new(.125,0)
local ASPECT_RATIO = .52
local PHONE_COLOR = Color3.new(0, 0, 0)
local CASE_THICKNESS = 3

local TIMEOUT = 5

type PhoneSettings = {
	Size: UDim2,
	Position: UDim2,
	AnchorPoint: Vector2,
	CornerRadius: UDim,
	AspectRatio: number,
	PhoneColor: Color3,
	CaseThickness: number
}

type Theme = "Light" | "Dark"

local RunService = game:GetService("RunService")

local Page = require(script:WaitForChild("Page"))
local App = require(script:WaitForChild("App"))
local Island = require(script:WaitForChild("Island"))
local Gesture = require(script:WaitForChild("Gesture"))

local OS = {}

local dependencies = script:WaitForChild("Dependencies")
local Spr = require(dependencies:WaitForChild("Spr"))
local Grid = require(dependencies:WaitForChild("Grid"))

function OS.new(player: Player, phoneSettings: PhoneSettings?, dataRemote: RemoteEvent?)	
	
	-- Create a settings table
	if phoneSettings == nil then
		phoneSettings = {
			Size = SIZE,
			Position = POSITION,
			AnchorPoint = ANCHOR_POINT,
			CornerRadius = CORNER_RADIUS,
			AspectRatio = ASPECT_RATIO,
			PhoneColor = PHONE_COLOR,
			CaseThickness = CASE_THICKNESS
		}
	end

	OS.Player = player
	OS.DataRemote = dataRemote or nil

	-- Create phone GUI
	OS.Gui = Instance.new("ScreenGui", player.PlayerGui)
	OS.Gui.Name = "PhoneGui"
	OS.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Manage added sound instances
	OS.Gui.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("Sound") then
			descendant.Volume = OS.Volume
			table.insert(OS.SoundInstances, descendant)
		end
	end)

	-- Set up phone frame (case)
	OS.Frame = Instance.new("Frame", OS.Gui)
	OS.Frame.Name = "PhoneFrame"
	
	OS.Frame.Size = phoneSettings.Size
	OS.Frame.Position = phoneSettings.Position
	OS.Frame.AnchorPoint = phoneSettings.AnchorPoint
	OS.Frame.BackgroundColor3 = phoneSettings.PhoneColor
	
	OS.FrameCorner = Instance.new("UICorner", OS.Frame)
	OS.FrameCorner.CornerRadius = phoneSettings.CornerRadius

	OS.FrameRatio = Instance.new("UIAspectRatioConstraint", OS.Frame)
	OS.FrameRatio.AspectRatio = phoneSettings.AspectRatio
	
	OS.FrameThick = Instance.new("UIStroke", OS.Frame)
	OS.FrameThick.Thickness = phoneSettings.CaseThickness
	OS.FrameThick.Color = phoneSettings.PhoneColor
	
	-- Set up phone screen
	OS.Screen = Instance.new("CanvasGroup", OS.Frame)
	OS.Screen.Name = "Screen"
	OS.Screen.AnchorPoint = Vector2.new(.5,.5)
	OS.Screen.Position = UDim2.new(.5,0,.5,0)
	OS.Screen.Size = UDim2.new(1,0,1,0)
	OS.Screen.BackgroundColor3 = Color3.new(1,1,1)
	
	OS.ScreenCorner = Instance.new("UICorner", OS.Screen)
	OS.ScreenCorner.CornerRadius = phoneSettings.CornerRadius
	
	-- Create homescreen frame
	OS.Homescreen = Instance.new("CanvasGroup", OS.Screen)
	OS.Homescreen.Name = "Homescreen"
	OS.Homescreen.AnchorPoint = Vector2.new(.5,.5)
	OS.Homescreen.Position = UDim2.new(.5,0,.5,0)
	OS.Homescreen.Size = UDim2.new(1,0,1,0)
	OS.Homescreen.BackgroundTransparency = 1
	
	OS.HomeBackground = Instance.new("ImageLabel", OS.Homescreen)
	OS.HomeBackground.Name = "Background"
	OS.HomeBackground.AnchorPoint = Vector2.new(.5,.5)
	OS.HomeBackground.Position = UDim2.new(.5,0,.5,0)
	OS.HomeBackground.Size = UDim2.new(2,0,1,0)
	OS.HomeBackground.ScaleType = Enum.ScaleType.Crop

	-- Set up island (pill at top of screen)
	OS.Island = Island.new(2)
	OS.Island.Frame.Parent = OS.Screen
	
	-- Set up gesture bar (home button at bottom of screen)
	OS.Gesture = Gesture.new()
	OS.Gesture.Button.Parent = OS.Screen
	
	OS.Gesture.GestureClicked:Connect(function()
		for i, v in OS.Apps do
			v:CloseApp()
			task.wait(.01)
			OS.Spring(OS.Gesture.Button, 1, 1, {BackgroundColor3 = Color3.new(1,1,1)})
		end
	end)
	
	-- Create a homescreen page
	OS.Pages = {
		[1] = Page.new(OS.Homescreen)
	}
	
	OS.Grids = {
		[1] = Grid.new(6, 4, Vector2.new(.2,.1), Vector2.new(.2,.4))
	}
	
	-- Create table for all registered apps
	OS.Apps = {}
	
	-- General OS variables
	OS.SoundInstances = {}
	OS.Volume = .5
end

function OS.AddAppPage()
	local page = Page.new()

	OS.Pages[#OS.Pages] = page
	return page
end

function OS.RegisterApp(name: string, frame: CanvasGroup, imageId: number, theme: Theme): typeof(App.new())
	local app = App.new(name, frame, imageId)
	
	local timeout = TIMEOUT
	
	repeat
		task.wait(1)
		timeout -= 1
		
		if timeout <= 0 and not OS.Apps then
			warn("Could not add app. App table not found.")
			return
		end
		
	until OS.Apps
	
	table.insert(OS.Apps, app)
		
	for i, v in OS.Grids do
		app.Button.Size = UDim2.fromScale((1/v.X), 1/v.Y)
		
		local added = v:AddObject(app.Button)
		if added then			
			app.Button.Parent = OS.Pages[i].Frame
			break
		end
	end
	
	app.DefaultSize = app.Button.Size
	app.DefaultPos = app.Button.Position
	
	frame.Parent = OS.Screen
	frame.Visible = false
	
	app.ButtonClicked:Connect(function()
		if app.Theme == "Dark" then
			OS.Spring(OS.Gesture.Button, 1, 1, {BackgroundColor3 = Color3.new(1,1,1)})
		else
			OS.Spring(OS.Gesture.Button, 1, 1, {BackgroundColor3 = Color3.new(0, 0, 0)})			
		end
	end)
	
	return app
end

function OS.Spring(instance: Instance, damping: number, frequency: number, properties: {[string]: any}): boolean
	Spr.target(instance, damping, frequency, properties)

	Spr.completed(instance, function()
		return true
	end)
end

return OS
