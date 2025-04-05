#!/bin/bash

if [ ! -d spec ]
then
	echo "Error: spec folder not found"
	echo "       run this script from the root of repo"
	exit 1
fi

tmpdir=scripts/tmp
mkdir -p scripts/tmp
tmpfile="$tmpdir/README.md"

version="$(grep TEEWORLDS_NETWORK_VERSION lib/version.rb | cut -d"'" -f2)"
if [ "$version" == "" ]
then
	echo "Error: failed to get library version"
	exit 1
fi
version="v$version"

arg_generate_docs=0

for arg in "$@"
do
	if [ "$arg" == "--fix" ] || [ "$arg" == "--generate-docs" ]
	then
		arg_generate_docs=1
	else
		echo "usage: ./scripts/update_docs_index.sh [--fix]"
		exit 1
	fi
done

function print_instance_methods() {
	local class="$1"
	local hook
	local hook_slug
	while read -r hook
	do
		hook_slug="${hook%%(*}"
		hook_slug="${hook_slug%%\?*}"
		echo ""
		echo "[#$hook](classes/$class.md#$hook_slug)"
	done < <(grep '### <a name="' "docs/classes/$class.md" | cut -d'#' -f5)
}

function list_classes() {
	local class_path
	local class_name
	for class_path in ./docs/classes/*.md
	do
		class_name="$(basename "$class_path" .md)"
		class_path="$(echo "$class_path" | cut -d'/' -f3-)"
		{
			echo ""
			echo "### [$class_name]($class_path)"
			print_instance_methods "$class_name"
		} >> "$tmpfile"
	done
}

function check_diff_or_fix() {
	local index_file="docs/README.md"
	if [ ! -f "$index_file" ]
	then
		echo "Error: missing index file $index_file"
		exit 1
	fi
	if [ "$arg_generate_docs" == "1" ]
	then
		mv "$tmpfile" "$index_file"
		return
	fi
	local diff
	echo "$tmpfile" "$index_file"
	diff="$(diff "$tmpfile" "$index_file")"
	if [ "$diff" != "" ]
	then
		echo "Error: documentation index is not up to date"
		echo "       to fix this run ./scripts/update_docs_index.sh --fix"
		echo ""
		echo "$diff"
		exit 1
	fi
}

function main() {
	cat <<- EOF > "$tmpfile"
	<!-- THIS FILE IS AUTOGENERATED BY ./scripts/update_docs_index.sh -->

	# teeworlds_network

	Version $version

	## Classes

	EOF
	list_classes
	check_diff_or_fix
}

main

