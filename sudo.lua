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

-- Strong Fling Logic (uses repeat-loop from user sample)
local function strongFling(target, duration)
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
	local hrp = character.HumanoidRootPart
	local targetHRP = target.Character.HumanoidRootPart

	-- Create BodyThrust
	local thrust = hrp:FindFirstChild("YeetForce") or Instance.new('BodyThrust', hrp)
	thrust.Force = Vector3.new(99999,99999,99999)
	thrust.Name = "YeetForce"
	thrust.Location = targetHRP.Position

	-- Create fake part for visual effect
	local fakepart = Instance.new("Part", workspace)
	fakepart.Anchored = true
	fakepart.Size = Vector3.new(5,5,5)
	fakepart.Position = hrp.Position
	fakepart.CanCollide = false
	fakepart.Transparency = 0.5
	fakepart.Material = Enum.Material.ForceField

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

	-- Fling loop
	local startTime = os.clock()
	repeat
		if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then break end
		if not character or not hrp then break end
		targetHRP = target.Character.HumanoidRootPart
		hrp.CFrame = targetHRP.CFrame
		thrust.Location = targetHRP.Position
		hrp.AssemblyAngularVelocity = Vector3.new(math.random(-2000,2000),math.random(-2000,2000),math.random(-2000,2000))
		hrp.AssemblyLinearVelocity = Vector3.new(math.random(-250,250),math.random(-500,500),math.random(-250,250))
		fakepart.Position = targetHRP.Position
		fakepart.Rotation = hrp.Rotation
		task.wait(0.05)
	until os.clock() - startTime > duration or not target.Character:FindFirstChild("Head")

	-- Cleanup
	if fakepart then
		fakepart:Destroy()
	end
	if thrust and thrust.Parent then
		thrust:Destroy()
	end
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

