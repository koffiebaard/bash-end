#!/bin/bash

# validation rules for comics
read -r -d '' validation_rules <<'EOF'
{
	"title": {
		"mandatory": true,
		"longer_than": 2
	},
	"slug": {
		"mandatory": true,
		"longer_than": 2,
		"validate_regex": "^[a-zA-Z0-9\\-]+$"
	},
	"image": {
		"mandatory": true,
		"longer_than": 5,
		"contains": ".png"
	},
	"comic_width": {
		"mandatory": true,
		"integer": true,
		"greater_than": 624
	},
	"comic_height": {
		"mandatory": true,
		"integer": true,
		"greater_than": 100
	},
	"tooltip": {
		"mandatory": true,
		"longer_than": 5
	},
	"sublog": {
		"mandatory": true,
		"longer_than": 5
	},
	"posted_on": {
		"mandatory": true,
		"datetime": true
	}
}
EOF

read -r -d '' search_config <<'EOF'
{
	"search": "title"
}
EOF


function model_comic_get_by_id () {
	id=$1;

	comic=$($curdir/lib/mysql.sh selectOne "
		select
			 id
			,title
			,slug
			,image
			,comic_width
			,comic_height
			,tooltip
			,sublog
			,posted_on
		from
			comics
		where
			id = $(int $id);
	");

	echo $comic;
}

function model_comic_list () {
	db_search=$1;
	db_limit=$2;

	local where_query=$(build_where_query "search,slug,id,enabled" "$query_string_object" "$search_config");

	$curdir/lib/mysql.sh selectAll "
		select
			 id
			,title
			,slug
			,image
			,posted_on 
		from 
			comics
		
		$where_query

		order by 
			id desc 
		limit $(int $db_limit 10)
	;" | jq '.';
}

function model_comic_create () {
	data=$1;

	validation_errors=$(validate_fields_in_json "title,slug,image,comic_width,comic_height,tooltip,sublog,posted_on" "$data");

	if [[ $validation_errors != "" ]]; then
		echo "{\"error\": \"Validation failed\", \"message\": \"$validation_errors\"}"
		exit 1
	fi

	$curdir/lib/mysql.sh selectOne "
	insert into comics (
		 title
		,slug
		,image
		,comic_width
		,comic_height
		,tooltip
		,sublog
		,posted_on
	)
	values (
		 \"$(sanitize "$(o_o "$data" "title")")\" 
		,\"$(sanitize "$(o_o "$data" "slug")")\"
		,\"$(sanitize "$(o_o "$data" "image")")\"
		,\"$(sanitize "$(o_o "$data" "comic_width")")\"
		,\"$(sanitize "$(o_o "$data" "comic_height")")\"
		,\"$(sanitize "$(o_o "$data" "tooltip")")\"
		,\"$(sanitize "$(o_o "$data" "sublog")")\"
		,\"$(sanitize "$(o_o "$data" "posted_on")")\"
	);
	select LAST_INSERT_ID() as 'id';
	";
}

function model_comic_update () {

	id=$1;
	data=$2;

	fields=$(get_fields_from_json "$data");

	validation_errors=$(validate_fields_in_json "$fields" "$data");

	if [[ $validation_errors != "" ]]; then
		echo "{\"error\": \"Validation failed\", \"message\": \"$validation_errors\"}"
		exit 1
	fi

	local update_query=$(build_update_query "$data" "$fields");

	$curdir/lib/mysql.sh selectOne "
	update comics 
		set 
			$update_query
		where
			id = $(int $id)
	;
	";
}

function model_comic_delete_by_id () {
	id=$1;

	$curdir/lib/mysql.sh selectOne "
	delete
		from
			comics
		where
			id = $(int $id);
	";
}