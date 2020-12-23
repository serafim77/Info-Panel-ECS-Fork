local applications = {
  {"serafim77/Info-Panel-ECS-Fork/master/info.lua", "info.lua"},
  {"serafim77/Info-Panel-ECS-Fork/master/image.lua", "image.lua"},
  {"serafim77/Info-Panel-ECS-Fork/master/color.lua", "color.lua"},
  {"serafim77/Info-Panel-ECS-Fork/master/OCIF.lua", "OCIF.lua"},
  {"serafim77/Info-Panel-ECS-Fork/master/Pages/Claims.txt", "Pages/Claims.txt"},
  {"serafim77/Info-Panel-ECS-Fork/master/Pages/Main.txt", "Pages/Main.txt"},
  {"serafim77/Info-Panel-ECS-Fork/master/Pages/Rules.txt", "Pages/Rules.txt"},
  {"serafim77/Info-Panel-ECS-Fork/master/Pages/SSPI.txt", "Pages/SSPI.txt"}
}

os.execute("md Pages")

for i = 1, #applications do
  print("Скачиваю " .. applications[i][2])
  os.execute("wget " .. "https://raw.githubusercontent.com/" .. applications[i][1] .. " " .. applications[i][2] .. " -fQ")
  os.sleep(0.1)
end