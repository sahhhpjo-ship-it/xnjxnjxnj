local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local PathfindingService = game:GetService("PathfindingService")

local SUDO_USER = "turripy"

--- SUDO COMMANDS ---

local function findPlayerByName(name)
	name = name:lower()
	local found = {}
	for _, player in Players:GetPlayers() do
		local pname = player.Name:lower()
		local dname = player.DisplayName and player.DisplayName:lower() or ""
		if pname:sub(1, #name) == name or dname:sub(1, #name) == name then
			table.insert(found, player)
		end
	end
	return found[1]
end

local function strongFling(target, duration)
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
	local hrp = character.HumanoidRootPart
	local targetHRP = target.Character.HumanoidRootPart

	local fakepart = Instance.new("Part", workspace)
	fakepart.Anchored = true
	fakepart.Size = Vector3.new(5,5,5)
	fakepart.Position = targetHRP.Position
	fakepart.CanCollide = false
	fakepart.Transparency = 0.5
	fakepart.Material = Enum.Material.ForceField

	local att1 = Instance.new("Attachment", fakepart)
	local att2 = Instance.new("Attachment", hrp)
	local align = Instance.new("AlignPosition", fakepart)
	align.Attachment0 = att2
	align.Attachment1 = att1
	align.RigidityEnabled = true
	align.Responsiveness = math.huge
	align.MaxForce = math.huge
	align.MaxVelocity = math.huge
	align.MaxAxesForce = Vector3.new(math.huge,math.huge,math.huge)
	align.Visible = true
	align.Mode = Enum.PositionAlignmentMode.TwoAttachment

	local partic = Instance.new("ParticleEmitter", fakepart)
	partic.Texture = "rbxassetid://15273937357"
	partic.SpreadAngle = Vector2.new(-180,180)
	partic.Rate = 45
	partic.Size = NumberSequence.new(1,0)
	partic.Transparency = NumberSequence.new(0.9)
	partic.Lifetime = NumberRange.new(0.7,1)
	partic.RotSpeed = NumberRange.new(-45,45)

	task.spawn(function()
		while fakepart.Parent do
			task.wait()
			for i = 0,1,0.01 do
				task.wait()
				fakepart.Color = Color3.fromHSV(i,1,1)
				partic.Color = ColorSequence.new(Color3.fromHSV(i,1,1))
			end
		end
	end)

	for _, v in character:GetDescendants() do
		if v:IsA("BasePart") then
			if v.Name ~= "HumanoidRootPart" then
				v.Transparency = .75
				v.Material = Enum.Material.Neon
			end
		elseif v:IsA("Decal") then
			v:Remove()
		end
	end

	if workspace.CurrentCamera then
		workspace.CurrentCamera.CameraSubject = fakepart
	end

	local startTime = os.clock()
	local power = 100
	local attack = 5
	local mouse = LocalPlayer:GetMouse()
	local keyStates = {w=false,a=false,s=false,d=false}
	mouse.KeyDown:Connect(function(key)
		if keyStates[key] ~= nil then keyStates[key] = true end
	end)
	mouse.KeyUp:Connect(function(key)
		if keyStates[key] ~= nil then keyStates[key] = false end
	end)

	local heartbeatConn
	heartbeatConn = game:GetService("RunService").Heartbeat:Connect(function()
		if keyStates.w then
			fakepart.Position = fakepart.Position + workspace.CurrentCamera.CFrame.LookVector * 2
		end
		if keyStates.a then
			fakepart.Position = fakepart.Position - workspace.CurrentCamera.CFrame.RightVector * 2
		end
		if keyStates.s then
			fakepart.Position = fakepart.Position - workspace.CurrentCamera.CFrame.LookVector * 2
		end
		if keyStates.d then
			fakepart.Position = fakepart.Position + workspace.CurrentCamera.CFrame.RightVector * 2
		end
	end)

	local angularSpin = task.spawn(function()
		while os.clock() - startTime < duration do
			hrp.AssemblyAngularVelocity = Vector3.new(math.random(-500,50),math.random(-500,500) * power,math.random(-5,5))
			task.wait(math.random(0,attack)/50)
		end
	end)

	local swimState = task.spawn(function()
		while os.clock() - startTime < duration do
			character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
			task.wait(.5)
			character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			task.wait(.5)
		end
	end)

	repeat
		if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then break end
		if not character or not hrp then break end
		targetHRP = target.Character.HumanoidRootPart
		hrp.CFrame = targetHRP.CFrame
		hrp.AssemblyAngularVelocity = Vector3.new(10000,9999,-9999)
		hrp.AssemblyLinearVelocity = Vector3.new(-17.7,500,17.7)
		fakepart.Position = targetHRP.Position
		fakepart.Rotation = hrp.Rotation
		character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		character.Humanoid.Jump = math.random(0,1)==1
		hrp.Velocity = Vector3.new(math.random(-250,250),math.random(-500,500),math.random(-250,250))
		task.wait()
	until os.clock() - startTime > duration or not target.Character:FindFirstChild("Head")

	if heartbeatConn then heartbeatConn:Disconnect() end
	if fakepart then fakepart:Destroy() end
end

local orbiting = false
local orbitConnection = nil

local function orbitTarget(targetPlayer, radius, speed)
	if orbiting and orbitConnection then
		orbitConnection:Disconnect()
		orbiting = false
	end
	if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local targetHRP = targetPlayer.Character.HumanoidRootPart
	local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end
	orbiting = true
	local angle = 0
	orbitConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		if not orbiting then return end
		angle = angle + speed * dt
		local offset = Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)
		myHRP.CFrame = CFrame.new(targetHRP.Position + offset, targetHRP.Position)
	end)
