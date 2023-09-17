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

arg_generate_docs=0

for arg in "$@"
do
	if [ "$arg" == "--fix" ] || [ "$arg" == "--generate-docs" ]
	then
		arg_generate_docs=1
	else
		echo "usage: ./scripts/update_docs_methods.sh [--fix]"
		exit 1
	fi
done

function list_pub_methods() {
	local rbfile="$1"
	local line
	local is_private=0
	while read -r line
	do
		if [ "$line" == private ]
		then
			is_private=1
		elif [ "$line" == public ]
		then
			is_private=0
		fi
		[[ "$is_private" == "1" ]] && continue
		[[ "$line" =~ def\  ]] && echo "${line#* }"
	done < "$rbfile"
}

function print_method_doc() {
	local ruby_class="$1"
	local method="$2"
	local method_slug
	method_slug="${method%%(*}"
	method_slug="${method_slug%%\?*}"
	local obj_var=client
	local run="client.connect('localhost', 8303, detach: false)"
	if [[ "$ruby_class" =~ Server ]]
	then
		obj_var=server
		run="server.run('127.0.0.1', 8377)"
	fi
	cat <<- EOF
	### <a name="$method_slug"></a> #$method

	**Parameter: TODO**

	**Example:**
	EOF
	echo '```ruby'
	cat <<- EOF
	$obj_var = $ruby_class.new

	# TODO: generated documentation
	$obj_var.$method

	$run
	EOF
	echo '```'
}

function gen_class_methods() {
	local class_name="$1"
	local rbfile="$2"
	local mdfile="$3"
	if [ ! -f "$mdfile" ]
	then
		echo "Error: file not found $mdfile"
		exit 1
	fi
	cat "$mdfile" > "$tmpfile"
	local method
	while read -r method
	do
		echo -n "[*] $method .. "
		if grep -q "#$method" "$mdfile"
		then
			echo "OK"
			continue
		fi
		if [ "$arg_generate_docs" == "1" ]
		then
			echo "GENERATING"
			print_method_doc "$class_name" "$method" >> "$tmpfile"
		else
			echo "ERROR (run with --fix to fix)"
			exit 1
		fi
	done < <(list_pub_methods "$rbfile")
	check_diff_or_fix "$mdfile"
}

function check_diff_or_fix() {
	local mdfile="$1"
	if [ ! -f "$mdfile" ]
	then
		echo "Error: missing markdown file $mdfile"
		exit 1
	fi
	if [ "$arg_generate_docs" == "1" ]
	then
		mv "$tmpfile" "$mdfile"
		return
	fi
	local diff
	echo "$tmpfile" "$mdfile"
	diff="$(diff "$tmpfile" "$mdfile")"
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
	gen_class_methods TeeworldsClient ./lib/teeworlds_client.rb ./docs/classes/TeeworldsClient.md
}

main

