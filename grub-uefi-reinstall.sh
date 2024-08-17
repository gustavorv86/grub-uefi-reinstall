#!/bin/bash

ROOTDIR="/mnt/linux"
MOUNTLIST="/dev /dev/pts /proc /sys /sys/firmware/efi/efivars /run"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

linfo() {
	echo -e "$GREEN[+]$RESET $@"
}

lerror() {
	echo -e "$RED[-]$RESET $@"
}

mount_list() {
	for i in $MOUNTLIST; do
		linfo "mount $i in ${ROOTDIR}${i}."
		mount --bind "$i" "${ROOTDIR}${i}"
	done

	rm -f "${ROOTDIR}"/sys/firmware/efi/efivars/dump-* &> /dev/null
}

umount_list() {
	for i in $MOUNTLIST; do
		linfo "umount ${ROOTDIR}${i}."
		umount "${ROOTDIR}${i}"
	done
}

main() {
	local partlinux
	local partefi
	local efiuuidnew
	local efiuuidold

	clear

	echo ""
	linfo "---- "$(basename $0)" ----"
	echo ""

	if [ $UID -ne 0 ]; then
		lerror "run as root."
		exit 1
	fi

	linfo "information."
	blkid | grep -vF "/dev/loop"
	echo ""

	read -p "[?] enter the EFI partition (example: /dev/sda1): " partefi
	read -p "[?] enter the Linux root partition (example: /dev/sda2): " partlinux

	linfo "mount root partition $ROOTDIR."
	mkdir -p "$ROOTDIR"
	mount "$partlinux" "$ROOTDIR"

	if [ ! -d "$ROOTDIR/boot/efi" ]; then
		lerror "partition $partlinux is not a linux partition."
		umount "$ROOTDIR"
		exit 1
	fi

	linfo "mount EFI partition."
	mount "$partefi" "$ROOTDIR/boot/efi"

	if [ ! -d "$ROOTDIR/boot/efi/EFI" ]; then
		lerror "partition $partefi is not an EFI partition."
		umount "$ROOTDIR/boot/efi"
		umount "$ROOTDIR"
		exit 1
	fi

	mount_list

	efiuuidnew="$(blkid | grep -F "$partefi" | cut -d" " -f2 | cut -d"=" -f2 | tr '"' ' ' | xargs)"
	if [ ! "$efiuuidnew" ]; then
		lerror "cannot read EFI UUID in $partefi."
		umount_list
		umount "$ROOTDIR/boot/efi"
		umount "$ROOTDIR"
		exit 1
	fi
	linfo "current EFI uuid: $efiuuidnew."

	efiuuidold="$(cat "$ROOTDIR/etc/fstab" | grep -vF '#' | grep -F "/boot/efi" | cut -d' ' -f1 | cut -d"=" -f2 | xargs)"
	if [ ! "$efiuuidold" ]; then
		lerror "cannot read EFI UUID in $ROOTDIR/etc/fstab."
		umount_list
		umount "$ROOTDIR/boot/efi"
		umount "$ROOTDIR"
		exit 1
	fi
	linfo "old EFI uuid in $partlinux: $efiuuidold."

	if [ "$efiuuidnew" != "$efiuuidold" ]; then
		linfo "replace $efiuuidold by $newrfiuuid in $ROOTDIR/etc/fstab."
		sed -i "s#$efiuuidold#$efiuuidnew#g" "$ROOTDIR/etc/fstab"
	fi

	linfo "chroot in $ROOTDIR."
	linfo "execute grub install."
	
	chroot "$ROOTDIR" /bin/bash -c "grub-install; update-grub; exit"

	echo ""
	linfo "finished successfully."
}

main
exit 0
