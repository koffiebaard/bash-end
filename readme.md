[![Bash-end](https://static.consolia-comic.com/bash-end-underline.png)](http://quax.net/bash-end)

  Fast, unopinionated, minimalist API framework written solely in Bash.

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

## Features

  * Efficient routing
  * Easily built controllers and models
  * Powerful input validation system
  * Only one dependency; jq
  * Decent test coverage
  * Out of the box MySQL support


## Quick Start

The framework itself is just a few bash scripts. You can easily tie it into a webserver using *fastcgi*.

There is one dependency: *jq*. So we just install it and get Bash-end from the repo. Like so:

```bash
$ git clone https://github.com/koffiebaard/bash-end/
$ apt install jq
```


If you want to use mysql, you also need *mysql-client*:

```bash
$ apt install mysql-client
```

You can run the whole thing with nginx and fcgiwrap, or whichever other flavors you prefer.

[Read more about setting up Bash-end](docs/setup.md)
[Reference docs](docs/ref.md)

## Database

lib/mysql.sh is the database connection handler. As input it accepts a query, and it returns json as output. There's a *config.yaml* file in the conf folder that contains your db connection info. An example file:

```bash
db_host: localhost                      # host for the database
db_name: testdb                         # database name
db_username: supersecret                # username for the database
db_password: alsosecretbutpredictable   # password for the database
basedir: bash-end                       # if the API is under a basedir, list it here
```

You can query like this:

```bash
$curdir/lib/mysql.sh selectAll "
    select
       id
      ,title
      ,slug
      ,image
      ,posted_on 
    from 
      comics
    limit 10
    ;"
```

## Docker

You can also run it with Docker:

```bash
$ git clone https://github.com/koffiebaard/bash-end/
$ docker build -t bash-end .
$ docker run --name=bash-end-container -d -p 6969:6969 bash-end
```

You can now view the API at: *http://localhost:6969*.


## Philosophy

  The Bash-end© Philosophy™ extends to all software. Why choose for big complex projects with hundreds of modules, where simple bash scripts more than suffice?

  That's just silly.

  Replace your ridiculously huge API framework with two or three bash scripts. Do it. Do it now.

  Bash-end is simple to use and unopinionated, with a bunch of tools you can use to make your life easier. Or not. It's Bash, so extend it with whatever you want. Sky is the limit! But not even that. Let's get Bash to run on fucking Mars.


## Examples

  The best example is the API built for the webcomic Consolia. That example is currently in the repo itself. The controller and model, as well as the routing in api.sh, are doing CRUD for comics in MySQL.


## Contributing

Feel free to contribute! Ping me or send a pull request and let's go.

## License

Bash-end is under the MIT license, but without me shipping the copyright text with the project. That's too much effort.
