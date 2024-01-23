# crosswalk-currency

This [crosswalk module](https://github.com/seaofvoices/crosswalk) simplifies the handling of game-specific currencies. It provides the necessary functions to add, spend or check funds for individual players.

This module requires the [Channels](https://github.com/seaofvoices/crosswalk-channels) and [DataHandler](https://github.com/seaofvoices/crosswalk-data-handler) modules.

## Installation

Add `crosswalk-currency` in your dependencies:

```bash
yarn add crosswalk-currency
```

Or if you are using `npm`:

```bash
npm install crosswalk-currency
```

## API

### `give`

```lua
Currency.give(player: Player, amount: number, currencyName?: string)
```

Give currency to a player. If `currencyName` is provided, the specified custom currency will be incremented; otherwise, the default currency will be incremented.

### `spend`

```lua
Currency.spend(player: Player, amount: number, currencyName?: string): boolean
```

Spend currency on behalf of a player. If `currencyName` is provided, the specified custom currency will be decremented; otherwise, the default currency will be decremented. Returns `true` if the transaction is successful, otherwise `false` if the player does not have sufficient funds.

### `hasFunds`

```lua
Currency.hasFunds(player: Player, amount: number, currencyName?: string): boolean
```

Check if a player has sufficient funds. Returns `true` if the player has enough currency (default or custom, depending on the presence of `currencyName`), otherwise `false`.

## Listen to Currency Changes

The module uses the [Channels](https://github.com/seaofvoices/crosswalk-channels) module to make the different currency amounts available. It will publish the amounts on different **local** channels:

- `currencies`: contains all the currencies amount in a dictionary. The default currency is indexed at `default`. Take note that **custom currencies** maybe be undefined if a player has never received that currency.
- `currency`: contains the default currency amount
- `currency_*`: contains a custom currency amount. If a game has a `gems` currency, it would publish the value on the channel `currency_gems`

In client modules, connect using the `Channels.Bind` function.

```lua
Modules.Channels.Bind('currency', function(amount: number)
    -- todo: display the value somewhere
end)
```

In **server modules**, connect using the `Channels.BindPlayer` function (since the data is published using `Channels.SendLocal`).

```lua
Modules.Channels.BindPlayer('currency', function(player: Player, amount: number)
    -- todo: the player's currency amount changed so server leaderboards
    -- could be updated here for example.
end)
```

## License

This project is available under the MIT license. See [LICENSE.txt](LICENSE.txt) for details.
