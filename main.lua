local timer = 0
local current_image = nil
local current_image_alpha = 0
local next_image = nil
local next_image_alpha = 0
local last_image_change_time = nil

local IMAGE_DURATION = os.getenv("IMAGE_DURATION")
local WIDTH = os.getenv("WIDTH")
local HEIGHT = os.getenv("HEIGHT")

local required_env = {'SERVER_ADDRESS', 'IMAGE_DURATION', 'WIDTH', 'HEIGHT'}
local should_exit_early = false
for _, env_var in pairs(required_env) do
    if not os.getenv(env_var) then
        print("Must provide env var: " .. env_var)
        should_exit_early = true
    end
end

if should_exit_early then os.exit(1) end

local downloader = nil
function start_downloader()
    if downloader then return end
    downloader = love.thread.newThread('downloader.lua')
    downloader:start()
end

function love.load() love.window.setMode(WIDTH, HEIGHT) end

function love.update(dt)
    timer = timer + dt

    start_downloader()

    -- Throw error on thread error
    local downloader_error = downloader:getError()
    assert(not downloader_error, downloader_error)

    -- JSON debugging
    --
    -- local json = love.thread.getChannel('json'):pop()
    -- if json then
    --     print(json.url)
    --     print(json.timestamp)
    -- end

    -- Get image from downlaoder thread
    local downloader_data = love.thread.getChannel('image'):pop()
    if downloader_data then
        local image_bytes = love.filesystem.newFileData(downloader_data,
                                                        'image.jpg')
        next_image = love.graphics.newImage(image_bytes)
    end

    -- Update next_image
    if next_image and next_image_alpha < 1 then
        next_image_alpha = next_image_alpha + dt
    end

    -- Update current_image
    if current_image then
        if next_image and current_image_alpha > 0 then
            current_image_alpha = current_image_alpha - dt
        elseif not next_image and current_image_alpha < 1 then
            current_image_alpha = current_image_alpha + dt
        end
    end

    -- Switch next_image for current_image
    if next_image_alpha >= 1 then
        current_image = next_image
        next_image = nil
        current_image_alpha = 1
        next_image_alpha = 0
        last_image_change_time = timer;
    end

    if last_image_change_time ~= nil and timer > last_image_change_time +
        IMAGE_DURATION then
        last_image_change_time = nil
        downloader = nil
        start_downloader()
    end
end

function love.draw()
    if next_image then
        love.graphics.setColor(1, 1, 1, next_image_alpha)
        local sx = love.graphics.getHeight() / next_image:getWidth()
        local sy = love.graphics.getWidth() / next_image:getHeight()

        love.graphics.draw(next_image, love.graphics.getWidth(), 0,
                           math.rad(90), sx, sy)
    end

    if current_image then
        love.graphics.setColor(1, 1, 1, current_image_alpha)
        local sx = love.graphics.getHeight() / current_image:getWidth()
        local sy = love.graphics.getWidth() / current_image:getHeight()
        love.graphics.draw(current_image, love.graphics.getWidth(), 0,
                           math.rad(90), sx, sy)
    end
end

function love.quit()
    if downloader and downloader:isRunning() then downloader:release() end
end
