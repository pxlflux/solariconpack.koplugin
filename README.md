# Solar Icon Pack for KOReader

Modern, rounded replacement icons for [KOReader](https://github.com/koreader/koreader), with a full icon pack for the [SimpleUI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) plugin, [ZenOS](https://github.com/xZenLabs/zen-os) plugin and [Project: Title](https://github.com/joshuacant/ProjectTitle) plugin. Includes many supplementary icons for use with custom quick actions.

<img width="2400" height="1180" alt="Solar Icon Pack: Colour and Mono icons" src="https://github.com/user-attachments/assets/60011e18-b307-41fd-b141-17c4e2a54f58" />

## What's included

|                         | Icons | Details                                                                                                                                                                                                                                                             |
| ----------------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **KOReader Icons**      | 102   | Replaces KOReader's built-in icons: menu tabs, reader bottom bar, rotation, chevrons, dog-ears, Wi-Fi etc.                                                                                                                                                          |
| **Supplementary Icons** | 173   | For use with Custom Quick Actions: the base icons themselves, under their own names (apps and plugins like BookOrbit, Bookshelf, Calibre, OPDS, Rakuyomi, RSS, Storefront, Syncthing, Wallabag, Z-Library etc. plus general icons like Calendar, Downloads, Font, Gestures, Patches, Terminal, Update, Wallpaper etc.), minus the few that only make sense inside a plugin. |
| **SimpleUI Icons**      | 35    | A SimpleUI icon pack; the included `pack.lua` maps the icons to all 48 SimpleUI system and action icons.                                                                                                                                                            |
| **ZenOS Icons**         | 195   | A ZenOS icon pack covering ZenOS, ZenPM and ZenFM: navbar, quick settings, launcher, lookup, menus, reader and device icons. ZenOS asks for some icons under several names, so many share the same artwork.                                                         |
| **Project Title Icons** | 11    | Project: Title's 5 title bar icons, plus its 6 book and folder images.                                                                                                                                                                                              |

Every icon sits on the same grid with matching line weights, so everything looks consistent across your UI.

Each pack is complete on its own, so many icons appear in more than one pack, sometimes under a different name or in a different colour. For example, KOReader's `book.opened` is also SimpleUI's `continue` and ZenOS's `book_open`.

Each style has just two folders: `KOReader Icons` (102 icons, KOReader's own, installed as they are) and `Base Icons` (182 icons: every other drawing once, with simple names like `heart` or `folder_up`). The base icons double as the supplementary icons for Quick Actions. When you install, the plugin builds the pack for the plugin you're using (SimpleUI, ZenOS or Project: Title) from these two folders, copying, renaming, recolouring or resizing icons as each pack needs. [Icon names](Icon%20names.md) lists which pack icons each one becomes.

Storing every drawing only once keeps the download small, and keeps the icons consistent: a fix to an icon only has to be made in one place and reaches every pack that uses it, so two copies of the same icon can never end up slightly different.

### Two versions

| | Style | Made for |
|---|---|---|
| **Solar Colour** | Soft pastel fills, 0.75 stroke | Colour e-ink screens |
| **Solar Mono** | Bolder outlines, 1.0 stroke | Black & white e-ink screens |

<img width="2400" height="1180" alt="KOReader and SimpleUI before and after Solar" src="https://github.com/user-attachments/assets/729dc6cc-fdf3-4aba-80ab-1f95f7b59ec9" />

## Install with the plugin (easiest)

1. Download `solariconpack.koplugin.zip` from the [latest release](https://github.com/pxlflux/solariconpack.koplugin/releases/latest), unzip it, and copy the `solariconpack.koplugin` folder into `koreader/plugins/`. Then restart KOReader.
2. Open **Tools → Solar Icon Pack**, choose **Solar Colour** or **Solar Mono**, then select **Install**.

When you install, Solar sets up KOReader and whichever of these plugins you're using:

- **KOReader** (always; supports 2026.07.1): replaces KOReader's built-in icons.
- **SimpleUI** (supports 3.0.2): adds the SimpleUI pack and applies it for you, and adds the supplementary icons for Quick Actions.
- **ZenOS** (supports 4.2.0): adds a Solar icon pack, turns on ZenOS's custom icons and selects the pack for you, and adds the supplementary icons it doesn't already have as extra choices in ZenOS's icon picker for App Launcher shortcuts. It also replaces two icons in ZenOS's own plugin folder, which ZenOS loads directly (its menu tab, with or without the update dot).
- **Project: Title** (supports 2026.07-v3.8.3): replaces its title bar icons and its book and folder images. If a Project: Title update puts its own images back, Solar replaces them again at the next start (the same goes for ZenOS's Zen UI icons).

Solar only builds the icons for the plugin you're using, from its KOReader and base icons, and keeps them in `koreader/settings/solariconpack-build/`. The KOReader and Quick Action icons are copied straight from the plugin, so they aren't built. It then asks you to restart KOReader to show the new icons.

Any icons Solar replaces are backed up first, including ZenOS's Zen UI icons and Project: Title's own images. To go back, choose **Off** in the same menu: your previous icons and SimpleUI and ZenOS icon settings are restored, and the ZenOS pack and the built icons are removed.

If you turn on SimpleUI, ZenOS or Project: Title later, or update Solar, choose your current style again to reinstall.

To update the plugin, choose **Check for updates** in the same menu.

## Manual install

Only the KOReader icons can be installed by hand: the SimpleUI, Supplementary, ZenOS and Project: Title packs are built by the plugin, so use [Install with the plugin](#install-with-the-plugin-easiest) for those.

Download `solariconpack.koplugin.zip` from the [latest release](https://github.com/pxlflux/solariconpack.koplugin/releases/latest) and unzip it. Inside the `solariconpack.koplugin` folder, open the version you'd like to install, `Solar Colour` or `Solar Mono`, then its `KOReader Icons` folder.

### KOReader icons

1. Copy the files **inside** `KOReader Icons` into `koreader/icons/` on your device. If there's no `icons` folder, create one inside `koreader/`.
2. Restart KOReader.

Copy the files themselves, not the folder: KOReader doesn't look in subfolders of `icons/`. These icons work with or without SimpleUI, and they survive KOReader updates.

### Uninstalling

If you installed with the plugin, choose **Off** in **Tools → Solar Icon Pack** first and then delete the plugin folder from `koreader/plugins/`. Removing the plugin folder on its own leaves the icons in place. If you've already removed it, reinstall the plugin and choose **Off** to restore your previous icons.

If you installed the KOReader icons manually, delete the Solar files from `koreader/icons/` and restart KOReader.

## Known issues

- **ZenOS:** a few places load ZenOS's own icons directly instead of through icon packs, so they keep ZenOS's icons even with Solar selected. This has been reported to ZenOS, and Solar already includes the icons for when it's fixed.

## Full icon list

The overview shows every KOReader and base icon with its filename. [Icon names](Icon%20names.md) lists which pack icons each one becomes, with their filenames in each pack.

<details>
<summary><strong>Solar Colour</strong></summary>

![Solar Colour: the KOReader and base icons with their names](Solar%20Colour/Icon%20Overview%20%28Colour%29.png)

</details>

<details>
<summary><strong>Solar Mono</strong></summary>

![Solar Mono: the KOReader and base icons with their names](Solar%20Mono/Icon%20Overview%20%28Mono%29.png)

</details>

## Editing the icons

- Every icon is a plain SVG with no editor data, so it opens cleanly in any text editor. All are drawn on the same 24 × 24 canvas.
- `KOReader Icons` use KOReader's own filenames, e.g. `appbar.settings.svg`. Keep the names, or KOReader won't find them. Some pack icons are made from these too, so editing one can change those as well.
- `Base Icons` hold every other drawing once. Keep the names: the manifest finds each icon by its name, and the names are also the Quick Action icon names. Edit one and every pack icon made from it changes too.

## How the packs are built

- `install/manifest.lua` lists every SimpleUI, ZenOS and Project: Title file: its name in the pack, the icon it's made from, and any change to it (`scale` to resize, `fills` to recolour). Base icons not listed in `quick_action_skip` are also offered as Quick Action icons.
- `install/Colour` and `install/Mono` hold SimpleUI's `pack.lua` and ZenOS's `pack.json`.
- Project: Title's `file`, `file-unsupported` and `folder` images are enlarged onto its 250 × 500 canvas with thicker lines.
- ZenOS asks for the same icon under different names in different places, so many of its icons share one source.

## Credits and licence

- Icons are based on the [Solar Icon Set](https://www.figma.com/community/file/1166831539721848736) by **480 Design**, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). They were edited and adapted for KOReader, and some were drawn from scratch where Solar didn't have a suitable icon.
- The `koreader` base icon is adapted from the KOReader logo in [koreader-icons](https://github.com/koreader/koreader-icons/tree/master/logo-2018-04), by KOReader contributors, licensed under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
- The icons in this pack are also released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), and the installer plugin's code under AGPL-3.0. See [LICENSE](LICENSE).
- Not affiliated with or endorsed by 480 Design, KOReader, SimpleUI, ZenOS or Project: Title.

## Support

Feedback and icon requests are welcome - open an [issue](https://github.com/pxlflux/solariconpack.koplugin/issues).

If you enjoy the pack, consider [buying me a coffee](https://ko-fi.com/pxlflux). Any support is appreciated.
