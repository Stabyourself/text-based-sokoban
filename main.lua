function love.load()
    entry = ""
    history = {}

    h = love.graphics.getHeight()
    w = love.graphics.getWidth()
    lh = 20

    font = love.graphics.newFont(lh)
    love.graphics.setFont(font)

    cmdlist = {
        n=goUp,
        e=goRight,
        s=goDown,
        w=goLeft,
        north=goUp,
        east=goRight,
        south=goDown,
        west=goLeft,
        up=goUp,
        right=goRight,
        down=goDown,
        left=goLeft,

        see=look,
        look=look,
        find=look,
        examine=look,
        debug=toggleDebug,

        help="Try entering a direction or finding out more about your surroundings.",
        despair="Yes.",
        push="Using state of the art technology, pushing happens automatically when moving in this game. Wow!",
        pull="Surely you jest.",
        test="Test successful. Good job.",
        punch="This isn't that kind of game.",
        fight="With what? There's nothing.",
        fuck="YOU LOSE.",
        undo="You wish.",
        redo="This game has no undo, so why would there be a redo?",
        restart="Close the game and reopen it.",
        analyze="You analyze everything. The walls are made of bricks, the boxes are wood, the switches are the pushy kind and not the Nintendo kind.",
        die="There is no escape.",
        exit="Sokoban levels have no exit.",
        inventory="Your inventory is empty."
    }

    mapStrings = {
        " #####",
        " #SS #",
        "###  #",
        "# B  #",
        "# B ##",
        "#P  # ",
        "##### ",
    }

    map = {}
    -- parse map
    for y, mapString in ipairs(mapStrings) do
        for x = 1, #mapString do
            if not map[x] then
                map[x] = {}
            end

            local char = string.sub(mapString, x, x)

            if char == "P" then
                playerX = x
                playerY = y
                char = " "
            end

            map[x][y] = char
        end
    end

    debug = false
    message("You find yourself in some dank warehouse. The walls are suspiciously grid-aligned. There's boxes all around and switches to push them on")
end

function love.draw()
    love.graphics.print(">" .. entry, 0, h-lh-20)

    local y = h-lh-40
    for i = #history, math.max(1, #history-(h/lh-1)), -1 do
        local _, wrappedText = font:getWrap(history[i], w)
        local th = #wrappedText*lh
        y = y - th - 3

        love.graphics.printf(history[i], 0,  y, w)
    end

    if debug then
        for x = 1, #map do
            for y = 1, #map[1] do
                local char = map[x][y]
                if playerX == x and playerY == y then
                    char = "P"
                end

                love.graphics.print(char, w-200 + x*20, y*20)
            end
        end
    end
end

function love.textinput(text)
    entry = entry .. text
end

function love.keypressed(key)
    if key == "backspace" then
        entry = entry:gsub("[%z\1-\127\194-\244][\128-\191]*$", "")
    end

    if key == "return" then
        parseEntry(entry)
    end
end

function message(msg)
    table.insert(history, msg)
end

function parseEntry(input)
    message(">" .. input)

    isolatedInput = split(input)[1]

    if isolatedInput then
        local cmd = cmdlist[string.lower(isolatedInput)]

        if cmd then
            if type(cmd) == "function" then
                cmd()

            elseif type(cmd) == "string" then
                message(cmd)
            end
        else
            message("I don't know how to " .. input .. ".")
        end
    end

    entry = ""
end

function inMap(x, y)
    return map[x] and y > 0 and y <= #map[x]
end

function goUp()
    move(0, -1)
end

function goRight()
    move(1, 0)
end

function goDown()
    move(0, 1)
end

function goLeft()
    move(-1, 0)
end

function move(x, y)
    local newX = playerX + x
    local newY = playerY + y

    if not inMap(newX, newY) then
        message("I can't do that.")
        return
    end

    if map[newX][newY] == "#" then
        message("I can't do that.")
        return
    end

    if map[newX][newY] == "B" or map[newX][newY] == "G" then
        local newBoxX = newX + x
        local newBoxY = newY + y

        if not inMap(newBoxX, newBoxY) then
            message("I can't do that.")
            return
        end

        if map[newBoxX][newBoxY] == "B" then
            message("I can't do that.")
            return
        end

        if map[newBoxX][newBoxY] == "G" then
            message("I can't do that.")
            return
        end

        if map[newBoxX][newBoxY] == "#" then
            message("I can't do that.")
            return
        end

        if map[newBoxX][newBoxY] == "S" then
            map[newBoxX][newBoxY] = "G"
            message("You pushed the box. You hear a click.")
            checkwin()
        elseif map[newBoxX][newBoxY] == " " then
            map[newBoxX][newBoxY] = "B"
            message("You pushed the box.")
        end

        if map[newX][newY] == "G" then
            map[newX][newY] = "S"
        else
            map[newX][newY] = " "
        end
    else
        message("You moved.")
    end

    playerX = newX
    playerY = newY
end

function checkwin()
    local win = true

    for x = 1, #map do
        for y = 1, #map[1] do
            if map[x][y] == "S" then
                win = false
            end
        end
    end

    if win then
        message("YOU WIN!!!")
    end
end

function look()
    local dirs = {
        North={0, -1},
        East={1, 0},
        South={0, 1},
        West={-1, 0},
    }

    for name, coords in pairs(dirs) do
        local x = playerX
        local y = playerY

        x = x + coords[1]
        y = y + coords[2]

        local object = "outside of the level"
        local dist = 0
        local found = false

        while not found and inMap(x, y) do
            local char = map[x][y]

            if char ~= " " then
                if char == "B" then
                    object = "a box"
                elseif char == "#" then
                    object = "a wall"
                elseif char == "S" then
                    object = "a switch"
                elseif char == "G" then
                    object = "a box on a switch"
                end
                found = true
            end

            x = x + coords[1]
            y = y + coords[2]

            dist = dist + 1
        end

        message(string.format("%s of you, %s %s away you see %s.", name, dist-1, dist==2 and "step" or "steps", object))
    end
end

function toggleDebug()
    debug = not debug
end

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end
