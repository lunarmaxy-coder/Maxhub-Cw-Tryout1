--[[
╔══════════════════════════════════════════════════════╗
║         PROJECT MUGETSU — ALL IN ONE SCRIPT          ║
║         Delta Executor Ready (Android/iOS)           ║
║         RE Source: MaxHub Sample 3 (98% recovered)  ║
╠══════════════════════════════════════════════════════╣
║  FITUR:                                              ║
║  [1] Auto Parry    (Animation + Sound detection)     ║
║  [2] Kill Aura     (VIM / Remote method)             ║
║  [3] Hitbox        (Torso + Weapon expander)         ║
║  [4] Player        (Speed, Fly, SuperJump)           ║
║  [5] Blatant       (No Ragdoll, No Stun, etc)        ║
║  [6] Infinite Stamina                                ║
║  [7] No Fall Damage                                  ║
║  [8] ESP           (Names, Box, HP, Distance)        ║
║  [9] Chams         (Through-wall highlight)          ║
╠══════════════════════════════════════════════════════╣
║  KEYBINDS:                                           ║
║  ]  = Auto Parry ON/OFF                              ║
║  K  = Kill Aura ON/OFF                               ║
║  M  = Kill Aura Method (VIM ↔ Remote)               ║
║  H  = Torso Hitbox Expander ON/OFF                   ║
║  J  = Melee/Weapon Extender ON/OFF                   ║
║  G  = Speed Hack ON/OFF                              ║
║  F  = Fly ON/OFF                                     ║
║  T  = Super Jump ON/OFF                              ║
║  I  = Infinite Stamina ON/OFF                        ║
║  N  = No Ragdoll + No Stun + No FallDmg ON/OFF       ║
║  E  = ESP ON/OFF                                     ║
║  C  = Chams ON/OFF                                   ║
║  P  = PANIC — Matikan SEMUA sekaligus                ║
╚══════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════════════════
--                  KONFIGURASI UTAMA
--   Edit nilai di bawah sesuai kebutuhan sebelum run
-- ═══════════════════════════════════════════════════════
local CFG = {
    -- AUTO PARRY
    Parry_Enabled        = true,
    Parry_Distance       = 18,     -- studs (default MaxHub: 18)
    Parry_Chance         = 100,    -- % (100 = selalu parry)
    Parry_Cooldown       = 0,      -- detik antar parry (0 = tidak ada)
    Parry_Timing         = 0.3,    -- window waktu parry (detik)
    Parry_Invisible      = false,  -- sembunyikan animasi parry
    Parry_DetectAnim     = true,   -- deteksi via animasi
    Parry_DetectSound    = true,   -- deteksi via suara serangan

    -- KILL AURA
    KillAura_Enabled     = false,  -- default OFF (tekan K untuk ON)
    KillAura_Method      = "VIM",  -- "VIM" (aman) atau "Remote" (kuat)
    KillAura_Distance    = 6,      -- studs
    KillAura_Delay       = 0.1,    -- detik antar serangan
    KillAura_TeamCheck   = true,   -- skip teman satu tim

    -- HITBOX
    Torso_Enabled        = false,
    Torso_Size           = 6,      -- default MaxHub: 6
    Melee_Enabled        = false,
    Melee_Size           = 7,      -- default MaxHub: 7
    Melee_ShowDmgPts     = false,

    -- PLAYER MOVEMENT
    Speed_Enabled        = false,
    WalkSpeed            = 17,     -- default MaxHub: 17 (vanilla: 16)
    Fly_Enabled          = false,
    FlySpeed             = 50,
    Jump_Enabled         = false,
    JumpHeight           = 150,    -- default MaxHub: 150
    NoDashCD             = false,
    NoJumpCD             = false,

    -- BLATANT / PROTECTION
    NoRagdoll            = false,
    NoParryStun          = false,
    NoExplosiveKB        = false,
    WalkOnWater          = false,
    NoFallDamage         = false,
    InfStamina           = false,
    AutoRespawn          = false,

    -- ESP
    ESP_Enabled          = true,
    ESP_TeamCheck        = false,
    ESP_MaxDist          = 200,
    ESP_FontSize         = 14,
    ESP_BoxStyle         = "Corner",  -- "Corner" atau "Full"
    ESP_BoxColor         = Color3.fromRGB(255, 60, 60),
    ESP_NameColor        = Color3.fromRGB(255, 255, 255),
    ESP_DistColor        = Color3.fromRGB(200, 200, 200),
    ESP_WeaponColor      = Color3.fromRGB(255, 200, 50),
    ESP_Names            = true,
    ESP_Distance         = true,
    ESP_Healthbar        = true,
    ESP_HealthText       = true,
    ESP_Weapons          = true,
    ESP_FriendCheck      = false,
    ESP_FriendColor      = Color3.fromRGB(50, 200, 255),

    -- CHAMS
    Chams_Enabled        = false,
    Chams_FillColor      = Color3.fromRGB(255, 60, 60),
    Chams_OutlineColor   = Color3.fromRGB(255, 255, 255),
}

-- ═══════════════════════════════════════════════════════
--                     SERVICES
-- ═══════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LP       = Players.LocalPlayer
local Camera   = workspace.CurrentCamera
local Char     = LP.Character or LP.CharacterAdded:Wait()
local Hum      = Char:WaitForChild("Humanoid")
local HRP      = Char:WaitForChild("HumanoidRootPart")

-- Update karakter saat respawn
LP.CharacterAdded:Connect(function(c)
    Char = c
    Hum  = c:WaitForChild("Humanoid")
    HRP  = c:WaitForChild("HumanoidRootPart")
    -- Reset state
    _isFlying = false
    _flyBV = nil
    _flyBG = nil
    _staminaThread = nil
    _fallConn = nil
    print("[PM] Karakter respawn — re-init selesai")
    setupNoFallDamage()
    setupAutoRespawn()
end)

-- ═══════════════════════════════════════════════════════
--           MODUL 1: AUTO PARRY
-- ═══════════════════════════════════════════════════════
local _parryRemote     = nil
local _lastParry       = 0
local _parryFired      = false
local _animConns       = {}
local _soundConns      = {}

local ATTACK_ANIM_KEYS = {
    "attack","combo","swing","slash","punch",
    "strike","hit","melee","ability","dash_attack","skill"
}

local function _findParryRemote()
    local names = {"Parry","parry","DoParry","ParryAction","BlockParry","Block"}
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, n in pairs(names) do
                if v.Name:lower():find(n:lower()) then
                    print("[Parry] Remote ditemukan: " .. v:GetFullName())
                    return v
                end
            end
        end
    end
    warn("[Parry] Remote tidak ditemukan — fallback ke VirtualInputManager")
    return nil
end

local function _doParry()
    if _parryRemote then
        if _parryRemote:IsA("RemoteEvent") then
            _parryRemote:FireServer()
        else
            _parryRemote:InvokeServer()
        end
    else
        local VIM = game:GetService("VirtualInputManager")
        if VIM then
            VIM:SendKeyEvent(true,  Enum.KeyCode.Q, false, game)
            task.delay(0.05, function()
                VIM:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
            end)
        end
    end
    if CFG.Parry_Invisible then
        for _, t in pairs(Hum:GetPlayingAnimationTracks()) do
            if t.Name:lower():find("parry") or t.Name:lower():find("block") then
                t:Stop(0)
            end
        end
    end
end

local function _tryParry(reason)
    if not CFG.Parry_Enabled then return end
    if (tick() - _lastParry) < CFG.Parry_Cooldown then return end
    if _parryFired then return end
    if math.random(1, 100) > CFG.Parry_Chance then return end
    _parryFired = true
    _lastParry  = tick()
    task.delay(CFG.Parry_Timing * 0.5, function()
        _doParry()
        task.delay(CFG.Parry_Timing, function() _parryFired = false end)
    end)
end

local function _isAttackAnim(name)
    local l = name:lower()
    for _, k in pairs(ATTACK_ANIM_KEYS) do
        if l:find(k) then return true end
    end
    return false
end

local function _watchPlayer(player)
    if player == LP then return end
    local function onChar(c)
        local h  = c:WaitForChild("Humanoid", 5)
        local rp = c:WaitForChild("HumanoidRootPart", 5)
        if not h or not rp then return end
        if CFG.Parry_DetectAnim then
            local conn = h.AnimationPlayed:Connect(function(track)
                if not CFG.Parry_Enabled then return end
                if (HRP.Position - rp.Position).Magnitude > CFG.Parry_Distance then return end
                if _isAttackAnim(track.Name) then _tryParry("Anim:"..track.Name) end
            end)
            _animConns[player.UserId] = conn
        end
        if CFG.Parry_DetectSound then
            local function hookSound(s)
                if not s:IsA("Sound") then return end
                local sc = s.Played:Connect(function()
                    if not CFG.Parry_Enabled then return end
                    if (HRP.Position - rp.Position).Magnitude > CFG.Parry_Distance then return end
                    local l = s.Name:lower()
                    if l:find("attack") or l:find("swing") or l:find("hit") or l:find("combo") then
                        _tryParry("Sound:"..s.Name)
                    end
                end)
                table.insert(_soundConns, sc)
            end
            for _, v in pairs(c:GetDescendants()) do hookSound(v) end
            c.DescendantAdded:Connect(hookSound)
        end
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

-- Init parry
_parryRemote = _findParryRemote()
for _, p in pairs(Players:GetPlayers()) do _watchPlayer(p) end
Players.PlayerAdded:Connect(_watchPlayer)
Players.PlayerRemoving:Connect(function(p)
    if _animConns[p.UserId] then
        _animConns[p.UserId]:Disconnect()
        _animConns[p.UserId] = nil
    end
end)
print("[Parry] ✅ Siap. Tekan ] untuk toggle.")

-- ═══════════════════════════════════════════════════════
--           MODUL 2: KILL AURA + HITBOX
-- ═══════════════════════════════════════════════════════
local _attackRemote   = nil
local _lastAura       = 0
local _origSizes      = {}
local _origWepSizes   = {}

local function _findAttackRemote()
    local names = {
        "UseActorAbility","Attack","DealDamage","HitRemote",
        "CombatHit","MeleeHit","AbilityHit","ComboHit"
    }
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            for _, n in pairs(names) do
                if v.Name:lower():find(n:lower()) then
                    print("[Combat] Attack remote: " .. v:GetFullName())
                    return v
                end
            end
        end
    end
    warn("[Combat] Attack remote tidak ditemukan — pakai VIM fallback")
    return nil
end

local function _expandTorso(c, sz)
    local p = c:FindFirstChild("HumanoidRootPart")
    if not p then return end
    local id = tostring(c)
    if not _origSizes[id] then _origSizes[id] = p.Size end
    p.Size = Vector3.new(sz, sz, sz)
    p.Transparency = 0.85
    p.CanCollide = false
end

local function _restoreTorso(c)
    local p = c:FindFirstChild("HumanoidRootPart")
    if not p then return end
    local id = tostring(c)
    if _origSizes[id] then
        p.Size = _origSizes[id]
        _origSizes[id] = nil
    end
end

local function _attackVIM(target)
    local orig = HRP.CFrame
    HRP.CFrame = target.hrp.CFrame * CFrame.new(0, 0, -2)
    task.delay(0.04, function()
        if HRP and HRP.Parent then HRP.CFrame = orig end
    end)
end

local function _attackRemoteMethod(target)
    if _attackRemote then
        if _attackRemote:IsA("RemoteEvent") then
            _attackRemote:FireServer(target.c, target.hrp.Position)
        else
            _attackRemote:InvokeServer(target.c, target.hrp.Position)
        end
    else
        _attackVIM(target)
    end
end

local function _getEnemies()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p == LP then continue end
        if CFG.KillAura_TeamCheck and p.Team == LP.Team then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChild("Humanoid")
        local r = c:FindFirstChild("HumanoidRootPart")
        if not h or not r or h.Health <= 0 then continue end
        local d = (HRP.Position - r.Position).Magnitude
        if d <= CFG.KillAura_Distance then
            table.insert(list, {c=c, humanoid=h, hrp=r, dist=d})
        end
    end
    table.sort(list, function(a,b) return a.dist < b.dist end)
    return list
end

_attackRemote = _findAttackRemote()
print("[Combat] ✅ Siap. K=KillAura H=Hitbox J=Melee M=SwitchMethod")

-- ═══════════════════════════════════════════════════════
--           MODUL 3: PLAYER MOVEMENT + BLATANT
-- ═══════════════════════════════════════════════════════
local _isFlying   = false
local _flyBV      = nil
local _flyBG      = nil

local function _enableFly()
    _isFlying = true
    Hum.PlatformStand = true
    if not _flyBV then
        _flyBV = Instance.new("BodyVelocity")
        _flyBV.Velocity  = Vector3.zero
        _flyBV.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
        _flyBV.P         = 9999
        _flyBV.Parent    = HRP
    end
    if not _flyBG then
        _flyBG = Instance.new("BodyGyro")
        _flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        _flyBG.P         = 9999
        _flyBG.D         = 100
        _flyBG.Parent    = HRP
    end
    print("[Player] Fly ON — WASD+Space/Shift untuk gerak")
end

local function _disableFly()
    _isFlying = false
    Hum.PlatformStand = false
    if _flyBV then _flyBV:Destroy(); _flyBV = nil end
    if _flyBG then _flyBG:Destroy(); _flyBG = nil end
    print("[Player] Fly OFF")
end

local _staminaThread = nil
local function _startStamina()
    if _staminaThread then return end
    _staminaThread = task.spawn(function()
        local keys = {"Stamina","stamina","SP","Energy","energy","Reiatsu","Cursed Energy"}
        while CFG.InfStamina do
            if Char then
                for _, k in pairs(keys) do
                    local cv = Char:GetAttribute(k)
                    if cv and type(cv) == "number" then Char:SetAttribute(k, 999999) end
                    if Hum then
                        local hv = Hum:GetAttribute(k)
                        if hv and type(hv) == "number" then Hum:SetAttribute(k, 999999) end
                    end
                end
            end
            task.wait(0.05)
        end
        _staminaThread = nil
    end)
end

local _fallConn = nil
local function setupNoFallDamage()
    if _fallConn then _fallConn:Disconnect() end
    _fallConn = Hum.HealthChanged:Connect(function()
        if not CFG.NoFallDamage then return end
        task.defer(function()
            if Hum and Hum.Parent and CFG.NoFallDamage then
                Hum.Health = Hum.MaxHealth
            end
        end)
    end)
end

local function setupAutoRespawn()
    Hum.Died:Connect(function()
        if not CFG.AutoRespawn then return end
        task.delay(1, function() LP:LoadCharacter() end)
    end)
end

setupNoFallDamage()
setupAutoRespawn()
print("[Player] ✅ Siap. G=Speed F=Fly T=Jump I=Stamina N=Blatant P=PANIC")

-- ═══════════════════════════════════════════════════════
--           MODUL 4: ESP + CHAMS
-- ═══════════════════════════════════════════════════════
local _espObjs    = {}
local _highlights = {}

local function _makeESP(player)
    if player == LP then return end
    if _espObjs[player.UserId] then return end
    local o = {}
    local function txt()
        local t = Drawing.new("Text")
        t.Visible = false; t.Center = true; t.Outline = true
        t.Size = CFG.ESP_FontSize; t.Font = Drawing.Fonts.Plex
        t.Color = Color3.new(1,1,1)
        return t
    end
    local function ln()
        local l = Drawing.new("Line")
        l.Visible = false; l.Thickness = 1.5
        l.Color = CFG.ESP_BoxColor
        return l
    end
    o.name    = txt(); o.name.Color   = CFG.ESP_NameColor
    o.dist    = txt(); o.dist.Color   = CFG.ESP_DistColor; o.dist.Size = CFG.ESP_FontSize - 2
    o.weapon  = txt(); o.weapon.Color = CFG.ESP_WeaponColor; o.weapon.Size = CFG.ESP_FontSize - 2
    o.hpTxt   = txt(); o.hpTxt.Size   = CFG.ESP_FontSize - 2
    o.hpBar   = ln();  o.hpBar.Thickness = 3; o.hpBar.Color = Color3.fromRGB(100,255,100)
    o.hpBg    = ln();  o.hpBg.Thickness = 3;  o.hpBg.Color  = Color3.fromRGB(40,40,40)
    o.boxLines = {}
    for i = 1, 8 do table.insert(o.boxLines, ln()) end
    _espObjs[player.UserId] = o
end

local function _removeESP(player)
    local o = _espObjs[player.UserId]
    if not o then return end
    for k, v in pairs(o) do
        if type(v) == "table" then
            for _, l in pairs(v) do if l.Remove then l:Remove() end end
        else
            if v.Remove then v:Remove() end
        end
    end
    _espObjs[player.UserId] = nil
end

local function _hideESP(o)
    if not o then return end
    for k, v in pairs(o) do
        if type(v) == "table" then
            for _, l in pairs(v) do if l.Visible ~= nil then l.Visible = false end end
        elseif v.Visible ~= nil then
            v.Visible = false
        end
    end
end

local function _drawCorner(lines, tl, tr, bl, br)
    local cw = math.abs(tr.X - tl.X) * 0.25
    local ch = math.abs(bl.Y - tl.Y) * 0.25
    -- TL
    lines[1].From=tl; lines[1].To=tl+Vector2.new(cw,0)
    lines[2].From=tl; lines[2].To=tl+Vector2.new(0,ch)
    -- TR
    lines[3].From=tr; lines[3].To=tr-Vector2.new(cw,0)
    lines[4].From=tr; lines[4].To=tr+Vector2.new(0,ch)
    -- BL
    lines[5].From=bl; lines[5].To=bl+Vector2.new(cw,0)
    lines[6].From=bl; lines[6].To=bl-Vector2.new(0,ch)
    -- BR
    lines[7].From=br; lines[7].To=br-Vector2.new(cw,0)
    lines[8].From=br; lines[8].To=br-Vector2.new(0,ch)
    for _, l in pairs(lines) do l.Color=CFG.ESP_BoxColor; l.Visible=true end
end

local function _getWeapon(c)
    for _, v in pairs(c:GetChildren()) do
        if v:IsA("Tool") then return v.Name end
    end
    local a = c:GetAttribute("CurrentWeapon") or c:GetAttribute("Weapon")
    return a and tostring(a) or nil
end

local function _updateChams(player)
    if not CFG.Chams_Enabled then
        if _highlights[player.UserId] then
            _highlights[player.UserId]:Destroy()
            _highlights[player.UserId] = nil
        end
        return
    end
    local c = player.Character
    if not c then return end
    if not _highlights[player.UserId] then
        local h = Instance.new("SelectionBox")
        h.SurfaceTransparency = 0.7
        h.LineThickness = 0.05
        h.Color3 = CFG.Chams_FillColor
        h.SurfaceColor3 = CFG.Chams_FillColor
        h.Adornee = c
        h.Parent = workspace
        _highlights[player.UserId] = h
    end
end

-- Init ESP
for _, p in pairs(Players:GetPlayers()) do _makeESP(p) end
Players.PlayerAdded:Connect(_makeESP)
Players.PlayerRemoving:Connect(function(p)
    _removeESP(p)
    if _highlights[p.UserId] then _highlights[p.UserId]:Destroy(); _highlights[p.UserId]=nil end
end)
print("[ESP] ✅ Siap. E=ESP C=Chams")

-- ═══════════════════════════════════════════════════════
--           MAIN HEARTBEAT — Semua update tiap frame
-- ═══════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not Hum or not Char or not HRP then return end

    -- Speed
    if CFG.Speed_Enabled then Hum.WalkSpeed = CFG.WalkSpeed end

    -- Jump height
    if CFG.Jump_Enabled then
        Hum.JumpHeight = CFG.JumpHeight
        if Hum.UseJumpPower then Hum.JumpPower = CFG.JumpHeight * 0.5 end
    end

    -- Infinite Stamina
    if CFG.InfStamina and not _staminaThread then _startStamina() end

    -- Fly movement
    if _isFlying and _flyBV and _flyBG then
        local cf = Camera.CFrame
        _flyBG.CFrame = cf
        local d = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then d = d + cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then d = d - cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then d = d - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then d = d + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then d = d + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then d = d - Vector3.new(0,1,0) end
        _flyBV.Velocity = (d.Magnitude > 0 and d.Unit or d) * CFG.FlySpeed
    end

    -- No Ragdoll / No Stun
    if CFG.NoRagdoll then
        if not _isFlying then Hum.PlatformStand = false end
        if Char:GetAttribute("Ragdolled")  == true then Char:SetAttribute("Ragdolled",  false) end
    end
    if CFG.NoParryStun then
        if Char:GetAttribute("Stunned")    == true then Char:SetAttribute("Stunned",    false) end
        if Char:GetAttribute("ParryStun")  == true then Char:SetAttribute("ParryStun",  false) end
    end
    if CFG.NoExplosiveKB then
        if Char:GetAttribute("Knockback") ~= nil then Char:SetAttribute("Knockback", Vector3.zero) end
    end

    -- No Dash/Jump Cooldown
    if CFG.NoDashCD then
        for _, k in pairs({"DashCooldown","dashCooldown","DashCD"}) do
            if Char:GetAttribute(k) ~= nil then Char:SetAttribute(k, 0) end
        end
    end
    if CFG.NoJumpCD then
        for _, k in pairs({"JumpCooldown","jumpCooldown","JumpCD"}) do
            if Char:GetAttribute(k) ~= nil then Char:SetAttribute(k, 0) end
        end
    end

    -- Kill Aura
    if CFG.KillAura_Enabled then
        local now = tick()
        if (now - _lastAura) >= CFG.KillAura_Delay then
            _lastAura = now
            local enemies = _getEnemies()
            if #enemies > 0 then
                local t = enemies[1]
                if CFG.KillAura_Method == "VIM" then _attackVIM(t)
                else _attackRemoteMethod(t) end
            end
        end
    end

    -- Torso Hitbox
    if CFG.Torso_Enabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                _expandTorso(p.Character, CFG.Torso_Size)
            end
        end
    end

    -- Melee Extender (weapon hitbox)
    if CFG.Melee_Enabled and Char then
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart"
               and v.Name ~= "Head" and not v.Name:find("Arm")
               and not v.Name:find("Leg") and not v.Name:find("Torso") then
                local id = v:GetFullName()
                if not _origWepSizes[id] then _origWepSizes[id] = v.Size end
                if v.Size.Magnitude < CFG.Melee_Size then
                    v.Size = Vector3.new(CFG.Melee_Size, v.Size.Y, CFG.Melee_Size)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════
--           ESP RENDER LOOP
-- ═══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local localHRP = Char and Char:FindFirstChild("HumanoidRootPart")

    for _, player in pairs(Players:GetPlayers()) do
        if player == LP then continue end

        if CFG.ESP_TeamCheck and player.Team == LP.Team then
            _hideESP(_espObjs[player.UserId]); continue
        end

        local c = player.Character
        if not c then _hideESP(_espObjs[player.UserId]); continue end

        local hum = c:FindFirstChild("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local head = c:FindFirstChild("Head")
        if not hum or not hrp or not head or hum.Health <= 0 then
            _hideESP(_espObjs[player.UserId]); continue
        end

        local dist = localHRP and (localHRP.Position - hrp.Position).Magnitude or 0
        if dist > CFG.ESP_MaxDist then
            _hideESP(_espObjs[player.UserId]); continue
        end

        if not _espObjs[player.UserId] then _makeESP(player) end
        local o = _espObjs[player.UserId]
        if not o then continue end

        local hp, hOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local fp, fOnScreen = Camera:WorldToViewportPoint(hrp.Position  - Vector3.new(0, 3, 0))

        if not hOnScreen then _hideESP(o); continue end

        local hs = Vector2.new(hp.X, hp.Y)
        local fs = Vector2.new(fp.X, fp.Y)
        local bh = (fs - hs).Magnitude
        local bw = bh * 0.45

        local espCol = LP:IsFriendsWith(player.UserId) and CFG.ESP_FriendColor or CFG.ESP_BoxColor

        if not CFG.ESP_Enabled then _hideESP(o); _updateChams(player); continue end

        -- Box
        _drawCorner(o.boxLines,
            Vector2.new(hs.X-bw, hs.Y), Vector2.new(hs.X+bw, hs.Y),
            Vector2.new(fs.X-bw, fs.Y), Vector2.new(fs.X+bw, fs.Y))
        for _, l in pairs(o.boxLines) do l.Color = espCol end

        -- Name
        o.name.Text = player.Name
        o.name.Position = Vector2.new(hs.X, hs.Y - 16)
        o.name.Color = espCol
        o.name.Visible = CFG.ESP_Names

        -- Distance
        o.dist.Text = string.format("[%.0f]", dist)
        o.dist.Position = Vector2.new(fs.X, fs.Y + 2)
        o.dist.Visible = CFG.ESP_Distance

        -- Weapon
        local wep = _getWeapon(c)
        o.weapon.Text = wep and ("⚔ " .. wep) or ""
        o.weapon.Position = Vector2.new(fs.X, fs.Y + 14)
        o.weapon.Visible = CFG.ESP_Weapons and (wep ~= nil)

        -- Healthbar
        local hpR  = hum.Health / hum.MaxHealth
        local hpC  = Color3.fromRGB(math.floor((1-hpR)*255), math.floor(hpR*255), 0)
        o.hpBg.From = Vector2.new(hs.X - bw - 7, hs.Y)
        o.hpBg.To   = Vector2.new(fs.X - bw - 7, fs.Y)
        o.hpBg.Visible = CFG.ESP_Healthbar
        o.hpBar.From = Vector2.new(hs.X - bw - 7, hs.Y)
        o.hpBar.To   = Vector2.new(fs.X - bw - 7, hs.Y + (fs.Y - hs.Y) * hpR)
        o.hpBar.Color = hpC
        o.hpBar.Visible = CFG.ESP_Healthbar
        o.hpTxt.Text = string.format("%.0f", hum.Health)
        o.hpTxt.Position = Vector2.new(hs.X - bw - 7, hs.Y - 13)
        o.hpTxt.Color = hpC
        o.hpTxt.Visible = CFG.ESP_Healthbar and CFG.ESP_HealthText

        -- Chams
        _updateChams(player)
    end
end)

-- ═══════════════════════════════════════════════════════
--           KEYBINDS TERPUSAT
-- ═══════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local k = input.KeyCode

    if k == Enum.KeyCode.RightBracket then     -- ] = Auto Parry
        CFG.Parry_Enabled = not CFG.Parry_Enabled
        print("[PM] Auto Parry: " .. (CFG.Parry_Enabled and "ON ✅" or "OFF ❌"))

    elseif k == Enum.KeyCode.K then            -- K = Kill Aura
        CFG.KillAura_Enabled = not CFG.KillAura_Enabled
        print("[PM] Kill Aura: " .. (CFG.KillAura_Enabled and "ON ✅ ["..CFG.KillAura_Method.."]" or "OFF ❌"))

    elseif k == Enum.KeyCode.M then            -- M = Switch Method
        CFG.KillAura_Method = CFG.KillAura_Method == "VIM" and "Remote" or "VIM"
        print("[PM] Kill Aura Method: " .. CFG.KillAura_Method)

    elseif k == Enum.KeyCode.H then            -- H = Torso Hitbox
        CFG.Torso_Enabled = not CFG.Torso_Enabled
        if not CFG.Torso_Enabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then _restoreTorso(p.Character) end
            end
        end
        print("[PM] Torso Hitbox: " .. (CFG.Torso_Enabled and "ON ✅ [size="..CFG.Torso_Size.."]" or "OFF ❌"))

    elseif k == Enum.KeyCode.J then            -- J = Melee Extender
        CFG.Melee_Enabled = not CFG.Melee_Enabled
        print("[PM] Melee Extender: " .. (CFG.Melee_Enabled and "ON ✅ [size="..CFG.Melee_Size.."]" or "OFF ❌"))

    elseif k == Enum.KeyCode.G then            -- G = Speed
        CFG.Speed_Enabled = not CFG.Speed_Enabled
        if not CFG.Speed_Enabled then Hum.WalkSpeed = 16 end
        print("[PM] Speed: " .. (CFG.Speed_Enabled and "ON ✅ ["..CFG.WalkSpeed.."]" or "OFF ❌"))

    elseif k == Enum.KeyCode.F then            -- F = Fly
        CFG.Fly_Enabled = not CFG.Fly_Enabled
        if CFG.Fly_Enabled then _enableFly() else _disableFly() end

    elseif k == Enum.KeyCode.T then            -- T = Super Jump
        CFG.Jump_Enabled = not CFG.Jump_Enabled
        if not CFG.Jump_Enabled then Hum.JumpHeight = 7.2 end
        print("[PM] Super Jump: " .. (CFG.Jump_Enabled and "ON ✅ [height="..CFG.JumpHeight.."]" or "OFF ❌"))

    elseif k == Enum.KeyCode.I then            -- I = Inf Stamina
        CFG.InfStamina = not CFG.InfStamina
        print("[PM] Infinite Stamina: " .. (CFG.InfStamina and "ON ✅" or "OFF ❌"))

    elseif k == Enum.KeyCode.N then            -- N = Blatant bundle
        local s = not CFG.NoRagdoll
        CFG.NoRagdoll = s; CFG.NoParryStun = s
        CFG.NoFallDamage = s; CFG.NoExplosiveKB = s
        print("[PM] No Ragdoll/Stun/FallDmg/ExpKB: " .. (s and "ON ✅" or "OFF ❌"))

    elseif k == Enum.KeyCode.E then            -- E = ESP
        CFG.ESP_Enabled = not CFG.ESP_Enabled
        print("[PM] ESP: " .. (CFG.ESP_Enabled and "ON ✅" or "OFF ❌"))

    elseif k == Enum.KeyCode.C then            -- C = Chams
        CFG.Chams_Enabled = not CFG.Chams_Enabled
        if not CFG.Chams_Enabled then
            for uid, h in pairs(_highlights) do h:Destroy(); _highlights[uid]=nil end
        end
        print("[PM] Chams: " .. (CFG.Chams_Enabled and "ON ✅" or "OFF ❌"))

    elseif k == Enum.KeyCode.LeftAlt then      -- LeftAlt = Super Jump trigger
        if CFG.Jump_Enabled and Hum then
            Hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end

    elseif k == Enum.KeyCode.P then            -- P = PANIC — matikan semua
        CFG.Parry_Enabled   = false
        CFG.KillAura_Enabled = false
        CFG.Torso_Enabled   = false
        CFG.Melee_Enabled   = false
        CFG.Speed_Enabled   = false
        CFG.Jump_Enabled    = false
        CFG.InfStamina      = false
        CFG.NoRagdoll       = false
        CFG.NoParryStun     = false
        CFG.NoFallDamage    = false
        CFG.NoExplosiveKB   = false
        CFG.ESP_Enabled     = false
        CFG.Chams_Enabled   = false
        if _isFlying then _disableFly() end
        CFG.Fly_Enabled     = false
        Hum.WalkSpeed       = 16
        Hum.JumpHeight      = 7.2
        for uid, h in pairs(_highlights) do h:Destroy(); _highlights[uid]=nil end
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then _restoreTorso(p.Character) end
        end
        warn("[PM] ⚠ PANIC — SEMUA FITUR DIMATIKAN")
    end
end)

-- ═══════════════════════════════════════════════════════
--           SELESAI
-- ═══════════════════════════════════════════════════════
print("╔══════════════════════════════════╗")
print("║  PM ALL-IN-ONE — LOADED ✅       ║")
print("╠══════════════════════════════════╣")
print("║  ] = Auto Parry                  ║")
print("║  K = Kill Aura  M = Switch Method║")
print("║  H = Hitbox     J = Melee        ║")
print("║  G = Speed      F = Fly          ║")
print("║  T = SuperJump  I = Stamina      ║")
print("║  N = NoBlatant  E = ESP          ║")
print("║  C = Chams      P = PANIC OFF    ║")
print("╚══════════════════════════════════╝")
