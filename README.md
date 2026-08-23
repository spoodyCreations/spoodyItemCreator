# spoodyItemCreator
Create custom [ox_inventory](https://github.com/overextended/ox_inventory) items from inside the game — no editing `items.lua` by hand, no full server restarts just to add one item, syncs to all players **instantly**.

Open the panel, type in a name, label, weight and image link, hit **Apply** — and the item is registered into ox_inventory and pushed live to everyone already online. Built with React, Tailwind and shadcn/ui.
---
## Preview
[Streamable Link](https://streamable.com/e/7lrm66)

<table>
  <tr>
    <td><img src="https://r2.fivemanage.com/CWDuI3yLS4av0OWnTLNNl/invmanager_2.png" alt="spoodyItemCreator – item panel" /></td>
    <td><img src="https://r2.fivemanage.com/CWDuI3yLS4av0OWnTLNNl/invmanager_1.png" alt="spoodyItemCreator – browsing items" /></td>
  </tr>
</table>

---
## Features
- Add, edit and delete items from a clean panel instead of a text editor
- Browse everything registered in ox_inventory — your items, stock items, and items from other resources — and click any of them to tweak or remove
- Paste a direct image URL and it's downloaded into `ox_inventory/web/images/` for you
- Items are written as proper native `['name'] = { ... }` entries, exactly like you'd add by hand
- Point an item at a client export so it actually *does* something when used
- New and edited items show up for connected players instantly — no relog, no restart
- Cleans up after itself: deleting an item removes it from `items.lua` and deletes only the image it downloaded (your stock images are never touched)
---
## Dependencies
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_lib](https://github.com/overextended/ox_lib)
---
## Installation
**1.** Drop the `spoodyItemCreator` folder into your `resources` directory and ensure it **after** ox_lib and ox_inventory:
```cfg
ensure ox_lib
ensure ox_inventory
ensure spoodyItemCreator
```
**2.** Open the **`install me`** folder inside `spoodyItemCreator` and drag both files into your **ox_inventory** folder (right next to its `fxmanifest.lua`):
- `item-creator-bridge.lua`
- `item-creator-bridge.client.lua`

**3.** Add these two lines anywhere in `ox_inventory/fxmanifest.lua`:
```lua
server_scripts { 'item-creator-bridge.lua' }
client_scripts { 'item-creator-bridge.client.lua' }
```
**4.** `restart ox_inventory`, then `restart spoodyItemCreator` — or just restart the server.

> Not sure it's wired up right? Run `/itemcreator install` in console or in-game and it'll tell you exactly what to copy and add, or confirm it's already done.
---
## Configuration
Everything lives in `config.lua`:

| Option | Default | What it does |
| --- | --- | --- |
| `Config.Command` | `itemcreator` | The chat command that opens the panel. |
| `Config.Ace` | `group.admin` | The permission allowed to open it. |
---
## Usage
Type `/itemcreator` in-game (admins only).

In **My Items**, click **Add Item** and fill in:
- **Name** — the ox_inventory id. Lowercase, no spaces (e.g. `energy_drink`).
- **Label** — what players actually see (e.g. `Energy Drink`).
- **Weight** — in grams.
- **Image URL** — a direct link to an image.
- **Use Export** — optional. A client export fired when the item is used (e.g. `myresource.useItem`). Leave blank for a plain item.
- **Stackable / Close on use / Consumable** — toggles.

Hit **Apply** and you're done.

In **All ox_inventory Items** you can search and browse everything registered, click an item to edit it, or tick a few and delete them. Sensitive items (money, weapons, ammo, licenses) ask you to confirm first, since removing those can break other scripts.

### Toolbar

| Button | What it does |
| --- | --- |
| **Add Item** | Create a new item. |
| **Apply** | Save everything — writes `items.lua`, downloads images, registers the items, and pushes them to online players. |
| **Refresh players** | Re-pushes the current items to everyone online without rewriting anything. Handy if a client looks out of sync. |

> Two honest caveats: editing an item that's already on a player's open inventory may need them to reopen it, and deleting an item someone is still holding shows an "item data undefined" note for them until it's re-added — that's just ox reacting to an item that no longer exists.
---
## Updating ox_inventory
Updating ox wipes its folder, so you'll need to **re-copy the two bridge files** into it and **re-add the two `fxmanifest.lua` lines** (install steps 2 and 3 again — `/itemcreator install` reminds you exactly what). Your items are remembered by spoodyItemCreator, so a single **Apply** brings every one of them back.

## Paid & Premium Resources
Need help or want more premium escrowed scripts? Check out the store:

<a href="https://spoody.store">
  <img src="https://r2.fivemanage.com/CWDuI3yLS4av0OWnTLNNl/tebex_banner.png" alt="Tebex Store" width="400" />
</a>

[Discord Invite](https://r2.fivemanage.com/CWDuI3yLS4av0OWnTLNNl/tebex_banner.png)