end

local function stopOrbit()
	if orbiting and orbitConnection then
		orbitConnection:Disconnect()
		orbiting = false
	end
end

local function teleportToTarget(targetPlayer)
	if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	local targetHRP = targetPlayer.Character.HumanoidRootPart
	local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP then return end
	myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
end

local function rejoinServer()
	local placeId = game.PlaceId
	local jobId = game.JobId
	TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
end

local function resetCharacter()
	local character = LocalPlayer.Character
	if character and character:FindFirstChild("Humanoid") then
		character.Humanoid.Health = 0
	end
end

local flingActive = false
local flingTask = nil

local function startTrackingFling(targetPlayer, duration)
	if flingActive then return end
	flingActive = true
	flingTask = task.spawn(function()
		strongFling(targetPlayer, duration)
		flingActive = false
	end)
end

local loopFlingActive = false
local loopFlingTask = nil
local loopFlingTarget = nil

local function startLoopFling(targetPlayer)
	if loopFlingActive then return end
	loopFlingActive = true
	loopFlingTarget = targetPlayer
	loopFlingTask = task.spawn(function()
		while loopFlingActive do
			if not loopFlingTarget or not loopFlingTarget.Character or not loopFlingTarget.Character:FindFirstChild("HumanoidRootPart") then
				break
			end
			startTrackingFling(loopFlingTarget, 2.5)
			task.wait(2.7)
		end
		loopFlingActive = false
		loopFlingTarget = nil
	end)
end

local function stopLoopFling()
	loopFlingActive = false
	loopFlingTarget = nil
	if loopFlingTask then
		flingTask = nil
	end
end

local followActive = false
local followTask = nil
local followTarget = nil

