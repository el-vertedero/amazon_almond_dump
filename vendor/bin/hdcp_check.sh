#!/vendor/bin/sh

echo "check hdcp status" > /dev/kmsg
result1=$(cat /sys/class/hdmirx/hdmirx0/hdcp14_onoff )
if [ $result1 -ne 0 ]; then
	setprop ro.product.drm.hdcp14.rx  1
fi

