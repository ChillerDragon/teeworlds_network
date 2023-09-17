#!/bin/bash

if [ ! -d spec ]
then
	echo "Error: spec folder not found"
	echo "       run this script from the root of repo"
	exit 1
fi

arg_generate_docs=0

for arg in "$@"
do
	if [ "$arg" == "--fix" ] || [ "$arg" == "--generate-docs" ]
	then
		arg_generate_docs=1
	fi
done

function missing_doc() {
	local rb_file="$1"
	local line
	local ifs="$IFS"
	local dir=''
	local class_name=''
	local is_init_raw=0
	local field
	local fields=''
	local dst_file
	while IFS='' read -r line
	do
		if [ "$line" == "# Client -> Server" ]
		then
			dir='Client -> Server'
		elif [ "$line" == "# Server -> Client" ]
		then
			dir='Server -> Client'
		elif [[ "$line" =~ ^class\ ([^ ]+) ]]
		then
			class_name="${BASH_REMATCH[1]}"
		elif [ "$line" == "  def init_raw(data)" ]
		then
			is_init_raw=1
		elif [ "$line" == "  end" ]
		then
			is_init_raw=0
		fi

		if [ "$is_init_raw" == "1" ]
		then
			if [[ "$line" =~ @(.*)\ =\ u.get_string ]]
			then
				field="${BASH_REMATCH[1]}"
				fields+="### @$field [String]\n"
			elif [[ "$line" =~ @(.*)\ =\ u.get_int ]]
			then
				field="${BASH_REMATCH[1]}"
				fields+="### @$field [Integer]\n"
			elif [[ "$line" =~ @(.*)\ =\ u.get_raw ]]
			then
				field="${BASH_REMATCH[1]}"
				fields+="### @$field [Raw]\n"
			fi
		fi
	done < "$rb_file"
	IFS="$ifs"
	dst_file="docs/classes/messages/$class_name.md"
	if [ -f "$dst_file" ]
	then
		return 1
	fi
	if [ "$arg_generate_docs" == "0" ]
	then
		return 0
	fi
	{
		echo "# $class_name"
		echo ''
		echo "$dir"
		echo ''
		echo -e "$fields"
	} > "$dst_file"
	return 1
}

function generate_msg_docs() {
	local rb_file
	for rb_file in ./lib/messages/*.rb
	do
		echo -n "[*] $(basename "$rb_file") .. "
		if missing_doc "$rb_file"
		then
			echo "ERROR: missing doc try --fix"
		else
			echo "OK"
		fi
	done
}

generate_msg_docs

