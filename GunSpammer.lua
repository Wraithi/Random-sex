local plr=game.Players.LocalPlayer
local char=plr.Character or plr.CharacterAdded:Wait()
local hum=char:WaitForChild("Humanoid")
local RS=game:GetService("ReplicatedStorage")
local RunS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local WS=game:GetService("Workspace")
local SG=game:GetService("StarterGui")
local GunRemote=RS:WaitForChild("GunEvents"):WaitForChild("FireGun")
SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)

local cfg={
    spamEnabled=false,waveDur=3,spamDelay=0.3,
    autoCure=false,autoSave=false,
    aimbot=false,aimPart="Head",wallCheck=true,prediction=true,
    noRecoil=false,horizOnly=false,smoothing=0.15,fov=120,predMult=1.8,
    esp=false,espNames=true,espHP=true,espDist=true,espBoxes=true,
    hotbarLocked=false
}
local TARGET="IoIPopNoob"
local slot1Name=nil
local SPAM_TOOLS={"WORM BLASTER","ULTRA WORM BLASTER","RPG","MODDED RPG"}
local SLOT2={"ULTRA WORM SLAYER","WORM SLAYER"}
local SLOT3={"ULTRA WORM ERADICATOR","WORM ERADICATOR"}
local W1={vector.create(138,1.24,-115.7),441,200,vector.create(36.6,19.5,-107.99),true,true,20,146,440,Color3.new(1,0.6,0.25)}
local W2={vector.create(-275.79,2.18,-308.9),441,200,vector.create(-208.78,15.87,-308.24),true,true,20,146,440,Color3.new(1,0.6,0.25)}
local W3={vector.create(-245.4,-79.3,-131.4),441,200,vector.create(-178.13,-70.42,-127.2),true,true,20,146,440,Color3.new(1,0.6,0.25)}

local function getTool(n) return plr.Backpack:FindFirstChild(n) or char:FindFirstChild(n) end
local function equip(n) local t=getTool(n) if t then hum:EquipTool(t) end end
local function unequipCurrent() hum:UnequipTools() end
local function hp() return (hum.Health/hum.MaxHealth)*100 end
local function targetChar() local p=game.Players:FindFirstChild(TARGET) return p and p.Character end
local function hasWormSound(c) if not c then return false end local t=c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") return t and t:FindFirstChild("WormSound")~=nil end
local function findVariant(t) for _,n in ipairs(t) do local f=getTool(n) if f then return f end end end

plr.CharacterAdded:Connect(function(nc)
    char=nc hum=nc:WaitForChild("Humanoid")
    SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
end)

-- ══════════════════════════════════════
--   3 SEPARATE SLOT GUIs
--   Centered at bottom like Roblox hotbar
--   ⠿ drag handle on bottom-left of each slot
--   Tap active slot again = unequip
-- ══════════════════════════════════════
local slotGuis={}
local slotLockedPositions={}

-- Slot 1 left, Slot 2 center, Slot 3 right — 96px spacing, anchored bottom-center
local defaultPositions={
    UDim2.new(0.5,-144,1,-8),
    UDim2.new(0.5,-48,1,-8),
    UDim2.new(0.5,48,1,-8),
}

