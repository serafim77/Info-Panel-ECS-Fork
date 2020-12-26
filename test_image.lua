local image = require("image")
local gpu = require("component").gpu

os.execute("cls")

--создаём картинку из случайных символов
local img = image.create(10, 10, nil, nil, nil, nil, true)
image.save("1.pic",img)

--отрисовываем созданую картинку
local picture = image.load("1.pic")
image.draw(2, 2, picture)

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
