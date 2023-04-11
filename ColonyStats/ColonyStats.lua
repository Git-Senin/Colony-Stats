-- ColonyStats.lua
-- 2023-04-11
--
-- The following is required for setup:
--   * 1 ComputerCraft Computer
--   * 1 or more ComputerCraft Monitors (recommend 3x3 monitors)
--   * 1 Advanced Peripheral Colony Integrator
--
-- init

print("\n--------------------")
print("Running Colony Stats")
print("\n--------------------")

local monitor = peripheral.find("monitor")
if not monitor then error("Monitor not found.") end
monitor.setTextScale(0.5)
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setCursorBlink(true)
print("Monitor           initialized.")

-- init colony integrator
local colony = peripheral.find("colonyIntegrator")
if not colony then error("Colony Integrator not found.") end
if not colony.isInColony then error("Colony Integrator is not in a colony.") end
print("Colony Integrator initialized.")

-- Prints to the screen one row after another, scrolling the screen when
-- reaching the bottom. Acts as a normal display where text is printed in
-- a standard way. Long lines are not wrapped and newlines are printed as
-- spaces, both to be addressed in a future update.
-- NOTE: No longer used in this program.
function mPrintScrollable(mon, ...)
    w, h = mon.getSize()
    x, y = mon.getCursorPos()

    -- Blink the cursor like a normal display.
    mon.setCursorBlink(true)

    -- For multiple strings, append them with a space between each.
    for i = 2, #arg do t = t.." "..arg[i] end
    mon.write(arg[1])
    if y >= h then
        mon.scroll(1)
        mon.setCursorPos(1, y)
    else
        mon.setCursorPos(1, y+1)
    end
end

