-- ==========================================
-- CẤU HÌNH WEBHOOK (Điền link của cậu vào đây)
-- ==========================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1524249194657742859/mvf4OxcYgB8qNNJVYjGxwW_ZAN5PA9f5Mb6kma5R8MhvrXPbcwh6KBuCE2E5k7KuQHOs"

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

-- Hàm gửi tin nhắn khởi động
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

-- ==========================================
-- ✅ ĐÃ BỔ SUNG: Hàm sendDiscord dùng chung cho Dự báo
-- ==========================================
local function sendDiscord(embedData)
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc or WEBHOOK_URL == "" then return end

    pcall(function()
        requestFunc({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                embeds = {{
                    title = embedData.title,
                    description = embedData.description,
                    color = tonumber(0xFF3B3B)
                }}
            })
        })
    end)
end

-- Hàm gửi thông báo thời tiết
local function sendNotification(weather)
    if WEBHOOK_URL == "" or WEBHOOK_URL == "THÊM_LINK_WEBHOOK_DISCORD_CỦA_CẬU_VÀO_ĐÂY" then
        warn("[Kyzen] Cậu quên chưa điền Link Webhook kìa!")
        return
    end

    local currentTime = os.date("%H:%M:%S")
    
    local eventIcon = Icons[weather] or "🔔"

    local webhookData = {
        ["content"] = "", 
        ["embeds"] = {{
            ["title"] = eventIcon .. " " .. tostring(weather), 
            ["description"] = "Phát hiện thay đổi thời tiết!",
            ["color"] = tonumber(0xFF3B3B), 
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

    if success and response then
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

-- Chạy thử các hàm ngay khi load
sendStartup()
onWeatherChanged()
workspace:GetAttributeChangedSignal("ActiveWeather"):Connect(onWeatherChanged)

-- ==============================
-- KYZEN Moon Predictor
-- ==============================

local CYCLE_TIME = 600 -- 10 phút
local NIGHT_ORDER = 3

local RareMoons = {
    ["Bloodmoon"] = {Icon="🔴"},
    ["Goldmoon"] = {Icon="🪙"},
    ["Rainbow Moon"] = {Icon="🌈"},
    ["Mega Moon"] = {Icon="💥"},
}

local MoonTable = {
    {Name="Moon",Chance=79},
    {Name="Bloodmoon",Chance=2},
    {Name="Goldmoon",Chance=13},
    {Name="Rainbow Moon",Chance=6},
    {Name="Mega Moon",Chance=2},
}

local function PickMoon(seed)
    local rng=Random.new(seed)

    local total=0
    for _,v in ipairs(MoonTable) do
        total+=v.Chance
    end

    local roll=rng:NextNumber()*total

    local current=0
    for _,v in ipairs(MoonTable) do
        current+=v.Chance
        if roll<=current then
            return v.Name
        end
    end

    return "Moon"
end

local Predicted = {}

local function BuildPrediction(hours)

    table.clear(Predicted)

    local now = os.time()

    -- Canh đúng mốc cycle 10 phút
    local first = now - (now % CYCLE_TIME)

    local finish = first + (hours * 3600)

    for t = first, finish, CYCLE_TIME do

        local cycleID = math.floor(t / CYCLE_TIME)

        local moon = PickMoon(cycleID * 1000 + NIGHT_ORDER)

        if RareMoons[moon] then

            table.insert(Predicted,{
                Name = moon,
                Icon = RareMoons[moon].Icon,
                Time = t,
                Warned = false
            })

        end

    end

    -- Gửi dự báo lên Discord
    local text = ""

    for _,v in ipairs(Predicted) do
        text ..= string.format(
            "%s %s %s\n",
            os.date("%H:%M", v.Time),
            v.Icon,
            v.Name
        )
    end

    if text == "" then text = "Không có Event Rare nào trong 24h tới." end

    sendDiscord({
        title = "🌙 Moon Prediction (24h)",
        description = text
    })

end

print("======================================")

BuildPrediction(24)

-- Vòng lặp báo trước 5 phút
task.spawn(function()
    while true do
        local now = os.time()

        for _,moon in ipairs(Predicted) do
            local remain = moon.Time - now

            if remain <= 300 and remain > 0 and not moon.Warned then
                moon.Warned = true

                sendNotification(string.format(
                    "⚠️ %s sẽ xuất hiện sau %d phút!",
                    moon.Name,
                    math.ceil(remain / 60)
                ))
            end
        end

        task.wait(1)
    end
end)

-- Vòng lặp cập nhật dự báo
task.spawn(function()
    while true do
        local waitTime = CYCLE_TIME - (os.time() % CYCLE_TIME)
        task.wait(waitTime + 1)
        BuildPrediction(24)
    end
end)
