#!/bin/bash

export LC_ALL=C

ROOT_DIR="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"
VRF_PATH="$ROOT_DIR/ValveResourceFormat/Decompiler/bin/Release/linux-x64/publish/Decompiler"
DO_GIT=1

if [[ $2 = "no-git" ]]; then
	DO_GIT=0
fi

ProcessDepot ()
{
	echo "> Processing binaries"
	
#	rm -r "Protobufs"
	mkdir -p "Protobufs"
	
	while IFS= read -r -d '' file
	do
		if [ "$(basename "$file" "$1")" = "steamclient" ]
		then
			continue
		fi
		
		echo " > $file"
		
		~/ProtobufDumper/ProtobufDumper "$file" "Protobufs/" > /dev/null
		
		nmBinary="nm"
		
		if [ "$1" = ".dylib" ]
		then
			nmBinary="$ROOT_DIR/.support/nm-with-macho"
		fi
		
		if [ "$1" = ".dylib" ] || [ "$1" = ".so" ]
		then
			$nmBinary -C -p "$file" | grep -Evi "GCC_except_table|google::protobuf" | awk '{$1=""; print $0}' | sort -u > "$(echo "$file" | sed -e "s/$1$/.txt/g")"
		fi
		
		if [ "$1" = ".so" ]
		then
			"$ROOT_DIR/.support/elfstrings/elfstrings" -binary "$file" | sort -u > "$(echo "$file" | sed -e "s/$1$/_strings.txt/g")"
		else
			strings "$file" -n 5 | grep -Evi "protobuf|GCC_except_table|osx-builder\." | c++filt -_ | sort -u > "$(echo "$file" | sed -e "s/$1$/_strings.txt/g")"
		fi
	done <   <(find . -type f -name "*$1" -print0)
}

ProcessVPK ()
{
	echo "> Processing VPKs"
	
	while IFS= read -r -d '' file
	do
		echo " > $file"
		
		"$VRF_PATH" --input "$file" --vpk_list > "$(echo "$file" | sed -e 's/\.vpk$/\.txt/g')"
	done <   <(find . -type f -name "*_dir.vpk" -print0)
}

ProcessToolAssetInfo ()
{
	echo "> Processing tools asset info"
	
	while IFS= read -r -d '' file
	do
		echo " > $file"
		
		"$VRF_PATH" --input "$file" --output "$(echo "$file" | sed -e 's/\.bin$/\.txt/g')" --tools_asset_info_short
	done <   <(find . -type f -name "*asset_info.bin" -print0)
}

FixUCS2 ()
{
	echo "> Fixing UCS-2"

	find . -type f -name "*.txt" -print0 | xargs --null --max-lines=1 --max-procs=3 "$ROOT_DIR/fix_encoding"
}

CreateCommit ()
{
	if ! [[ $DO_GIT == 1 ]]; then
		echo "Not performing git commit"
		return
	fi

	message="$1 | $(git status --porcelain | wc -l) files | $(git status --porcelain | sed '{:q;N;s/\n/, /g;t q}' | sed 's/^ *//g' | cut -c 1-1024)"

	if [ -n "$2" ]; then
		bashpls=$'\n\n'
		message="${message}${bashpls}https://steamdb.info/patchnotes/$2/"
	fi

	git add -A
	git commit -S -a -m "$message"
	git push
	
	~/ValveProtobufs/update.sh
}
