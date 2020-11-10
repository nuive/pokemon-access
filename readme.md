## Introduction

The Pokemon access project is an improved version of the Pokecrystal Access Project, a set of scripts which initially provided access to Pokémon Crystal for people using a screen reader.
The goal of this project is to extend this functionality throughout all the Pokémon games. Current version has support only for Pokémon Yellow, but in the future it will include, if it's possible, support for several games unified into a single script including an improved version of the initial Pokecrystal Access release.

At the momment, this readme will be essentially a copy of the readme provided with the Pokecrystal Access release, with only minnor  changes.

These scripts are designed to work with the VBA-ReRecording GameBoy emulator.
  
## Requirements and installation
1. Download the GameBoy emulator VBA Rerecording
http://vba-rerecording.googlecode.com/files/vba-v24m-svn-r480.7z

2. Get a Pokémon Yellow rom (the script supports english and spanish roms at the momment).

3. After you have these, extract and run VBA.

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

## Notes
New translations for the supported games are welcome. You should translate all files on the lang/<language> and send them to me (or make a PR).

## Contact information
If you find a bug, or want to contact me about these scripts, my contact information is below.
for bugs, send a save state with instructions on how to reproduce the issue from it, whenever possible. You can save a named one with control shift s in the game.

Email: nuive.code@gmail.com
Source code: https://github.com/nuive/pokemon-access

## Credits
None of this would have been possible without the original Pokecrystal Access Project written by Tyler Spivey, who did a great work with that. Here is the original project information.

Original project homepage (pokecrystal access): http://allinaccess.com/pca/
Original source code: https://github.com/tspivey/pokecrystal-access
