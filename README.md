# poe-trade-macro-updater

Updater/wrapper/launcher for [PoE-TradeMacro](https://github.com/PoE-TradeMacro/POE-TradeMacro), because it's bad at updating itself.

## How to use

Download the [latest release](https://github.com/Solonarv/poe-trade-macro-updater/releases/latest), drop the executable anywhere you want,
and double-click it. It will download TradeMacro and launch it automatically.

## Isn't this a bit pointless?

Yes. I wrote a [shell script](https://gist.github.com/Solonarv/121d42960c7078ff262f16167f33b488) a while ago, which does the exact same thing.
But the script is not very useful to people who can't or don't want to install `bash`, `jq`, and other miscellaneous command-line tools.
This was mostly written out of boredom, and a vague idea that other people might find it useful. It is completely self-contained and does not
rely on any other dependencies being installed on your system, although launching the trade macro will fail if AutoHotKey isn't installed.

This launcher does not currently update itself, which may seem a bit pointless. But the current version works and I expect it to continue working
for a long time, so if you don't need any other features you can just never update.

The next version will probably include a (working!) self-updater, so this shouldn't be an issue for very long.