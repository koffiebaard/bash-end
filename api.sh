#!/bin/bash 

curdir="$(dirname "$0")"

source "$curdir/internals.sh"
source "$curdir/controller/comic.sh"


add_route "GET" 	/comic/[0-9]+$ 		"controller_comic_get"
add_route "GET" 	/comic 				"controller_comic_list"
add_route "POST" 	/comic 				"controller_comic_create"
add_route "PUT" 	/comic/[0-9]+$ 		"controller_comic_update"
add_route "DELETE" 	/comic/[0-9]+$ 		"controller_comic_delete"

add_404_route 							"default_404"
