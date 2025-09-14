pcall(function()
    repeat wait() until game:IsLoaded()
    
    -- Services
    local TeleportService = cloneref(game:GetService("TeleportService"))
    local Players = game:GetService("Players")
    local GuiService = cloneref(game:GetService("GuiService"))
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    
    -- Variables
    local placeId = game.PlaceId
    local plr = Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoidRootPart, humanoid
    
    -- Persistent data (survives death)
    if not _G.MM2BallCollectorData then
        _G.MM2BallCollectorData = {
            ballsCollected = 0,
            farmingStartTime = tick(),
            enabled = true,
            farmingSpeed = 2, -- 1 = slow, 2 = medium, 3 = fast
            collectedBalls = {} -- Track collected balls to prevent double counting
        }
    end
    
    local data = _G.MM2BallCollectorData
    
    -- Configuration based on farming speed
    local speedConfigs = {
        [1] = {flySpeed = 25, waitAfterCollect = 1.5, waitBetweenChecks = 2}, -- Slow
        [2] = {flySpeed = 40, waitAfterCollect = 0.8, waitBetweenChecks = 1}, -- Medium  
        [3] = {flySpeed = 60, waitAfterCollect = 0.4, waitBetweenChecks = 0.5} -- Fast
    }
    
    local config = {
        collectDistance = 120,
        underFloorOffset = -15, -- How far under the floor to stay
        safeZone = Vector3.new(132, 140, 60),
    }
    
    -- GUI Creation (persistent)
    local function createGUI()
        -- Remove old GUI if exists
        if plr.PlayerGui:FindFirstChild("MM2BallCollector") then
            plr.PlayerGui:FindFirstChild("MM2BallCollector"):Destroy()
        end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "MM2BallCollector"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = plr.PlayerGui
        
        -- Main frame
        local frame = Instance.new("Frame")
        frame.Name = "MainFrame"
        frame.Size = UDim2.new(0, 320, 0, 280)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        -- Make draggable
        local UIS = game:GetService("UserInputService")
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 25)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        title.BorderSizePixel = 0
        title.Text = "MM2 Ball Collector v2.0"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextScaled = true
        title.Font = Enum.Font.SourceSansBold
        title.Parent = frame
        
        -- Ball counter
        local ballLabel = Instance.new("TextLabel")
        ballLabel.Name = "BallCounter"
        ballLabel.Size = UDim2.new(1, -20, 0, 20)
        ballLabel.Position = UDim2.new(0, 10, 0, 35)
        ballLabel.BackgroundTransparency = 1
        ballLabel.Text = "Мячиков собрано: " .. data.ballsCollected
        ballLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        ballLabel.TextScaled = true
        ballLabel.Font = Enum.Font.SourceSansBold
        ballLabel.Parent = frame
        
        -- Farming timer
        local timerLabel = Instance.new("TextLabel")
        timerLabel.Name = "Timer"
        timerLabel.Size = UDim2.new(1, -20, 0, 18)
        timerLabel.Position = UDim2.new(0, 10, 0, 58)
        timerLabel.BackgroundTransparency = 1
        timerLabel.Text = "Время фарма: 0:00"
        timerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        timerLabel.TextScaled = true
        timerLabel.Font = Enum.Font.SourceSans
        timerLabel.Parent = frame
        
        -- Status label
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "Status"
        statusLabel.Size = UDim2.new(1, -20, 0, 20)
        statusLabel.Position = UDim2.new(0, 10, 0, 80)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "Статус: Инициализация..."
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.TextScaled = true
        statusLabel.Font = Enum.Font.SourceSans
        statusLabel.Parent = frame
        
        -- Toggle button
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "ToggleButton"
        toggleButton.Size = UDim2.new(0.48, -5, 0, 25)
        toggleButton.Position = UDim2.new(0, 10, 0, 105)
        toggleButton.BackgroundColor3 = data.enabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        toggleButton.BorderSizePixel = 0
        toggleButton.Text = data.enabled and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН"
        toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.TextScaled = true
        toggleButton.Font = Enum.Font.SourceSansBold
        toggleButton.Parent = frame
        
        toggleButton.MouseButton1Click:Connect(function()
            data.enabled = not data.enabled
            toggleButton.BackgroundColor3 = data.enabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
            toggleButton.Text = data.enabled and "ВКЛЮЧЕН" or "ВЫКЛЮЧЕН"
        end)
        
        -- Reset counter button
        local resetButton = Instance.new("TextButton")
        resetButton.Size = UDim2.new(0.48, -5, 0, 25)
        resetButton.Position = UDim2.new(0.52, 0, 0, 105)
        resetButton.BackgroundColor3 = Color3.fromRGB(150, 75, 0)
        resetButton.BorderSizePixel = 0
        resetButton.Text = "СБРОС"
        resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        resetButton.TextScaled = true
        resetButton.Font = Enum.Font.SourceSansBold
        resetButton.Parent = frame
        
        resetButton.MouseButton1Click:Connect(function()
            data.ballsCollected = 0
            data.collectedBalls = {}
            data.farmingStartTime = tick()
            ballLabel.Text = "Мячиков собрано: 0"
        end)
        
        -- Speed control label
        local speedLabel = Instance.new("TextLabel")
        speedLabel.Size = UDim2.new(1, -20, 0, 18)
        speedLabel.Position = UDim2.new(0, 10, 0, 140)
        speedLabel.BackgroundTransparency = 1
        speedLabel.Text = "Скорость фарма:"
        speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        speedLabel.TextScaled = true
        speedLabel.Font = Enum.Font.SourceSans
        speedLabel.Parent = frame
        
        -- Speed buttons
        local speedTexts = {"МЕДЛЕННО", "СРЕДНЕ", "БЫСТРО"}
        local speedColors = {Color3.fromRGB(0, 150, 0), Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 0, 0)}
        
        for i = 1, 3 do
            local speedButton = Instance.new("TextButton")
            speedButton.Size = UDim2.new(0.31, -3, 0, 25)
            speedButton.Position = UDim2.new((i-1) * 0.33 + 0.02, 0, 0, 165)
            speedButton.BackgroundColor3 = data.farmingSpeed == i and speedColors[i] or Color3.fromRGB(70, 70, 70)
            speedButton.BorderSizePixel = 0
            speedButton.Text = speedTexts[i]
            speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            speedButton.TextScaled = true
            speedButton.Font = Enum.Font.SourceSansBold
            speedButton.Parent = frame
            
            speedButton.MouseButton1Click:Connect(function()
                data.farmingSpeed = i
                -- Update all speed buttons
                for j = 1, 3 do
                    local btn = frame:FindFirstChild("SpeedButton" .. j)
                    if btn then
                        btn.BackgroundColor3 = data.farmingSpeed == j and speedColors[j] or Color3.fromRGB(70, 70, 70)
                    end
                end
                speedButton.BackgroundColor3 = speedColors[i]
            end)
            
            speedButton.Name = "SpeedButton" .. i
        end
        
        -- Instructions
        local instructions = Instance.new("TextLabel")
        instructions.Size = UDim2.new(1, -20, 0, 60)
        instructions.Position = UDim2.new(0, 10, 0, 200)
        instructions.BackgroundTransparency = 1
        instructions.Text = "Полёт под полом для безопасности\nШифт 3 сек = стоп\nПеретащите окно за заголовок\n\nСделано для MM2 🏀"
        instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
        instructions.TextScaled = true
        instructions.Font = Enum.Font.SourceSans
        instructions.Parent = frame
        
        return screenGui, ballLabel, statusLabel, timerLabel
    end
    
    -- Create GUI
    local gui, ballCounterLabel, statusLabel, timerLabel = createGUI()
    
    -- Function to update GUI
    local function updateGUI(status)
        if ballCounterLabel then
            ballCounterLabel.Text = "Мячиков собрано: " .. data.ballsCollected
        end
        if statusLabel then
            statusLabel.Text = "Статус: " .. status
        end
        if timerLabel then
            local elapsed = tick() - data.farmingStartTime
            local minutes = math.floor(elapsed / 60)
            local seconds = math.floor(elapsed % 60)
            timerLabel.Text = string.format("Время фарма: %d:%02d", minutes, seconds)
        end
    end
    
    -- Character setup with proper under-floor positioning
    local function setupCharacter()
        char = plr.Character or plr.CharacterAdded:Wait()
        humanoidRootPart = char:WaitForChild("HumanoidRootPart")
        humanoid = char:WaitForChild("Humanoid")
        
        wait(1) -- Wait for character to fully load
        
        -- Set up character to be under the floor
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        
        -- Position character well under the floor
        local underFloorPos = Vector3.new(config.safeZone.X, config.safeZone.Y + config.underFloorOffset, config.safeZone.Z)
        humanoidRootPart.CFrame = CFrame.new(underFloorPos)
        
        -- Make character invisible and non-collidable
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                if part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0.8 -- Semi-transparent
                end
            end
        end
        
        updateGUI("Персонаж настроен под полом")
    end
    
    setupCharacter()
    
    -- Character respawn handler
    plr.CharacterAdded:Connect(function()
        wait(2)
        setupCharacter()
        if not plr.PlayerGui:FindFirstChild("MM2BallCollector") then
            gui, ballCounterLabel, statusLabel, timerLabel = createGUI()
        end
    end)
    
    -- Anti-idle setup
    local GC = getconnections or get_signal_cons
    if GC then
        for _, v in pairs(GC(plr.Idled)) do
            if v.Disable then
                v:Disable()
            elseif v.Disconnect then
                v:Disconnect()
            end
        end
    else
        local vu = cloneref(game:GetService("VirtualUser"))
        plr.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
    
    -- Map detection
    local map = nil
    game.Workspace.DescendantAdded:Connect(function(m)
        if m:IsA("Model") and m:GetAttribute("MapID") then
            map = m
            -- Clear collected balls list for new round
            data.collectedBalls = {}
            updateGUI("Карта обнаружена: " .. m.Name)
        end
    end)
    
    game.Workspace.DescendantRemoving:Connect(function(m)
        if m == map then
            map = nil
            updateGUI("Карта удалена, ожидание...")
        end
    end)
    
    -- Smooth flying function with under-floor movement to collect balls
    local currentTween = nil
    local function smoothFlyTo(targetPosition, callback)
        if not char or not humanoidRootPart or not humanoidRootPart.Parent then return end
        
        if currentTween then
            currentTween:Cancel()
        end
        
        local currentConfig = speedConfigs[data.farmingSpeed]
        
        -- Position directly under the ball for optimal collection
        -- Make sure we're close enough to touch the ball from below
        local underBallTarget = Vector3.new(targetPosition.X, targetPosition.Y - 8, targetPosition.Z)
        
        local distance = (humanoidRootPart.Position - underBallTarget).Magnitude
        local tweenTime = math.max(distance / currentConfig.flySpeed, 0.3)
        
        local tweenInfo = TweenInfo.new(
            tweenTime,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.InOut
        )
        
        local tween = TweenService:Create(
            humanoidRootPart,
            tweenInfo,
            {CFrame = CFrame.new(underBallTarget)}
        )
        
        currentTween = tween
        tween:Play()
        
        local completed = false
        tween.Completed:Connect(function()
            completed = true
            if callback then callback() end
        end)
        
        -- Wait with timeout
        local startTime = tick()
        while not completed and tick() - startTime < tweenTime + 2 do
            wait(0.05)
        end
        
        currentTween = nil
    end
    
    -- Improved ball detection and collection with double-counting prevention
    local function findAndCollectBalls()
        if not map or not map:FindFirstChild("CoinContainer") then
            return false
        end
        
        local currentConfig = speedConfigs[data.farmingSpeed]
        
        for _, coin in ipairs(map:FindFirstChild("CoinContainer"):GetChildren()) do
            if coin:IsA("BasePart") and coin.Name == "Coin_Server" then
                local coinID = coin:GetAttribute("CoinID")
                if coinID and (coinID == "BeachBall" or coinID:lower():find("ball")) then
                    -- Prevent double counting - check if already collected
                    local coinKey = coin:GetDebugId() or tostring(coin)
                    if data.collectedBalls[coinKey] then
                        continue -- Skip already collected balls
                    end
                    
                    -- Check if ball is visible/collectable
                    local coinVisual = coin:FindFirstChild("CoinVisual")
                    local isVisible = not coinVisual or coinVisual.Transparency < 1
                    
                    if isVisible and coin.CanCollide == false then
                        local distance = (humanoidRootPart.Position - coin.Position).Magnitude
                        if distance <= config.collectDistance then
                            updateGUI("Лечу к мячику... (" .. math.floor(distance) .. "м)")
                            
                            -- Mark as being collected before flying to prevent double collection
                            data.collectedBalls[coinKey] = true
                            
                            -- Fly directly under the ball for collection
                            smoothFlyTo(coin.Position, function()
                                -- Position exactly under the ball and touch it
                                if coin and coin.Parent then
                                    -- Move closer to the ball for better collection
                                    local ballPos = coin.Position
                                    local touchPos = Vector3.new(ballPos.X, ballPos.Y - 6, ballPos.Z)
                                    humanoidRootPart.CFrame = CFrame.new(touchPos)
                                    wait(0.1)
                                    
                                    -- Multiple touch attempts from directly below
                                    for i = 1, 5 do
                                        pcall(function()
                                            firetouchinterest(humanoidRootPart, coin, 0)
                                            firetouchinterest(humanoidRootPart, coin, 1)
                                        end)
                                        wait(0.05)
                                        
                                        -- Check if coin was collected (removed from workspace)
                                        if not coin.Parent then
                                            break
                                        end
                                    end
                                    
                                    data.ballsCollected = data.ballsCollected + 1
                                    updateGUI("Мячик собран! Всего: " .. data.ballsCollected)
                                end
                            end)
                            
                            -- Wait based on farming speed to prevent Invalid Position kicks
                            wait(currentConfig.waitAfterCollect)
                            return true -- Found and collected a ball
                        end
                    end
                end
            end
        end
        
        return false -- No balls found
    end
    
    -- Emergency stop with better input handling
    local shiftPressed = false
    local shiftStartTime = 0
    
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftShift then
            shiftPressed = true
            shiftStartTime = tick()
        end
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.LeftShift then
            shiftPressed = false
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        if shiftPressed and tick() - shiftStartTime >= 3 then
            updateGUI("СКРИПТ ОСТАНОВЛЕН ПОЛЬЗОВАТЕЛЕМ")
            if currentTween then currentTween:Cancel() end
            error("Script stopped by user")
        end
    end)
    
    -- Load anti-fling protection
    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/Linux6699/DaHubRevival/main/AntiFling.lua'))()
        end)
    end)
    
    updateGUI("Скрипт инициализирован! Ожидание карты...")
    
    -- Main loop
    while true do
        if data.enabled then
            -- Check character validity
            if not char or not humanoidRootPart or not humanoidRootPart.Parent then
                updateGUI("Ожидание персонажа...")
                wait(1)
                continue
            end
            
            -- Wait for map (no more pre-round teleportation)
            if not map or not map:FindFirstChild("CoinContainer") then
                updateGUI("Ожидание начала раунда...")
                wait(2)
                continue
            end
            
            -- Collect balls
            local foundBall = findAndCollectBalls()
            local currentConfig = speedConfigs[data.farmingSpeed]
            
            if not foundBall then
                -- Return to safe zone under floor
                local safePos = Vector3.new(config.safeZone.X, config.safeZone.Y + config.underFloorOffset, config.safeZone.Z)
                local distanceToSafe = (humanoidRootPart.Position - safePos).Magnitude
                if distanceToSafe > 20 then
                    updateGUI("Возвращаюсь в безопасную зону...")
                    smoothFlyTo(config.safeZone)
                else
                    updateGUI("Нет мячиков поблизости, жду...")
                end
                wait(currentConfig.waitBetweenChecks)
            end
        else
            updateGUI("Скрипт выключен через интерфейс")
            wait(2)
        end
        
        -- Small delay to prevent too frequent loops
        wait(0.1)
    end
end)
