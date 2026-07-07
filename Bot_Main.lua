--// Mutation Notifier - Delta X
--// Kyzen

local WEBHOOK_URL = "https://discord.com/api/webhooks/1524046777504895017/c3PJMK19okyD56aV81tcoYqs6bBEzChNcmOB_ZKQ5th556xbHAP7AErseZFby46BajO8"

local WeatherValues = game:GetService("ReplicatedStorage"):WaitForChild("WeatherValues")

local request =
    (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

assert(request, "Executor does not support HTTP requests.")

local Sent = {}

local Mutations = {
    "Bloodlit",
    "Rainbow",
    "Aurora",
    "Starstruck",
    "Chained",
    "Ignited",
    "Electric",
    "Frozen",
    "Gold"
}

local function TimeNow()
    return os.date("%H:%M:%S")
end

local function SendWebhook(name)
    local data = {
        embeds = {{
            title = "🚨 Boss thông báo",
            color = 16711680,
            fields = {
                {
                    name = "🌟 Mutation",
                    value = name,
                    inline = false
                },
                {
                    name = "🕒 Phát hiện",
                    value = TimeNow(),
                    inline = false
                }
            },
            footer = {
                text = "Kyzen Mutation Notifier"
            }
        }}
    }

    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    end)
end

local function CheckMutation(name)
    local attr = name .. "_Playing"
    local playing = WeatherValues:GetAttribute(attr)

    if playing then
        if not Sent[name] then
            Sent[name] = true
            print("[Mutation Detected]", name)
            SendWebhook(name)
        end
    else
        Sent[name] = nil
    end
end

for _, name in ipairs(Mutations) do
    CheckMutation(name)

    WeatherValues:GetAttributeChangedSignal(name .. "_Playing"):Connect(function()
        CheckMutation(name)
    end)
end

print("[Kyzen] Mutation Notifier Loaded.")
