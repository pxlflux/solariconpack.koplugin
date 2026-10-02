# Solar Icon Pack for KOReader

Modern, rounded replacement icons for [KOReader](https://github.com/koreader/koreader), with a full icon pack and supplementary icons for the [SimpleUI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) plugin.

<img width="2400" height="1180" alt="Solar Icon Pack: Colour and Mono icons" src="https://github.com/user-attachments/assets/60011e18-b307-41fd-b141-17c4e2a54f58" />

## What's included

| | Icons | Details |
|---|---|---|
| **KOReader Icons** | 102 | Replaces KOReader's built-in icons: menu tabs, reader bottom bar, rotation, chevrons, dog-ears, Wi-Fi etc. |
| **Pack Icons** | 34 | A SimpleUI icon pack; the included `pack.lua` maps the icons to all 46 SimpleUI system and action icons |
| **Supplementary Icons** | 24 | For use with SimpleUI's Custom Quick Actions, e.g. Bookshelf, Rakuyomi, Syncthing, File Browser, Z-Library |

Every icon sits on the same grid with matching line weights, so everything looks consistent across KOReader and SimpleUI.

### Two versions

| | Style | Made for |
|---|---|---|
| **Solar Colour** | Soft pastel fills, 0.75 stroke | Colour e-ink screens |
| **Solar Mono** | Bolder outlines, 1.0 stroke | Black & white e-ink screens |

<img width="2400" height="1180" alt="KOReader and SimpleUI before and after Solar" src="https://github.com/user-attachments/assets/729dc6cc-fdf3-4aba-80ab-1f95f7b59ec9" />

## Install with the plugin (easiest)

1. Download `solariconpack.koplugin.zip` from the [latest release](https://github.com/pxlflux/solariconpack.koplugin/releases/latest), unzip it, and copy the `solariconpack.koplugin` folder into `koreader/plugins/`. Then restart KOReader.
2. Open **Tools → Solar Icon Pack**, choose **Solar Colour** or **Solar Mono**, then select **Install**.

The plugin copies everything into place, applies the SimpleUI pack if you use SimpleUI, and asks you to restart. Any icons it replaces are backed up first. To go back, choose **Off** in the same menu: your previous icons and SimpleUI settings are restored.

If you install SimpleUI later, or want the latest icons after an update, choose your current style again to reinstall.

To update the plugin, choose **Check for updates** in the same menu.

## Manual install

Download `solariconpack.koplugin.zip` from the [latest release](https://github.com/pxlflux/solariconpack.koplugin/releases/latest) and unzip it. Inside the `solariconpack.koplugin` folder, open the version you'd like to install, `Solar Colour` or `Solar Mono`. Each contains three folders:

```
KOReader Icons (Colour or Mono)/          102 icons for KOReader
Pack Icons (Colour or Mono)/              SimpleUI icon pack (34 icons + pack.lua)
Supplementary Icons (Colour or Mono)/     24 icons for Custom Quick Actions
```

Copy from these folders as described below. You don't need to install the plugin itself. To see every icon with its filename, check the [full icon list](#full-icon-list).

### 1. KOReader icons

1. Copy the files **inside** `KOReader Icons` into `koreader/icons/` on your device. If there's no `icons` folder, create one inside `koreader/`.
2. Restart KOReader.

Copy the files themselves, not the folder: KOReader doesn't look in subfolders of `icons/`. These icons work with or without SimpleUI, and they survive KOReader updates.

### 2. Pack icons

1. Make sure [SimpleUI](https://github.com/doctorhetfield-cmd/simpleui.koplugin) is installed.
2. Copy the `Pack Icons` **folder** for your version into `koreader/settings/simpleui/sui_icons/packs/`.
3. Restart KOReader.
4. Apply it in **SimpleUI → Style → Icons → Icon Packs**.

### 3. Supplementary icons

1. Copy the files **inside** the `Supplementary Icons` folder for your version into `koreader/settings/simpleui/sui_icons/`.
2. Restart KOReader.
3. Choose them for a Quick Action in **SimpleUI → Quick Actions → Quick Action Icons**, or when creating one in **SimpleUI → Quick Actions → Custom Quick Actions → Create Quick Action**.

Colour and Mono supplementary icons use the same filenames, so install one set at a time. Copying the other set over the top later switches all your custom Quick Action icons to that style. To keep both, copy each `Supplementary Icons` folder itself (not its contents) into `sui_icons/`, and pick icons with **Browse**.

### Uninstalling

If you installed with the plugin, choose **Off** in **Tools → Solar Icon Pack** first and then delete the plugin folder from `koreader/plugins/`. Removing the plugin folder on its own leaves the icons in place. If you've already removed it, reinstall the plugin and choose **Off** to restore your previous icons.

If you installed manually, delete the Solar files from `koreader/icons/` and restart KOReader. For the SimpleUI pack, go to **SimpleUI → Style → Icons → System Icons → Reset all**, then delete the pack folder from `packs/`. If you installed the supplementary icons, reset any Quick Actions that use them and delete the files from `sui_icons/`.

## Known issues

SimpleUI 2.7.1 doesn't load the Recent and Random icons from icon packs, so for now you'll need to set those two by hand in **Quick Action Icons**. It's been [fixed](https://github.com/doctorhetfield-cmd/simpleui.koplugin/issues/540) in SimpleUI's development code and should work from the next release.

## Full icon list

<details>
<summary><strong>Solar Colour</strong></summary>

![Solar Colour: every icon with its filename](Solar%20Colour/Full%20Icon%20Overview%20%28Colour%29.png)

</details>

<details>
<summary><strong>Solar Mono</strong></summary>

![Solar Mono: every icon with its filename](Solar%20Mono/Full%20Icon%20Overview%20%28Mono%29.png)

</details>

## Editing the icons

- Every icon is a plain 24 × 24 SVG with no editor data, so it opens cleanly in any text editor.
- The KOReader icons use KOReader's own filenames, e.g. `appbar.settings.svg`. Keep the names, or KOReader won't find them.
- The SimpleUI pack uses simple filenames (`library.svg`, `chevron_left.svg` etc.). `pack.lua` maps each SimpleUI slot to a file, and several slots can share one file. To change one slot without affecting the others, add a new file and point that slot's line at it.

## Credits and licence

- Icons are based on the [Solar Icon Set](https://www.figma.com/community/file/1166831539721848736) by **480 Design**, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). They were edited and adapted for KOReader, and some were drawn from scratch where Solar didn't have a suitable icon.
- The icons in this pack are also released under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), and the installer plugin's code under AGPL-3.0. See [LICENSE](LICENSE).
- Not affiliated with or endorsed by 480 Design, KOReader or SimpleUI.

## Support

Feedback and icon requests are welcome - open an [issue](https://github.com/pxlflux/solariconpack.koplugin/issues).

If you enjoy the pack, consider [buying me a coffee](https://ko-fi.com/pxlflux). Any support is appreciated.
