#!/bin/bash

query="$1"
curdir="$(dirname "$0")"

source "$curdir/internals.sh"

db_response=$(mysql -u $(setting "username") -p$(setting "password") -e "$query" consolia --batch 2>&1 | grep -v "Warning: Using a password" | egrep '^|');

read_column_names=1;
array_of_results='[]';

while IFS=$'\t' read -r -a values
do 

    if [[ $read_column_names == 1 ]]; then
	
	columns=("${values[@]}")
	read_column_names=0;
	continue;
    fi

    jq_args=( )
    jq_query='.'
    
    for key in "${!values[@]}"; do
	
	column=${columns[$key]};
	value=${values[$key]};
	#echo column is $column and value is $value 

	jq_args+=( --arg "column$column"   "$column"   )
	jq_args+=( --arg "value$column" "$value" )

	if [[ \
		# encapsulated in [ or { hints at json objects / arrays, so bypass jq args and insert directly
		$value =~ ^\[.*\]$ || $value =~ ^\{.*\}$ \

		# numbers need to be inserted directly as well, lest they be escaped and quoted (so they'd become strings)
		|| $value =~ ^[0-9\.]+$ \

		# booleans, same
		|| $value == "true" || $value == "false" \
	    ]]; then
		jq_query+=" | .[\$column$column]=$value";

	# all else is encoded properly through jq args
	else
        	jq_query+=" | .[\$column$column]=\$value$column";
        fi 
    done

    # run the generated command
    object=$(jq "${jq_args[@]}" "$jq_query" <<<'{}');
    array_of_results=$(echo $array_of_results | jq ". += [$object]")

done <<< "$db_response"

echo $array_of_results;
