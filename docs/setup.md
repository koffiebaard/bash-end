[![Bash-end](https://static.consolia-comic.com/bash-end-underline.png)](http://quax.net/bash-end)


## Setup docs

This is the setup docs. You can read this, the [reference docs](ref.md) or [go home](../readme.md).


## Features

The entry script for bash-end is `api.sh`. It looks roughly like this:

```bash
curdir="$(dirname "$0")"

source "$curdir/internals.sh"
source "$curdir/controller/comic.sh"

add_route "GET"     /comic/[0-9]+$    "controller_comic_get"
add_route "GET"     /comic            "controller_comic_list"
add_route "POST"    /comic            "controller_comic_create"
add_route "PUT"     /comic/[0-9]+$    "controller_comic_update"
add_route "DELETE"  /comic/[0-9]+$    "controller_comic_delete"

add_404_route                         "default_404"
```

It's pretty self explanatory. matching the request method and the string/regex for the uri - and run the function in the last argument if it matches.

You don't have to use controllers and models. Any function will do. 


## Controller

The example controller looks something like this:

```bash
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
```

As you can see the name of the function matches to one in the routing. It fetches the ID from the url (like /comic/200 gets 200), uses a model function to get the record from the database, and either sends back either a 200 or a 404.

## Model

The models have a tiny bit extra, which is two configuration objects at the top. Beyond that the idea is the same. A list of functions, and it does whatever you want it to do.

```bash
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
```

The first configuration object is a list of `validation_rules`. You can assign all kinds of validations to any field passing through. This is used in PUT and POST calls, by validating like this:

```bash
validation_errors=$(validate_fields_in_json "title,slug" "$data");
```

The functions have only one task, which is talking to the database. For mysql there's a db handler called `mysql.sh`. The syntax is like this:

```bash
$curdir/lib/mysql.sh selectOne "select * from comics where id = 1337;"

$curdir/lib/mysql.sh selectAll "select * from comics limit 10;"
```

Specify if you want one or more records (selectOne vs selectAll) and specify the query you want to execute. `mysql.sh` will look for the db connection info in the yaml file.


## Config.yaml

There's a configuration at `conf/config.yaml`, which holds your db connection info. You can also specify the `basedir`, which is the directory the API is under, if any. Otherwise you can leave it empty.

```bash
db_host: localhost                      # host for the database
db_name: testdb                         # database name
db_username: supersecret                # username for the database
db_password: alsosecretbutpredictable   # password for the database
basedir: bash-end                       # if the API is under a basedir, list it here
```


## Fastcgi

You can use something like fcgiwrap and just point it to the entry script (`api.sh`). It works immediately.

With nginx you can configure it [like this](../conf/nginx-bash-end.conf), which is the configuration Docker uses to build the environment.

For the lazy, it looks something like this:

```bash
location / {
	gzip off;
	root /var/www/;
	autoindex on;
	fastcgi_pass unix:/var/run/fcgiwrap.socket;
	include /etc/nginx/fastcgi_params;
	fastcgi_param SCRIPT_FILENAME /var/www/api.sh;
}
```



