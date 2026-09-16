#!/bin/bash

pokemon=$(ls /usr/share/pokemon-colorscripts/colorscripts | shuf -n 1)

#pokemon-colorscripts -n "$(basename "$pokemon")" --no-title > ~/.cache/pokemon.txt

fastfetch
