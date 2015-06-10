#!/bin/bash

FILESTEST="one two three fo'u'r five.dpkg-old"
DIR="testdir"

rm -rf "$DIR"
mkdir "$DIR"
for x in $FILESTEST; do
    touch "$DIR/$x"
    chmod +x "$DIR/$x"
done
chmod -x "$DIR/two"
# to test 'maybe chown/chgrp'
sudo chown root:nogroup "$DIR/five.dpkg-old"

NOVCS="$DIR"

old() {
    find $NOVCS \( -type f -or -type d \) -print | sort | perl -ne '
    	BEGIN { $q=chr(39) }
    	sub uidname {
    		my $want=shift;
    		if (exists $uidcache{$want}) {
    			return $uidcache{$want};
    		}
    		my $name=scalar getpwuid($want);
    		return $uidcache{$want}=defined $name ? $name : $want;
    	}
    	sub gidname {
    		my $want=shift;
    		if (exists $gidcache{$want}) {
    			return $gidcache{$want};
    		}
    		my $name=scalar getgrgid($want);
    		return $gidcache{$want}=defined $name ? $name : $want;
    	}
    	chomp;
    	my @stat=stat($_);
    	my $mode = $stat[2];
    	my $uid = $stat[4];
    	my $gid = $stat[5];
    	s/$q/$q"$q"$q/g; # escape single quotes
    	s/^/$q/;
    	s/$/$q/;
    	if ($uid != $>) {
    		printf "maybe chown $q%s$q %s\n", uidname($uid), $_;
    	}
    	if ($gid != $)) {
    		printf "maybe chgrp $q%s$q %s\n", gidname($gid), $_;
    	}
    	printf "maybe chmod %04o %s\n", $mode & 07777, $_;
    '
}

new() {
    maybe_chmod_chown()
    {
       euid=$(id -u)
       egid=$(id -g)
       q="'"
       while read x; do
           stat=$(stat -c "%f:%u:%g:%a:%U:%G" $x)
           IFS=":" read mode uid gid perm uname gname <<< "$stat"
           x=$q$(echo $x | sed "s/$q/$q\"$q\"$q/g")$q
           if [ $uid -ne $euid ]; then
               echo maybe chown "'$uname'" $x
           fi
           if [ $gid -ne $egid ]; then
               echo maybe chgrp "'$gname'" $x
           fi
           echo maybe chmod 0$perm $x
       done
    }
    
    find $NOVCS \( -type f -or -type d \) -print  | sort | maybe_chmod_chown
}

echo "Old:"
old

echo "New:"
new
