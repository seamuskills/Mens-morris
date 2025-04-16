#!/bin/sh
echo -ne '\033c\033]0;mens-morris\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/mens-morris.x86_64" "$@"
