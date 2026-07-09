#!/vendor/bin/sh

echo "init libdolbyms12.so" > /dev/kmsg
result1=$(/vendor/bin/dolby_fw_dolbyms12 /product/lib/libdolbyms12.so /vendor/lib/ms12/libdolbyms12.so)
if [ $? -eq 0 ]; then
	setprop ro.vendor.lib.libdolbyms12 1
fi
