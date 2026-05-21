#!/bin/bash

SIZE=""
OUTPUT_FILE="output.bin"

for i in "$@"
do
  case $i in
    --size=*)
      SIZE="${i#*=}"
      shift # past argument=value
      ;;
    --output=*)
      OUTPUT_FILE="${i#*=}"
      shift # past argument=value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
  esac
done

if [ -z "$SIZE" ]; then
  echo "Usage: $0 --size=<size_with_unit> [--output=<filename>]"
  echo "Example: $0 --size=716M --output=my_file.bin"
  exit 1
fi

function usage() {
  echo "Usage: $0 --size=<size_with_unit> [--output=<filename>]"
  echo "Example: $0 --size=716M --output=my_file.bin"
  exit 1
}

UNIT=$(echo "$SIZE" | sed -r 's/^[0-9]+([MGKBmgkb])$/\1/i')
VALUE=$(echo "$SIZE" | sed -r 's/^([0-9]+)[MGKBmgkb]$/\1/')

case "$UNIT" in
  M|m) COUNT=$((VALUE * 1024)) ; BS="1K" ;;
  G|g) COUNT=$((VALUE * 1024 * 1024)) ; BS="1K" ;;
  K|k) COUNT=$((VALUE)) ; BS="1K" ;;
  B|b) COUNT=$((VALUE)) ; BS="1" ;;
  *) echo "Invalid size unit. Use M, G, K, or B." ; exit 1 ;;
esac

echo "Creating file $OUTPUT_FILE with size $SIZE..."
dd if=/dev/zero of="$OUTPUT_FILE" bs="$BS" count="$COUNT" status=progress

if [ $? -eq 0 ]; then
  echo "File $OUTPUT_FILE created successfully."
else
  echo "Error creating file $OUTPUT_FILE."
fi