local function makeSlotGui(index)
    local sg=Instance.new("ScreenGui")
    sg.Name="Slot"..index sg.ResetOnSpawn=false sg.DisplayOrder=15
    sg.Parent=plr:WaitForChild("PlayerGui")

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,90,0,80)
    btn.Position=defaultPositions[index]
    btn.AnchorPoint=Vector2.new(0,1)
    btn.BackgroundColor3=Color3.fromRGB(25,25,30)
    btn.BackgroundTransparency=0.15
    btn.TextColor3=Color3.new(1,1,1)
    btn.TextWrapped=true btn.TextSize=10
    btn.Font=Enum.Font.GothamBold
    btn.Text="Empty" btn.BorderSizePixel=0 btn.ZIndex=5
    btn.Parent=sg
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,12)
    local stroke=Instance.new("UIStroke",btn)
    stroke.Color=Color3.fromRGB(80,80,100) stroke.Thickness=1.2

    -- Slot number badge top-right
    local badge=Instance.new("TextLabel")
    badge.Size=UDim2.new(0,18,0,18) badge.Position=UDim2.new(1,-22,0,4)
    badge.BackgroundColor3=Color3.fromRGB(0,110,220) badge.BackgroundTransparency=0.2
    badge.TextColor3=Color3.new(1,1,1) badge.TextSize=9
    badge.Font=Enum.Font.GothamBold badge.Text=tostring(index)
    badge.BorderSizePixel=0 badge.ZIndex=6 badge.Parent=btn
    Instance.new("UICorner",badge).CornerRadius=UDim.new(0.5,0)

    -- ⠿ drag handle bottom-left
    local handle=Instance.new("TextButton")
    handle.Size=UDim2.new(0,22,0,22)
    handle.Position=UDim2.new(0,0,1,-22)
    handle.BackgroundColor3=Color3.fromRGB(60,60,80)
    handle.BackgroundTransparency=0.3
    handle.TextColor3=Color3.fromRGB(200,200,200)
    handle.Text="⠿" handle.TextSize=13
    handle.Font=Enum.Font.GothamBold
    handle.BorderSizePixel=0 handle.ZIndex=7
    handle.Parent=btn
    Instance.new("UICorner",handle).CornerRadius=UDim.new(0,6)

    -- Drag state
    local dragging=false
    local dragStart=nil
    local startPos=nil

    local function beginDrag(input)
        if cfg.hotbarLocked then return end
        dragging=true dragStart=input.Position startPos=btn.Position
    end
    local function moveDrag(input)
        if not dragging or not dragStart then return end
        local d=input.Position-dragStart
        btn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
    local function endDrag()
        if dragging then dragging=false slotLockedPositions[index]=btn.Position end
    end

    -- Handle events on grip only
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then beginDrag(i) end
        i:Handled()
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement then moveDrag(i) end
        i:Handled()
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then endDrag() end
        i:Handled()
    end)
    -- Global fallback so drag survives finger sliding off handle
    UIS.InputChanged:Connect(function(i)
        if dragging and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then moveDrag(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if dragging and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1) then endDrag() end
    end)

    -- Eat touch on main button body so camera never sees it
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then i:Handled() end end)
    btn.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then i:Handled() end end)
    btn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then i:Handled() end end)

    slotLockedPositions[index]=btn.Position
    slotGuis[index]={gui=sg,btn=btn,stroke=stroke}
end

makeSlotGui(1) makeSlotGui(2) makeSlotGui(3)

-- Lock enforcement + label/color update
RunS.Heartbeat:Connect(function()
    if cfg.hotbarLocked then
        for i=1,3 do slotGuis[i].btn.Position=slotLockedPositions[i] end
    end
    local s1=slot1Name and getTool(slot1Name)
    local s2=findVariant(SLOT2)
    local s3=findVariant(SLOT3)
    local eq=char:FindFirstChildOfClass("Tool")
    local tools={s1,s2,s3}
    local empties={"Slot 1\n(pick in UI)","No Slayer","No Eradicator"}
    for i,t in ipairs(tools) do
        local b=slotGuis[i].btn
        b.Text=t and t.Name or empties[i]
        if t then
            local active=eq and eq.Name==t.Name
            b.BackgroundColor3=active and Color3.fromRGB(0,140,255) or Color3.fromRGB(30,30,38)
            slotGuis[i].stroke.Color=active and Color3.fromRGB(0,180,255) or Color3.fromRGB(80,80,100)
        else
            b.BackgroundColor3=Color3.fromRGB(50,20,20)
            slotGuis[i].stroke.Color=Color3.fromRGB(120,40,40)
        end
    end
end)

