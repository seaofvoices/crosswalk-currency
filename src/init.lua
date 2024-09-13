return function(Modules, _, _)
    local Disk = require('@pkg/luau-disk')

    local Map = Disk.Map

    local module = {}

    type Data = {
        default: number,
        custom: { [string]: number },
    }

    local playerDatas

    local function getDefault(): Data
        return {
            default = 0,
            custom = {},
        }
    end

    function module.Init()
        playerDatas = Modules.DataHandler.register(
            'currency',
            getDefault,
            function(player: Player, data: Data)
                Modules.Channels.sendLocal(
                    player,
                    'currencies',
                    Map.merge(data.custom, { default = data.default })
                )
                Modules.Channels.sendLocal(player, 'currency', data.default)
                for currencyName, amount in data.custom do
                    Modules.Channels.sendLocal(player, `currency_{currencyName}`, amount)
                end
            end
        )
    end

    local function sendToChannel(player: Player, data: Data, currencyChanged: string?)
        Modules.Channels.sendLocal(
            player,
            'currencies',
            Map.merge(data.custom, { default = data.default })
        )
        if currencyChanged == nil then
            Modules.Channels.sendLocal(player, 'currency', data.default)
        else
            Modules.Channels.sendLocal(
                player,
                `currency_{currencyChanged}`,
                data.custom[currencyChanged]
            )
        end
    end

    local function verifyCurrencyName(name: string)
        if not string.match(name, '^[%w_]+$') then
            error(`invalid currency name '{name}' (it should contain only letters, numbers or '_')`)
        end
    end

    local function getCustomCurrency(currencyName: string?): string?
        return if currencyName == nil
                or currencyName == ''
                or currencyName == 'default'
            then nil
            else currencyName
    end

    function module.give(player: Player, amount: number, currencyName: string?)
        if amount == 0 then
            return
        end

        local data: Data = playerDatas:expect(player)
        local customCurrency = getCustomCurrency(currencyName)

        if customCurrency == nil then
            data.default += amount
        else
            if _G.DEV then
                verifyCurrencyName(customCurrency)
            end
            local custom = data.custom
            custom[customCurrency] = amount + (custom[customCurrency] or 0)
        end

        sendToChannel(player, data, customCurrency)
    end

    function module.tryGive(player: Player, amount: number, currencyName: string?): boolean
        if amount == 0 then
            return true
        end

        local data: Data? = playerDatas:tryGet(player)

        if data == nil then
            return false
        end

        local data = data :: Data

        local customCurrency = getCustomCurrency(currencyName)

        if customCurrency == nil then
            data.default += amount
        else
            if _G.DEV then
                verifyCurrencyName(customCurrency)
            end
            local custom = data.custom
            custom[customCurrency] = amount + (custom[customCurrency] or 0)
        end

        sendToChannel(player, data, customCurrency)

        return true
    end

    function module.spend(player: Player, amount: number, currencyName: string?): boolean
        local data: Data = playerDatas:expect(player)

        local customCurrency = getCustomCurrency(currencyName)

        if customCurrency == nil then
            if data.default >= amount then
                data.default -= amount
                sendToChannel(player, data, nil)
                return true
            end
        else
            if _G.DEV then
                verifyCurrencyName(customCurrency)
            end
            local currencyAmount = data.custom[customCurrency] or 0
            if currencyAmount >= amount then
                data.custom[customCurrency] = currencyAmount - amount
                sendToChannel(player, data, customCurrency)
                return true
            end
        end

        return false
    end

    function module.hasFunds(player: Player, amount: number, currencyName: string?): boolean
        local data: Data = playerDatas:expect(player)

        local customCurrency = getCustomCurrency(currencyName)

        if customCurrency == nil then
            return data.default >= amount
        else
            if _G.DEV then
                verifyCurrencyName(customCurrency)
            end
            return (data.custom[customCurrency] or 0) >= amount
        end
    end

    function module.get(player: Player, currencyName: string?): number
        local data: Data = playerDatas:expect(player)

        local customCurrency = getCustomCurrency(currencyName)

        if customCurrency == nil then
            return data.default or 0
        else
            if _G.DEV then
                verifyCurrencyName(customCurrency)
            end
            return data.custom[customCurrency] or 0
        end
    end

    return module
end
