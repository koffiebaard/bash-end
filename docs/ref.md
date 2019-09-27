[![Bash-end](https://static.consolia-comic.com/bash-end-underline.png)](http://quax.net/bash-end)

This is the reference docs. You can read this, the [setup docs](setup.md) or [go home](../readme.md).

## Data handling

Casting to an int:
```bash
$(int "13.37"); #returns 13
```

Check if it's an int:
```bash
if is_int "13.37"; then
	echo "yay it's an int!";
else
	echo "aww.";
fi
```


Is a string shorter than N:

```bash
if string_shorter_than "test" 5
	echo "aww.";
else
	echo "i finally have something that's long enough!";
fi
```


## URL handling

Get an ID from the url:

```bash
$(get_id_from_uri "/user/1337") # returns 1337
```


## Database

Query the mysql database:

```bash
$curdir/lib/mysql.sh selectOne "select * from comics where id = 1337;"

$curdir/lib/mysql.sh selectAll "select * from comics limit 10;"
```

Specify if you want one or more records (selectOne vs selectAll) and specify the query you want to execute. `mysql.sh` will look for the db connection info in the yaml file.