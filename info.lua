local image = require("image")
local event = require("event")
local unicode = require("unicode")
local fs = require("filesystem")
local component = require("component")
local gpu = require("component").gpu

------------------------------------------------------------------------------------------------------------------

local function getCurrentScript()
  local info
  for runLevel = 0, math.huge do
    info = debug.getinfo(runLevel)
    if info then
      if info.what == "main" then
        return info.source:sub(2, -1)
      end
    else
      error("Failed to get debug info for runlevel " .. runLevel)
    end
  end
end

local function getScaledResolution(scale)
  if scale > 1 then
    scale = 1
  elseif scale < 0.1 then
    scale = 0.1
  end
  local function calculateAspect(screens)
    local abc = 12
    if screens == 2 then
      abc = 28
    elseif screens > 2 then
      abc = 28 + (screens - 2) * 16
    end
    return abc
  end
  local xScreens, yScreens = component.proxy(component.gpu.getScreen()).getAspectRatio()
  local xPixels, yPixels = calculateAspect(xScreens), calculateAspect(yScreens)
  local proportion = xPixels / yPixels
  local xMax, yMax = component.gpu.maxResolution()
  local newWidth, newHeight
  if proportion >= 1 then
    newWidth = xMax
    newHeight = math.floor(newWidth / proportion / 2)
  else
    newHeight = yMax
    newWidth = math.floor(newHeight * proportion * 2)
  end
  local optimalNewWidth, optimalNewHeight = newWidth, newHeight
  if optimalNewWidth > xMax then
    local difference = newWidth / xMax
    optimalNewWidth = xMax
    optimalNewHeight = math.ceil(newHeight / difference)
  end
  if optimalNewHeight > yMax then
    local difference = newHeight / yMax
    optimalNewHeight = yMax
    optimalNewWidth = math.ceil(newWidth / difference)
  end
  local finalNewWidth, finalNewHeight = math.floor(optimalNewWidth * scale), math.floor(optimalNewHeight * scale)
  return finalNewWidth, finalNewHeight
end

local function square(x,y,width,height,color)
  component.gpu.setBackground(color)
  component.gpu.fill(x,y,width,height," ")
end

local function drawButton(x,y,width,height,text,backColor,textColor)
  local textPosX = math.floor(x + width / 2 - unicode.len(text) / 2)
  local textPosY = math.floor(y + height / 2)
  square(x,y,width,height,backColor)
  component.gpu.setForeground(textColor)
  component.gpu.set(textPosX,textPosY,text)
  return x, y, (x + width - 1), (y + height - 1)
end

local function srollBar(x, y, width, height, countOfAllElements, currentElement, backColor, frontColor)
  local sizeOfScrollBar = math.ceil(1 / countOfAllElements * height)
  local displayBarFrom = math.floor(y + height * ((currentElement - 1) / countOfAllElements))
  square(x, y, width, height, backColor)
  square(x, displayBarFrom, width, sizeOfScrollBar, frontColor)
  sizeOfScrollBar, displayBarFrom = nil, nil
end

local function hideFileFormat(path)
  local name = fs.name(path)
  local starting, ending = string.find(name, "(.)%.[%d%w]*$")
  if starting == nil then
    return nil
  else
    return unicode.sub(name, 1, unicode.len(name) - unicode.len(unicode.sub(name,starting + 1, -1)))
  end
  name, starting, ending = nil, nil, nil
end

local function stringLimit(mode, text, size, noDots)
  if unicode.len(text) <= size then return text end
  local length = unicode.len(text)
  if mode == "start" then
    if noDots then
      return unicode.sub(text, length - size + 1, -1)
    else
      return "…" .. unicode.sub(text, length - size + 2, -1)
    end
  else
    if noDots then
      return unicode.sub(text, 1, size)
    else
      return unicode.sub(text, 1, size - 1) .. "…"
    end
  end
end

local function clickedAtArea(x,y,sx,sy,ex,ey)
  if (x >= sx) and (x <= ex) and (y >= sy) and (y <= ey) then return true end    
  return false
end

local function prepareToExit()
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  os.execute("cls")
end

local function xml_parseargs(s)
  local arg = {}
  string.gsub(s, "([%-%w]+)=([\"'])(.-)%2", function (w, _, a)
    arg[w] = a
  end)
  return arg
end
    
