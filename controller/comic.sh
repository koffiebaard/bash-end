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

	# is there a valid ID? everything went well
	if [[ $(o_o "$result" "id") != "" ]] && is_int $(o_o "$result" "id"); then
		comic=$(model_comic_get_by_id $(o_o "$result" "id"));
		send_200 "$comic";

	# error property? something went wrong on the db side
	elif [[ $(o_o "$result" "error") != "" ]]; then
		send_response 400 "$result";

	# we should get either of the above. so it's a 500.
	else
		send_error 500 "Error: something went wrong. There's no ID and no error from the database.";
	fi
}

function comic_controller_update () {

	id=$(get_id_from_uri $uri);
	send_404 "PUT is not implemented yet"
}