-- Tap: equip if not equipped, unequip if already equipped
slotGuis[1].btn.MouseButton1Click:Connect(function()
    if not slot1Name then return end
    local eq=char:FindFirstChildOfClass("Tool")
    if eq and eq.Name==slot1Name then unequipCurrent() else equip(slot1Name) end
end)
slotGuis[2].btn.MouseButton1Click:Connect(function()
    local s=findVariant(SLOT2) if not s then return end
    local eq=char:FindFirstChildOfClass("Tool")
    if eq and eq.Name==s.Name then unequipCurrent() else hum:EquipTool(s) end
end)
slotGuis[3].btn.MouseButton1Click:Connect(function()
    local s=findVariant(SLOT3) if not s then return end
    local eq=char:FindFirstChildOfClass("Tool")
    if eq and eq.Name==s.Name then unequipCurrent() else hum:EquipTool(s) end
end)

-- ══════════════════════════════════════
--   ITEM PICKER (Slot 1)
-- ══════════════════════════════════════
local pkGui=Instance.new("ScreenGui")
pkGui.Name="Picker" pkGui.ResetOnSpawn=false pkGui.Enabled=false pkGui.DisplayOrder=20
pkGui.Parent=plr:WaitForChild("PlayerGui")
local pkBg=Instance.new("Frame")
pkBg.Size=UDim2.new(0,260,0,320) pkBg.AnchorPoint=Vector2.new(0.5,0.5)
pkBg.Position=UDim2.new(0.5,0,0.5,0) pkBg.BackgroundColor3=Color3.fromRGB(18,18,22) pkBg.BorderSizePixel=0 pkBg.Parent=pkGui
Instance.new("UICorner",pkBg).CornerRadius=UDim.new(0,12)
local ptl=Instance.new("TextLabel")
ptl.Size=UDim2.new(1,-40,0,36) ptl.Position=UDim2.new(0,10,0,0) ptl.BackgroundTransparency=1
ptl.TextColor3=Color3.new(1,1,1) ptl.Font=Enum.Font.GothamBold ptl.TextSize=15 ptl.Text="Pick Item for Slot 1" ptl.Parent=pkBg
local xcb=Instance.new("TextButton")
xcb.Size=UDim2.new(0,30,0,30) xcb.Position=UDim2.new(1,-34,0,3)
xcb.BackgroundColor3=Color3.fromRGB(180,40,40) xcb.TextColor3=Color3.new(1,1,1)
xcb.Text="✕" xcb.Font=Enum.Font.GothamBold xcb.TextSize=14 xcb.BorderSizePixel=0 xcb.Parent=pkBg
Instance.new("UICorner",xcb).CornerRadius=UDim.new(0,6)
xcb.MouseButton1Click:Connect(function() pkGui.Enabled=false end)
local scr=Instance.new("ScrollingFrame")
scr.Size=UDim2.new(1,-16,1,-46) scr.Position=UDim2.new(0,8,0,42)
scr.BackgroundTransparency=1 scr.ScrollBarThickness=5 scr.BorderSizePixel=0 scr.Parent=pkBg
local ll=Instance.new("UIListLayout") ll.SortOrder=Enum.SortOrder.Name ll.Padding=UDim.new(0,4) ll.Parent=scr

