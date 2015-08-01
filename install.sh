#!/sbin/busybox sh
# Remove files from previous installation -- if the user flashes the zip
# twice, there would otherwise be issues, creating a useless boot.img
rm -rf /tmp/kernel12
# Use keycheck to determine what kind of image the user wants. Give it 30 seconds.
# Vol+ means permissive, Vol- or no keypress means enforcing.
choose () {
	busybox chmod 777 /tmp/kernel12/tools/keycheck
	busybox timeout -t 30 /tmp/kernel12/tools/keycheck
	if [[ $? -eq 42 ]]; then
		mode="permissive"
	else
		busybox echo "shitshitshit"
		mode="enforcing"
	fi
}

# Extract the ramdisk, replace the crucial files, then compress it again.
ramdisk () {
	busybox dd if=/dev/block/mmcblk0p14 of=/tmp/kernel12/original.img
	busybox chmod 777 /tmp/kernel12/tools/unpackbootimg
	busybox mkdir /tmp/kernel12/work
	/tmp/kernel12/tools/unpackbootimg -i /tmp/kernel12/original.img -o /tmp/kernel12/work
	busybox mkdir /tmp/kernel12/work/combinedroot
	cd /tmp/kernel12/work/combinedroot
	busybox cat /tmp/kernel12/work/original.img-ramdisk.gz | busybox gzip -d | cpio -i -d
	busybox mkdir /tmp/kernel12/work/ramdisk
	cd /tmp/kernel12/work/ramdisk
	busybox cat /tmp/kernel12/work/combinedroot/sbin/ramdisk.cpio | cpio -i -d
	busybox cp /tmp/kernel12/res/fstab.qcom /tmp/kernel12/work/ramdisk/fstab.qcom
	busybox chmod 777 /tmp/kernel12/work/ramdisk/fstab.qcom
	busybox cp /tmp/kernel12/res/init.sh /tmp/kernel12/work/combinedroot/sbin/init.sh
	busybox chmod 777 /tmp/kernel12/work/combinedroot/sbin/init.sh
	busybox find . | cpio -o -H newc > /tmp/kernel12/work/combinedroot/sbin/ramdisk.cpio
	cd /tmp/kernel12/work/combinedroot
	busybox find . | cpio -o -H newc | gzip -c > /tmp/kernel12/work/original.img-ramdisk.gz
	cd /tmp/kernel12/work
}

cmdline () {
	# cd /tmp/kernel12/work
	# If Vol+ was pressed, check if cmdline already has the permissive tag
	# If not, echo it in
	if [ $mode = "permissive" ]; then
		if busybox cat /tmp/kernel12/work/original.img-cmdline | busybox grep androidboot.selinux=permissive; then
			:
		elif ! busybox cat /tmp/kernel12/work/original.img-cmdline | busybox grep androidboot.selinux=permissive; then
			busybox echo "$(busybox cat /tmp/kernel12/work/original.img-cmdline) androidboot.selinux=permissive" >/tmp/kernel12/work/original.img-cmdline
		fi
	# Else, check the cmdline and remove the tag if it's already present
	else
		if ! busybox cat /tmp/kernel12/work/original.img-cmdline | busybox grep androidboot.selinux=permissive; then
			:
		elif busybox cat /tmp/kernel12/work/original.img-cmdline | busybox grep androidboot.selinux=permissive; then
			# It's dirty, I know. I'm new to this.
			# Tips and/or pull requests appreciated!
			busybox cat /tmp/kernel12/work/original.img-cmdline | busybox sed 's/ androidboot.selinux=permissive//' >tmp
			busybox cat tmp >/tmp/kernel12/work/original.img-cmdline
		fi
	fi
	busybox cat /tmp/kernel12/work/original.img-cmdline
}

mkimg () {
	cd /tmp/kernel12
	busybox chmod 777 /tmp/kernel12/tools/mkbootimg
	/tmp/kernel12/tools/mkbootimg --kernel /tmp/kernel12/res/zImage --ramdisk /tmp/kernel12/work/original.img-ramdisk.gz --cmdline "$(busybox cat work/original.img-cmdline)" --board "$(busybox cat work/original.img-board)" --base "$(busybox cat work/original.img-base)" --pagesize "$(busybox cat work/original.img-pagesize)" --kernel_offset "$(busybox cat work/original.img-kerneloff)" --ramdisk_offset "$(busybox cat work/original.img-ramdiskoff)" --tags_offset "$(busybox cat work/original.img-tagsoff)" --dt /tmp/kernel12/res/dt.img -o /tmp/kernel12/boot.img
}

choose
ramdisk
cmdline
mkimg
