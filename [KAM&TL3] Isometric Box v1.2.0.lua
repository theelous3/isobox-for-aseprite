--[[


__/\\\\\\\\\\\_____/\\\\\\\\\\\_________/\\\\\_______/\\\\____________/\\\\__/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\\\____/\\\\\\\\\______/\\\\\\\\\\\________/\\\\\\\\\_
 _\/////\\\///____/\\\/////////\\\_____/\\\///\\\____\/\\\\\\________/\\\\\\_\/\\\///////////__\///////\\\/////___/\\\///////\\\___\/////\\\///______/\\\////////__
  _____\/\\\______\//\\\______\///____/\\\/__\///\\\__\/\\\//\\\____/\\\//\\\_\/\\\___________________\/\\\_______\/\\\_____\/\\\_______\/\\\_______/\\\/___________
   _____\/\\\_______\////\\\__________/\\\______\//\\\_\/\\\\///\\\/\\\/_\/\\\_\/\\\\\\\\\\\___________\/\\\_______\/\\\\\\\\\\\/________\/\\\______/\\\_____________
    _____\/\\\__________\////\\\______\/\\\_______\/\\\_\/\\\__\///\\\/___\/\\\_\/\\\///////____________\/\\\_______\/\\\//////\\\________\/\\\_____\/\\\_____________
     _____\/\\\_____________\////\\\___\//\\\______/\\\__\/\\\____\///_____\/\\\_\/\\\___________________\/\\\_______\/\\\____\//\\\_______\/\\\_____\//\\\____________
      _____\/\\\______/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_\/\\\___________________\/\\\_______\/\\\_____\//\\\______\/\\\______\///\\\__________
       __/\\\\\\\\\\\_\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\_____________\/\\\_\/\\\\\\\\\\\\\\\_______\/\\\_______\/\\\______\//\\\__/\\\\\\\\\\\____\////\\\\\\\\\_
        _\///////////____\///////////__________\/////_______\///______________\///__\///////////////________\///________\///________\///__\///////////________\/////////__
__/\\\\\\\\\\\\\_________/\\\\\_______/\\\_______/\\\________________/\\\__________/\\\\\\\\\_______________/\\\\\\\____
 _\/\\\/////////\\\_____/\\\///\\\____\///\\\___/\\\/_____________/\\\\\\\________/\\\///////\\\___________/\\\/////\\\__
  _\/\\\_______\/\\\___/\\\/__\///\\\____\///\\\\\\/______________\/////\\\_______\///______\//\\\_________/\\\____\//\\\_
   _\/\\\\\\\\\\\\\\___/\\\______\//\\\_____\//\\\\____________________\/\\\_________________/\\\/_________\/\\\_____\/\\\_
    _\/\\\/////////\\\_\/\\\_______\/\\\______\/\\\\____________________\/\\\______________/\\\//___________\/\\\_____\/\\\_
     _\/\\\_______\/\\\_\//\\\______/\\\_______/\\\\\\___________________\/\\\___________/\\\//______________\/\\\_____\/\\\_
      _\/\\\_______\/\\\__\///\\\__/\\\_______/\\\////\\\_________________\/\\\_________/\\\/_________________\//\\\____/\\\__
       _\/\\\\\\\\\\\\\/_____\///\\\\\/______/\\\/___\///\\\_______________\/\\\__/\\\__/\\\\\\\\\\\\\\\__/\\\__\///\\\\\\\/___
        _\/////////////_________\/////_______\///_______\///________________\///__\///__\///////////////__\///_____\///////_____


  ISOMETRIC BOX GENERATOR 1.2.0 for Aseprite (https://aseprite.org)

  This is the original project page, but I believe it to be abandoned.
  https://darkwark.itch.io/isobox-for-aseprite

    Overhaul by Mark Jameson @theelous3
    https://theelous3.net
    I frankly don't give a shite about the (lack of) pre existing licence & status
    as there has been no movement for 6 years. Whatever power I have
    for the addition of my own work, I release under the nov 21st 2025 version
    of the MIT licence. I believe the changes in this file are so broad as to be
    essentially entirely transformational. However, out of respect for the previous
    dev I am going to include their details and notes etc.

    Original by Kamil Khadeyev (@darkwark)
    Twitter: http://twitter.com/darkwark
    Dribbble: http://dribbble.com/darkwark
    Website: http://darkwark.com

    (c) 2018, November
    All rights reserved or something

    Features:
        + Customize X, Y and Z size of the box
        + Customize colors for each side of the box
        + Custom Stroke and Highlight colors
        + Two types of the box: 3px and 2px corner

    New features:
        + Wireframe mode for outlining
        + Custom layer naming and auto increment
        + Improved ui
        + Auto centering tall boxes
        + Auto update of color palette with fg

    Requirements:
        + Aseprite >= 1.2.10-beta2
        + Color Mode: RGBA

    Installation:
        + Open Aseprite
        + Go to `File → Scripts → Open Scripts Folder`
        + Place downloaded LUA script into opened directory
        + F5 to reload scripts, or select reload scripts from scripts menu

    Usage:
        + Go to `File → Scripts → [TL3] Isometric Box v1.2.0` to run the script
        + You can also setup a custom hotkey under `Edit → Keyboard Shortcuts`

]]


---------------------------------------
-- USER DEFAULTS --
---------------------------------------
local c = app.fgColor

-- Default colors:
local colors = {
    stroke    = nil,
    top       = nil,
    left      = nil,
    right     = nil,
    highlight = nil
}

local function computeColorsFromFg(fg)
    if not fg then return end

    local h = fg.hsvHue
    local s = fg.hsvSaturation
    local v = fg.hsvValue

    colors.stroke    = Color{ h=0, s=0, v=0, a=255 }
    colors.top       = fg
    colors.left      = Color{ h=h, s=s+0.3, v=v-0.1, a=255 }
    colors.right     = Color{ h=h, s=s+0.3, v=v-0.4, a=255 }
    colors.highlight = Color{ h=h, s=s-0.2, v=v+0.2, a=255 }
end

-- initial computation at script load
computeColorsFromFg(app.fgColor)

-- Use 3px corner by default:
local use3pxCorner = false

-- Default Max Sizes:
local maxSize = {
    x = math.floor(app.activeSprite.width),
    y = math.floor(app.activeSprite.width),
    z = math.floor(app.activeSprite.height)
}

-- Initial size defaults (one source of truth)
local defaultSize = {
    x = 5,
    y = 5,
    z = 10
}

-- dialog handle (forward declared for use in redraw helpers)
local dlg



---------------------------------------
-- Colors Utility --
---------------------------------------
local function colorAsPixel(color)
    return app.pixelColor.rgba(color.red, color.green, color.blue, color.alpha)
end

local function isColorEqual(a, b)
    local pc = app.pixelColor

    return pc.rgbaR(a) == pc.rgbaR(b) and
           pc.rgbaG(a) == pc.rgbaG(b) and
           pc.rgbaB(a) == pc.rgbaB(b) and
           pc.rgbaA(a) == pc.rgbaA(b)
end

local function isColorEqualAt(x, y, color)
    local pc = app.pixelColor
    local pickedColor = app.activeImage:getPixel(x, y)

    return isColorEqual(pickedColor, color)
end

---------------------------------------
-- Flood Fill --
---------------------------------------
local function floodFill(x, y, targetColor, replacementColor)
    if isColorEqual(targetColor, replacementColor) then return end
    if not isColorEqualAt(x, y, targetColor) then return end

    app.activeImage:putPixel(x, y, replacementColor)

    floodFill(x+1, y, targetColor, replacementColor)
    floodFill(x-1, y, targetColor, replacementColor)
    floodFill(x, y+1, targetColor, replacementColor)
    floodFill(x, y-1, targetColor, replacementColor)
end

---------------------------------------
-- BASIC LINES --
---------------------------------------
local function hLine(color, x, y, len)
    for i = 1, len do
        app.activeImage:putPixel(x+i, y, color)
    end
end

local function vLine(color, x, y, len)
    for i = 1, len do
        app.activeImage:putPixel(x, y+i, color)
    end
end

---------------------------------------
-- ISOMETRIC LINES --
---------------------------------------
local function isoLineDownRight(color, x, y, len)
    for i=0,len do
        local x1 = i*2
        local x2 = x1+1
        app.activeImage:putPixel(x+x1, y+i, color)
        app.activeImage:putPixel(x+x2, y+i, color)
    end
end

local function isoLineDownLeft(color, x, y, len)
    for i=0,len do
        local x1 = i*2
        local x2 = x1+1
        app.activeImage:putPixel(x-x1, y+i, color)
        app.activeImage:putPixel(x-x2, y+i, color)
    end
end

local function isoLineUpRight(color, x, y, len)
    for i=0,len do
        local x1 = i*2
        local x2 = x1+1
        app.activeImage:putPixel(x+x1, y-i, color)
        app.activeImage:putPixel(x+x2, y-i, color)
    end
end

local function isoLineUpLeft(color, x, y, len)
    for i=0,len do
        local x1 = i*2
        local x2 = x1+1
        app.activeImage:putPixel(x-x1, y-i, color)
        app.activeImage:putPixel(x-x2, y-i, color)
    end
end


---------------------------------------
-- Cube position --
---------------------------------------
local function getBoxOrigin(xSize, ySize, zSize)
    local spr     = app.activeSprite
    local centerX = math.floor(spr.width  / 2)
    local centerY = math.floor(spr.height / 2)

    -- Full vertical span is roughly (xSize + ySize + zSize).
    -- so the box's vertical midpoint is:
    --     centerY + (zSize - xSize - ySize) / 2
    --
    -- We want that midpoint to line up with sprite centerY.
    -- So we shift the "centerY" we pass into the drawing code by:
    --     offset = (xSize + ySize - zSize) / 2
    --
    local offsetY = math.floor((xSize + ySize - zSize) / 2)
    local baseY   = centerY + offsetY

    return centerX, baseY
end


local function drawCube(type_, xSize, ySize, zSize, color)
    local centerX, centerY = getBoxOrigin(xSize, ySize, zSize)

    local a = (type_ == 1) and 0 or 1
    local b = (type_ == 1) and 1 or 0

    -- top plane
    isoLineUpRight(color, centerX-a,         centerY,       xSize) -- bottom right
    isoLineUpLeft (color, centerX,           centerY,       ySize) -- bottom left
    isoLineUpLeft (color, centerX+xSize*2+b, centerY-xSize, ySize) -- top right
    isoLineUpRight(color, centerX-ySize*2-1, centerY-ySize, xSize) -- top left

    -- bottom plane
    isoLineUpRight(color, centerX-a,         centerY+zSize, xSize) -- right
    isoLineUpLeft (color, centerX,           centerY+zSize, ySize) -- left

    -- verticals
    vLine(color, centerX-a,         centerY,       zSize) -- middle
    vLine(color, centerX-ySize*2-1, centerY-ySize, zSize) -- left
    vLine(color, centerX+xSize*2+b, centerY-xSize, zSize) -- right
end


------------ Adding Colors: ------------

local function fillCubeSides(xSize, ySize, zSize, topColor, leftColor, rightColor)
    local centerX, centerY = getBoxOrigin(xSize, ySize, zSize)

    local TRANSPARENT_COLOR = app.pixelColor.rgba(0, 0, 0, 0)

    floodFill(centerX,   centerY-1, TRANSPARENT_COLOR, colorAsPixel(topColor))
    floodFill(centerX-2, centerY+1, TRANSPARENT_COLOR, colorAsPixel(leftColor))
    floodFill(centerX+1, centerY+1, TRANSPARENT_COLOR, colorAsPixel(rightColor))
end


local function addHighlight(type_, xSize, ySize, zSize, color)
    local centerX, centerY = getBoxOrigin(xSize, ySize, zSize)

    local alt = (type_ == 1) and 0 or 1

    isoLineUpRight(color, centerX-alt, centerY,       xSize-1)
    isoLineUpLeft (color, centerX,     centerY,       ySize-1)
    vLine         (color, centerX-alt, centerY,       zSize-1)

    app.activeImage:putPixel(centerX-alt, centerY, app.pixelColor.rgba(255, 255, 255, 255))
end

---------------------------------------
-- LAYER MANAGEMENT --
---------------------------------------
local function newLayer(name)
    local s   = app.activeSprite
    local lyr = s:newLayer()
    lyr.name  = name
    s:newCel(lyr, 1)
    return lyr
end

local function ensureCel(layer, frame)
    local s           = layer.sprite
    local frameNumber = (frame and frame.frameNumber) or 1
    local cel         = layer:cel(frameNumber)
    if not cel then
        cel = s:newCel(layer, frameNumber)
    end
    return cel
end

local function activateLayer(layer, frame)
    local s   = layer.sprite
    local fr  = frame or app.activeFrame or s.frames[1]
    local cel = ensureCel(layer, fr)
    app.activeSprite = s
    app.activeFrame  = fr
    app.activeLayer  = layer
    app.activeCel    = cel
    return cel
end

local function clearLayer(layer, frame)
    local cel = activateLayer(layer, frame)
    cel.image:clear(app.pixelColor.rgba(0, 0, 0, 0))
end

-- Track whether we're live-editing a box
local boxState = {
    mode  = "idle", -- "idle" | "editing"
    layer = nil,
    frame = nil
}

local function stopEditing()
    boxState.mode  = "idle"
    boxState.layer = nil
    boxState.frame = nil
end

local function layerExistsInSprite(spr, target)
    if not spr or not target then return false end
    local function walk(layers)
        for _, l in ipairs(layers) do
            if l == target then return true end
            if l.isGroup and l.layers then
                if walk(l.layers) then return true end
            end
        end
        return false
    end
    return walk(spr.layers)
end

local function isLayerAlive(layer)
    if not layer then return false end
    local hasSprite, spr = pcall(function() return layer.sprite end)
    if not hasSprite or not spr then return false end
    local checked, res = pcall(layerExistsInSprite, spr, layer)
    if not checked then return false end
    return res == true
end

local function isFrameAlive(frame, spr)
    if not frame or not spr then return false end
    for _, f in ipairs(spr.frames) do
        if f == frame then return true end
    end
    return false
end

local function maybeEditing()
    if boxState.mode ~= "editing" then return false end
    local lyr = boxState.layer
    if not isLayerAlive(lyr) then
        stopEditing()
        return false
    end
    local spr = lyr.sprite
    if spr ~= app.activeSprite then
        stopEditing()
        return false
    end
    if boxState.frame and not isFrameAlive(boxState.frame, spr) then
        stopEditing()
        return false
    end
    return true
end

local function startEditing(layer)
    boxState.mode  = "editing"
    boxState.layer = layer
    boxState.frame = app.activeFrame or (layer.sprite and layer.sprite.frames[1]) or nil
end

local function collectBoxParams(data)
    local d = data or {}
    local x = math.max(1, math.min(maxSize.x, d.xSize or defaultSize.x))
    local y = math.max(1, math.min(maxSize.y, d.ySize or defaultSize.y))
    local z = math.max(3, math.min(maxSize.z, d.zSize or defaultSize.z))

    return {
        xSize          = x,
        ySize          = y,
        zSize          = z,
        cubeType       = d.typeOne and 1 or 2,
        strokeColor    = d.color or colors.stroke,
        topColor       = d.topColor or colors.top,
        leftColor      = d.leftColor or colors.left,
        rightColor     = d.rightColor or colors.right,
        highlightColor = d.highlightColor or colors.highlight,
        wireframeOnly  = (d.noFillAll == true)
    }
end

local function redrawBox()
    if not maybeEditing() then return end
    local params = collectBoxParams(dlg.data)
    local layer  = boxState.layer
    local frame  = boxState.frame

    app.transaction(function()
        clearLayer(layer, frame)

        drawCube(params.cubeType, params.xSize, params.ySize, params.zSize, params.strokeColor)

        if not params.wireframeOnly then
            fillCubeSides(params.xSize, params.ySize, params.zSize, params.topColor, params.leftColor, params.rightColor)
            addHighlight(params.cubeType, params.xSize, params.ySize, params.zSize, params.highlightColor)
        end
    end)

    app.refresh()
end

local function maybeRedraw()
    if maybeEditing() then redrawBox() end
end

---------------------------------------
-- USER INTERFACE / STATE --
---------------------------------------
local updating = false
local labelIncrement = 0
local lastLabelName  = ""

dlg = Dialog("[TL3] Isometric Box v1.2.0")


local function updateDialogColorsFromFg(fg)
    -- refresh our colour set
    computeColorsFromFg(fg)

    -- if the dialog is still around, push the values into the widgets
    if dlg then
        dlg:modify{ id="topColor",       color = colors.top }
        dlg:modify{ id="leftColor",      color = colors.left }
        dlg:modify{ id="rightColor",     color = colors.right }
        dlg:modify{ id="highlightColor", color = colors.highlight }
    end
end

local function onFgColorChange(ev)
    local fg = ev and ev.color or app.fgColor
    if not fg then return end
    updateDialogColorsFromFg(fg)
end

app.events:on("fgcolorchange", onFgColorChange)

dlg
    :separator{ text="Size:" }
    ---------------------------------------
    -- Y (Left) --
    ---------------------------------------
    :slider{
        id="ySize",
        label="Left:",
        min=1,
        max=maxSize.y,
        value=defaultSize.y,
        onchange=function()
            if updating then return end
            updating = true

            local v = dlg.data.ySize or defaultSize.y
            v = math.max(1, math.min(maxSize.y, v))

            dlg:modify{ id="ySize",    value=v }
            dlg:modify{ id="ySizeNum", text=tostring(v) }

            updating = false
            maybeRedraw()
        end
    }
    :number{
        id="ySizeNum",
        label="->",
        text=tostring(defaultSize.y),
        onchange=function()
            if updating then return end
            updating = true

            local v = tonumber(dlg.data.ySizeNum) or defaultSize.y
            v = math.max(1, math.min(maxSize.y, v))

            dlg:modify{ id="ySizeNum", text=tostring(v) }
            dlg:modify{ id="ySize",    value=v }

            updating = false
            maybeRedraw()
        end
    }

    ---------------------------------------
    -- X (Right) --
    ---------------------------------------
    :slider{
        id="xSize",
        label="Right:",
        min=1,
        max=maxSize.x,
        value=defaultSize.x,
        onchange=function()
            if updating then return end
            updating = true

            local v = dlg.data.xSize or defaultSize.x
            v = math.max(1, math.min(maxSize.x, v))

            dlg:modify{ id="xSize",    value=v }
            dlg:modify{ id="xSizeNum", text=tostring(v) }

            updating = false
            maybeRedraw()
        end
    }
    :number{
        id="xSizeNum",
        label="->",
        text=tostring(defaultSize.x),
        onchange=function()
            if updating then return end
            updating = true

            local v = tonumber(dlg.data.xSizeNum) or defaultSize.x
            v = math.max(1, math.min(maxSize.x, v))

            dlg:modify{ id="xSizeNum", text=tostring(v) }
            dlg:modify{ id="xSize",    value=v }

            updating = false
            maybeRedraw()
        end
    }


    ---------------------------------------
    -- Z (Height) --
    ---------------------------------------
    :slider{
        id="zSize",
        label="Height:",
        min=1,
        max=maxSize.z,
        value=defaultSize.z,
        onchange=function()
            if updating then return end
            updating = true

            local v = dlg.data.zSize or defaultSize.z
            v = math.max(3, math.min(maxSize.z, v))

            dlg:modify{ id="zSize",    value=v }
            dlg:modify{ id="zSizeNum", text=tostring(v) }

            updating = false
            maybeRedraw()
        end
    }
    :number{
        id="zSizeNum",
        label="->",
        text=tostring(defaultSize.z),
        onchange=function()
            if updating then return end
            updating = true

            local v = tonumber(dlg.data.zSizeNum) or defaultSize.z
            v = math.max(1, math.min(maxSize.z, v))

            dlg:modify{ id="zSizeNum", text=tostring(v) }
            dlg:modify{ id="zSize",    value=v }

            updating = false
            maybeRedraw()
        end
    }


    :separator{ text="Colors:" }
    :color {id="color",          label="Stroke:",    color = colors.stroke,    onchange=maybeRedraw}
    :color {id="topColor",       label="Top:",       color = colors.top,       onchange=maybeRedraw}
    :color {id="leftColor",      label="Left:",      color = colors.left,      onchange=maybeRedraw}
    :color {id="rightColor",     label="Right:",     color = colors.right,     onchange=maybeRedraw}
    :color {id="highlightColor", label="Highlight:", color = colors.highlight, onchange=maybeRedraw}
    :check{
        id="noFillAll",
        label="No fill (black wireframe)",
        selected=false,
        onclick=maybeRedraw
    }

    :separator()
    :radio {id="typeOne", label="Corner:", text="3 px", selected=use3pxCorner, onchange=maybeRedraw}
    :radio {id="typeTwo", text="2 px", selected=not use3pxCorner, onchange=maybeRedraw}

    :separator()
    :entry{
        id="customLayerName",
        label="Custom layer name:",
        text=""
    }

:button{
    id="ok",
    text="Add Box",
    onclick = function()
        local data = dlg.data

        -- check min height of z >= 3
        local zSize = data.zSize or defaultSize.z
        if zSize < 3 then
            app.alert("Height cannot be less than 3")
            return
        end

        stopEditing()

        app.transaction(function()

            local xSize = data.xSize or defaultSize.x
            local ySize = data.ySize or defaultSize.y


            -----------------------------------------------------
            -- cube type --
            -----------------------------------------------------
            local cubeType = data.typeOne and 1 or 2

            -----------------------------------------------------
            -- layer naming --
            -----------------------------------------------------
            local customLayerName = data.customLayerName or ""
            local layerName

            if customLayerName ~= "" then
                if customLayerName ~= lastLabelName then
                    lastLabelName  = customLayerName
                    labelIncrement = 0
                    layerName      = customLayerName
                else
                    labelIncrement = labelIncrement + 1
                    layerName      = customLayerName .. " " .. tostring(labelIncrement)
                end
            else
                lastLabelName  = ""
                labelIncrement = 0
                layerName      = "Cube("..xSize.." "..ySize.." "..zSize..")"
            end

            -----------------------------------------------------
            -- colors / wireframe --
            -----------------------------------------------------
            local wireframeOnly  = (data.noFillAll == true)

            local strokeColor    = data.color
            local topColor       = data.topColor
            local leftColor      = data.leftColor
            local rightColor     = data.rightColor
            local highlightColor = data.highlightColor

            if wireframeOnly then
                strokeColor = Color{ r=0, g=0, b=0, a=255 }
            end

            -----------------------------------------------------
            -- draw --
            -----------------------------------------------------
            local layer = newLayer(layerName)
            startEditing(layer)

            redrawBox()
        end)

        app.refresh()
    end
}
    :button{
        id="finish",
        text="Finish Box",
        onclick = function()
            stopEditing()
        end
    }
    :show{wait=false}
