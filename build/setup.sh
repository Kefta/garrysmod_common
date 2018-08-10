#!/bin/bash

# Exit if any command fails and if any unset variable is used
set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE:-$0}" )" && pwd )"

function validate_variable_or_set_default {
	NAME="$1"
	DEFAULT="$2"

	value="$DEFAULT"
	if [ "${!NAME}" ]; then
		value="${!NAME}"
	fi

	if [ -z "$value" ]; then
		if [ -z "$DEFAULT" ]; then
			exit 1
		fi

		export "$NAME"="$value"
	fi
}

function update_local_git_repository {
	$DIRECTORY="$1"
	$REPOSITORY="$2"

	$UPDATED=0
	if [ ! $(git -C "$DIRECTORY" rev-parse --is-inside-work-tree >/dev/null 2>/dev/null) ]; then
		rm -rf "$DIRECTORY"
		git clone --recursive "$REPOSITORY" "$DIRECTORY" >/dev/null 2>/dev/null
		$UPDATED=1
	else
		pushd "$DIRECTORY"

		LOCAL=$(git rev-parse @)
		REMOTE=$(git rev-parse @{u})
		BASE=$(git merge-base @ @{u})

		if [ $LOCAL = $BASE ]; then
			git pull >/dev/null 2>/dev/null
			git submodule update --init --recursive >/dev/null 2>/dev/null
			$UPDATED=1
		elif [ ! $LOCAL = $REMOTE ]; then
			git reset --hard origin/master >/dev/null 2>/dev/null
			git clean -f >/dev/null 2>/dev/null
			git pull >/dev/null 2>/dev/null
			$UPDATED=1
		fi

		popd
	fi

	echo "$UPDATED"
}

function create_directory_forcefully {
	$PATH="$1"

	if [ -d "$PATH" ]; then
		return
	elif [ -f "$PATH" ]; then
		rm -f "$PATH"
	fi

	mkdir -p "$PATH"
}

create_directory_forcefully "$DEPENDENCIES"
