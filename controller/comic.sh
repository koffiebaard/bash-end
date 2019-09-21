#!/bin/bash

source "$curdir/model/comic.sh"

function controller_comic_get () {

	id=$(get_id_from_uri $uri);
	comic=$(model_comic_get_by_id $id);

	if [[ "$comic" != "" ]]; then
		send_200 "$comic";
	else
		send_404 "Could not find comic"
	fi
}

function controller_comic_list () {

	list_of_comics=$(model_comic_list "$get_search" "$get_limit");

	send_200 "$list_of_comics";
}

function controller_comic_create () {

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

function controller_comic_update () {

	id=$(get_id_from_uri $uri);

	if is_int $id && ! empty $(model_comic_get_by_id $id); then

		result=$(model_comic_update "$id" "$body");

		# update has nothing to report? success!
		if [[ "$result" == "" ]]; then
			comic=$(model_comic_get_by_id $id);
			send_200 "$comic";

		# existence of error property strongly hints at an error
		elif valid_json "$result" && [[ $(o_o "$result" "error") != "" ]]; then
			send_response 400 "$result";

		# we should get either of the above. so it's a 500.
		else
			send_error 500 "$result";
		fi
	else
		send_404 "ID doesn't exist."
	fi
}

function controller_comic_delete () {

	id=$(get_id_from_uri $uri);

	if is_int $id && ! empty $(model_comic_get_by_id $id); then

		result=$(model_comic_delete_by_id "$id");

		# delete has nothing to report? success!
		if [[ "$result" == "" ]]; then
			send_response 200 "{\"message\": \"Comic #$id is deleted\"}"

		# existence of error property strongly hints at an error
		elif valid_json "$result" && [[ $(o_o "$result" "error") != "" ]]; then
			send_response 400 "$result";

		# we should get either of the above. so it's a 500.
		else
			send_error 500 "$result";
		fi
	else
		send_404 "ID doesn't exist."
	fi
}
