#!/bin/bash

# Exit if any command fails and if any unset variable is used
set -eu

# Checkout with the correct line endings on plain text files, depending on the host OS
git config --global core.autocrlf true >/dev/null 2>/dev/null

function validate_variable {
	NAME="$1"

	value=""
	if [ "${!NAME}" ]; then
		value="${!NAME}"
	fi

	if [ -z "$value" ]; then
		exit 1
	fi
}

function update_local_git_repository {
	$DIRECTORY="$1"
	$REPOSITORY="$2"

	$UPDATED=0
	if [ ! $(git -C "$DIRECTORY" rev-parse --is-inside-work-tree >/dev/null 2>/dev/null) ]; then
		rm -rf "$DIRECTORY"
		git clone --recursive "$REREPOSITORYPO" "$DIRECTORY" >/dev/null 2>/dev/null
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

validate_variable "GARRYSMOD_COMMON_REPOSITORY"
validate_variable "GARRYSMOD_COMMON"

update_local_git_repository "$GARRYSMOD_COMMON" "$GARRYSMOD_COMMON_REPOSITORY"
