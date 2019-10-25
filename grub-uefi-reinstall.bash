#!/bin/bash

## TODO: Check efi and linux partition automatically

## Edit this configuration

LINUX_PARTITION=/dev/sdb1
EFI_PARTITION=/dev/sda2

## End configuration

TARGET=/media/linux

mkdir -p ${TARGET}
mount ${LINUX_PARTITION} ${TARGET}
mount ${EFI_PARTITION} ${TARGET}/boot/efi

mount --bind /sys ${TARGET}/sys
mount --bind /proc ${TARGET}/proc
mount --bind /dev ${TARGET}/dev

## TODO: Check ${EFI_PARTITION} UUID and ${TARGET}/etc/fstab EFI UUID

echo "#!/bin/bash"                                          >  ${TARGET}/install.sh
echo "mount -t efivarfs efivarfs /sys/firmware/efi/efivars" >> ${TARGET}/install.sh
echo "rm /sys/firmware/efi/efivars/dump-* &> /dev/null"     >> ${TARGET}/install.sh
echo "grub-install"                                         >> ${TARGET}/install.sh
echo "update-grub"                                          >> ${TARGET}/install.sh
echo ""                                                     >> ${TARGET}/install.sh
echo "efibootmgr --verbose"                                 >> ${TARGET}/install.sh
echo "echo"                                                 >> ${TARGET}/install.sh
echo "echo 'Install finished'"                              >> ${TARGET}/install.sh
echo "echo"                                                 >> ${TARGET}/install.sh

chmod a+x ${TARGET}/install.sh

echo
echo
echo "Chroot: ${TARGET}"
echo "Linux partiton: ${LINUX_PARTITION}"
echo "EFI partition: ${EFI_PARTITION}"
echo
echo "Execute the next command:"
echo "./install.sh; exit"
echo

chroot ${TARGET}
## ./install.sh executed by the user
rm -f ${TARGET}/install.sh

umount ${TARGET}/dev
umount ${TARGET}/proc
umount ${TARGET}/sys
umount ${TARGET}/boot/efi
umount ${TARGET}

echo "Done"
echo

