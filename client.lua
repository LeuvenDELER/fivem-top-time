local sx, sy = guiGetScreenSize()
local scale = sy / 1080

local panelW = math.floor(550 * scale)
local rowH   = math.floor(32 * scale)
local headerH = math.floor(100 * scale)
local colHeadH = math.floor(30 * scale)
local footerH = math.floor(40 * scale)
local padX   = math.floor(20 * scale)
local innerW = panelW - padX * 2

local cxRank = 0
local cxName = math.floor(innerW * 0.12)
local cxHour = math.floor(innerW * 0.75)
local maxBarW = math.floor(innerW * 0.25)

-- State
local isVisible = false
local currentAlpha = 0
local targetAlpha = 0
local topPlayers = {}
local myRank = "?"
local maxHours = 1
local myNameCached = ""
local myHoursCached = 0
local scrollOffset = 0

-- Assets
local texLogo, texCircle, texVignette
local fontLogo, fontTitle, fontCol, fontRow

-- Helpers
local function tc(r, g, b, a)
    return tocolor(r, g, b, math.floor((a or 255) * currentAlpha))
end

local function dxDrawRoundedRectangle(x, y, w, h, radius, color)
    if not texCircle then
        dxDrawRectangle(x, y, w, h, color)
        return
    end
    dxDrawRectangle(x + radius, y, w - radius * 2, h, color)
    dxDrawRectangle(x, y + radius, radius, h - radius * 2, color)
    dxDrawRectangle(x + w - radius, y + radius, radius, h - radius * 2, color)
    
    dxDrawImageSection(x, y, radius, radius, 0, 0, 32, 32, texCircle, 0, 0, 0, color)
    dxDrawImageSection(x + w - radius, y, radius, radius, 32, 0, 32, 32, texCircle, 0, 0, 0, color)
    dxDrawImageSection(x, y + h - radius, radius, radius, 0, 32, 32, 32, texCircle, 0, 0, 0, color)
    dxDrawImageSection(x + w - radius, y + h - radius, radius, radius, 32, 32, 32, 32, texCircle, 0, 0, 0, color)
end

local svgCrown = [[
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white">
  <path d="M5 16L3 5l5.5 5L12 4l3.5 6L21 5l-2 11H5zm14 3c0 .6-.4 1-1 1H6c-.6 0-1-.4-1-1v-1h14v1z"/>
</svg>
]]

addEventHandler("onClientResourceStart", resourceRoot, function()
    texLogo   = svgCreate(math.floor(128 * scale), math.floor(128 * scale), svgCrown)
    texCircle = dxCreateTexture("assets/circle.png", "argb", true, "clamp")
    texVignette = dxCreateTexture("assets/vignette.png", "argb", true, "clamp")

    local bPath = "assets/BebasNeueBold.otf"
    local rBol = "assets/Roboto-Bold.ttf"
    
    fontTitle = dxCreateFont(bPath, math.floor(40 * scale))
    fontCol   = dxCreateFont(rBol, math.floor(13 * scale), false, "cleartype")
    fontRow   = dxCreateFont(rBol, math.floor(14 * scale), false, "cleartype")
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    if isVisible then
        exports.pav_secure:setData(localPlayer, "hudkapa", false, false)
        pcall(function() exports.pav_chat:chatVisible(true) end)
        pcall(function() exports.pav_hud:setHudVisible(true) end)
        toggleControl("radio_next", true)
        toggleControl("radio_previous", true)
        toggleControl("fire", true)
        toggleControl("aim_weapon", true)
    end
end)

-- Networking
addEvent("pav_toptime:receiveData", true)
addEventHandler("pav_toptime:receiveData", root, function(data)
    topPlayers = data or {}
    maxHours = 1
    if topPlayers[1] and topPlayers[1].hoursplayed then
        maxHours = math.max(1, tonumber(topPlayers[1].hoursplayed))
    end
end)

addEvent("pav_toptime:receiveMyRank", true)
addEventHandler("pav_toptime:receiveMyRank", root, function(rank)
    myRank = rank
end)

