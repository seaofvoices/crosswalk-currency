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
        if name == 'default' then
            error(
                "the currency name 'default' is reserved, please use a different name "
                    .. 'or do not provide the currency name to use the default currency'
            )
        end
        if not string.match('^[%w_]+$', name) then
            error(`invalid currency name '{name}' (it should contain only letters, numbers or '_')`)
        end
    end

    function module.give(player: Player, amount: number, currencyName: string?)
        local data: Data = playerDatas:expect(player)

        if amount == 0 then
            return
        end

        if currencyName == nil then
            data.default += amount
        else
            if _G.DEV then
                verifyCurrencyName(currencyName)
            end
            local custom = data.custom
            custom[currencyName] = amount + (custom[currencyName] or 0)
        end

        sendToChannel(player, data, currencyName)
    end

    function module.spend(player: Player, amount: number, currencyName: string?): boolean
        local data: Data = playerDatas:expect(player)

        if currencyName == nil then
            if data.default >= amount then
                data.default -= amount
                sendToChannel(player, data, nil)
                return true
            end
        else
            if _G.DEV then
                verifyCurrencyName(currencyName)
            end
            local currencyAmount = data.custom[currencyName] or 0
            if currencyAmount >= amount then
                data.custom[currencyName] = currencyAmount - amount
                sendToChannel(player, data, currencyName)
                return true
            end
        end

        return false
    end

    function module.hasFunds(player: Player, amount: number, currencyName: string?): boolean
        local data: Data = playerDatas:expect(player)

        if currencyName == nil then
            return data.default >= amount
        else
            if _G.DEV then
                verifyCurrencyName(currencyName)
            end
            return (data.custom[currencyName] or 0) >= amount
        end
    end

    return module
end
