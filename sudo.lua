local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")

local SUDO_USER = "turripy"

local function findPlayerByName(name)
	for _, player in Players:GetPlayers() do
		if player.Name:lower() == name:lower() then
			return player
		end
	end
	return nil
end

-- New Strong Fling Logic (based on user sample)
local function strongFling(target, duration)
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
	local hrp = character.HumanoidRootPart
	local targetHRP = target.Character.HumanoidRootPart

	-- Create fake part and attachments for forced alignment
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

	-- Particle effect
	local partic = Instance.new("ParticleEmitter", fakepart)
	partic.Texture = "rbxassetid://15273937357"
	partic.SpreadAngle = Vector2.new(-180,180)
	partic.Rate = 45
	partic.Size = NumberSequence.new(1,0)
	partic.Transparency = NumberSequence.new(0.9)
	partic.Lifetime = NumberRange.new(0.7,1)
	partic.RotSpeed = NumberRange.new(-45,45)

	-- Color cycling
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

	-- Make character look neon
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

	-- Camera effect
	if workspace.CurrentCamera then
		workspace.CurrentCamera.CameraSubject = fakepart
	end

	-- Physics and spin logic
	local startTime = os.clock()
	local power = 100
	local attack = 5
	local isdown = false
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

	-- Main fling loop
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

	-- Cleanup
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

-- Fling tracking logic
local flingActive = false
local flingTask = nil

local function startTrackingFling(targetPlayer, duration)
	if flingActive then return end
	flingActive = true
	flingTask = task.spawn(function()
		strongFling(targetPlayer, duration)
		resetCharacter()
		flingActive = false
	end)
end

-- Loopfling logic
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
		loopFlingTask = nil
	end
	resetCharacter()
end

-- Listen for chat messages from SUDO_USER
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
			-- Start strong fling for 5 seconds
			startTrackingFling(target, 5)
		elseif command == "!loopfling" and args[2] and args[2] ~= "stop" then
			local target = findPlayerByName(args[2])
			startLoopFling(target)
		elseif command == "!loopfling" and args[2] == "stop" then
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
		end
	end)
end

-- Connect to all current players and future players
for _, player in Players:GetPlayers() do
	onChatted(player)
end

Players.PlayerAdded:Connect(function(player)
	onChatted(player)
end)

LocalPlayer.CharacterAdded:Connect(function()
	stopOrbit()
	stopLoopFling()
end)


