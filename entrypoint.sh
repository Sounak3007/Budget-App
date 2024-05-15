#!/bin/bash
set -e

# Kill any running Rails server
if pgrep -f 'rails server'; then
  pkill -f 'rails server'
fi

