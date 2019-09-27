#!/bin/bash 

curdir="$(dirname "$0")"

source "$curdir/lib/internals.sh"


validate () {
    is=$2
    should_be=$3

    printf "%-80s" "$(tput setaf 7)$1$(tput sgr0)"

    if [[ "$is" == "$should_be" ]]; then
            printf "$(tput setaf 2)Passed.$(tput sgr0)\n"
    else
            printf "$(tput setaf 1)Failed. Should be $should_be, is $is$(tput sgr0)\n"
    fi
}

header () {
	title=$1;
	first_header=$2;

	if [[ $arg == "" && $first_header != 1 ]]; then
		echo "";
	fi

	printf "$(tput setaf 3)$title$(tput sgr0)\n"
}

# Integers
if [[ $arg == "--int" || $arg == "" ]]; then
	header "Integers" 1;
	validate "Casting \"1234567890\" properly" $(int 1234567890) 1234567890
	validate "Casting float \"13.37\" properly" $(int "13.37") 13
	validate "Casting float \"100000.00001\" properly" $(int "100000.00001") 100000
	validate "Casting weird text int \"123onetwothree\" properly" $(int "123onetwothree") 123
	validate "is \"42\" an int? (yes)" $(is_int "42"; echo $?;) 0
	validate "is \"13.37\" an int? (no)" $(is_int "13.37"; echo $?;) 1
	validate "is \"123onetwothree\" an int? (maybe? i think no)" $(is_int "123onetwothree"; echo $?;) 1
fi

# URL handling
if [[ $arg == "--url" || $arg == "" ]]; then
	header "URL handling" 0;
	validate "Getting ID from \"/test/1337\"" $(get_id_from_uri "/test/1337") 1337
	validate "Getting ID from \"/test/1337/\"" $(get_id_from_uri "/test/1337") 1337
	validate "Getting ID from \"/test/99999999\"" $(get_id_from_uri "/test/99999999") 99999999
fi

