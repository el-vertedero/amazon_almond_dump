#!/vendor/bin/sh

ret=0
echo "check tee mount" > /dev/kmsg
cat /proc/mounts | grep "/dev/block/tee"
ret=$?
if [ $ret -ne 0 ]; then
	setprop vendor.sys.tee.need_remount 1
	echo "need format" > /dev/kmsg
fi