local function drawGradientBar(x, y, w, h, r, g, b, maxAlpha)
    if w <= 2 then
        dxDrawRectangle(x, y, w, h, tocolor(r, g, b, maxAlpha))
        return
    end
    local sections = math.min(math.floor(w), 150)
    local stepW = w / sections
    for i = 1, sections do
        local secAlpha = (i / sections) * maxAlpha
        dxDrawRectangle(x + (i - 1) * stepW, y, stepW + 0.6, h, tocolor(r, g, b, secAlpha))
    end
end

-- Main Render
local function renderTopTime()
    if currentAlpha < targetAlpha then
        currentAlpha = math.min(targetAlpha, currentAlpha + 0.08)
    elseif currentAlpha > targetAlpha then
        currentAlpha = math.max(targetAlpha, currentAlpha - 0.08)
    end

    if currentAlpha <= 0.001 and targetAlpha <= 0 then
        currentAlpha = 0
        isVisible = false
        removeEventHandler("onClientRender", root, renderTopTime)
        return
    end

    local maxDisplay = 10
    local totalPlayers = #topPlayers
    local numPlayers = math.min(maxDisplay, math.max(1, totalPlayers))
    local listH = rowH * numPlayers
    local panelH = headerH + colHeadH + listH + footerH
    local panelX = math.floor((sx - panelW) / 2)
    local panelY = math.floor((sy - panelH) / 2)

    local a = currentAlpha

    if texVignette then
        -- Top and Bottom
        dxDrawImage(0, 0, sx, sy * 0.25, texVignette, 0, 0, 0, tocolor(0, 0, 0, a * 200))
        dxDrawImage(0, sy * 0.75, sx, sy * 0.25, texVignette, 180, 0, 0, tocolor(0, 0, 0, a * 200))
        -- Left and Right
        dxDrawImage(-sx * 0.15, 0, sx * 0.3, sy, texVignette, -90, 0, 0, tocolor(0, 0, 0, a * 200))
        dxDrawImage(sx * 0.85, 0, sx * 0.3, sy, texVignette, 90, 0, 0, tocolor(0, 0, 0, a * 200))
    end

    -- Panel BG
    dxDrawRoundedRectangle(panelX, panelY, panelW, panelH, math.floor(12 * scale), tocolor(25, 25, 25, a * 240))

    -- Header (Logo + Title)
    local hY = panelY
    local logoS = math.floor(64 * scale)
    local logoX = panelX + math.floor((panelW - logoS) / 2)
    local logoY = hY - math.floor(32 * scale)
    
    if texLogo then
        -- Hover/Breath effect
        local now = getTickCount()
        local floatOff = math.sin(now / 1500) * (5 * scale)
        local pulse = math.abs(math.sin(now / 800))
        
        -- Glow Layer 1 (Large, expanding aura)
        local auraS = logoS + math.floor(10 * scale) + (pulse * math.floor(6 * scale))
        local auraX = logoX - (auraS - logoS) / 2
        local auraY = logoY + floatOff - (auraS - logoS) / 2
        dxDrawImage(auraX, auraY, auraS, auraS, texLogo, 0, 0, 0, tc(255, 80, 150, a * (40 + pulse * 60)))
        
        -- Glow Layer 2 (Tight, bright pink outline)
        local outS = logoS + math.floor(4 * scale)
        local outX = logoX - (outS - logoS) / 2
        local outY = logoY + floatOff - (outS - logoS) / 2
        dxDrawImage(outX, outY, outS, outS, texLogo, 0, 0, 0, tc(255, 80, 150, a * 180))
        
        -- Main White Crown
        dxDrawImage(logoX, logoY + floatOff, logoS, logoS, texLogo, 0, 0, 0, tc(255, 255, 255, a * 255))
    end

    if fontTitle then
        dxDrawText("SAAT TABLOSU", panelX, hY + math.floor(30 * scale), panelX + panelW, hY + headerH,
            tc(255, 255, 255, a * 255), 1, fontTitle, "center", "center")
    end

    -- Columns Header
    local chY = hY + headerH
    dxDrawRectangle(panelX, chY, panelW, colHeadH, tocolor(20, 20, 20, a * 200))
    dxDrawRectangle(panelX, chY + colHeadH - 1, panelW, 1, tc(255, 80, 150, a * 150)) -- Pink theme border
    
    local bx = panelX + padX
    if fontCol then
        dxDrawText("#", bx + cxRank, chY, bx + cxRank + math.floor(50*scale), chY + colHeadH, tc(153, 153, 153), 1, fontCol, "left", "center")
        dxDrawText("KARAKTER ADI", bx + cxName, chY, bx + cxName + math.floor(200*scale), chY + colHeadH, tc(153, 153, 153), 1, fontCol, "left", "center")
        dxDrawText("SAAT", bx + cxHour, chY, panelX + panelW - padX, chY + colHeadH, tc(153, 153, 153), 1, fontCol, "right", "center")
    end

    -- List rows
    local lY = chY + colHeadH
    
    for i = 1, numPlayers do
        local dataIndex = i + scrollOffset
        local p = topPlayers[dataIndex]
        if not p then break end
        
        local ry = lY + (i - 1) * rowH
        local bg = (i % 2 == 1) and tocolor(30, 30, 30, a * 150) or tocolor(35, 35, 35, a * 150)
        local r, g, b = 255, 80, 150 -- Default pink
        local nameCol = tc(220, 220, 220, a * 255)
        
        if dataIndex == 1 then
            r, g, b = 241, 196, 15 -- Gold
            bg = tc(r, g, b, a * 30)
            nameCol = tc(r, g, b, a * 255)
        elseif dataIndex == 2 then
            r, g, b = 189, 195, 199 -- Silver
            bg = tc(r, g, b, a * 30)
            nameCol = tc(r, g, b, a * 255)
        elseif dataIndex == 3 then
            r, g, b = 211, 84, 0 -- Bronze
            bg = tc(r, g, b, a * 30)
            nameCol = tc(r, g, b, a * 255)
        end
        
        dxDrawRectangle(panelX, ry, panelW, rowH, bg)
        
        local pRank = tostring(dataIndex)
        local pName = p.charactername or "Bilinmeyen"
        local pHours = tonumber(p.hoursplayed) or 0
        
        -- Draw Rank
        if dataIndex <= 3 then
            dxDrawText("#"..pRank, bx + cxRank, ry, bx + cxRank + math.floor(50*scale), ry + rowH, tc(r, g, b, a * 255), 1, fontCol, "left", "center")
        else
            dxDrawText("#"..pRank, bx + cxRank, ry, bx + cxRank + math.floor(50*scale), ry + rowH, tc(200, 200, 200, a * 255), 1, fontCol, "left", "center")
        end
        
        -- Draw Name
        dxDrawText(pName, bx + cxName, ry, bx + cxHour, ry + rowH, nameCol, 1, fontRow, "left", "center", true)
        
        -- Empty Track Bar
        local barH = math.floor(10 * scale)
        local trackY = ry + math.floor((rowH - barH) / 2)
        local trackX = panelX + panelW - padX - maxBarW
        dxDrawRectangle(trackX, trackY, maxBarW, barH, tocolor(10, 10, 10, a * 150))
        
        -- Draw Bar Graph (Gradient)
        local fillW = math.max(2, math.floor((pHours / maxHours) * maxBarW))
        local barX = panelX + panelW - padX - fillW
        
        drawGradientBar(barX, trackY, fillW, barH, r, g, b, a * 200)
        
        -- Draw Hours Text
        dxDrawText(tostring(pHours), bx + cxHour, ry, trackX - math.floor(12*scale), ry + rowH, tc(255, 255, 255, a * 255), 1, fontRow, "right", "center")
    end
    
    -- Scrollbar
    if totalPlayers > maxDisplay then
        local scrollTotal = totalPlayers - maxDisplay
        local scrollTrackH = listH
        local thumbH = math.max(20 * scale, (maxDisplay / totalPlayers) * scrollTrackH)
        local thumbY = lY + (scrollOffset / scrollTotal) * (scrollTrackH - thumbH)
        
        -- Scroll Track
        dxDrawRectangle(panelX + panelW - math.floor(4*scale), lY, math.floor(4*scale), scrollTrackH, tc(20, 20, 20, a * 150))
        -- Scroll Thumb
        dxDrawRectangle(panelX + panelW - math.floor(4*scale), thumbY, math.floor(4*scale), thumbH, tc(255, 80, 150, a * 200))
    end
    
    -- Footer (My Rank)
    local fY = lY + listH
    -- Separator
    dxDrawRectangle(panelX, fY, panelW, 1, tocolor(26, 188, 156, a * 150))
    dxDrawRoundedRectangle(panelX, fY + 1, panelW, footerH - 1, math.floor(12 * scale), tc(15, 35, 30, a * 240))
    -- Cover top corners of footer
    dxDrawRectangle(panelX, fY + 1, panelW, math.floor(12 * scale), tc(15, 35, 30, a * 240))
    
    dxDrawText("#"..tostring(myRank), bx + cxRank, fY, bx + cxRank + math.floor(50*scale), fY + footerH, tc(26, 188, 156), 1, fontCol, "left", "center")
    dxDrawText(myNameCached .. " (Sen)", bx + cxName, fY, bx + cxHour, fY + footerH, tc(26, 188, 156), 1, fontRow, "left", "center", true)
    
    local barH = math.floor(10 * scale)
    local trackY = fY + math.floor((footerH - barH) / 2)
    local trackX = panelX + panelW - padX - maxBarW
    dxDrawRectangle(trackX, trackY, maxBarW, barH, tocolor(5, 15, 12, a * 150))
    
    local fillW = math.max(2, math.floor((myHoursCached / maxHours) * maxBarW))
    local barX = panelX + panelW - padX - fillW
    drawGradientBar(barX, trackY, fillW, barH, 26, 188, 156, a * 200)
    dxDrawText(tostring(myHoursCached), bx + cxHour, fY, panelX + panelW - padX - maxBarW - math.floor(12*scale), fY + footerH, tc(26, 188, 156), 1, fontRow, "right", "center")

