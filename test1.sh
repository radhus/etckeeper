#!/bin/bash

FILESTEST="one two three fo'ur five.dpkg-old"
DIR="testdir"

rm -rf "$DIR"
mkdir "$DIR"
for x in $FILESTEST; do
    touch "$DIR/$x"
    chmod +x "$DIR/$x"
done
chmod -x "$DIR/two"

old() {
    lsscripts() {
       LANG=C perl -e '
           $dir=shift;
           print join "\n", grep { ! -d $_ && -x $_ }
               grep /^\Q$dir\/\E[-a-zA-Z0-9]+$/,
               glob "$dir/*";
       ' "$1"
    }
    
    for script in $(lsscripts "$DIR"); do
       echo "$script" "$@"
   done
}

new() {
    for script in $DIR/*; do
	if [ ! -d "$script" -a -x "$script" ]; then
        echo "$script" | grep -q -E "/[-a-zA-Z0-9]+$"
		[ $? -eq 0 ] && echo "$script" "$@"
    fi
    done
}

echo "Old:"
old

echo "New:"
new
