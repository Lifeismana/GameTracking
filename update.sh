#!/bin/bash

# Validate that first argument is a number (depotid)
re='^[0-9]+$'
if ! [[ $1 =~ $re ]]; then
	echo "First argument must be an integer" >&2; exit 1
fi

# Set working directory where this file is located
cd "${0%/*}"

ProcessDepot ()
{
	while IFS= read -r -d '' file
	do
		baseFile=$(basename "$file" "$3")
		
		echo "> $baseFile"
		
		if [ "$2" = "dota_s2" ]
		then
			mono .support/ProtobufDumper.exe "$file" "Protobufs/$2/$baseFile/" > /dev/null
		else
			mono .support/ProtobufDumper.exe "$file" "Protobufs/$2/" > /dev/null
		fi
		
		mkdir -p "BuildbotPaths/$2"
		mkdir -p "Strings/$2"
		
		strings "$file" | grep "buildslave" | grep -v "/.ccache/tmp/" | sort -u > "BuildbotPaths/$2/$baseFile.txt"
		strings "$file" -n 5 | grep "^[a-zA-Z0-9\.\_\-]*$" | grep -Evi "protobuf|GCC_except_table|osx-builder\." | sort -u > "Strings/$2/$baseFile.txt"
	done <   <(find "$1/" -type f -name "*$3" -print0)
}

ProcessVPK ()
{
	while IFS= read -r -d '' file
	do
		baseFile=$(basename "$file" "_dir.vpk")
		
		echo "> VPK $baseFile"
		
		./.support/vpktool "$file" > "$1/$baseFile.txt"
	done <   <(find "$1/" -type f -name "*_dir.vpk" -print0)
}

# Do stuff based on the depotid
case $1 in

# Team Fortress 2
441)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/tf_english_utf8.txt" "$1/tf_english.txt"
	;;

232252)
	ProcessDepot "$1" "tf" ".dylib"
	;;

# Counter-Strike: Global Offensive
731)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/csgo_english_utf8.txt" "$1/csgo_english.txt"
	;;

733)
	ProcessDepot "$1" "csgo" ".dylib"
	;;

# Dota 2
571)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/dota_english_utf8.txt" "$1/dota_english.txt"
	iconv -t UTF-8 -f UCS-2 -o "$1/items_english_utf8.txt" "$1/items_english.txt"
	;;

574)
	ProcessDepot "$1" "dota" ".dylib"
	;;

# Dota 2 Test
205791)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/dota_english_utf8.txt" "$1/dota_english.txt"
	iconv -t UTF-8 -f UCS-2 -o "$1/items_english_utf8.txt" "$1/items_english.txt"
	;;

205794)
	ProcessDepot "$1" "dota_test" ".dylib"
	;;

# Dota 2 Workshop
313250)
	ProcessDepot "$1" "dota_s2" ".dll"
	;;

# Half-Life 2
221)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/hl2_english_utf8.txt" "$1/hl2_english.txt"
	;;
	
223)
	ProcessDepot "$1" "hl2" ".dylib"
	;;
	
# Half-Life 2: Episode One
389)
	ProcessVPK "$1"
	;;

# Half-Life 2: Episode Two
420)
	ProcessVPK "$1"
	;;

# Half-Life 2: Death Match
321)
	ProcessVPK "$1"
	;;

232372)
	ProcessDepot "$1" "hl2dm" ".dylib"
	;;

# Portal
401)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/portal_english_utf8.txt" "$1/portal_english.txt"
	;;
	
403)
	ProcessDepot "$1" "portal" ".dylib"
	;;
	
# Portal 2
621)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/portal2_english_utf8.txt" "$1/portal2_english.txt"
	;;
	
624)
	ProcessDepot "$1" "portal2" ".dylib"
	;;

# Left 4 Dead
502)
	ProcessVPK "$1"
	;;
	
515)
	ProcessDepot "$1" "l4d" ".dylib"
	;;
	
# Left 4 Dead 2
551)
	ProcessVPK "$1"
	;;

553)
	ProcessDepot "$1" "l4d2" ".dylib"
	;;

# Alien Swarm
631)
	ProcessVPK "$1"
	
	iconv -t UTF-8 -f UCS-2 -o "$1/swarm_english_utf8.txt" "$1/swarm_english.txt"
	
	ProcessDepot "$1" "as" ".dll"
	;;

# SFM
1841)
	ProcessDepot "$1" "sfm" ".dll"
	;;

# OpenVR
250822)
	ProcessDepot "$1" "openvr" ".dylib"
	;;
	
esac

git add -A
git commit -a -m "$(git status --porcelain | sed '{:q;N;s/\n/, /g;t q}' | sed 's/^ *//g')"
git push
