#!/usr/bin/env bash

# ────────────────────────────────────────────────────────
# SIMPLE LOFI PLAYER & VISUALIZER (Waybar)
# Left-click: Play/Pause
# Right-click: Toggle visualizer
# Middle-click: Launch cava visualizer (floating)
# Scroll Up: Next station
# Scroll Down: Previous station
# ────────────────────────────────────────────────────────

STATIONS=(
  "🎧|lofi hip hop|#b48ead|https://www.youtube.com/watch?v=jfKfPfyJRdk"
  "😔|lofi sad|#a3be8c|https://www.youtube.com/watch?v=P6Segk8cr-c"
  "🎷|lofi jazz|#ffd700|https://www.youtube.com/watch?v=HuFYqnbVbzY"
  "🏰|lofi medieval|#d08770|https://www.youtube.com/watch?v=IxPANmjPaek"
  "😴|lofi sleep|#5e81ac|https://www.youtube.com/watch?v=28KRPhVzCus"
  "⛩️|lofi asian|#e63946|https://www.youtube.com/watch?v=Na0w3Mz46GA&list=PL6NdkXsPL07Il2hEQGcLI4dg_LTg7xA2L&index=8"
  "🌸|lofi japan|#f9c5d1|https://www.youtube.com/watch?v=yr9ZxQaWkqs"
  "🎹|lofi piano|#cba6f7|https://www.youtube.com/watch?v=TtkFsfOP9QI&list=PL6NdkXsPL07Il2hEQGcLI4dg_LTg7xA2L&index=12"
  "🌧️|gentle rain|#a0c4ff|https://www.youtube.com/watch?v=-OekvEFm1lo&list=PL6NdkXsPL07Il2hEQGcLI4dg_LTg7xA2L&index=12"
  "🌧️🎷|rainy jazz|#c0a6d4|https://www.youtube.com/watch?v=DSGyEsJ17cI"
  "🚗|future garage|#a79aff|https://www.youtube.com/watch?v=sQ28KTOUgVM"
  "🧬|synthwave|#ff79c6|https://www.youtube.com/watch?v=4xDzrJKXOOY"
  "🇺🇸|abc news|#6e6b7b|https://www.youtube.com/watch?v=-mvUkiILTqI"
  "🇫🇷|france info|#fab387|https://www.youtube.com/watch?v=Z-Nwo-ypKtM"
)

PID_FILE="/tmp/lofi-mpv.pid"
STATE_FILE="/tmp/lofi-state.txt"
TICK_FILE="/tmp/fake_viz_tick"
VIZ_FILE="/tmp/lofi-visualizer.txt"

INDEX=$(cat "$STATE_FILE" 2>/dev/null)
[[ -z "$INDEX" || ! "$INDEX" =~ ^[0-9]+$ ]] && INDEX=0

IFS='|' read -r ICON NAME COLOR URL <<< "${STATIONS[$INDEX]}"
[[ -f $VIZ_FILE ]] || echo "on" > "$VIZ_FILE"
VIZ=$(<"$VIZ_FILE")

if [[ -f "$PID_FILE" ]]; then
  pid=$(<"$PID_FILE")
  if kill -0 "$pid" 2>/dev/null; then
    PLAYING=true
  else
    PLAYING=false
  fi
else
  PLAYING=false
fi

case "$1" in
  toggle)
    if $PLAYING; then
      kill "$pid"
      rm "$PID_FILE"
    else
      mpv --no-video --quiet --ytdl-format=bestaudio "$URL" &
      echo $! > "$PID_FILE"
    fi
    exit
    ;;

  right)
    [[ "$VIZ" == "on" ]] && echo "off" > "$VIZ_FILE" || echo "on" > "$VIZ_FILE"
    exit
    ;;

  next|up)
    INDEX=$(( (INDEX + 1) % ${#STATIONS[@]} ))
    echo "$INDEX" > "$STATE_FILE"
    [[ "$PLAYING" == true ]] && "$0" toggle && "$0" toggle
    exit
    ;;

  prev|down)
    INDEX=$(( (INDEX - 1 + ${#STATIONS[@]}) % ${#STATIONS[@]} ))
    echo "$INDEX" > "$STATE_FILE"
    [[ "$PLAYING" == true ]] && "$0" toggle && "$0" toggle
    exit
    ;;

  middle2)
    kitty --class cava --title "lofi-cava" cava &
    exit
    ;;

  middle)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(<"$PID_FILE")
      kill "$pid" 2>/dev/null
      rm "$PID_FILE"
    fi
    mpv --ytdl-format=best "$URL" &
    echo $! > "$PID_FILE"
    exit
    ;;

  show)
    [[ -f $TICK_FILE ]] && TICK=$(<"$TICK_FILE") || TICK=0
    TICK=${TICK//[^0-9]/}  # sanitize to digits only
    TICK=$((TICK + 1)) && echo "$TICK" > "$TICK_FILE"

    if [[ -f "$PID_FILE" ]]; then
      pid=$(<"$PID_FILE")
      if kill -0 "$pid" 2>/dev/null; then
        PLAYING=true
      else
        PLAYING=false
      fi
    else
      PLAYING=false
    fi

    pattern=(1 2 3 2 1 0)
    BARS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
    NUM_BARS=6
    output=""

    if [[ "$VIZ" == "on" ]]; then
      if $PLAYING; then
        for ((i = 0; i < NUM_BARS; i++)); do
          idx=$(( (i + TICK) % ${#pattern[@]} ))
          bar_idx=${pattern[$idx]}
          output+="${BARS[$bar_idx]}"
        done
      else
        output="$(printf '▁%.0s' $(seq 1 $NUM_BARS))"
      fi
    fi

    if [[ -n "$COLOR" ]]; then
      echo "<span color='$COLOR'>$ICON $output</span>"
    else
      echo "$ICON $output"
    fi
    ;;

  *)
    echo "Usage: $0 [toggle|right|up|down|middle|show]"
    exit 1
    ;;
esac

exit 0
