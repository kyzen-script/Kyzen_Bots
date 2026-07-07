-- ==========================================
-- CẤU HÌNH WEBHOOK (Điền link của cậu vào đây)
-- ==========================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1524046777504895017/c3PJMK19okyD56aV81tcoYqs6bBEzChNcmOB_ZKQ5th556xbHAP7AErseZFby46BajO8"

-- 1. Chờ game load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local HttpService = game:GetService("HttpService")

-- ✅ Cập nhật #2: Đợi workspace.ActiveWeather xuất hiện (Tránh lỗi trả về nil khi inject quá sớm)
local timeout = tick() + 15

while workspace:GetAttribute("ActiveWeather") == nil and tick() < timeout do
    task.wait(0.2)
end

print("🔥 Kyzen Báo Sự Kiện Mutation - Loaded")

-- 3. Khởi tạo lastWeather
local lastWeather = nil

-- ✅ Cập nhật #4: Bảng Icon theo từng Event
local Icons = {
    ["Rain"] = "🌧️",
    ["Lightning"] = "⚡",
    ["Rainbow"] = "🌈",
    ["Snowfall"] = "❄️",
    ["Starfall"] = "⭐",
    ["Aurora"] = "🌌",
    ["Sunburst"] = "☀️",
    ["Bloodmoon"] = "🌕",
    ["Goldmoon"] = "🪙",
    ["Rainbow Moon"] = "🌈🌕",
    ["Mega Moon"] = "💥🌕"
}

local function sendStartup()
    local startupData = {
        content = "🟢 **KYZEN Mutation Tracker Online**\nScript đã khởi động thành công."
    }

    local requestFunc = request or http_request or (syn and syn.request)

    if requestFunc then
        pcall(function()
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(startupData)
            })
        end)
    end
end

local function sendNotification(weather)
    if WEBHOOK_URL == "" or WEBHOOK_URL == "THÊM_LINK_WEBHOOK_DISCORD_CỦA_CẬU_VÀO_ĐÂY" then
        warn("[Kyzen] Cậu quên chưa điền Link Webhook kìa!")
        return
    end

    local currentTime = os.date("%H:%M:%S")
    
    -- Lấy icon tương ứng, nếu event lạ không có trong bảng thì dùng icon mặc định 🔔
    local eventIcon = Icons[weather] or "🔔"

    local webhookData = {
        ["content"] = "", 
        ["embeds"] = {{
            ["title"] = eventIcon .. " " .. tostring(weather), -- ✅ Đã gắn icon vào Title
            ["description"] = "Phát hiện thay đổi thời tiết!",
            ["color"] = tonumber(0xFF3B3B), -- ✅ Cập nhật #3: Đổi sang màu đỏ 
            ["fields"] = {
                {
                    ["name"] = "Sự kiện (Event)",
                    ["value"] = tostring(weather),
                    ["inline"] = true
                },
                {
                    ["name"] = "Thời gian (Time)",
                    ["value"] = currentTime,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Kyzen Auto Tracker"
            }
        }}
    }

    local response
    local success, err = pcall(function()
        local requestFunc = request or http_request or (syn and syn.request) 
        
        if requestFunc then
            response = requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(webhookData)
            })
        else
            error("Executor không hỗ trợ HTTP Request!")
        end
    end)

    -- ✅ Cập nhật #1: Kiểm tra response xem Discord có thực sự nhận thành công hay không
    if success and response then
        -- HTTP code 2xx nghĩa là request thành công
        if response.Success or (response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300) then
            print("[Kyzen] Discord Sent. Đã báo:", weather, "lúc", currentTime)
        else
            warn("[Kyzen] Discord Failed. Mã HTTP:", response.StatusCode, " - Lỗi:", response.Body)
        end
    else
        warn("[Kyzen] Lỗi môi trường Lua hoặc Executor khi gửi Webhook:", err)
    end
end

local function onWeatherChanged()
    local weather = workspace:GetAttribute("ActiveWeather")

    if not weather or weather == "" then
        return
    end

    if weather == lastWeather then
        return
    end

    lastWeather = weather
    sendNotification(weather)
end

sendStartup()

onWeatherChanged()

workspace:GetAttributeChangedSignal("ActiveWeather"):Connect(onWeatherChanged)
