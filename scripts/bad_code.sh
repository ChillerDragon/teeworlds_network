#!/bin/bash

arg_fix=0

if [ "$1" == "--fix" ]
then
	arg_fix=1
fi

function check_hex_str() {
	local bad_file
	local del
	local del_end
	if [ "$arg_fix" == "1" ]
	then
		while read -r bad_file
		do
			echo "[*] fixing '$bad_file' ..."
			for del in ';' '$' ' '
			do
				del_end="$del"
				[[ "$del" == '$' ]] && del_end=''
				sed "s/.to_s(16)$del/.to_s(16).rjust(2, '0')$del_end/g" "$bad_file" > "$bad_file".tmp
			done
			mv "$bad_file".tmp "$bad_file"
		done < <(grep -nr "to_s(16)" --exclude=bad_code.sh |
			grep -v "to_s(16).rjust(2, '0')" |
			cut -d':' -f1)
	fi

	if grep -nr "to_s(16)" --exclude=bad_code.sh | grep -v "to_s(16).rjust(2, '0')"
	then
		if [ "$arg_fix" == "1" ]
		then
			echo "[-] Error: could not fix those ^"
			exit 1
		fi
		echo "[-] Error: found usage of 'to_s(16)' without 'rjust(2, '0')'"
		echo "[-]        all hexadecimal string bytes have to be zero padded!"
		echo "[-]"
		echo "[-]        bad:  FAF"
		echo "[-]        good: 0FAF"
		echo "[-]"
		echo "[-]	 run ./scripts/bad_code.sh --fix to fix"
		echo "[-]"
		exit 1
	fi
}

function check_chunk_header_args() {
	local header_line
	local line
	local method_args
	local needed_args
	local needed_arg
	local needed_srv
	local code
	needed_args=(vital: size:)
	while read -r header_line
	do
		line="$(echo "$header_line" | cut -d':' -f1-2)"
		code="$(echo "$header_line" | cut -d':' -f3-)"
		method_args="$(echo "$header_line" | cut -d'(' -f2-)"
		unset needed_srv
		# vital chunk headers sent by the server
		# need a client: to get the sequence number
		if [[ "$line" =~ server ]] && [[ "$method_args" =~ 'vital: true' ]]
		then
			needed_srv='client:'
		fi
		for needed_arg in "${needed_args[@]}" $needed_srv
		do
			if ! echo "$method_args" | grep -q "$needed_arg"
			then
				echo "[-] Error: missing argument '$needed_arg' for create_header() in $line"
				echo "[-]"
				echo "[-]        $code"
				echo "[-]"
				exit 1
			fi
		done
	done < <(grep -Enor "Chunk.create_header\([^)]+\)" --include=*.rb)
}

check_hex_str
check_chunk_header_args

