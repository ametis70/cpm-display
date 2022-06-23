local http = require("socket.http")
local ltn12 = require("ltn12")

local M = {}

M.get = function(u)
    local t = {}
    local _, code = http.request {
        url = u,
        sink = ltn12.sink.table(t),
        redirect = false
    }
    return table.concat(t), code
end

return M