end

local lastToggle = 0
addEventHandler("onClientKey", root, function(button, state)
    if exports.pav_secure:getData(localPlayer, "loggedin") ~= 1 then return end
    if button == "F5" and state then
        if isChatBoxInputActive() or isConsoleActive() or isMainMenuActive() then return end
        cancelEvent()
        
        local now = getTickCount()
        if now - lastToggle < 500 then return end
        lastToggle = now

        if isVisible then
            targetAlpha = 0
            exports.pav_secure:setData(localPlayer, "hudkapa", false, false)
            pcall(function() exports.pav_chat:chatVisible(true) end)
            pcall(function() exports.pav_hud:setHudVisible(true) end)
            toggleControl("radio_next", true)
            toggleControl("radio_previous", true)
            toggleControl("fire", true)
            toggleControl("aim_weapon", true)
        else
            isVisible = true
            targetAlpha = 1
            scrollOffset = 0
            
            -- Cache values ONCE to save CPU inside the render loop!
            myNameCached = (exports.pav_secure:getData(localPlayer, "fakename") or (getPlayerName(localPlayer):gsub("_", " ")))
            myHoursCached = tonumber(exports.pav_secure:getData(localPlayer, "hoursplayed")) or 0
            
            triggerServerEvent("pav_toptime:requestData", localPlayer)
            
            removeEventHandler("onClientRender", root, renderTopTime)
            addEventHandler("onClientRender", root, renderTopTime, true, "low-3")
            
            exports.pav_secure:setData(localPlayer, "hudkapa", true, false)
            pcall(function() exports.pav_chat:chatVisible(false) end)
            pcall(function() exports.pav_hud:setHudVisible(false) end)
            toggleControl("radio_next", false)
            toggleControl("radio_previous", false)
            toggleControl("fire", false)
        end
    end
end)

bindKey("mouse_wheel_up", "down", function()
    if isVisible and currentAlpha > 0.5 then
        if scrollOffset > 0 then
            scrollOffset = scrollOffset - 1
        end
    end
end)

bindKey("mouse_wheel_down", "down", function()
    if isVisible and currentAlpha > 0.5 then
        local maxDisplay = 10
        if #topPlayers > maxDisplay and scrollOffset < #topPlayers - maxDisplay then
            scrollOffset = scrollOffset + 1
        end
    end
end)
