#!/bin/bash


ROOTDIR="/mnt/linux"
MOUNTLIST="/dev /dev/pts /proc /sys /sys/firmware/efi/efivars /run"


mount_list() {
	for i in $MOUNTLIST; do
		echo "[+] mount $i in ${ROOTDIR}${i}."
		mount --bind "$i" "${ROOTDIR}${i}"
	done

	rm -f "${ROOTDIR}"/sys/firmware/efi/efivars/dump-* &> /dev/null
}


umount_list() {
	for i in $MOUNTLIST; do
		echo "[+] umount ${ROOTDIR}${i}."
		umount "${ROOTDIR}${i}"
	done
}


main() {
	local linuxpart
	local efipart
	local newefiuuid
	local oldefiuuid

	clear

	echo ""
	echo "[+] ---- "$(basename $0)" ----"
	echo ""

	if [ $UID -ne 0 ]; then
		echo "[-] Run as root."
		exit 1
	fi

	echo "[+] information."
	blkid | grep -vF "/dev/loop"
	echo ""

	read -p "[?] Enter the EFI partition (example: /dev/sda1): " efipart
	read -p "[?] Enter the Linux root partition (example: /dev/sda2): " linuxpart

	echo "[+] mount root partition $ROOTDIR."
	mkdir -p "$ROOTDIR"
	mount "$linuxpart" "$ROOTDIR"

	if [ ! -d "$ROOTDIR/boot/efi" ]; then
		echo "[-] partition $linuxpart is not a linux partition."
		umount "$ROOTDIR"
		exit 1
	fi

	echo "[+] mount EFI partition."
	mount "$efipart" "$ROOTDIR/boot/efi"

	if [ ! -d "$ROOTDIR/boot/efi/EFI" ]; then
		echo "[-] partition $efipart is not an EFI partition."
		umount "$ROOTDIR/boot/efi"
		umount "$ROOTDIR"
		exit 1
	fi

	mount_list

	newefiuuid=$(blkid | grep -F "$efipart" | cut -d" " -f2 | cut -d"=" -f2 | tr '"' ' ' | xargs)
	if [ ! "$newefiuuid" ]; then
		echo "[-] cannot read EFI UUID in $efipart."
		umount_list
		umount "$ROOTDIR/boot/efi"
		umount "$ROOTDIR"
		exit 1
	fi
	echo "[+] current EFI uuid: $newefiuuid."

	oldefiuuid=$(cat "$ROOTDIR/etc/fstab" | grep -vF '#' | grep -F "/boot/efi" | cut -d' ' -f1 | cut -d"=" -f2 | xargs)
	if [ ! "$oldefiuuid" ]; then
		echo "[-] cannot read EFI UUID in $ROOTDIR/etc/fstab."
		umount_list
		umount "$ROOTDIR/boot/efi"
		umount "$ROOTDIR"
		exit 1
	fi
	echo "[+] old EFI uuid in $linuxpart: $oldefiuuid."

	if [ "$newefiuuid" != "$oldefiuuid" ]; then
		echo "[+] replace $oldefiuuid by $newrfiuuid in $ROOTDIR/etc/fstab."
		sed -i "s#$oldefiuuid#$newefiuuid#g" "$ROOTDIR/etc/fstab"
	fi

	echo "[+] chroot in $ROOTDIR."
	echo "[!] Execute this command into the chroot:"
	echo ""
	echo "    grub-install; update-grub; exit"
	echo ""
	
	chroot "$ROOTDIR"

	echo ""
	echo "[+] finished."
}

main
exit 0

