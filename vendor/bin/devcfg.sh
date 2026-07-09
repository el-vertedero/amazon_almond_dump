#!/vendor/bin/sh

fos_flags_path='/proc/idme/fos_flags'
dev_flags_path='/proc/idme/dev_flags'
FOS_DEV_FLAGS_NO_STR=256
FOS_DEV_FLAGS_USB_MODE_PHERIPHERAL=0x1
FOS_FLAGS_ADB_ROOT=2
FOS_DEV_FLAGS_STR_LESS_DELAY=0x8

# populate ro.nrdp.oemmodel
idme_mfr_name=`/vendor/bin/cat /proc/idme/mfr_name`
idme_mfr_model=`/vendor/bin/cat /proc/idme/mfr_model`
idme_prod_model=`/vendor/bin/cat /proc/idme/product_model`
prop_ome_model=$idme_mfr_name"_"$idme_mfr_model
# for settings use
/vendor/bin/setprop ro.product.oemmodel $prop_ome_model
/vendor/bin/setprop ro.nrdp.oemmodel $prop_ome_model
# for netflix use
/vendor/bin/setprop ro.vendor.nrdp.oemmodel $prop_ome_model
# set product model
#/vendor/bin/setprop ro.vendor.product.model $idme_prod_model
#refer https://issues.labcollab.net/browse/PRIMROSE-677
/vendor/bin/setprop ro.vendor.product.model_trigger $idme_prod_model
#/vendor/bin/setprop ro.product.model $idme_prod_model

# set modelgroup
idme_conf_name=`/vendor/bin/cat /proc/idme/config_name`
hdr_flag=`/vendor/bin/sed -rn 's/tvin.enable.hdr[^=]*=[^=]//p' "/tvconfig/$idme_conf_name.ini"`
idme_model_name=`/vendor/bin/cat /proc/idme/model_name`
panel_ini_file=`/vendor/bin/sed -rn 's/PANELINI_PATH[^=]*=[^=]//p' $idme_model_name`
panel_width=`/vendor/bin/sed -rn 's/h_active[^=]*=[^0-9]*([0-9]+).*/\1/p' $panel_ini_file`
panel_height=`/vendor/bin/sed -rn 's/v_active[^=]*=[^0-9]*([0-9]+).*/\1/p' $panel_ini_file`
if (( $panel_width >= 1280 )) && (( $panel_width <= 1366 )) && \
   (( $panel_height >= 720 )) && (( $panel_height <= 768 )); then
    if (( $hdr_flag == 1 )); then
        /vendor/bin/setprop ro.vendor.nrdp.modelgroup FTVEAML950X4HDHDR2022
    else
        /vendor/bin/setprop ro.vendor.nrdp.modelgroup FTVEAML950X4HD2022
    fi
else
    if (( $hdr_flag == 1 )); then
        /vendor/bin/setprop ro.vendor.nrdp.modelgroup FTVEAML950X4FHDHDR2022
    else
        /vendor/bin/setprop ro.vendor.nrdp.modelgroup FTVEAML950X4FHD2022
    fi
fi
echo "devcfg-fs: devices HDR: $hdr_flag Resolution: $panel_width * $panel_height" > /dev/kmsg

#set ro.poweron.src and sys.poweron.src based on wakeup reason
power_on_reason=`/vendor/bin/cat /sys/devices/platform/aml_pm/suspend_reason`
case $power_on_reason in
    13)
        /vendor/bin/setprop ro.poweron.src "app_1"
        /vendor/bin/setprop sys.poweron.src "app_1"
        ;;
    14)
        /vendor/bin/setprop ro.poweron.src "app_2"
        /vendor/bin/setprop sys.poweron.src "app_2"
        ;;
    15)
        /vendor/bin/setprop ro.poweron.src "app_3"
        /vendor/bin/setprop sys.poweron.src "app_3"
        ;;
    9)
        /vendor/bin/setprop ro.poweron.src "app_4"
        /vendor/bin/setprop sys.poweron.src "app_4"
        ;;
    *)
        /vendor/bin/setprop ro.poweron.src "unknown"
        /vendor/bin/setprop sys.poweron.src "unknown"
esac

# set suspend blocker per FOS_DEV_FLAGS_NO_STR
dev_flags=`/vendor/bin/cat $dev_flags_path`
dev_flags=0x$dev_flags
if [ $(($dev_flags & $FOS_DEV_FLAGS_NO_STR)) != "0" ] ; then
    /vendor/bin/setprop odm.hold.wakelock.idme y
fi

if [ $(($dev_flags & $FOS_DEV_FLAGS_STR_LESS_DELAY)) != "0" ] ; then
    /vendor/bin/setprop sys.str.delay_before_str 10000
fi

# enable USB device mode if ADB is enabled
if [ $(($dev_flags & $FOS_DEV_FLAGS_USB_MODE_PHERIPHERAL)) != "0" ] ; then
    /vendor/bin/setprop vendor.usb.debugging.init y
else
    /vendor/bin/setprop vendor.usb.debugging.init n
fi

# disable rescue when adb root flage is set
fos_flags=`/vendor/bin/cat $fos_flags_path`
fos_flags=0x$fos_flags
if [ $(($fos_flags & $FOS_FLAGS_ADB_ROOT)) != "0" ] ; then
    /vendor/bin/setprop persist.odm.disable_rescue true
fi

