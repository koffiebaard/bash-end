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

function model_comic_get_by_id () {
	id=$1;

	comic=$($curdir/db.sh "
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
	" | jq '.[]');

	echo $comic;
}

function model_comic_list () {
	db_search=$1;
	db_limit=$2;

	if [[ "$db_search" != "" ]]; then
		list_of_comics=$($curdir/db.sh "select id, title, slug, image, posted_on from comics where title like \"%$(sanitize $db_search)%\" order by id desc limit $(int $db_limit 10);" | jq '.');
	else
		list_of_comics=$($curdir/db.sh "select id, title, slug, image, posted_on from comics order by id desc limit $(int $db_limit 10);" | jq '.');
	fi

	echo "$list_of_comics";
}


function model_comic_create () {
	data=$1;

	validation_errors=$(validate_fields_in_json "title,slug,image,comic_width,comic_height,tooltip,sublog,posted_on" "$data");

	if [[ $validation_errors != "" ]]; then
		echo "{\"error\": \"Validation failed\", \"message\": \"$validation_errors\"}"
		exit 1
	fi

	echo "lets create a comic!";
	
	$curdir/db.sh "
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
