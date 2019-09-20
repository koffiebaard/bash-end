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
	}
}
EOF

function model_comic_get_by_id () {
	id=$1;

	comic=$($curdir/db.sh "select id, title, slug, image, tooltip, sublog, posted_on from comics where id = $(int $id);" | jq '.[]');
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

	validation_errors=$(validate_fields_in_json "title,slug,image,comic_width,comic_height" "$data");

	if [[ $validation_errors != "" ]]; then
		echo "{\"error\": \"Validation failed\", \"message\": \"$validation_errors\"}"
		exit 1
	fi

	echo "lets create a comic!";
}
