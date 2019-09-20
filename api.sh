#!/bin/bash 

curdir="$(dirname "$0")"

source "$curdir/internals.sh"
source "$curdir/controller/comic.sh"


add_route "GET" 	/comic/[0-9]+$ 		"comic_controller_get"
add_route "GET" 	/comic 				"comic_controller_list"
add_route "POST" 	/comic 				"comic_controller_create"
add_route "PUT" 	/comic/[0-9]+$ 		"comic_controller_update"

add_404_route 							"default_404"
