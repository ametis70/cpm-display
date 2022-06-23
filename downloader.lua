local JSON = require('third_party.json')
local http = require('http')
local server_address = os.getenv("SERVER_ADDRESS")

local raw_json, json_code = http.get(server_address .. '/processed/random')
if not raw_json then error(json_code) end

local json = JSON:decode(raw_json)

if not json.url then error("No url found") end

-- JSON debugging
--
-- love.thread.getChannel('json'):push(json)

local raw_image, image_code = http.get(server_address .. json.url)
if not raw_image then error(image_code) end

love.thread.getChannel('image'):push(raw_image)
