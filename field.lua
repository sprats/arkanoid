---------------------------------------------------------------------------------
--
-- field.lua
--
---------------------------------------------------------------------------------
BRICKS_COUNT = 10
POINTS_MULTIPLIER = 10

local field_w, field_h = display.contentWidth, display.contentHeight
LEFT_BORDER_X = -field_w * 0.01
RIGHT_BORDER_X = field_w * 1.01

table.print = require('print_r')
table.unpack = require('unpack_table')
table.reverse = require('table_reverse')

local physics = require('physics')
physics.start()
physics.setTimeStep( 0 )


local background_music = audio.loadStream( "background.mp3" )
local lose_sound = audio.loadSound( "lose.mp3" )
local win_sound = audio.loadSound( "win.mp3" )
local explosion = audio.loadSound( "explosion.mp3" )
local backgroundMusicChannel = audio.play( background_music, { channel=1, loops=-1, fadein=2000 } )


local data = { 
    ['points'] = 0,
    ['lives'] = 3,
    ['level'] = 1,
}

local options =
{
    width = 474 / 4 + 1,
    height = 41,
    numFrames = 4,

    --optional parameters; used for scaled content support
    sheetContentWidth = 480,
    sheetContentHeight = 42
}

local default_slots_x = {}
for i = 1, BRICKS_COUNT do
    --table.insert(default_slots_x,  0.20 * (i-1))
    table.insert(default_slots_x, 0.1 + 0.20 * (i-1))
end

local default_slots_y = {}
for i = 1, 4 do
    table.insert(default_slots_y, 0.1 + 0.13 * (i-1))
end

local sequenceData = {
            name = 'bricks',
            frames = {1, 2, 3, 4},
            time = 1240,
            loopCount = 5
        }



local base = display.newImage("base.png", display.contentCenterX, display.contentCenterY * 1.7)
physics.addBody( base, "static", { density=1, friction=0.1, bounce=1 } )
base:scale(1, 1)

local ball = display.newImage("ball.png", display.contentCenterX, display.contentCenterY * 1.7)
physics.addBody( ball, "dynamic", { bounce=0.0, radius=25 } )
ball._in_action = false
ball:scale(0.5, 0.5)

local imageSheet = graphics.newImageSheet( 'bricks.png', options )