local function refreshPicker()
    for _,c in ipairs(scr:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local count=0
    for _,tool in ipairs(plr.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local fixed=false
            for _,n in ipairs(SLOT2) do if tool.Name==n then fixed=true end end
            for _,n in ipairs(SLOT3) do if tool.Name==n then fixed=true end end
            if not fixed then
                local b=Instance.new("TextButton")
                b.Size=UDim2.new(1,-8,0,40)
                b.BackgroundColor3=(slot1Name==tool.Name) and Color3.fromRGB(0,120,200) or Color3.fromRGB(35,35,40)
                b.TextColor3=Color3.new(1,1,1) b.Text=tool.Name b.Font=Enum.Font.Gotham b.TextSize=13 b.BorderSizePixel=0 b.Parent=scr
                Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
                b.MouseButton1Click:Connect(function()
                    slot1Name=tool.Name pkGui.Enabled=false
                    Velvet:Notify({Title="Slot 1 Set",Content=tool.Name.." assigned",Duration=3,Type="success"})
                end)
                count=count+1
            end
        end
    end
    if count==0 then
        local b=Instance.new("TextButton") b.Size=UDim2.new(1,-8,0,40) b.BackgroundTransparency=1
        b.TextColor3=Color3.fromRGB(150,150,150) b.Text="No items available" b.Font=Enum.Font.Gotham b.TextSize=13 b.Parent=scr
    end
    scr.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8)
end

-- ══════════════════════════════════════
--   LOOPS
-- ══════════════════════════════════════
local function autoCureLoop() while cfg.autoCure do local tc=targetChar() if tc and hasWormSound(tc) and getTool("Cure Potion") then while cfg.autoCure and targetChar() and hasWormSound(targetChar()) and getTool("Cure Potion") do equip("Cure Potion") task.wait(0.1) end if not getTool("Cure Potion") then Velvet:Notify({Title="Auto Cure",Content="Cure Potion used",Duration=3,Type="success"}) end end task.wait(0.4) end end
local function autoSaveLoop() while cfg.autoSave do if hp()<=35 and getTool("Save Potion") then while cfg.autoSave and hp()<=35 and getTool("Save Potion") do equip("Save Potion") task.wait(0.1) end if not getTool("Save Potion") then Velvet:Notify({Title="Auto Save",Content="Save Potion used",Duration=3,Type="success"}) end end task.wait(0.4) end end
local function spamLoop() local i=1 while cfg.spamEnabled do equip(SPAM_TOOLS[i]) task.wait(cfg.spamDelay) i=(i%#SPAM_TOOLS)+1 end end
local function waveLoop() while cfg.spamEnabled do for _,args in ipairs({W1,W2,W3}) do if not cfg.spamEnabled then break end local t=tick() while cfg.spamEnabled and tick()-t<cfg.waveDur do GunRemote:FireServer(unpack(args)) task.wait(0.001) end end task.wait(0.1) end end

-- ══════════════════════════════════════
--   AIMBOT
-- ══════════════════════════════════════
local aimConn,recoilConn,aimbotBtn=nil,nil,nil
local lastBtnPos=UDim2.new(0.5,-80,0.35,0) local btnLocked=false
local function isVisible(part) if not cfg.wallCheck then return true end local root=char:FindFirstChild("HumanoidRootPart") if not root then return false end local rp=RaycastParams.new() rp.FilterDescendantsInstances={char} rp.FilterType=Enum.RaycastFilterType.Exclude rp.IgnoreWater=true local res=WS:Raycast(root.Position,part.Position-root.Position,rp) return res==nil or res.Instance:IsDescendantOf(part.Parent) end
local function getAimTarget() local best,bd=nil,math.huge local root=char:FindFirstChild("HumanoidRootPart") local cam=WS.CurrentCamera if not root then return end for _,p in ipairs(game.Players:GetPlayers()) do if p~=plr and p.Team and p.Team.Name=="Worm" then local c=p.Character if c and c:FindFirstChild("Humanoid") and c.Humanoid.Health>0 then local part=c:FindFirstChild(cfg.aimPart) or c:FindFirstChild("Head") if part and isVisible(part) then local sp=cam:WorldToViewportPoint(part.Position) local fd=(Vector2.new(sp.X,sp.Y)-Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)).Magnitude local d=(part.Position-root.Position).Magnitude if fd<=cfg.fov and d<bd then bd=d best=part end end end end end return best end
local function startAimbot() if aimConn then aimConn:Disconnect() end aimConn=RunS.RenderStepped:Connect(function() if not cfg.aimbot then return end local t=getAimTarget() if not t then return end local cam=WS.CurrentCamera local pos=t.Position if cfg.prediction then local r=t.Parent:FindFirstChild("HumanoidRootPart") if r then pos=pos+(r.Velocity*((pos-cam.CFrame.Position).Magnitude/350)*cfg.predMult) end end local cf=cam.CFrame local tc=cfg.horizOnly and CFrame.new(cf.Position,Vector3.new(pos.X,cf.Position.Y,pos.Z)) or CFrame.lookAt(cf.Position,pos) cam.CFrame=cf:Lerp(tc,cfg.smoothing) end) end
local function makeAimbotBtn() if aimbotBtn then aimbotBtn.Position=lastBtnPos aimbotBtn.Visible=true return end local gui=Instance.new("ScreenGui") gui.ResetOnSpawn=false gui.Parent=plr:WaitForChild("PlayerGui") aimbotBtn=Instance.new("TextButton") aimbotBtn.Size=UDim2.new(0,160,0,55) aimbotBtn.Position=lastBtnPos aimbotBtn.BackgroundColor3=Color3.fromRGB(0,170,255) aimbotBtn.TextColor3=Color3.new(1,1,1) aimbotBtn.Text="AIMBOT: ON" aimbotBtn.TextScaled=true aimbotBtn.Font=Enum.Font.GothamBold aimbotBtn.Parent=gui local drag=Instance.new("Frame") drag.Size=UDim2.new(0,20,0,20) drag.Position=UDim2.new(1,-20,1,-20) drag.BackgroundColor3=Color3.new(1,1,1) drag.BackgroundTransparency=0.3 drag.Parent=aimbotBtn local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1 lbl.Text="≡" lbl.TextColor3=Color3.new(0,0,0) lbl.TextScaled=true lbl.Font=Enum.Font.GothamBold lbl.Parent=drag local dragging,ds,sp=false,nil,nil local function sd(i) if btnLocked then return end dragging=true ds=i.Position sp=aimbotBtn.AbsolutePosition end drag.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then sd(i) end end) aimbotBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then sd(i) end end) UIS.InputEnded:Connect(function(i) if dragging and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1) then dragging=false lastBtnPos=aimbotBtn.Position end end) UIS.InputChanged:Connect(function(i) if dragging and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-ds aimbotBtn.Position=UDim2.new(0,sp.X+d.X,0,sp.Y+d.Y) end end) aimbotBtn.MouseButton1Click:Connect(function() cfg.aimbot=not cfg.aimbot if cfg.aimbot then aimbotBtn.Text="AIMBOT: ON" aimbotBtn.BackgroundColor3=Color3.fromRGB(0,170,255) startAimbot() else aimbotBtn.Text="AIMBOT: OFF" aimbotBtn.BackgroundColor3=Color3.fromRGB(170,0,0) if aimConn then aimConn:Disconnect() aimConn=nil end end end) end

