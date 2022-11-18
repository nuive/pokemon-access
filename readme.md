# Pokémon Access
# Version 3.1.0

## Introduction

The Pokemon access project is an improved version of the Pokecrystal Access Project, a set of scripts which initially provided access to Pokémon Crystal for people using a screen reader.
The goal of this project is to extend this functionality throughout all the Pokémon games. Current version has support for the following games, but in the future it will include, if it's possible, support for more games unified into this script.

-Pokémon Red, Blue and Yellow.
-Pokémon Gold, Silver and Crystal.
-Pokémon Fire Red and Leaf Green.
-Pokémon Emerald.

These scripts are designed to work with the VBA-ReRecording GameBoy emulator.
  
## Requirements and installation
1. Download the GameBoy emulator VBA Rerecording from https://mega.nz/file/ogEV1LZI#GgOG9ayodsIO7tbwBCNlQI8YenvsL_pnf-FSJC8m5S4

2. Get a compatible rom. Currently, the script supports the following:

-Pokémon Red, Blue and Yellow: : English, French, German, Italian and Spanish.
-Pokémon Gold, Silver and Crystal: English, French, Italian, Spanish and Brazilian Portuguese (crystal only).
-Pokémon Fire Red and Leaf Green: English (version 1.0) and Spanish.
-Pokémon Emerald: English and Spanish.

3. After you have the desired rom, extract and run VBA.

4. Go to the Options menu, Head-Up Display, Show Speed, None (alt-o, h, s, enter)
Without this, NVDA reads the title bar every time it changes.

5. Optional but recommended: turn down the sound. In the Options menu, navigate to Audio, Volume (alt o, a, v)

.25x for GameBoy ROMs and .5x for GameBoy Advance ROMs.

## Starting the game
Each time you run VBA, you'll need to load the rom.
You can do this from the open dialog, or load a recent rom after you've opened it once.

Once the rom is loaded, load the lua script (tools, lua, New Lua script window).
From there, load pokemon.lua, press run. It should say ready (or your language equivalent, bassed on the game you've downloaded), alt tab out and back in again

## Troubleshooting
If you receive any error when opening the emulator it is possible that you need to install DirectX. DirectX is necessary to run the latest versions of the VBA-ReRecording emulator, without it the emulator will show an error message indicating that a DLL is missing and will not open. It can be downloaded from https://www.microsoft.com/en-us/download/confirmation.aspx?id=35

## Keys

* Standard gameBoy keys: z/x are a/b, a/s l/r, enter/backspace start/select and arrows.
* j, k and l - previous, current and next item
* shift k - rename current item
* shift j and l - previous and next item filters
* m - read current map name
* shift M - rename current map
* t - read text on screen, if any
* p - pathfind. This tries to find a path between you and the object selected.
* Shift + P - Toggle HM compatibility when using pathfind. For example surf or cut. This has 3 possible options. Do not use HMs, Use Available HMs (bassed on the number of gym badges you have) or Use all HMs.
* y - read current position
* h - read enemy health if in a battle
* shift + h - read player health if in a battle
* e - read the surrounding tiles (for debugging purposes)

### Camera
* d - move the camera left, stopping at walls
* g - move the camera right, stopping at walls
* r - move the camera up, stopping at walls
* v - move the camera down, stopping at walls
* f - move the camera to the player's position
* add shift to d/g/r/v to move the camera, ignoring walls
* Shift + y - read current camera position
* shift+f - pathfind to camera position
* Shift + c - toggle if camera follows the player or not.

### Gold/SILVER/Crystal exclusive keys
* shift+e - say which piece you are holding (on the unown puzzles)

## HackRom support
Current version of the script has extended support for hackroms of the games previously mentioned. The process is as follows.

You've loaded a ROM that the script detects as "Language not supported" or "Game not supported".
You return to the game ignoring the previous result... but wait, if you try to execute any script command you'll only get the message "Script not loaded". Okay, let's fix this...

1. With the incompatible game running, press shift+0. A window will show up, where you'll select the base game of the hack.
2. When you press "OK", if there are any game expansions available, the script will show a list where you can add all the compatible expansions with your hack.
3. When you press "OK", the script now asks you for a data folder. This is the folder which containts the LUA files for the game (maps.lua, sprites.lua, memory.lua...).
4. When you press "OK", the script now asks you for a language for the spoken messages (not for the game names, those are into the data folder).
When you press "OK", the script will restart automatically and load the new data.
Congratulations! Now you can enjoy your hack!

### Notes
* You can edit previously added HackRoms pressing again Shift + 0, for example if you want to try another base script or if you develop a custom extension  for a specific hack.

## Notes
New translations for the supported games are welcome. You should translate the files "maps.lua" and "sprites.lua" located on the game/[game]/[lang]  ([lang] can be any of the existing languages, choose which is better for you to translate from). You should translate asswell the file messages/[lang].lua (applies same rules). Once translated, you can send these files to me (or make a PR).

## Contact information
If you find a bug, or want to contact me about these scripts, my contact information is below.
for bugs, send a save state with instructions on how to reproduce the issue from it, whenever possible. You can save a named one with control shift s in the game.

Email: nuive.code@gmail.com
Source code: https://github.com/nuive/pokemon-access

## Credits
None of this would have been possible without the original Pokecrystal Access Project written by Tyler Spivey, who did a great work with that. Here is the original project information.

Original project homepage (pokecrystal access): http://allinaccess.com/pca/
Original source code: https://github.com/tspivey/pokecrystal-access

### Additional contributors
-ambro86 for the italian translations.
-pika-san for the french translations.
-janagirl for the german translations.
-zargonbr  for the brazilian portuguese translations.