local function startFollow(targetPlayer)
	if followActive then return end
	followActive = true
	followTarget = targetPlayer
	followTask = task.spawn(function()
		local lastTargetPos = nil
		local lastPathTime = 0
		local path = nil
		local myChar = nil
		local myHRP = nil
		local myHumanoid = nil
		local targetHRP = nil
		local stuckCheckPos = nil
		local stuckCheckTime = 0

		while followActive and followTarget and followTarget.Character and followTarget.Character:FindFirstChild("HumanoidRootPart") do
			myChar = LocalPlayer.Character
			myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
			myHumanoid = myChar and myChar:FindFirstChild("Humanoid")
			targetHRP = followTarget.Character.HumanoidRootPart
			if not myHRP or not myHumanoid or not targetHRP then
				task.wait(0.05)
				continue
			end

			-- Recalculate path if target moved >0.5 stud or every 0.1s
			local targetMoved = (not lastTargetPos) or ((targetHRP.Position - lastTargetPos).Magnitude > 0.5)
			local timeElapsed = (os.clock() - lastPathTime) > 0.1
			if targetMoved or timeElapsed or not path or path.Status ~= Enum.PathStatus.Success then
				lastTargetPos = targetHRP.Position
				lastPathTime = os.clock()
				path = PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 5,
					AgentCanJump = true,
					AgentJumpHeight = 10,
					AgentMaxSlope = 45,
					WaypointSpacing = 1,
				})
				path:ComputeAsync(myHRP.Position, targetHRP.Position)
			end

			local waypoints = path and path:GetWaypoints() or {}
			for i = 1, #waypoints do
				if not followActive then break end
				local wp = waypoints[i]
				if wp and myHumanoid then
					-- If target moved >0.5 stud, break and recalc path
					if (targetHRP.Position - lastTargetPos).Magnitude > 0.5 then
						break
					end

					-- Face the target before moving
					local lookAt = CFrame.lookAt(myHRP.Position, Vector3.new(targetHRP.Position.X, myHRP.Position.Y, targetHRP.Position.Z))
					myHRP.CFrame = lookAt

					myHumanoid:MoveTo(wp.Position)
					if wp.Action == Enum.PathWaypointAction.Jump then
						myHumanoid.Jump = true
					end

					local reached = false
					local moveConn = myHumanoid.MoveToFinished:Connect(function(success)
						reached = true
					end)

					local t0 = os.clock()
					local stuckStartPos = myHRP.Position
					while not reached and followActive and (os.clock()-t0 < 0.4) do
						task.wait(0.01)
						-- If target moved >0.5 stud, break and recalc path
						if (targetHRP.Position - lastTargetPos).Magnitude > 0.5 then
							break
						end
						-- Stuck check: if not moved >0.5 stud in 0.3s, break and recalc
						if (os.clock()-t0 > 0.3) and ((myHRP.Position - stuckStartPos).Magnitude < 0.5) then
							break
						end
					end
					moveConn:Disconnect()
					task.wait(0.01)
				end
				if path.Status == Enum.PathStatus.NoPath then
					break
				end
			end

			task.wait(0.01)
		end
		followActive = false
		followTarget = nil
	end)
end

local function stopFollow()
	followActive = false
	followTarget = nil
	if followTask then
		followTask = nil
	end
end

-- Say logic (support TextChatService and legacy chat)
local function sayPhrase(phrase, whisperTarget)
	if phrase and phrase ~= "" then
		if TextChatService and TextChatService:FindFirstChild("TextChannels") then
			-- Try to use RBXWhisper channel if available
			local whisperChannel = TextChatService.TextChannels:FindFirstChild("RBXWhisper")
			if whisperChannel and whisperTarget then
				whisperChannel:SendAsync(whisperTarget, phrase)
				return
			end
			-- Fallback to general channel
			local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral") or TextChatService.TextChannels:FindFirstChild("General")
			if generalChannel then
				generalChannel:SendAsync(phrase)
				return
			end
		end
		local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
		if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
			chatEvents.SayMessageRequest:FireServer(phrase, "All")
		end
	end
end

-- Helper to send a whisper to SUDO_USER
local function whisperToSudoUser(text)
	if SUDO_USER and text and text ~= "" then
		if TextChatService and TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXWhisper") then
			sayPhrase(text, SUDO_USER)
		else
			-- Enter whisper mode first, then send the message
			local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
			if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
				chatEvents.SayMessageRequest:FireServer("/w " .. SUDO_USER, "All")
				task.wait(0.1)
				chatEvents.SayMessageRequest:FireServer(text, "All")
			else
				-- Fallback to sending "/w turripy message" as one phrase
				local phrase = "/w " .. SUDO_USER .. " " .. text
				sayPhrase(phrase)
			end
		end
	end
end

-- Helper to get current map name if available
local function getCurrentMapName()
	local mapName = "Unknown"
	for i, obj in workspace:GetChildren() do
		if obj:IsA("Model") and obj:GetAttribute("MapID") then
			mapName = obj.Name
			break
		end
	end
	return mapName