-- ══════════════════════════════════════
--   ESP
-- ══════════════════════════════════════
local espConns,espObjs={},{}
local function makeESP(p) if espObjs[p] then return end local c=p.Character if not c then return end local head=c:FindFirstChild("Head") if not head then return end local hl=Instance.new("Highlight") hl.FillTransparency=0.8 hl.OutlineColor=Color3.fromRGB(255,0,0) hl.FillColor=Color3.fromRGB(255,0,0) hl.Parent=c local bb=Instance.new("BillboardGui") bb.Adornee=head bb.Size=UDim2.new(0,200,0,60) bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true bb.Parent=c local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1 lbl.TextColor3=Color3.new(1,1,1) lbl.TextStrokeTransparency=0 lbl.Font=Enum.Font.GothamBold lbl.TextSize=14 lbl.Parent=bb espObjs[p]={hl=hl,bb=bb,lbl=lbl} end
local function updateESP() for _,p in ipairs(game.Players:GetPlayers()) do if p==plr or not p.Team or p.Team.Name~="Worm" then continue end local c=p.Character if not c or not c:FindFirstChild("Humanoid") or c.Humanoid.Health<=0 then continue end if not espObjs[p] then makeESP(p) end local obj=espObjs[p] if not obj then continue end local root=c:FindFirstChild("HumanoidRootPart") local dist=root and(root.Position-char.HumanoidRootPart.Position).Magnitude or 0 local info={} if cfg.espNames then table.insert(info,p.Name) end if cfg.espDist then table.insert(info,string.format("%.0f studs",dist)) end if cfg.espHP then table.insert(info,string.format("HP: %.0f",c.Humanoid.Health)) end if obj.lbl then obj.lbl.Text=table.concat(info," | ") end end end
local function startESP() for _,c in pairs(espConns) do c:Disconnect() end espConns={} table.insert(espConns,RunS.RenderStepped:Connect(updateESP)) end
local function stopESP() for _,obj in pairs(espObjs) do if obj.hl then obj.hl:Destroy() end if obj.bb then obj.bb:Destroy() end end espObjs={} for _,c in pairs(espConns) do c:Disconnect() end espConns={} end

