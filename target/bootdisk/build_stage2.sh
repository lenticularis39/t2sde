
echo_header "Creating 2nd stage filesystem:"
mkdir -p $disksdir/2nd_stage
cd $disksdir/2nd_stage
mkdir -p mnt/source mnt/target
#
package_map='       +tcp_wrappers       +glibc22            -gcc3
+00-dirtree         -linux24-src        +linux24            +glibc23
-binutils           -gcc2               -bin86              +cpuburn
+memtest86          +mine               -termcap            +ncurses
+readline           -strace             -ltrace             -perl5
-m4                 -time               -gettext            -zlib
+bash               +attr               +acl                +findutils
+mktemp             +coreutils          +diffutils          +patch
-make               +grep               +sed                +gzip
+tar                +gawk               -flex               +bzip2
-texinfo            +less               -groff              -man
+nvi                -bison              +bc                 +cpio
+ed                 -autoconf           -automake           -libtool
+curl               +wget               +dialog             +minicom
+lrzsz              +mtools             +rsync              +tcpdump
+sysvinit           +shadow             +util-linux         +hdparm
+e2fsprogs          +reiserfsprogs      +genromfs           +lvm
+raidtools          +net-tools          +procps             +psmisc
+modutils           +pciutils           -cron               +jfsutils
+sysklogd           +devfsd             +setserial          +dump
+netkit-base        +netkit-ftp         +netkit-telnet      +netkit-tftp
+portmap            +iproute2           +grub               +lilo
+sysfiles           +libpcap            +bonnie++           -nasm
-dietlibc           -linux25-src        +linux25            +iptables
+xfsprogs           +module-init-tools  -linux24-header     -linux25-header
+yaboot             +aboot              +wireless-tools     +pdisk
+parted             +mkdosfs            +rockplug           +eject'

echo_status "Extracting the packages archives."
for x in $( ls ../../pkgs/*.tar.bz2 | tr . / | cut -f8 -d/ )
do
	if echo "" $package_map "" | grep -q " +$x "
	then
		echo_status "\`- Extracting $x.tar.bz2 ..."
		tar --use-compress-program=bzip2 -xpf ../../pkgs/$x.tar.bz2
	elif ! echo "" $package_map "" | grep -q " -$x "
	then
		echo_error "\`- Not found in \$package_map: $x"
		echo_error "    ... fix target/$target/build.sh"
	fi
done
#
echo_status "Remove the stuff we don't need ..."
rm -rf usr/doc usr/man usr/info usr/share/* var/adm/*
rm -rf usr/{include,src} usr/*-linux-gnu usr/lib/*.{a,la,o}
rm -rf usr/lib/*/ boot/*-rock boot/System.map
#
echo_status "Installing some terminfo databases ..."
tar --use-compress-program=bzip2 -xf ../../pkgs/ncurses.tar.bz2	\
	usr/share/terminfo/x/xterm	usr/share/terminfo/a/ansi	\
	usr/share/terminfo/n/nxterm	usr/share/terminfo/l/linux	\
	usr/share/terminfo/v/vt200	usr/share/terminfo/v/vt220	\
	usr/share/terminfo/v/vt100	usr/share/terminfo/s/screen
#
echo_status "Creating 2nd stage linuxrc."
cp $base/target/$target/linuxrc2.sh linuxrc ; chmod +x linuxrc
echo '$STONE install' > etc/stone.d/default.sh
#
echo_status "Creating 2nd_stage.tar.gz archive."
tar -czf ../2nd_stage.tar.gz * ; cd ..


echo_header "Creating small 2nd stage filesystem:"
mkdir -p 2nd_stage_small ; cd 2nd_stage_small
mkdir dev proc tmp bin lib etc share
mkdir -p mnt/source mnt/target
ln -s bin sbin ; ln -s . usr

#

progs="agetty bash cat cp date dd df ifconfig ip ln ls mine mkdir mke2fs \
       mkswap mount mv rm reboot route sleep swapoff swapon sync umount wget"

progs="$progs fdisk sfdisk"

if [ $arch = ppc ] ; then
	progs="$progs mac-fdisk pdisk"
fi

echo_status "Copy the most important programs ..."
for x in $progs ; do
	fn=""
	[ -f ../2nd_stage/bin/$x ] && fn="bin/$x"
	[ -f ../2nd_stage/sbin/$x ] && fn="sbin/$x"
	[ -f ../2nd_stage/usr/bin/$x ] && fn="usr/bin/$x"
	[ -f ../2nd_stage/usr/sbin/$x ] && fn="usr/sbin/$x"

	if [ "$fn" ] ; then
		cp ../2nd_stage/$fn $fn
	else
		echo_error "\`- Program not found: $x"
	fi
done

#

echo_status "Copy the required libraries ..."
found=1 ; while [ $found = 1 ]
do
	found=0
	for x in ../2nd_stage/lib ../2nd_stage/usr/lib
	do
		for y in $( cd $x ; ls *.so.* 2> /dev/null )
		do
			if [ ! -f lib/$y ] &&
			   grep -q $y bin/* lib/* 2> /dev/null
			then
				echo_status "\`- Found $y."
				cp $x/$y lib/$y ; found=1
			fi
		done
	done
done
#
echo_status "Copy linuxrc."
cp ../2nd_stage/linuxrc .
#
echo_status "Creating links for identical files."
while read ck fn
do
	if [ "$oldck" = "$ck" ] ; then
		echo_status "\`- Found $fn -> $oldfn."
		rm $fn ; ln $oldfn $fn
	else
		oldck=$ck ; oldfn=$fn
	fi
done < <( find -type f | xargs md5sum | sort )
#
echo_status "Creating 2nd_stage_small.tar.gz archive."
tar -czf ../2nd_stage_small.tar.gz * ; cd ..
