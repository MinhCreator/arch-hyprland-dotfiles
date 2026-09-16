#!/bin/bash

for id in $(wpctl status | grep -A 20 Sources | grep -o '[0-9]\+'); do
    wpctl set-mute "$id" toggle
done
