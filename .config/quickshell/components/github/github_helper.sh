#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/quickshell"
mkdir -p "$CACHE_DIR"

TEMP_FILE="$CACHE_DIR/github_contributions_temp.svg"
FINAL_FILE="$CACHE_DIR/github_contributions.svg"
COUNT_FILE="$CACHE_DIR/github_commit_count.txt"

# Defaults
COLOR_HEX="7ac79f"
WIDGET_HEX="1a2120"
COLORS_FILE="$HOME/.config/quickshell/Colors/colors.json"

if [[ -f "$COLORS_FILE" ]]; then
    primary=$(jq -r '.primary' "$COLORS_FILE" 2>/dev/null)
    if [[ "$primary" =~ ^#([0-9a-fA-F]{6})$ ]]; then
        COLOR_HEX="${BASH_REMATCH[1]}"
    fi
    
    widget_bg=$(jq -r '.surface_container' "$COLORS_FILE" 2>/dev/null)
    if [[ "$widget_bg" =~ ^#([0-9a-fA-F]{6})$ ]]; then
        WIDGET_HEX="${BASH_REMATCH[1]}"
    fi
fi

# 1. Download SVG atomically
curl -s "https://ghchart.rshah.org/${COLOR_HEX}/Priyam792" -o "$TEMP_FILE"
if [[ -f "$TEMP_FILE" ]]; then
    # Replace empty/uncommitted colors with a faint 8% opacity theme accent color
    sed -i -E "s/fill:#(EEEEEE|eeeeee|ebedf0|EBEDF0)/fill:#${COLOR_HEX};fill-opacity:0.08/g" "$TEMP_FILE"
    # Round the square corners in the SVG
    sed -i 's/width="10" height="10"/width="10" height="10" rx="2" ry="2"/g' "$TEMP_FILE"
    mv "$TEMP_FILE" "$FINAL_FILE"
fi

# 2. Download and extract commit count (use authenticated gh CLI if available, fallback to curl)
count=""
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
    count=$(gh api graphql -f query='query { viewer { contributionsCollection { contributionCalendar { totalContributions } } } }' -q '.data.viewer.contributionsCollection.contributionCalendar.totalContributions' 2>/dev/null)
fi

if [[ -z "$count" || "$count" == "null" ]]; then
    count=$(curl -s "https://github.com/users/Priyam792/contributions" | grep -A 2 -i "js-contribution-activity-description" | tail -n 2 | grep -oE "[0-9,]+" | tr -d ',' | head -n 1)
fi

if [[ -n "$count" && "$count" != "null" ]]; then
    echo "$count" > "$COUNT_FILE"
else
    echo "0" > "$COUNT_FILE"
fi

# 3. Download and format repositories JSON atomically
curl -s "https://api.github.com/users/Priyam792/repos?sort=updated&per_page=30" | \
    jq '[.[] | {name: .name, description: (if .description != null then .description else "" end), stars: .stargazers_count, lang: (if .language != null then .language else "Markdown" end), url: .html_url}]' \
    > "$CACHE_DIR/github_repos_temp.json"
if [[ -f "$CACHE_DIR/github_repos_temp.json" ]]; then
    mv "$CACHE_DIR/github_repos_temp.json" "$CACHE_DIR/github_repos.json"
fi
