local shell = require("shell")
local fs = require("filesystem")

local applications = {
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/info.lua", "info.lua"},
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/image.lua", "image.lua"},
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/color.lua", "color.lua"},
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/OCIF.lua", "OCIF.lua"},
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/Pages/Claims.txt", "Pages/Claims.txt"},
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/Pages/Main.txt", "Pages/Main.txt"},
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/Pages/Rules.txt", "Pages/Rules.txt"},
  {"https://raw.githubusercontent.com/serafim77/Info-Panel-ECS-Fork/master/Pages/SSPI.txt"} "Pages/SSPI.txt"}
}

for i = 1, #applications do
  print("Скачиваю " .. applications[i][2])
  fs.makeDirectory(fs.path(applications[i][2]) or "")
  shell.execute("wget " .. applications[i][1] .. " " .. applications[i][2] .. " -fQ")
  os.sleep(0.3)
end
print("Готово")