-----------------------------------
-- functions to generate game field
-----------------------------------
function gen_next_line()
    local function gen_elem(prev_elem)
        local init_list = {1, 2, 3, 4}

        if prev_elem then table.remove(init_list, prev_elem) end
        return init_list[math.random(#init_list)]
    end

    local line = {}
    
    for k = 1, BRICKS_COUNT do
        local prev_elem = line[k-1]
        table.insert(line, gen_elem(prev_elem))    
    end

    return line
end

function gen_field()
    local game_field = {}
    for k = 1, 4 do
        local line = gen_next_line()
        table.insert(game_field, line)
    end

    return game_field
end

-------------------
-- END of the level
-------------------
local function level_end()
    --audio.play( win_sound )

    data.level = data.level + 1
    update_text()
    ball._in_action = false
    reset_ball()
    timer.performWithDelay(1, function() form_slots() end )
end

------------------------------
-- for the collisions 
-- between bricks and the ball
------------------------------
local function after_removing(obj)
    local function check_field_state()
        local flag_finish = true

        for _, row in pairs(slots) do
            for _, elem in pairs(row) do
                if elem.isVisible then flag_finish = false end 
            end
        end

        if flag_finish then 
            level_end()
        end
    end
    
    physics.removeBody(obj)
    obj.isVisible = false
    check_field_state()  
end

-----------------------------
-- initialize all values
-----------------------------
local function init()
    slots = {}

    for i = 1, 4 do
        table.insert(slots, {})
        for j = 1, BRICKS_COUNT do
            local new_slot = display.newSprite( imageSheet, sequenceData )
            new_slot.x = display.contentCenterX * default_slots_x[j]
            new_slot.y = display.contentCenterY * default_slots_y[i]
            new_slot._focus = false

            table.insert(slots[i], new_slot)

            local function on_collision(event)
                local obj = event.target

                if obj._focus == false then
                    obj._focus = true
                    data.points = data.points + POINTS_MULTIPLIER * data.level
                    update_text()
                    --audio.play( explosion )
                    timer.performWithDelay(1, transition.scaleTo( obj, { xScale=0.01, yScale=0.01, time=500, onComplete = after_removing } ) )

                end
            end

            new_slot:addEventListener( "collision", on_collision )
        end
    end

end

-----------------------------
-- to form slots
-----------------------------
function form_slots()
    local game_field = gen_field()

    for i, line in pairs(game_field) do
        for j, elem in pairs(line) do
            local obj = slots[i][j]
            obj:setFrame(elem)
            transition.scaleTo( obj, { xScale=1, yScale=1, time=1 } )
            obj.isVisible = true
            obj._focus = false
            physics.addBody( obj, 'static', {  density=5.0, friction=1, bounce=0.5 })
        end
    end

end

------------------
-- to move a ball
-----------------
local function constantForce()
    local obj = ball
    
    if not obj._in_action then
        return
    end

    if base.x > obj.x then
        obj:applyForce( -2, -5 * data.level, obj.x, obj.y )
    else
        obj:applyForce( 2, -5 * data.level, obj.x, obj.y )
    end
end

------------------------
-- global event handlers
------------------------
local function onGlobalTap(event)
    local obj = ball
    if not obj._in_action then
        obj._in_action = true
        obj:applyForce( 2, -10, obj.x, obj.y )
    end
end


--local function onMouseEvent(event)
local function onTouchEvent(event)
    local x_1 = LEFT_BORDER_X + base.width/2
    local x_2 = RIGHT_BORDER_X - base.width/2

    if (x_1 < event.x) and (event.x < x_2) then    
        base.x = event.x
        if not ball._in_action then ball.x = event.x end
    end
end


--------------------
-- on the round lose
--------------------

function reset_ball()
    physics.removeBody(ball)
    ball.x, ball.y = base.x, base.y - 1
    physics.addBody(ball, "dynamic", { bounce=0.0, radius=25 })
end

function real_handler()
    reset_ball()

    if data.lives > 1 then
        data.lives = data.lives - 1
    else
        data.lives, data.level, data.points = 3, 1, 0
        form_slots()
    end

    audio.play(lose_sound)

    update_text()
end

local function on_round_lose(self, event)
    if (event.phase == 'ended') and (ball._in_action) then
        ball._in_action = false

        -- you can't perform any changes to the object during the 'collision' effect
        -- that's why timer is involved here
        timer.performWithDelay(1, function() real_handler() end )
    end
end


----------------------------
-- borders to the game field
----------------------------

local bound_coords = {
    ['bottom'] = {field_w / 2, field_h, field_w * 2 , 10},
    ['top'] = {field_w / 2, 0, field_w * 2 , 10},
    ['left'] = {LEFT_BORDER_X , 0, 10 , field_h * 2},
    ['right'] = {RIGHT_BORDER_X, 0, 10 , field_h * 2},
}



for key, elem in pairs(bound_coords) do
    local rect = display.newRect( table.unpack(elem) )
    rect:setFillColor(1, 1, 1)
    rect.alpha = 0
    physics.addBody(rect, "static", { density=5.0, friction=1, bounce=0.5 })

    if key == 'bottom' then
        rect.collision = on_round_lose
        rect:addEventListener( "collision", rect )
    end
end


-------------------------------
-- to update text on the screen
-------------------------------
local labels_table = {}

for i = 1, 3 do
    local newText = display.newText("", display.contentCenterX * 0.5 * i, display.contentCenterY * 1.9, native.systemFont, 50)
    newText:setFillColor(1, 1, 1)
    table.insert(labels_table, newText)
end


function update_text()
    local data_info = {['Level'] = data.level, ['Lives'] = data.lives, ['Points'] = data.points, }

    local count = 1
    for key, info in pairs(data_info) do
        local lbl = labels_table[count]
        lbl.text = tostring(key) .. ': ' .. tostring(info)

        count = count + 1
    end
end

-----------------------------
-- just a few event listeners
-----------------------------
Runtime:addEventListener("tap", onGlobalTap)
--Runtime:addEventListener("mouse", onMouseEvent)
Runtime:addEventListener("mouse", onTouchEvent)
Runtime:addEventListener("touch", onTouchEvent)

base:addEventListener("collision", constantForce)

-----------------------------------
-- perform initialization right now
-----------------------------------
init()
form_slots()
update_text()

------------------------------------------
-- to return this module to the main scene
------------------------------------------
local field = {}

return field