-- ══════════════════════════════════════
--   VELVET UI
-- ══════════════════════════════════════
local repo="https://raw.githubusercontent.com/DexCodeSX/Velvet/main/"
local Velvet=loadstring(game:HttpGet(repo.."Library.lua"))()
local SaveManager=loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()
local ThemeManager=loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
Velvet:SetIcons(loadstring(game:HttpGet(repo.."addons/Icons.lua"))())
SaveManager:Bind(Velvet,"GunSpammerConfig") ThemeManager:Bind(Velvet)
local Win=Velvet:CreateWindow({Title="Gun Spammer",SubTitle="Waves+Aimbot+ESP",ToggleKey=Enum.KeyCode.RightShift})

local mainSec=Win:AddTab("Main","zap"):AddSection("Gun Spammer")
mainSec:AddToggle("Spam",{Text="Enable Spammer",Default=false,Callback=function(v) cfg.spamEnabled=v if v then task.spawn(spamLoop) task.spawn(waveLoop) end end})
mainSec:AddSlider("WaveDur",{Text="Wave Duration",Min=1,Max=10,Default=3,Increment=0.1,Suffix="s",Callback=function(v) cfg.waveDur=v end})
mainSec:AddSlider("SpamDelay",{Text="Switch Delay",Min=0.05,Max=1,Default=0.3,Increment=0.05,Suffix="s",Callback=function(v) cfg.spamDelay=v end})

local combat=Win:AddTab("Combat","sword")
local aimSec=combat:AddSection("Aimbot")
aimSec:AddToggle("Aimbot",{Text="Enable Aimbot",Default=false,Callback=function(v) cfg.aimbot=v if v then startAimbot() makeAimbotBtn() else if aimConn then aimConn:Disconnect() aimConn=nil end if aimbotBtn then aimbotBtn.Visible=false end end end})
aimSec:AddToggle("LockBtn",{Text="Lock Aimbot Button",Default=false,Callback=function(v) btnLocked=v end})
aimSec:AddToggle("HorizOnly",{Text="Horizontal Only",Default=false,Callback=function(v) cfg.horizOnly=v end})
aimSec:AddToggle("WallChk",{Text="Wall Check",Default=true,Callback=function(v) cfg.wallCheck=v end})
aimSec:AddToggle("Pred",{Text="Prediction",Default=true,Callback=function(v) cfg.prediction=v end})
aimSec:AddToggle("NoRecoil",{Text="No Recoil",Default=false,Callback=function(v) cfg.noRecoil=v if v and not recoilConn then local cam=WS.CurrentCamera recoilConn=RunS.RenderStepped:Connect(function() if cfg.noRecoil then cam.CFrame=CFrame.new(cam.CFrame.Position,cam.CFrame.Position+cam.CFrame.LookVector) end end) end end})
aimSec:AddDropdown("AimPart",{Text="Aim Part",Default="Head",Options={"Head","Torso"},Callback=function(v) cfg.aimPart=v end})
aimSec:AddSlider("Smooth",{Text="Smoothing",Min=0.05,Max=0.8,Default=0.15,Increment=0.01,Callback=function(v) cfg.smoothing=v end})
aimSec:AddSlider("FOV",{Text="FOV",Min=30,Max=360,Default=120,Increment=5,Suffix="°",Callback=function(v) cfg.fov=v end})
aimSec:AddSlider("PredStr",{Text="Prediction Strength",Min=0.5,Max=3,Default=1.8,Increment=0.1,Callback=function(v) cfg.predMult=v end})
local cureSec=combat:AddSection("Auto Cure Potion")
cureSec:AddToggle("AutoCure",{Text="Enable Auto Cure",Default=false,Callback=function(v) cfg.autoCure=v if v then task.spawn(autoCureLoop) end end})
cureSec:AddParagraph({Title="Condition",Content="WormSound on Torso → Cure Potion force-equipped until used"})
local saveSec=combat:AddSection("Auto Save Potion")
saveSec:AddToggle("AutoSave",{Text="Enable Auto Save",Default=false,Callback=function(v) cfg.autoSave=v if v then task.spawn(autoSaveLoop) end end})
saveSec:AddParagraph({Title="Condition",Content="HP ≤ 35% → Save Potion force-equipped until used"})