-- Prints strings left, centered, or right justified at a specific row and
-- specific foreground/background color.
function mPrintRowJustified(mon, y, pos, text, ...)
    w, h = mon.getSize()
    fg = mon.getTextColor()
    bg = mon.getBackgroundColor()

    if pos == "left" then x = 1 end
    if pos == "center" then x = math.floor((w - #text) / 2) end
    if pos == "right" then x = w - #text end

    if #arg > 0 then mon.setTextColor(arg[1]) end
    if #arg > 1 then mon.setBackgroundColor(arg[2]) end
    mon.setCursorPos(x, y)
    mon.write(text)
    mon.setTextColor(fg)
    mon.setBackgroundColor(bg)
end
-- Utility function that displays current time and remaining time on timer.
-- For time of day, yellow is day, orange is sunset/sunrise, and red is night.
-- The countdown timer is orange over 15s, yellow under 15s, and red under 5s.
-- At night, the countdown timer is red and shows PAUSED insted of a time.
function displayTimer(mon, t)
    now = os.time()

    cycle = "day"
    cycle_color = colors.orange
    if now >= 4 and now < 6 then
        cycle = "sunrise"
        cycle_color = colors.orange
    elseif now >= 6 and now < 18 then
        cycle = "day"
        cycle_color = colors.yellow
    elseif now >= 18 and now < 19.5 then
        cycle = "sunset"
        cycle_color = colors.orange
    elseif now >= 19.5 or now < 5 then
        cycle = "night"
        cycle_color = colors.red
    end

    timer_color = colors.orange
    if t < 15 then timer_color = colors.yellow end
    if t < 5 then timer_color = colors.red end

    mPrintRowJustified(mon, 1, "left", string.format("Time: %s [%s]    ", textutils.formatTime(now, false), cycle), cycle_color)
    if cycle ~= "night" then mPrintRowJustified(mon, 1, "right", string.format("    Remaining: %ss", t), timer_color)
    else mPrintRowJustified(mon, 1, "right", "    Remaining: PAUSED", colors.red) end
end
-- Prints bar width of monitor with specific percent and color
function mPrintBar(mon, y, percent, fillColor)
    w, h = mon.getSize()
    fg = mon.getTextColor()
    bg = mon.getBackgroundColor()

    bar = ""
    for i = 1, w - 4 do
        bar = bar.." " 
    end 

    barFill = ""
    for i = 1, w - 4 do 
        if i / w > (percent / 100) then
            break 
        end
        barFill = barFill.." "
    end

    mon.setCursorPos(2, y)
    mon.setBackgroundColor(colors.white)
    mon.write(bar)

    mon.setCursorPos(2, y)
    mon.setBackgroundColor(fillColor)
    mon.write(barFill)

    mon.setTextColor(fg)
    mon.setBackgroundColor(bg)
end
function stats() 
    monitor.clear()
    local citizenTable = colony.getCitizens()
    local visitorTable = colony.getVisitors()
    local buildingTable = colony.getBuildings()
    -----------------------------------------------------------------------------------
    -- Stats
    -----------------------------------------------------------------------------------
    local statsY = 3
    
    -- Citizen Count
    mPrintRowJustified(monitor, statsY, "left", "Citizens: "..#citizenTable, colors.white)
    statsY = statsY + 1
    -- Ages
    local citizenAdult = 0
    local citizenChild = 0
    for i, citizen in ipairs(citizenTable) do
        if citizen.age == "adult" then
            citizenAdult = citizenAdult + 1
        else
            citizenChild = citizenChild + 1
        end
    end
    mPrintRowJustified(monitor, statsY, "left", "\t".."Adults: "..citizenAdult, colors.lightBlue)
    statsY = statsY + 1
    mPrintRowJustified(monitor, statsY, "left", "\t".."Children: "..citizenChild, colors.lightBlue)
    statsY = statsY + 1

    -- Visitors
    mPrintRowJustified(monitor, statsY, "left", "Visitors: "..#visitorTable, colors.white)
    statsY = statsY + 1

    -- Buildings
    mPrintRowJustified(monitor, statsY, "left", "Buildings: "..#buildingTable, colors.white)
    statsY = statsY + 1

    -- being worked on
    local buildingsBeingWorkedOn = {};
    for i, building in ipairs(buildingTable) do
        if building.isWorkingOn then table.insert(buildingsBeingWorkedOn, building) end
    end
    mPrintRowJustified(monitor, statsY, "right", "\t".."Being Worked On: "..#buildingsBeingWorkedOn, colors.lightBlue)
    statsY = statsY + 1
    for i, building in ipairs(buildingsBeingWorkedOn) do 
        mPrintRowJustified(monitor, statsY, "right", "\t".."\t"..string.upper(string.sub(building.type, 1, 1))..string.sub(building.type, 2).." "..building.level.." -> "..building.level+1, colors.blue)
        statsY = statsY + 1
    end





    -----------------------------------------------------------------------------------
    -- Bars
    -----------------------------------------------------------------------------------
    local barsY = statsY;

    -- Saturation
    local saturationY = barsY + 1
    local saturationPercentage = 0
    local saturationColor = colors.green
    for i, citizen in ipairs(citizenTable) do 
        saturationPercentage = saturationPercentage + citizen.saturation
    end
    saturationPercentage = (saturationPercentage / #citizenTable) / 20 * 100
    mPrintRowJustified(monitor, saturationY, "center", "Saturation: "..string.format("%.2f",saturationPercentage).."%", saturationColor)
    mPrintBar(monitor, saturationY + 1, saturationPercentage, saturationColor)

    -- Happiness
    local happinessY = barsY + 4
    local happinessPercentage = 0
    local happinessColor = colors.yellow 
    for i, citizen in ipairs(citizenTable) do 
        happinessPercentage = happinessPercentage + citizen.happiness
    end
    happinessPercentage = (happinessPercentage / #citizenTable) / 10 * 100
    mPrintRowJustified(monitor, happinessY, "center", "Happiness: "..string.format("%.2f",happinessPercentage).."%", happinessColor)
    mPrintBar(monitor, happinessY + 1, happinessPercentage, happinessColor)
    
end

--------------------------------------------------------
-- Main
--------------------------------------------------------

 

local time_between_runs = 30
local current_run = time_between_runs
displayTimer(monitor, current_run)
stats()
local TIMER = os.startTimer(1)

while true do
    local e = {os.pullEvent()}
    if e[1] == "timer" and e[2] == TIMER then
        now = os.time()
        if now >= 5 and now < 19.5 then
            current_run = current_run - 1
            if current_run <= 0 then
                stats() 
                current_run = time_between_runs
            end
        end
        displayTimer(monitor, current_run)
        TIMER = os.startTimer(1)
    elseif e[1] == "monitor_touch" then
        os.cancelTimer(TIMER)
        stats()
        current_run = time_between_runs
        displayTimer(monitor, current_run)
        TIMER = os.startTimer(1)
    end
end