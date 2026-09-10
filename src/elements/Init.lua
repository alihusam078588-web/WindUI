return {
	Elements = {
		Paragraph = require("./Paragraph"),
		Button = require("./Button"),
		Toggle = require("./Toggle"),
		Slider = require("./Slider"),
		ProgressBar = require("./ProgressBar"),
		Keybind = require("./Keybind"),
		Input = require("./Input"),
		Dropdown = require("./Dropdown"),
		Code = require("./Code"),
		Colorpicker = require("./Colorpicker"),
		Section = require("./Section"),
		Divider = require("./Divider"),
		Space = require("./Space"),
		Image = require("./Image"),
		Group = require("./Group"),
		HStack = require("./HStack"),
		VStack = require("./VStack"),
		Viewport = require("./Viewport"),
		--Video = require("./Video"),
	},

	Load = function(tbl, Container, Elements, Window, WindUI, OnElementCreateFunction, ElementsModule, UIScale, Tab)
		local AutoFlagElements = {
			Toggle = true,
			Slider = true,
			Dropdown = true,
			Input = true,
			Keybind = true,
			Colorpicker = true,
		}

		local function MakeFlag(title)
			if type(title) ~= "string" then
				return nil
			end

			local flag = title:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
			if flag == "" then
				return nil
			end

			Window._WindUIAutoFlags = Window._WindUIAutoFlags or {}

			local base = flag
			local index = 2

			while Window._WindUIAutoFlags[flag] do
				flag = base .. "_" .. index
				index += 1
			end

			Window._WindUIAutoFlags[flag] = true

			return flag
		end

		local function GetKeybindGui()
			if Window._KeybindGui and Window._KeybindGui.Parent then
				return Window._KeybindGui
			end

			local Players = game:GetService("Players")
			local Player = Players.LocalPlayer
			local PlayerGui = Player:WaitForChild("PlayerGui")

			local ScreenGui = Instance.new("ScreenGui")
			ScreenGui.Name = "WindUIKeybindButtons"
			ScreenGui.ResetOnSpawn = false
			ScreenGui.DisplayOrder = 999999
			ScreenGui.Parent = PlayerGui

			Window._KeybindGui = ScreenGui
			Window._KeybindButtonCount = Window._KeybindButtonCount or 0

			return ScreenGui
		end

		local function CreateKeybindButton(content)
			Window._KeybindButtons = Window._KeybindButtons or {}

			if Window._KeybindButtons[content] and Window._KeybindButtons[content].Parent then
				return Window._KeybindButtons[content]
			end

			local UserInputService = game:GetService("UserInputService")
			local Camera = workspace.CurrentCamera
			local ScreenGui = GetKeybindGui()

			Window._KeybindButtonCount += 1

			local Button = Instance.new("TextButton")
			Button.Name = (content.Title or "Keybind") .. "Button"
			Button.Size = UDim2.fromOffset(80, 40)
			Button.Position = UDim2.new(
				1,
				-20,
				0,
				20 + ((Window._KeybindButtonCount - 1) * 50)
			)
			Button.AnchorPoint = Vector2.new(1, 0)
			Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			Button.Text = content.Title or "Button"
			Button.TextScaled = true
			Button.Font = Enum.Font.GothamBold
			Button.AutoButtonColor = true
			Button.Parent = ScreenGui

			local Corner = Instance.new("UICorner")
			Corner.CornerRadius = UDim.new(0, 12)
			Corner.Parent = Button

			local function UpdateSize()
				Camera = workspace.CurrentCamera or Camera

				if not Camera then
					return
				end

				local viewport = Camera.ViewportSize
				local scale = math.clamp(
					math.min(viewport.X, viewport.Y) / 700,
					0.75,
					1.25
				)

				Button.Size = UDim2.fromOffset(
					80 * scale,
					40 * scale
				)
			end

			if Camera then
				Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateSize)
			end

			UpdateSize()

			local dragging = false
			local moved = false
			local dragStart
			local startPosition
			local dragInput

			local function UpdateDrag(input)
				if not dragStart or not startPosition then
					return
				end

				local delta = input.Position - dragStart

				if not moved and delta.Magnitude > 6 then
					moved = true
					dragging = true
				end

				if dragging then
					Button.Position = UDim2.new(
						startPosition.X.Scale,
						startPosition.X.Offset + delta.X,
						startPosition.Y.Scale,
						startPosition.Y.Offset + delta.Y
					)
				end
			end

			Button.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then

					dragStart = input.Position
					startPosition = Button.Position
					moved = false
					dragging = false
				end
			end)

			Button.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch then

					dragInput = input
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if input == dragInput then
					UpdateDrag(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then

					if not moved then
						local currentValue = content.Value == true
						content:Set(not currentValue, nil, true)
					end

					dragging = false

					if input == dragInput then
						dragInput = nil
					end

					dragStart = nil
					startPosition = nil
				end
			end)

			Window._KeybindButtons[content] = Button

			return Button
		end

		local function DestroyKeybindButton(content)
			if Window._KeybindButtons and Window._KeybindButtons[content] then
				Window._KeybindButtons[content]:Destroy()
				Window._KeybindButtons[content] = nil
			end
		end

		for name, module in next, Elements do
			tbl[name] = function(self, config)
				config = config or {}

				config.Tab = Tab or tbl
				config.ParentType = tbl.__type
				config.ParentTable = tbl
				config.Index = #tbl.Elements + 1
				config.GlobalIndex = #Window.AllElements + 1
				config.Parent = Container
				config.Window = Window
				config.WindUI = WindUI
				config.UIScale = UIScale
				config.ElementsModule = ElementsModule

				if AutoFlagElements[name] and config.Flag == nil then
					config.Flag = MakeFlag(config.Title)
				elseif type(config.Flag) == "string" then
					Window._WindUIAutoFlags = Window._WindUIAutoFlags or {}
					Window._WindUIAutoFlags[config.Flag] = true
				end

				local _elementInstance, content = module:New(config)

				if config.Flag and typeof(config.Flag) == "string" then
					if Window.CurrentConfig then
						Window.CurrentConfig:Register(config.Flag, content)

						if Window.PendingConfigData and Window.PendingConfigData[config.Flag] then
							local data = Window.PendingConfigData[config.Flag]
							local ConfigManager = Window.ConfigManager

							if ConfigManager.Parser[data.__type] then
								task.defer(function()
									local success, err = pcall(function()
										ConfigManager.Parser[data.__type].Load(content, data)
									end)

									if success then
										Window.PendingConfigData[config.Flag] = nil
									else
										warn(
											"[ WindUI ] Failed to apply pending config for '"
												.. config.Flag
												.. "': "
												.. tostring(err)
										)
									end
								end)
							end
						end
					else
						Window.PendingFlags = Window.PendingFlags or {}
						Window.PendingFlags[config.Flag] = content
					end
				end

				local frame

				for key, value in next, content do
					if typeof(value) == "table"
						and key ~= "ElementFrame"
						and key:match("Frame$") then

						frame = value
						break
					end
				end

				if frame then
					content.ElementFrame = frame.UIElements.Main

					function content:SetTitle(title)
						return frame.SetTitle and frame:SetTitle(title)
					end

					function content:SetDesc(desc)
						return frame.SetDesc and frame:SetDesc(desc)
					end

					function content:SetImage(image, size)
						return frame.SetImage and frame:SetImage(image, size)
					end

					function content:SetThumbnail(image, size)
						return frame.SetThumbnail and frame:SetThumbnail(image, size)
					end

					function content:Highlight()
						frame:Highlight()
					end

					function content:Destroy()
						frame:Destroy()

						table.remove(Window.AllElements, config.GlobalIndex)
						table.remove(tbl.Elements, config.Index)

						if Tab then
							table.remove(Tab.Elements, config.Index)
						end

						tbl:UpdateAllElementShapes(tbl)
					end
				end

				Window.AllElements[config.GlobalIndex] = content
				tbl.Elements[config.Index] = content

				if Tab then
					Tab.Elements[config.Index] = content
				end

				if name == "Toggle"
					and not config._KeybindInternal
					and not Window._CreatingKeybindToggle then

					Window._KeybindTab = Window._KeybindTab or Window:Tab({
						Title = "Keybinds",
						Icon = "lucide:keyboard",
					})

					Window._CreatingKeybindToggle = true

					local keybindToggle = Window._KeybindTab:Toggle({
						Title = (content.Title or "Toggle") .. " Button",
						Desc = "Show a button for " .. (content.Title or "Toggle"),
						Value = false,
						Flag = (config.Flag and (config.Flag .. "_Button")) or nil,
						_KeybindInternal = true,

						Callback = function(value)
							if value then
								task.defer(function()
									if Window._KeybindButtons
										and Window._KeybindButtons[content]
										and Window._KeybindButtons[content].Parent then
										return
									end

									CreateKeybindButton(content)
								end)
							else
								DestroyKeybindButton(content)
							end
						end,
					})

					Window._CreatingKeybindToggle = false

					content._KeybindToggle = keybindToggle
				end

				if Window.NewElements then
					tbl:UpdateAllElementShapes(tbl)
				end

				if OnElementCreateFunction then
					OnElementCreateFunction(content, tbl.Elements)
				end

				return content
			end
		end

		function tbl:UpdateAllElementShapes(bbb)
			for i, element in next, bbb.Elements do
				local frame

				for key, value in pairs(element) do
					if typeof(value) == "table" and key:match("Frame$") then
						frame = value
						break
					end
				end

				if not frame and element.UpdateShape then
					frame = element
				end

				if frame then
					frame.Index = i

					if frame.UpdateShape then
						frame.UpdateShape(bbb)
					end
				end
			end
		end
	end,
}