local function xml_collect(s)
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,label,xarg, empty
  local i, j = 1, 1
  while true do
    ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then
      table.insert(top, {label=label, xarg=xml_parseargs(xarg), empty=1})
    elseif c == "" then
      top = {label=label, xarg=xml_parseargs(xarg)}
      table.insert(stack, top)
    else
      local toclose = table.remove(stack)
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..label)
      end
      if toclose.label ~= label then
        error("trying to close "..toclose.label.." with "..label)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[#stack].label)
  end
  return stack[1]
end

------------------------------------------------------------------------------------------------------------------

local config = {
  scale = 1, --0.63,
  leftBarWidth = 20,
  scrollSpeed = 6,
  pathToInfoPanelFolder = fs.path(getCurrentScript()) .. "Pages/",
  colors = {
    leftBar = 0xEEEEEE,
    leftBarText = 0x262626,
    leftBarSelection = 0x00C6FF,
    leftBarSelectionText = 0xFFFFFF,
    scrollbarBack = 0xEEEEEE,
    scrollbarPipe = 0x3366CC,
    background = 0x262626,
    text = 0xFFFFFF,
  },
}

local xOld, yOld = gpu.getResolution()
component.gpu.setResolution(getScaledResolution(config.scale))
local xSize, ySize = gpu.getResolution()

fs.makeDirectory(config.pathToInfoPanelFolder)
local currentFile = 1
local stroki = {}
local currentString = 1
local stringsHeightLimit = ySize - 2
local stringsWidthLimit = xSize - config.leftBarWidth - 4

------------------------------------------------------------------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
  obj[class] = obj[class] or {}
  obj[class][name] = {...}
end

local function drawLeftBar()
  fileList = {}
  local list = fs.list(config.pathToInfoPanelFolder)
  for file in list do
    table.insert(fileList, file)
  end
  obj["Files"] = {}
  local yPos = 1, 1
  for i = 1, #fileList do
    if i == currentFile then
      newObj("Files", i, drawButton(1, yPos, config.leftBarWidth, 3, hideFileFormat(fileList[i]), config.colors.leftBarSelection, config.colors.leftBarSelectionText))
    else
      if i % 2 == 0 then
        newObj("Files", i, drawButton(1, yPos, config.leftBarWidth, 3, stringLimit("end", hideFileFormat(fileList[i]), config.leftBarWidth - 2), config.colors.leftBar, config.colors.leftBarText))
      else
        newObj("Files", i, drawButton(1, yPos, config.leftBarWidth, 3, stringLimit("end", hideFileFormat(fileList[i]), config.leftBarWidth - 2), config.colors.leftBar - 0x111111, config.colors.leftBarText))
      end
    end
    yPos = yPos + 3
  end
  square(1, yPos, config.leftBarWidth, ySize - yPos + 1, config.colors.leftBar)
end

local function loadFile()
  currentString = 1
  stroki = {}
  local file = io.open(config.pathToInfoPanelFolder .. fileList[currentFile], "r")
  for line in file:lines() do table.insert(stroki, xml_collect(line)) end
  file:close()
end

local function drawMain()
  local x, y = config.leftBarWidth + 3, 2
  local xPos, yPos = x, y
  square(xPos, yPos, xSize - config.leftBarWidth - 5, ySize, config.colors.background)
  gpu.setForeground(config.colors.text)
  for line = currentString, (stringsHeightLimit + currentString - 1) do
    if stroki[line] then
      for i = 1, #stroki[line] do
        if type(stroki[line][i]) == "table" then
          if stroki[line][i].label == "color" then
            gpu.setForeground(tonumber(stroki[line][i][1]))
          elseif stroki[line][i].label == "image" then
            local bg, fg = gpu.getBackground(), gpu.getForeground()
            local picture = image.load(stroki[line][i][1])
            image.draw(xPos, yPos, picture)
            yPos = yPos + picture.height - 1
            gpu.setForeground(fg)
            gpu.setBackground(bg)
          end
        else
          gpu.set(xPos, yPos, stroki[line][i])
          xPos = xPos + unicode.len(stroki[line][i])
        end
      end
      yPos = yPos + 1
      xPos = x
    else
      break
    end
  end
end

local function drawScrollBar()
  local name
  name = "▲"; newObj("Scroll", name, drawButton(xSize - 2, 1, 3, 3, name, config.colors.leftBarSelection, config.colors.leftBarSelectionText))
  name = "▼"; newObj("Scroll", name, drawButton(xSize - 2, ySize - 2, 3, 3, name, config.colors.leftBarSelection, config.colors.leftBarSelectionText))
  srollBar(xSize - 2, 4, 3, ySize - 6, #stroki, currentString, config.colors.scrollbarBack, config.colors.scrollbarPipe)
end

------------------------------------------------------------------------------------------------------------------

prepareToExit()
drawLeftBar()
loadFile()
drawMain()
drawScrollBar()

while true do
  local e = {event.pull()}
  if e[1] == "touch" then
    for key in pairs(obj["Files"]) do
      if clickedAtArea(e[3], e[4], obj["Files"][key][1], obj["Files"][key][2], obj["Files"][key][3], obj["Files"][key][4]) then
        currentFile = key
        loadFile()
        drawLeftBar()
        drawMain()
        drawScrollBar()
        break
      end
    end
    for key in pairs(obj["Scroll"]) do
      if clickedAtArea(e[3], e[4], obj["Scroll"][key][1], obj["Scroll"][key][2], obj["Scroll"][key][3], obj["Scroll"][key][4]) then
        drawButton(obj["Scroll"][key][1], obj["Scroll"][key][2], 3, 3, key, config.colors.leftBarSelectionText, config.colors.leftBarSelection)
        os.sleep(0.2)
        drawButton(obj["Scroll"][key][1], obj["Scroll"][key][2], 3, 3, key, config.colors.leftBarSelection, config.colors.leftBarSelectionText)
        if key == "▲" then
          if currentString > config.scrollSpeed then
            currentString = currentString - config.scrollSpeed
            drawMain()
            drawScrollBar()
          end
        else
          if currentString < (#stroki - config.scrollSpeed + 1) then
            currentString = currentString + config.scrollSpeed
            drawMain()
            drawScrollBar()
          end
        end
        break
      end
    end
  elseif e[1] == "key_down" then
    if e[4] == 28 then --Enter
      gpu.setResolution(xOld, yOld)
      prepareToExit()
      return
    end
  end
end