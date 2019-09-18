#!/bin/bash 

setting_file="config.yaml"
uri=$(printenv "DOCUMENT_URI" | sed "s/\/$basedir//g" | sed "s/\/$//g");
query=$(printenv "QUERY_STRING");
request_method=$(printenv "REQUEST_METHOD");

currentIFS=$IFS
IFS='=&'
args=($query)
IFS=$currentIFS

for ((i=0; i<${#args[@]}; i+=2))
do
    declare get_${args[i]}=${args[i+1]}
done

setting () {
	key="$1"

	if [[ $setting_file != "" && -f $setting_file ]]; then

		setting_in_config=$(egrep -h -R "^$key:" $setting_file | sed "s/^$key:[[:space:]]*//g" | sed 's/#.*$//g' | xargs);
		echo "$setting_in_config";
	fi
}

# cast to int, with an option to return default value
int () {
	attempt_to_cast=$(echo $1 | sed 's/^\([0-9\.]\+\).*/\1/g' | sed 's/\.$//g');
	default_value=$2;

	if [[ "$attempt_to_cast" =~ ^[0-9]+$ ]]; then
		echo $attempt_to_cast;
	else
		if [[ "$default_value" =~ ^[0-9]+$ ]]; then
			echo $default_value;
		else
			echo 0;
		fi
	fi
}

sanitize () {
	input=$1;
	
	jq_args=( )
	jq_args+=( --arg "column" "input" );
	jq_args+=( --arg "value" "$input" );
	
	jq_query=". | .[\$column]=\$value";

	object=$(jq "${jq_args[@]}" "$jq_query" <<<'{}');

	sanitized_input=$(echo $object | jq '.input');
	echo $sanitized_input | sed 's/^"//g' | sed 's/"$//g';
}

send_200 () {
	payload=$1;
	echo "Content-type: application/json"
        echo -e "Status: 200\n";
        echo "$payload";
}

send_404 () {
	message=$1;
	echo "Content-type: application/json"
        echo -e "Status: 404\n";
        echo "{\"error\": \"$message\"}";
}

get_id_from_uri () {
	uri=$1;
	id=$(echo $uri | sed 's/\/[a-zA-Z0-9\-_]\+\/\([0-9]\+\)$/\1/g');
	echo $id;
}



req () {
	want_request_method=$1;
	want_uri=$2;

	if [[ $want_request_method == $request_method ]]; then

		# always try literal comparison first
		if [[ $uri == $want_uri ]]; then
			true;
			return;
		fi
		
		# contains bracket? must be regex
		if [[ $want_uri == *"["* && $uri =~ $want_uri ]]; then
			true;
			return;
		fi
	fi
	
	false;
}






