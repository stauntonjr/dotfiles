#!/usr/bin/env bash

# Keep login bash startup routed through the shared profile chain.
if [ -f "$HOME/.profile" ]; then
	# shellcheck disable=SC1090
	. "$HOME/.profile"
fi
