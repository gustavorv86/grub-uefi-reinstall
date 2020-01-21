#!/bin/bash

## Edit this configuration ##

LINUX_PARTITION=/dev/sdb1
EFI_PARTITION=/dev/sda2

## End configuration ##

TARGET=/media/linux
CHROOT_INSTALLER=${TARGET}/grub-reinstall.bash

if [[ $UID -ne 0 ]]; then
	echo "Run as root..."
	exit 1
fi

mkdir -p ${TARGET}
mount ${LINUX_PARTITION} ${TARGET}
mount ${EFI_PARTITION} ${TARGET}/boot/efi

mount --bind /sys ${TARGET}/sys
mount --bind /proc ${TARGET}/proc
mount --bind /dev ${TARGET}/dev

echo "#!/bin/bash"                                          >  ${CHROOT_INSTALL}
echo "mount -t efivarfs efivarfs /sys/firmware/efi/efivars" >> ${CHROOT_INSTALL}
echo "rm -f /sys/firmware/efi/efivars/dump-* &> /dev/null"  >> ${CHROOT_INSTALL}
echo "grub-install"                                         >> ${CHROOT_INSTALL}
echo "update-grub"                                          >> ${CHROOT_INSTALL}
echo ""                                                     >> ${CHROOT_INSTALL}
echo "efibootmgr --verbose"                                 >> ${CHROOT_INSTALL}
echo "echo"                                                 >> ${CHROOT_INSTALL}
echo "echo 'Install finished'"                              >> ${CHROOT_INSTALL}
echo "echo"                                                 >> ${CHROOT_INSTALL}

chmod a+x ${CHROOT_INSTALL}

echo
echo
echo "Chroot: ${TARGET}"
echo "Linux partiton: ${LINUX_PARTITION}"
echo "EFI partition: ${EFI_PARTITION}"
echo
echo "Execute the next commands:"
echo "./"`basename ${CHROOT_INSTALL}`"; exit"
echo

chroot ${TARGET}
## CHROOT_INSTALLER executed by the user and exit...
rm -f ${CHROOT_INSTALLER}

umount ${TARGET}/dev       &> /dev/null
umount ${TARGET}/proc      &> /dev/null
umount ${TARGET}/sys       &> /dev/null
umount ${TARGET}/boot/efi  &> /dev/null
umount ${TARGET}

echo "Done"
echo

exit 0
