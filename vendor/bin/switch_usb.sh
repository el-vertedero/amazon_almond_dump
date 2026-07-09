#!/vendor/bin/sh

# Read/Write idme dev_flags.
# if $1 is device, set usb device mode, otherwise set usb host mode

flags_file='/proc/idme/dev_flags'

###sys.usb.start be define in adb_usb.sh

usb_start_prop=$(getprop sys.usb.start)
if [[ $usb_start_prop != *y* ]]; then
    echo "Don't need to set idme!"
    exit 0
fi

if [ -f $flags_file ]; then
    dev_flags=`/vendor/bin/idme print dev_flags`

    #delete '0x' or '0X'
    dev_flags=${dev_flags#*x}
    dev_flags=${dev_flags#*X}

    if [ "$1" == "device" ]; then
        echo "set USB device mode"
        new_dev_flags=$(($((16#${dev_flags}))|0x1000))
    else
        echo "set USB host mode"
        new_dev_flags=$(($((16#${dev_flags}))& ~0x1000))
    fi
    new_dev_flags=`printf "%X" $new_dev_flags`

    ###Wirte dev_flags
    /vendor/bin/idme dev_flags $new_dev_flags
else
    echo "Can't get dev_flags from idme!"
fi
