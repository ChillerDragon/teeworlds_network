#!/bin/bash

if [ ! -d spec ]
then
	echo "Error: spec folder not found"
	echo "       run this script from the root of repo"
	exit 1
fi

arg_generate_docs=0

function show_usage() {
	echo "usage: ./scripts/hooks.sh [OPTION]"
	echo "options:"
	echo "  --fix | --generate-docs       to generate docs"
	echo "  -h | --help                   to show this help"
}

for arg in "$@"
do
	if [ "$arg" == "--fix" ] || [ "$arg" == "--generate-docs" ]
	then
		arg_generate_docs=1
	elif [ "$arg" == "-h" ] || [ "$arg" == "--help" ]
	then
		show_usage
		exit 0
	else
		show_usage
		exit 1
	fi
done

tmpdir=scripts/tmp
mkdir -p scripts/tmp

function get_hooks() {
	local ruby_file="$1"
	grep -o "^[[:space:]]*def on_.*(&block)" "$ruby_file" | grep -o "on_[^(]*" | awk NF
}

function get_msg_of_client_hook() {
	local hook="$1"
	local line
	local ifs="$IFS"
	local in_func=0
	while IFS='' read -r line
	do
		if [ "$line" == "  def $hook(chunk)" ] \
			|| [ "$line" == "  def $hook(data)" ] \
			|| [ "$line" == "  def $hook" ]
		then
			in_func=1
		fi
		if [[ "$line" =~ "  end" ]]
		then
			in_func=0
		fi
		if [ "$in_func" == "1" ]
		then
			if [[ "$line" =~ message\ =\ (.*).new ]]
			then
				echo "${BASH_REMATCH[1]}"
				break
			fi
			if [[ "$line" =~ Context\.new\(nil ]]
			then
				echo nil
				break
			fi
		fi
	done < lib/game_client.rb
	IFS="$ifs"
}

function add_hook_doc() {
	local mdfile="$1"
	local ruby_class="$2"
	local hook="$3"
	local class_ln
	if [ ! -f "$mdfile" ]
	then
		echo "Error: failed to generate docs! File not found $mdfile"
		exit 1
	fi
	class_ln="$(grep -n "^# $ruby_class" "$mdfile" | cut -d':' -f1)"
	class_ln="$((class_ln+1))"
	if [ "$class_ln" == "" ]
	then
		echo "Error: failed to generate docs could not get line"
		echo "   mdfile=$mdfile"
		echo "   ruby_class=$ruby_class"
		echo "   hook=$hook"
		exit 1
	fi
	local tmpdoc
	local obj_var=client
	local run="client.connect('localhost', 8303, detach: false)"
	if [[ "$ruby_class" =~ Server ]]
	then
		obj_var=server
		run="server.run('127.0.0.1', 8377)"
	fi
	local doc_text='TODO: generated documentation'
	local msg_class
	msg_class="$(get_msg_of_client_hook "$hook")"
	if [ "$msg_class" != "" ]
	then
		if [ "$msg_class" == "nil" ]
		then
			doc_text="context.message is nil because there is no message payload."
		else
			doc_text="context.message is a [$msg_class](../classes/messages/$msg_class.md)"
		fi
	fi
	tmpdoc="$tmpdir/doc.md"
	{
		head -n "$class_ln" "$mdfile" 
		# the ancor tag is a hack to allow linking
		# methods using #hook_name
		# because we want to put junk after the hook name
		# for example the parameters
		cat <<- EOF
		### <a name="$hook"></a> #$hook(&block)

		**Parameter: block [Block |[context](../classes/Context.md)|]**

		$doc_text

		**Example:**
		EOF
		echo '```ruby'
		cat <<- EOF
		$obj_var = $ruby_class.new

		$obj_var.$hook do |context|
		  # TODO: generated documentation
		end

		$run
		EOF
		echo '```'
		tail -n +"$class_ln" "$mdfile"
	} > "$tmpdoc"
	mv "$tmpdoc" "$mdfile"
}

function check_file() {
	local ruby_class="$1"
	local ruby_file="$2"
	local hooks
	local hook
	local got_err=0
	hooks="$(get_hooks "$ruby_file")"

	# self testing the test
	# if the test finds no hooks the test is wrong not the code
	if [ "$(echo "$hooks" | wc -l)" -lt 8 ]
	then
		echo "Error: found only $(echo "$hooks" | wc -l) hooks in $ruby_file"
		echo "       expected 8 or more"
		exit 1
	fi

	for hook in $hooks
	do
		local hook_err=0
		echo -n "[*] checking hook: $hook"
		# check documentation
		local mdfile
		mdfile="docs/classes/$ruby_class.md"
		if [ ! -f "$mdfile" ]
		then
			echo "ERROR: documentation not found $mdfile"
			exit 1
		fi
		if ! grep -q "#$hook" "$mdfile"
		then
			if [ "$arg_generate_docs" == "1" ]
			then
				add_hook_doc "$mdfile" "$ruby_class" "$hook"
			else
				echo " ERROR: missing documentation in $mdfile"
				# TODO: totally overengineer this and get spacing of 2nd line correct
				#       by computing prev line length
				echo "        try --generate-docs and fill out the templated docs"
				got_err=1
				hook_err=1
			fi
		else
			printf ' .'
		fi

		# check calling it
		local tmpfile
		tmpfile="$tmpdir/hook.rb"
		{
			echo '# frozen_string_literal: true'
			echo ''
			echo "require_relative '../../${ruby_file::-3}'"
			echo "obj = $ruby_class.new"
			echo "obj.$hook(&:verify)"
		} > "$tmpfile"
		if ! ruby "$tmpfile" &>/dev/null
		then
			echo " ERROR: calling the hook failed"
			ruby "$tmpfile"
		elif [ "$hook_err" == "0" ]
		then
			echo ". OK"
		fi
	done
	if [ "$got_err" == "0" ]
	then
		echo "[+] OK: all hooks okay."
		return 1
	else
		echo "[-] Error: some hooks have errors."
		return 0
	fi
}

echo "[*] client"
if check_file TeeworldsClient lib/teeworlds_client.rb
then
	exit 1
fi
echo "[*] server"
if check_file TeeworldsServer lib/teeworlds_server.rb
then
	exit 1
fi
