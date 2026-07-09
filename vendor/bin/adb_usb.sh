#!/vendor/bin/sh
PATH=/sbin:/vendor/bin

FOS_FLAGS_ADB_ON=0x1
FILE2CHECK="/data/hwval/adb_check.bin"
MD5CHECK="27ec1016c3db85fa8bb547ada6d3321e"

# General FOS flags, shared across devices
fosflagsfile="/proc/idme/fos_flags"

# General bootcount, to check first boot up
bootcountfile="/proc/idme/bootcount"

# factory reset record.
FACTORY_RESET="/data/hwval/factory_reset"
echo "************************************"
echo "***ADB USB BEGIN****"
echo "************************************"
# dev flags, don't use DEV_FLAGS_USB_MODE_PERIPHERAL bit
devflagsfile="/proc/idme/dev_flags"
DEV_FLAGS_ADB_USB_ON=0x1000

setprop sys.usb.start n

# "persist.sys.usb.debugging" is used for ADB-over-USB debugging.
# "persist.sys.usb.debugging" is enabled by default on userdebug and eng build.
# On user build, "persist.sys.usb.debugging" depends on ADB_ON bit of fos_flags.
#
# "persist.sys.usb.debug_visible" is for visibility of "USB debugging" menu on user build.
# "USB debugging" menu in Setting is always visible on userdebug and eng build.
# On user build, "persist.sys.usb.debug_visible" also depends on fos_flags.
# That is, if "USB debugging" menu is visible, internal user can switch it in Setting.
#
# So if "ADB_ON" bit of fosflags is 1,
# then for internal developer&QA, "USB Debugging" menu is visible on any types of builds.
# For MP, after "ADB_ON" bit of fosflags is cleared,
# on user build, USB is always HOST, and "USB Debugging" is always NOT visible.
#
# For external developers, only ADB-over-TCPIP can be used for debugging.
#
# When "USB Debugging" menu is NOT visible,
# all users can use USB-HOST function directly, and only ADB-over-TCPIP is availabe for debugging.
# When "USB Debugging" is visible,
# internal developer&QA can set it "ON" for ADB-over-USB debugging, and set it "OFF" for USB-HOST.
# When internal developer&QA switch "USB Debugging" from "ON" to "OFF",
# we should reboot TV manually to use USB-HOST function.
# When switch "USB Debugging" from "OFF" to "ON", ADB-over-USB can work right now.
#
# In conclusion, this design is for convenience for both internal developers and QA,
# and can avoid to disable USB-HOST wrongly by external users.

##if [ -e ${FILE2CHECK} ]; then
##    CHECKSUM=$(md5sum ${FILE2CHECK})
##    CHECKSUM=${CHECKSUM%% *}

    CHECKSUM="27ec1016c3db85fa8bb547ada6d3321e"
if [ "$bootcountfile" == 0]; then
    if [ "${CHECKSUM}" == "${MD5CHECK}" ]; then
        if [ -f $fosflagsfile ]; then
            FOSFLAGS=`cat $fosflagsfile`

            #delete '0x' or '0X'
            FOSFLAGS=${FOSFLAGS#*x}
            FOSFLAGS=${FOSFLAGS#*X}

            if [ $(( $FOS_FLAGS_ADB_ON & 0x$FOSFLAGS )) != 0 ]; then
                echo "Enabling adb and usb debugging for first boot" > /dev/kmsg
                usb_prop=$(getprop persist.sys.usb.debugging)
                if [[ $usb_prop != *y* ]]; then
                    echo "Force device to be adb-usb enabled" > /dev/kmsg
                    setprop sys.usb.debugging y
                    setprop sys.usb.debug_visible y
                fi
            fi
        fi
    fi
    rm -rf ${FILE2CHECK}
##fi
fi


#####################################
#	Factory reset don't run on fireos.
#####################################

# Restore adb-over-adb after factory reset
if [ -e ${FACTORY_RESET} ]; then
    if [ -f $fosflagsfile ]; then
        FOSFLAGS=`cat $fosflagsfile`
        if [ $(( $FOS_FLAGS_ADB_ON & 0x$FOSFLAGS )) != 0 ]; then
            usb_prop=$(getprop persist.sys.usb.debugging)
            if [[ $usb_prop != *y* ]]; then
                echo "After factory reset, still force to adb-usb enabled" > /dev/kmsg
                setprop sys.usb.debugging y
                setprop sys.usb.debug_visible y
            fi
        fi
    fi
    rm -rf ${FACTORY_RESET}
fi

# If ADB-over-USB should be disabled in user build.
# If "ADB_ON" bit of fos_flags is 0,
# then set "USB Debugging" menu to be invisible,
# because device's first-bootup is in factory, and "ADB_ON" is 1 at that time.
if [ -f $fosflagsfile ]; then
    FOSFLAGS=`cat $fosflagsfile`
    #delete '0x' or '0X'
    FOSFLAGS=${FOSFLAGS#*x}
    FOSFLAGS=${FOSFLAGS#*X}

    if [ $(( $FOS_FLAGS_ADB_ON & 0x$FOSFLAGS )) == 0 ]; then
        echo "Set invisibility of USB Debugging" > /dev/kmsg
        setprop sys.usb.debugging n
        setprop sys.usb.debug_visible n
    fi
fi

# If we unlock device with user build,
# then we want adb-over-usb to be also enabled,
# But "ADB_ON" bit of fos_flags can only work well in the first bootup because of BLANCHE-2444,
# So we need another flag bit to forcefully enable adb-over-usb on Rosalita platform.
# this flag bit in dev_flags should only be set when unlocked, and should be cleared when relock.
# "ADB_ON" bit of fos_flags will also be cleared when relock,
# so adb-over-usb will be disabled by code written above.
if [ -f $devflagsfile ]; then
    DEVFLAGS=`cat $devflagsfile`

    #delete '0x' or '0X'
    DEVFLAGS=${DEVFLAGS#*x}
    DEVFLAGS=${DEVFLAGS#*X}

    if [ $(( $DEV_FLAGS_ADB_USB_ON & 0x$DEVFLAGS )) != 0 ]; then
        echo "Enable ADB-over-USB Debugging" > /dev/kmsg
        setprop sys.usb.debugging y
        setprop sys.usb.debug_visible y
    fi
fi


setprop sys.usb.start y

echo "************************************"
echo "***ADB USB END****"
echo "************************************"

