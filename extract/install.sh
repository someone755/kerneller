#!/sbin/sh
# Define commonly used/long directory names.
boot="/dev/block/platform/msm_sdcc.1/by-name/boot"
tools="/tmp/kerneller/tools"
work="/tmp/kerneller/work"
OUTFD=`ps | grep -v "grep" | grep -oE "update(.*)" | cut -d" " -f3`;
ui_print() { echo "ui_print $1" >&$OUTFD; echo "ui_print" >&$OUTFD; }
# Remove files from previous installation -- if the user flashes the zip
# twice, there would otherwise be issues, creating a useless boot.img
rm -rf $work;
# Use keycheck to determine what kind of image the user wants. Give it 30 seconds.
# Vol+ means permissive, Vol- or no keypress means enforcing.
choose () {
	ui_print "You now have 30 seconds to press vol+/-";
	ui_print " ";
	ui_print "Pressing volume up will set SELinux to permissive.";
	ui_print "Pressing volume down or not pressing anything will set it to enforcing.";
	ui_print "Your move.";
	ui_print " ";
	chmod 777 $tools/keycheck;
	timeout -t 30 $tools/keycheck;
	if [[ $? -eq 42 ]]; then
		ui_print "Making permissive image";
		mode="permissive";
	else
		ui_print "Making enforcing image";
		mode="enforcing";
	fi
}
# Extract the ramdisk, replace the crucial files, then compress it again.
ramdisk () {
	ui_print "Modifying ramdisk";
	dd if=$boot of=/tmp/kerneller/original.img;
	chmod 777 $tools/unpackbootimg;
	mkdir $work;
	$tools/unpackbootimg -i /tmp/kerneller/original.img -o $work;
	mkdir $work/combinedroot;
	cd $work/combinedroot;
	cat $work/original.img-ramdisk.gz | gzip -d | cpio -i -d;
	mkdir $work/ramdisk;
	cd $work/ramdisk;
	cat $work/combinedroot/sbin/ramdisk.cpio | cpio -i -d;
# At this point the ramdisk is completely extracted: begin making changes (copy and chmod)
	cp /tmp/kerneller/res/fstab.qcom $work/ramdisk/fstab.qcom;
	cp /tmp/kerneller/res/init.sh $work/combinedroot/sbin/init.sh;
	chmod 777 $work/ramdisk/fstab.qcom;
	chmod 777 $work/combinedroot/sbin/init.sh;
# Changes that are not related to the ramdisk and still need to be reviewed:
	# rm -rf /system/bin/mpdecision;
	# rm -rf /system/bin/thermanager;
# Repack the ramdisk back completely
	find . | cpio -o -H newc > $work/combinedroot/sbin/ramdisk.cpio;
	cd $work/combinedroot;
	find . | cpio -o -H newc | gzip -c > $work/original.img-ramdisk.gz;
}

cmdline () {
	cd $work
	# If Vol+ was pressed, check if cmdline already has the permissive tag
	# If yes, move on. If not, echo it in.
	if [ $mode = "permissive" ]; then
		if cat $work/original.img-cmdline | grep androidboot.selinux=permissive; then
			:
		elif ! cat $work/original.img-cmdline | grep androidboot.selinux=permissive; then
			 echo "$(cat $work/original.img-cmdline) androidboot.selinux=permissive" >$work/original.img-cmdline
		fi
	# Else, check the cmdline and remove the tag if it's already present
	else
		if ! cat $work/original.img-cmdline | grep androidboot.selinux=permissive; then
			:
		elif cat $work/original.img-cmdline | grep androidboot.selinux=permissive; then
			# It's dirty, I know. I'm new to this.
			# Tips and/or pull requests appreciated!
			cat $work/original.img-cmdline | sed 's/ androidboot.selinux=permissive//' >tmp
			cat tmp >$work/original.img-cmdline
		fi
	fi
	cat $work/original.img-cmdline
}

mkimg () {
	chmod 777 $tools/mkbootimg
	$tools/mkbootimg --kernel /tmp/kerneller/res/zImage --ramdisk $work/original.img-ramdisk.gz --cmdline "$(cat $work/original.img-cmdline)" --board "$(cat $work/original.img-board)" --base "$(cat $work/original.img-base)" --pagesize "$(cat $work/original.img-pagesize)" --kernel_offset "$(cat $work/original.img-kerneloff)" --ramdisk_offset "$(cat $work/original.img-ramdiskoff)" --tags_offset "$(cat $work/original.img-tagsoff)" --dt /tmp/kerneller/res/dt.img -o /tmp/kerneller/boot.img
}

modcpy () {
	cp -f /tmp/kerneller/modules/* /system/lib/modules/
}

# Functions are all set: Run them in order
choose
ramdisk
cmdline
mkimg
# Check for one of the files we copied: if it's there, the boot
# image was repacked succesfully. If not, flashing it would not
# allow the device to boot.
if [ -f $work/ramdisk/fstab.qcom ]; then
  ui_print "Done messing around!";
  ui_print "Writing the new boot.img...";
  dd if=/tmp/kerneller/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
  ui_print "Copying modules...";
  modcpy
else
  ui_print "Error creating working boot image, aborting install!";
  ui_print "Are you running a compatible recovery?";
fi
