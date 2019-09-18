#!/bin/bash 

curdir="$(dirname "$0")"
basedir="bashtest"

source "$curdir/internals.sh"

if req "GET" "/comic"; then
	
	if [[ "$get_search" != "" ]]; then
		list_of_comics=$(/web/bashtest/db.sh "select id, title, slug, image, posted_on from comics where title like \"%$(sanitize $get_search)%\" order by id desc limit $(int $get_limit 10);" | jq '.');
	else
		list_of_comics=$(/web/bashtest/db.sh "select id, title, slug, image, posted_on from comics order by id desc limit $(int $get_limit 10);" | jq '.');
	fi 

	send_200 "$list_of_comics";

elif req "GET" /comic/[0-9]+; then

	id=$(get_id_from_uri $uri)
	comic=$(/web/bashtest/db.sh "select id, title, slug, image, tooltip, sublog, posted_on from comics where id = $(int $id);" | jq '.[]');

	if [[ "$comic" != "" ]]; then
		send_200 "$comic";
	else
		send_404 "Could not find comic"
	fi

elif req "POST" "/comic"; then
	send_404 "Well POST is not implemented yet."

elif req "PUT" /comic/[0-9]+; then
	send_404 "Well PUT is not implemented yet."

else
	send_404 "Not found"
fi

exit 0