local espTab=Win:AddTab("ESP","eye"):AddSection("Worm ESP")
espTab:AddToggle("ESP",{Text="Enable ESP",Default=false,Callback=function(v) cfg.esp=v if v then startESP() else stopESP() end end})
espTab:AddToggle("ESPNames",{Text="Names",Default=true,Callback=function(v) cfg.espNames=v end})
espTab:AddToggle("ESPHP",{Text="Health",Default=true,Callback=function(v) cfg.espHP=v end})
espTab:AddToggle("ESPDist",{Text="Distance",Default=true,Callback=function(v) cfg.espDist=v end})
espTab:AddToggle("ESPBox",{Text="Boxes",Default=true,Callback=function(v) cfg.espBoxes=v end})

local utilSec=Win:AddTab("Utility","wrench"):AddSection("Custom Hotbar")
utilSec:AddParagraph({Title="Hotbar Info",Content="3 slots centered at bottom (like Roblox hotbar).\nSlot 2=Slayer (auto) | Slot 3=Eradicator (auto)\nDrag via ⠿ grip (bottom-left each slot).\nTap active slot again to unequip."})
utilSec:AddToggle("HotbarLock",{Text="Lock Hotbar Positions",Default=false,Callback=function(v)
    cfg.hotbarLocked=v
    if v then
        for i=1,3 do slotLockedPositions[i]=slotGuis[i].btn.Position end
        Velvet:Notify({Title="Hotbar",Content="Positions locked",Duration=2,Type="success"})
    else
        Velvet:Notify({Title="Hotbar",Content="Positions unlocked",Duration=2,Type="info"})
    end
end})
utilSec:AddButton({Text="Pick Item for Slot 1",Callback=function() refreshPicker() pkGui.Enabled=true end})
utilSec:AddButton({Text="Clear Slot 1",Callback=function() slot1Name=nil Velvet:Notify({Title="Slot 1",Content="Slot 1 cleared",Duration=2,Type="info"}) end})
utilSec:AddButton({Text="Reset Slot Positions",Callback=function()
    for i=1,3 do slotGuis[i].btn.Position=defaultPositions[i] slotLockedPositions[i]=defaultPositions[i] end
    Velvet:Notify({Title="Hotbar",Content="Reset to center-bottom",Duration=2,Type="info"})
end})

SaveManager:BuildProfileUI(Win:AddTab("Settings","settings"):AddSection("Profiles"))
Velvet:Notify({Title="Gun Spammer",Content="Loaded — drag slots via ⠿ grip",Duration=5,Type="success"})