end

-- Helper to get info string
local function getInfoString()
	local mapName = getCurrentMapName()
	local playerCount = #Players:GetPlayers()
	local info = "User Info:\n"
	info = info .. "CurrentMap: " .. mapName .. "\n"
	info = info .. "Players: " .. tostring(playerCount)
	return info
end

-- Helper to get status string
local function getStatusString()
	local status = "Feature Status:\n"
	status = status .. "Orbit: " .. (orbiting and "ON" or "OFF")
	if orbiting and orbitConnection then
		status = status .. " (targeted)"
	else
		status = status .. ""
	end
	status = status .. "\nFollow: " .. (followActive and "ON" or "OFF")
	if followActive and followTarget then
		status = status .. " (target: " .. tostring(followTarget.Name) .. ")"
	else
		status = status .. ""
	end
	status = status .. "\nLoopFling: " .. (loopFlingActive and "ON" or "OFF")
	if loopFlingActive and loopFlingTarget then
		status = status .. " (target: " .. tostring(loopFlingTarget.Name) .. ")"
	else
		status = status .. ""
	end
	-- Add more features here if needed
	return status
end

-- Helper to show notification or fallback to system message
local function showNotification(title, text, duration)
	local success, err = pcall(function()
		StarterGui:SetCore("SendNotification",{
			Title = title,
			Text = text,
			Duration = duration or 8
		})
	end)
	if not success then
		-- Fallback to system message
		pcall(function()
			StarterGui:SetCore("ChatMakeSystemMessage",{
				Text = "[" .. title .. "] " .. text,
				Color = Color3.new(1, 1, 0),
				Font = Enum.Font.SourceSansBold,
				FontSize = Enum.FontSize.Size24
			})
		end)
		print("Notification fallback: " .. tostring(err))
	end
end

local function onChatted(player)
	player.Chatted:Connect(function(msg)
		if player.Name ~= SUDO_USER then return end
		local args = {}
		for word in string.gmatch(msg, "[^%s]+") do
			table.insert(args, word)
		end
		local command = args[1]
		if command == "!fling" and args[2] then
			local target = findPlayerByName(args[2])
			startTrackingFling(target, 5)
		elseif command == "!loopfling" and args[2] then
			local target = findPlayerByName(args[2])
			startLoopFling(target)
		elseif command == "!unloopfling" then
			stopLoopFling()
		elseif command == "!orbit" and args[2] and args[3] and args[4] then
			local target = findPlayerByName(args[2])
			local radius = tonumber(args[3]) or 10
			local speed = tonumber(args[4]) or 2
			orbitTarget(target, radius, speed)
		elseif command == "!orbitstop" then
			stopOrbit()
		elseif command == "!to" and args[2] then
			local target = findPlayerByName(args[2])
			teleportToTarget(target)
		elseif command == "!rejoin" then
			rejoinServer()
		elseif command == "!reset" then
			resetCharacter()
		elseif command == "!follow" and args[2] then
			local target = findPlayerByName(args[2])
			startFollow(target)
		elseif command == "!unfollow" then
			stopFollow()
		elseif command == "!say" and #args > 1 then
			local phrase = msg:sub(#command + 2)
			sayPhrase(phrase)
		elseif command == "!antifling" then
			-- Run AntiFling script from URL
			local success, err = pcall(function()
				loadstring(game:HttpGet('https://raw.githubusercontent.com/Linux6699/DaHubRevival/main/AntiFling.lua'))()
			end)
			if not success then
				showNotification("Antifling Error", tostring(err), 5)
			end
		elseif command == "!info" then
			local info = getInfoString()
			whisperToSudoUser(info)
			showNotification("Info", info, 8)
		elseif command == "!status" then
			local status = getStatusString()
			whisperToSudoUser(status)
			showNotification("Status", status, 8)
		end
	end)
end

for _, player in Players:GetPlayers() do
	onChatted(player)
end

Players.PlayerAdded:Connect(function(player)
	onChatted(player)
end)

LocalPlayer.CharacterAdded:Connect(function()
	stopOrbit()
	stopFollow()
end)
