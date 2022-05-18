# Pokémon Access
# Version 2.5.1

## Introduction

The Pokemon access project is an improved version of the Pokecrystal Access Project, a set of scripts which initially provided access to Pokémon Crystal for people using a screen reader.
The goal of this project is to extend this functionality throughout all the Pokémon games. Current version has support for Pokémon Red, Blue, Yellow, Gold, Silver and Crystal, but in the future it will include, if it's possible, support for more games unified into this script.

At the momment, this readme will be essentially a copy of the readme provided with the Pokecrystal Access release, with only minnor  changes.

These scripts are designed to work with the VBA-ReRecording GameBoy emulator.
  
## Requirements and installation
1. Download the GameBoy emulator VBA Rerecording

2. Get a compatible rom. Currently, the script supports the following:

-Pokémon Red, Blue, Yellow, Gold, Silver and Crystal: English, French, Spanish and Italian.

3. After you have the desired rom, extract and run VBA.

4. Go to the Options menu, Head-Up Display, Show Speed, None (alt-o, h, s, enter)
Without this, NVDA reads the title bar every time it changes.

5. Optional but recommended: turn down the sound. In the Options menu, navigate to Audio, Volume (alt o, a, v)

## Starting the game
Each time you run VBA, you'll need to load the rom.
You can do this from the open dialog, or load a recent rom after you've opened it once.

Once the rom is loaded, load the lua script (tools, lua, New Lua script window).
From there, load pokemon.lua, press run. It should say ready (or your language equivalent, bassed on the game you've downloaded), alt tab out and back in again

## Keys
Make sure num lock is off while playing the game, or the keys won't work.

* Standard gameBoy keys: z/x are a/b, enter/backspace start/select and arrows.
* j, k and l - previous, current and next item
* shift k - rename current item
* m - read current map name
* shift M - rename current map
* t - read text on screen, if any
* p - pathfind. This tries to find a path between you and the object selected.
* Shift + P - Toggle HM compatibility when using pathfind. For example surf or cut
* y - read current position
* h - read enemy health if in a battle
* r - read the surrounding tiles (for debugging purposes)

### Camera
* s - move the camera left, stopping at walls
* f - move the camera right, stopping at walls
* e - move the camera up, stopping at walls
* c - move the camera down, stopping at walls
* d - move the camera to the player's position
* add shift to s/f/e/c to move the camera, ignoring walls
* Shift + y - read current camera position

### Gold/SILVER/Crystal exclusive keys
* shift+d - say which piece you are holding (on the unown puzzles)

## HackRom support
Current version of the script has extended support for hackroms of the games previously mentioned.
In the future, you'll have a more intuitive in-game feature to manage HackRoms. For now, the process is as follows.

You've loaded a ROM that the script detects as "Language not supported" or "Game not supported".
You return to the game ignoring the previous result... but wait, if you try to execute any script command you'll only get the message "Script not loaded". Okay, let's fix this...

1. With the incompatible game running, press shift+h. A window will show up, asking you for a "base game folder". This, in other words, is the base game script that this incompatible game will use. You'll have to access the lua/game folder, and here you'll see all compatible scripts. Keep in mind that you have to tell the script the exact folder name. For example, if you want to use the red/blue script, you'll write 'red_blue'; if you want to use the pokémon crystal script you'll write crystal, etc...
2. When you type the base folder name and press "OK", if the folder is valid the script now asks you for a language. Now you have to enter into the folder you selected on previous step and check what languages are available for the selected game. As in the previous step, you have to put the folder name ("en" for english, "fr" for french...)
3. When you type the language code and press "OK", if the language is valid the script will say "Done. Restart the script".
4. Congratulations! Now you can enjoy your hack!

### Notes
* You can edit previously added HackRoms pressing again Shift + H, for example if you want to try another base script or if you develop a custom extension  for a specific hack.
* Keep in mind that if the chosen language and the hack's language didn't match, the script will probably crash.

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

