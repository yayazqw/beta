if Library and Library.Unload then
    Library:Unload()
end
--
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")
--
local Client = Players.LocalPlayer
local Camera = Workspace:FindFirstChildWhichIsA("Camera")
local Viewport = Camera.ViewportSize
-- // ============================================================
-- // TRIDENT SURVIVAL | HEAD : Drawing fix (lvl7) + Settings
-- // Вшито из actorDrawingFix.lua, работает даже без run_on_actor
-- // ============================================================
local TridentSettings = getgenv().TridentSettings or {
    Players = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        Weapon = true,
        ShowSleepers = false,
        ShowLocal = false,
        MaxDistance = 1500,
        Color = Color3.fromRGB(255, 255, 255),
        SleeperColor = Color3.fromRGB(160, 160, 160),
        Chams = false,
        ChamsColor = Color3.fromRGB(255, 0, 0),
        ChamsFill = 0.5,
        Skeleton = false,
        SkeletonColor = Color3.fromRGB(0, 255, 0),
    },
    Ores = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        MaxDistance = 1200,
        Iron = true,
        Nitrate = true,
        Stone = true,
        ColorIron = Color3.fromRGB(255, 170, 60),
        ColorNitrate = Color3.fromRGB(240, 240, 240),
        ColorStone = Color3.fromRGB(150, 150, 150),
    },
    NPC = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        MaxDistance = 1200,
        Color = Color3.fromRGB(255, 90, 90),
    },
    Backpacks = {
        Enabled = false,
        Box = true,
        Name = true,
        Distance = true,
        MaxDistance = 1200,
        Color = Color3.fromRGB(0, 255, 255),
    },
    Misc = {
        UseHighlightFallback = true,
        HideWhenMenuClosed = false,
    },
}
getgenv().TridentSettings = TridentSettings

-- // defaults-merge: добиваем новые поля тем, у кого настройки уже закешированы в getgenv
do
    local function fill(t, defaults)
        for k, v in defaults do
            if t[k] == nil then
                if typeof(v) == "Color3" then
                    t[k] = Color3.new(v.R, v.G, v.B)
                else
                    t[k] = v
                end
            end
        end
    end
    TridentSettings.Players = TridentSettings.Players or {}
    TridentSettings.Ores = TridentSettings.Ores or {}
    TridentSettings.NPC = TridentSettings.NPC or {}
    TridentSettings.Backpacks = TridentSettings.Backpacks or {}
    TridentSettings.Misc = TridentSettings.Misc or {}
    fill(TridentSettings.Players, { Enabled = false, Box = true, Name = true, Distance = true, Weapon = true, ShowSleepers = false, ShowLocal = false, MaxDistance = 1500, Chams = false, ChamsFill = 0.5, Skeleton = false })
    fill(TridentSettings.Ores, { Enabled = false, Box = true, Name = true, Distance = true, MaxDistance = 1200, Iron = true, Nitrate = true, Stone = true })
    fill(TridentSettings.NPC, { Enabled = false, Box = true, Name = true, Distance = true, MaxDistance = 1200 })
    fill(TridentSettings.Backpacks, { Enabled = false, Box = true, Name = true, Distance = true, MaxDistance = 1200 })
    fill(TridentSettings.Misc, { UseHighlightFallback = true, HideWhenMenuClosed = false })
    if typeof(TridentSettings.Players.Color) ~= "Color3" then TridentSettings.Players.Color = Color3.fromRGB(255, 255, 255) end
    if typeof(TridentSettings.Players.SleeperColor) ~= "Color3" then TridentSettings.Players.SleeperColor = Color3.fromRGB(160, 160, 160) end
    if typeof(TridentSettings.Players.ChamsColor) ~= "Color3" then TridentSettings.Players.ChamsColor = Color3.fromRGB(255, 0, 0) end
    if typeof(TridentSettings.Players.SkeletonColor) ~= "Color3" then TridentSettings.Players.SkeletonColor = Color3.fromRGB(0, 255, 0) end
    if typeof(TridentSettings.Ores.ColorIron) ~= "Color3" then TridentSettings.Ores.ColorIron = Color3.fromRGB(255, 170, 60) end
    if typeof(TridentSettings.Ores.ColorNitrate) ~= "Color3" then TridentSettings.Ores.ColorNitrate = Color3.fromRGB(240, 240, 240) end
    if typeof(TridentSettings.Ores.ColorStone) ~= "Color3" then TridentSettings.Ores.ColorStone = Color3.fromRGB(150, 150, 150) end
    if typeof(TridentSettings.NPC.Color) ~= "Color3" then TridentSettings.NPC.Color = Color3.fromRGB(255, 90, 90) end
    if typeof(TridentSettings.Backpacks.Color) ~= "Color3" then TridentSettings.Backpacks.Color = Color3.fromRGB(0, 255, 255) end
end

-- // ---- Actor Drawing Fix : SERIAL SIDE (safe) ----
do
    local okSerial = pcall(function()
        local coreGUI = game:GetService("CoreGui")
        if coreGUI:FindFirstChild("DRAWING_COMMUNICATOR") then return end
        local drawingCache = {}
        local drawingID = 0
        local communicator = Instance.new("BindableEvent")
        communicator.Name = "DRAWING_COMMUNICATOR"
        communicator.Parent = coreGUI
        communicator.Event:Connect(function(enviroment, action, ...)
            if enviroment ~= "parallel" then return end
            if action == "__index" then
                local id, index = ...
                if drawingCache[id] then
                    pcall(function()
                        communicator:Fire("serial", drawingCache[id][index])
                    end)
                end
            elseif action == "new" then
                local t = ...
                pcall(function()
                    drawingID += 1
                    drawingCache[drawingID] = Drawing.new(t)
                end)
            elseif action == "__newindex" then
                local id, index, value = ...
                if drawingCache[id] then
                    pcall(function()
                        drawingCache[id][index] = value
                    end)
                end
            elseif action == "remove" then
                local id = ...
                if drawingCache[id] then
                    pcall(function() drawingCache[id]:Remove() end)
                    drawingCache[id] = nil
                end
            end
        end)
    end)
end

-- // ---- Actor Drawing Fix : PARALLEL SOURCE (для run_on_actor, если есть) ----
getgenv().TRIDENT_ACTOR_SRC = [====[
--!actor
local drawingID = 0
local drawingResponse = nil
local communicator = game:GetService("CoreGui"):FindFirstChild("DRAWING_COMMUNICATOR")
if communicator then
    communicator.Parent = nil
    communicator.Event:Connect(function(enviroment, value)
        if enviroment ~= "serial" then return end
        drawingResponse = value
    end)
    local permissionBypass = Instance.new("BindableEvent")
    permissionBypass.Event:Connect(function(...)
        communicator:Fire(...)
    end)
    local function new(_type)
        drawingID += 1
        permissionBypass:Fire("parallel", "new", _type)
        local drawID = drawingID
        local customDrawing = newproxy(true)
        local objectMT = getmetatable(customDrawing)
        objectMT.__index = function(_, idx)
            if idx == "Remove" or idx == "Destroy" then
                return function()
                    permissionBypass:Fire("parallel", "remove", drawID)
                end
            end
            permissionBypass:Fire("parallel", "__index", drawID, idx)
            local response = drawingResponse
            drawingResponse = nil
            return response
        end
        objectMT.__newindex = function(_, idx, nidx)
            permissionBypass:Fire("parallel", "__newindex", drawID, idx, nidx)
        end
        return customDrawing
    end
    getgenv().Drawing = {
        new = new,
        Fonts = { UI = 0, System = 1, Plex = 2, Monospace = 3 },
    }
end
]====]

-- // Хелпер: проверить Drawing
local function TridentDrawingOK()
    if typeof(getgenv().Drawing) ~= "table" then return false end
    if typeof(getgenv().Drawing.new) ~= "function" then return false end
    local ok = pcall(function()
        local d = getgenv().Drawing.new("Text")
        d.Visible = false
        d:Remove()
    end)
    return ok
end
getgenv().TridentDrawingOK = TridentDrawingOK


-- // ================= espLibrary.lua (embedded) =================
local espLibrary = (function()
local cloneref          = cloneref or function(...) return ...; end;
local compareinstances  = compareinstances or rawequal;

local runService        = cloneref(game:GetService('RunService'));

local currentCamera     = cloneref(workspace.CurrentCamera);


local createDrawing           = function(_type, properties, ...)
      local drawing = Drawing.new(_type);
      for i, value in properties do
            drawing[i] = value;
      end;
      for _, _table in {...} do
            table.insert(_table, drawing);
      end;
      return drawing;
end;
local getBoundingBox = function(model, maxsize: number?)
      local cframe, size = model:GetBoundingBox();
      if (maxsize) then
            size = Vector3.new(math.min(size.X, 5), math.min(size.Y, 6.7), math.min(size.Z, 5));
      end;
      return cframe, size;
end;
local worldToViewPoint = function(position)
      local pos, onscreen = currentCamera:WorldToViewportPoint(position);
      return Vector2.new(pos.X, pos.Y), onscreen, pos.Z;
end;

local executor 	= identifyexecutor and identifyexecutor() or 'unknown';

local GLOBAL_FONT = executor == 'AWP' and 0 or executor == 'Zenith' and 3 or 1;
local GLOBAL_SIZE	= executor == 'AWP' and 16 or executor == 'Zenith' and 15 or 13;

local espLibrary = {};


-- playerESP
do
      local playerESP = {
            playerCache = {};
            drawingCache = {};
      };
      playerESP.__index = playerESP;

      playerESP.new = function(player: table)

            local self = setmetatable({
                  
                  player      = player;
                  model       = rawget(player, 'model');

                  connections = {};
                  allDrawings = nil;
                  drawings    = nil;

            }, playerESP);

            if (typeof(self.model) ~= 'Instance') then
                  return;
            end;

            -- drawing cacher
            local cache = playerESP.drawingCache[1];
            if (cache) then
                  table.remove(playerESP.drawingCache, 1);
                  
                  -- cache.name.Text = 'player';

                  self.allDrawings  = cache.all;
                  self.drawings     = cache;
            else
                  self:createDrawingCache();
            end;

            -- setup
            self.rootPart = self.model:FindFirstChild('HumanoidRootPart');
            self.model.AncestryChanged:Connect(function(child, parent)
                  if (parent) then
                        return;
                  end;

                  self:remove();
            end);

            playerESP.playerCache[player] = self;
            return self;
      end;
      function playerESP:remove()
            playerESP.playerCache[self.player] = nil;
            self:hideDrawings();

            for i = 1, #self.connections do
                  self.connections[i]:Disconnect();
            end;

            table.insert(playerESP.drawingCache, self.drawings);
      end;

      function playerESP:createDrawingCache()
            local allDrawings = {};
            local drawings = {
                  box = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 1;
                        Color             = Color3.new(1, 1, 1);
                        Filled            = false;
                        ZIndex            = 1;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Thickness         = 2;
                        Color             = Color3.new(0, 0, 0);
                        Filled            = false;
                        ZIndex            = 0;
                  }, allDrawings);

                  -- healthBar = createDrawing('Square', {
                  --       Visible           = false;
                  --       Thickness         = 1;
                  --       Filled            = true;
                  --       ZIndex            = 1;
                  -- }, allDrawings);
                  -- healthBackground = createDrawing('Square', {
                  --       Visible           = false;
                  --       Color             = Color3.new(0.239215, 0.239215, 0.239215);
                  --       Transparency      = 0.7;
                  --       Thickness         = 1;
                  --       Filled            = true;
                  --       ZIndex            = 0
                  -- }, allDrawings);

                  name = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Text              = 'player';
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
                  distance = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
                  weapon = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
            };
            drawings.all = allDrawings;

            self.drawings = drawings;
            self.allDrawings = allDrawings;
      end;
      function playerESP:hideDrawings()
            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
      end;

      --character functions
      function playerESP:loop(settings, distance)
            local _, size           = getBoundingBox(self.model, 5);
            local goal              = self.rootPart.Position;

            local vector2, onscreen = worldToViewPoint(goal);
            if (not onscreen) then
                  return self:hideDrawings();
            end;

            local cframe = CFrame.new(goal, currentCamera.CFrame.Position);

            local x, y = -size.X / 2, size.Y / 2;
            local topright    = worldToViewPoint((cframe * CFrame.new(x, y, 0)).Position)
            local bottomright = worldToViewPoint((cframe * CFrame.new(x, -y, 0)).Position)

            local offset = Vector2.new(
                  math.max(topright.X - vector2.X, bottomright.X - vector2.X),
                  math.max((vector2.Y - topright.Y), (bottomright.Y - vector2.Y))
            );

            self:renderBox(vector2, offset, settings.box);
            self:renderName(vector2, offset, settings.name);
            self:renderDistance(vector2, offset, settings.distance);
            -- self:renderHealthbar(vector2, offset, settings.healthbar);
            self:renderWeapon(vector2, offset, settings.weapon);
      end;

      --render functions
      function playerESP:renderBox(vector2, offset, enabled)
            local drawings = self.drawings;

            if (not enabled) then
                  drawings.box.Visible          = false;
                  drawings.boxOutline.Visible   = false;
                  return;
            end;

            local fill        = drawings.box;
            local outline     = drawings.boxOutline;

            local position    = vector2 - offset;
            local size        = offset * 2;
            
            fill.Visible      = true;
            fill.Position     = position;
            fill.Size         = size;

            outline.Visible   = true;
            outline.Position  = position;
            outline.Size      = size;
      end;
      function playerESP:renderName(vector2, offset, enabled)
            local name = self.drawings.name;

            if (not enabled) then
                  name.Visible          = false;
                  return;
            end;
            
            name.Visible      = true;
            name.Text         = rawget(self.player, 'sleeping') and 'sleeper' or 'player';
            name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
      end;
      function playerESP:renderDistance(vector2, offset, enabled, _distance)
            local distance = self.drawings.distance;

            if (not enabled) then
                  distance.Visible          = false;
                  return;
            end;

            local Yoffset     = self.drawings.weapon.Visible and 13 or 0;
            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.rootPart.Position).Magnitude );
            
            distance.Visible  = true;
            distance.Position = vector2 + Vector2.new(0, offset.Y + Yoffset);
            distance.Text     = `[{magnitude}]`;
      end;
      function playerESP:renderWeapon(vector2, offset, enabled)
            local weapon = self.drawings.weapon;

            if (not enabled) then
                  weapon.Visible          = false;
                  return;
            end;

            local weaponText        = 'none';
            local equippedItem      = rawget(self.player, 'equippedItem');

            if (equippedItem) then
                  weaponText = rawget(equippedItem, 'type') or 'none';
                  if (rawget(equippedItem, 'amt') > 1) then
                        weaponText = `{weaponText} x{ rawget(equippedItem, 'amt') }`;
                  end;
            end;

            weapon.Visible  = true;
            weapon.Position = vector2 + Vector2.new(0, offset.Y);
            weapon.Text     = weaponText;
      end;

      espLibrary.playerESP = playerESP;
end;

-- entityESP
do
      local entityESP = {
            entityCache = {};
            drawingCache = {};

            childAddedConnections = {};
            childRemovedConnections = {};
      };
      entityESP.__index = entityESP;

      entityESP.new = function(entity: Model, name: string?, colour: Color3?)
            local self = setmetatable({
                  entity      = entity;
                  
                  name        = name or rawget(entity, 'type');
                  colour      = colour or Color3.new(1, 1, 1);
                  model       = rawget(entity, 'model');

                  connections = {};
            }, entityESP);

            if (type(self.name) ~= 'string') then
                  self.name = '???';
            elseif (typeof(self.model) ~= 'Instance') then
                  return;
            end;

            local cache = entityESP.drawingCache[1];
            if (cache) then
                  table.remove(entityESP.drawingCache, 1);
                  
                  cache.name.Text         = self.name;

                  cache.name.Color        = self.colour;
                  cache.box.Color         = self.colour;
                  cache.distance.Color    = self.colour;

                  self.allDrawings        = cache.all;
                  self.drawings           = cache;
            else
                  self:createDrawingCache();
            end;

            
            table.insert(self.connections, self.model.AncestryChanged:Connect(function(child, parent)
                  if (child == self.model and parent == nil) then
                        return self:remove();
                  end;
            end));

            entityESP.entityCache[entity] = self;
            return self;
      end;
      function entityESP:remove()
            entityESP.entityCache[self.entity] = nil;
            
            self:hideDrawings();
            
            table.insert(entityESP.drawingCache, self.drawings);

            for i = 1, #self.connections do
                  self.connections[i]:Disconnect();
            end;
      end;
      function entityESP:createDrawingCache()
            local allDrawings = {};

            local drawings = {
                  box = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = self.colour;
                        ZIndex            = 0;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = Color3.new(0, 0, 0);
                        ZIndex            = -1;
                  }, allDrawings);

                  name = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Text              = self.name;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);
                  distance = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);
            };
            drawings.all = allDrawings;

            self.drawings = drawings;
            self.allDrawings = allDrawings;

      end;
      function entityESP:hideDrawings()
            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
      end;
      function entityESP:loop(settings, distance)
            local goal, size = getBoundingBox(self.model);

            local vector2, onscreen = worldToViewPoint(goal.Position);
            if (not onscreen) then
                  return self:hideDrawings();
            end;

            local cframe = CFrame.new(goal.Position, currentCamera.CFrame.Position);

            local x, y = -size.X / 2, size.Y / 2;
            local topright    = worldToViewPoint((cframe * CFrame.new(x, y, 0)).Position)
            local bottomright = worldToViewPoint((cframe * CFrame.new(x, -y, 0)).Position)

            local offset = Vector2.new(
                  math.max(topright.X - vector2.X, bottomright.X - vector2.X),
                  math.max((vector2.Y - topright.Y), (bottomright.Y - vector2.Y))
            );

            self:renderBox(vector2, offset, settings.box);
            self:renderName(vector2, offset, settings.name);
            self:renderDistance(vector2, offset, settings.distance, distance);
      end;
      
      -- render functions
      function entityESP:renderBox(vector2, offset, enabled)
            local drawings = self.drawings;

            if (not enabled) then
                  drawings.box.Visible          = false;
                  drawings.boxOutline.Visible   = false;
                  return;
            end;

            local fill        = drawings.box;
            local outline     = drawings.boxOutline;

            local position    = vector2 - offset;
            local size        = offset * 2;
            
            fill.Visible      = true;
            fill.Position     = position;
            fill.Size         = size;

            outline.Visible   = true;
            outline.Position  = position;
            outline.Size      = size;
      end;
      function entityESP:renderName(vector2, offset, enabled)
            local name = self.drawings.name;

            if (not enabled) then
                  name.Visible          = false;
                  return;
            end;
            
            name.Visible      = true;
            name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
      end;
      function entityESP:renderDistance(vector2, offset, enabled, _distance)
            local distance = self.drawings.distance;

            if (not enabled) then
                  distance.Visible          = false;
                  return;
            end;

            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.model:GetPivot().Position).Magnitude );
            
            distance.Visible  = true;
            distance.Position = vector2 + Vector2.new(0, offset.Y);
            distance.Text     = `[{magnitude}]`;
      end;

      espLibrary.entityESP = entityESP;
end;

-- npcESP
do
      local npcESP = {
            npcCache = {};
            drawingCache = {};
      };
      npcESP.__index = npcESP;

      npcESP.new = function(entity: Model, colour: Color3?)
            local self = setmetatable({
                  entity      = entity;
                  settingName = settingName;
                  
                  name        = rawget(entity, 'type') or 'npc';
                  colour      = colour or Color3.new(1, 1, 1);
                  model       = rawget(entity, 'model');

                  connections = {};
            }, npcESP);

            if (typeof(self.model) ~= 'Instance') then
                  return;
            elseif (type(self.name) ~= 'string') then
                  self.name = 'npc';
            end;

            -- drawing cacher
            local cache = npcESP.drawingCache[1];
            if (cache) then
                  table.remove(npcESP.drawingCache, 1);
                  
                  self.allDrawings  = cache.all;
                  self.drawings     = cache;
            else
                  self:createDrawingCache();
            end;

            -- updating drawing info
            local drawings = self.drawings;
            drawings.name.Text      = self.name;
            drawings.name.Color     = self.colour;
            drawings.box.Color      = self.colour;
            drawings.weapon.Color   = self.colour;
            drawings.distance.Color = self.colour;

            -- setup
            self.rootPart = self.model:FindFirstChild('HumanoidRootPart');
            self.model.AncestryChanged:Connect(function(child, parent)
                  if (parent) then
                        return;
                  end;
                  self:remove();
            end);

            npcESP.npcCache[entity] = self;
            return self;
      end;
      function npcESP:remove()
            npcESP.npcCache[self.entity] = nil;
            
            self:hideDrawings();
            
            table.insert(npcESP.drawingCache, self.drawings);

            for i = 1, #self.connections do
                  self.connections[i]:Disconnect();
            end;
      end;
      function npcESP:createDrawingCache()
            local allDrawings = {};

            local drawings = {
                  box = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = self.colour;
                        ZIndex            = 0;
                  }, allDrawings);
                  boxOutline = createDrawing('Square', {
                        Visible           = false;
                        Filled            = false;
                        Thickness         = 1;
                        Color             = Color3.new(0, 0, 0);
                        ZIndex            = -1;
                  }, allDrawings);

                  name = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Text              = self.name;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);
                  distance = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = self.colour;
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 0;
                  }, allDrawings);

                  weapon = createDrawing('Text', {
                        Visible           = false;
                        Center            = true;
                        Outline           = true;
                        OutlineColor      = Color3.new(0, 0, 0);
                        Color             = Color3.new(1, 1, 1);
                        Transparency      = 1;
                        Size              = GLOBAL_SIZE;
                        Font              = GLOBAL_FONT;
                        ZIndex            = 1;
                  }, allDrawings);
            };
            drawings.all = allDrawings;

            self.drawings = drawings;
            self.allDrawings = allDrawings;

      end;
      function npcESP:hideDrawings()
            for i = 1, #self.allDrawings do
                  self.allDrawings[i].Visible = false;
            end;
      end;
      function npcESP:loop(settings, distance)
            local goal, size = getBoundingBox(self.model, Vector3.new(3, 5, 3));

            local vector2, onscreen = worldToViewPoint(goal.Position);
            if (not onscreen) then
                  return self:hideDrawings();
            end;

            local cframe = CFrame.new(goal.Position, currentCamera.CFrame.Position);

            local x, y = -size.X / 2, size.Y / 2;
            local topright    = worldToViewPoint((cframe * CFrame.new(x, y, 0)).Position)
            local bottomright = worldToViewPoint((cframe * CFrame.new(x, -y, 0)).Position)

            local offset = Vector2.new(
                  math.max(topright.X - vector2.X, bottomright.X - vector2.X),
                  math.max((vector2.Y - topright.Y), (bottomright.Y - vector2.Y))
            );

            self:renderBox(vector2, offset, settings.box);
            self:renderName(vector2, offset, settings.name);
            self:renderDistance(vector2, offset, settings.distance, distance);
            -- self:renderHealthbar(vector2, offset, settings.healthbar);
      end;

      -- render functions
      function npcESP:renderBox(vector2, offset, enabled)
            local drawings = self.drawings;

            if (not enabled) then
                  drawings.box.Visible          = false;
                  drawings.boxOutline.Visible   = false;
                  return;
            end;

            local fill        = drawings.box;
            local outline     = drawings.boxOutline;

            local position    = vector2 - offset;
            local size        = offset * 2;
            
            fill.Visible      = true;
            fill.Position     = position;
            fill.Size         = size;

            outline.Visible   = true;
            outline.Position  = position;
            outline.Size      = size;
      end;
      function npcESP:renderName(vector2, offset, enabled)
            local name = self.drawings.name;

            if (not enabled) then
                  name.Visible          = false;
                  return;
            end;
            
            name.Visible      = true;
            name.Position     = vector2 - Vector2.new(0, offset.Y + name.Size);
      end;
      function npcESP:renderDistance(vector2, offset, enabled, _distance)
            local distance = self.drawings.distance;

            if (not enabled) then
                  distance.Visible          = false;
                  return;
            end;

            local magnitude   = math.round( _distance or (currentCamera.CFrame.Position - self.model:GetPivot().Position).Magnitude );
            
            distance.Visible  = true;
            distance.Position = vector2 + Vector2.new(0, offset.Y);
            distance.Text     = `[{magnitude}]`;
      end;
      -- function npcESP:renderHealthbar(vector2, offset, enabled)
      --       if (not enabled) then
      --             self.drawings.healthBar.Visible = false;
      --             self.drawings.healthBackground.Visible = false;
      --             return;
      --       end;

      --       local healthBar         = self.drawings.healthBar;
      --       local healthBackground  = self.drawings.healthBackground;

      --       healthBar.Visible = true;
      --       healthBackground.Visible = true;

      --       local basePosition = vector2 - offset - Vector2.new(5, 0);
      --       local baseSize = Vector2.new(3, offset.Y * 2);

      --       local healthLength = (baseSize.Y - 2) * self.healthPercentage;
      --       local healthPosition = basePosition + Vector2.new(1, 1 + (baseSize.Y - 2 - healthLength));
      --       local healthSize = Vector2.new(1, healthLength);

      --       healthBackground.Position     = basePosition;
      --       healthBackground.Size         = baseSize;

      --       healthBar.Position            = healthPosition;
      --       healthBar.Size                = healthSize;
      -- end;


      espLibrary.npcESP = npcESP;
end;


return espLibrary, 1;

end)()
getgenv().TridentESPLib = espLibrary
-- // ============== end espLibrary ==============

--
do -- Folders
    if not isfolder("gamesense") then
        makefolder("gamesense")
    end
    --
    if not isfolder("gamesense/Configs") then
        makefolder("gamesense/Configs")
    end
end
--
do -- Library
    getgenv().Library = {
        Connections = {},
        Errors = {},
        Tweens = {},
        Objects = {},
        Sections = {},
        ThemeSections = {},
        Flags = {},
        UnnamedFlags = 0,
        Build = "Beta",
        UID = "1",
        UnsafeMode = false,
        InitTime = os.clock(),
        Folder = "gamesense",
        ConfigFolder = "gamesense/Configs",
        UI = {
            Name = "gamesense",
            CloseBind = Enum.KeyCode.RightShift,
            SectionResizeIncrements = 1,
            WatermarkRefreshRate = 1,
            MainUI = nil,
            Initialized = false,
            Faded = false,
            LastCopiedColor = nil,
            TabIndex = 0,
            Viewing = false,
            CurrentSelectedColorPicker = nil,
            CurrentSelectedColorPickerExtra = nil,
            CurrentSelectedKeybindMode = nil,
            TotalColorPickers = 0,
            TotalKeybindModes = 0,
            WatermarkPosition = "Top Right",
            SectionZIndex = 100,
            Resizing = false,
            DropdownZIndex = 1,
            OpenColorFrames = 0,
            ScreenGUI = nil,
            TweenSpeed = 0.15,
            NewFont = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            FontSize = 13,
            DraggingGui = nil,
            Notifications = {TopLeft = {}, Middle = {}},
            Keys = {
                [Enum.KeyCode.LeftShift] = "LSHF",
                [Enum.KeyCode.RightShift] = "RSHF",
                [Enum.KeyCode.LeftControl] = "LCTR",
                [Enum.KeyCode.RightControl] = "RCTR",
                [Enum.KeyCode.LeftAlt] = "LALT",
                [Enum.KeyCode.RightAlt] = "RALT",
                [Enum.KeyCode.CapsLock] = "CAPS",
                [Enum.KeyCode.Space] = "SPCE",
                [Enum.KeyCode.One] = "ONE",
                [Enum.KeyCode.Two] = "TWO",
                [Enum.KeyCode.Three] = "THREE",
                [Enum.KeyCode.Four] = "FOUR",
                [Enum.KeyCode.Five] = "FIVE",
                [Enum.KeyCode.Six] = "SIX",
                [Enum.KeyCode.Seven] = "SEVEN",
                [Enum.KeyCode.Eight] = "EIGHT",
                [Enum.KeyCode.Nine] = "NINE",
                [Enum.KeyCode.Zero] = "ZERO",
                [Enum.KeyCode.KeypadOne] = "NUM1",
                [Enum.KeyCode.KeypadTwo] = "NUM2",
                [Enum.KeyCode.KeypadThree] = "NUM3",
                [Enum.KeyCode.KeypadFour] = "NUM4",
                [Enum.KeyCode.KeypadFive] = "NUM5",
                [Enum.KeyCode.KeypadSix] = "NUM6",
                [Enum.KeyCode.KeypadSeven] = "NUM7",
                [Enum.KeyCode.KeypadEight] = "NUM8",
                [Enum.KeyCode.KeypadNine] = "NUM9",
                [Enum.KeyCode.KeypadZero] = "NUM0",
                [Enum.KeyCode.Insert] = "INS",
                [Enum.KeyCode.Minus] = "-",
                [Enum.KeyCode.Equals] = "=",
                [Enum.KeyCode.Tilde] = "~",
                [Enum.KeyCode.LeftBracket] = "[",
                [Enum.KeyCode.RightBracket] = "]",
                [Enum.KeyCode.RightParenthesis] = ")",
                [Enum.KeyCode.LeftParenthesis] = "(",
                [Enum.KeyCode.Semicolon] = ",",
                [Enum.KeyCode.Quote] = "'",
                [Enum.KeyCode.BackSlash] = "\\",
                [Enum.KeyCode.Comma] = ",",
                [Enum.KeyCode.Period] = ".",
                [Enum.KeyCode.Slash] = "/",
                [Enum.KeyCode.Asterisk] = "*",
                [Enum.KeyCode.Plus] = "+",
                [Enum.KeyCode.Period] = ".",
                [Enum.KeyCode.Backquote] = "`",
                [Enum.UserInputType.MouseButton1] = "M1",
                [Enum.UserInputType.MouseButton2] = "M2",
                [Enum.UserInputType.MouseButton3] = "M3"
            },
        },
        Theme = {
            Objects = {},
            Default = {
                Accent = Color3.fromRGB(153, 196, 39),
                SecondAccent = Color3.fromRGB(124, 158, 32),
                TextColor = Color3.fromRGB(205, 205, 205),
                Risky = Color3.fromRGB(165, 165, 120),
            }
        }
    }
    --
    function Library:Validate(Defaults, Options)
        for Index, Value in Defaults do
            if Options[Index] == nil then
                Options[Index] = Value
            end
        end
        --
        return Options
    end
    --
    function Library:Connection(Signal, Func, Name, Table)
        Name = Name or "Unknown"
        Table = Table or Library.Connections
        --
        local Connection; Connection = Signal:Connect(function(...)
            local Args = {...}
            --
            local Success, Message = pcall(function() coroutine.wrap(Func)(unpack(Args)) end)
            --
            if not Success and not Library.Errors[Message] then
                if Library.Notify then
                    Library:Notify({Message = ("[ERROR] | An error has occurred:\n%s\nName: %s"):format(Message, Name), Delay = math.huge})
                else
                    warn(("[ERROR] | An error has occurred:\n%s\nName: %s"):format(Message, Name))
                end
                --
                Library.Errors[Message] = Message
                --
                if Table[Connection] then
                    Table[Connection] = nil
                end
                --
                return Connection and Connection:Disconnect()
            end
        end)
        --
        if Connection and Table then
            table.insert(Table, Connection)
        end
        --
        return Connection
    end
    --
    function Library:TweenObject(Object, Info, Goal, Callback)
        if not Object then return end
        --
        local Tween = TweenService:Create(Object, Info, Goal)
        --
        Library:Connection(Tween.Completed, Callback or function() end)
        --
        Tween:Play()
        --
        Library.Tweens[#Library.Tweens + 1] = Tween
    end
    --
    function Library:NewFlag()
        Library.UnnamedFlags += 1
        --
        return ("UnknownFlag%s"):format(tostring(Library.UnnamedFlags))
    end
    --
    function Library:ClampString(String, MaxWidth)
        local Clamped = String
        --
        local TextLabel = Library:CreateObject("TextLabel", {
            FontFace = Library.UI.NewFont,
            TextStrokeTransparency = 0,
            Text = String,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextScaled = false,
            TextWrapped = false,
            Visible = false,
            TextSize = Library.UI.FontSize,
            Parent = Client.PlayerGui
        })
        --
        if TextLabel.TextBounds.X <= MaxWidth then
            TextLabel:Destroy()
            --
            return String
        end
        --
        while TextLabel.TextBounds.X > MaxWidth and #Clamped > 0 do
            Clamped = Clamped:sub(1, #Clamped - 1)
            --
            TextLabel.Text = Clamped .. "..."
            --
            task.wait()
        end
        --
        TextLabel:Destroy()
        --
        return Clamped .. "..."
    end
    --
    function Library:GetConfig()
        local Config = {}
        --
        for Index, Value in Library.Flags do
            if Value.Get and not string.find(Index, "_Status") then
                if typeof(Value:Get()) == "table" and Value:Get().Color and Value:Get().Transparency then
                    local Transparency = Value:Get().Transparency
                    local Hue, Saturation, Value = Value:Get().Color:ToHSV()
                    --
                    Config[Index] = {Hue, Saturation, Value, Transparency}
                else
                    Config[Index] = Value:Get()
                end
            end
        end
        --
        return HttpService:JSONEncode(Config)
    end
    --
    function Library:LoadConfig(Config)
        local Config = HttpService:JSONDecode(Config)
        --
        for Index, Value in Config do
            if Library.Flags[Index] and Library.Flags[Index].Set then
                Library.Flags[Index]:Set(Value)
            end
        end
    end
    --
    function Library:SectionDragging(Frame)
        local MousePosition = UserInputService:GetMouseLocation()
        local Position = Frame.AbsolutePosition
        local Size = Frame.AbsoluteSize
        --
        local InsideX = MousePosition.X >= Position.X and MousePosition.X <= Position.X + Size.X
        local InsideY = MousePosition.Y >= Position.Y and MousePosition.Y <= Position.Y + Size.Y
        --
        return InsideX and InsideY
    end
    --
    function Library:CreateObject(Type, Properties, Hidden)
        local Hidden = Hidden or false
        local Object = Instance.new(Type)
        --
        for Index, Value in Properties do
            if (not RunService:IsStudio()) and Index == "Name" and not string.match(Value, "%d") then
                Value = "\0"
            end
            --
            if Index == "TextStrokeTransparency" and Value == 0 then
                local Stroke = Instance.new("UIStroke")
                --
                Stroke.Parent = Object
                Stroke.LineJoinMode = Enum.LineJoinMode.Miter
                --
                Library.Objects[Stroke] = {Stroke, {Parent = Object, LineJoinMode = Enum.LineJoinMode.Miter}, Hidden}
            else
                Object[Index] = Value
            end
        end
        --
        Library.Objects[Object] = {Object, Properties, Hidden}
        --
        return Object
    end
    --
    function Library:AddTheme(Object, Properties)
        for Index, Value in Properties do
            Library.Theme.Objects[Object] = Library.Theme.Objects[Object] or {}
            Library.Theme.Objects[Object][Index] = Value
        end
    end
    --
    function Library:GetTableIndexes(Table, Custom)
        local Table2 = {}
        --
        for Index, Value in Table do
            Table2[Custom and Value[1] or #Table2 + 1] = Index 
        end
        --
        return Table2
    end
    --
    function Library:UpdateConfigList(List, Type)
        for _, File in listfiles("gamesense/Configs") do
            local FileName = File:gsub("\\", "/"):gsub("gamesense/Configs/", ""):gsub(".cfg", "")
            --
            if Type == "Remove" then
                List:RemoveValue(FileName)
            else
                List:AddValue(FileName)
            end
        end
    end
    --
    function Library:GetObjectsTable(MainUI, AddMain, Ignored)
        local AddMain = AddMain or false
        local Ignored = Ignored or {}
        local DescendantTable = {}
        local NewTable = {}
        --
        for _, Descendant in MainUI:GetDescendants() do
            if table.find(Ignored, Descendant) then continue end
            --
            DescendantTable[#DescendantTable + 1] = Descendant
        end
        --
        if AddMain then
            DescendantTable[#DescendantTable + 1] = MainUI
        end
        --
        for _, Descendant in DescendantTable do
            local Found = Library.Objects[Descendant]
            --
            if Found then
                local Properties = Found[2]
                local HiddenValue = Found[3]
                --
                NewTable[#NewTable + 1] = {Descendant, Properties, HiddenValue}
            end
        end
        --
        return NewTable
    end
    --
    function Library:SetTableVisible(Table, State, Ignored)
        local Ignored = Ignored or {}
        --
        for _, Object in Table do
            if table.find(Ignored, Object) then continue end
            --
            if typeof(Object) == "table" and Object.SetVisible then 
                Object:SetVisible(State)
            end
        end
    end
    --
    function Library:UpdateColor(ColorType, ColorValue)
        Library.Theme.Default[ColorType] = ColorValue
        --
        for Object, Properties in Library.Theme.Objects do
            for Property, ThemeKeys in Properties do
                if typeof(ThemeKeys) == "table" then
                    if Object:IsA("UIGradient") and Property == "Color" then
                        if Library.Theme.Default[ThemeKeys[1]] then
                            Object.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Library.Theme.Default[ThemeKeys[1]]), ColorSequenceKeypoint.new(1, Library.Theme.Default[ThemeKeys[2]])}
                        end
                    end
                else
                    if ThemeKeys == ColorType then
                        Object[Property] = Library.Theme.Default[ThemeKeys]
                    end
                end
            end
        end
    end
    --
    function Library:ViewPlayer(Player)
        local ok = pcall(function()
            if not Library.UI.Viewing then
                local ch = Player and Player.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum then Camera.CameraSubject = hum end
            else
                local ch = Client and Client.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum then Camera.CameraSubject = hum end
            end
        end)
        if not ok then return end
        --
        Library.UI.Viewing = not Library.UI.Viewing
    end
    --
    function Library:GetTableLength(Table)
        local Length = 0
        --
        for Index, Value in pairs(Table) do
            Length += 1
        end
        --
        return Length
    end
    --
    function Library:ScrollingCheck(ScrollingFrame, Frame)
        if not ScrollingFrame:IsA("ScrollingFrame") then return true end
        --
        local VisibleTopLeft = ScrollingFrame.CanvasPosition
        local VisibleBottomRight = VisibleTopLeft + ScrollingFrame.AbsoluteWindowSize
        --
        local FrameTopLeft = Frame.AbsolutePosition - ScrollingFrame.AbsolutePosition + ScrollingFrame.CanvasPosition
        local FrameBottomRight = FrameTopLeft + Frame.AbsoluteSize
        --
        return FrameBottomRight.X > VisibleTopLeft.X and FrameTopLeft.X < VisibleBottomRight.X and FrameBottomRight.Y > VisibleTopLeft.Y and FrameTopLeft.Y < VisibleBottomRight.Y
    end
    --
    function Library:ClampPosition(Object, Position, Offset)
        local ClampedX = math.clamp(Position.X.Offset, Offset, Viewport.X - Object.AbsoluteSize.X - Offset)
        local ClampedY = math.clamp(Position.Y.Offset, Offset, Viewport.Y - Object.AbsoluteSize.Y - Offset)
        --
        return UDim2.new(Position.X.Scale, ClampedX, Position.Y.Scale, ClampedY)
    end
    --
    function Library:Fade(State, Table, MainUI, Speed)
        local IsMainUI = Table == Library.Objects
        --
        MainUI.Active = State
        --
        if State then
            MainUI.Visible = true
        end
        --
        if IsMainUI then
            Library.UI.Faded = not State
        end
        --  handle toggle transparency when fading out since im not using fade out for now as it causes fps issues
        if not State and IsMainUI then
            -- find all toggle elements and force them transparent immediately instead of waiting since some things may not leave instantly
            for _, obj in pairs(MainUI:GetDescendants()) do
                if obj.ClassName == "Frame" then
                    if obj.Name == "ToggleMain" then
                        obj.BackgroundTransparency = 1
                    end
                end
            end
        end
        --
        for _, Object in Table do
            if not Object[3] then
                if Object[1].ClassName == "Frame" and (Object[2]["BackgroundTransparency"] or 0) ~= 1 then
                    -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1})
                    Object[1].BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1
                elseif Object[1].ClassName == "ImageLabel" or Object[1].ClassName == "ImageButton" then
                    if (Object[2]["BackgroundTransparency"] or 0) ~= 1 then
                        -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1})
                        Object[1].BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1
                    end
                    --
                    if (Object[2]["ImageTransparency"] or 0) ~= 1 then
                        -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {ImageTransparency = State and (Object[2]["ImageTransparency"] or 0) or 1})
                        Object[1].ImageTransparency = State and (Object[2]["ImageTransparency"] or 0) or 1
                    end
                elseif Object[1].ClassName == "TextLabel" or Object[1].ClassName == "TextButton" or Object[1].ClassName == "TextBox" then
                    if (Object[2]["BackgroundTransparency"] or 0) ~= 1 then
                        -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1})
                        Object[1].BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1
                    end
                    --
                    if (Object[2]["TextTransparency"] or 0) ~= 1 then
                        -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {TextTransparency = State and (Object[2]["TextTransparency"] or 0) or 1})
                        Object[1].TextTransparency = State and (Object[2]["TextTransparency"] or 0) or 1
                    end
                elseif Object[1].ClassName == "ScrollingFrame" then
                    if (Object[2]["BackgroundTransparency"] or 0) ~= 1 then
                        -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1})
                        Object[1].BackgroundTransparency = State and (Object[2]["BackgroundTransparency"] or 0) or 1
                    end
                    --
                    if (Object[2]["ScrollBarImageTransparency"] or 0) ~= 1 then
                        -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {ScrollBarImageTransparency = State and (Object[2]["ScrollBarImageTransparency"] or 0) or 1})
                        Object[1].ScrollBarImageTransparency = State and (Object[2]["ScrollBarImageTransparency"] or 0) or 1
                    end
                elseif Object[1].ClassName == "UIStroke" then
                    -- Library:TweenObject(Object[1], TweenInfo.new(Speed, Enum.EasingStyle.Linear, State and Enum.EasingDirection["Out"] or Enum.EasingDirection["In"]), {Transparency = State and (Object[2]["Transparency"] or 0) or 1})
                    Object[1].Transparency = State and (Object[2]["Transparency"] or 0) or 1
                end
            end
        end
        --
        if not State then
            task.delay(Speed, function()
                if not MainUI.Parent then return end
                MainUI.Visible = false
            end)
        end
    end
    --
    function Library:CheckFrameFirst(FrameA, FrameB)
        local Parent = FrameA.Parent
        local Frames = {}
        local IndexA, IndexB
        --
        for _, Child in Parent:GetChildren() do
            if Child:IsA("Frame") then
                table.insert(Frames, Child)
            end
        end
        --
        table.sort(Frames, function(a, b)
            if a.LayoutOrder == b.LayoutOrder then
                for _, Child in Parent:GetChildren() do
                    if Child == a then return true end
                    if Child == b then return false end
                end
            end
            --
            return a.LayoutOrder < b.LayoutOrder
        end)
        --
        for i, Frame in Frames do
            if Frame == FrameA then IndexA = i end
            if Frame == FrameB then IndexB = i end
        end
        --
        return IndexA and IndexB and IndexA < IndexB
    end
    --
    function Library:Resizable(Object, DragFrame, MinResize, MaxResize, Increments, UseIcon, UseParent, Delay)
        local StartingSize, ObjectSize, Dragging, MouseLocation, PerformanceDragUI, NewMouse, Hovering
        --
        local function UpdateSize()
            if not MouseLocation then return end
            --
            Library.UI.Resizing = true
            --
            local CurrentMousePosition = UserInputService:GetMouseLocation()
            local Delta = CurrentMousePosition - MouseLocation
            local NewSizeX = StartingSize.X.Offset + Delta.X
            local NewSizeY = StartingSize.Y.Offset + Delta.Y
            local Parent = Object.Parent
            local ParentSize = Parent.AbsoluteSize
            --
            if UseParent then
                local OccupiedSpaceY = 0
                local FrameCount = 0
                --
                for _, Child in Parent:GetChildren() do
                    if Child:IsA("Frame") and Child ~= Object then
                        FrameCount += 1
                        --
                        if Library:CheckFrameFirst(Object, Child) then
                            if Child.AbsoluteSize.Y >= (ParentSize.Y - Object.AbsoluteSize.Y) - 57 then
                                Child.Size = UDim2.new(Child.Size.X.Scale, Child.Size.X.Offset, 0, math.max(50, (ParentSize.Y - Object.AbsoluteSize.Y) - 57))
                            end
                        else
                            OccupiedSpaceY += Child.AbsoluteSize.Y + 19
                        end
                    end
                end
                --
                if OccupiedSpaceY == 0 then
                    MaxResize = UDim2.new(0, 0, 0, (ParentSize.Y - OccupiedSpaceY) - (FrameCount * (50 + 19)) - 38)
                else
                    MaxResize = UDim2.new(0, 0, 0, (ParentSize.Y - OccupiedSpaceY) - 38)
                end
            end
            --
            if Increments then
                NewSizeY = math.clamp(math.round(NewSizeY / Increments) * Increments, MinResize.Y.Offset, MaxResize.Y.Offset)
            else
                NewSizeY = math.clamp(NewSizeY, MinResize.Y.Offset, MaxResize.Y.Offset)
                NewSizeX = math.clamp(NewSizeX, MinResize.X.Offset, MaxResize.X.Offset)
            end
            --
            return UseParent and UDim2.new(1, 0, 0, NewSizeY) or UDim2.new(0, NewSizeX, 0, NewSizeY)
        end
        
        --
        Library:Connection(DragFrame.MouseEnter, function()
            Hovering = true
        end)
        --
        Library:Connection(DragFrame.MouseLeave, function()
            if NewMouse then NewMouse:Destroy() NewMouse = nil end
            --
            UserInputService.MouseIconEnabled = true
            Hovering = false
        end)
        --
        Library:Connection(DragFrame.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = true
                MouseLocation = UserInputService:GetMouseLocation()
                StartingSize = Object.Size
            end
        end)
        --
        Library:Connection(RunService.PreRender, function()
            if (Hovering or Dragging) and UseIcon then
                local MousePosition = UserInputService:GetMouseLocation()
                --
                UserInputService.MouseIconEnabled = false
                --
                if not NewMouse then
                    NewMouse = Library:CreateObject("ImageLabel", {
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Image = "rbxassetid://87982048533100",
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Name = "Transparency",
                        Size = UDim2.new(0, 35, 0, 35),
                        ZIndex = 10000,
                        BorderSizePixel = 0,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Parent = Library.UI.ScreenGUI
                    }, true)
                end
                --
                NewMouse.Position = UDim2.new(0, MousePosition.X, 0, MousePosition.Y)
            end
            --
            if Dragging then
                if Delay then task.delay(Delay, function()
                        Object.Size = UpdateSize()
                    end)
                else
                    Object.Size = UpdateSize()
                end
            end
        end)
        --
        Library:Connection(UserInputService.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dragging then
                if NewMouse then NewMouse:Destroy() NewMouse = nil end
                --
                if UseParent then
                    for _, Child in Object.Parent:GetChildren() do
                        if Child:IsA("Frame") and Child ~= Object then
                            if Library:CheckFrameFirst(Object, Child) then
                                if Child.AbsoluteSize.Y >= (Object.Parent.AbsoluteSize.Y - Object.AbsoluteSize.Y) - 57 then
                                    Child.Size = UDim2.new(Child.Size.X.Scale, Child.Size.X.Offset, 0, math.max(50, (Object.Parent.AbsoluteSize.Y - Object.AbsoluteSize.Y) - 57))
                                end
                            end
                        end
                    end
                end
                --
                UserInputService.MouseIconEnabled = true
                Dragging = false
                Library.UI.Resizing = false
            end
        end)
    end
    --
    Library.__index = Library
    Library.Sections.__index = Library.Sections
    --
    local Sections = Library.Sections
    --
    function Library:ColorPicker(Options)
        Options = Library:Validate({
            Name = "Preview Color Picker",
            Default = Library.Theme.Default.Accent,
            Alpha = 0,
            AlphaBar = true,
            Parent = nil,
            MainUI = nil,
            TabUI = nil,
            Count = 1,
            Keybind = false,
            Flag = Library:NewFlag(),
            Callback = function() end,
        }, Options or {})
        --
        local Hue, Saturation, Value = Options.Default:ToHSV()
        --
        local ColorPicker = {
            Hover = false,
            Active = false,
            MouseDown = false,
            MainFrameHover = false,
            Color = Options.Default,
            SecondColor = Color3.fromRGB(math.max(math.floor(Options.Default.R * 255) - 14, 0), math.max(math.floor(Options.Default.G * 255) - 14, 0), math.max(math.floor(Options.Default.B * 255) - 14, 0)),
            Saturation = {Saturation, Value},
            Alpha = Options.Alpha,
            Hue = Hue,
            ActiveFrame = false,
            LastCopiedColor = {self.Color, self.Alpha},
            FrameOpened = false,
        }
        --
        Library.Flags[Options.Flag] = ColorPicker
        --
        Library.UI.TotalColorPickers += 1
        --
        if Options.Keybind then
            Options.Count += 1
        end
        --
        local ColorPickerOutline_1 = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            Name = "ColorPickerOutline" .. Library.UI.TotalColorPickers,
            Position = UDim2.new(1, 0 - (Options.Count - 1) * 22, 0, 0),
            Size = UDim2.new(0, 17, 0, 9),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = Options.Parent
        })
        --
        local ColorPickerChecker = Library:CreateObject("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 4),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            Visible = false,
            BorderSizePixel = 0,
            Parent = ColorPickerOutline_1
        })
        --
        local Button_9 = Library:CreateObject("TextButton", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button_9",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextTransparency = 1,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = ColorPickerOutline_1
        })
        --
        local ColorPickerTransparency = Library:CreateObject("ImageLabel", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Image = "rbxassetid://18249241978",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Name = "Transparency",
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BorderSizePixel = 0,
            ZIndex = 3,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.new(0, 6, 0, 6),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = ColorPickerOutline_1
        })
        --
        local ColorPickerInline_1 = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "ColorPickerInline_1",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = ColorPickerOutline_1
        })
        --
        local UIGradient_24 = Library:CreateObject("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, ColorPicker.Color),
                ColorSequenceKeypoint.new(1, ColorPicker.SecondColor)
            },
            Parent = ColorPickerInline_1
        })
        --
        do -- Functions
            function ColorPicker:SetVisible(Bool)
                ColorPickerOutline_1.Visible = Bool
                --
                if Bool == false then
                    ColorPicker:RemoveFrame()
                end
            end
            --
            function ColorPicker:AddFrame()
                Library.UI.CurrentSelectedColorPicker = {ColorPicker = ColorPicker, ColorPickerOutline = ColorPickerOutline_1, Parent = Options.Parent}
                --
                Library.UI.OpenColorFrames += 1
                --
                local ColorPickerOutline = Library:CreateObject("Frame", {
                    Size = UDim2.new(0, 180, 0, 175),
                    Name = "ColorPickerFrame" .. Library.UI.TotalColorPickers,
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = Library.UI.ScreenGUI
                })
                --
                ColorPickerOutline.BackgroundTransparency = 1
                --
                local ColorPickerInline = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "ColorPickerInline",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(60, 60, 60),
                    Parent = ColorPickerOutline
                })
                --
                ColorPickerInline.BackgroundTransparency = 1
                --
                local ColorPickerMain = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "ColorPickerMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    Parent = ColorPickerInline
                })
                --
                ColorPickerMain.BackgroundTransparency = 1
                --
                local MainPicker = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -24, 1, -19),
                    Name = "MainPicker",
                    Position = UDim2.new(0, 2, 0, 2),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = ColorPickerMain
                })
                --
                MainPicker.BackgroundTransparency = 1
                --
                local Button_91 = Library:CreateObject("TextButton", {
                    FontFace = Library.UI.NewFont,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Button_9",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextTransparency = 1,
                    ZIndex = 250,
                    TextSize = Library.UI.FontSize,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = MainPicker
                })
                --
                local MainPickerColor = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "MainPickerColor",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = MainPicker
                })
                --
                MainPickerColor.BackgroundTransparency = 1
                --
                local UIGradient_20 = Library:CreateObject("UIGradient", {
                    Rotation = 180,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 4)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    },
                    Parent = MainPickerColor
                })
                --
                local BackImage = Library:CreateObject("ImageLabel", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Image = "rbxassetid://13966897785",
                    BackgroundTransparency = 1,
                    Name = "BackImage",
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    Parent = MainPickerColor
                })
                --
                BackImage.ImageTransparency = 1
                --
                local DraggingMainOutline = Library:CreateObject("Frame", {
                    Size = UDim2.new(0, 4, 0, 4),
                    Name = "DraggingMainOutline",
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 251,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = MainPicker
                })
                --
                DraggingMainOutline.BackgroundTransparency = 1
                --
                local DraggingMain = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "DraggingMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 251,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = DraggingMainOutline
                })
                --
                DraggingMain.BackgroundTransparency = 1
                --
                local SaturationSlider = Library:CreateObject("Frame", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    AnchorPoint = Vector2.new(0, 1),
                    Name = "SaturationSlider",
                    Position = UDim2.new(0, 2, 1, -2),
                    Size = UDim2.new(1, -24, 0, 12),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = ColorPickerMain
                })
                --
                SaturationSlider.BackgroundTransparency = 1
                --
                local Button_915241 = Library:CreateObject("TextButton", {
                    FontFace = Library.UI.NewFont,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Button_9",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextTransparency = 1,
                    ZIndex = 250,
                    TextSize = Library.UI.FontSize,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = SaturationSlider
                })
                --
                local SaturationColor = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "SaturationColor",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 251,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = SaturationSlider
                })
                --
                SaturationColor.BackgroundTransparency = 1
                --
                local UIGradient_21 = Library:CreateObject("UIGradient", {
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 4)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                    },
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0.10000000149011612),
                        NumberSequenceKeypoint.new(0.5, 0.800000011920929),
                        NumberSequenceKeypoint.new(1, 1)
                    },
                    Rotation = 180,
                    Parent = SaturationColor
                })
                --
                local BackImage_1 = Library:CreateObject("ImageLabel", {
                    ScaleType = Enum.ScaleType.Tile,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "BackImage_1",
                    TileSize = UDim2.new(0, 12, 0, 12),
                    Image = "rbxassetid://18249241978",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 1, 0, 1),
                    Size = UDim2.new(1, -2, 1, -2),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    Parent = SaturationSlider
                })
                --
                BackImage_1.ImageTransparency = 1
                --
                local DraggingSatOutline = Library:CreateObject("Frame", {
                    Size = UDim2.new(0, 4, 1, 0),
                    Name = "DraggingSatOutline",
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 251,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = SaturationSlider
                })
                --
                DraggingSatOutline.BackgroundTransparency = 1
                --
                local DraggingSatMain = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "DraggingSatMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 251,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = DraggingSatOutline
                })
                --
                DraggingSatMain.BackgroundTransparency = 1
                --
                local HueSlider = Library:CreateObject("Frame", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    AnchorPoint = Vector2.new(1, 0),
                    Name = "HueSlider",
                    Position = UDim2.new(1, -2, 0, 2),
                    Size = UDim2.new(0, 17, 1, -19),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = ColorPickerMain
                })
                --
                HueSlider.BackgroundTransparency = 1
                --
                local Button_9141 = Library:CreateObject("TextButton", {
                    FontFace = Library.UI.NewFont,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Button_9",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextTransparency = 1,
                    ZIndex = 250,
                    TextSize = Library.UI.FontSize,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = HueSlider
                })
                --
                local BackImage_2 = Library:CreateObject("ImageLabel", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "BackImage_2",
                    TileSize = UDim2.new(0, 12, 0, 12),
                    Image = "rbxassetid://8180989234",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 1, 0, 1),
                    Size = UDim2.new(1, -2, 1, -2),
                    ZIndex = 250,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    Parent = HueSlider
                })
                --
                BackImage_2.ImageTransparency = 1
                --
                local DraggingHueOutline = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, 0, 0, 4),
                    Name = "DraggingHueOutline",
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 251,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = HueSlider
                })
                --
                DraggingHueOutline.BackgroundTransparency = 1
                --
                local DraggingHueMain = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "DraggingHueMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 251,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = DraggingHueOutline
                })
                --
                DraggingHueMain.BackgroundTransparency = 1
                --
                do -- Functions
                    function ColorPicker:UpdateSize()
                        ColorPickerOutline.Position = UDim2.new(0, ColorPickerOutline_1.AbsolutePosition.X, 0, (ColorPickerOutline_1.AbsolutePosition.Y + ColorPickerOutline_1.AbsoluteSize.Y + GuiService:GetGuiInset().Y + 2))
                    end
                    --
                    ColorPicker:UpdateSize()
                    --
                    Library:Connection(Options.MainUI:GetPropertyChangedSignal("AbsolutePosition"), ColorPicker.UpdateSize)
                    --
                    local StartingY = ColorPickerOutline_1.AbsolutePosition.Y
                    local MainUIStartingY = Options.MainUI.AbsolutePosition.Y
                    local StartingCanvasPosition = Options.Parent.Parent.CanvasPosition
                    --
                    Library:Connection(ColorPickerOutline_1:GetPropertyChangedSignal("AbsolutePosition"), function()
                        local CurrentY = ColorPickerOutline_1.AbsolutePosition.Y
                        local MainUICurrentY = Options.MainUI.AbsolutePosition.Y
                        local CurrentCanvasPosition = Options.Parent.Parent.CanvasPosition
                        --
                        if MainUICurrentY ~= MainUIStartingY then
                            MainUIStartingY = MainUICurrentY
                            StartingY = CurrentY
                            --
                            return
                        end
                        --
                        if CurrentCanvasPosition ~= StartingCanvasPosition then
                            StartingCanvasPosition = CurrentCanvasPosition
                            StartingY = CurrentY
                            --
                            return
                        end
                        --
                        if Library.UI.Resizing then
                            return
                        end
                        --
                        if CurrentY ~= StartingY then
                            ColorPicker:RemoveFrame(true)
                        end
                        --
                        StartingY = CurrentY
                    end)
                    --
                    Library:Connection(Options.MainUI:GetPropertyChangedSignal("AbsoluteSize"), function()
                        if ColorPicker.Active then
                            ColorPickerOutline.Visible = Library:ScrollingCheck(Options.Parent.Parent, ColorPickerChecker)
                        end
                        --
                        ColorPicker:UpdateSize()
                    end)
                    --
                    if Options.Parent.Parent:IsA("ScrollingFrame") then
                        Library:Connection(Options.Parent.Parent:GetPropertyChangedSignal("CanvasPosition"), function()
                            ColorPicker:UpdateSize()
                            --
                            if ColorPicker.Active then
                                ColorPickerOutline.Visible = Library:ScrollingCheck(Options.Parent.Parent, ColorPickerChecker)
                            end
                        end)
                    end
                    --
                    Library:Connection(Options.MainUI:GetPropertyChangedSignal("Visible"), function()
                        if not Options.MainUI.Visible then
                            ColorPickerOutline.Visible = false
                        else
                            ColorPickerOutline.Visible = ColorPicker.Active
                        end
                    end)
                    --
                    Library:Connection(Options.Parent.Parent:GetPropertyChangedSignal("Visible"), function()
                        if not Options.Parent.Parent.Visible then
                            ColorPickerOutline.Visible = false
                        else
                            ColorPickerOutline.Visible = ColorPicker.Active
                        end
                    end)
                    --
                    function ColorPicker:Update()
                        ColorPicker.Color = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Saturation[1], ColorPicker.Saturation[2])
                        ColorPicker.SecondColor = Color3.fromRGB(math.max(math.floor(ColorPicker.Color.R * 255) - 23, 0), math.max(math.floor(ColorPicker.Color.G * 255) - 23, 0), math.max(math.floor(ColorPicker.Color.B * 255) - 23, 0))
                        --
                        UIGradient_24.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ColorPicker.Color), ColorSequenceKeypoint.new(1, ColorPicker.SecondColor)}
                        UIGradient_20.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ColorPicker.Color), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))}
                        UIGradient_21.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, ColorPicker.Color), ColorSequenceKeypoint.new(1, ColorPicker.Color)}
                        UIGradient_20.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromHSV(ColorPicker.Hue, 1, 1)), ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255))}
                        --
                        local MaxSaturationX = math.max(0, MainPickerColor.AbsoluteSize.X - DraggingMainOutline.AbsoluteSize.X) / MainPickerColor.AbsoluteSize.X
                        local MaxSaturationY = math.max(0, MainPickerColor.AbsoluteSize.Y - DraggingMainOutline.AbsoluteSize.Y) / MainPickerColor.AbsoluteSize.Y
                        local MaxAlpha = math.max(0, SaturationColor.AbsoluteSize.X - DraggingSatOutline.AbsoluteSize.X) / SaturationColor.AbsoluteSize.X
                        local MaxHue = math.max(0, BackImage_2.AbsoluteSize.Y - DraggingHueOutline.AbsoluteSize.Y) / BackImage_2.AbsoluteSize.Y
                        --
                        Library:TweenObject(DraggingMainOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromScale(math.clamp(ColorPicker.Saturation[1], 0, MaxSaturationX), math.clamp(1 - ColorPicker.Saturation[2], 0, MaxSaturationY))})
                        Library:TweenObject(DraggingSatOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(math.clamp(1 - ColorPicker.Alpha, 0, MaxAlpha), 0, 0, 0)})
                        Library:TweenObject(DraggingHueOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, math.clamp(ColorPicker.Hue, 0, MaxHue), 0)})
                        --
                        DraggingMain.BackgroundColor3 = ColorPicker.Color
                        DraggingSatMain.BackgroundColor3 = ColorPicker.Color
                        DraggingHueMain.BackgroundColor3 = ColorPicker.Color
                        ColorPickerInline_1.BackgroundTransparency = ColorPicker.Alpha
                        UIGradient_21.Transparency = NumberSequence.new{NumberSequenceKeypoint.new(0, 0.304 + (0.604 - 0.304) * ColorPicker.Alpha), NumberSequenceKeypoint.new(0.5, 0.7), NumberSequenceKeypoint.new(1, 1)}
                        --
                        Options.Callback(ColorPicker.Color, ColorPicker.Alpha)
                        Library.Flags[Options.Flag] = ColorPicker
                    end
                    --
                    function ColorPicker:Set(Color, Transparency)
                        if typeof(Color) == "table" then
                            ColorPicker.Color = Color3.fromHSV(Color[1], Color[2], Color[3])
                            ColorPicker.Alpha = Color[4]
                            ColorPicker.Hue = Color[1]
                            ColorPicker.Saturation[1] = Color[2]
                            ColorPicker.Saturation[2] = Color[3]
                            ColorPicker:Update()
                            Options.Callback(ColorPicker.Color, ColorPicker.Alpha)
                        elseif typeof(Color) == "Color3" then
                            local h, s, v = Color:ToHSV()
                            --
                            ColorPicker.Color = Color3.fromHSV(h, s, v)
                            ColorPicker.Alpha = Transparency or 1
                            ColorPicker.Hue = h
                            ColorPicker.Saturation[1] = s
                            ColorPicker.Saturation[2] = v
                            ColorPicker:Update()
                            Options.Callback(ColorPicker.Color, ColorPicker.Alpha)
                        end
                    end
                    --
                    function ColorPicker:Get()
                        return {Color = ColorPicker.Color, Transparency = ColorPicker.Alpha}
                    end
                    --
                    function ColorPicker:UpdateHue(Percentage)
                        local Percentage = typeof(Percentage == "number") and math.clamp(Percentage, 0, 1) or 0
                        --
                        ColorPicker.Hue = Percentage
                        --
                        ColorPicker:Update()
                    end
                    --
                    function ColorPicker:UpdateAlpha(Percentage)
                        local Percentage = typeof(Percentage == "number") and math.clamp(Percentage, 0, 1) or 0
                        --
                        ColorPicker.Alpha = Percentage
                        --
                        ColorPicker:Update()
                    end
                    --
                    function ColorPicker:UpdateSaturation(PercentageX, PercentageY)
                        local PercentageX = typeof(PercentageX == "number") and math.clamp(PercentageX, 0, 1) or 0
                        local PercentageY = typeof(PercentageY == "number") and math.clamp(PercentageY, 0, 1) or 0
                        --
                        ColorPicker.Saturation[1] = PercentageX
                        ColorPicker.Saturation[2] = 1 - PercentageY
                        --
                        ColorPicker:Update()
                    end
                end
                --
                do -- Connections
                    Library:Connection(Button_91.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Library.UI.DraggingGui = MainPickerColor
                            --
                            local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
                            local Percentage = (InputPosition - MainPickerColor.AbsolutePosition) / MainPickerColor.AbsoluteSize
                            --
                            ColorPicker:UpdateSaturation(Percentage.X, Percentage.Y)
                        end
                    end)
                    --
                    Library:Connection(Button_915241.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Library.UI.DraggingGui = SaturationColor
                            --
                            local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
                            local GuiPosition = SaturationColor.AbsolutePosition.X
                            local GuiSize = SaturationColor.AbsoluteSize.X
                            local Percentage = ((GuiPosition + GuiSize - InputPosition.X) / GuiSize)
                            --
                            ColorPicker:UpdateAlpha(Percentage)
                        end
                    end)
                    --
                    Library:Connection(Button_9141.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Library.UI.DraggingGui = BackImage_2
                            --
                            local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
                            local Percentage = (InputPosition - BackImage_2.AbsolutePosition) / BackImage_2.AbsoluteSize
                            --
                            ColorPicker:UpdateHue(Percentage.Y)
                        end
                    end)
                    --
                    Library:Connection(UserInputService.InputChanged, function(Input)
                        if (Library.UI.DraggingGui ~= SaturationColor and Library.UI.DraggingGui ~= MainPickerColor and Library.UI.DraggingGui ~= BackImage_2) then return end
                        --
                        if not (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
                            Library.UI.DraggingGui = nil
                            return
                        end
                        --
                        local InputPosition = Vector2.new(Input.Position.X, Input.Position.Y)
                        --
                        if (Input.UserInputType == Enum.UserInputType.MouseMovement) then
                            if Library.UI.DraggingGui == MainPickerColor then
                                local Percentage = (InputPosition - MainPickerColor.AbsolutePosition) / MainPickerColor.AbsoluteSize
                                --
                                ColorPicker:UpdateSaturation(Percentage.X, Percentage.Y)
                            end
                            --
                            if Library.UI.DraggingGui == SaturationColor then
                                local GuiPosition = SaturationColor.AbsolutePosition.X
                                local GuiSize = SaturationColor.AbsoluteSize.X
                                local Percentage = ((GuiPosition + GuiSize - InputPosition.X) / GuiSize)
                                --
                                ColorPicker:UpdateAlpha(Percentage)
                            end
                            --
                            if Library.UI.DraggingGui == BackImage_2 then
                                local Percentage = (InputPosition - BackImage_2.AbsolutePosition) / BackImage_2.AbsoluteSize
                                --
                                ColorPicker:UpdateHue(Percentage.Y)
                            end
                        end
                    end)
                end
                --
                ColorPicker:Update()
                Library:Fade(true, Library:GetObjectsTable(ColorPickerOutline, true), ColorPickerOutline, 0.1)
            end
            --
            function ColorPicker:RemoveFrame(Fast)
                local Fast = Fast or false
                --
                for Index, Value in Library.UI.ScreenGUI:GetChildren() do
                    if Value:IsA("Frame") and Value.Name == "ColorPickerFrame" .. Library.UI.TotalColorPickers then
                        if Fast then
                            Value:Destroy()
                        else
                            Library:Fade(false, Library:GetObjectsTable(Value, true), Value, 0.1)
                            --
                            task.delay(Library.UI.TweenSpeed, function()
                                Value:Destroy()
                            end)
                        end
                    end
                end
            end
            --
            function ColorPicker:FindFrame()
                for Index, Value in Library.UI.ScreenGUI:GetChildren() do
                    if Value:IsA("Frame") and Value.Name == "ColorPickerFrame" .. Library.UI.TotalColorPickers then
                        return true
                    end
                end
                --
                return false
            end
            --
            function ColorPicker:Toggle()
                if Library.UI.CurrentSelectedColorPicker and Library.UI.CurrentSelectedColorPicker.ColorPickerOutline.Name ~= ColorPickerOutline_1.Name then
                    Library.UI.CurrentSelectedColorPicker.ColorPicker:RemoveFrame()
                end
                --
                if not ColorPicker:FindFrame() then
                    ColorPicker.Active = true
                    ColorPicker:AddFrame()
                else
                    ColorPicker.Active = false
                    ColorPicker:RemoveFrame()
                end
            end
            --
            function ColorPicker:AddOtherFrame()
                Library.UI.CurrentSelectedColorPickerExtra = {ColorPicker = ColorPicker, ColorPickerObject = ColorPickerOutline_1, Parent = Options.Parent}
                --
                local KeybindModePickerOutline = Library:CreateObject("Frame", {
                    Name = "ColorPickerOutline" .. Library.UI.TotalColorPickers,
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(0, 100, 0, 55),
                    BorderSizePixel = 0,
                    ZIndex = 25,
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = Library.UI.ScreenGUI
                })
                --
                local KeybindModePickerMain = Library:CreateObject("Frame", {
                    Name = "KeybindModePickerMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    ZIndex = 25,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Parent = KeybindModePickerOutline
                })
                --
                KeybindModePickerOutline.BackgroundTransparency = 1
                KeybindModePickerMain.BackgroundTransparency = 1
                --
                local UIListLayout_9 = Library:CreateObject("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = KeybindModePickerMain
                })
                --
                function ColorPicker:UpdateSize()
                    KeybindModePickerOutline.Position = UDim2.new(0, ColorPickerOutline_1.AbsolutePosition.X - 2, 0, ColorPickerOutline_1.AbsolutePosition.Y + ColorPickerOutline_1.AbsoluteSize.Y + KeybindModePickerOutline.AbsoluteSize.Y - 4)
                end
                --
                ColorPicker:UpdateSize()
                --
                Library:Connection(Options.MainUI:GetPropertyChangedSignal("AbsolutePosition"), ColorPicker.UpdateSize)
                --
                local StartingY = ColorPickerOutline_1.AbsolutePosition.Y
                local MainUIStartingY = Options.MainUI.AbsolutePosition.Y
                local StartingCanvasPosition = Options.Parent.Parent.CanvasPosition
                --
                Library:Connection(ColorPickerOutline_1:GetPropertyChangedSignal("AbsolutePosition"), function()
                    local CurrentY = ColorPickerOutline_1.AbsolutePosition.Y
                    local MainUICurrentY = Options.MainUI.AbsolutePosition.Y
                    local CurrentCanvasPosition = Options.Parent.Parent.CanvasPosition
                    --
                    if MainUICurrentY ~= MainUIStartingY then
                        MainUIStartingY = MainUICurrentY
                        StartingY = CurrentY
                        --
                        return
                    end
                    --
                    if CurrentCanvasPosition ~= StartingCanvasPosition then
                        StartingCanvasPosition = CurrentCanvasPosition
                        StartingY = CurrentY
                        --
                        return
                    end
                    --
                    if Library.UI.Resizing then
                        return
                    end
                    --
                    if CurrentY ~= StartingY then
                        ColorPicker:RemoveOtherFrame(true)
                    end
                    --
                    StartingY = CurrentY
                end)
                --
                Library:Connection(Options.MainUI:GetPropertyChangedSignal("AbsoluteSize"), function()
                    if ColorPicker.ActiveFrame then
                        KeybindModePickerOutline.Visible = Library:ScrollingCheck(Options.Parent.Parent, ColorPickerChecker)
                    end
                    --
                    ColorPicker:UpdateSize()
                end)
                --
                if Options.Parent.Parent:IsA("ScrollingFrame") then
                    Library:Connection(Options.Parent.Parent:GetPropertyChangedSignal("CanvasPosition"), function()
                        ColorPicker:UpdateSize()
                        --
                        if ColorPicker.ActiveFrame then
                            KeybindModePickerOutline.Visible = Library:ScrollingCheck(Options.Parent.Parent, ColorPickerChecker)
                        end
                    end)
                end
                --
                for Index, Value in {"Copy", "Paste", "Reset"} do
                    local ModeItem = {
                        Active = false,
                        Hovering = false,
                    }
                    --
                    local Inactive = Library:CreateObject("TextLabel", {
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextColor3 = Color3.fromRGB(208, 208, 208),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = Value,
                        Text = Value,
                        RichText = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Size = UDim2.new(1, 0, 0, 17),
                        BorderSizePixel = 0,
                        TextSize = Library.UI.FontSize,
                        ZIndex = 25,
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                        Parent = KeybindModePickerMain
                    })
                    --
                    local Button_4 = Library:CreateObject("TextButton", {
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Button_4",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        BorderSizePixel = 0,
                        TextTransparency = 1,
                        TextSize = Library.UI.FontSize,
                        ZIndex = 25,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Parent = Inactive
                    })
                    --
                    local UIPadding_48 = Library:CreateObject("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        Parent = Inactive
                    })
                    --
                    Inactive.TextTransparency = 1
                    --
                    do -- Functions
                        function ModeItem:Activate()
                            if not ModeItem.Active then
                                ModeItem.Active = true
                                --
                                Inactive.Text = "<b>" .. Value .. "</b>"
                                Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Default.Accent})
                                --
                                if Value == "Copy" then
                                    Library.UI.LastCopiedColor = {Color = ColorPicker.Color, Alpha = ColorPicker.Alpha}
                                elseif Value == "Paste" then
                                    if Library.UI.LastCopiedColor then
                                        ColorPicker:Set(Library.UI.LastCopiedColor.Color, Library.UI.LastCopiedColor.Alpha)
                                    end
                                elseif Value == "Reset" then
                                    ColorPicker:Set(Options.Default, Options.Alpha)
                                end
                                --
                                ColorPicker:RemoveOtherFrame()
                            end
                        end
                        --
                        function ModeItem:Deactivate()
                            if ModeItem.Active then
                                ModeItem.Active = false
                                ModeItem.Hovering = false
                                Inactive.Text = Value
                                Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                            end
                        end
                    end
                    --
                    do -- Connections
                        Library:Connection(Button_4.MouseButton1Click, function()
                            ModeItem:Activate()
                        end)
                        --
                        Library:Connection(Inactive.MouseEnter, function()
                            Inactive.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                            --
                            if ModeItem.Active then return end
                            --
                            Inactive.Text = "<b>" .. Value .. "</b>"
                        end)
                        --
                        Library:Connection(Inactive.MouseLeave, function()
                            Inactive.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                            --
                            if ModeItem.Active then return end
                            --
                            Inactive.Text = Value
                            Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                        end)
                    end
                end
                --
                Library:Fade(true, Library:GetObjectsTable(KeybindModePickerOutline, true), KeybindModePickerOutline, 0.1)
            end
            --
            function ColorPicker:RemoveOtherFrame(Fast)
                local Fast = Fast or false
                --
                for Index, Value in Library.UI.ScreenGUI:GetChildren() do
                    if Value:IsA("Frame") and Value.Name == "ColorPickerOutline" .. Library.UI.TotalColorPickers then
                        if Fast then
                            Value:Destroy()
                        else
                            Library:Fade(false, Library:GetObjectsTable(Value, true), Value, 0.1)
                            --
                            task.delay(Library.UI.TweenSpeed, function()
                                Value:Destroy()
                            end)
                        end
                    end
                end
            end
            --
            function ColorPicker:FindOtherFrame()
                for Index, Value in Library.UI.ScreenGUI:GetChildren() do
                    if Value:IsA("Frame") and Value.Name == "ColorPickerOutline" .. Library.UI.TotalColorPickers then
                        return true
                    end
                end
                --
                return false
            end
            --
            function ColorPicker:ToggleOtherFrame()
                if Library.UI.CurrentSelectedColorPickerExtra and Library.UI.CurrentSelectedColorPickerExtra.ColorPickerObject.Name ~= ColorPickerOutline_1.Name then
                    Library.UI.CurrentSelectedColorPickerExtra.ColorPicker:RemoveFrame()
                end
                --
                if not ColorPicker:FindOtherFrame() then
                    ColorPicker.ActiveFrame = true
                    ColorPicker:AddOtherFrame()
                else
                    ColorPicker.ActiveFrame = false
                    ColorPicker:RemoveOtherFrame()
                end
            end
        end
        --
        do -- Connections
            Library:Connection(Button_9.MouseButton2Click, function()
                ColorPicker:ToggleOtherFrame()
            end)
            --
            Library:Connection(Button_9.MouseButton1Click, function()
                ColorPicker:Toggle()
            end)
        end
        --
        ColorPicker:AddFrame()
        ColorPicker:Update()
        ColorPicker:RemoveFrame()
        --
        return ColorPicker
    end
    --
    function Library:Keybind(Options)
        Options = Library:Validate({
            Default = Enum.KeyCode.Backspace,
            Mode = "Toggle",
            UseMode = true,
            HideFromList = false,
            Blacklisted = {},
            Parent = nil,
            Toggle = nil,
            MainUI = nil,
            Hiding = false,
            ToggleState = false,
            Flag = Library.NewFlag(),
            Count = 1,
            ChangeToggle = false,
            Callback = function() end,
        }, Options or {})
        --
        if Options.Toggle == nil then return end
        --
        local Keybind = {
            Hover = false,
            ActiveFrame = false,
            Keybind = Options.Default,
            RegKeybind = nil,
            State = false,
            SelectingKeybind = false,
            Toggle = false,
            Connection = nil,
            Mode = Options.Mode,
            ConfigKeybind = nil,
            Current = {},
            CurrentMode = nil,
            Hiding = false,
        }
        --
        Library.Flags[Options.Flag] = Keybind
        Library.UI.TotalKeybindModes += 1
        --
        local KeybindObject = Library:CreateObject("TextLabel", {
            FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Color3.fromRGB(117, 117, 117),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = "[-]",
            Name = "KeybindOutline" .. Library.UI.TotalKeybindModes,
            AnchorPoint = Vector2.new(1, 0),
            BorderSizePixel = 0,
            Size = UDim2.new(0, 16, 0, 7),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0 - (Options.Count - 1) * 22, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 3,
            TextStrokeTransparency = 0,
            TextSize = 9,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local KeybindChecker = Library:CreateObject("Frame", {
            Position = UDim2.new(0, 0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            Visible = false,
            BorderSizePixel = 0,
            Parent = KeybindObject
        })
        --
        local Button_4 = Library:CreateObject("TextButton", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button_4",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextTransparency = 1,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = KeybindObject
        })
        --
        local UserInputTypeBinds = {"MouseButton1", "MouseButton2", "MouseButton3"}
        --
        do -- Functions
            function Keybind:SetVisible(Bool)
                local OldValues = Library.Objects[KeybindObject]
                --
                Keybind.Hiding = not Bool
                --
                if Bool then
                    Library.Objects[KeybindObject] = {KeybindObject, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(KeybindObject), KeybindObject, 0.075)
                Library:TweenObject(KeybindObject, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and UDim2.new(1, 0, 0, 8) or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[KeybindObject] = {KeybindObject, OldValues[2], false}
                    end
                end)
            end
            --
            function Keybind:Set(Key)
                if Keybind.Hiding then return end
                if typeof(Key) == "boolean" then return end
                --
                if typeof(Key) == "EnumItem" then
                    Keybind.RegKeybind = Key
                elseif typeof(Key) == "string" then
                    if table.find(UserInputTypeBinds, Key) then
                        Keybind.RegKeybind = Enum.UserInputType[Key]
                        Key = Enum.UserInputType[Key]
                    else
                        Keybind.RegKeybind = Enum.KeyCode[Key]
                        Key = Enum.KeyCode[Key]
                    end
                end
                --
                if typeof(Key) == "string" then
                    if Key:find("KEY") then
                        Key = Enum.KeyCode[Key:gsub("KEY_", "")]
                    elseif Key:find("Input") then
                        Key = Enum.UserInputType[Key:gsub("Input_", "")]
                    end
                end
                --
                local ValidKey = false
                local KeyString = ""
                --
                if table.find(Options.Blacklisted, Key) then
                    Key = nil
                end
                --
                if Key then
                    if ((Key.EnumType == Enum.KeyCode and UserInputService:GetStringForKeyCode(Key) ~= "") or Library.UI.Keys[Key]) then
                        ValidKey = true
                        KeyString = Library.UI.Keys[Key] or UserInputService:GetStringForKeyCode(Key)
                    end
                end
                --
                if ValidKey then
                    Keybind.Keybind = KeyString
                    KeybindObject.Text = "[" .. KeyString:upper() .. "]"
                    --
                    Options.Callback(Key)
                    Library.Flags[Options.Flag] = Keybind
                else
                    Keybind.Keybind = "[-]"
                    KeybindObject.Text = Keybind.Keybind
                end
                --
                Library:TweenObject(KeybindObject, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(117, 117, 117)})
                KeybindObject.Size = UDim2.new(0, KeybindObject.TextBounds.X + 2, 0, 7)
            end
            --
            function Keybind:Toggle(Bool)
                if Keybind.Hiding then return end
                --
                if Bool == nil then
                    Keybind.State = not Keybind.State
                else
                    Keybind.State = Bool
                end
                --
                if not Options.HideFromList then
                    if Keybind.State then
                        --Library:AddKeybindFrame(Keybind.Mode, Options.Toggle:GetName(), Keybind.Keybind, Options.Toggle:GetSection())
                    else
                        --Library:RemoveKeybindFrame(Options.Toggle:GetName(), Options.Toggle:GetSection())
                    end
                end
                --
                if Options.Toggle.GetFlag then
                    Library.Flags[Options.Toggle:GetFlag()] = Keybind
                end
                --
                if Options.ChangeToggle then
                    -- viuslaly toggle the UI element and update its state
                    Options.Toggle:Set(Keybind.State)
                else
                    Options.Toggle:GetCallback(Keybind.State)
                end
            end
            --
            task.delay(1, function()
                Keybind:Set(Options.Default)
            end)
            --
            function Keybind:Get()
                local KeyString = Keybind.RegKeybind.EnumType == Enum.KeyCode and tostring(Keybind.RegKeybind):match("^Enum%.KeyCode%.(.+)$") or tostring(Keybind.RegKeybind):match("^Enum%.UserInputType%.(.+)$")
                --
                return KeyString
            end
            --
            function Keybind:Active()
                return (Keybind.Keybind:lower() == "[-]" and true or Keybind.State)
            end
            --
            if Options.Mode == "Always on" then
                Keybind:Toggle(true)
            end
            --
            function Keybind:SetMode(Mode)
                Keybind.Mode = Mode
                --
                if Mode == "Always on" then
                    if Mode == "Always on" then
                        Keybind:Toggle(true)
                    end
                    --
                    if not Keybind.State then
                        Keybind.State = true
                        --
                        --Library:AddKeybindFrame(Mode, Options.Toggle:GetName(), Keybind.Keybind, Options.Toggle:GetSection())
                    else
                        --Library:UpdateKeybindFrame(Mode, Options.Toggle:GetName(), Keybind.Keybind, Options.Toggle:GetSection())
                    end
                elseif Mode == "Toggle" then
                    if Keybind.State then
                        --Library:UpdateKeybindFrame(Mode, Options.Toggle:GetName(), Keybind.Keybind, Options.Toggle:GetSection())
                    end
                elseif Mode == "On hotkey" then
                    Keybind.State = false
                    --
                    --Library:RemoveKeybindFrame(Options.Toggle:GetName(), Options.Toggle:GetSection())
                end
            end
            --
            function Keybind:AddFrame()
                Library.UI.CurrentSelectedKeybindMode = {Keybind = Keybind, KeybindObject = KeybindObject, Parent = Options.Parent}
                --
                local KeybindModePickerOutline = Library:CreateObject("Frame", {
                    Name = "KeybindModePickerOutline" .. Library.UI.TotalKeybindModes,
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(0, 100, 0, 55),
                    BorderSizePixel = 0,
                    ZIndex = 25,
                    AnchorPoint = Vector2.new(1, 0),
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = Library.UI.ScreenGUI
                })
                --
                local KeybindModePickerMain = Library:CreateObject("Frame", {
                    Name = "KeybindModePickerMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    ZIndex = 25,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Parent = KeybindModePickerOutline
                })
                --
                KeybindModePickerOutline.BackgroundTransparency = 1
                KeybindModePickerMain.BackgroundTransparency = 1
                --
                local UIListLayout_9 = Library:CreateObject("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = KeybindModePickerMain
                })
                --
                function Keybind:UpdateSize()
                    KeybindModePickerOutline.Position = UDim2.new(0, KeybindObject.AbsolutePosition.X , 0, KeybindObject.AbsolutePosition.Y + KeybindObject.AbsoluteSize.Y + KeybindModePickerOutline.AbsoluteSize.Y - 2)
                end
                --
                Keybind:UpdateSize()
                --
                Library:Connection(Options.MainUI:GetPropertyChangedSignal("AbsolutePosition"), Keybind.UpdateSize)
                --
                local StartingY = KeybindObject.AbsolutePosition.Y
                local MainUIStartingY = Options.MainUI.AbsolutePosition.Y
                local StartingCanvasPosition = Options.Parent.Parent.CanvasPosition
                --
                Library:Connection(KeybindObject:GetPropertyChangedSignal("AbsolutePosition"), function()
                    local CurrentY = KeybindObject.AbsolutePosition.Y
                    local MainUICurrentY = Options.MainUI.AbsolutePosition.Y
                    local CurrentCanvasPosition = Options.Parent.Parent.CanvasPosition
                    --
                    if MainUICurrentY ~= MainUIStartingY then
                        MainUIStartingY = MainUICurrentY
                        StartingY = CurrentY
                        --
                        return
                    end
                    --
                    if CurrentCanvasPosition ~= StartingCanvasPosition then
                        StartingCanvasPosition = CurrentCanvasPosition
                        StartingY = CurrentY
                        --
                        return
                    end
                    --
                    if Library.UI.Resizing then
                        return
                    end
                    --
                    if CurrentY ~= StartingY then
                        Keybind:RemoveFrame(true)
                    end
                    --
                    StartingY = CurrentY
                end)
                --
                Library:Connection(Options.MainUI:GetPropertyChangedSignal("AbsoluteSize"), function()
                    if Keybind.ActiveFrame then
                        KeybindModePickerOutline.Visible = Library:ScrollingCheck(Options.Parent.Parent, KeybindChecker)
                    end
                    --
                    Keybind:UpdateSize()
                end)
                --
                Library:Connection(KeybindObject:GetPropertyChangedSignal("AbsoluteSize"), function()
                    Keybind:UpdateSize()
                end)
                --
                if Options.Parent.Parent:IsA("ScrollingFrame") then
                    Library:Connection(Options.Parent.Parent:GetPropertyChangedSignal("CanvasPosition"), function()
                        Keybind:UpdateSize()
                        --
                        if Keybind.ActiveFrame then
                            KeybindModePickerOutline.Visible = Library:ScrollingCheck(Options.Parent.Parent, KeybindChecker)
                        end
                    end)
                end
                --
                for Index, Value in {"Always on", "On hotkey", "Toggle"} do
                    local ModeItem = {
                        Active = false,
                        Hovering = false,
                    }
                    --
                    local Inactive = Library:CreateObject("TextLabel", {
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextColor3 = Color3.fromRGB(208, 208, 208),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = Value,
                        Text = Value,
                        RichText = true,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Size = UDim2.new(1, 0, 0, 17),
                        BorderSizePixel = 0,
                        TextSize = Library.UI.FontSize,
                        ZIndex = 25,
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                        Parent = KeybindModePickerMain
                    })
                    --
                    local Button_4 = Library:CreateObject("TextButton", {
                        FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Button_4",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        BorderSizePixel = 0,
                        TextTransparency = 1,
                        TextSize = Library.UI.FontSize,
                        ZIndex = 25,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Parent = Inactive
                    })
                    --
                    local UIPadding_48 = Library:CreateObject("UIPadding", {
                        PaddingLeft = UDim.new(0, 8),
                        Parent = Inactive
                    })
                    --
                    Inactive.TextTransparency = 1
                    --
                    do -- Functions
                        function ModeItem:Activate()
                            if not ModeItem.Active then
                                if Keybind.CurrentMode ~= nil then
                                    Keybind.CurrentMode:Deactivate()
                                end
                                --
                                ModeItem.Active = true
                                --
                                Keybind.Mode = Value
                                Keybind.CurrentMode = ModeItem
                                --
                                Inactive.Text = "<b>" .. Value .. "</b>"
                                Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Default.Accent})
                                --
                                if Value == "Always on" then
                                    if Keybind.Mode == "Always on" then
                                        Keybind:Toggle(true)
                                    end
                                    --
                                    if not Keybind.State then
                                        Keybind.State = true
                                        --
                                        --Library:AddKeybindFrame(Value, Options.Toggle:GetName(), Keybind.Keybind, Options.Toggle:GetSection())
                                    else
                                        --Library:UpdateKeybindFrame(Value, Options.Toggle:GetName(), Keybind.Keybind, Options.Toggle:GetSection())
                                    end
                                elseif Value == "Toggle" then
                                    if Keybind.State then
                                        --Library:UpdateKeybindFrame(Value, Options.Toggle:GetName(), Keybind.Keybind, Options.Toggle:GetSection())
                                    end
                                elseif Value == "On hotkey" then
                                    Keybind.State = false
                                    --
                                    --Library:RemoveKeybindFrame(Options.Toggle:GetName(), Options.Toggle:GetSection())
                                end
                            end
                        end
                        --
                        function ModeItem:Deactivate()
                            if ModeItem.Active then
                                ModeItem.Active = false
                                ModeItem.Hovering = false
                                Inactive.Text = Value
                                Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                            end
                        end
                    end
                    --
                    do -- Connections
                        Library:Connection(Button_4.MouseButton1Click, function()
                            ModeItem:Activate()
                        end)
                        --
                        Library:Connection(Inactive.MouseEnter, function()
                            Inactive.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                            --
                            if ModeItem.Active then return end
                            --
                            Inactive.Text = "<b>" .. Value .. "</b>"
                        end)
                        --
                        Library:Connection(Inactive.MouseLeave, function()
                            Inactive.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                            --
                            if ModeItem.Active then return end
                            --
                            Inactive.Text = Value
                            Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                        end)
                    end
                    --
                    if Value == Keybind.Mode then
                        ModeItem:Activate()
                    end
                end
                --
                Library:Fade(true, Library:GetObjectsTable(KeybindModePickerOutline, true), KeybindModePickerOutline, 0.1)
            end
            --
            function Keybind:RemoveFrame(Fast)
                local Fast = Fast or false
                --
                for Index, Value in Library.UI.ScreenGUI:GetChildren() do
                    if Value:IsA("Frame") and Value.Name == "KeybindModePickerOutline" .. Library.UI.TotalKeybindModes then
                        if Fast then
                            Value:Destroy()
                        else
                            Library:Fade(false, Library:GetObjectsTable(Value, true), Value, 0.1)
                            --
                            task.delay(Library.UI.TweenSpeed, function()
                                Value:Destroy()
                            end)
                        end
                    end
                end
            end
            --
            function Keybind:FindFrame()
                for Index, Value in Library.UI.ScreenGUI:GetChildren() do
                    if Value:IsA("Frame") and Value.Name == "KeybindModePickerOutline" .. Library.UI.TotalKeybindModes then
                        return true
                    end
                end
                --
                return false
            end
            --
            function Keybind:ToggleFrame()
                Library:TweenObject(KeybindObject, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(176, 176, 176)})
                --
                if Library.UI.CurrentSelectedKeybindMode and Library.UI.CurrentSelectedKeybindMode.KeybindObject.Name ~= KeybindObject.Name then
                    Library.UI.CurrentSelectedKeybindMode.Keybind:RemoveFrame()
                    --
                    Library:TweenObject(Library.UI.CurrentSelectedKeybindMode.KeybindObject, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(117, 117, 117)})
                end
                --
                if not Keybind:FindFrame() then
                    Keybind.ActiveFrame = true
                    Keybind:AddFrame()
                else
                    Keybind.ActiveFrame = false
                    Keybind:RemoveFrame()
                end
            end
        end
        --
        do -- Connections
            Library:Connection(KeybindObject.MouseEnter, function()
                if Keybind.SelectingKeybind then return end
                --
                Library:TweenObject(KeybindObject, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(176, 176, 176)})
            end)
            --
            Library:Connection(KeybindObject.MouseLeave, function()
                if Keybind.SelectingKeybind then return end
                --
                Library:TweenObject(KeybindObject, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(117, 117, 117)})
            end)
            --
            Library:Connection(Button_4.MouseButton2Click, function()
                if not Options.UseMode then return end
                --
                Keybind:ToggleFrame()
            end)
            --
            Library:Connection(Button_4.MouseButton1Click, function()
                if Keybind.Connection then
                    Keybind.Connection:Disconnect()
                end
                --
                Keybind.SelectingKeybind = true
                --
                Library:TweenObject(KeybindObject, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(255, 0, 0)})
                --
                Keybind.Connection = Library:Connection(UserInputService.InputBegan, function(Input)
                    Keybind:Set(Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode or Input.UserInputType)
                    --
                    if Keybind.Connection then
                        Keybind.Connection:Disconnect()
                        --
                        task.delay(0.1, function()
                            Keybind.Connection = nil
                            Keybind.SelectingKeybind = false
                        end)
                    end
                end)
            end)
            --
            Library:Connection(UserInputService.InputBegan, function(Input, Proccessed)
                if Proccessed then return end
                --
                if (Input.UserInputType == Enum.UserInputType.Keyboard and Keybind.Keybind ~= "[-]" and Input.KeyCode == Keybind.RegKeybind) or (Input.UserInputType == Enum.UserInputType.MouseButton1 and Keybind.Keybind == "MB1") or (Input.UserInputType == Enum.UserInputType.MouseButton2 and Keybind.Keybind == "MB2") or (Input.UserInputType == Enum.UserInputType.MouseButton3 and Keybind.Keybind == "MMB") then
                    if Keybind.Mode == "Always on" then
                        Keybind:Toggle(true)
                    else
                        Keybind:Toggle()
                    end
                end
            end)
            --
            Library:Connection(UserInputService.InputEnded, function(Input, Proccessed)
                if Proccessed then return end
                --
                if Keybind.Mode == "On hotkey" then
                    if (Input.UserInputType == Enum.UserInputType.Keyboard and Keybind.Keybind ~= "[-]" and Input.KeyCode == Keybind.RegKeybind) or (Input.UserInputType == Enum.UserInputType.MouseButton1 and Keybind.Keybind == "MB1") or (Input.UserInputType == Enum.UserInputType.MouseButton2 and Keybind.Keybind == "MB2") or (Input.UserInputType == Enum.UserInputType.MouseButton3 and Keybind.Keybind == "MMB") then
                        Keybind:Toggle()
                    end
                end
            end)
        end
        --
        if Options.Hiding then
            Keybind:SetVisible(false)
        end
        --
        return Keybind
    end
    --
    function Library:MultiBox(Options)
        Options = Library:Validate({
            Default = "None",
            Name = "Preview MultiBox",
            Content = {},
            Parent = nil,
            MainUI = nil,
            Hiding = false,
            TabUI = nil,
            Risky = false,
            Flag = Library.NewFlag(),
            Callback = function() end
        }, Options or {})
        --
        local MultiBox = {
            Open = false,
            Hover = false,
            Items = Options.Content,
            Scrollable = false,
            Value = {},
            SelectedOrder = {},
            AllItems = {},
        }
        --
        Library.Flags[Options.Flag] = MultiBox
        Options.Callback(Options.Default)
        --
        local PreviewMultiBox_5 = Library:CreateObject("Frame", {
            Name = "PreviewMultiBox_5",
            BackgroundTransparency = 1,
            Size = Options.Name == "" and UDim2.new(1, 0, 0, 20) or UDim2.new(1, 0, 0, 31),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local MultiBoxOutline_5 = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            AnchorPoint = Vector2.new(0, 1),
            Name = "MultiBoxOutline_5",
            Position = UDim2.new(0, -1, 1, 0),
            Size = UDim2.new(1, -19, 0, 20),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = PreviewMultiBox_5
        })
        --
        local MultiBoxChecker = Library:CreateObject("Frame", {
            Name = "MultiBoxChecker",
            Position = UDim2.new(0, 0, 1, 0),
            Visible = false,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0,
            Parent = MultiBoxOutline_5
        })
        --
        local MultiBoxBack_5 = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "MultiBoxBack_5",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(220, 220, 220),
            Parent = MultiBoxOutline_5
        })
        --
        local MultiBoxArrow = Library:CreateObject("ImageLabel", {
            ImageColor3 = Color3.fromRGB(151, 151, 151),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "MultiBoxArrow",
            Image = "rbxassetid://15556784588",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -11, 0, 6),
            Size = UDim2.new(0, 5, 0, 4),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = MultiBoxBack_5
        })
        --
        local UIGradient_34 = Library:CreateObject("UIGradient", {
            Rotation = -90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 39, 39)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35))
            },
            Parent = MultiBoxBack_5
        })
        --
        local MultiBoxValue_5 = Library:CreateObject("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Color3.fromRGB(152, 152, 152),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = "None",
            Name = "MultiBoxValue_5",
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 3,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = MultiBoxBack_5
        })
        --
        local UIPadding_87 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 5),
            Parent = MultiBoxValue_5
        })
        --
        local Button_44 = Library:CreateObject("TextButton", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button_44",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextTransparency = 1,
            TextSize = 14,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = MultiBoxOutline_5
        })
        --
        local MultiBoxName_5 = Library:CreateObject("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Library.Theme.Default.TextColor,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = Options.Name,
            Name = "MultiBoxName_5",
            ZIndex = 3,
            Size = UDim2.new(1, -19, 1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, -4),
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewMultiBox_5
        })
        --
        local UIPadding_88 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 20),
            Parent = PreviewMultiBox_5
        })
        --
        local MultiBoxMainOutline = Library:CreateObject("Frame", {
            Name = "MultiBoxMainOutline",
            Position = UDim2.new(0, 0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 10,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = Library.UI.ScreenGUI
        })
        --
        local MultiBoxMain = Library:CreateObject("Frame", {
            Name = "MultiBoxMain",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            ZIndex = 10,
            ClipsDescendants = true,
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            Parent = MultiBoxMainOutline
        })
        --
        MultiBoxMainOutline.BackgroundTransparency = 1
        MultiBoxMain.BackgroundTransparency = 1
        --
        local UIListLayout_9 = Library:CreateObject("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = MultiBoxMain
        })
        --
        do -- Functions
            function MultiBox:Set(Values)
                for Index, Item in MultiBox.AllItems do
                    if not table.find(Values, Index) then
                        MultiBox.Items[Index] = false
                    else
                        MultiBox.Items[Index] = true
                    end
                    --
                    Item:Toggle()
                end
            end
            --
            function MultiBox:Get()
                return MultiBox.Value
            end
            --
            function MultiBox:SetVisible(Bool)
                local OldValues = Library.Objects[PreviewMultiBox_5]
                --
                MultiBox.Hiding = not Bool
                --
                if Bool then
                    Library.Objects[PreviewMultiBox_5] = {PreviewMultiBox_5, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(PreviewMultiBox_5), PreviewMultiBox_5, 0.075)
                Library:TweenObject(PreviewMultiBox_5, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and (Options.Name == "" and UDim2.new(1, 0, 0, 20) or UDim2.new(1, 0, 0, 31)) or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[PreviewMultiBox_5] = {PreviewMultiBox_5, OldValues[2], false}
                    end
                end)
            end
            --
            function MultiBox:AddValue(Value)
                local Item = {
                    Active = false,
                    Hovering = false,
                }
                --
                MultiBox.Items[Value] = Item
                --
                local Inactive = Library:CreateObject("TextLabel", {
                    FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextColor3 = Color3.fromRGB(208, 208, 208),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = Value,
                    Text = Value,
                    RichText = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = Library.UI.FontSize,
                    ZIndex = 10,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Parent = MultiBoxMain
                })
                --
                local Button_4 = Library:CreateObject("TextButton", {
                    FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Button_4",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextTransparency = 1,
                    TextSize = Library.UI.FontSize,
                    ZIndex = 11,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Inactive
                })
                --
                local UIPadding_48 = Library:CreateObject("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    Parent = Inactive
                })
                --
                Inactive.TextTransparency = 1
                --
                do -- Functions
                    function Item:GetSelectedItems()
                        local SelectedItems = {}
                        --
                        for _, Item in MultiBox.SelectedOrder do
                            if MultiBox.Items[Item] then
                                table.insert(SelectedItems, Item)
                            end
                        end
                        --
                        return SelectedItems
                    end
                    --
                    function MultiBox:UpdateValue()
                        MultiBox.Value = Item:GetSelectedItems()
                        --
                        MultiBoxValue_5.Text = Library:ClampString(table.concat(MultiBox.Value, ", "), MultiBoxMain.AbsoluteSize.X - MultiBoxArrow.AbsoluteSize.X - 4)
                    end
                    --
                    function Item:SelectItem(Item)
                        if not table.find(MultiBox.SelectedOrder, Item) then
                            table.insert(MultiBox.SelectedOrder, Item)
                        end
                        --
                        MultiBox:UpdateValue()
                    end

                    function Item:DeselectItem(Item)
                        for Index, Value in MultiBox.SelectedOrder do
                            if Value == Item then
                                table.remove(MultiBox.SelectedOrder, Index)
                                --
                                break
                            end
                        end
                        --
                        MultiBox:UpdateValue()
                    end
                    --
                    function Item:Activate()
                        if not Item.Active then
                            Item.Active = true
                            MultiBox.CurrentItem = Item
                            MultiBox.Items[Value] = true
                            Library.Flags[Options.Flag] = MultiBox
                            Item:SelectItem(Value)
                            Options.Callback(MultiBox.Value)
                            --
                            Inactive.Text = "<b>" .. Value .. "</b>"
                            Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Default.Accent})
                            Library:AddTheme(Inactive, {
                                TextColor3 = "Accent",
                            })
                        end
                    end
                    --
                    function Item:Deactivate()
                        if Item.Active then
                            Item.Active = false
                            Item.Hovering = false
                            MultiBox.CurrentItem = nil
                            Library.Flags[Options.Flag] = MultiBox
                            MultiBox.Items[Value] = false
                            Item:DeselectItem(Value)
                            Options.Callback(MultiBox.Value)
                            --
                            Inactive.Text = Value
                            Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                            Library:AddTheme(Inactive, {
                                TextColor3 = "TextColor",
                            })
                        end
                    end
                    --
                    function Item:Toggle()
                        MultiBox.Items[Value] = not MultiBox.Items[Value]
                        --
                        if MultiBox.Items[Value] then
                            Item:Activate()
                        else
                            Item:Deactivate()
                        end
                    end
                end
                --
                do -- Connections
                    Library:Connection(Button_4.MouseButton1Click, function()
                        if MultiBox.Hiding then return end
                        --
                        Item:Toggle()
                    end)
                    --
                    Library:Connection(Inactive.MouseEnter, function()
                        Inactive.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                        --
                        if Item.Active then return end
                        --
                        Inactive.Text = "<b>" .. Value .. "</b>"
                    end)
                    --
                    Library:Connection(Inactive.MouseLeave, function()
                        Inactive.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        --
                        if Item.Active then return end
                        --
                        Inactive.Text = Value
                        Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                    end)
                end
                --
                if typeof(Options.Default) == "table" and table.find(Options.Default, Value) then
                    Item:Activate()
                    Item:SelectItem(Value)
                else
                    MultiBox.Items[Value] = false
                end
            end
            --
            function MultiBox:Toggle(Fast)
                local Fast = Fast or false
                local OldValues = Library.Objects[MultiBoxMainOutline]
                --
                if MultiBox.Open then
                    if Fast then
                        Library:Fade(false, Library:GetObjectsTable(MultiBoxMainOutline, true), MultiBoxMainOutline, 0)
                        MultiBoxMainOutline.Size = UDim2.new(0, MultiBoxOutline_5.AbsoluteSize.X, 0, 0)
                        Library.Objects[MultiBoxMainOutline] = {MultiBoxMainOutline, OldValues[2], true}
                    else
                        Library:Fade(false, Library:GetObjectsTable(MultiBoxMainOutline, true), MultiBoxMainOutline, 0.1)
                        Library:TweenObject(MultiBoxMainOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, MultiBoxOutline_5.AbsoluteSize.X, 0, 0)}, function()
                            Library.Objects[MultiBoxMainOutline] = {MultiBoxMainOutline, OldValues[2], true}
                        end)
                    end
                else
                    Library.Objects[MultiBoxMainOutline] = {MultiBoxMainOutline, OldValues[2], false}
                    --
                    if Fast then
                        Library:Fade(true, Library:GetObjectsTable(MultiBoxMainOutline, true), MultiBoxMainOutline, 0)
                        MultiBoxMainOutline.Size = UDim2.new(0, MultiBoxOutline_5.AbsoluteSize.X, 0, (#Options.Content * 20) + 2)
                    else
                        Library:Fade(true, Library:GetObjectsTable(MultiBoxMainOutline, true), MultiBoxMainOutline, 0.1)
                        Library:TweenObject(MultiBoxMainOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, MultiBoxOutline_5.AbsoluteSize.X, 0, (#Options.Content * 20) + 2)})
                    end	
                end
                --
                MultiBox.Open = not MultiBox.Open
            end
            --
            function MultiBox:Update()
                MultiBoxMainOutline.Size = UDim2.new(0, MultiBoxOutline_5.AbsoluteSize.X, 0, MultiBoxMainOutline.AbsoluteSize.Y)
                MultiBoxMainOutline.Position = UDim2.new(0, MultiBoxOutline_5.AbsolutePosition.X, 0, ((MultiBoxOutline_5.AbsolutePosition.Y + MultiBoxOutline_5.AbsoluteSize.Y) + GuiService:GetGuiInset().Y + 2))
                --
                if MultiBox.Open then
                    MultiBoxMainOutline.Visible = Library:ScrollingCheck(Options.Parent, MultiBoxChecker)
                end
            end
            --
            MultiBox:Update()
            --
            Library:Connection(MultiBoxOutline_5:GetPropertyChangedSignal("AbsolutePosition"), MultiBox.Update)
            Library:Connection(MultiBoxOutline_5:GetPropertyChangedSignal("AbsoluteSize"), MultiBox.Update)
            --
            local StartingX = PreviewMultiBox_5.AbsolutePosition.X
            local StartingY = PreviewMultiBox_5.AbsolutePosition.Y
            local MainUIStartingX = Options.MainUI.AbsolutePosition.X
            local MainUIStartingY = Options.MainUI.AbsolutePosition.Y
            local StartingCanvasPosition = Options.Parent.CanvasPosition
            --
            Library:Connection(PreviewMultiBox_5:GetPropertyChangedSignal("AbsolutePosition"), function()
                if not MultiBox.Open then return end
                --
                local CurrentX = PreviewMultiBox_5.AbsolutePosition.X
                local CurrentY = PreviewMultiBox_5.AbsolutePosition.Y
                local MainUICurrentX = Options.MainUI.AbsolutePosition.X
                local MainUICurrentY = Options.MainUI.AbsolutePosition.Y
                local CurrentCanvasPosition = Options.Parent.CanvasPosition
                --
                if MainUICurrentX ~= MainUIStartingX or MainUICurrentY ~= MainUIStartingY then
                    MainUIStartingX = MainUICurrentX
                    MainUIStartingY = MainUICurrentY
                    StartingX = CurrentX
                    StartingY = CurrentY
                    --
                    return
                end
                --
                if CurrentCanvasPosition ~= StartingCanvasPosition then
                    StartingCanvasPosition = CurrentCanvasPosition
                    StartingX = CurrentX
                    StartingY = CurrentY
                    --
                    return
                end
                --
                if Library.UI.Resizing then
                    return
                end
                --
                if CurrentX ~= StartingX or CurrentY ~= StartingY then
                    MultiBox:Toggle(true)
                end
                --
                StartingX = CurrentX
                StartingY = CurrentY
            end)
            --
            if Options.Parent:IsA("ScrollingFrame") then
                Library:Connection(Options.Parent:GetPropertyChangedSignal("CanvasPosition"), function()
                    MultiBox:Update()
                end)
            end
        end
        --
        do -- Connections
            Library:Connection(Button_44.MouseButton1Click, function()
                if MultiBox.Hiding then return end
                --
                MultiBox:Toggle()
            end)
            --
            Library:Connection(MultiBoxOutline_5.MouseEnter, function()
                if Library.UI.Faded then return end
                --
                if not MultiBox.Open then
                    MultiBox.Hovering = true
                    Library:TweenObject(MultiBoxBack_5, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                end	
            end)
            --
            Library:Connection(MultiBoxOutline_5.MouseLeave, function()
                if Library.UI.Faded then return end
                --
                if not MultiBox.Open then
                    MultiBox.Hovering = false
                    Library:TweenObject(MultiBoxBack_5, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)})
                end	
            end)
        end
        --
        for Index, Value in Options.Content do
            if typeof(Value) == "boolean" or typeof(Value) == "table" then continue end
            --
            MultiBox:AddValue(Value)
        end
        --
        Library:Fade(false, Library:GetObjectsTable(MultiBoxMainOutline, true), MultiBoxMainOutline, 0.1)
        --
        if Options.Hiding then
            MultiBox:SetVisible(false)
        end
        --
        MultiBox:Toggle(true)
        --
        return MultiBox
    end
    --
    function Library:Dropdown(Options)
        Options = Library:Validate({
            Default = "None",
            Name = "Preview Dropdown",
            Content = {},
            Parent = nil,
            MainUI = nil,
            Hiding = false,
            TabUI = nil,
            Risky = false,
            Flag = Library.NewFlag(),
            Callback = function() end
        }, Options or {})
        --
        local Dropdown = {
            Open = false,
            Active = false,
            Hovering = false,
            CurrentItem = nil,
            Scrollable = false,
            Hiding = false,
            Items = {},
            Value = Options.Default,
        }
        --
        Library.Flags[Options.Flag] = Dropdown
        --
        local PreviewDropdown_5 = Library:CreateObject("Frame", {
            Name = "PreviewDropdown_5",
            BackgroundTransparency = 1,
            Size = Options.Name == "" and UDim2.new(1, 0, 0, 20) or UDim2.new(1, 0, 0, 31),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local DropdownOutline_5 = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            AnchorPoint = Vector2.new(0, 1),
            Name = "DropdownOutline_5",
            Position = UDim2.new(0, -1, 1, 0),
            Size = UDim2.new(1, -19, 0, 20),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = PreviewDropdown_5
        })
        --
        local DropdownChecker = Library:CreateObject("Frame", {
            Name = "DropdownChecker",
            Position = UDim2.new(0, 0, 1, 0),
            Visible = false,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BorderSizePixel = 0,
            Parent = DropdownOutline_5
        })
        --
        local DropdownBack_5 = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "DropdownBack_5",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(220, 220, 220),
            Parent = DropdownOutline_5
        })
        --
        local DropdownArrow = Library:CreateObject("ImageLabel", {
            ImageColor3 = Color3.fromRGB(151, 151, 151),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "DropdownArrow",
            Image = "rbxassetid://15556784588",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -11, 0, 6),
            Size = UDim2.new(0, 5, 0, 4),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = DropdownBack_5
        })
        --
        local UIGradient_34 = Library:CreateObject("UIGradient", {
            Rotation = -90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 39, 39)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35))
            },
            Parent = DropdownBack_5
        })
        --
        local DropdownValue_5 = Library:CreateObject("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Color3.fromRGB(152, 152, 152),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = Options.Default ~= "None" and table.find(Options.Content, Options.Default) and Options.Default or "None",
            Name = "DropdownValue_5",
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 3,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = DropdownBack_5
        })
        --
        local UIPadding_87 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 5),
            Parent = DropdownValue_5
        })
        --
        local Button_44 = Library:CreateObject("TextButton", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button_44",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextTransparency = 1,
            TextSize = 14,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = DropdownOutline_5
        })
        --
        local DropdownName_5 = Library:CreateObject("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Library.Theme.Default.TextColor,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = Options.Name,
            Name = "DropdownName_5",
            ZIndex = 3,
            Position = UDim2.new(0, 0, 0, -4),
            Size = UDim2.new(1, -19, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewDropdown_5
        })
        --
        local UIPadding_88 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 20),
            Parent = PreviewDropdown_5
        })
        --
        local DropdownMainOutline = Library:CreateObject("Frame", {
            Name = "DropdownMainOutline",
            Position = UDim2.new(0, 0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 10,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = Library.UI.ScreenGUI
        })
        --
        local DropdownMain = Library:CreateObject("Frame", {
            Name = "DropdownMain",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            ZIndex = 10,
            ClipsDescendants = true,
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            Parent = DropdownMainOutline
        })
        --
        DropdownMainOutline.BackgroundTransparency = 1
        DropdownMain.BackgroundTransparency = 1
        --
        local UIListLayout_9 = Library:CreateObject("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = DropdownMain
        })
        --
        do -- Functions
            function Dropdown:Set(State)
                for Index, Value in Dropdown.Items do
                    if Index == State then
                        Value:Activate()
                    else
                        Value:Deactivate()
                    end
                end
            end
            --
            function Dropdown:Get()
                return Dropdown.Value
            end
            --
            function Dropdown:SetVisible(Bool)
                local OldValues = Library.Objects[PreviewDropdown_5]
                --
                Dropdown.Hiding = not Bool
                --
                if Bool then
                    Library.Objects[PreviewDropdown_5] = {PreviewDropdown_5, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(PreviewDropdown_5), PreviewDropdown_5, 0.075)
                Library:TweenObject(PreviewDropdown_5, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and (Options.Name == "" and UDim2.new(1, 0, 0, 20) or UDim2.new(1, 0, 0, 31)) or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[PreviewDropdown_5] = {PreviewDropdown_5, OldValues[2], false}
                    end
                end)
            end
            --
            function Dropdown:AddValue(Value)
                local Item = {
                    Active = false,
                    Hovering = false,
                }
                --
                Dropdown.Items[Value] = Item
                --
                local Inactive = Library:CreateObject("TextLabel", {
                    FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextColor3 = Color3.fromRGB(208, 208, 208),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = Value,
                    Text = Value,
                    RichText = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = Library.UI.FontSize,
                    ZIndex = 10,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Parent = DropdownMain
                })
                --
                local Button_4 = Library:CreateObject("TextButton", {
                    FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Button_4",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextTransparency = 1,
                    TextSize = Library.UI.FontSize,
                    ZIndex = 10,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = Inactive
                })
                --
                local UIPadding_48 = Library:CreateObject("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                    Parent = Inactive
                })
                --
                Inactive.TextTransparency = 1
                --
                do -- Functions
                    function Item:Activate()
                        if not Item.Active then
                            if Dropdown.CurrentItem ~= nil then
                                Dropdown.CurrentItem:Deactivate()
                            end
                            --
                            Item.Active = true
                            Dropdown.CurrentItem = Item
                            Dropdown.Value = Value
                            Library.Flags[Options.Flag] = Dropdown
                            Options.Callback(Value)
                            DropdownValue_5.Text = Value
                            --
                            Inactive.Text = "<b>" .. Value .. "</b>"
                            Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Default.Accent})
                            Library:AddTheme(Inactive, {
                                TextColor3 = "Accent",
                            })
                        end
                    end
                    --
                    function Item:Deactivate()
                        if Item.Active then
                            Item.Active = false
                            Item.Hovering = false
                            Inactive.Text = Value
                            Inactive.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                            Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                            Library:AddTheme(Inactive, {
                                TextColor3 = "TextColor",
                            })
                        end
                    end
                end
                --
                do -- Connections
                    Library:Connection(Button_4.MouseButton1Click, function()
                        if Dropdown.Hiding then return end
                        --
                        Item:Activate()
                        Dropdown:Toggle()
                    end)
                    --
                    Library:Connection(Inactive.MouseEnter, function()
                        Inactive.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                        --
                        if Item.Active then return end
                        --
                        Inactive.Text = "<b>" .. Value .. "</b>"
                    end)
                    --
                    Library:Connection(Inactive.MouseLeave, function()
                        Inactive.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        --
                        if Item.Active then return end
                        --
                        Inactive.Text = Value
                        Library:TweenObject(Inactive, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(205, 205, 205)})
                    end)
                end
                --
                if Value == Options.Default then
                    Item:Activate()
                end
            end
            --
            function Dropdown:Toggle(Fast)
                local Fast = Fast or false
                local OldValues = Library.Objects[DropdownMainOutline]
                --
                if Dropdown.Open then
                    if Fast then
                        Library:Fade(false, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0)
                        DropdownMainOutline.Size = UDim2.new(0, DropdownOutline_5.AbsoluteSize.X, 0, 0)
                        Library.Objects[DropdownMainOutline] = {DropdownMainOutline, OldValues[2], true}
                    else
                        Library:Fade(false, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0.1)
                        Library:TweenObject(DropdownMainOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, DropdownOutline_5.AbsoluteSize.X, 0, 0)}, function()
                            Library.Objects[DropdownMainOutline] = {DropdownMainOutline, OldValues[2], true}
                        end)
                    end
                else
                    Library.Objects[DropdownMainOutline] = {DropdownMainOutline, OldValues[2], false}
                    --
                    if Fast then
                        Library:Fade(true, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0)
                        DropdownMainOutline.Size = UDim2.new(0, DropdownOutline_5.AbsoluteSize.X, 0, (#Options.Content * 20) + 2)
                    else
                        Library:Fade(true, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0.1)
                        Library:TweenObject(DropdownMainOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, DropdownOutline_5.AbsoluteSize.X, 0, (#Options.Content * 20) + 2)})
                    end	
                end
                --
                Dropdown.Open = not Dropdown.Open
            end
            --
            function Dropdown:Update()
                DropdownMainOutline.Size = UDim2.new(0, DropdownOutline_5.AbsoluteSize.X, 0, DropdownMainOutline.AbsoluteSize.Y)
                DropdownMainOutline.Position = UDim2.new(0, DropdownOutline_5.AbsolutePosition.X, 0, ((DropdownOutline_5.AbsolutePosition.Y + DropdownOutline_5.AbsoluteSize.Y) + GuiService:GetGuiInset().Y + 2))
                --
                if Dropdown.Open then
                    DropdownMainOutline.Visible = Library:ScrollingCheck(Options.Parent, DropdownChecker)
                end
            end
            --
            Dropdown:Update()
            --
            Library:Connection(DropdownOutline_5:GetPropertyChangedSignal("AbsolutePosition"), Dropdown.Update)
            Library:Connection(DropdownOutline_5:GetPropertyChangedSignal("AbsoluteSize"), Dropdown.Update)
            --
            local StartingX = PreviewDropdown_5.AbsolutePosition.X
            local StartingY = PreviewDropdown_5.AbsolutePosition.Y
            local MainUIStartingX = Options.MainUI.AbsolutePosition.X
            local MainUIStartingY = Options.MainUI.AbsolutePosition.Y
            local StartingCanvasPosition = Options.Parent.CanvasPosition
            --
            Library:Connection(PreviewDropdown_5:GetPropertyChangedSignal("AbsolutePosition"), function()
                if not Dropdown.Open then return end
                --
                local CurrentX = PreviewDropdown_5.AbsolutePosition.X
                local CurrentY = PreviewDropdown_5.AbsolutePosition.Y
                local MainUICurrentX = Options.MainUI.AbsolutePosition.X
                local MainUICurrentY = Options.MainUI.AbsolutePosition.Y
                local CurrentCanvasPosition = Options.Parent.CanvasPosition
                --
                if MainUICurrentX ~= MainUIStartingX or MainUICurrentY ~= MainUIStartingY then
                    MainUIStartingX = MainUICurrentX
                    MainUIStartingY = MainUICurrentY
                    StartingX = CurrentX
                    StartingY = CurrentY
                    --
                    return
                end
                --
                if CurrentCanvasPosition ~= StartingCanvasPosition then
                    StartingCanvasPosition = CurrentCanvasPosition
                    StartingX = CurrentX
                    StartingY = CurrentY
                    --
                    return
                end
                --
                if Library.UI.Resizing then
                    return
                end
                --
                if CurrentX ~= StartingX or CurrentY ~= StartingY then
                    Dropdown:Toggle(true)
                end
                --
                StartingX = CurrentX
                StartingY = CurrentY
            end)
            --
            if Options.Parent:IsA("ScrollingFrame") then
                Library:Connection(Options.Parent:GetPropertyChangedSignal("CanvasPosition"), function()
                    Dropdown:Update()
                end)
            end
        end
        --
        do -- Connections
            Library:Connection(Button_44.MouseButton1Click, function()
                if Dropdown.Hiding then return end
                --
                Dropdown:Toggle()
            end)
            --
            Library:Connection(DropdownOutline_5.MouseEnter, function()
                if Library.UI.Faded then return end
                --
                if not Dropdown.Open then
                    Dropdown.Hovering = true
                    Library:TweenObject(DropdownBack_5, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                end	
            end)
            --
            Library:Connection(DropdownOutline_5.MouseLeave, function()
                if Library.UI.Faded then return end
                --
                if not Dropdown.Open then
                    Dropdown.Hovering = false
                    Library:TweenObject(DropdownBack_5, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)})
                end	
            end)
        end
        --
        for _, Value in Options.Content do
            Dropdown:AddValue(Value)
        end
        --
        Library:Fade(false, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0.1)
        --
        if Options.Hiding then
            Dropdown:SetVisible(false)
        end
        --
        Dropdown:Toggle(true)
        --
        return Dropdown
    end
    --
    function Library:Slider(Options)
        Options = Library:Validate({
            Name = "Preview Slider",
            Min = 0,
            Max = 100,
            Default = 1,
            Decimal = 1,
            UseIcons = true,
            Ending = "",
            Disable = {},
            Hidden = false,
            Risky = false,
            Parent = nil,
            OverrideLimit = false, -- new parameter to allow values beyond max
            Flag = Library.NewFlag(),
            Callback = function() end
        }, Options or {})
        --
        local Slider = {
            MouseDown = false,
            Hiding = false,
            Hovering = false,
            Connection = nil,
            CurrentValue = -9999,
            LeftControlDown = false,
        }
        --
        Library.Flags[Options.Flag] = Slider
        --
        local PreviewSlider = Library:CreateObject("Frame", {
            Name = "PreviewSlider",
            BackgroundTransparency = 1,
            Size = Options.Name == "" and UDim2.new(1, 0, 0, 7) or UDim2.new(1, 0, 0, 20),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local SliderOutline = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            AnchorPoint = Vector2.new(0, 1),
            Name = "SliderOutline",
            Position = UDim2.new(0, -1, 1, 0),
            Size = UDim2.new(1, -19, 0, 7),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = PreviewSlider
        })
        --
        local SliderBack = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "SliderBack",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(205, 205, 205),
            Parent = SliderOutline
        })
        --
        local UIGradient_2 = Library:CreateObject("UIGradient", {
            Rotation = -90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(81, 81, 81)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(68, 68, 68))
            },
            Parent = SliderBack
        })
        --
        local SliderDrag = Library:CreateObject("Frame", {
            Name = "Slider",
            Size = UDim2.new(0.5, 0, 1, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = SliderBack
        })
        --
        local UIGradient_3 = Library:CreateObject("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Library.Theme.Default.Accent),
                ColorSequenceKeypoint.new(1, Library.Theme.Default.SecondAccent)
            },
            Parent = SliderDrag
        })
        --
        Library:AddTheme(UIGradient_3, {
            Color = {"Accent", "SecondAccent"},
        })
        --
        local Button_4 = Library:CreateObject("TextButton", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button_4",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextTransparency = 1,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = SliderOutline
        })
        --
        local SliderName = Library:CreateObject("TextLabel", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Options.Risky and Library.Theme.Default.Risky or Library.Theme.Default.TextColor,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = Options.Name,
            Name = "SliderName",
            ZIndex = 3,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewSlider
        })
        --
        if Options.Risky then
            Library:AddTheme(SliderName, {
                TextColor3 = "Risky",
            })
        end
        --
        local UIPadding_3 = Library:CreateObject("UIPadding", {
            PaddingTop = UDim.new(0, -4),
            PaddingLeft = UDim.new(0, 20),
            Parent = PreviewSlider
        })
        --
        local SliderValue = Library:CreateObject("TextBox", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Color3.fromRGB(198, 198, 198),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = Options.Default,
            Name = "SliderValue",
            ZIndex = 3,
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0, 10, 0, 10),
            Position = UDim2.new(0, 100, 0, 0),
            BackgroundTransparency = 1,
            RichText = true,
            BorderSizePixel = 0,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextSize = Library.UI.FontSize,
            TextStrokeTransparency = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = SliderDrag
        })
        --
        local AddButton = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            AnchorPoint = Vector2.new(1, 1),
            Name = "AddButton",
            Position = UDim2.new(1, -13, 1, -3),
            Size = UDim2.new(0, 3, 0, 1),
            ZIndex = 3,
            BorderSizePixel = 0,
            Visible = Options.UseIcons,
            BackgroundColor3 = Color3.fromRGB(100, 100, 100),
            Parent = PreviewSlider
        })
        --
        local AddButton2 = Library:CreateObject("Frame", {
            Size = UDim2.new(0, 1, 0, 3),
            Name = "AddButton2",
            Position = UDim2.new(0, 1, 0, -1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            Visible = Options.UseIcons,
            BackgroundColor3 = Color3.fromRGB(100, 100, 100),
            Parent = AddButton
        })
        --
        local AddActualButton = Library:CreateObject("TextButton", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "AddActualButton",
            TextTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0, 11, 0, 7),
            Visible = Options.UseIcons,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -9, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 3,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewSlider
        })
        --
        local MinusActualButton = Library:CreateObject("TextButton", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "MinusActualButton",
            TextTransparency = 1,
            Visible = Options.UseIcons,
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(0, 11, 0, 7),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, -12, 1, 0),
            BorderSizePixel = 0,
            ZIndex = 3,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewSlider
        })
        --
        local MinusButton = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            AnchorPoint = Vector2.new(0, 1),
            Name = "MinusButton",
            Visible = Options.UseIcons,
            Position = UDim2.new(0, -8, 1, -3),
            Size = UDim2.new(0, 3, 0, 1),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(100, 100, 100),
            Parent = PreviewSlider
        })
        --
        local function GetValue(Value)
            return typeof(Value) == "string" and Value or ("%.14g"):format(Value)
        end
        --
        local function SetValue(Value, IgnoreLimit)
            if (not Value) or Slider.Hiding then return end
            --
            local OriginalValue = Value
            -- check if we should allow values beyond the max
            if Options.OverrideLimit and IgnoreLimit then
                -- allow any value (still enforce min and decimal rounding)
                Value = Value and math.max(Options.Decimal * math.round(tonumber(Value) / Options.Decimal), Options.Min) or 0
            else
                -- default behavior: clamp between min and max
                Value = Value and math.clamp(Options.Decimal * math.round(tonumber(Value) / Options.Decimal), Options.Min, Options.Max) or 0
            end
            
            local ValueText = Options.Disable[1] and ((Value <= Options.Disable[2] or Value >= Options.Disable[3]) and Options.Disable[1]) or tostring(GetValue(Value)) .. Options.Ending
            --
            SliderValue.Text = "<b>" .. ValueText .. "</b>"
            --
            if Value ~= Slider.CurrentValue then
                Slider.CurrentValue = Value
                --
                -- always display the slider within bounds, even if the value is beyond max
                local DisplayValue = math.min(Value, Options.Max)
                Library:TweenObject(SliderDrag, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new((DisplayValue - Options.Min) / (Options.Max - Options.Min), 0, 1, 0)})
                --
                SliderValue.Size = UDim2.fromOffset(SliderValue.TextBounds.X, SliderValue.TextBounds.Y)
                SliderValue.Position = UDim2.new(1, SliderValue.TextBounds.X / 2, 0, -4)
            end
            --
            Library.Flags[Options.Flag] = Slider
            Options.Callback(tonumber(GetValue(Value)))
        end
        --
        SetValue(Options.Default)
        --
        function Slider:Get()
            return tonumber(GetValue(Slider.CurrentValue))
        end
        --
        function Slider:Max()
            return Options.Max
        end
        --
        function Slider:Min()
            return Options.Min
        end
        --
        function Slider:Set(Value)
            if not Value then return end
            --
            SetValue(Value, Options.OverrideLimit) -- allow overriding limits for api calls too
        end
        --
        function Slider:GetName()
            return Options.Name
        end
        --
        function Slider:SetVisible(Bool)
            local OldValues = Library.Objects[PreviewSlider]
            --
            Slider.Hiding = not Bool
            SliderValue.Visible = Bool
            --
            if Bool then
                Library.Objects[PreviewSlider] = {PreviewSlider, OldValues[2], true}
            end
            --
            Library:Fade(Bool, Library:GetObjectsTable(PreviewSlider), PreviewSlider, 0.075)
            Library:TweenObject(PreviewSlider, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and (Options.Name == "" and UDim2.new(1, 0, 0, 7) or UDim2.new(1, 0, 0, 20)) or UDim2.new(1, 0, 0, -10)}, function()
                if not Bool then
                    Library.Objects[PreviewSlider] = {PreviewSlider, OldValues[2], false}
                end
            end)
        end
        --
        local function SlideBar(Input)
            local SizeX = (Input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X
            local Value = math.clamp((Options.Max - Options.Min) * SizeX + Options.Min, Options.Min, Options.Max)
            --
            SetValue(Value)
        end
        --
        do -- Connections
            Library:Connection(SliderOutline.MouseEnter, function()
                if Library.UI.Faded then return end
                --
                Library:TweenObject(SliderBack, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
            end)
            --
            Library:Connection(SliderOutline.MouseLeave, function()
                if Library.UI.Faded then return end
                --
                Library:TweenObject(SliderBack, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(205, 205, 205)})
            end)
            --
            Library:Connection(MinusActualButton.MouseButton1Click, function()
                if Library.UI.Faded then return end
                --
                Slider:Set(Slider.CurrentValue - Options.Decimal)
            end)
            --
            Library:Connection(AddActualButton.MouseButton1Click, function()
                if Library.UI.Faded then return end
                --
                Slider:Set(Slider.CurrentValue + Options.Decimal)
            end)
            --
            Library:Connection(Button_4.MouseButton1Down, function()
                if Library.UI.Faded then return end
                --
                Library.UI.DraggingGui = SliderDrag
                Slider.MouseDown = true
                SlideBar({Position = UserInputService:GetMouseLocation()})
            end)
            --
            Library:Connection(SliderValue.FocusLost, function()
                local NewValue = tonumber(SliderValue.Text)
                --
                if NewValue then
                    SetValue(NewValue, Options.OverrideLimit) -- pass true to allow exceeding max
                else
                    SetValue(Options.Min)
                end
            end)
            --
            Library:Connection(UserInputService.InputChanged, function(Input)
                if Library.UI.Faded then return end
                --
                if Library.UI.DraggingGui ~= SliderDrag and not (UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
                    return
                end
                --
                if Slider.MouseDown and Input.UserInputType == Enum.UserInputType.MouseMovement then
                    SlideBar(Input)
                end
            end)
            --
            Library:Connection(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Slider.MouseDown = false
                end
            end)
        end
        --
        if Options.Hidden then
            Slider:SetVisible(false)
        end
        --
        return Slider
    end
    --
    function Library:Toggle(Options)
        Options = Library:Validate({
            Default = false,
            Name = "Preview Toggle",
            Risky = false,
            SectionName = nil,
            Parent = nil,
            Hidden = false,
            AnchorPoint = Vector2.new(0, 0),
            MainUI = nil,
            Size = UDim2.new(1, 0, 0, 8),
            Position = UDim2.new(0, 0, 0, 0),
            UseToggleOutline = false,
            ZIndex = 2,
            Flag = Library:NewFlag(),
            Callback = function() end
        }, Options or {})
        --
        local Toggle = {
            Active = false,
            Hovering = false,
            State = false,
            Hiding = false,
            MainUI = Options.MainUI,
            TabUI = Options.TabUI,
            ColorPickers = {},
            KeybindState = false,
        }
        --
        Library.Flags[Options.Flag] = Toggle
        --
        local PreviewToggle = Library:CreateObject("Frame", {
            Name = "PreviewToggle",
            BackgroundTransparency = 1,
            Size = Options.Size,
            Position = Options.Position,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            AnchorPoint = Options.AnchorPoint,
            ZIndex = Options.ZIndex or 2,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local ToggleOutline = Library:CreateObject("Frame", {
            Name = "ToggleOutline",
            Size = UDim2.new(0, 8, 0, 8),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = Options.ZIndex or 2,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = PreviewToggle
        })
        --
        if Options.UseToggleOutline then
            ToggleOutline.AnchorPoint = Options.AnchorPoint
            ToggleOutline.Position = Options.Position
        end
        --
        local ToggleInline = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "ToggleInline",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = Options.ZIndex or 2,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(227, 227, 227),
            Parent = ToggleOutline
        })
        --
        local UIGradient_3 = Library:CreateObject("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(84, 84, 84)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 74, 74))
            },
            Parent = ToggleInline
        })
        --
        local ToggleMain = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "ToggleInline",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = Options.ZIndex or 2,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = ToggleOutline
        })
        --
        Library.Objects[ToggleMain] = {ToggleMain, {BackgroundTransparency = ToggleMain.BackgroundTransparency}, false}
        --
        local UIGradient_32 = Library:CreateObject("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Library.Theme.Default.Accent),
                ColorSequenceKeypoint.new(1, Library.Theme.Default.SecondAccent)
            },
            Parent = ToggleMain
        })
        --
        Library:AddTheme(UIGradient_32, {
            Color = {"Accent", "SecondAccent"},
        })
        --
        local ToggleName = Library:CreateObject("TextLabel", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "ToggleName",
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = Options.ZIndex or 2,
            FontFace = Library.UI.NewFont,
            RichText = true,
            Text = Options.Name,
            TextColor3 = Options.Risky and Library.Theme.Default.Risky or Library.Theme.Default.TextColor,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewToggle
        })
        --
        if Options.Risky then
            Library:AddTheme(ToggleName, {
                TextColor3 = "Risky",
            })
        end
        --
        local UIPadding_7 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 20),
            Parent = ToggleName
        })
        --
        local Button_9 = Library:CreateObject("TextButton", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button_9",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextTransparency = 1,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewToggle
        })
        --
        do -- Functions
            function Toggle:ToggleGUI(Bool)
                if Bool == nil then
                    Toggle.State = not Toggle.State
                else
                    Toggle.State = Bool
                end
                --
                Library:TweenObject(ToggleMain, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundTransparency = Toggle.State and 0 or 1})
                
                -- update the stored transparency value in the objects table, this is for the temp fix for the toggle out and toggle in 
                -- since this uses instant out and instant in instead of the normal fade in and fade out
                if Library.Objects[ToggleMain] then
                    Library.Objects[ToggleMain][2].BackgroundTransparency = Toggle.State and 0 or 1
                end
                
                --
                Library.Flags[Options.Flag] = Toggle
                Options.Callback(Toggle.State)
            end
            --
            function Toggle:GetName()
                return Options.Name
            end
            --
            function Toggle:GetFlag()
                return Options.Flag
            end
            --
            function Toggle:GetSection()
                return Options.SectionName
            end
            --
            function Toggle:GetState()
                return Toggle.State
            end
            --
            function Toggle:GetCallback(b)
                Options.Callback(b)
            end
            --
            function Toggle:Set(Value)
                Toggle:ToggleGUI(Value)
            end
            --
            function Toggle:SetName(Name)
                Options.Name = Name
                ToggleName.Text = Name
            end
            --
            function Toggle:Get()
                return Toggle.State
            end
            --
            function Toggle:SetVisible(Bool)
                local OldValues = Library.Objects[PreviewToggle]
                --
                Toggle.Hiding = not Bool
                --
                if Bool then
                    Library.Objects[PreviewToggle] = {PreviewToggle, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(PreviewToggle), PreviewToggle, 0.075)
                Library:TweenObject(PreviewToggle, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and UDim2.new(1, 0, 0, 8) or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[PreviewToggle] = {PreviewToggle, OldValues[2], false}
                    end
                end)
            end
            --
            function Toggle:ColorPicker(Options)
                Options = Library:Validate({
                    Name = "Preview Color Picker",
                    Default = Library.Theme.Default.Accent,
                    Flag = Library.NewFlag(),
                    Alpha = 0,
                    AlphaBar = true,
                    Callback = function() end,
                }, Options or {})
                --
                local ColorPicker = {}
                --
                Toggle.ColorPickers[#Toggle.ColorPickers + 1] = ColorPicker
                --
                local ColorPickerFrame = Library:ColorPicker({
                    Name = Options.Name,
                    Default = Options.Default,
                    Flag = Options.Flag,
                    Alpha = Options.Alpha,
                    AlphaBar = Options.AlphaBar,
                    MainUI = Toggle.MainUI,
                    TabUI = Toggle.TabUI,
                    Callback = Options.Callback,
                    Parent = PreviewToggle,
                    Keybind = Toggle.KeybindState,
                    Count = #Toggle.ColorPickers,
                })
                --
                return ColorPickerFrame
            end
            --
            function Toggle:Keybind(Options)
                Options = Library:Validate({
                    Default = Enum.KeyCode.Backspace,
                    Mode = "Toggle",
                    UseMode = true,
                    HideFromList = false,
                    Blacklisted = {},
                    Hiding = false,
                    ChangeToggle = false,
                    Flag = Library.NewFlag(),
                    Callback = function() end,
                }, Options or {})
                --
                local Keybind = {}
                --
                Toggle.KeybindState = true
                --
                Library:Keybind({
                    Default = Options.Default,
                    Mode = Options.Mode,
                    HideFromList = Options.HideFromList,
                    Blacklisted = Options.Blacklisted,
                    Parent = PreviewToggle,
                    UseMode = Options.UseMode,
                    Toggle = Toggle,
                    MainUI = Toggle.MainUI,
                    TabUI = Toggle.TabUI,
                    Hiding = Options.Hiding,
                    ToggleState = Toggle.State,
                    ChangeToggle = Options.ChangeToggle,
                    Flag = Options.Flag,
                    Callback = Options.Callback,
                    Count = #Toggle.ColorPickers + 1,
                })
                --
                return Keybind
            end
        end
        --
        do -- Connections
            Library:Connection(PreviewToggle.MouseEnter, function()
                if Library.UI.Faded then return end
                --
                Library:TweenObject(ToggleInline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
            end)
            --
            Library:Connection(PreviewToggle.MouseLeave, function()
                if Library.UI.Faded then return end
                --
                Library:TweenObject(ToggleInline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(227, 227, 227)})
            end)
            --
            Library:Connection(Button_9.MouseButton1Click, function()
                if Library.UI.Faded then return end
                --
                if Toggle.Hiding then return end
                --
                Toggle:ToggleGUI()
            end)
        end
        --
        Toggle:ToggleGUI(Options.Default)
        --
        if Options.Hidden then
            Toggle:SetVisible(false)
        end
        --
        return Toggle
    end
    --
    function Library:Label(Options)
        Options = Library:Validate({
            Message = "Preview Label",
            Side = "Left",
            Risky = false,
            Parent = nil,
            MainUI = nil,
            SectionName = nil,
            Hidden = false,
            TabUI = nil,
            Callback = function() end
        }, Options or {})
        --
        local Label = {
            ColorPickers = {},
            KeybindState = false,
            Hiding = false,
            MainUI = Options.MainUI,
            TabUI = Options.TabUI,
            State = true,
        }
        --
        local PreviewLabel = Library:CreateObject("Frame", {
            Name = "PreviewLabel",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 7),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 2,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local LabelText = Library:CreateObject("TextLabel", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "ToggleName",
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment[Options.Side],
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, -1),
            ZIndex = 2,
            FontFace = Library.UI.NewFont,
            RichText = true,
            Text = Options.Message,
            TextColor3 = Color3.fromRGB(198, 198, 198),
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PreviewLabel
        })
        --
        local UIPadding_7 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 20),
            Parent = LabelText
        })
        --
        do -- Functions
            function Label:GetName()
                return Options.Message
            end
            --
            function Label:GetState()
                return Label.State
            end
            --
            function Label:GetSection()
                return Options.SectionName
            end
            --
            function Label:GetCallback(Bool)
                Options.Callback(Bool)
            end
            --
            function Label:SetVisible(Bool)
                local OldValues = Library.Objects[PreviewLabel]
                --
                Label.Hiding = not Bool
                --
                if Bool then
                    Library.Objects[PreviewLabel] = {PreviewLabel, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(PreviewLabel), PreviewLabel, 0.075)
                Library:TweenObject(PreviewLabel, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and UDim2.new(1, 0, 0, 8) or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[PreviewLabel] = {PreviewLabel, OldValues[2], false}
                    end
                end)
            end
            --
            function Label:ColorPicker(Options)
                Options = Library:Validate({
                    Name = "Preview Color Picker",
                    Default = Library.Theme.Default.Accent,
                    Flag = Library.NewFlag(),
                    Alpha = 0,
                    AlphaBar = true,
                    MainUI = nil,
                    Callback = function() end,
                }, Options or {})
                --
                local ColorPicker = {}
                --
                Label.ColorPickers[#Label.ColorPickers + 1] = ColorPicker
                --
                local ColorPickerFrame = Library:ColorPicker({
                    Name = Options.Name,
                    Default = Options.Default,
                    Flag = Options.Flag,
                    Alpha = Options.Alpha,
                    AlphaBar = Options.AlphaBar,
                    MainUI = Label.MainUI,
                    TabUI = Label.TabUI,
                    Callback = Options.Callback,
                    Parent = PreviewLabel,
                    Keybind = Label.KeybindState,
                    Count = #Label.ColorPickers,
                })
                --
                return ColorPickerFrame
            end
            --
            function Label:Keybind(Options)
                Options = Library:Validate({
                    Default = Enum.KeyCode.Backspace,
                    Mode = "Toggle",
                    UseMode = true,
                    HideFromList = false,
                    Blacklisted = {},
                    Hiding = false,
                    Flag = Library.NewFlag(),
                    Callback = function() end,
                }, Options or {})
                --
                local Keybind = {}
                --
                Label.KeybindState = true
                --
                Library:Keybind({
                    Default = Options.Default,
                    Mode = Options.Mode,
                    HideFromList = Options.HideFromList,
                    Blacklisted = Options.Blacklisted,
                    Parent = PreviewLabel,
                    Toggle = Label,
                    UseMode = Options.UseMode,
                    MainUI = Label.MainUI,
                    TabUI = Label.TabUI,
                    Hiding = Options.Hiding,
                    ToggleState = Label.State,
                    Flag = Options.Flag,
                    Callback = Options.Callback,
                    Count = #Label.ColorPickers + 1,
                })
                --
                return Keybind
            end
            --
            --[[function Label:Update()
                LabelText.Size = UDim2.new(LabelText.Size.X.Scale, LabelText.Size.X.Offset, 0, math.huge)
                LabelText.Size = UDim2.new(LabelText.Size.X.Scale, LabelText.Size.X.Offset, 0, LabelText.TextBounds.Y)
                PreviewLabel.Size = UDim2.new(PreviewLabel.Size.X.Scale, PreviewLabel.Size.X.Offset, 0, LabelName.TextBounds.Y + 6)
            end]]
        end
        --
        --Label:Update()
        --
        if Options.Hidden then
            Label:SetVisible(false)
        end
        --
        return Label
    end
    --
    function Library:TextBox(Options)
        Options = Library:Validate({
            Default = "",
            Name = "Preview TextBox",
            Max = 32,
            Parent = nil,
            Size = UDim2.new(1, 0, 0, 19),
            Position = UDim2.new(0, 0, 0, 0),
            NumbersOnly = false,
            ClearOnFocus = false,
            Hidden = false,
            TypedCheck = false,
            CheckIfPressedEnter = false,
            Risky = false,
            Flag = Library.NewFlag(),
            Callback = function() end
        }, Options or {})
        --
        local TextBox = {
            Focused = false,
            Hovering = false,
            Hiding = false,
        }
        --
        Library.Flags[Options.Flag] = TextBox
        --
        local PreviewTextBox = Library:CreateObject("Frame", {
            Name = "PreviewTextBox",
            BackgroundTransparency = 1,
            Size = Options.Size,
            Position = Options.Position,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local TextBoxOutline = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "TextBoxOutline",
            Position = UDim2.new(0, -1, 0, 0),
            Size = UDim2.new(1, -19, 0, 19),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = PreviewTextBox
        })
        --
        local TextBoxInline = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "TextBoxInline",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Parent = TextBoxOutline
        })
        --
        local TextBoxMain = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "TextBoxMain",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(24, 24, 24),
            Parent = TextBoxInline
        })
        --
        local TextBoxObject = Library:CreateObject("TextBox", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Library.Theme.Default.TextColor,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Text = "",
            ZIndex = 3,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            SelectionStart = 1,
            ClearTextOnFocus = Options.ClearOnFocus,
            PlaceholderColor3 = Library.Theme.Default.TextColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            PlaceholderText = "_",
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = TextBoxMain
        })
        --
        TextBox.Object = TextBoxObject
        --
        local UIPadding_6 = Library:CreateObject("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 5),
            Parent = TextBoxObject
        })
        --
        local UIPadding_7 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 20),
            Parent = PreviewTextBox
        })
        --
        do -- Functions
            function TextBox:SetVisible(Bool)
                local OldValues = Library.Objects[PreviewTextBox]
                --
                TextBox.Hiding = not Bool
                TextBoxObject.Visible = Bool
                --
                if Bool then
                    Library.Objects[PreviewTextBox] = {PreviewTextBox, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(PreviewTextBox), PreviewTextBox, 0.075)
                Library:TweenObject(PreviewTextBox, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and Options.Size or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[PreviewTextBox] = {PreviewTextBox, OldValues[2], false}
                    end
                end)
            end
            --
            function TextBox:Get()
                return TextBoxObject.Text
            end
        end
        --
        do -- Connections
            Library:Connection(TextBoxObject:GetPropertyChangedSignal("Text"), function()
                TextBoxObject.Text = TextBoxObject.Text:sub(1, Options.Max)
                --
                if Options.NumbersOnly then
                    TextBoxObject.Text = TextBoxObject.Text:gsub('[^%d%.%-]+', '')
                end
                --
                if Options.TypedCheck then
                    Library.Flags[Options.Flag] = TextBox
                    Options.Callback(TextBoxObject.Text)
                end
                --
                TextBox.Focused = true
            end)
            --
            Library:Connection(TextBoxObject.Focused, function()
                if Library.UI.Faded then return end
                --
                if TextBox.Hiding then
                    TextBoxObject:ReleaseFocus()
                    --
                    return
                end
                --
                TextBox.Focused = true
                --
                TextBoxObject.TextColor3 = Library.Theme.Default.Accent
                --
                Library:AddTheme(TextBoxObject, {
                    TextColor3 = "Accent",
                })
                --
                TextBoxObject.PlaceholderText = ""
            end)
            --
            Library:Connection(TextBoxObject.FocusLost, function(EnterPressed)
                if Options.CheckIfPressedEnter and not EnterPressed then return end
                --
                TextBox.Focused = false
                TextBoxObject.PlaceholderText = "_"
                --
                TextBoxObject.TextColor3 = Library.Theme.Default.TextColor
                --
                Library:AddTheme(TextBoxObject, {
                    TextColor3 = "TextColor",
                })
                --
                Library.Flags[Options.Flag] = TextBox
                Options.Callback(TextBoxObject.Text)
            end)
        end
        --
        if Options.Hidden then
            TextBox:SetVisible(false)
        end
        --
        return TextBox
    end
    --
    function Library:List(Options)
        Options = Library:Validate({
            Size = 100,
            Hidden = false,
            Flag = Library.NewFlag(),
            Callback = function() end
        }, Options or {})
        --
        local List = {
            CurrentValue = nil,
            CurrentValueName = nil,
        }
        --
        Library.Flags[Options.Flag] = List
        --
        local PreviewList = Library:CreateObject("Frame", {
            Name = "PreviewList",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Options.Size),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local UIPadding_11 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 20),
            Parent = PreviewList
        })
        --
        local ListOutline = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -19, 1, -18),
            Name = "ListOutline",
            Position = UDim2.new(0, -1, 0, 18),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = PreviewList
        })
        --
        local ListMain = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "ListMain",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 4,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
            Parent = ListOutline
        })
        --
        local DownArrow = Library:CreateObject("ImageButton", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "DownArrow",
            Image = "rbxassetid://15540867448",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -10, 1, -9),
            Size = UDim2.new(0, 5, 0, 4),
            ZIndex = 7,
            Visible = false,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = ListMain
        })
        --
        local UpArrow = Library:CreateObject("ImageButton", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "UpArrow",
            Image = "rbxassetid://15540851994",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -10, 0, 5),
            Size = UDim2.new(0, 5, 0, 4),
            ZIndex = 7,
            Visible = false,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = ListMain
        })
        --
        local ListScrolling = Library:CreateObject("ScrollingFrame", {
            ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
            MidImage = "rbxassetid://158362264",
            Active = true,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ScrollBarThickness = 5,
            Name = "ListScrolling",
            ZIndex = 3,
            TopImage = "rbxassetid://158362264",
            Position = UDim2.new(0, 1, 0, 1),
            Size = UDim2.new(1, -2, 1, -2),
            BottomImage = "rbxassetid://158362264",
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            CanvasPosition = Vector2.new(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            Parent = ListOutline
        })
        --
        local UIListLayout_2 = Library:CreateObject("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = ListScrolling
        })
        --
        local TextBox = Library:TextBox({Parent = PreviewList, TypedCheck = true, Size = UDim2.new(1, 20, 0, 19), Position = UDim2.new(0, -20, 0, 0), Callback = function(Text)
            List:UpdateSection()
            --
            for _, Frame in ListScrolling:GetChildren() do
                if Frame:IsA("Frame") then
                    Frame.Visible = string.find(Frame.Name:lower(), Text:lower()) and true or false
                end
            end
        end})
        --
        do -- Functions
            function List:Get()
                return List.CurrentValueName
            end
            --
            function List:SetVisible(Bool)
                local OldValues = Library.Objects[PreviewList]
                --
                TextBox.Object.Visible = Bool
                --
                if Bool then
                    Library.Objects[PreviewList] = {PreviewList, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(PreviewList, false), PreviewList, 0.075)
                Library:TweenObject(PreviewList, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and UDim2.new(1, 0, 0, Options.Size) or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[PreviewList] = {PreviewList, OldValues[2], false}
                    end
                end)
            end
            --
            function List:AddValue(Value, Icon)
                if ListScrolling:FindFirstChild(Value) then return end
                --
                local ListValue = {
                    Active = false,
                    Hovering = false,
                }
                --
                local InactiveValue = Library:CreateObject("Frame", {
                    Name = Value .. "1",
                    Size = UDim2.new(1, 0, 0, 20),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 5,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Parent = ListScrolling
                })
                --
                local Button_912 = Library:CreateObject("TextButton", {
                    FontFace = Library.UI.NewFont,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Button_9",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextTransparency = 1,
                    TextSize = Library.UI.FontSize,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = InactiveValue
                })
                --
                local ValueName_1 = Library:CreateObject("TextLabel", {
                    FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    TextColor3 = Color3.fromRGB(208, 208, 208),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "ValueName_1",
                    BorderSizePixel = 0,
                    Text = Value,
                    RichText = true,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 5,
                    TextSize = Library.UI.FontSize,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = InactiveValue
                })
                --
                if Icon then
                    local Color = Icon.Color or Color3.fromRGB(255, 255, 255)
                    --
                    local IconImage = Library:CreateObject("ImageLabel", {
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Image = Icon.Image,
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = Icon.Position or UDim2.new(0, 7, 0.5, 0),
                        BackgroundTransparency = 1,
                        Name = "BackImage",
                        Size = Icon.Size or UDim2.new(0, 13, 0, 13),
                        ZIndex = 5,
                        BorderSizePixel = 0,
                        ImageColor3 = Color,
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                        Parent = InactiveValue
                    })
                    --
                    local UIPadding_135 = Library:CreateObject("UIPadding", {
                        PaddingLeft = UDim.new(0, 10),
                        Parent = IconImage
                    })
                end
                --
                ValueName_1.Text = Library:ClampString(Value, ValueName_1.AbsoluteSize.X - 25)
                --
                local UIPadding_13 = Library:CreateObject("UIPadding", {
                    PaddingLeft = UDim.new(0, (Icon and 25 or 10)),
                    Parent = ValueName_1
                })
                --
                do -- Functions
                    function ListValue:Activate()
                        if not ListValue.Active then
                            --
                            if List.CurrentValue then
                                List.CurrentValue:Deactivate()
                            end
                            --
                            ListValue.Active = true
                            --
                            ValueName_1.TextColor3 = Library.Theme.Default.Accent
                            ValueName_1.Text = "<b>" .. Value .. "</b>"
                            --
                            Library:AddTheme(ValueName_1, {
                                TextColor3 = "Accent",
                            })
                            --
                            List.CurrentValue = ListValue
                            List.CurrentValueName = Value
                            Library.Flags[Options.Flag] = List
                            Options.Callback(Value)
                        end
                    end
                    --
                    function ListValue:Deactivate()
                        if ListValue.Active then
                            ListValue.Active = false
                            ListValue.Hovering = false
                            ValueName_1.TextColor3 = Library.Theme.Default.TextColor
                            --
                            Library:AddTheme(ValueName_1, {
                                TextColor3 = "TextColor",
                            })
                        end
                    end
                end
                --
                do -- Connections
                    local OldText = ValueName_1.Text
                    --
                    Library:Connection(PreviewList:GetPropertyChangedSignal("AbsoluteSize"), function()
                        ValueName_1.Text = Library:ClampString(Value, ValueName_1.AbsoluteSize.X - 25)
                    end)
                    --
                    Library:Connection(InactiveValue.MouseEnter, function()
                        if Library.UI.Faded then return end
                        --
                        InactiveValue.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                        OldText = ValueName_1.Text
                        --
                        if not ListValue.Active then
                            ValueName_1.Text = "<b>" .. OldText .. "</b>"
                        end
                    end)
                    --
                    Library:Connection(InactiveValue.MouseLeave, function()
                        if Library.UI.Faded then return end
                        --
                        InactiveValue.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        --
                        if not ListValue.Active then
                            ValueName_1.Text = OldText
                        end
                    end)
                    --
                    Library:Connection(Button_912.MouseButton1Click, function()
                        if Library.UI.Faded then return end
                        --
                        ListValue:Activate()
                    end)
                end
            end
            --
            function List:RemoveValue(Value)
                for _, Object in ListScrolling:GetChildren() do
                    if Object.Name == Value .. "1" then
                        Object:Destroy()
                    end
                end
            end
            --
            function List:UpdateSection()
                local CanvasSize = ListScrolling.AbsoluteCanvasSize.Y
                local AbsoluteSize = ListMain.AbsoluteSize.Y
                --
                if CanvasSize > AbsoluteSize then
                    ListMain.Size = UDim2.new(1, -8, 1, -2)
                    UpArrow.Visible = not List:CheckArrows("Up")
                    DownArrow.Visible = not List:CheckArrows("Down")
                elseif CanvasSize == AbsoluteSize then
                    ListMain.Size = UDim2.new(1, -2, 1, -2)
                    UpArrow.Visible = false
                    DownArrow.Visible = false
                end
            end
            --
            function List:CheckArrows(Type)
                if Type == "Up" then
                    return ListScrolling.CanvasPosition == Vector2.new(0, 0)
                elseif Type == "Down" then
                    return ListScrolling.CanvasPosition == Vector2.new(0, ListScrolling.AbsoluteCanvasSize.Y - ListScrolling.AbsoluteSize.Y)
                else
                    return false
                end
            end
        end
        --
        List:UpdateSection()
        --
        do -- Connections
            Library:Connection(ListScrolling.ChildAdded, function()
                List:UpdateSection()
            end)
            --
            Library:Connection(ListScrolling.ChildRemoved, function()
                List:UpdateSection()
            end)
            --
            Library:Connection(ListOutline:GetPropertyChangedSignal("AbsoluteSize"), function()
                List:UpdateSection()
            end)
            --
            Library:Connection(ListScrolling:GetPropertyChangedSignal("AbsoluteSize"), function()
                List:UpdateSection()
            end)
            --
            Library:Connection(ListScrolling:GetPropertyChangedSignal("CanvasPosition"), function()
                List:UpdateSection()
            end)
            --
            Library:Connection(UpArrow.MouseButton1Click, function()
                if Library.UI.Faded then return end
                --
                if not UpArrow.Visible then return end
                --
                Library:TweenObject(ListScrolling, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(0, 0)})
            end)
            --
            Library:Connection(DownArrow.MouseButton1Click, function()
                if Library.UI.Faded then return end
                --
                if not DownArrow.Visible then return end
                --
                Library:TweenObject(ListScrolling, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(0, ListScrolling.AbsoluteCanvasSize.Y - ListScrolling.AbsoluteSize.Y)})
            end)
        end
        --
        if Options.Hidden then
            List:SetVisible(false)
        end
        --
        return List
    end
    --
    function Library:Button(Options)
        Options = Library:Validate({
            Name = "Preview Button",
            Confirmation = false,
            Parent = nil,
            Hidden = false,
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, 0),
            Risky = false,
            Callback = function() end
        }, Options or {})
        --
        local Button = {
            MouseDown = false,
            Hovering = false,
            WaitingForConfirm = false,
            Hiding = false,
            ConfirmationTime = 0,
            ConfirmationConnection = nil,
        }
        --
        local PreviewButton = Library:CreateObject("Frame", {
            Name = "PreviewButton",
            BackgroundTransparency = 1,
            Size = Options.Size,
            Position = Options.Position,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Options.Parent
        })
        --
        local ButtonOutline = Library:CreateObject("Frame", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "ButtonOutline",
            Position = UDim2.new(0, -1, 0, 0),
            Size = UDim2.new(1, -19, 0, 25),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = PreviewButton
        })
        --
        local ButtonInline = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "ButtonInline",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            Parent = ButtonOutline
        })
        --
        local ButtonMain_1 = Library:CreateObject("Frame", {
            Size = UDim2.new(1, -2, 1, -2),
            Name = "ButtonMain_1",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            ZIndex = 3,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(220, 220, 220),
            Parent = ButtonInline
        })
        --
        local UIGradient_4 = Library:CreateObject("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 39, 39)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35))
            },
            Parent = ButtonMain_1
        })
        --
        local Button_6 = Library:CreateObject("TextButton", {
            FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
            TextColor3 = Options.Risky and Library.Theme.Default.Risky or Library.Theme.Default.TextColor,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button_6",
            RichText = true,
            Text = "<b>" .. Options.Name .. "</b>",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ZIndex = 3,
            TextSize = Library.UI.FontSize,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = ButtonOutline
        })
        --
        if Options.Risky then
            Library:AddTheme(Button_6, {
                TextColor3 = "Risky",
            })
        end
        --
        local UIPadding_8 = Library:CreateObject("UIPadding", {
            PaddingLeft = UDim.new(0, 20),
            Parent = PreviewButton
        })
        --
        do -- Functions
            function Button:UpdateSize(Size)
                ButtonOutline.Size = Size
            end
            --
            function Button:UpdatePosition(Position)
                PreviewButton.Position = Position
            end
            --
            function Button:SetVisible(Bool)
                local OldValues = Library.Objects[PreviewButton]
                --
                Button.Hiding = not Bool
                --
                if Bool then
                    Library.Objects[PreviewButton] = {PreviewButton, OldValues[2], true}
                end
                --
                Library:Fade(Bool, Library:GetObjectsTable(PreviewButton), PreviewButton, 0.075)
                Library:TweenObject(PreviewButton, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = Bool and Options.Size or UDim2.new(1, 0, 0, -10)}, function()
                    if not Bool then
                        Library.Objects[PreviewButton] = {PreviewButton, OldValues[2], false}
                    end
                end)
            end
            --
            function Button:ConfirmationStart()
                Button.MouseDown = true
                Button.WaitingForConfirm = true
                Button.ConfirmationTime = 3
                Button_6.Text = "<b>Are you sure?</b>"
                --
                if Button.ConfirmationConnection then
                    coroutine.close(Button.ConfirmationConnection)
                    Button.ConfirmationConnection = nil
                end
                --
                Button.ConfirmationConnection = coroutine.create(function()
                    for i = 1, 3 do 
                        task.wait(1)
                        --
                        Button.ConfirmationTime = Button.ConfirmationTime - 1
                        --
                        if Button.ConfirmationTime <= 0 then
                            Button_6.Text = "<b>" .. Options.Name .. "</b>"
                            --
                            if Button.MouseDown then
                                Library:TweenObject(Button_6, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {TextColor3 = Library.Theme.Default.TextColor})
                                --
                                Button.MouseDown = false
                                Button.WaitingForConfirm = false
                            end
                            --
                            break
                        end
                    end
                end)
                --
                coroutine.resume(Button.ConfirmationConnection)
            end
        end
        --
        do -- Connections
            Library:Connection(Button_6.MouseButton1Down, function()
                if Library.UI.Faded then return end
                --
                if Button.Hiding then return end
                --
                Library:TweenObject(ButtonMain_1, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(180, 180, 180)})
                --
                if Options.Confirmation then
                    if not Button.WaitingForConfirm then
                        Button:ConfirmationStart()
                    else
                        if Button.ConfirmationConnection then
                            coroutine.close(Button.ConfirmationConnection)
                            Button.ConfirmationConnection = nil
                        end
                        --
                        Options.Callback()
                        Button.MouseDown = true
                        Button.Hovering = false
                        Button.WaitingForConfirm = false
                        --
                        Library:TweenObject(ButtonMain_1, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(180, 180, 180)})
                        --
                        Button_6.Text = "<b>" .. Options.Name .. "</b>"
                    end
                else
                    Options.Callback()
                    Button.MouseDown = true
                end
            end)
            --
            Library:Connection(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and Button.MouseDown and not Button.WaitingForConfirm then
                    Button.Hovering = false
                    Button.MouseDown = false
                end
                --
                Library:TweenObject(ButtonMain_1, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)})
            end)
            --
            Library:Connection(ButtonOutline.MouseEnter, function()
                if Library.UI.Faded then return end
                --
                if not Button.MouseDown then
                    Button.Hovering = true
                    Library:TweenObject(ButtonMain_1, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)})
                end	
            end)
            --
            Library:Connection(ButtonOutline.MouseLeave, function()
                if Library.UI.Faded then return end
                --
                if not Button.MouseDown then
                    Button.Hovering = false
                    Library:TweenObject(ButtonMain_1, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(220, 220, 220)})
                end	
            end)
        end
        --
        if Options.Hidden then
            Button:SetVisible(false)
        end
        --
        return Button
    end
    --
    function Library:Window(Options)
        Options = Library:Validate({
            Name = "gamesense",
            Size = UDim2.new(0, 700, 0, 612),
            MinResize = UDim2.new(0, 500, 0, 400),
            MaxResize = UDim2.new(0, 10000, 0, 10000),
            CloseBind = Enum.KeyCode.RightShift,
        }, Options or {})
        --
        local Window = {
            Visible = true,
            CurrentTab = nil,
            Tabs = {},
        }
        --
        local MainUI = Library:CreateObject("ScreenGui", {
            ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
            DisplayOrder = 1000,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            Name = "\0",
            Parent = gethui()
        })
        --
        Library.UI.ScreenGUI = MainUI
        --
        local Outline = Library:CreateObject("Frame", {
            Name = "Outline",
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = Options.Size,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            Parent = MainUI
        })
        --
        Outline:SetAttribute("g", Window.CurrentTab)
        Library.UI.MainUI = Outline
        --
        Outline.Position = UDim2.fromOffset((Viewport.X / 2) - (Outline.Size.X.Offset / 2), (Viewport.Y / 2) - (Outline.Size.Y.Offset / 2))
        Outline.Active = true
        Outline.Draggable = true
        --
        local Inline = Library:CreateObject("Frame", {
            Name = "Inline",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            Parent = Outline
        })
        --
        local Inner = Library:CreateObject("Frame", {
            Name = "Inner",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            Parent = Inline
        })
        --
        local Outline_1 = Library:CreateObject("Frame", {
            Name = "Outline_1",
            Position = UDim2.new(0, 3, 0, 3),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, -6, 1, -6),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            Parent = Inner
        })
        --
        local PatternHolder = Library:CreateObject("Frame", {
            Name = "PatternHolder",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            Parent = Outline_1
        })
        --
        local Pattern = Library:CreateObject("ImageLabel", {
            ImageColor3 = Color3.fromRGB(12, 12, 12),
            ScaleType = Enum.ScaleType.Tile,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Image = "rbxassetid://8547666218",
            BackgroundTransparency = 1,
            Name = "Pattern",
            Size = UDim2.new(1, 0, 1, 0),
            TileSize = UDim2.new(0, 8, 0, 8),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = PatternHolder
        })
        --
        local TopBarGradientHolder = Library:CreateObject("Frame", {
            Name = "TopBarGradientHolder",
            Position = UDim2.new(0, 1, 0, 1),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, -2, 0, 4),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Outline_1
        })
        --
        local GradientBar = Library:CreateObject("ImageLabel", {
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Image = "rbxassetid://8508019876",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 1, 0, 1),
            Name = "GradientBar",
            Size = UDim2.new(1, -2, 1, -2),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = TopBarGradientHolder
        })
        --
        local UIGradient = Library:CreateObject("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 0.550000011920929)
            },
            Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 12, 12)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            },
            Parent = TopBarGradientHolder
        })
        --
        local SideBarMain = Library:CreateObject("Frame", {
            Name = "SideBarMain",
            Position = UDim2.new(0, 1, 0, 5),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(0, 75, 1, -6),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
            ClipsDescendants = true,
            Parent = Outline_1
        })
        --
        local Outline_2 = Library:CreateObject("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Name = "Outline_2",
            Position = UDim2.new(1, 0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            Parent = SideBarMain
        })
        --
        local Holder = Library:CreateObject("Frame", {
            BackgroundTransparency = 1,
            Name = "Holder",
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = SideBarMain
        })
        --
        local UIListLayout = Library:CreateObject("UIListLayout", {
            Padding = UDim.new(0, 0),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Holder
        })
        --
        local UIPadding = Library:CreateObject("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            Parent = Holder
        })
        --
        local Inline_4 = Library:CreateObject("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Name = "Inline_4",
            Position = UDim2.new(1, -1, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            Parent = SideBarMain
        })
        --
        local ResizeButton = Library:CreateObject("TextButton", {
            FontFace = Library.UI.NewFont,
            TextColor3 = Color3.fromRGB(0, 0, 0),
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            Name = "Button",
            AnchorPoint = Vector2.new(1, 1),
            Size = UDim2.new(0, 20, 0, 20),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            TextTransparency = 1,
            TextSize = Library.UI.FontSize,
            ZIndex = 5,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = Outline
        })
        --
        do -- Functions
            function Window:SetTab(Number)
                for Index, Tab in Window.Tabs do
                    if Index == Number then
                        if Window.CurrentTab ~= nil then
                            Window.CurrentTab:Deactivate()
                        end
                        --
                        Tab:Activate()
                    end
                end
            end
        end
        --
        do -- Connections
            Library:Connection(UserInputService.InputBegan, function(Input)
                if Input.KeyCode == Library.UI.CloseBind then
                    Window.Visible = not Window.Visible
                    --
                    Library:Fade(Window.Visible, Library.Objects, Outline, 0.2)
                end
            end)
            --
            Library:Resizable(Outline, ResizeButton, Options.MinResize, Options.MaxResize)
        end
        --
        function Window:CreateTab(Options)
            Options = Library:Validate({
                Icon = "rbxassetid://8547236654",
            }, Options or {})
            --
            local Tab = {
                Hovering = false,
                Active = false,
                Index = Library.UI.TabIndex + 1,
                SubSectionEnabled = false,
                DropdownSectionEnabled = false,
                Position = "Bottom",
                Sides = {
                    Left = {
                        Sections = {},
                        Sizes = 0,
                    },
                    Right = {
                        Sections = {},
                        Sizes = 0,
                    }
                }
            }
            --
            Library.UI.TabIndex = Tab.Index
            --
            local TabActive = Library:CreateObject("Frame", {
                BackgroundTransparency = 1,
                Name = "TabActive",
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(1, -2, 0, 64),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = Holder
            })
            --
            local Outline_3 = Library:CreateObject("Frame", {
                Name = "Outline_3",
                Size = UDim2.new(1, 0, 1, 0),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                Visible = false,
                Parent = TabActive
            })
            --
            local Inline_1 = Library:CreateObject("Frame", {
                Size = UDim2.new(1, 1, 1, -2),
                Name = "Inline_1",
                Position = UDim2.new(0, 0, 0, 1),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                Parent = Outline_3
            })
            --
            local Main = Library:CreateObject("Frame", {
                Size = UDim2.new(1, 1, 1, -2),
                Name = "Main",
                Position = UDim2.new(0, 0, 0, 1),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(20, 20, 20),
                Parent = Inline_1
            })
            --
            local Pattern_1 = Library:CreateObject("ImageLabel", {
                ImageColor3 = Color3.fromRGB(12, 12, 12),
                ScaleType = Enum.ScaleType.Tile,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Pattern_1",
                Image = "rbxassetid://8547666218",
                BackgroundTransparency = 1,
                TileSize = UDim2.new(0, 8, 0, 8),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                Parent = Main
            })
            --
            local Button = Library:CreateObject("TextButton", {
                FontFace = Font.new("rbxasset://fonts/families/Zekton.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Button",
                Text = Options.Icon,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                TextColor3 = Color3.fromRGB(90, 90, 90),
                BorderSizePixel = 0,
                TextTransparency = 1,
                TextSize = Library.UI.FontSize,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = TabActive
            })
            --
            local Icon = Library:CreateObject("ImageLabel", {
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Name = "Button",
                Image = Options.Icon,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ImageColor3 = Color3.fromRGB(109, 109, 109),
                BorderSizePixel = 0,
                ZIndex = 3,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = TabActive
            })
            --
            local SectionsHolder = Library:CreateObject("Frame", {
                Name = "SectionsHolder",
                BackgroundTransparency = 1,
                Visible = true,
                Position = UDim2.new(0, 76, 0, 5),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(1, -78, 1, -6),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ClipsDescendants = true,
                Parent = Outline_1
            })
            --
            local Left = Library:CreateObject("Frame", {
                BackgroundTransparency = 1,
                Name = "Left",
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.new(0, 1, 0, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ClipsDescendants = true,
                Parent = SectionsHolder
            })
            --
            local UIPadding_1 = Library:CreateObject("UIPadding", {
                PaddingTop = UDim.new(0, 19),
                PaddingBottom = UDim.new(0, 19),
                PaddingRight = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 21),
                Parent = Left
            })
            --
            local UIListLayout12 = Library:CreateObject("UIListLayout", {
                Padding = UDim.new(0, 19),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Left
            })
            --
            local Right = Library:CreateObject("Frame", {
                Name = "Right",
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 1, 0, 0),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(0.5, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ClipsDescendants = true,
                Parent = SectionsHolder
            })
            --
            local UIPadding_2 = Library:CreateObject("UIPadding", {
                PaddingTop = UDim.new(0, 19),
                PaddingBottom = UDim.new(0, 19),
                PaddingRight = UDim.new(0, 19),
                PaddingLeft = UDim.new(0, 10),
                Parent = Right
            })
            --
            local UIListLayout52 = Library:CreateObject("UIListLayout", {
                Padding = UDim.new(0, 19),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Right
            })
            --
            local SectionsHolder2 = Library:CreateObject("Frame", {
                Name = "SectionsHolder",
                BackgroundTransparency = 1,
                Visible = true,
                Position = UDim2.new(0, 76, 0, 5),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(1, -78, 1, -6),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                ClipsDescendants = true,
                Parent = Outline_1
            })
            --
            local SubSectionHolder = Library:CreateObject("Frame", {
                Name = "SubSectionHolder",
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(1, -39, 0, 61),
                BorderSizePixel = 0,
                ZIndex = 1,
                Visible = false,
                BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                Parent = SectionsHolder2
            })
            --
            Left.Position = UDim2.new(0, 0, 0, Left.AbsoluteSize.Y)
            Right.Position = UDim2.new(0.5, 1, 0, Right.AbsoluteSize.Y)
            SubSectionHolder.Position = UDim2.new(0, 21, 0, SectionsHolder2.AbsoluteSize.Y + SubSectionHolder.AbsoluteSize.Y)
            --
            do -- Functions
                function Tab:MoveSides(State)
                    task.spawn(function()
                        if State then
                            if Tab.Position == "Bottom" then
                                Left.Position = UDim2.new(0, 0, 0, Left.AbsoluteSize.Y)
                                Right.Position = UDim2.new(0.5, 1, 0, Right.AbsoluteSize.Y)
                                SubSectionHolder.Position = UDim2.new(0, 21, 0, SectionsHolder2.AbsoluteSize.Y + SubSectionHolder.AbsoluteSize.Y)
                            else
                                Left.Position = UDim2.new(0, 0, 0, -Left.AbsoluteSize.Y)
                                Right.Position = UDim2.new(0.5, 1, 0, -Right.AbsoluteSize.Y)
                                SubSectionHolder.Position = UDim2.new(0, 21, 0, -(SectionsHolder2.AbsoluteSize.Y + SubSectionHolder.AbsoluteSize.Y))
                            end
                            --
                            Library:TweenObject(SubSectionHolder, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 21, 0, 19)})
                            Library:TweenObject(Left, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
                            Library:TweenObject(Right, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 1, 0, 0)})
                        else
                            task.wait(0.001)
                            --
                            local SubSectionPosition = Tab.Position == "Bottom" and SectionsHolder2.AbsoluteSize.Y + 10 or -SectionsHolder2.AbsoluteSize.Y
                            local LeftPosition = Tab.Position == "Bottom" and Left.AbsoluteSize.Y + 10 or -Left.AbsoluteSize.Y
                            local RightPosition = Tab.Position == "Bottom" and Right.AbsoluteSize.Y + 10 or -Right.AbsoluteSize.Y
                            --
                            Library:TweenObject(SubSectionHolder, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 21, 0, SubSectionPosition)})
                            Library:TweenObject(Left, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, LeftPosition)})
                            Library:TweenObject(Right, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 1, 0, RightPosition)})
                        end
                    end)
                end
                --
                function Tab:Activate()
                    if not Tab.Active then
                        --
                        if Window.CurrentTab ~= nil then
                            Window.CurrentTab:Deactivate()
                        end
                        --
                        Tab.Active = true
                        Tab:MoveSides(true)
                        --
                        Library:TweenObject(Icon, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(210, 210, 210)})
                        Outline_3.Visible = true
                        --
                        Window.CurrentTab = Tab
                        Outline:SetAttribute("g", table.find(Window.Tabs, Tab))
                    end
                end
                --
                function Tab:Deactivate()
                    if Tab.Active then
                        Tab.Active = false
                        Tab.Hovering = false
                        Outline_3.Visible = false
                        Library:TweenObject(Icon, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(90, 90, 90)})
                        --
                        Tab:MoveSides(false)
                    end
                end
            end
            --
            do -- Connections
                Library:Connection(Outline:GetAttributeChangedSignal("g"), function()
                    if Outline:GetAttribute("g") > Tab.Index then
                        Tab.Position = "Top"
                    elseif Outline:GetAttribute("g") < Tab.Index then
                        Tab.Position = "Bottom"
                    end
                end)
                --
                Library:Connection(Outline:GetPropertyChangedSignal("AbsoluteSize"), function()
                    if not Tab.Active then
                        SubSectionHolder.Position = UDim2.new(0, 21, 0, SectionsHolder2.AbsoluteSize.Y + SubSectionHolder.AbsoluteSize.Y)
                        Left.Position = UDim2.new(0, 0, 0, Left.AbsoluteSize.Y)
                        Right.Position = UDim2.new(0.5, 1, 0, Right.AbsoluteSize.Y)
                    else
                        Left.Position = UDim2.new(0, 0, 0, 0)
                        Right.Position = UDim2.new(0.5, 1, 0, 0)
                    end
                end)
                --
                Library:Connection(Button.MouseButton1Click, function()
                    Tab:Activate()
                end)
                --
                Library:Connection(TabActive.MouseEnter, function()
                    if not Tab.Active then
                        Tab.Hovering = true
                        Library:TweenObject(Icon, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(168, 168, 168)})
                    end
                end)
                --
                Library:Connection(TabActive.MouseLeave, function()
                    if not Tab.Active then
                        Tab.Hovering = false
                        Library:TweenObject(Icon, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {ImageColor3 = Color3.fromRGB(90, 90, 90)})
                    end
                end)
            end
            --
            Window.Tabs[#Window.Tabs + 1] = Tab
            --
            function Tab:Section(Options)
                Options = Library:Validate({
                    Name = "Preview Section",
                    Side = "Left",
                    Fill = false,
                    Size = UDim2.new(1, 0, 0, 40),
                    ParentOptions = {},
                    Icon = nil,
                    Parent = nil,
                }, Options or {})
                --
                local Section = {
                    Elements = {},
                    SizeButton = nil,
                    Hovering = false,
                    DragConnection = nil,
                    Left = {
                        Order = 1,
                    },
                    Right = {
                        Order = 1,
                    },
                }
                --
                local Parent = Options.Side == "Left" and Left or Right
                --
                local SectionOutline = Library:CreateObject("Frame", {
                    Name = "SectionOutline",
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, 0, 0, Options.Size),
                    AutomaticSize = Options.Fill and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
                    BorderSizePixel = 0,
                    ZIndex = 1,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = Options.Parent or Parent
                })
                --
                table.insert(Tab.Sides[Options.Side].Sections, SectionOutline)
                --
                task.delay(0.01, function()
                    if Options.Fill == false then
                        Tab.Sides[Options.Side].Sizes += SectionOutline.AbsoluteSize.Y + 19
                    end
                    --
                    if Options.Fill then
                        SectionOutline.Size = UDim2.new(1, 0, 1, -(Tab.Sides[Options.Side].Sizes))
                    else
                        SectionOutline.Size = UDim2.new(1, 0, 0, Options.Size)
                    end
                end)
                --
                local SectionInline = Library:CreateObject("Frame", {
                    Name = "SectionInline",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    Parent = SectionOutline
                })
                --
                local SectionScrolling = Library:CreateObject("ScrollingFrame", {
                    ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65),
                    MidImage = "rbxassetid://158362264",
                    Active = true,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ScrollBarThickness = 5,
                    Size = UDim2.new(1, -2, 1, -2),
                    TopImage = "rbxassetid://158362264",
                    Position = UDim2.new(0, 1, 0, 1),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    CanvasPosition = Vector2.new(0, 0),
                    BottomImage = "rbxassetid://158362264",
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    Parent = SectionInline
                })
                --
                local UIListLayout_3 = Library:CreateObject("UIListLayout", {
                    Padding = UDim.new(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = SectionScrolling
                })
                --
                local UIPadding_8 = Library:CreateObject("UIPadding", {
                    PaddingTop = UDim.new(0, 19),
                    PaddingBottom = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 18),
                    PaddingLeft = UDim.new(0, 18),
                    Parent = SectionScrolling
                })
                --
                local SectionMain = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "SectionMain_1",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 1,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    Parent = SectionInline
                })
                --
                local SectionFader = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    AnchorPoint = Vector2.new(0, 1),
                    Name = "SectionFader",
                    Position = UDim2.new(0, 0, 1, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    Parent = SectionMain
                })
                --
                local DownArrow = Library:CreateObject("ImageButton", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "DownArrow",
                    Image = "rbxassetid://15540867448",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -10, 1, -9),
                    Size = UDim2.new(0, 5, 0, 4),
                    ZIndex = 4,
                    BorderSizePixel = 0,
                    Visible = false,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = SectionMain
                })
                --
                local UpArrow = Library:CreateObject("ImageButton", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "UpArrow",
                    Image = "rbxassetid://15540851994",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -10, 0, 5),
                    Size = UDim2.new(0, 5, 0, 4),
                    ZIndex = 4,
                    BorderSizePixel = 0,
                    Visible = false,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = SectionMain
                })
                --
                local UIGradient = Library:CreateObject("UIGradient", {
                    Rotation = -90,
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    },
                    Parent = SectionFader
                })
                --
                local SectionFader2 = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    Name = "SectionFader",
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    Parent = SectionMain
                })
                --
                local UIGradient = Library:CreateObject("UIGradient", {
                    Rotation = 90,
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    },
                    Parent = SectionFader2
                })
                --
                local TitleInline = Library:CreateObject("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 0,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "TitleInline",
                    BorderSizePixel = 0,
                    Parent = SectionOutline,
                    Position = UDim2.new(0, 9, 0, 0),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 5
                })
                --
                local UIGradient2 = Library:CreateObject("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 19, 19)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 24))
                    },
                    Parent = TitleInline
                })
                --
                local Title = Library:CreateObject("TextButton", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    Parent = SectionOutline,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -26, 0, 15),
                    ZIndex = 5,
                    FontFace = Library.UI.NewFont,
                    RichText = true,
                    Text = "<b>" .. Options.Name .. "</b>",
                    TextColor3 = Color3.fromRGB(198, 198, 198),
                    TextSize = Library.UI.FontSize,
                    TextStrokeTransparency = 1,
                    TextXAlignment = "Left"
                })
                --
                local ResizableButton_6 = Library:CreateObject("ImageButton", {
                    ImageColor3 = Color3.fromRGB(40, 40, 40),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    AnchorPoint = Vector2.new(1, 1),
                    Image = "http://www.roblox.com/asset/?id=127012144286347",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -2, 1, -2),
                    Name = "ResizableButton_6",
                    Size = UDim2.new(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    ZIndex = 5,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = SectionOutline
                })
                --
                Section.Elements = {
                    Name = Title,
                    ContentHolder = SectionScrolling,
                }
                --
                Title.Size = UDim2.fromOffset(Title.TextBounds.X, 15)
                TitleInline.Size = UDim2.new(0, Title.TextBounds.X + 6, 0, 2)
                --
                do -- Functions
                    function Section:UpdateSection()
                        local CanvasSizeFloored = math.floor(SectionScrolling.AbsoluteCanvasSize.Y)
                        local AbsoluteSizeFloored = math.floor(SectionMain.AbsoluteSize.Y)
                        --
                        if CanvasSizeFloored > AbsoluteSizeFloored then
                            SectionMain.Size = UDim2.new(1, -8, 1, -2)
                            UpArrow.Visible = not Section:CheckArrows("Up")
                            DownArrow.Visible = not Section:CheckArrows("Down")
                        elseif CanvasSizeFloored == AbsoluteSizeFloored then
                            SectionMain.Size = UDim2.new(1, -2, 1, -2)
                            UpArrow.Visible = false
                            DownArrow.Visible = false
                        end
                    end
                    --
                    function Section:CheckArrows(Type)
                        if Type == "Up" then
                            return SectionScrolling.CanvasPosition == Vector2.new(0, 0)
                        elseif Type == "Down" then
                            return SectionScrolling.CanvasPosition == Vector2.new(0, SectionScrolling.AbsoluteCanvasSize.Y - SectionScrolling.AbsoluteSize.Y)
                        else
                            return false
                        end
                    end
                    --
                    function Section:CalculateHeight(Section, Container)
                        local Padding = 10
                        local Height = 0
                        --
                        for _, Child in Container:GetChildren() do
                            if Child:IsA("GuiObject") and Child.Visible then
                                Height = Height + Child.AbsoluteSize.Y + Padding
                            end
                        end
                        --
                        Section.Size = UDim2.new(Section.Size.X.Scale, Section.Size.X.Offset, 0, math.clamp(Height + 31, 50, SectionOutline.Parent.AbsoluteSize.Y))
                    end
                    --
                    function Section:CalculateButton(Position)
                        if Section.SizeButton then return end
                        --
                        local ButtonOutline = Library:CreateObject("Frame", {
                            Name = "SectionOutline",
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Size = UDim2.new(0, 30, 0, 25),
                            BorderSizePixel = 0,
                            Position = Position,
                            ZIndex = 5,
                            BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                            Parent = Library.UI.ScreenGUI
                        })
                        --
                        local ButtonMain = Library:CreateObject("Frame", {
                            Size = UDim2.new(1, -2, 1, -2),
                            Name = "SectionMain_1",
                            Position = UDim2.new(0, 1, 0, 1),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            ZIndex = 5,
                            BorderSizePixel = 0,
                            BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                            Parent = ButtonOutline
                        })
                        --
                        local ButtonText = Library:CreateObject("TextLabel", {
                            AnchorPoint = Vector2.new(0, 0.5),
                            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                            BackgroundTransparency = 1,
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            Parent = ButtonOutline,
                            Position = UDim2.new(0, 0, 0.5, -1),
                            Size = UDim2.new(1, 0, 1, 0),
                            ZIndex = 5,
                            FontFace = Library.UI.NewFont,
                            RichText = true,
                            Text = "Calculate height",
                            TextColor3 = Color3.fromRGB(198, 198, 198),
                            TextSize = Library.UI.FontSize,
                            TextStrokeTransparency = 1,
                            TextXAlignment = "Left"
                        })
                        --
                        local UIPadding_82 = Library:CreateObject("UIPadding", {
                            PaddingLeft = UDim.new(0, 8),
                            Parent = ButtonText
                        })
                        --
                        local Button_945 = Library:CreateObject("TextButton", {
                            FontFace = Library.UI.NewFont,
                            TextColor3 = Color3.fromRGB(0, 0, 0),
                            BorderColor3 = Color3.fromRGB(0, 0, 0),
                            Name = "Button_9",
                            BackgroundTransparency = 1,
                            ZIndex = 5,
                            Size = UDim2.new(1, 0, 1, 0),
                            BorderSizePixel = 0,
                            TextTransparency = 1,
                            TextSize = Library.UI.FontSize,
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                            Parent = ButtonOutline
                        })
                        --
                        Section.SizeButton = ButtonOutline
                        ButtonOutline.Size = UDim2.fromOffset(ButtonText.TextBounds.X + 16, 25)
                        ButtonOutline.BackgroundTransparency = 1
                        ButtonMain.BackgroundTransparency = 1
                        ButtonText.TextTransparency = 1
                        Button_945.TextTransparency = 1
                        --
                        do -- Connections
                            Library:Connection(Button_945.MouseEnter, function()
                                Section.Hovering = true
                            end)
                            --
                            Library:Connection(Button_945.MouseLeave, function()
                                Section.Hovering = false
                            end)
                            --
                            Library:Connection(Button_945.MouseButton1Click, function()
                                Section:CalculateHeight(SectionOutline, SectionScrolling)
                                Library:Fade(false, Library:GetObjectsTable(ButtonOutline, true), ButtonOutline, 0.1)
                                --
                                task.delay(Library.UI.TweenSpeed, function()
                                    for _, Value in ButtonOutline:GetDescendants() do
                                        Value:Destroy()
                                    end
                                    --
                                    ButtonOutline:Destroy()
                                    Section.SizeButton = nil
                                end)
                            end)
                        end
                        --
                        Library:Fade(true, Library:GetObjectsTable(ButtonOutline, true), ButtonOutline, 0.1)
                    end
                end
                --
                do -- Connections
                    Library:Connection(SectionScrolling.ChildAdded, function()
                        Section:UpdateSection()
                    end)
                    --
                    Library:Connection(SectionScrolling.ChildRemoved, function()
                        Section:UpdateSection()
                    end)
                    --
                    Library:Connection(SectionOutline:GetPropertyChangedSignal("AbsoluteSize"), function()
                        Section:UpdateSection()
                    end)
                    --
                    Library:Connection(RunService.PreRender, function() -- fastest option
                        if SectionOutline.AbsoluteSize.Y >= ((SectionOutline.Parent.AbsoluteSize.Y - Tab.Sides[Options.Side].Sizes) - 38) then
                            if Tab.SubSectionEnabled then
                                if #Tab.Sides[Options.Side].Sections <= 3 then
                                    SectionOutline.Size = UDim2.new(1, 0, 1, -Tab.Sides[Options.Side].Sizes)
                                end
                            else
                                SectionOutline.Size = UDim2.new(1, 0, 1, -Tab.Sides[Options.Side].Sizes)
                            end
                        end
                        --
                        for _, Child in SectionOutline.Parent:GetChildren() do
                            if Child:IsA("Frame") and Child ~= SectionOutline then
                                if Library:CheckFrameFirst(SectionOutline, Child) then
                                    if Child.AbsoluteSize.Y >= ((Child.Parent.AbsoluteSize.Y - Tab.Sides[Options.Side].Sizes) - 38) then
                                        Child.Size = UDim2.new(Child.Size.X.Scale, Child.Size.X.Offset, 0, math.max(50, (SectionOutline.Parent.AbsoluteSize.Y - SectionOutline.AbsoluteSize.Y) - 57))
                                    end
                                    --
                                    if Child.AbsoluteSize.Y == 50 and (SectionOutline.AbsoluteSize.Y == SectionOutline.Parent.AbsoluteSize.Y - 107) then
                                        SectionOutline.Size = UDim2.new(SectionOutline.Size.X.Scale, SectionOutline.Size.X.Offset, 0, SectionOutline.Parent.AbsoluteSize.Y - 107)
                                    end
                                end
                            end
                        end
                    end)
                    --
                    Library:Connection(SectionScrolling:GetPropertyChangedSignal("AbsoluteCanvasSize"), function()
                        Section:UpdateSection()
                    end)
                    --
                    Library:Connection(SectionScrolling:GetPropertyChangedSignal("CanvasPosition"), function()
                        UpArrow.Visible = not Section:CheckArrows("Up")
                        DownArrow.Visible = not Section:CheckArrows("Down")
                    end)
                    --
                    Library:Connection(UpArrow.MouseButton1Click, function()
                        if not UpArrow.Visible then return end
                        --
                        Library:TweenObject(SectionScrolling, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(0, 0)})
                    end)
                    --
                    Library:Connection(DownArrow.MouseButton1Click, function()
                        if not DownArrow.Visible then return end
                        --
                        Library:TweenObject(SectionScrolling, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {CanvasPosition = Vector2.new(0, SectionScrolling.AbsoluteCanvasSize.Y - SectionScrolling.AbsoluteSize.Y)})
                    end)
                    --
                    do -- Dragging
                        Library:Connection(Title.MouseButton1Down, function()
                            Title.TextColor3 = Library.Theme.Default.Accent
                            --
                            Section.DragConnection = Library:Connection(UserInputService.InputChanged, function(Input)
                                if Input.UserInputType == Enum.UserInputType.MouseMovement then
                                    local SelectedOptions = {["SubSection"] = Options.ParentOptions, ["Other"] = {Left, Right}}
                                    local Selected = Tab.SubSectionEnabled and "SubSection" or "Other"
                                    local NewLeft, NewRight = SelectedOptions[Selected][1], SelectedOptions[Selected][2]
                                    local Parent2 = Library:SectionDragging(NewLeft) and NewLeft or Library:SectionDragging(NewRight) and NewRight
                                    local ParentName = Parent2 == NewLeft and "Left" or "Right"
                                    local TopHalf = Parent2 and Input.Position.Y < Parent2.AbsoluteSize.Y / 2
                                    --
                                    if not Parent2 then return end
                                    --
                                    SectionOutline.Parent = Parent2
                                    --
                                    for _, SectionChild in Parent2:GetChildren() do
                                        if SectionChild:IsA("Frame") and SectionChild.Visible then
                                            if SectionChild == SectionOutline then
                                                if TopHalf then
                                                    SectionChild.LayoutOrder = (Tab.DropdownSectionEnabled and Parent2 == NewLeft and 2) or 1
                                                else
                                                    SectionChild.LayoutOrder = Section[ParentName].Order + 1
                                                end
                                            else
                                                if SectionChild.Name == "DropdownSection1" then
                                                    SectionChild.LayoutOrder = 1
                                                else
                                                    SectionChild.LayoutOrder = Section[ParentName].Order
                                                    Section[ParentName].Order = 3
                                                end
                                            end
                                        end
                                    end
                                end
                            end)
                        end)
                    end
                    --
                    do -- Resizing
                        Library:Connection(ResizableButton_6.MouseButton2Click, function()
                            Section:CalculateButton(UDim2.fromOffset(ResizableButton_6.AbsolutePosition.X + ResizableButton_6.AbsoluteSize.X + 4, ResizableButton_6.AbsolutePosition.Y + ResizableButton_6.AbsoluteSize.Y + GuiService:GetGuiInset().Y))
                        end)
                        --
                        Library:Connection(ResizableButton_6.MouseButton1Down, function()
                            ResizableButton_6.ImageColor3 = Library.Theme.Default.Accent
                            SectionInline.BackgroundColor3 = Library.Theme.Default.Accent
                            --
                            SectionOutline.Size = UDim2.new(SectionOutline.Size.X.Scale, SectionOutline.Size.X.Offset, 0, SectionOutline.AbsoluteSize.Y)
                        end)
                        --
                        Library:Connection(UserInputService.InputBegan, function(Input)
                            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Section.SizeButton and not Section.Hovering then
                                Library:Fade(false, Library:GetObjectsTable(Section.SizeButton, true), Section.SizeButton, 0.1)
                                --
                                task.delay(Library.UI.TweenSpeed, function()
                                    for _, Value in Section.SizeButton:GetDescendants() do
                                        Value:Destroy()
                                    end
                                    --
                                    Section.SizeButton:Destroy()
                                    Section.SizeButton = nil
                                end)
                            end
                        end)
                        --
                        Library:Resizable(SectionOutline, ResizableButton_6, UDim2.fromOffset(200, 50), UDim2.fromOffset(SectionOutline.Parent.AbsoluteSize.X - 29, SectionOutline.Parent.AbsoluteSize.Y - 38), Library.UI.SectionResizeIncrements, false, true, 0.01)
                    end
                    --
                    Library:Connection(UserInputService.InputEnded, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            if Section.DragConnection then Section.DragConnection:Disconnect() Section.DragConnection = nil end
                            Section.Left.Order = 1
                            Section.Right.Order = 1
                            Title.TextColor3 = Color3.fromRGB(198, 198, 198)
                            --
                            ResizableButton_6.ImageColor3 = Color3.fromRGB(40, 40, 40)
                            SectionInline.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        end
                    end)
                end
                --
                return setmetatable(Section, Library.Sections)
            end
            --
            function Tab:SubSection(Options)
                Options = Library:Validate({
                    Name = "Preview Sub Section",
                    Options = {},
                    Flag = Library:NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local SubSection = {
                    CurrentSection = nil,
                    Sections = {},
                    List = {},
                    Elements = {},
                }
                --
                SubSectionHolder.Visible = true
                Tab.SubSectionEnabled = true
                Tab.Sides.Right.Sizes = 0
                Tab.Sides.Left.Sizes = 0
                --
                local SectionOutline = Library:CreateObject("Frame", {
                    Name = "SectionOutline",
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    ZIndex = 1,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = SubSectionHolder
                })
                --
                SectionOutline:SetAttribute("g", 0)
                --
                local SectionInline = Library:CreateObject("Frame", {
                    Name = "SectionInline",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    Parent = SectionOutline
                })
                --
                local SectionMain = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "SectionMain_1",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    Parent = SectionInline
                })
                --
                local UIPadding_81 = Library:CreateObject("UIPadding", {
                    PaddingRight = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 10),
                    Parent = SectionMain
                })
                --
                local UIListLayout52 = Library:CreateObject("UIListLayout", {
                    Padding = UDim.new(0, -0),
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    HorizontalAlignment = Enum.HorizontalAlignment.Left,
                    Parent = SectionMain
                })
                --
                local TitleInline = Library:CreateObject("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 0,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "TitleInline",
                    BorderSizePixel = 0,
                    Parent = SectionOutline,
                    Position = UDim2.new(0, 9, 0, 0),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 5
                })
                --
                local UIGradient2 = Library:CreateObject("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 19, 19)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 24))
                    },
                    Parent = TitleInline
                })
                --
                local Title = Library:CreateObject("TextLabel", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    Parent = SectionOutline,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -26, 0, 15),
                    ZIndex = 5,
                    FontFace = Library.UI.NewFont,
                    RichText = true,
                    Text = "<b>" .. Options.Name .. "</b>",
                    TextColor3 = Color3.fromRGB(198, 198, 198),
                    TextSize = Library.UI.FontSize,
                    TextStrokeTransparency = 1,
                    TextXAlignment = "Left"
                })
                --
                for Index, Value in Options.Options do
                    local SectionItem = {
                        Active = false,
                        Hovering = false,
                        Position = "Bottom",
                        Elements = {},
                    }
                    --
                    local SectionsHolder2 = Library:CreateObject("Frame", {
                        Name = "SectionsHolder",
                        BackgroundTransparency = 1,
                        Visible = false,
                        Position = UDim2.new(0, 97, 0, 33),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Size = UDim2.new(1, -112, 1, -34),
                        BorderSizePixel = 0,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        ClipsDescendants = true,
                        Parent = Outline_1
                    })
                    --
                    local UIPadding_141 = Library:CreateObject("UIPadding", {
                        PaddingTop = UDim.new(0, 52),
                        Parent = SectionsHolder2
                    })
                    --
                    local Left2 = Library:CreateObject("Frame", {
                        BackgroundTransparency = 1,
                        Name = "Left2",
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Size = UDim2.new(0.5, 0, 1, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Parent = SectionsHolder2
                    })
                    --
                    local UIPadding_11 = Library:CreateObject("UIPadding", {
                        PaddingTop = UDim.new(0, 19),
                        PaddingBottom = UDim.new(0, 19),
                        PaddingRight = UDim.new(0, 12),
                        Parent = Left2
                    })
                    --
                    local UIListLayout12 = Library:CreateObject("UIListLayout", {
                        Padding = UDim.new(0, 19),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = Left2
                    })
                    --
                    local Right2 = Library:CreateObject("Frame", {
                        Name = "Right2",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0.5, 0, 0, 0),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Size = UDim2.new(0.5, 0, 1, 0),
                        BorderSizePixel = 0,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Parent = SectionsHolder2
                    })
                    --
                    local UIPadding_21 = Library:CreateObject("UIPadding", {
                        PaddingTop = UDim.new(0, 19),
                        PaddingBottom = UDim.new(0, 19),
                        PaddingRight = UDim.new(0, 6),
                        PaddingLeft = UDim.new(0, 6),
                        Parent = Right2
                    })
                    --
                    local UIListLayout521 = Library:CreateObject("UIListLayout", {
                        Padding = UDim.new(0, 19),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = Right2
                    })
                    --
                    local Icon = Library:CreateObject("ImageButton", {
                        ImageColor3 = Color3.fromRGB(100, 100, 100),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Icon",
                        Image = Value,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 75, 0, 57),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Parent = SectionMain
                    })
                    --
                    Left2.Position = UDim2.new(0, -(Left2.AbsoluteSize.X * 2), 0, 0)
                    Right2.Position = UDim2.new(0.5, -(Right2.AbsoluteSize.X * 2), 0, 0)
                    --
                    do -- Functions
                        function SectionItem:MoveSides(State)
                            task.spawn(function()
                                if State then
                                    if SectionItem.Position == "Bottom" then
                                        Left2.Position = UDim2.new(0, (Left2.AbsoluteSize.X * 2), 0, 0)
                                        Right2.Position = UDim2.new(0.5, (Right2.AbsoluteSize.X * 2), 0, 0)
                                    else
                                        Left2.Position = UDim2.new(0, -(Left2.AbsoluteSize.X * 2), 0, 0)
                                        Right2.Position = UDim2.new(0.5, -(Right2.AbsoluteSize.X * 2), 0, 0)
                                    end
                                    --
                                    SectionsHolder2.Visible = Outline:GetAttribute("g") == table.find(Window.Tabs, Tab)
                                    Library:TweenObject(Left2, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, 1, 0, 0)})
                                    Library:TweenObject(Right2, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 1, 0, 0)})
                                else
                                    task.wait(0.001)
                                    --
                                    local LeftPosition = SectionItem.Position == "Bottom" and (Left2.AbsoluteSize.X * 2) + 10 or -(Left2.AbsoluteSize.X * 2)
                                    local RightPosition = SectionItem.Position == "Bottom" and (Right2.AbsoluteSize.X * 2) + 10 or -(Right2.AbsoluteSize.X * 2)
                                    --
                                    Library:TweenObject(Left2, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0, LeftPosition, 0, 0)})
                                    Library:TweenObject(Right2, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, RightPosition, 0, 0)})
                                end
                            end)
                        end
                        --
                        function SectionItem:Activate()
                            if not SectionItem.Active then
                                if SubSection.CurrentSection ~= nil then
                                    SubSection.CurrentSection:Deactivate()
                                end
                                --
                                SectionItem.Active = true
                                --
                                SectionItem:MoveSides(true)
                                Icon.ImageColor3 = Color3.fromRGB(188, 188, 188)
                                --
                                SubSection.CurrentSection = SectionItem
                                SectionOutline:SetAttribute("g", Index)
                            end
                        end
                        --
                        function SectionItem:Deactivate()
                            if SectionItem.Active then
                                SectionItem.Active = false
                                SectionItem.Hovering = false
                                --
                                SectionItem:MoveSides(false)
                                Icon.ImageColor3 = Color3.fromRGB(93, 93, 93)
                            end
                        end
                        --
                        function SectionItem:Section(Options)
                            Options = Library:Validate({
                                Name = "Preview Section",
                                Side = "Left",
                                Size = 40,
                            }, Options or {})
                            --
                            local Section = Tab:Section({
                                Name = Options.Name,
                                Side = Options.Side,
                                Fill = Options.Fill,
                                Size = Options.Size,
                                Parent = Options.Side == "Left" and Left2 or Right2,
                                ParentOptions = {Left2, Right2},
                                Icon = Icon,
                            })
                            --
                            return Section
                        end
                    end
                    --
                    do -- Connections
                        Library:Connection(Outline:GetPropertyChangedSignal("AbsoluteSize"), function()
                            if not SectionItem.Active then
                                Left2.Position = UDim2.new(0, Left2.AbsoluteSize.X * 2, 0, 0)
                                Right2.Position = UDim2.new(0.5, Right2.AbsoluteSize.X * 2, 0, 0)
                            end
                        end)
                        --
                        Library:Connection(Outline:GetAttributeChangedSignal("g"), function()
                            if Outline:GetAttribute("g") == table.find(Window.Tabs, Tab) then
                                SectionsHolder2.Visible = true
                            end
                        end)
                        --
                        Library:Connection(SectionOutline:GetAttributeChangedSignal("g"), function()
                            if SectionOutline:GetAttribute("g") > Index then
                                SectionItem.Position = "Top"
                            elseif SectionOutline:GetAttribute("g") < Index then
                                SectionItem.Position = "Bottom"
                            end
                        end)
                        --
                        Library:Connection(Left:GetPropertyChangedSignal("AbsolutePosition"), function()
                            if SectionItem.Active then
                                Left2.Position = Left.Position
                            end
                        end)
                        --
                        Library:Connection(Right:GetPropertyChangedSignal("AbsolutePosition"), function()
                            if SectionItem.Active then
                                Right2.Position = Right.Position
                            end
                        end)
                        --
                        Library:Connection(Icon.MouseButton1Click, function()
                            SectionItem:Activate()
                        end)
                        --
                        Library:Connection(Icon.MouseEnter, function()
                            if not SectionItem.Active then
                                SectionItem.Hovering = true
                                Icon.ImageColor3 = Color3.fromRGB(124, 124, 124)
                            end
                        end)
                        --
                        Library:Connection(Icon.MouseLeave, function()
                            if not SectionItem.Active then
                                SectionItem.Hovering = false
                                Icon.ImageColor3 = Color3.fromRGB(93, 93, 93)
                            end
                        end)
                    end
                    --
                    if SubSection.CurrentSection == nil then
                        SectionItem:Activate()
                    end
                    --
                    SubSection.Sections[#SubSection.Sections + 1] = setmetatable(SectionItem, Library.Sections)
                end
                --
                SubSection.Elements = {
                    Name = Title,
                    ContentHolder = SectionMain,
                }
                --
                TitleInline.Size = UDim2.new(0, Title.TextBounds.X + 6, 0, 2)
                --
                return table.unpack(SubSection.Sections)
            end
            --
            function Tab:ImageDropdown(Options)
                Options = Library:Validate({
                    Name = "Weapon Type",
                    Options = {},
                    Default = nil,
                    Flag = Library:NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local ImageDropdown = {
                    Open = false,
                    Active = false,
                    Hovering = false,
                    CurrentItem = nil,
                    Scrollable = false,
                    Hiding = false,
                    ContentLength = Library:GetTableLength(Options.Options),
                }
                --
                Tab.DropdownSectionEnabled = true
                Tab.Sides.Left.Sizes = 70
                --
                local DropdownImageOutline = Library:CreateObject("Frame", {
                    Name = "DropdownSection1",
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, 0, 0, 51),
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = Left
                })
                --
                local DropdownChecker = Library:CreateObject("Frame", {
                    Name = "DropdownChecker",
                    Position = UDim2.new(0, 0, 1, 0),
                    Visible = false,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    BorderSizePixel = 0,
                    Parent = DropdownImageOutline
                })
                --
                local DropdownImageInline = Library:CreateObject("Frame", {
                    Name = "DropdownImageInline",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                    Parent = DropdownImageOutline
                })
                --
                local DropdownImageMain = Library:CreateObject("Frame", {
                    Size = UDim2.new(1, -2, 1, -2),
                    Name = "DropdownImageMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(23, 23, 23),
                    Parent = DropdownImageInline
                })
                --
                local Button_92 = Library:CreateObject("TextButton", {
                    FontFace = Library.UI.NewFont,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Button_9",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextTransparency = 1,
                    TextSize = Library.UI.FontSize,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = DropdownImageMain
                })
                --
                local DownArrow = Library:CreateObject("ImageLabel", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "DownArrow",
                    Size = UDim2.new(0, 5, 0, 4),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Image = "rbxassetid://15540867448",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -6, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    ImageColor3 = Color3.fromRGB(210, 210, 210),
                    Parent = DropdownImageMain
                })
                --
                local Icon = Library:CreateObject("ImageLabel", {
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "Icon",
                    Size = UDim2.new(0, 50, 1, -6),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Image = "rbxassetid://18657040454",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -14, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    ImageColor3 = Color3.fromRGB(210, 210, 210),
                    Parent = DropdownImageMain
                })
                --
                local ToggleHolder = Library:CreateObject("Frame", {
                    Name = "ToggleHolder",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 100, 1, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Parent = DropdownImageMain
                })
                --
                local ActualToggleButton = Library:Toggle({
                    Default = false,
                    Name = "Global",
                    SectionName = "ToggleHolder",
                    Parent = ToggleHolder,
                    Risky = false,
                    MainUI = Outline,
                    ZIndex = 2,
                    TabUI = SideBarMain,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    UseToggleOutline = true,
                    Hidden = false,
                    Flag = Options.Flag .. "Extra",
                    Callback = function(State)
                        if ImageDropdown.CurrentItem then
                            ImageDropdown.CurrentItem:SetValue(State)
                            Library.Flags[Options.Flag] = ImageDropdown.CurrentItem
                            Options.Callback(ImageDropdown.CurrentItem.Name, ImageDropdown.CurrentItem.CurrentValue)
                        end
                    end,
                })
                --
                local UIPadding = Library:CreateObject("UIPadding", {
                    PaddingLeft = UDim.new(0, 18),
                    Parent = ToggleHolder
                })
                --
                local TitleInline = Library:CreateObject("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BackgroundTransparency = 0,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Name = "TitleInline",
                    BorderSizePixel = 0,
                    Parent = DropdownImageOutline,
                    Position = UDim2.new(0, 9, 0, 0),
                    Size = UDim2.new(0, 0, 0, 2),
                    ZIndex = 5
                })
                --
                local UIGradient2 = Library:CreateObject("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 19, 19)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 24))
                    },
                    Parent = TitleInline
                })
                --
                local Title = Library:CreateObject("TextButton", {
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    Parent = DropdownImageOutline,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(1, -26, 0, 15),
                    ZIndex = 5,
                    FontFace = Library.UI.NewFont,
                    RichText = true,
                    Text = "<b>" .. Options.Name .. "</b>",
                    TextColor3 = Color3.fromRGB(198, 198, 198),
                    TextSize = Library.UI.FontSize,
                    TextStrokeTransparency = 1,
                    TextXAlignment = "Left"
                })
                --
                local DropdownMainOutline = Library:CreateObject("Frame", {
                    Name = "DropdownMainOutline",
                    Position = UDim2.new(0, 0, 0, 0),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 50,
                    BorderSizePixel = 0,
                    BackgroundColor3 = Color3.fromRGB(12, 12, 12),
                    Parent = Library.UI.ScreenGUI
                })
                --
                local DropdownMain = Library:CreateObject("Frame", {
                    Name = "DropdownMain",
                    Position = UDim2.new(0, 1, 0, 1),
                    BorderColor3 = Color3.fromRGB(0, 0, 0),
                    Size = UDim2.new(1, -2, 1, -2),
                    BorderSizePixel = 0,
                    ZIndex = 50,
                    ClipsDescendants = true,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    Parent = DropdownMainOutline
                })
                --
                DropdownMainOutline.BackgroundTransparency = 1
                DropdownMain.BackgroundTransparency = 1
                --
                local UIListLayout_9 = Library:CreateObject("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = DropdownMain
                })
                --
                Title.Size = UDim2.fromOffset(Title.TextBounds.X, 15)
                TitleInline.Size = UDim2.new(0, Title.TextBounds.X + 6, 0, 2)
                --
                for Index, Value in Options.Options do
                    local DropdownOption = {
                        Hovering = false,
                        Active = false,
                        CurrentValue = false,
                        Name = Index,
                    }
                    --
                    local ButtonMain = Library:CreateObject("Frame", {
                        Name = "DropdownMain",
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Size = UDim2.new(1, 0, 0, 30),
                        BorderSizePixel = 0,
                        ZIndex = 50,
                        ClipsDescendants = true,
                        LayoutOrder = Value.Order,
                        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                        Parent = DropdownMain
                    })
                    --
                    local Button_925 = Library:CreateObject("TextButton", {
                        FontFace = Library.UI.NewFont,
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Button_9",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        BorderSizePixel = 0,
                        ZIndex = 50,
                        TextTransparency = 1,
                        TextSize = Library.UI.FontSize,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Parent = ButtonMain
                    })
                    --
                    ButtonMain.BackgroundTransparency = 1
                    --
                    local ToggleButton = Library:Toggle({
                        Default = false,
                        Name = Index,
                        SectionName = "ImageDropdown",
                        Parent = ButtonMain,
                        Risky = false,
                        MainUI = Outline,
                        ZIndex = 50,
                        TabUI = SideBarMain,
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 15, 0.5, 0),
                        Hidden = false,
                        Callback = function(State)

                        end,
                    })
                    --
                    local IconButton = Library:CreateObject("ImageLabel", {
                        BorderColor3 = Color3.fromRGB(0, 0, 0),
                        Name = "Icon",
                        Size = UDim2.new(0, 35, 1, 0),
                        AnchorPoint = Vector2.new(1, 0.5),
                        Image = Value.Icon,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -10, 0.5, 0),
                        ZIndex = 50,
                        BorderSizePixel = 0,
                        ImageColor3 = Color3.fromRGB(124, 124, 124),
                        Parent = ButtonMain
                    })
                    --
                    do -- Functions
                        function DropdownOption:Activate()
                            if not DropdownOption.Active then
                                if ImageDropdown.CurrentItem ~= nil then
                                    ImageDropdown.CurrentItem:Deactivate()
                                end
                                --
                                DropdownOption.Active = true
                                ImageDropdown.CurrentItem = DropdownOption
                                --
                                IconButton.ImageColor3 = Color3.fromRGB(210, 210, 210)
                                Icon.Image = Value.Icon
                                ActualToggleButton:SetName(Index)
                            end
                        end
                        --
                        function DropdownOption:Deactivate()
                            if DropdownOption.Active then
                                DropdownOption.Active = false
                                DropdownOption.Hovering = false
                                ImageDropdown.CurrentItem = nil
                                --
                                ButtonMain.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                                IconButton.ImageColor3 = Color3.fromRGB(124, 124, 124)
                            end
                        end
                        --
                        function DropdownOption:SetValue(Value)
                            ToggleButton:Set(Value)
                            DropdownOption.CurrentValue = Value
                        end
                        --
                        function DropdownOption:Get()
                            return {Name = DropdownOption.Name, Value = DropdownOption.CurrentValue}
                        end
                    end
                    --
                    do -- Connections
                        Library:Connection(ButtonMain.MouseEnter, function()
                            ButtonMain.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                            IconButton.ImageColor3 = Color3.fromRGB(210, 210, 210)
                        end)
                        --
                        Library:Connection(ButtonMain.MouseLeave, function()
                            ButtonMain.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                            --
                            if DropdownOption.Active then return end
                            --
                            IconButton.ImageColor3 = Color3.fromRGB(124, 124, 124)
                        end)
                        --
                        Library:Connection(Button_925.MouseButton1Click, function()
                            DropdownOption:Activate()
                            ActualToggleButton:Set(DropdownOption.CurrentValue)
                        end)
                    end
                    --
                    if Options.Default == Index then
                        DropdownOption:Activate()
                    end
                    --
                    Library:Fade(false, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0.1)
                end
                --
                do -- Functions
                    function ImageDropdown:Toggle(Fast)
                        local Fast = Fast or false
                        local OldValues = Library.Objects[DropdownMainOutline]
                        --
                        if ImageDropdown.Open then
                            if Fast then
                                Library:Fade(false, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0)
                                DropdownMainOutline.Size = UDim2.new(0, DropdownImageOutline.AbsoluteSize.X, 0, 0)
                                Library.Objects[DropdownMainOutline] = {DropdownMainOutline, OldValues[2], true}
                            else
                                Library:Fade(false, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0.1)
                                Library:TweenObject(DropdownMainOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, DropdownImageOutline.AbsoluteSize.X, 0, 0)}, function()
                                    Library.Objects[DropdownMainOutline] = {DropdownMainOutline, OldValues[2], true}
                                end)
                            end
                        else
                            Library.Objects[DropdownMainOutline] = {DropdownMainOutline, OldValues[2], false}
                            --
                            if Fast then
                                Library:Fade(true, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0)
                                DropdownMainOutline.Size = UDim2.new(0, DropdownImageOutline.AbsoluteSize.X, 0, (ImageDropdown.ContentLength * 30) + 2)
                            else
                                Library:Fade(true, Library:GetObjectsTable(DropdownMainOutline, true), DropdownMainOutline, 0.1)
                                Library:TweenObject(DropdownMainOutline, TweenInfo.new(Library.UI.TweenSpeed, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, DropdownImageOutline.AbsoluteSize.X, 0, (ImageDropdown.ContentLength * 30) + 2)})
                            end	
                        end
                        --
                        ImageDropdown.Open = not ImageDropdown.Open
                    end
                    --
                    function ImageDropdown:Update()
                        DropdownMainOutline.Size = UDim2.new(0, DropdownImageOutline.AbsoluteSize.X, 0, DropdownMainOutline.AbsoluteSize.Y)
                        DropdownMainOutline.Position = UDim2.new(0, DropdownImageOutline.AbsolutePosition.X, 0, ((DropdownImageOutline.AbsolutePosition.Y + DropdownImageOutline.AbsoluteSize.Y) + GuiService:GetGuiInset().Y + 2))
                    end
                end
                --
                do -- Dropdown Connections
                    ImageDropdown:Update()
                    --
                    Library:Connection(DropdownImageOutline:GetPropertyChangedSignal("AbsolutePosition"), ImageDropdown.Update)
                    Library:Connection(DropdownImageOutline:GetPropertyChangedSignal("AbsoluteSize"), ImageDropdown.Update)
                    --
                    local StartingY = DropdownImageOutline.AbsolutePosition.Y
                    local MainUIStartingY = Outline.AbsolutePosition.Y
                    --
                    Library:Connection(DropdownImageOutline:GetPropertyChangedSignal("AbsolutePosition"), function()
                        if not ImageDropdown.Open then return end
                        --
                        local CurrentY = DropdownImageOutline.AbsolutePosition.Y
                        local MainUICurrentY = Outline.AbsolutePosition.Y
                        --
                        if MainUICurrentY ~= MainUIStartingY then
                            MainUIStartingY = MainUICurrentY
                            StartingY = CurrentY
                            --
                            return
                        end
                        --
                        if Library.UI.Resizing then
                            return
                        end
                        --
                        if CurrentY ~= StartingY then
                            ImageDropdown:Toggle(true)
                        end
                        --
                        StartingY = CurrentY
                    end)
                end
                --
                do -- Connections
                    Library:Connection(Button_92.MouseButton1Click, function()
                        ImageDropdown:Toggle()
                    end)
                end
            end
            --
            function Sections:Dropdown(Options)
                Options = Library:Validate({
                    Default = "None",
                    Name = "Preview Dropdown",
                    Content = {},
                    Hiding = false,
                    Risky = false,
                    Flag = Library.NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local Dropdown = Library:Dropdown({
                    Default = Options.Default,
                    Name = Options.Name,
                    Content = Options.Content,
                    MainUI = Outline,
                    TabUI = SideBarMain,
                    Hiding = Options.Hiding,
                    Risky = Options.Risky,
                    Flag = Options.Flag,
                    Callback = Options.Callback,
                    Parent = self.Elements.ContentHolder
                })
                --
                return Dropdown
            end
            --
            function Sections:MultiBox(Options)
                Options = Library:Validate({
                    Default = {},
                    Name = "Preview MultiBox",
                    Content = {},
                    Hiding = false,
                    Risky = false,
                    Flag = Library.NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local Dropdown = Library:MultiBox({
                    Default = Options.Default,
                    Name = Options.Name,
                    Content = Options.Content,
                    MainUI = Outline,
                    TabUI = SideBarMain,
                    Hiding = Options.Hiding,
                    Risky = Options.Risky,
                    Flag = Options.Flag,
                    Callback = Options.Callback,
                    Parent = self.Elements.ContentHolder
                })
                --
                return Dropdown
            end
            --
            function Sections:Toggle(Options)
                Options = Library:Validate({
                    Default = false,
                    Name = "Preview Toggle",
                    Risky = false,
                    Hidden = false,
                    Flag = Library:NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local Toggle = Library:Toggle({
                    Default = Options.Default,
                    Name = Options.Name,
                    SectionName = self.Elements.Name,
                    Parent = self.Elements.ContentHolder,
                    Risky = Options.Risky,
                    MainUI = Outline,
                    TabUI = SideBarMain,
                    Hidden = Options.Hidden,
                    Flag = Options.Flag,
                    Callback = Options.Callback
                })
                --
                return Toggle
            end
            --
            function Sections:Slider(Options)
                Options = Library:Validate({
                    Name = "Preview Slider",
                    Min = 0,
                    Max = 100,
                    Default = 1,
                    Decimal = 1,
                    Ending = "",
                    Hidden = false,
                    UseIcons = true,
                    Disable = {},
                    Risky = false,
                    OverrideLimit = false, -- new parameter to allow values beyond max
                    Flag = Library.NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local Slider = Library:Slider({
                    Name = Options.Name,
                    Min = Options.Min,
                    Max = Options.Max,
                    Default = Options.Default,
                    Decimal = Options.Decimal,
                    Ending = Options.Ending,
                    Hidden = Options.Hidden,
                    Parent = self.Elements.ContentHolder,
                    Risky = Options.Risky,
                    Disable = Options.Disable,
                    OverrideLimit = Options.OverrideLimit, -- pass the parameter
                    Flag = Options.Flag,
                    UseIcons = Options.UseIcons,
                    Callback = Options.Callback
                })
                --
                return Slider
            end
            --
            function Sections:Label(Options)
                Options = Library:Validate({
                    Message = "Preview Label",
                    Risky = false,
                    Side = "Left",
                    Hidden = false,
                }, Options or {})
                --
                local Label = Library:Label({
                    Message = Options.Message,
                    Side = Options.Side,
                    Risky = Options.Risky,
                    MainUI = Outline,
                    Hidden = Options.Hidden,
                    TabUI = SideBarMain,
                    SectionName = self.Elements.Name,
                    Callback = Options.Callback,
                    Parent = self.Elements.ContentHolder
                })
                --
                return Label
            end
            --
            function Sections:TextBox(Options)
                Options = Library:Validate({
                    Default = "",
                    Name = "Preview TextBox",
                    Max = 32,
                    NumbersOnly = false,
                    ClearOnFocus = false,
                    CheckIfPressedEnter = false,
                    Risky = false,
                    Hidden = false,
                    Flag = Library.NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local TextBox = Library:TextBox({
                    Default = Options.Default,
                    Name = Options.Name,
                    Max = Options.Max,
                    NumbersOnly = Options.NumbersOnly,
                    ClearOnFocus = Options.ClearOnFocus,
                    CheckIfPressedEnter = Options.CheckIfPressedEnter,
                    Risky = Options.Risky,
                    Hidden = Options.Hidden,
                    Parent = self.Elements.ContentHolder,
                    Flag = Options.Flag,
                    Callback = Options.Callback
                })
                --
                return TextBox
            end
            --
            function Sections:List(Options)
                Options = Library:Validate({
                    Size = 100,
                    Hidden = false,
                    Flag = Library.NewFlag(),
                    Callback = function() end
                }, Options or {})
                --
                local TextBox = Library:List({
                    Size = Options.Size,
                    Hidden = Options.Hidden,
                    Parent = self.Elements.ContentHolder,
                    Flag = Options.Flag,
                    Callback = Options.Callback
                })
                --
                return TextBox
            end
            --
            function Sections:Button(Options)
                Options = Library:Validate({
                    Name = "Preview Button",
                    Confirmation = false,
                    Risky = false,
                    Hidden = false,
                    Callback = function() end
                }, Options or {})
                --
                local Button = Library:Button({
                    Name = Options.Name,
                    Confirmation = Options.Confirmation,
                    Risky = Options.Risky,
                    Hidden = Options.Hidden,
                    Parent = self.Elements.ContentHolder,
                    Callback = Options.Callback
                })
                --
                return Button
            end
            --
            return Tab
        end
        --
        function Library:CreateWatermark()
            local Watermark = {
                CanUse = true,
                Tick = tick(),
                RefreshTick = tick(),
            }
            --
            local MainWatermark = Library:CreateObject("Frame", {
                Name = "Watermark",
                Position = UDim2.new(0, 0, 0, 0),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(0, 400, 0, 20),
                BorderSizePixel = 0,
                ZIndex = 10000,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                Parent = Library.UI.ScreenGUI
            }, true)
            --
            local UIGradient = Library:CreateObject("UIGradient", {
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.25, 0.6119999885559082),
                    NumberSequenceKeypoint.new(0.5, 0.625),
                    NumberSequenceKeypoint.new(0.75, 0.625),
                    NumberSequenceKeypoint.new(1, 1)
                },
                Parent = MainWatermark
            }, true)
            --
            local UIStroke = Library:CreateObject("UIStroke", {
                Parent = MainWatermark
            }, true)
            --
            local UIGradient_1 = Library:CreateObject("UIGradient", {
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.232, 0.4000000059604645),
                    NumberSequenceKeypoint.new(0.5, 0.4000000059604645),
                    NumberSequenceKeypoint.new(0.75, 0.4000000059604645),
                    NumberSequenceKeypoint.new(1, 1)
                },
                Parent = UIStroke
            }, true)
            --
            local WatermarkText = Library:CreateObject("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextColor3 = Color3.fromRGB(208, 208, 208),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Text = "gamesense",
                Name = "Text",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                ZIndex = 10000,
                RichText = true,
                TextSize = 14,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = MainWatermark
            }, true)
            --
            local Stroke = Library:CreateObject("UIStroke", {
                Parent = WatermarkText,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Color = Color3.fromRGB(50, 50, 50),
            }, true)
            --
            local UIPadding = Library:CreateObject("UIPadding", {
                PaddingRight = UDim.new(0, 22),
                PaddingLeft = UDim.new(0, 22),
                Parent = WatermarkText
            }, true)
            --
            do -- Functions
                function Library:ToggleWatermark(State)
                    Watermark.CanUse = State
                    MainWatermark.Visible = State
                end
                --
                function Library:UpdateWatermark(Text)
                    if Watermark.CanUse and not MainWatermark.Visible then MainWatermark.Visible = true end
                    --
                    WatermarkText.Text = tostring(Text)
                    MainWatermark.Size = UDim2.new(0, WatermarkText.TextBounds.X + 44, 0, MainWatermark.Size.Y.Offset)
                    MainWatermark.Position = UDim2.new(1, -(MainWatermark.Size.X.Offset) - 5, 0, 5)
                end
            end
            --
            local R, G, B = Library.Theme.Default.Accent.R * 255, Library.Theme.Default.Accent.G * 255, Library.Theme.Default.Accent.B * 255
            --
            Library:UpdateWatermark(("game<font color='rgb(%d, %d, %d)'>sense</font>  <font color='rgb(%d, %d, %d)'>%s</font> <font size='10'>FPS</font>  %s"):format(R, G, B, R, G, B, "60", os.date("%X")))
            --
            Library:Notify({
                Message = ("You are using <font color='rgb(%d, %d, %d)'>gamesense</font>. Join <font color='rgb(%d, %d, %d)'>@</font> discord.gg/3E82u6ecyW"):format(R, G, B, R, G, B),
                Position = "Top Left",
                Delay = 15
            })
            --
            do -- Connections
                Library:Connection(RunService.PostSimulation, function()
                    if Library.UI.Initialized and MainWatermark.Visible then
                        local R, G, B = Library.Theme.Default.Accent.R * 255, Library.Theme.Default.Accent.G * 255, Library.Theme.Default.Accent.B * 255
                        local FPS = math.floor(1 / math.abs(Watermark.Tick - tick()))
                        --
                        Watermark.Tick = tick()
                        --
                        if (tick() - Watermark.RefreshTick) > Library.UI.WatermarkRefreshRate then
                            Library:UpdateWatermark(("game<font color='rgb(%d, %d, %d)'>sense</font>  <font color='rgb(%d, %d, %d)'>%s</font> <font size='10'>FPS</font>  %s"):format(R, G, B, R, G, B, FPS, os.date("%X")))
                            --
                            Watermark.RefreshTick = tick()
                        end
                    end
                end)
            end
        end
        --
        function Library:Notify(Options)
            Options = Library:Validate({
                Message = "Notification",
                Delay = 3,
                Position = "Top Left",
            }, Options or {})
            --
            local Notification = {}
            local Path = Options.Position == "Top Left" and Library.UI.Notifications.TopLeft or Library.UI.Notifications.Middle
            --
            local NotificationFrameObject = Library:CreateObject("Frame", {
                Name = "Watermark",
                Position = UDim2.new(0, 0, 0, 0),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Size = UDim2.new(0, 400, 0, 20),
                BorderSizePixel = 0,
                ZIndex = 10000,
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                Parent = Library.UI.ScreenGUI
            }, true)
            --
            NotificationFrameObject.BackgroundTransparency = 1
            --
            local UIGradient = Library:CreateObject("UIGradient", {
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.25, 0.6119999885559082),
                    NumberSequenceKeypoint.new(0.5, 0.625),
                    NumberSequenceKeypoint.new(0.75, 0.625),
                    NumberSequenceKeypoint.new(1, 1)
                },
                Parent = NotificationFrameObject
            }, true)
            --
            local UIStroke = Library:CreateObject("UIStroke", {
                Parent = NotificationFrameObject
            }, true)
            --
            UIStroke.Transparency = 1
            --
            local UIGradient_1 = Library:CreateObject("UIGradient", {
                Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.232, 0.4000000059604645),
                    NumberSequenceKeypoint.new(0.5, 0.4000000059604645),
                    NumberSequenceKeypoint.new(0.75, 0.4000000059604645),
                    NumberSequenceKeypoint.new(1, 1)
                },
                Parent = UIStroke
            }, true)
            --
            local NotificationText = Library:CreateObject("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                TextColor3 = Color3.fromRGB(208, 208, 208),
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                Text = Options.Message,
                Name = "Text",
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 10000,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                BorderSizePixel = 0,
                RichText = true,
                TextSize = 14,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = NotificationFrameObject
            }, true)
            --
            local Stroke = Library:CreateObject("UIStroke", {
                Parent = NotificationText,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Color = Color3.fromRGB(50, 50, 50),
            }, true)
            --
            Stroke.Transparency = 1
            --
            NotificationText.TextTransparency = 1
            --
            local UIPadding = Library:CreateObject("UIPadding", {
                PaddingRight = UDim.new(0, 22),
                PaddingLeft = UDim.new(0, 22),
                Parent = NotificationText
            }, true)
            --
            local NotificationFrame = {
                Class = "Notification",
                Object = NotificationFrameObject,
                Text = NotificationText,
            }
            --
            NotificationFrameObject.Position = Options.Position == "Top Left" and UDim2.new(0, -70, 0, 80 + (#Path * 24)) or UDim2.new(0, Viewport.X / 2 - (NotificationText.TextBounds.X + 4) / 2, 1, -150)
            --
            do -- Functions
                function Notification:UpdatePositions()
                    local TotalHeight = 80
                    local Padding = 6
                    --
                    for Index = #Path, 1, -1 do
                        local Value = Path[Index]
                        local NewPosition
                        --
                        if Options.Position == "Top Left" then
                            NewPosition = UDim2.new(0, 5, 0, TotalHeight)
                            TotalHeight = TotalHeight + Value.Object.AbsoluteSize.Y + Padding
                        else
                            NewPosition = UDim2.new(0, Viewport.X / 2 - (Value.Text.TextBounds.X + 4) / 2, 1, -150 - (Index * 24))
                        end
                        --
                        Library:TweenObject(Value.Object, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = NewPosition})
                    end
                end
                --
                function Notification:RemoveFrame()
                    Library:TweenObject(NotificationFrameObject, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
					Library:TweenObject(NotificationText, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 1})
					Library:TweenObject(UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1})
					Library:TweenObject(Stroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 1})
                    --
                    task.delay(0.25, function()
                        NotificationFrameObject:Destroy()

                        table.remove(Path, table.find(Path, NotificationFrame))

                        Notification:UpdatePositions()
                    end)
                end
                --
                function Notification:UpdateText(Text)
                    NotificationText.Text = Text
                    NotificationFrameObject.Size = UDim2.new(NotificationFrameObject.Size.X.Scale, NotificationText.TextBounds.X + 44, 0, NotificationText.TextBounds.Y + 4)
                end
                --
                function Notification:Update()
                    local TotalHeight = 50
                    local Padding = 6
                    --
					Library:TweenObject(NotificationFrameObject, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
					Library:TweenObject(NotificationText, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0})
					Library:TweenObject(UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 0})
					Library:TweenObject(Stroke, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Transparency = 0})
                    NotificationFrameObject.Size = UDim2.new(NotificationFrameObject.Size.X.Scale, NotificationText.TextBounds.X + 44, 0, NotificationText.TextBounds.Y + 4)
                    --
                    for _, Value in Path do
                        TotalHeight = TotalHeight + Value.Object.AbsoluteSize.Y + Padding
                    end
                    --
                    local NewPosition = Options.Position == "Top Left" and UDim2.new(0, 5, 0, TotalHeight) or UDim2.new(0, Viewport.X / 2 - (NotificationText.TextBounds.X + 4) / 2, 1, -150)
                    --
                    Library:TweenObject(NotificationFrameObject, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = NewPosition}, function()
                        if Options.Delay ~= math.huge then
                            task.delay(Options.Delay, Notification.RemoveFrame)
                        end
                    end)
                end
            end
            --
            Notification:Update()
            --
            table.insert(Path, 1, NotificationFrame)
            --
            Notification:UpdatePositions()
            --
            return Notification
        end
        --
        function Library:Init()
            Library.UI.Initialized = true
            --
            Library:CreateWatermark()
            --
            Library:Connection(Camera:GetPropertyChangedSignal("ViewportSize"), function()
                Viewport = Camera.ViewportSize
                --
                Outline.Position = UDim2.fromOffset((Viewport.X / 2) - (Outline.Size.X.Offset / 2), (Viewport.Y / 2) - (Outline.Size.Y.Offset / 2))
            end)
        end
        --
        function Library:Unload()
            pcall(function()
                local ch = Client and Client.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum then Camera.CameraSubject = hum end
            end)
            --
            for Index, Value in Library.Connections do
                pcall(function() Value:Disconnect() end)
            end
            --
            for _, Objects in Library.Objects do
                pcall(function() Objects[1]:Destroy() end)
            end
            --
            pcall(function() MainUI:Destroy() end)
        end
        --
        function Library:Disable()
            for Index, Value in Library.Flags do
                if Value.Set then
                    Value:Set(false)
                end
            end
        end
        --
        return setmetatable(Window, Library)
    end
end
--
local Window = Library:Window({CloseBind = Enum.KeyCode.RightShift})
local Rage = Window:CreateTab({Icon = "rbxassetid://18248771514"})
local AntiAim = Window:CreateTab({Icon = "rbxassetid://15453313321"})
local Aimbot = Window:CreateTab({Icon = "rbxassetid://15453335745"})
local Visuals = Window:CreateTab({Icon = "rbxassetid://15453344494"})
local Settings = Window:CreateTab({Icon = "rbxassetid://15453349637"})
local Weapons = Window:CreateTab({Icon = "rbxassetid://15453354931"})
local PlayerList = Window:CreateTab({Icon = "rbxassetid://15453359751"})
local Configs = Window:CreateTab({Icon = "rbxassetid://15453364412"})
local Lua = Window:CreateTab({Icon = "rbxassetid://18240049800"})
local ActualPlayerList
--
Window:SetTab(4)
AntiAim:Section({Fill = true})
AntiAim:Section({Fill = true, Side = "Right"})
--
do -- Rage
    Rage:ImageDropdown({Name = "Weapon type", Flag = "RageWeaponType", Options = {["Global"] = {Icon = "rbxassetid://18657040454", Order = 1}, ["Double Barrel SG"] = {Icon = "rbxassetid://18205706952", Order = 2}, ["Revolver"] = {Icon = "rbxassetid://18205704829", Order = 3}, ["LMG"] = {Icon = "rbxassetid://18205822505", Order = 4}}, Default = "Global"})
    --
	Rage:Section({Fill = true, Side = "Right"})
	local RageSection = Rage:Section({Fill = true})
	local Toggle1, Toggle2, Toggle3 = nil, nil, nil
	local Test = nil
	--
	local g = RageSection:Toggle({Callback = function(State)
		if not Toggle1 then return end
		--
		Toggle1:SetVisible(State)
		Toggle2:SetVisible(State)
		Toggle3:SetVisible(State)
	end})
	g:ColorPicker()
	g:ColorPicker()
	g:Keybind()
	--
	Toggle1 = RageSection:Toggle({Hidden = true, Callback = function(State)
		if not Test then return end
		--
		Test:SetVisible(State)
	end})
	Toggle1:Keybind({Default = Enum.KeyCode.Q, Mode = "On hotkey"})
	Test = RageSection:Slider({Name = "", Hidden = true, Default = 50})
	Toggle2 = RageSection:List({Hidden = true})
	Toggle3 = RageSection:Button({Confirmation = true, Hidden = true})
	--
	RageSection:Dropdown({Content = {"Option 1", "Option 2"}})
	RageSection:Label()
	RageSection:MultiBox({Content = {"Option 1", "Option 2"}})
end
--
-- // ============================================================
-- // TRIDENT SURVIVAL ESP | VISUALS (gamesense tab + controller)
-- // Использует espLibrary.lua + actorDrawingFix (уже вшиты выше)
-- // Executor lvl7 friendly: Advanced (PlayerClient) -> Workspace fallback -> Highlight fallback
-- // ============================================================
local ESP_DrawingOK_Cached = nil
do -- Visuals
    local VisualsSubSection, VisualsSubSection2, VisualsSubSection3, VisualsSubSection4 = Visuals:SubSection({Name = "Category", Options = {"rbxassetid://18334627891", "rbxassetid://18334630306", "rbxassetid://18334626899", "rbxassetid://18334625304"}})
    VisualsSubSection3:Section({Side = "Right", Fill = true})
    VisualsSubSection3:Section({Fill = true})
    VisualsSubSection4:Section({Side = "Right", Fill = true})
    VisualsSubSection4:Section({Fill = true})

    -- // ---------- espLibrary check ----------
    local espLib = nil
    pcall(function()
        espLib = espLibrary or getgenv().TridentESPLib
    end)
    if espLib then
        getgenv().TridentESPLib = espLib
    end

    -- // ---------- helpers (no debug lib needed) ----------
    local function GetLocalMiddle()
        local ok, m = pcall(function() return Workspace:FindFirstChild("Ignore") end)
        if ok and m then
            local lc = m:FindFirstChild("LocalCharacter")
            if lc then
                local mid = lc:FindFirstChild("Middle") or lc:FindFirstChild("HumanoidRootPart") or lc:FindFirstChildWhichIsA("BasePart", true)
                if mid then return mid end
            end
        end
        if Client and Client.Character then
            local hrp = Client.Character:FindFirstChild("HumanoidRootPart") or Client.Character:FindFirstChild("Head")
            if hrp then return hrp end
        end
        return nil
    end

    local function IsLocalModel(model)
        if not model then return false end
        if Client then
            if model == Client.Character then return true end
            pcall(function()
                if model.Name == Client.Name then
                    -- в Trident Workspace.Players/<Nick> совпадает с ником
                end
            end)
            if model.Name == Client.Name then return true end
        end
        local lm = nil
        pcall(function() lm = GetLocalMiddle() end)
        if lm and lm.Parent then
            local lok, lmodel = pcall(function() return lm:FindFirstAncestorOfClass("Model") end)
            if lok and lmodel and lmodel == model then return true end
            -- дистанция < 3 = это мы (для internal таблиц)
            local okd, d = pcall(function()
                return (model:GetPivot().Position - lm.Position).Magnitude
            end)
            if okd and d and d < 3 then return true end
        end
        return false
    end

    local function IsSleepingModel(model)
        local head = nil
        pcall(function() head = model:FindFirstChild("Head") end)
        if head then
            if head.Rotation == Vector3.new(0, 0, -75) or head.Rotation == Vector3.new(0, 0, 45) then
                return true
            end
        end
        local ok, res = pcall(function()
            local ac = model:FindFirstChildOfClass("AnimationController", true)
            if ac then
                local anim = ac:FindFirstChildOfClass("Animator", true)
                if anim then
                    for _, tr in anim:GetPlayingAnimationTracks() do
                        if tr.Animation and tr.Animation.AnimationId == "rbxassetid://13280887764" then
                            return true
                        end
                    end
                end
            end
            return false
        end)
        return ok and res or false
    end

    local function GetWeaponName(model)
        local ok, w = pcall(function()
            for _, ch in model:GetChildren() do
                if ch:IsA("Tool") then return ch.Name end
            end
            for _, ch in model:GetDescendants() do
                if ch:IsA("Tool") then return ch.Name end
            end
            return "none"
        end)
        return (ok and w) or "none"
    end

    local function GetPlayerModels()
        local out = {}
        local ok, folder = pcall(function() return Workspace:FindFirstChild("Players") end)
        if ok and folder then
            for _, m in folder:GetChildren() do
                if m:IsA("Model") then
                    local hrp = m:FindFirstChild("HumanoidRootPart")
                    if hrp then table.insert(out, m) end
                end
            end
            if #out > 0 then return out end
        end
        -- fallback: любые модели с Humanoid + HRP в Workspace
        for _, m in Workspace:GetChildren() do
            if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Head") then
                if m.Name ~= "Model" and not m:FindFirstChild("Meshes/rock", true) then
                    table.insert(out, m)
                end
            end
        end
        return out
    end

    local function OreKindFromName(nm)
        nm = string.lower(nm)
        if string.find(nm, "iron", 1, true) then return "Iron Ore", TridentSettings.Ores.ColorIron end
        if string.find(nm, "nitra", 1, true) then return "Nitrate Ore", TridentSettings.Ores.ColorNitrate end
        if string.find(nm, "stone", 1, true) or string.find(nm, "cobble", 1, true) then return "Stone Ore", TridentSettings.Ores.ColorStone end
        return nil, nil
    end
    local function PushOre(out, m, name, col)
        if typeof(m) ~= "Instance" or not m.Parent then return end
        if not m:IsA("Model") then return end
        local ok = pcall(function() m:GetBoundingBox() end)
        if ok then table.insert(out, { model = m, oreName = name, color = col }) end
    end
    local function IsCharLike(ch)
        local ok, r = pcall(function()
            return ch:FindFirstChild("HumanoidRootPart") ~= nil or ch:FindFirstChild("Humanoid") ~= nil
        end)
        return ok and r
    end
    local function ClassifyRockModelInto(out, ch)
        local rock = nil
        pcall(function() rock = ch:FindFirstChild("Meshes/rock", true) end)
        if not rock then return false end
        local oreName = "Stone Ore"
        local col = TridentSettings.Ores.ColorStone
        pcall(function()
            for _, v2 in ch:GetChildren() do
                if v2:IsA("MeshPart") then
                    if v2.BrickColor == BrickColor.new(352) then
                        oreName = "Iron Ore" col = TridentSettings.Ores.ColorIron
                    elseif v2.BrickColor == BrickColor.new(1001) then
                        oreName = "Nitrate Ore" col = TridentSettings.Ores.ColorNitrate
                    end
                end
            end
            if #ch:GetChildren() == 1 then oreName = "Stone Ore" col = TridentSettings.Ores.ColorStone end
        end)
        PushOre(out, ch, oreName, col)
        return true
    end
    -- // ---------- POIs: глубокий скан руды + NPC (кэш + инкремент) ----------
    -- // ---------- Сигнатуры сущностей (метод SwimHub/yougame): ReplicatedStorage.Shared.entities ----------
    local EntitySig = {}
    local EntitySigBuilt = false
    local function BuildEntitySig()
        if EntitySigBuilt then return end
        EntitySigBuilt = true
        pcall(function()
            local shared = ReplicatedStorage:FindFirstChild("Shared")
            local ents = shared and shared:FindFirstChild("entities")
            if not ents then return end
            for _, v in ents:GetChildren() do
                local model = v:FindFirstChild("Model")
                local pp = model and model.PrimaryPart
                if pp then
                    EntitySig[v.Name] = { Color = pp.Color, Material = pp.Material, CollisionGroup = pp.CollisionGroup }
                end
            end
        end)
    end
    local ORE_MESH = "rbxassetid://12939036056"
    local function IdentifyModel(model)
        local ok, kind, part = pcall(function()
            if not model:IsA("Model") then return nil, nil end
            local mp = model:FindFirstChildOfClass("MeshPart")
            if mp and mp.MeshId == ORE_MESH then
                if #model:GetChildren() == 1 then return "Stone", mp end
                for _, p in model:GetChildren() do
                    if p:IsA("BasePart") then
                        if p.Color == Color3.fromRGB(248, 248, 248) then return "Nitrate", p end
                        if p.Color == Color3.fromRGB(199, 172, 120) then return "Iron", p end
                    end
                end
                return "Stone", mp
            end
            local pp = model.PrimaryPart
            if not pp then return nil, nil end
            BuildEntitySig()
            for name, sig in EntitySig do
                if sig.Color == pp.Color and sig.Material == pp.Material and sig.CollisionGroup == pp.CollisionGroup then
                    return name, pp
                end
            end
            return nil, nil
        end)
        if ok then return kind, part end
        return nil, nil
    end
    local function OreLabelColor(kind)
        if kind == "Iron" then return "Iron Ore", TridentSettings.Ores.ColorIron end
        if kind == "Nitrate" then return "Nitrate Ore", TridentSettings.Ores.ColorNitrate end
        return "Stone Ore", TridentSettings.Ores.ColorStone
    end
    local POIOres = {}
    local POINPCs = {}
    local POISeen = {}
    local POIConns = {}
    local POIScanTick = -100
    local POIConnected = false
    local function ClassifyPOIModel(m, oreOut, npcOut)
        if not m:IsA("Model") then return end
        if not m.Parent then return end
        if POISeen[m] then return end
        POISeen[m] = true
        -- NPC: любая кукла с HRP/Humanoid/Head (игроков в POIs нет — их модели в корне)
        do
            local hasChar = false
            pcall(function()
                hasChar = m:FindFirstChild("HumanoidRootPart") ~= nil
                    or m:FindFirstChild("Humanoid") ~= nil
                    or m:FindFirstChild("Head") ~= nil
            end)
            if hasChar then table.insert(npcOut, m) return end
        end
        if IsCharLike(m) then return end
        -- точная сигнатура шаблона (метод SwimHub)
        do
            local signame = IdentifyModel(m)
            if signame == "Stone" or signame == "Nitrate" or signame == "Iron" then
                local label, col = OreLabelColor(signame)
                PushOre(oreOut, m, label, col)
                return
            elseif signame then
                return -- Backpack/Tree/ATV/... — не руда, разберут свои сканеры
            end
        end
        local kind, col = OreKindFromName(m.Name)
        if kind then PushOre(oreOut, m, kind, col) return end
        local small = false
        pcall(function() small = #m:GetDescendants() < 60 end)
        if small then
            if ClassifyRockModelInto(oreOut, m) then return end
            -- запасной вариант: тан/белый меш (фирменные цвета железной/нитратной руды)
            pcall(function()
                for _, d in m:GetDescendants() do
                    if d:IsA("MeshPart") then
                        if d.Color == Color3.fromRGB(199, 172, 120) then
                            PushOre(oreOut, m, "Iron Ore", TridentSettings.Ores.ColorIron)
                            return
                        elseif d.Color == Color3.fromRGB(248, 248, 248) then
                            PushOre(oreOut, m, "Nitrate Ore", TridentSettings.Ores.ColorNitrate)
                            return
                        end
                        local dn = string.lower(d.Name)
                        if string.find(dn, "rock", 1, true) or string.find(dn, "ore", 1, true) then
                            PushOre(oreOut, m, "Stone Ore", TridentSettings.Ores.ColorStone)
                            return
                        end
                    end
                end
            end)
        end
    end
    local function RescanPOIs(force)
        local now = os.clock()
        if not force and now - POIScanTick < 30 then return end
        POIScanTick = now
        POISeen = {}
        local oreOut, npcOut = {}, {}
        local pois = nil
        pcall(function()
            local w = Workspace:FindFirstChild("World")
            pois = w and w:FindFirstChild("POIs")
        end)
        if pois then
            pcall(function()
                for _, d in pois:GetDescendants() do
                    if d:IsA("Model") then ClassifyPOIModel(d, oreOut, npcOut) end
                end
            end)
            if not POIConnected then
                POIConnected = true
                pcall(function()
                    local c = pois.DescendantAdded:Connect(function(d)
                        if d:IsA("Model") then
                            task.delay(1, function() pcall(function() ClassifyPOIModel(d, POIOres, POINPCs) end) end)
                        end
                    end)
                    table.insert(POIConns, c)
                end)
            end
        end
        POIOres, POINPCs = oreOut, npcOut
    end
    local OreScanCache = {}
    local OreScanTick = 0
    local function ScanOres()
        local now = os.clock()
        if now - OreScanTick < 1 and #OreScanCache > 0 then return OreScanCache end
        OreScanTick = now
        local out = {}
        local seen = {}
        local function push(m, name, col)
            if seen[m] then return end
            local before = #out
            PushOre(out, m, name, col)
            if #out > before then seen[m] = true end
        end
        -- 0) Точный метод SwimHub: сигнатуры шаблонов ReplicatedStorage.Shared.entities
        do
            local sigModels = {}
            pcall(function()
                for _, ch in Workspace:GetChildren() do
                    if ch:IsA("Model") then table.insert(sigModels, ch) end
                end
                local w = Workspace:FindFirstChild("World")
                if w then
                    for _, ch in w:GetChildren() do
                        if ch:IsA("Model") then table.insert(sigModels, ch)
                        elseif ch:IsA("Folder") then
                            for _, m in ch:GetChildren() do
                                if m:IsA("Model") then table.insert(sigModels, m) end
                            end
                        end
                    end
                end
            end)
            for _, m in sigModels do
                if not IsCharLike(m) then
                    local kind = IdentifyModel(m)
                    if kind == "Stone" or kind == "Nitrate" or kind == "Iron" then
                        local label, col = OreLabelColor(kind)
                        push(m, label, col)
                    end
                end
            end
        end
        -- 1) Workspace.Entities/IronOre и т.д.
        local entOk, ent = pcall(function() return Workspace:FindFirstChild("Entities") end)
        if entOk and ent then
            local map = {
                IronOre = { "Iron Ore", TridentSettings.Ores.ColorIron },
                NitrateOre = { "Nitrate Ore", TridentSettings.Ores.ColorNitrate },
                StoneOre = { "Stone Ore", TridentSettings.Ores.ColorStone },
                ["Iron Ore"] = { "Iron Ore", TridentSettings.Ores.ColorIron },
                ["Nitrate Ore"] = { "Nitrate Ore", TridentSettings.Ores.ColorNitrate },
                ["Stone Ore"] = { "Stone Ore", TridentSettings.Ores.ColorStone },
            }
            for folderName, info in map do
                local f = ent:FindFirstChild(folderName)
                if f then
                    for _, m in f:GetChildren() do
                        if m:IsA("Model") then push(m, info[1], info[2]) end
                    end
                end
            end
            -- loose: папки руд с любым названием внутри Entities
            do
                local keywords = { "ore", "rock", "stone", "iron", "nitra", "cobble", "node", "deposit", "mine" }
                for _, sub in ent:GetChildren() do
                    if sub:IsA("Folder") then
                        local ln = string.lower(sub.Name)
                        local hit = false
                        for _, k in keywords do if string.find(ln, k, 1, true) then hit = true break end end
                        if hit and not map[sub.Name] then
                            local fkind, fcol = OreKindFromName(sub.Name)
                            for _, m in sub:GetChildren() do
                                if m:IsA("Model") then
                                    local kind, col = OreKindFromName(m.Name)
                                    push(m, kind or fkind or "Stone Ore", col or fcol or Color3.fromRGB(200, 200, 200))
                                end
                            end
                        end
                    end
                end
            end
            -- generic: любые немаркированные модели внутри Entities (PrimaryPart не требуем)
            if #out == 0 then
                for _, d in ent:GetDescendants() do
                    if d:IsA("Model") then
                        if not d:FindFirstChild("HumanoidRootPart") and not d:FindFirstChild("Humanoid") then
                            local kind, col = OreKindFromName(d.Name)
                            local rockHit = false
                            pcall(function() rockHit = d:FindFirstChild("Meshes/rock", true) ~= nil end)
                            if kind or rockHit then
                                local ok = pcall(function() d:GetPivot() end)
                                if ok then push(d, kind or "Stone Ore", col or TridentSettings.Ores.ColorStone) end
                            end
                        end
                    end
                end
            end
        end
        -- 2) Модели с Meshes/rock (корень Workspace + папка World, любое имя, не персонажи)
        for _, ch in Workspace:GetChildren() do
            if ch:IsA("Model") and not IsCharLike(ch) then
                ClassifyRockModelInto(out, ch)
            end
        end
        do -- World: модели напрямую и на 1 уровень вглубь
            local w = nil
            pcall(function() w = Workspace:FindFirstChild("World") end)
            if w then
                pcall(function()
                    for _, ch in w:GetChildren() do
                        if ch:IsA("Model") then
                            if not IsCharLike(ch) then
                                local before = #out
                                ClassifyRockModelInto(out, ch)
                                if #out == before then
                                    local kind, col = OreKindFromName(ch.Name)
                                    if kind then push(ch, kind, col) end
                                end
                            end
                        elseif ch:IsA("Folder") then
                            for _, m in ch:GetChildren() do
                                if m:IsA("Model") and not IsCharLike(m) then
                                    local before = #out
                                    ClassifyRockModelInto(out, m)
                                    if #out == before then
                                        local kind, col = OreKindFromName(m.Name)
                                        if kind then push(m, kind, col) end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
        -- 3) Папки руд в корне Workspace (Ores/Resources/Rocks/...) + свободный поиск моделей с "rock/ore"
        do
            local keywords = { "ore", "rock", "stone", "iron", "nitra", "cobble", "node", "deposit", "mine" }
            for _, ch in Workspace:GetChildren() do
                if ch:IsA("Folder") then
                    local ln = string.lower(ch.Name)
                    local hit = false
                    for _, k in keywords do if string.find(ln, k, 1, true) then hit = true break end end
                    if hit then
                        local fkind, fcol = OreKindFromName(ch.Name)
                        for _, m in ch:GetChildren() do
                            if m:IsA("Model") then
                                local kind, col = OreKindFromName(m.Name)
                                push(m, kind or fkind or "Stone Ore", col or fcol or Color3.fromRGB(200, 200, 200))
                            end
                        end
                    end
                elseif ch:IsA("Model") and ch.Name ~= "Model" then
                    local ln = string.lower(ch.Name)
                    for _, k in { "ore", "iron", "nitra", "cobble" } do
                        if string.find(ln, k, 1, true) and not ch:FindFirstChild("HumanoidRootPart") then
                            local kind, col = OreKindFromName(ch.Name)
                            if kind then push(ch, kind, col) end
                            break
                        end
                    end
                end
            end
        end
        -- 4) POIs: мержим глубокий кэш (первый скан — асинхронно, чтобы не фризить)
        if POIScanTick < 0 then
            POIScanTick = os.clock()
            task.spawn(function() pcall(function() RescanPOIs(true) end) end)
        else
            pcall(function()
                RescanPOIs(false)
                for _, info in POIOres do
                    if info.model.Parent and not seen[info.model] then
                        seen[info.model] = true
                        table.insert(out, info)
                    end
                end
            end)
        end
        OreScanCache = out
        return out
    end

    local NPCCache = {}
    local NPCScanTick = 0
    -- игроки из сервиса + неймтег модели (метод k.mn): чья голова не подписана ником игрока — тот NPC
    local ModelSeenAt = {}
    local PlayerNamesCache = {}
    local PlayerNamesTick = 0
    local function PlayerNamesSet()
        local now = os.clock()
        if now - PlayerNamesTick < 5 and next(PlayerNamesCache) then return PlayerNamesCache end
        PlayerNamesTick = now
        local set = {}
        pcall(function()
            for _, pl in Players:GetPlayers() do set[pl.Name] = true end
        end)
        PlayerNamesCache = set
        return set
    end
    local function ModelClaimedName(m)
        local ok, txt = pcall(function()
            local head = m:FindFirstChild("Head")
            local nt = head and head:FindFirstChild("Nametag")
            local tag = nt and nt:FindFirstChild("tag")
            if tag and tag.Text ~= "" then return tag.Text end
        end)
        if ok then return txt end
    end
    local function ModelAge(m)
        local t = ModelSeenAt[m]
        if not t then
            t = os.clock()
            ModelSeenAt[m] = t
            pcall(function()
                m.AncestryChanged:Connect(function(_, p)
                    if p == nil then ModelSeenAt[m] = nil end
                end)
            end)
        end
        return os.clock() - t
    end
    local function GetNPCModels()
        local now = os.clock()
        if now - NPCScanTick < 1 and #NPCCache > 0 then return NPCCache end
        NPCScanTick = now
        local out = {}
        local entOk, ent = pcall(function() return Workspace:FindFirstChild("Entities") end)
        local function consider(m)
            if not m:IsA("Model") then return end
            if not m:FindFirstChild("HumanoidRootPart") then return end
            if not (m:FindFirstChild("Head") or m:FindFirstChild("Humanoid")) then return end
                -- исключить игроков (они в Workspace.Players)
                local inPlayers = false
                pcall(function()
                    local pf = Workspace:FindFirstChild("Players")
                    if pf and m.Parent == pf then inPlayers = true end
                end)
                if not inPlayers then
                    if m.Name ~= "Model" then
                        table.insert(out, m)
                    else
                        -- "Model" с HRP: игрок доказывается сигнатурой Player или ником из игроков
                        local provenPlayer = false
                        pcall(function()
                            if IdentifyModel(m) == "Player" then provenPlayer = true return end
                            local claimed = ModelClaimedName(m)
                            if claimed and PlayerNamesSet()[claimed] then provenPlayer = true end
                        end)
                        if not provenPlayer then table.insert(out, m) end
                    end
                end
        end
        if entOk and ent then
            for _, d in ent:GetChildren() do
                if d:IsA("Model") then consider(d)
                elseif d:IsA("Folder") then
                    for _, m in d:GetChildren() do
                        if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
                            -- папки руд пропускаем (у руд нет HRP, так что consider сам отсеет)
                            consider(m)
                        end
                    end
                end
            end
        end
        -- папки NPC с любым названием (NPC/NPCs/Animals/Mobs/Bots/...)
        do
            local keywords = { "npc", "animal", "mob", "bot", "zombie", "bandit", "mutant", "creature", "enemy", "enemies" }
            local function scanFolder(f)
                for _, m in f:GetChildren() do
                    if m:IsA("Model") then consider(m) end
                end
            end
            for _, ch in Workspace:GetChildren() do
                if ch:IsA("Folder") then
                    local ln = string.lower(ch.Name)
                    for _, k in keywords do
                        if string.find(ln, k, 1, true) then scanFolder(ch) break end
                    end
                end
            end
        end
        -- папка World: модели напрямую и на 1 уровень вглубь
        do
            local w = nil
            pcall(function() w = Workspace:FindFirstChild("World") end)
            if w then
                pcall(function()
                    for _, ch in w:GetChildren() do
                        if ch:IsA("Model") then consider(ch)
                        elseif ch:IsA("Folder") then
                            for _, m in ch:GetChildren() do consider(m) end
                        end
                    end
                end)
            end
        end
        -- fallback: корень — NPC среди "Model": у кого неймтег не из игроков (метод k.mn)
        if #out == 0 then
            local pnames = PlayerNamesSet()
            for _, m in Workspace:GetChildren() do
                if m:IsA("Model") and m ~= Client.Character then
                    if m:FindFirstChild("HumanoidRootPart") and (m:FindFirstChild("Head") or m:FindFirstChild("Humanoid")) then
                        local rockHit = false
                        pcall(function() rockHit = m:FindFirstChild("Meshes/rock", true) ~= nil end)
                        if not rockHit then
                            if m.Name ~= "Model" then
                                table.insert(out, m)
                            else
                                local claimed = ModelClaimedName(m)
                                if claimed ~= nil then
                                    if not pnames[claimed] then table.insert(out, m) end
                                elseif ModelAge(m) > 6 then
                                    table.insert(out, m) -- неймтег так и не прогрузился — не игрок
                                end
                            end
                        end
                    end
                end
            end
        end
        do -- POIs: мержим NPC-кэш (первый скан — асинхронно, чтобы не фризить кадр)
            if POIScanTick < 0 then
                POIScanTick = os.clock()
                task.spawn(function() pcall(function() RescanPOIs(true) end) end)
            else
                local seenN = {}
                for _, m in out do seenN[m] = true end
                pcall(function()
                    RescanPOIs(false)
                    for _, m in POINPCs do
                        if m.Parent and not seenN[m] then table.insert(out, m) end
                    end
                end)
            end
        end
        NPCCache = out
        return out
    end

    -- // ---------- Advanced PlayerList (PlayerClient.updatePlayers) ----------
    local AdvancedList = nil
    local AdvancedTried = false
    local function TryAdvanced()
        if AdvancedTried then return AdvancedList end
        AdvancedTried = true
        local ok, res = pcall(function()
            if typeof(getgc) ~= "function" then return nil end
            if typeof(debug) ~= "table" then return nil end
            if typeof(debug.getupvalue) ~= "function" then return nil end
            if typeof(debug.getinfo) ~= "function" then return nil end
            if typeof(islclosure) ~= "function" then return nil end
            for _, v in pairs(getgc(true)) do
                if typeof(v) == "function" and islclosure(v) then
                    local inf = debug.getinfo(v)
                    if inf and inf.short_src and inf.name == "updatePlayers" then
                        local src = tostring(inf.short_src)
                        if string.find(src, "PlayerClient") then
                            local uv = debug.getupvalue(v, 1)
                            if type(uv) == "table" then return uv end
                        end
                    end
                end
            end
            return nil
        end)
        if ok and type(res) == "table" then
            AdvancedList = res
        end
        return AdvancedList
    end
    task.spawn(function()
        task.wait(3)
        pcall(TryAdvanced)
    end)

    -- // ---------- Fake tables для workspace-режима (чтобы использовать espLibrary) ----------
    local FakePlayerByModel = {}
    local FakeOreByModel = {}
    local FakeNPCByModel = {}
    local function GetFakePlayer(model)
        local f = FakePlayerByModel[model]
        if not f then
            f = { model = model, sleeping = false, equippedItem = { type = "none", amt = 1 } }
            FakePlayerByModel[model] = f
            pcall(function()
                model.AncestryChanged:Connect(function(_, parent)
                    if parent == nil then FakePlayerByModel[model] = nil end
                end)
            end)
        end
        f.sleeping = IsSleepingModel(model)
        local wn = GetWeaponName(model)
        if type(f.equippedItem) ~= "table" then f.equippedItem = { type = "none", amt = 1 } end
        f.equippedItem.type = wn
        f.equippedItem.amt = 1
        return f
    end
    local function GetFakeOre(model, oreName)
        local f = FakeOreByModel[model]
        if not f then
            f = { model = model, type = oreName }
            FakeOreByModel[model] = f
            pcall(function()
                model.AncestryChanged:Connect(function(_, parent)
                    if parent == nil then FakeOreByModel[model] = nil end
                end)
            end)
        end
        f.type = oreName
        return f
    end
    local function GetFakeNPC(model)
        local f = FakeNPCByModel[model]
        if not f then
            f = { model = model, type = model.Name }
            FakeNPCByModel[model] = f
            pcall(function()
                model.AncestryChanged:Connect(function(_, parent)
                    if parent == nil then FakeNPCByModel[model] = nil end
                end)
            end)
        end
        return f
    end

    -- // ---------- Backpacks (лут после смерти) : corpse/bag-модели в корне Workspace ----------
    local FakeBackpackByModel = {}
    local function GetFakeBackpack(model, label)
        local f = FakeBackpackByModel[model]
        if not f then
            f = { model = model, type = label or "Backpack" }
            FakeBackpackByModel[model] = f
            pcall(function()
                model.AncestryChanged:Connect(function(_, parent)
                    if parent == nil then FakeBackpackByModel[model] = nil end
                end)
            end)
        end
        f.type = label or "Backpack"
        return f
    end
    local BackpackScanCache = {}
    local BackpackScanTick = 0
    local function GetBackpackModels()
        local now = os.clock()
        if now - BackpackScanTick < 1 and #BackpackScanCache > 0 then return BackpackScanCache end
        BackpackScanTick = now
        local out = {}
        local function consider(m)
            if not m:IsA("Model") then return end
            if not m.Parent then return end
            if m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Humanoid") then return end
            if m:FindFirstChild("Meshes/rock", true) then return end
            do -- точная сигнатура Backpack из шаблонов игры
                local signame = IdentifyModel(m)
                if signame == "Backpack" then
                    local ok = pcall(function() m:GetPivot() end)
                    if ok then table.insert(out, m) end
                    return
                end
            end
            local nm = string.lower(m.Name)
            -- двери/ворота — никогда не рюкзаки
            for _, w in { "door", "gate", "hatch", "shutter", "doorway", "entrance" } do
                if string.find(nm, w, 1, true) then return end
            end
            -- сигнал трупа из k.mn-скриптов: UnionOperation цвета 205,205,205
            local hasUnion205 = false
            pcall(function()
                for _, u in m:GetDescendants() do
                    if u:IsA("UnionOperation") and u.Color == Color3.fromRGB(205, 205, 205) then
                        hasUnion205 = true break
                    end
                end
            end)
            local nameHit = string.find(nm, "bag", 1, true) or string.find(nm, "backpack", 1, true)
                or string.find(nm, "corpse", 1, true) or string.find(nm, "body", 1, true)
                or string.find(nm, "loot", 1, true) or string.find(nm, "death", 1, true)
                or string.find(nm, "pouch", 1, true) or string.find(nm, "sack", 1, true)
            if hasUnion205 or nameHit then
                local ok = pcall(function() m:GetPivot() end)
                if ok then table.insert(out, m) end
            end
        end
        pcall(function()
            for _, ch in Workspace:GetChildren() do
                if ch:IsA("Model") then consider(ch) end
            end
        end)
        BackpackScanCache = out
        return out
    end

    -- // ---------- Руды-части (если руда это Part/MeshPart, а не Model) ----------
    local OrePartScanCache = {}
    local OrePartScanTick = 0
    local function ScanOreParts()
        local now = os.clock()
        if now - OrePartScanTick < 1 and #OrePartScanCache > 0 then return OrePartScanCache end
        OrePartScanTick = now
        local out = {}
        local function consider(p)
            if not p.Parent then return end
            local kind, col = OreKindFromName(p.Name)
            if kind then table.insert(out, { part = p, oreName = kind, color = col }) end
        end
        pcall(function()
            for _, ch in Workspace:GetChildren() do
                if ch:IsA("BasePart") then consider(ch) end
            end
            local ent = Workspace:FindFirstChild("Entities")
            if ent then
                for _, d in ent:GetDescendants() do
                    if d:IsA("BasePart") then
                        local par = d.Parent
                        if not (par and par:IsA("Model")) then consider(d) end
                    end
                end
            end
        end)
        OrePartScanCache = out
        return out
    end
    local PartTextPool = {}
    local function HideAllPartTexts()
        for _, t in PartTextPool do pcall(function() t.Visible = false end) end
    end
    local function ShowPartText(part, label, color)
        local t = PartTextPool[part]
        if not t or not pcall(function() t.Visible = t.Visible end) then
            local ok, nt = pcall(function()
                local x = Drawing.new("Text")
                x.Visible = false x.Center = true x.Outline = true
                x.OutlineColor = Color3.new(0, 0, 0)
                x.Size = 13 x.Font = 1 x.ZIndex = 1
                return x
            end)
            if not (ok and nt) then return end
            t = nt PartTextPool[part] = t
            pcall(function()
                part.AncestryChanged:Connect(function(_, p)
                    if p == nil then
                        local tt = PartTextPool[part]
                        if tt then pcall(function() tt:Remove() end) end
                        PartTextPool[part] = nil
                    end
                end)
            end)
        end
        local pos, onscreen = nil, false
        pcall(function() pos, onscreen = Camera:WorldToViewportPoint(part.Position) end)
        if not onscreen or not pos then t.Visible = false return end
        t.Visible = true t.Text = label t.Color = color
        t.Position = Vector2.new(pos.X, pos.Y)
    end

    -- // ---------- Chams (Highlight с заливкой, работает и на lvl7) ----------
    local ChamsCache = {}
    local ChamsFolder = nil
    local function GetChamsFolder()
        if ChamsFolder and ChamsFolder.Parent then return ChamsFolder end
        pcall(function()
            ChamsFolder = CoreGui:FindFirstChild("TridentESP_HL")
            if not ChamsFolder then
                ChamsFolder = Instance.new("Folder")
                ChamsFolder.Name = "TridentESP_HL"
                ChamsFolder.Parent = CoreGui
            end
        end)
        return ChamsFolder
    end
    local function SetChams(model, color, fillTrans, enabled)
        local folder = GetChamsFolder()
        if not folder then return end
        local hl = ChamsCache[model]
        if not enabled then
            if hl then pcall(function() hl.Enabled = false end) end
            return
        end
        if not hl or not hl.Parent then
            local ok, n = pcall(function()
                local h = Instance.new("Highlight")
                h.Name = "_TridentESP_Chams"
                h.Adornee = model
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = folder
                return h
            end)
            if ok and n then hl = n ChamsCache[model] = hl
                pcall(function()
                    model.AncestryChanged:Connect(function(_, p)
                        if p == nil and ChamsCache[model] then
                            pcall(function() ChamsCache[model]:Destroy() end)
                            ChamsCache[model] = nil
                        end
                    end)
                end)
            else return end
        end
        pcall(function()
            hl.Enabled = true hl.Adornee = model
            hl.FillColor = color hl.OutlineColor = color
            hl.FillTransparency = fillTrans hl.OutlineTransparency = 0
        end)
    end
    local function ClearAllChams()
        for _, h in ChamsCache do pcall(function() h.Enabled = false end) end
    end

    -- // ---------- Skeleton (Drawing Lines, только если Drawing жив) ----------
    local SkeletonPools = {}
    local function HideSkeleton(model)
        local pool = SkeletonPools[model]
        if pool then for _, l in pool.lines do pcall(function() l.Visible = false end) end end
    end
    local function HideAllSkeletons()
        for m, _ in SkeletonPools do HideSkeleton(m) end
    end
    local function HideExtraESP()
        HideAllSkeletons()
        HideAllPartTexts()
        pcall(function()
            if espLib then
                for _, e in pairs(espLib.entityESP.entityCache) do
                    local m = rawget(e.entity, "model")
                    if m and FakeBackpackByModel[m] then e:hideDrawings() end
                end
            end
        end)
    end
    local function DrawSkeleton(model, color)
        local pool = SkeletonPools[model]
        if not pool then
            pool = { lines = {} }
            SkeletonPools[model] = pool
            pcall(function()
                model.AncestryChanged:Connect(function(_, p)
                    if p == nil then
                        local pl = SkeletonPools[model]
                        if pl then for _, l in pl.lines do pcall(function() l:Remove() end) end end
                        SkeletonPools[model] = nil
                    end
                end)
            end)
        end
        local function P(n)
            local ok, p = pcall(function() return model:FindFirstChild(n) end)
            if ok then return p end
        end
        local pairs = {}
        local head, hrp = P("Head"), P("HumanoidRootPart")
        local torso = P("Torso") or P("UpperTorso")
        local low = P("LowerTorso")
        if head and torso then
            -- Trident R15: LeftUpperArm/LeftLowerArm/LeftHand ... (порядок SwimHub)
            local ual, lal, hal = P("LeftUpperArm"), P("LeftLowerArm"), P("LeftHand")
            local uar, lar, har = P("RightUpperArm"), P("RightLowerArm"), P("RightHand")
            local ull, lll, fl = P("LeftUpperLeg"), P("LeftLowerLeg"), P("LeftFoot")
            local ulr, llr, fr = P("RightUpperLeg"), P("RightLowerLeg"), P("RightFoot")
            local legRoot = low or torso
            pairs = {
                { head, torso },
                { torso, low },
                { torso, ual }, { ual, lal }, { lal, hal },
                { torso, uar }, { uar, lar }, { lar, har },
                { legRoot, ull }, { ull, lll }, { lll, fl },
                { legRoot, ulr }, { ulr, llr }, { llr, fr },
            }
        else
            local torso = P("Torso")
            if head and torso then
                pairs = {
                    { head, torso },
                    { torso, P("Left Arm") }, { torso, P("Right Arm") },
                    { torso, P("Left Leg") }, { torso, P("Right Leg") },
                }
            elseif head and hrp then
                pairs = { { head, hrp } }
            else
                HideSkeleton(model)
                return
            end
        end
        local want = 0
        for _, pr in pairs do if pr[1] and pr[2] then want += 1 end end
        while #pool.lines < want do
            local ok, ln = pcall(function()
                local l = Drawing.new("Line")
                l.Visible = false l.Thickness = 1 l.Transparency = 1 l.ZIndex = 2
                return l
            end)
            if ok and ln then table.insert(pool.lines, ln) else break end
        end
        local i = 0
        for _, pr in pairs do
            local a, b = pr[1], pr[2]
            if a and b then
                i += 1
                local ln = pool.lines[i]
                if ln then
                    local ok, ax, ay, ao, bx, by, bo = pcall(function()
                        local A, Aon = Camera:WorldToViewportPoint(a.Position)
                        local B, Bon = Camera:WorldToViewportPoint(b.Position)
                        return A.X, A.Y, Aon, B.X, B.Y, Bon
                    end)
                    if ok and (ao or bo) then
                        pcall(function()
                            ln.Visible = true ln.Color = color
                            ln.From = Vector2.new(ax, ay) ln.To = Vector2.new(bx, by)
                        end)
                    else
                        pcall(function() ln.Visible = false end)
                    end
                end
            end
        end
        for j = i + 1, #pool.lines do pcall(function() pool.lines[j].Visible = false end) end
    end

    -- // ---------- Highlight fallback (lvl7 без Drawing) ----------
    local HLFolder = nil
    pcall(function()
        HLFolder = CoreGui:FindFirstChild("TridentESP_HL")
        if not HLFolder then
            HLFolder = Instance.new("Folder")
            HLFolder.Name = "TridentESP_HL"
            HLFolder.Parent = CoreGui
        end
    end)
    local HLCache = {}
    local function SetHighlight(model, color, enabled)
        if not HLFolder then return end
        local hl = HLCache[model]
        if not enabled then
            if hl then hl.Enabled = false end
            return
        end
        if not hl or not hl.Parent then
            local ok, n = pcall(function()
                local h = Instance.new("Highlight")
                h.Name = "_TridentESP_HL"
                h.Adornee = model
                h.FillTransparency = 1
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = HLFolder
                return h
            end)
            if ok and n then hl = n HLCache[model] = hl
                pcall(function()
                    model.AncestryChanged:Connect(function(_, p)
                        if p == nil and HLCache[model] then
                            pcall(function() HLCache[model]:Destroy() end)
                            HLCache[model] = nil
                        end
                    end)
                end)
            else return end
        end
        hl.Enabled = true
        hl.OutlineColor = color
        hl.Adornee = model
    end
    local function ClearAllHighlights()
        for m, h in HLCache do
            pcall(function() h.Enabled = false end)
        end
    end
    -- // ---------- World highlights (руды/NPC/рюкзаки когда нет Drawing) ----------
    local WorldHLCache = {}
    local function SetWorldHighlight(obj, color, enabled)
        if not HLFolder then return end
        local hl = WorldHLCache[obj]
        if not enabled then
            if hl then pcall(function() hl.Enabled = false end) end
            return
        end
        if not hl or not hl.Parent then
            local ok, n = pcall(function()
                local h = Instance.new("Highlight")
                h.Name = "_TridentESP_World"
                h.Adornee = obj
                h.FillTransparency = 1
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = HLFolder
                return h
            end)
            if ok and n then hl = n WorldHLCache[obj] = hl
                pcall(function()
                    if typeof(obj) == "Instance" then
                        obj.AncestryChanged:Connect(function(_, p)
                            if p == nil and WorldHLCache[obj] then
                                pcall(function() WorldHLCache[obj]:Destroy() end)
                                WorldHLCache[obj] = nil
                            end
                        end)
                    end
                end)
            else return end
        end
        pcall(function() hl.Enabled = true hl.Adornee = obj hl.OutlineColor = color end)
    end
    local function SweepWorldHighlights(seen)
        for obj, hl in WorldHLCache do
            if not seen[obj] then pcall(function() hl.Enabled = false end) end
        end
    end

    local function HideAllESP()
        if espLib then
            pcall(function()
                for _, e in pairs(espLib.playerESP.playerCache) do e:hideDrawings() end
            end)
            pcall(function()
                for _, e in pairs(espLib.entityESP.entityCache) do e:hideDrawings() end
            end)
            pcall(function()
                for _, e in pairs(espLib.npcESP.npcCache) do e:hideDrawings() end
            end)
        end
        ClearAllHighlights()
        pcall(HideExtraESP)
        pcall(ClearAllChams)
    end
    getgenv().TridentHideESP = HideAllESP

    -- полный снос всех Drawing/highlight/кэшей (для кнопки Unload)
    local function NukeDrawings()
        pcall(function()
            if espLib then
                local groups = {
                    espLib.playerESP.playerCache, espLib.entityESP.entityCache, espLib.npcESP.npcCache,
                    espLib.playerESP.drawingCache, espLib.entityESP.drawingCache, espLib.npcESP.drawingCache,
                }
                for _, g in pairs(groups) do
                    for _, e in pairs(g) do
                        local ds = e and (e.allDrawings or e.all)
                        if ds then
                            if ds.Visible ~= nil then pcall(function() ds:Remove() end)
                            else for _, d in pairs(ds) do pcall(function() d:Remove() end) end end
                        end
                    end
                end
                espLib.playerESP.playerCache = {}
                espLib.entityESP.entityCache = {}
                espLib.npcESP.npcCache = {}
            end
        end)
        pcall(function()
            for _, pl in pairs(SkeletonPools) do for _, l in pairs(pl.lines) do pcall(function() l:Remove() end) end end
        end)
        pcall(function() for _, t in pairs(PartTextPool) do pcall(function() t:Remove() end) end end)
        pcall(function()
            for _, c in pairs(POIConns) do pcall(function() c:Disconnect() end) end
        end)
    end

    -- wrap Unload: гасим флаги, СНОСИМ всё, чистим кэши, потом штатный Unload
    do
        local oldUnload = Library.Unload
        function Library:Unload(...)
            pcall(function()
                TridentSettings.Players.Enabled = false
                TridentSettings.Players.Chams = false
                TridentSettings.Players.Skeleton = false
                TridentSettings.Ores.Enabled = false
                TridentSettings.NPC.Enabled = false
                TridentSettings.Backpacks.Enabled = false
            end)
            pcall(NukeDrawings)
            pcall(function()
                SkeletonPools = {}
                PartTextPool = {}
                FakePlayerByModel = {}
                FakeOreByModel = {}
                FakeNPCByModel = {}
                FakeBackpackByModel = {}
                ChamsCache = {}
                HLCache = {}
                WorldHLCache = {}
                OreScanCache = {}
                OrePartScanCache = {}
                BackpackScanCache = {}
                NPCCache = {}
                POIOres = {}
                POINPCs = {}
                POISeen = {}
                POIConns = {}
                OreScanTick = 0
                OrePartScanTick = 0
                BackpackScanTick = 0
                NPCScanTick = 0
                POIScanTick = -100
                POIConnected = false
                AdvancedList = nil
                AdvancedTried = false
                ModelSeenAt = {}
                PlayerNamesCache = {}
                PlayerNamesTick = 0
            end)
            pcall(function()
                if HLFolder then HLFolder:Destroy() end
            end)
            pcall(function() return oldUnload(self, ...) end)
            getgenv().TridentESPLib = nil
            getgenv().TridentSettings = nil
            getgenv().Library = nil
        end
        function Library:Disable(...)
            TridentSettings.Players.Enabled = false
            TridentSettings.Ores.Enabled = false
            TridentSettings.NPC.Enabled = false
            TridentSettings.Backpacks.Enabled = false
            TridentSettings.Players.Chams = false
            TridentSettings.Players.Skeleton = false
            pcall(HideAllESP)
            for _, flag in pairs(Library.Flags) do
                if type(flag) == "table" and flag.Set then
                    pcall(function() flag:Set(false) end)
                end
            end
        end
    end

    -- // ================= UI =================
    local PlayersSec = VisualsSubSection:Section({Name = "Players — Trident", Fill = true})
    local OresSec = VisualsSubSection:Section({Name = "Ores / World", Side = "Right", Fill = true})

    local NPCSec = VisualsSubSection2:Section({Name = "NPC / Animals", Fill = true})
    local MiscSec = VisualsSubSection2:Section({Name = "Status / Fix", Side = "Right", Fill = true})

    -- ----- Players UI -----
    PlayersSec:Toggle({Name = "Enable Player ESP", Flag = "ESP_PlayersEnabled", Default = false, Callback = function(s)
        TridentSettings.Players.Enabled = s
        if not s then
            pcall(function()
                for _, e in pairs(espLib.playerESP.playerCache) do e:hideDrawings() end
            end)
            ClearAllHighlights()
        end
    end}):ColorPicker({Name = "Player color", Default = TridentSettings.Players.Color, Flag = "ESP_PlayerColor", Callback = function(c)
        TridentSettings.Players.Color = c
    end})
    PlayersSec:Toggle({Name = "Box", Flag = "ESP_PlayersBox", Default = true, Callback = function(s) TridentSettings.Players.Box = s end})
    PlayersSec:Toggle({Name = "Name (player/sleeper)", Flag = "ESP_PlayersName", Default = true, Callback = function(s) TridentSettings.Players.Name = s end})
    PlayersSec:Toggle({Name = "Distance [m]", Flag = "ESP_PlayersDist", Default = true, Callback = function(s) TridentSettings.Players.Distance = s end})
    PlayersSec:Toggle({Name = "Weapon", Flag = "ESP_PlayersWeapon", Default = true, Callback = function(s) TridentSettings.Players.Weapon = s end})
    PlayersSec:Toggle({Name = "Show sleepers", Flag = "ESP_ShowSleepers", Default = false, Callback = function(s) TridentSettings.Players.ShowSleepers = s end})
    PlayersSec:Toggle({Name = "Show local player", Flag = "ESP_ShowLocal", Default = false, Callback = function(s) TridentSettings.Players.ShowLocal = s end})
    PlayersSec:Slider({Name = "Max distance", Flag = "ESP_PlayersMaxDist", Min = 100, Max = 5000, Default = 1500, Decimal = 10, Ending = "m", Callback = function(v) TridentSettings.Players.MaxDistance = v end})
    PlayersSec:Label({Message = "Sleeper color"}):ColorPicker({Default = TridentSettings.Players.SleeperColor, Flag = "ESP_SleeperColor", Callback = function(c)
        TridentSettings.Players.SleeperColor = c
    end})
    PlayersSec:Toggle({Name = "Chams (Highlight)", Flag = "ESP_PlayersChams", Default = false, Callback = function(s)
        TridentSettings.Players.Chams = s
        if not s then pcall(ClearAllChams) end
    end}):ColorPicker({Default = TridentSettings.Players.ChamsColor, Flag = "ESP_PlayersChamsCol", Callback = function(c)
        TridentSettings.Players.ChamsColor = c
    end})
    PlayersSec:Toggle({Name = "Skeleton (Lines)", Flag = "ESP_PlayersSkeleton", Default = false, Callback = function(s)
        TridentSettings.Players.Skeleton = s
        if not s then pcall(HideAllSkeletons) end
    end}):ColorPicker({Default = TridentSettings.Players.SkeletonColor, Flag = "ESP_PlayersSkeletonCol", Callback = function(c)
        TridentSettings.Players.SkeletonColor = c
    end})

    -- ----- Ores UI -----
    OresSec:Toggle({Name = "Enable Ore ESP", Flag = "ESP_OresEnabled", Default = false, Callback = function(s)
        TridentSettings.Ores.Enabled = s
        if s then task.spawn(function() pcall(function() RescanPOIs(true) end) end) end
        if s then task.delay(7, function()
            if not TridentSettings.Ores.Enabled then return end
            local n = 0
            pcall(function() n = #ScanOres() end)
            Library:Notify({Message = "Руд найдено: " .. tostring(n), Delay = 4})
        end) end
        if not s and espLib then
            pcall(function()
                for _, e in pairs(espLib.entityESP.entityCache) do e:hideDrawings() end
            end)
        end
    end})
    OresSec:Toggle({Name = "Box", Flag = "ESP_OresBox", Default = true, Callback = function(s) TridentSettings.Ores.Box = s end})
    OresSec:Toggle({Name = "Name", Flag = "ESP_OresName", Default = true, Callback = function(s) TridentSettings.Ores.Name = s end})
    OresSec:Toggle({Name = "Distance", Flag = "ESP_OresDist", Default = true, Callback = function(s) TridentSettings.Ores.Distance = s end})
    OresSec:Toggle({Name = "Iron Ore", Flag = "ESP_OreIron", Default = true, Callback = function(s) TridentSettings.Ores.Iron = s end}):ColorPicker({Default = TridentSettings.Ores.ColorIron, Flag = "ESP_OreIronCol", Callback = function(c) TridentSettings.Ores.ColorIron = c end})
    OresSec:Toggle({Name = "Nitrate Ore", Flag = "ESP_OreNitrate", Default = true, Callback = function(s) TridentSettings.Ores.Nitrate = s end}):ColorPicker({Default = TridentSettings.Ores.ColorNitrate, Flag = "ESP_OreNitrateCol", Callback = function(c) TridentSettings.Ores.ColorNitrate = c end})
    OresSec:Toggle({Name = "Stone Ore", Flag = "ESP_OreStone", Default = true, Callback = function(s) TridentSettings.Ores.Stone = s end}):ColorPicker({Default = TridentSettings.Ores.ColorStone, Flag = "ESP_OreStoneCol", Callback = function(c) TridentSettings.Ores.ColorStone = c end})
    OresSec:Slider({Name = "Max distance", Flag = "ESP_OresMaxDist", Min = 100, Max = 5000, Default = 1200, Decimal = 10, Ending = "m", Callback = function(v) TridentSettings.Ores.MaxDistance = v end})
    OresSec:Label({Message = "Backpacks (лут после смерти)"})
    OresSec:Toggle({Name = "Enable Backpack ESP", Flag = "ESP_BackpacksEnabled", Default = false, Callback = function(s)
        TridentSettings.Backpacks.Enabled = s
        if s then task.delay(4, function()
            if not TridentSettings.Backpacks.Enabled then return end
            local n = 0
            pcall(function() n = #GetBackpackModels() end)
            Library:Notify({Message = "Рюкзаков найдено: " .. tostring(n), Delay = 4})
        end) end
        if not s and espLib then
            pcall(function()
                for _, e in pairs(espLib.entityESP.entityCache) do
                    local m = rawget(e.entity, "model")
                    if m and FakeBackpackByModel[m] then e:hideDrawings() end
                end
            end)
        end
    end}):ColorPicker({Default = TridentSettings.Backpacks.Color, Flag = "ESP_BackpacksCol", Callback = function(c)
        TridentSettings.Backpacks.Color = c
    end})
    OresSec:Slider({Name = "Backpack max dist", Flag = "ESP_BackpacksMaxDist", Min = 100, Max = 5000, Default = 1200, Decimal = 10, Ending = "m", Callback = function(v) TridentSettings.Backpacks.MaxDistance = v end})

    -- ----- NPC UI -----
    NPCSec:Toggle({Name = "Enable NPC ESP", Flag = "ESP_NPCEnabled", Default = false, Callback = function(s)
        TridentSettings.NPC.Enabled = s
        if s then task.spawn(function() pcall(function() RescanPOIs(true) end) end) end
        if s then task.delay(7, function()
            if not TridentSettings.NPC.Enabled then return end
            local n = 0
            pcall(function() n = #GetNPCModels() end)
            Library:Notify({Message = "NPC найдено: " .. tostring(n), Delay = 4})
        end) end
        if not s and espLib then
            pcall(function()
                for _, e in pairs(espLib.npcESP.npcCache) do e:hideDrawings() end
            end)
        end
    end}):ColorPicker({Default = TridentSettings.NPC.Color, Flag = "ESP_NPCColor", Callback = function(c) TridentSettings.NPC.Color = c end})
    NPCSec:Toggle({Name = "Box", Flag = "ESP_NPCBox", Default = true, Callback = function(s) TridentSettings.NPC.Box = s end})
    NPCSec:Toggle({Name = "Name", Flag = "ESP_NPCName", Default = true, Callback = function(s) TridentSettings.NPC.Name = s end})
    NPCSec:Toggle({Name = "Distance", Flag = "ESP_NPCDist", Default = true, Callback = function(s) TridentSettings.NPC.Distance = s end})
    NPCSec:Slider({Name = "Max distance", Flag = "ESP_NPCMaxDist", Min = 100, Max = 5000, Default = 1200, Decimal = 10, Ending = "m", Callback = function(v) TridentSettings.NPC.MaxDistance = v end})

    -- ----- Misc / Status -----
    local StatusLabel = MiscSec:Label({Message = "Mode: ..."})
    MiscSec:Toggle({Name = "Highlight fallback (no Drawing)", Flag = "ESP_HLfallback", Default = true, Callback = function(s) TridentSettings.Misc.UseHighlightFallback = s end})
    MiscSec:Button({Name = "Re-scan PlayerClient", Callback = function()
        AdvancedTried = false
        local l = TryAdvanced()
        if l then
            Library:Notify({Message = "Trident ESP: PlayerClient найден (" .. tostring(#l) .. " записей)", Delay = 3})
        else
            Library:Notify({Message = "Trident ESP: PlayerClient не найден, Workspace-режим", Delay = 3})
        end
    end})
    MiscSec:Button({Name = "Clear ESP", Callback = function()
        HideAllESP()
    end})
    MiscSec:Button({Name = "Scan map (debug)", Callback = function()
        local lines = {}
        local function add(s) table.insert(lines, s) end
        pcall(function()
            add("== workspace children (" .. tostring(#Workspace:GetChildren()) .. ") ==")
            for _, ch in Workspace:GetChildren() do
                local extra = ""
                pcall(function()
                    if ch:IsA("Folder") then extra = " [" .. tostring(#ch:GetChildren()) .. " kids]" end
                end)
                add(ch.ClassName .. " | " .. ch.Name .. extra)
            end
        end)
        pcall(function()
            local ent = Workspace:FindFirstChild("Entities")
            if ent then
                add("== Entities children ==")
                for _, ch in ent:GetChildren() do
                    add(ch.ClassName .. " | Entities/" .. ch.Name)
                end
            else
                add("== Entities: MISSING ==")
            end
        end)
        pcall(function()
            local pf = Workspace:FindFirstChild("Players")
            if pf then
                local names = {}
                for _, m in pf:GetChildren() do table.insert(names, m.Name) end
                add("== Players(" .. tostring(#names) .. "): " .. table.concat(names, ", ") .. " ==")
            else
                add("== Players folder: MISSING ==")
            end
        end)
        pcall(function()
            BuildEntitySig()
            local names = {}
            for n, _ in EntitySig do table.insert(names, n) end
            table.sort(names)
            add("== RS entity templates(" .. tostring(#names) .. "): " .. table.concat(names, ", ") .. " ==")
        end)
        local function sample(title, list, fmt)
            add("== " .. title .. ": " .. tostring(#list) .. " ==")
            for i = 1, math.min(#list, 12) do
                local ok, s = pcall(fmt, list[i])
                if ok then add("  " .. s) end
            end
        end
        pcall(function()
            sample("ores", ScanOres(), function(info) return info.oreName .. " | " .. info.model:GetFullName() end)
        end)
        pcall(function()
            sample("oreParts", ScanOreParts(), function(pi) return pi.oreName .. " | " .. pi.part:GetFullName() end)
        end)
        pcall(function()
            sample("npc", GetNPCModels(), function(m) return m:GetFullName() end)
        end)
        pcall(function()
            sample("backpacks", GetBackpackModels(), function(m)
                local u = m:FindFirstChildWhichIsA("UnionOperation", true)
                return m.Name .. " | union=" .. tostring(u and u.Color) .. " | " .. m:GetFullName()
            end)
        end)
        pcall(function()
            add("== World folder ==")
            local w = Workspace:FindFirstChild("World")
            if w then
                for _, ch in w:GetChildren() do add(ch.ClassName .. " | World/" .. ch.Name) end
            else add("World: MISSING") end
            add("== Const folder ==")
            local c = Workspace:FindFirstChild("Const")
            if c then
                for _, ch in c:GetChildren() do add(ch.ClassName .. " | Const/" .. ch.Name) end
            end
        end)
        pcall(function()
            local cats = { rock = {}, union = {}, hrp = {}, other = {} }
            local counts = { rock = 0, union = 0, hrp = 0, other = 0 }
            for _, m in Workspace:GetChildren() do
                if m:IsA("Model") then
                    local hasHRP, hasRock, hasU = false, false, false
                    pcall(function()
                        hasHRP = m:FindFirstChild("HumanoidRootPart") ~= nil
                        hasRock = m:FindFirstChild("Meshes/rock", true) ~= nil
                        hasU = m:FindFirstChildWhichIsA("UnionOperation", true) ~= nil
                    end)
                    local cat = hasHRP and "hrp" or (hasRock and "rock" or (hasU and "union" or "other"))
                    counts[cat] += 1
                    if #cats[cat] < 6 then table.insert(cats[cat], m) end
                end
            end
            add(("== root cats: hrp=%d rock=%d union=%d other=%d =="):format(counts.hrp, counts.rock, counts.union, counts.other))
            for cat, list in cats do
                for _, m in list do
                    local kids = {}
                    pcall(function()
                        for _, k in m:GetChildren() do
                            local extra = ""
                            if k:IsA("MeshPart") then extra = "#BC" .. tostring(k.BrickColor.Number) end
                            if k:IsA("UnionOperation") then extra = "#U" .. tostring(math.floor(k.Color.R * 255)) end
                            table.insert(kids, k.Name .. "(" .. k.ClassName .. extra .. ")")
                            if #kids >= 10 then table.insert(kids, "...") break end
                        end
                    end)
                    local prompt = ""
                    pcall(function() if m:FindFirstChildWhichIsA("ProximityPrompt", true) then prompt = " PROMPT" end end)
                    add("[" .. cat .. "] " .. m.Name .. prompt .. " kids: " .. table.concat(kids, ", "))
                end
            end
            add("== root HRP nametag audit ==")
            do
                local pnames = PlayerNamesSet()
                local shown, total = 0, 0
                for _, m in Workspace:GetChildren() do
                    if m:IsA("Model") and m:FindFirstChild("HumanoidRootPart") then
                        total += 1
                        if shown < 25 then
                            shown += 1
                            local claimed = ModelClaimedName(m) or "<none>"
                            local isP = pnames[claimed] and "PLAYER" or "???"
                            local sig = IdentifyModel(m) or "-"
                            add("  " .. m.Name .. " nametag=" .. tostring(claimed) .. " " .. isP .. " sig=" .. tostring(sig) .. " age=" .. tostring(math.floor(ModelAge(m))))
                        end
                    end
                end
                add("hrp total: " .. tostring(total))
            end
            add("== World/POIs ==")
            pcall(function()
                local pois = Workspace:FindFirstChild("World")
                pois = pois and pois:FindFirstChild("POIs")
                if pois then
                    for _, ch in pois:GetChildren() do
                        if ch:IsA("Folder") then
                            add("Folder | POIs/" .. ch.Name .. " [" .. tostring(#ch:GetChildren()) .. " kids]")
                        else
                            add(ch.ClassName .. " | POIs/" .. ch.Name)
                        end
                    end
                else add("POIs: MISSING") end
            end)
            add("== World/Decoration (first 15) ==")
            pcall(function()
                local dec = Workspace:FindFirstChild("World")
                dec = dec and dec:FindFirstChild("Decoration")
                if dec then
                    local n = 0
                    for _, ch in dec:GetChildren() do
                        n += 1
                        if n <= 15 then add(ch.ClassName .. " | Decoration/" .. ch.Name) end
                    end
                    add("decoration total: " .. tostring(n))
                else add("Decoration: MISSING") end
            end)
            add("== Const/Ignore + Objects ==")
            pcall(function()
                local ig = Workspace:FindFirstChild("Const")
                ig = ig and ig:FindFirstChild("Ignore")
                if ig then for _, ch in ig:GetChildren() do add(ch.ClassName .. " | Ignore/" .. ch.Name) end end
                local ob = Workspace:FindFirstChild("Const")
                ob = ob and ob:FindFirstChild("Objects")
                if ob then
                    local n = 0
                    for _, ch in ob:GetChildren() do
                        n += 1
                        if n <= 15 then add(ch.ClassName .. " | Objects/" .. ch.Name) end
                    end
                    add("objects total: " .. tostring(n))
                end
            end)
            add("== [other] full dump x3 ==")
            pcall(function()
                local n = 0
                for _, m in Workspace:GetChildren() do
                    if m:IsA("Model") and m.Name == "Model" then
                        local isOther = false
                        pcall(function()
                            isOther = m:FindFirstChild("HumanoidRootPart") == nil
                                and m:FindFirstChild("Meshes/rock", true) == nil
                                and m:FindFirstChildWhichIsA("UnionOperation", true) == nil
                        end)
                        if isOther then
                            n += 1
                            if n <= 3 then
                                add("-- " .. m:GetFullName())
                                for _, d in m:GetDescendants() do
                                    local extra = ""
                                    if d:IsA("BasePart") then
                                        extra = " size=" .. tostring(d.Size) .. " col=" .. tostring(math.floor(d.Color.R * 255)) .. "," .. tostring(math.floor(d.Color.G * 255)) .. "," .. tostring(math.floor(d.Color.B * 255))
                                    end
                                    add("   " .. d.ClassName .. " | " .. d.Name .. extra)
                                end
                            end
                        end
                    end
                end
                add("other-like total: " .. tostring(n))
            end)
        end)
        pcall(function()
            add("== Trading Post dump (first 120) ==")
            local tp = Workspace:FindFirstChild("World")
            tp = tp and tp:FindFirstChild("POIs")
            tp = tp and tp:FindFirstChild("Trading Post")
            if tp then
                local n = 0
                for _, d in tp:GetDescendants() do
                    n += 1
                    if n <= 120 then
                        local extra = ""
                        if d:IsA("BasePart") then extra = " size=" .. tostring(d.Size) end
                        add("  " .. d.ClassName .. " | " .. d.Name .. extra)
                    end
                end
                add("tradingpost total: " .. tostring(n))
            else add("Trading Post: MISSING") end
        end)
        pcall(function()
            add("== POI Humanoid search ==")
            local w = Workspace:FindFirstChild("World")
            local pois = w and w:FindFirstChild("POIs")
            if pois then
                local n = 0
                for _, d in pois:GetDescendants() do
                    if d:IsA("Humanoid") then
                        n += 1
                        if n <= 20 then
                            local m = d:FindFirstAncestorOfClass("Model")
                            add("  Humanoid hp=" .. tostring(math.floor(d.Health)) .. "/" .. tostring(math.floor(d.MaxHealth)) .. " in " .. (m and m:GetFullName() or "?"))
                        end
                    end
                end
                add("humanoids in POIs: " .. tostring(n))
            end
        end)
        pcall(function()
            add("== POI prompt models ==")
            local w = Workspace:FindFirstChild("World")
            local pois = w and w:FindFirstChild("POIs")
            if pois then
                local n = 0
                for _, d in pois:GetDescendants() do
                    if d:IsA("ProximityPrompt") then
                        n += 1
                        if n <= 20 then
                            local m = d:FindFirstAncestorOfClass("Model")
                            add("  prompt in " .. (m and m:GetFullName() or "?"))
                        end
                    end
                end
                add("prompts in POIs: " .. tostring(n))
            end
        end)
        local text = table.concat(lines, "\n")
        getgenv().TridentLastScan = text
        pcall(function() writefile("trident_scan.txt", text) end)
        pcall(function() setclipboard(text) end)
        Library:Notify({Message = "Scan готов: trident_scan.txt + буфер. Пришли мне содержимое.", Delay = 6})
    end})
    MiscSec:Button({Name = "Rescan world (POIs)", Callback = function()
        task.spawn(function()
            local ok = pcall(function() RescanPOIs(true) end)
            Library:Notify({Message = ok and "World пересканирован" or "Rescan упал", Delay = 3})
        end)
    end})
    MiscSec:Button({Name = "Fix Drawing (actor)", Callback = function()
        local src = getgenv().TRIDENT_ACTOR_SRC
        local runner = rawget(getgenv(), "run_on_actor") or rawget(getgenv(), "runonactor") or rawget(getgenv(), "RunOnActor")
        if type(runner) == "function" and type(src) == "string" then
            local ok, actor = pcall(function()
                local a = Instance.new("Actor")
                a.Parent = game:GetService("CoreGui")
                return a
            end)
            if ok and actor then
                pcall(function() runner(actor, src) end)
                task.delay(0.5, function() pcall(function() actor:Destroy() end) end)
                Library:Notify({Message = "Actor Drawing fix отправлен", Delay = 3})
            else
                Library:Notify({Message = "Нет Actor, Drawing уже должен работать", Delay = 3})
            end
        else
            local okD = getgenv().TridentDrawingOK and getgenv().TridentDrawingOK()
            Library:Notify({Message = okD and "Drawing OK, фикс не нужен" or "Drawing недоступен, включи Highlight fallback", Delay = 4})
        end
    end})

    -- // ================= MAIN LOOP =================
    local function DrawingOKCached()
        if _G.__trident_drawing_ok_tick and os.clock() - _G.__trident_drawing_ok_tick < 1 then
            return _G.__trident_drawing_ok
        end
        local ok = false
        pcall(function()
            if getgenv().TridentDrawingOK then ok = getgenv().TridentDrawingOK() end
        end)
        _G.__trident_drawing_ok = ok
        _G.__trident_drawing_ok_tick = os.clock()
        return ok
    end

    Library:Connection(RunService.RenderStepped, function()
        local S = TridentSettings
        local drawOK = DrawingOKCached()
        local useHL = (not drawOK) and S.Misc.UseHighlightFallback
        local seenChams, seenSkel, seenWorld = {}, {}, {}

        -- статус раз в ~2 сек
        do
            local now = os.clock()
            if not _G.__trident_status_tick or now - _G.__trident_status_tick > 2 then
                _G.__trident_status_tick = now
                local mode = "Workspace"
                if AdvancedList and next(AdvancedList) ~= nil then mode = "PlayerClient" end
                local d = drawOK and "Drawing OK" or (useHL and "Highlight" or "NO DRAW")
                pcall(function()
                    -- Label не имеет Set, пересоздавать не будем, просто игнорим если нет метода
                    if StatusLabel and StatusLabel.GetName then
                        -- обновить через внутренний текст нельзя, поэтому только notify при смене
                    end
                end)
                _G.__trident_mode = mode .. " | " .. d
            end
        end

        -- ---------- PLAYERS ----------
        if S.Players.Enabled and espLib and drawOK then
            local adv = (AdvancedList and next(AdvancedList) ~= nil) and AdvancedList or nil
            if adv then
                for _, pt in pairs(adv) do
                    if type(pt) ~= "table" then continue end
                    local isP = false
                    pcall(function() isP = (rawget(pt, "type") == "Player") end)
                    if not isP then continue end
                    local model = nil
                    pcall(function() model = rawget(pt, "model") end)
                    if typeof(model) ~= "Instance" or not model.Parent then continue end
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if not hrp then
                        local e0 = espLib.playerESP.playerCache[pt]
                        if e0 then e0:hideDrawings() end
                        continue
                    end
                    if not S.Players.ShowLocal and IsLocalModel(model) then
                        local e0 = espLib.playerESP.playerCache[pt]
                        if e0 then e0:hideDrawings() end
                        continue
                    end
                    local sleeping = false
                    pcall(function() sleeping = rawget(pt, "sleeping") == true end)
                    if sleeping and not S.Players.ShowSleepers then
                        local e0 = espLib.playerESP.playerCache[pt]
                        if e0 then e0:hideDrawings() end
                        continue
                    end
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    if dist > S.Players.MaxDistance then
                        local e0 = espLib.playerESP.playerCache[pt]
                        if e0 then e0:hideDrawings() end
                        continue
                    end
                    local esp = espLib.playerESP.playerCache[pt]
                    if not esp then
                        local okc, obj = pcall(function() return espLib.playerESP.new(pt) end)
                        if okc then esp = obj end
                    end
                    if esp then
                        local col = sleeping and S.Players.SleeperColor or S.Players.Color
                        pcall(function()
                            esp.drawings.box.Color = col
                            esp.drawings.name.Color = col
                            esp.drawings.distance.Color = col
                            esp.drawings.weapon.Color = col
                        end)
                        pcall(function()
                            esp:loop({box = S.Players.Box, name = S.Players.Name, distance = S.Players.Distance, weapon = S.Players.Weapon}, dist)
                        end)
                        pcall(function()
                            if S.Players.Chams then seenChams[model] = true SetChams(model, S.Players.ChamsColor, S.Players.ChamsFill, true)
                            else SetChams(model, nil, 0, false) end
                            if S.Players.Skeleton and drawOK then seenSkel[model] = true DrawSkeleton(model, S.Players.SkeletonColor)
                            else HideSkeleton(model) end
                        end)
                    end
                end
            else
                for _, model in GetPlayerModels() do
                    if not model.Parent then continue end
                    if not S.Players.ShowLocal and IsLocalModel(model) then
                        local f0 = FakePlayerByModel[model]
                        if f0 then
                            local e0 = espLib.playerESP.playerCache[f0]
                            if e0 then e0:hideDrawings() end
                        end
                        if useHL then SetHighlight(model, S.Players.Color, false) end
                        continue
                    end
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if not hrp then continue end
                    local sleeping = IsSleepingModel(model)
                    if sleeping and not S.Players.ShowSleepers then
                        local f0 = FakePlayerByModel[model]
                        if f0 then
                            local e0 = espLib.playerESP.playerCache[f0]
                            if e0 then e0:hideDrawings() end
                        end
                        continue
                    end
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    if dist > S.Players.MaxDistance then
                        local f0 = FakePlayerByModel[model]
                        if f0 then
                            local e0 = espLib.playerESP.playerCache[f0]
                            if e0 then e0:hideDrawings() end
                        end
                        if useHL then SetHighlight(model, S.Players.Color, false) end
                        continue
                    end
                    local fake = GetFakePlayer(model)
                    local esp = espLib.playerESP.playerCache[fake]
                    if not esp then
                        local okc, obj = pcall(function() return espLib.playerESP.new(fake) end)
                        if okc then esp = obj end
                    end
                    if esp then
                        local col = sleeping and S.Players.SleeperColor or S.Players.Color
                        pcall(function()
                            esp.drawings.box.Color = col
                            esp.drawings.name.Color = col
                            esp.drawings.distance.Color = col
                            esp.drawings.weapon.Color = col
                            -- имя: player/sleeper уже ставит библиотека, но для workspace покажем ник
                            if S.Players.Name then
                                esp.drawings.name.Text = (sleeping and "sleeper [" or "") .. model.Name .. (sleeping and "]" or "")
                                -- renderName перезапишет текст каждый кадр, поэтому правим после loop ниже
                            end
                        end)
                        pcall(function()
                            esp:loop({box = S.Players.Box, name = S.Players.Name, distance = S.Players.Distance, weapon = S.Players.Weapon}, dist)
                        end)
                        -- поверх библиотеки ставим ник (workspace-режим информативнее)
                        pcall(function()
                            if S.Players.Name and esp.drawings.name.Visible then
                                local nick = model.Name
                                pcall(function()
                                    local tag = model:FindFirstChild("Head")
                                    tag = tag and tag:FindFirstChild("Nametag")
                                    tag = tag and tag:FindFirstChild("tag")
                                    if tag and tag.Text ~= "" then nick = tag.Text end
                                end)
                                esp.drawings.name.Text = nick .. (sleeping and " [sleep]" or "")
                            end
                            if S.Players.Weapon and esp.drawings.weapon.Visible then
                                local wn = GetWeaponName(model)
                                esp.drawings.weapon.Text = wn
                            end
                        end)
                        pcall(function()
                            if S.Players.Chams then seenChams[model] = true SetChams(model, S.Players.ChamsColor, S.Players.ChamsFill, true)
                            else SetChams(model, nil, 0, false) end
                            if S.Players.Skeleton and drawOK then seenSkel[model] = true DrawSkeleton(model, S.Players.SkeletonColor)
                            else HideSkeleton(model) end
                        end)
                    end
                end
            end
        elseif S.Players.Enabled and useHL then
            -- Highlight режим без Drawing
            if espLib then
                pcall(function()
                    for _, e in pairs(espLib.playerESP.playerCache) do e:hideDrawings() end
                end)
            end
            for _, model in GetPlayerModels() do
                local okh = pcall(function()
                    if not S.Players.ShowLocal and IsLocalModel(model) then
                        SetHighlight(model, S.Players.Color, false) return
                    end
                    if IsSleepingModel(model) and not S.Players.ShowSleepers then
                        SetHighlight(model, S.Players.Color, false) return
                    end
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local d = (Camera.CFrame.Position - hrp.Position).Magnitude
                    if d > S.Players.MaxDistance then
                        SetHighlight(model, S.Players.Color, false) return
                    end
                    local sleeping = IsSleepingModel(model)
                    SetHighlight(model, sleeping and S.Players.SleeperColor or S.Players.Color, true)
                    if S.Players.Chams then seenChams[model] = true SetChams(model, S.Players.ChamsColor, S.Players.ChamsFill, true)
                    else SetChams(model, nil, 0, false) end
                end)
            end
        else
            if espLib then
                pcall(function()
                    for _, e in pairs(espLib.playerESP.playerCache) do
                        -- прячем только если выключено, чтобы не мигало когда просто нет drawOK
                        if not S.Players.Enabled then e:hideDrawings() end
                    end
                end)
            end
            if not S.Players.Enabled then ClearAllHighlights() end
            pcall(function()
                for m, _ in ChamsCache do if not seenChams[m] then SetChams(m, nil, 0, false) end end
                for m, _ in SkeletonPools do if not seenSkel[m] then HideSkeleton(m) end end
                if not S.Players.Chams then ClearAllChams() end
                if not (S.Players.Skeleton and drawOK) then HideAllSkeletons() end
            end)
        end

        -- ---------- ORES ----------
        if S.Ores.Enabled and espLib and drawOK then
            local ores = ScanOres()
            for _, info in ores do
                local m = info.model
                if not m.Parent then continue end
                local allow = (info.oreName == "Iron Ore" and S.Ores.Iron) or (info.oreName == "Nitrate Ore" and S.Ores.Nitrate) or (info.oreName == "Stone Ore" and S.Ores.Stone)
                if not allow then
                    local f0 = FakeOreByModel[m]
                    if f0 then
                        local e0 = espLib.entityESP.entityCache[f0]
                        if e0 then e0:hideDrawings() end
                    end
                    continue
                end
                local pivOk, piv = pcall(function() return m:GetPivot().Position end)
                if not pivOk then continue end
                local dist = (Camera.CFrame.Position - piv).Magnitude
                if dist > S.Ores.MaxDistance then
                    local f0 = FakeOreByModel[m]
                    if f0 then
                        local e0 = espLib.entityESP.entityCache[f0]
                        if e0 then e0:hideDrawings() end
                    end
                    continue
                end
                local fake = GetFakeOre(m, info.oreName)
                local esp = espLib.entityESP.entityCache[fake]
                if not esp then
                    local okc, obj = pcall(function() return espLib.entityESP.new(fake, info.oreName, info.color) end)
                    if okc then esp = obj end
                end
                if esp then
                    pcall(function()
                        esp.drawings.box.Color = info.color
                        esp.drawings.name.Color = info.color
                        esp.drawings.distance.Color = info.color
                        esp.drawings.name.Text = info.oreName
                    end)
                    pcall(function()
                        esp:loop({box = S.Ores.Box, name = S.Ores.Name, distance = S.Ores.Distance}, dist)
                    end)
                end
            end
            -- руды-части (Part/MeshPart): текст + подсветка, т.к. entityESP умеет только Model
            pcall(function()
                for _, pi in ScanOreParts() do
                    local p = pi.part
                    if p.Parent then
                        local allow = (pi.oreName == "Iron Ore" and S.Ores.Iron) or (pi.oreName == "Nitrate Ore" and S.Ores.Nitrate) or (pi.oreName == "Stone Ore" and S.Ores.Stone)
                        if allow then
                            local d = (Camera.CFrame.Position - p.Position).Magnitude
                            if d <= S.Ores.MaxDistance then
                                if S.Ores.Box then seenWorld[p] = true SetWorldHighlight(p, pi.color, true) end
                                if S.Ores.Name or S.Ores.Distance then
                                    local label = S.Ores.Name and pi.oreName or ""
                                    if S.Ores.Distance then label = label .. (label ~= "" and " " or "") .. "[" .. math.floor(d) .. "]" end
                                    ShowPartText(p, label, pi.color)
                                end
                            else
                                local t0 = PartTextPool[p]
                                if t0 then pcall(function() t0.Visible = false end) end
                            end
                        end
                    end
                end
            end)
        else
            if espLib and not S.Ores.Enabled then
                pcall(function()
                    for _, e in pairs(espLib.entityESP.entityCache) do
                        local m = rawget(e.entity, "model")
                        if m and not FakeBackpackByModel[m] then e:hideDrawings() end
                    end
                end)
                pcall(HideAllPartTexts)
            elseif S.Ores.Enabled and not drawOK and S.Misc.UseHighlightFallback then
                -- fallback без Drawing: подсвечиваем руды-модели и руды-части
                pcall(function()
                    for _, info in ScanOres() do
                        local m = info.model
                        if m.Parent then
                            local allow = (info.oreName == "Iron Ore" and S.Ores.Iron) or (info.oreName == "Nitrate Ore" and S.Ores.Nitrate) or (info.oreName == "Stone Ore" and S.Ores.Stone)
                            if allow then
                                local okp, piv = pcall(function() return m:GetPivot().Position end)
                                if okp and (Camera.CFrame.Position - piv).Magnitude <= S.Ores.MaxDistance then
                                    seenWorld[m] = true SetWorldHighlight(m, info.color, true)
                                end
                            end
                        end
                    end
                    for _, pi in ScanOreParts() do
                        if pi.part.Parent and (Camera.CFrame.Position - pi.part.Position).Magnitude <= S.Ores.MaxDistance then
                            seenWorld[pi.part] = true SetWorldHighlight(pi.part, pi.color, true)
                        end
                    end
                end)
            end
        end

        -- ---------- NPC ----------
        if S.NPC.Enabled and espLib and drawOK then
            for _, model in GetNPCModels() do
                if not model.Parent then continue end
                local okp, piv = pcall(function() return model:GetPivot().Position end)
                if not okp then continue end
                local dist = (Camera.CFrame.Position - piv).Magnitude
                if dist > S.NPC.MaxDistance then
                    local f0 = FakeNPCByModel[model]
                    if f0 then
                        local e0 = espLib.npcESP.npcCache[f0]
                        if e0 then e0:hideDrawings() end
                    end
                    continue
                end
                local fake = GetFakeNPC(model)
                local esp = espLib.npcESP.npcCache[fake]
                if not esp then
                    local okc, obj = pcall(function() return espLib.npcESP.new(fake, S.NPC.Color) end)
                    if okc then esp = obj end
                end
                if esp then
                    pcall(function()
                        esp.drawings.box.Color = S.NPC.Color
                        esp.drawings.name.Color = S.NPC.Color
                        esp.drawings.distance.Color = S.NPC.Color
                        esp.drawings.name.Text = model.Name
                    end)
                    pcall(function()
                        esp:loop({box = S.NPC.Box, name = S.NPC.Name, distance = S.NPC.Distance}, dist)
                    end)
                end
            end
        else
            if espLib and not S.NPC.Enabled then
                pcall(function()
                    for _, e in pairs(espLib.npcESP.npcCache) do e:hideDrawings() end
                end)
            elseif S.NPC.Enabled and not drawOK and S.Misc.UseHighlightFallback then
                pcall(function()
                    for _, model in GetNPCModels() do
                        if model.Parent then
                            local okp, piv = pcall(function() return model:GetPivot().Position end)
                            if okp and (Camera.CFrame.Position - piv).Magnitude <= S.NPC.MaxDistance then
                                seenWorld[model] = true SetWorldHighlight(model, S.NPC.Color, true)
                            end
                        end
                    end
                end)
            end
        end

        -- ---------- BACKPACKS (лут после смерти) ----------
        if S.Backpacks.Enabled and espLib and drawOK then
            pcall(function()
                for _, model in GetBackpackModels() do
                    if not model.Parent then continue end
                    local okp, piv = pcall(function() return model:GetPivot().Position end)
                    if not okp then continue end
                    local dist = (Camera.CFrame.Position - piv).Magnitude
                    local fake0 = FakeBackpackByModel[model]
                    if dist > S.Backpacks.MaxDistance then
                        if fake0 then
                            local e0 = espLib.entityESP.entityCache[fake0]
                            if e0 then e0:hideDrawings() end
                        end
                        continue
                    end
                    local nm = string.lower(model.Name)
                    local label = (string.find(nm, "bag", 1, true) or string.find(nm, "backpack", 1, true)
                        or string.find(nm, "corpse", 1, true) or string.find(nm, "body", 1, true)
                        or string.find(nm, "loot", 1, true)) and model.Name or "Backpack"
                    local fake = GetFakeBackpack(model, label)
                    local esp = espLib.entityESP.entityCache[fake]
                    if not esp then
                        local okc, obj = pcall(function() return espLib.entityESP.new(fake, label, S.Backpacks.Color) end)
                        if okc then esp = obj end
                    end
                    if esp then
                        pcall(function()
                            esp.drawings.box.Color = S.Backpacks.Color
                            esp.drawings.name.Color = S.Backpacks.Color
                            esp.drawings.distance.Color = S.Backpacks.Color
                            esp.drawings.name.Text = label
                        end)
                        pcall(function()
                            esp:loop({box = S.Backpacks.Box, name = S.Backpacks.Name, distance = S.Backpacks.Distance}, dist)
                        end)
                    end
                end
            end)
        else
            if espLib and not S.Backpacks.Enabled then
                pcall(function()
                    for _, e in pairs(espLib.entityESP.entityCache) do
                        local m = rawget(e.entity, "model")
                        if m and FakeBackpackByModel[m] then e:hideDrawings() end
                    end
                end)
            elseif S.Backpacks.Enabled and not drawOK and S.Misc.UseHighlightFallback then
                pcall(function()
                    for _, model in GetBackpackModels() do
                        if model.Parent then
                            local okp, piv = pcall(function() return model:GetPivot().Position end)
                            if okp and (Camera.CFrame.Position - piv).Magnitude <= S.Backpacks.MaxDistance then
                                seenWorld[model] = true SetWorldHighlight(model, S.Backpacks.Color, true)
                            end
                        end
                    end
                end)
            end
        end
        pcall(function() SweepWorldHighlights(seenWorld) end)
    end, "TridentESP_Loop")
end
--
--
do -- Settings
	local SettingsSection = Settings:Section({Name = "Settings", Side = "Right", Fill = true})
	--
	do -- Settings
		SettingsSection:Label({Message = "Menu key"}):Keybind({Default = Enum.KeyCode.RightShift, UseMode = false, Callback = function(Key) Library.UI.CloseBind = Key end})
		SettingsSection:Label({Message = "Menu color"}):ColorPicker({Default = Library.Theme.Default.Accent, Callback = function(Color)
			Library:UpdateColor("Accent", Color)
			Library:UpdateColor("SecondAccent", Color3.fromRGB(math.max(math.floor(Color.R * 255) - 12, 0), math.max(math.floor(Color.G * 255) - 12, 0), math.max(math.floor(Color.B * 255) - 12, 0)))
		end})
		SettingsSection:Slider({Name = "Menu animation speed", Min = 0, Max = 150, Default = 100, Ending = "%", Disable = {"Off", 0, 150}, Callback = function(Value)
			local MinSource, MaxSource = 1, 150
			local MinTarget, MaxTarget = 0.8, 0.1
			local NewValue = MinTarget + ((Value - MinSource) * (MaxTarget - MinTarget)) / (MaxSource - MinSource)
			--
			Library.UI.TweenSpeed = Value == (0 or 150) and 0 or NewValue
		end})
		SettingsSection:Button({Name = "Unload", Callback = Library.Unload})
		SettingsSection:Button({Name = "Disable all", Callback = Library.Disable})
	end
end
--
do -- Weapons
	local SkinsSection = Weapons:Section({Name = "Skins", Fill = true})
	local SkinList = SkinsSection:List({Size = 200})
	--
	SkinList:AddValue("Test Skin 1", {Image = "http://www.roblox.com/asset/?id=12206409737", Color = Color3.fromRGB(232, 0, 0), Size = UDim2.fromOffset(5, 5), Position = UDim2.new(0, 11, 0.5, 0)})
	SkinList:AddValue("Test Skin 2", {Image = "http://www.roblox.com/asset/?id=12206409737", Color = Color3.fromRGB(2, 144, 232), Size = UDim2.fromOffset(5, 5), Position = UDim2.new(0, 11, 0.5, 0)})
	SkinList:AddValue("Test Skin 3", {Image = "http://www.roblox.com/asset/?id=12206409737", Color = Color3.fromRGB(198, 7, 232), Size = UDim2.fromOffset(5, 5), Position = UDim2.new(0, 11, 0.5, 0)})
	SkinList:AddValue("Test Skin 4", {Image = "http://www.roblox.com/asset/?id=12206409737", Color = Color3.fromRGB(36, 232, 1), Size = UDim2.fromOffset(5, 5), Position = UDim2.new(0, 11, 0.5, 0)})
end
--
do -- Aimbot
	local AimbotSubSection, AimbotSubSection2 = Aimbot:SubSection({Name = "Category", Options = {"rbxassetid://18686402989", "rbxassetid://18657040454", "rbxassetid://18205704829", "rbxassetid://18205706952", "rbxassetid://18205822505"}})
end
--
do -- PlayerList
	local PlayerSection = PlayerList:Section({Name = "Players", Fill = true})
	local PlayerAdjustments = PlayerList:Section({Name = "Adjustments", Fill = true, Side = "Right"})
	--
	do -- Player Section
		ActualPlayerList = PlayerSection:List({Flag = "PlayerListCurrentPlayer", Size = 300})
		--
		PlayerSection:Button({Name = "View player", Callback = function()
			local Player = Players:FindFirstChild(Library.Flags["PlayerListCurrentPlayer"]:Get())
			--
			if Player then
				Library:ViewPlayer(Player)
			end
		end})
		--
		for _, Player in Players:GetPlayers() do
			ActualPlayerList:AddValue(Player.Name, {Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)})
		end
	end
	--
	do -- Adjustments
		PlayerAdjustments:Toggle({Name = "Whitelisted"})
	end
end
--
do -- Configs
	local ConfigSection = Configs:Section({Name = "Configs", Fill = true})
	local LuaSection = Configs:Section({Name = "LUA", Side = "Right", Fill = true})
	--
	do -- Configs
		local ConfigList = ConfigSection:List({Size = 200, Flag = "CurrentConfig"})
		--
		Library:UpdateConfigList(ConfigList, "Add")
		--
		ConfigSection:Button({Name = "Update config", Callback = function()
			if Library.Flags["CurrentConfig"]:Get() then
				writefile("LuckyHub/Configs/" .. Library.Flags["CurrentConfig"]:Get() .. ".cfg", Library:GetConfig())
			end
		end})
		ConfigSection:Button({Name = "Load config", Callback = function()
			if Library.Flags["CurrentConfig"]:Get() then
				Library:LoadConfig(readfile("LuckyHub/Configs/" .. Library.Flags["CurrentConfig"]:Get() .. ".cfg"))
			end
		end})
		ConfigSection:TextBox({Flag = "ConfigName"})
		ConfigSection:Button({Name = "Create config", Callback = function()
			local ConfigName = Library.Flags["ConfigName"]:Get()
			--
			if Library.Flags["ConfigName"]:Get() ~= "" and not isfile("LuckyHub/Configs/" .. ConfigName .. ".cfg") then
			    writefile("LuckyHub/Configs/" .. ConfigName .. ".cfg", Library:GetConfig())
			    --
			    ConfigList:AddValue(ConfigName)
			end
		end})
		ConfigSection:Button({Name = "Refresh list", Callback = function()
			Library:UpdateConfigList(ConfigList, "Remove")
			Library:UpdateConfigList(ConfigList, "Add")
		end})
	end
	--
	do -- LUA
		local LuaList = LuaSection:List({Size = 75})
		--
		LuaSection:Button({Name = "Load script"})
		LuaSection:Button({Name = "Unload script"})
		LuaSection:Button({Name = "Refresh list"})
	end
end
--
do -- Lua
	local TabA = Lua:Section({Name = "Tab A", Fill = true})
	local TabB = Lua:Section({Name = "Tab B", Side = "Right", Fill = true})
end
--
do -- Connections
	Library:Connection(Players.PlayerAdded, function(Player)
		if not ActualPlayerList then return end
		--
		ActualPlayerList:AddValue(Player.Name, {Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)})
	end)
	--
	Library:Connection(Players.PlayerRemoving, function(Player)
		if not ActualPlayerList then return end
		--
		ActualPlayerList:AddValue(Player.Name, {Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)})
	end)
end
--

Library:Init()
-- // Trident Survival ESP ready. Open Visuals and enable ESP.
Library:Notify({Message = "Trident ESP loaded. Open <b>Visuals</b> and enable ESP.", Delay = 5})

