#!/bin/bash
outdir="$HOME/cputemps/$(hostname)"
echo "writing output to: $outdir"
currentdate=$(date +%Y-%m-%d)
mkdir -p "$outdir" && touch "$outdir/$currentdate.csv"
if [ ! -s "$outdir/$currentdate.csv" ]; then
    echo "Time,CPU Temp" > "$outdir/$currentdate.csv"
fi

# Determines what values we need to pull of out of sensors.
cpuvendor=$(lscpu | awk -F: '/Vendor ID/ {gsub(/^[ \t]+/,"",$2); print $2}' | head -n 1)
if [[ "$cpuvendor" == *"Intel"* ]]; then
    # Happy with an average of the package.
    # I'm terrible with awk so I expect there are nicer ways to do this.
    cputemp=$(sensors | awk -F: '/Package id 0:/ {gsub(/^[ \t]+/,"",$2);sub(/[[:space:]]*\(.*/,"",$2);print $2}')
elif [[ "$cpuvendor" == *"AMD"* ]]; then
    # The _average_ sligtly inflated temperature of the CCDs is fine here. Some of my AMD machines don't even report a single ccd temp.
    cputemp=$(sensors 2>/dev/null | awk -F: '/Tctl:/ {gsub(/^[ \t]+/,"",$2); print $2}')
else
    # defaulting to what my raspi 3 reports, If I ever have to care about making this better I will.
    cputemp=$(sensors 2>/dev/null | awk -F: '/temp1:/ {gsub(/^[ \t]+/,"",$2);sub(/[[:space:]]*\(.*/,"",$2);print $2}')
fi

echo "$(date +%H:%M:%S),$cputemp" >> "$outdir/$currentdate.csv"
