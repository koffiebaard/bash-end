#!/bin/bash

source "$curdir/model/comic.sh"

function comic_controller_get () {

	id=$(get_id_from_uri $uri);
	comic=$(model_comic_get_by_id $id);

	if [[ "$comic" != "" ]]; then
		send_200 "$comic";
	else
		send_404 "Could not find comic"
	fi
}

function comic_controller_list () {

	list_of_comics=$(model_comic_list "$get_search" "$get_limit");

	send_200 "$list_of_comics";
}

function comic_controller_create () {

	result=$(model_comic_create "$body");

	if [[ $? == 0 ]]; then
		send_response 200 "$result";
	else
		send_response 400 "$result";
	fi
}

function comic_controller_update () {

	id=$(get_id_from_uri $uri);
	send_404 "PUT is not implemented yet"
}
