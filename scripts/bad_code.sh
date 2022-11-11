#!/bin/bash

arg_fix=0

if [ "$1" == "--fix" ]
then
	arg_fix=1
fi

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
	done < <(grep -nri "to_s(16)" --exclude=bad_code.sh |
		grep -v "to_s(16).rjust(2, '0')" |
		cut -d':' -f1)
fi

if grep -nri "to_s(16)" --exclude=bad_code.sh | grep -v "to_s(16).rjust(2, '0')"
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
