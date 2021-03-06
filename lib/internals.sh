#!/bin/bash 

setting_file="conf/config.yaml"

setting () {
	key="$1"

	if [[ $setting_file != "" && -f $setting_file ]]; then

		setting_in_config=$(egrep -h -R "^$key:" $setting_file | sed "s/^$key:[[:space:]]*//g" | sed 's/#.*$//g' | xargs);
		echo "$setting_in_config";
	fi
}

# cast to int, with an option to return default value
int () {
	attempt_to_cast=$(echo $1 | sed 's/^\([0-9]\{1,\}\).*/\1/g' | sed 's/\.$//g');
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

is_int () {
	if [[ "$1" =~ ^[0-9]+$ ]]; then
		true;
	else
		false;
	fi
}

string_shorter_than () {
	supplied_string=$1;
	minimum_length=$2;
	length=${#supplied_string};
	
	if [[ $length -lt $minimum_length ]]; then
		true
	else
		false
	fi
}

greater_than () {

	if ! is_int $1 || ! is_int $2; then
		false;
	fi

	if [[ $1 -gt $2 ]]; then
		true;
	else
		false;
	fi
}

valid_json () {

	if jq -e . >/dev/null 2>&1 <<<"$1"; then
		true;
	else
		false;
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

get_uri () {

	uri=$(printenv "DOCUMENT_URI" | sed "s/\/$//g");

	if [[ $(setting "basedir") != "" ]]; then
		uri=$(printenv "DOCUMENT_URI" | sed "s/\/$(setting 'basedir')//g" | sed "s/\/$//g");
		echo $uri;
	else
		uri=$(printenv "DOCUMENT_URI" | sed "s/\/$//g");
		echo $uri;
	fi
}

get_id_from_uri () {
	uri=$1;
	id=$(echo $uri | sed 's/.*\/\([0-9]*\)$/\1/g');
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

add_route () {
	route_request_method=$1;
	route_uri=$2;
	route_func=$3

	if req $route_request_method $route_uri; then
		$route_func
		exit 0
	fi
}

add_404_route () {
	$1;
}

default_404 () {
	send_404 "Not found"
}

send_200 () {
	payload=$1;
	echo "Content-type: application/json"
    echo -e "Status: 200\n";
    echo "$payload";
}

send_404 () {
	local message=$1;
    send_response 404 "{\"error\": \"$message\"}";
}

send_error () {
	local resp_status_code=$1;
	local message=$2;
    send_response $resp_status_code "{\"error\": \"$message\"}";
}

send_response () {
	local resp_status_code=$1;
	local payload=$2

	echo "Content-type: application/json"
    echo -e "Status: $resp_status_code\n";
    echo -e "$payload";
}



function validate_fields_in_json () {
	fields_as_csv=$1;
	json=$2;

	if ! valid_json "$json"; then
		echo "- supplied body is not valid JSON";
		exit 1
	fi

	{
		while IFS=',' read -r -a values; do

		    for key in "${!values[@]}"; do

		    	field=${values[$key]};
		    	value=$(echo $data | jq -j ".$field");
		    	field_validation=$(o_o "$validation_rules" "$field");

		    	if ! empty $field_validation; then

		    		# empty but mandatory?
			    	if [[ $(o_o "$field_validation" "mandatory") == "true" ]] && empty $value; then
			    		echo "- $field should not be empty";
			    	fi

			    	# value too short?
			    	if ! empty $(o_o "$field_validation" "longer_than") && string_shorter_than "$value" $(o_o "$field_validation" "longer_than"); then
			    		longer_than=$(o_o "$field_validation" "longer_than")
			    		echo "- $field needs to be equal or longer than $longer_than";
			    	fi

			    	# value must contain x
		    		contains=$(o_o "$field_validation" "contains");
			    	if ! empty $(o_o "$field_validation" "contains") && [[ "$value" != *"$contains"* ]]; then
			    		echo "- $field needs to contain \"$contains\"";
			    	fi

			    	#value must validate to regex
			    	if ! empty $(o_o "$field_validation" "validate_regex") && [[ ! $value =~ $(o_o "$field_validation" "validate_regex") ]]; then
				    		validate_regex=$(o_o "$field_validation" "validate_regex");
				    		echo "- $field must be valid to this regex: $validate_regex";
			    	fi

			    	#value must validate to be a datetime
			    	if ! empty $(o_o "$field_validation" "datetime") && [[ ! $value =~ ^[0-9]{4}\-[0-9]{2}\-[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
				    		echo "- $field must be a valid datetime, the format is: yyyy-mm-dd hh:mm:ss";
			    	else
			    		validate_year=$(echo "2019-12-20 12:30:00" | awk '{print $1}' | awk -F  "-" '/1/ {print $1}');
			    		validate_month=$(echo "2019-12-20 12:30:00" | awk '{print $1}' | awk -F  "-" '/1/ {print $2}');
			    		validate_day=$(echo "2019-12-20 12:30:00" | awk '{print $1}' | awk -F  "-" '/1/ {print $3}');

			    		validate_hour=$(echo "2019-12-20 12:30:00" | awk '{print $2}' | awk -F  ":" '/1/ {print $3}');
			    		validate_min=$(echo "2019-12-20 12:30:00" | awk '{print $2}' | awk -F  ":" '/1/ {print $3}');
			    		validate_sec=$(echo "2019-12-20 12:30:00" | awk '{print $2}' | awk -F  ":" '/1/ {print $3}');
			    	fi

			    	# must be int
			    	if [[ $(o_o "$field_validation" "integer") == "true" ]] && ! is_int $value; then
			    		echo "- $field must be an integer";
			    	
			    	# is int, so do int specific validations
			    	else

				    	# int must be greater than
				    	if ! empty $(o_o "$field_validation" "greater_than") && ! greater_than $value $(o_o "$field_validation" "greater_than"); then
				    		greater_than=$(o_o "$field_validation" "greater_than");
				    		echo "- $field must be greater than $greater_than";
				    	fi
				    fi

		    	fi
		    done
	  	done
  	} <<<"$fields_as_csv"
}

empty () {

	if [[ $1 == "" || $1 == "null" ]]; then
		true;
	else
		false;
	fi
}

o_o () {

	if ! valid_json "$1"; then
		echo "Error: supplied object is not valid json";
		echo "$1";
		exit 1
	fi

	echo "$1" | jq -j ".$2";
}

get_fields_from_json () {
	local supplied_json=$1;

	if valid_json "$supplied_json"; then
		echo "$data" | jq '. | to_entries[] | .key' | tr '\n' ',' | sed 's/"//g' | sed 's/,$//g';
	fi
}


build_update_query () {
	local data=$1
	local fields=$2

	motherfucking_first_yall=1;
	{
		while IFS=',' read -r -a values; do

			for key in "${!values[@]}"; do

		    	local field=${values[$key]};
		    	local value=$(o_o "$data" "$field");

		    	if [[ $motherfucking_first_yall == 1 ]]; then
		    		motherfucking_first_yall=0;
		    		echo "$(sanitize "$field") = \"$(sanitize "$value")\"";
		    	else
		    		echo ",$(sanitize "$field") = \"$(sanitize "$value")\"";
		    	fi
		    done
		done
  	} <<<"$fields"
}

build_where_query () {
	local fields=$1
	local data=$2
	local search_config=$3
	motherfucking_first_yall=1;

	{
		while IFS=',' read -r -a values; do

			for key in "${!values[@]}"; do

		    	local field=${values[$key]};
		    	local value=$(o_o "$data" "$field");

		    	if empty "$value"; then
		    		continue;
		    	fi

		    	if [[ $motherfucking_first_yall == 1 ]]; then
		    		motherfucking_first_yall=0;
		    		echo "where ";
		    	else
		    		echo "and ";
		    	fi

		    	# is the current field a search field?
		    	if ! empty $(o_o "$search_config" "$field"); then

		    		local filter_field=$(o_o "$search_config" "$field");
		    		echo "$(sanitize "$filter_field") like \"%$(sanitize "$value")%\"";
		    	# if no, carry on
		    	else
		    		echo "$(sanitize "$field") = \"$(sanitize "$value")\"";
		    	fi
		    done
		done
  	} <<<"$fields"
}

if [[ "$CONTENT_LENGTH" -gt 0 ]]; then
	read -n $CONTENT_LENGTH POST_DATA <&0
	body="$POST_DATA";
fi

# get all necessary data from environment variables (fastcgi)
uri=$(get_uri);
query=$(printenv "QUERY_STRING");
request_method=$(printenv "REQUEST_METHOD");

currentIFS=$IFS
IFS='=&'
args=($query)
IFS=$currentIFS
query_string_object="{}"

for ((i=0; i<${#args[@]}; i+=2))
do
	query_field=${args[i]};
	query_value=${args[i+1]};

    declare get_$query_field=$query_value;
    query_string_object=$(echo "$query_string_object" | jq --arg value "$query_value" ". + {$query_field: \$value}");
done