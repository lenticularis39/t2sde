# --- T2-COPYRIGHT-NOTE-BEGIN ---
# This copyright note is auto-generated by ./scripts/Create-CopyPatch.
# 
# T2 SDE: package/.../sysfiles/stone_mod_setup.sh
# Copyright (C) 2004 - 2005 The T2 SDE Project
# Copyright (C) 1998 - 2003 ROCK Linux Project
# 
# More information can be found in the files COPYING and README.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License. A copy of the
# GNU General Public License can be found in the file COPYING.
# --- T2-COPYRIGHT-NOTE-END ---
#
# This module should only be executed once directly after the installation

make_fstab() {
	tmp1=`mktemp` ; tmp2=`mktemp`

	cat <<- EOT > $tmp2
/dev/root / auto defaults 0 0
none /proc proc defaults 0 0
none /dev devfs defaults 0 0
none /dev/pts devpts defaults 0 0
none /dev/shm ramfs defaults 0 0
none /sys sysfs defaults 0 0
#none /tmp tmpfs defaults 0 0
EOT

	for x in /dev/cdroms/cdrom[0-9] ; do
	    if [ -e $x ] ; then
		trg=/mnt/${x/*\//} ; trg=${trg/cdrom0/cdrom}
		mkdir -p $trg
		echo "$x $trg iso9660 ro,noauto 0 0" >> $tmp2
	    fi
	done

	for x in /dev/floppy/[0-9] ; do
	    if [ -e $x ] ; then
		trg=/mnt/floppy${x/*\//} ; trg=${trg/floppy0/floppy}
		mkdir -p $trg
		echo "$x $trg auto sync,noauto 0 0" >> $tmp2
	    fi
	done

	sed -e "s/ nfs [^ ]\+/ nfs rw/" < /etc/mtab | \
		sed "s/ rw,/ /; s/ rw / defaults /" >> $tmp2
	grep '^/dev/' /proc/swaps | cut -f1 -d' ' | \
		sed 's,$, swap swap defaults 0 0,' >> $tmp2

	cut -f2 -d' ' < $tmp2 | sort -u | while read dn ; do
		grep " $dn " $tmp2 | tail -n 1; done > $tmp1

	cat << EOT > $tmp2
ARGIND == 1 {
    for (c=1; c<=NF; c++) if (ss[c] < length(\$c)) ss[c]=length(\$c);
}
ARGIND == 2 {
    for (c=1; c<NF; c++) printf "%-*s",ss[c]+2,\$c;
    printf "%s\n",\$NF;
}
EOT
	gawk -f $tmp2 $tmp1 $tmp1 | \
		sed 's,\( ext[23] .*\) 0  0$,\1 0  1,' > /etc/fstab

	while read a b c d e f ; do
		printf "%-60s %s\n" "$(
			printf "%-50s %s" "$(
				printf "%-40s %s" "$(
					printf "%-25s %s" "$a" "$b"
				)" $c
			)" "$d"
		)" "$e $f"
	done < /etc/fstab | tr ' ' '\240' > $tmp1

	gui_message $'Auto-created /etc/fstab file:\n\n'"$( cat $tmp1 )"
	rm -f $tmp1 $tmp2
}

set_rootpw() {
	if [ "$SETUPG" = dialog ] ; then
		tmp1="`mktemp`" ; tmp2="`mktemp`" ; rc=0
		gui_dialog --nocancel --passwordbox "Setting a root password. `
			`Type password:" 8 70 > $tmp1
		gui_dialog --nocancel --passwordbox "Setting a root password. `
			`Retype password:" 8 70 > $tmp2
		if [ -s $tmp1 ] && cmp -s $tmp1 $tmp2 ; then
			echo -n "root:" > $tmp1 ; echo >> $tmp2
			cat $tmp1 $tmp2 | chpasswd
		else
			gui_message "Password 1 and password 2 are `
					`not the same" ; rc=1
		fi
		rm $tmp1 $tmp2
		return $rc
	else
		passwd root
		return $?
	fi
}

main() {
	ldconfig
	export gui_nocancel=1

	make_fstab
	$STONE general set_keymap
	while ! set_rootpw; do :; done
	$STONE general set_tmarea
	$STONE general set_dtime
	$STONE general set_locale
	$STONE general set_vcfont

	cron.run

	# run the postinstall scripts right here
	for x in /etc/postinstall.d/* ; do
		[ -f $x ] || continue
		echo "Running $x ..."
		$x
	done

	unset gui_nocancel
	exec $STONE
}

