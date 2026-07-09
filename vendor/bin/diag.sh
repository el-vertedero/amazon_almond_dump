#!/system/bin/sh

dev_flags_path='/proc/idme/dev_flags'
DEV_FLAGS_ENABLE_FACTORY_TEST=0x800
DEV_FLAGS_ENABLE_FACTORY_FATP=0x200000
dev_flags=`/vendor/bin/cat $dev_flags_path`
dev_flags=0x$dev_flags
DIAG_INIT_SH="/data/data/com.amazon.servicemenu/files/scripts/common/diag_init.sh"
DIAG_READY="/data/data/com.amazon.servicemenu/files/DIAG_READY"
USB_PATH=`ls /dev/block/ | grep "sd[a-z][0-1]"`
DIR_PATH="/dev/block"
DIR_MOUNT="/mnt/udisk"
DIAG_PACKAGE_NAME="com.amazon.servicemenu.apk"
STARTAT_FILE="FAC_BOOT_SMART.cvt"
OOBE_TIMEOUT=200
DIAG_APK_TIMEOUT=600
DIAG_APK_PATH=""
BUSY_BOX=""
#=== FUNCTION ================================================================
# NAME: findfile
# DESCRIPTION: Find Diag Apk package or SMT Flag file in USB stick
# PARAMETER 1: USB device path 
#===============================================================================
function findfile()
{
	USB_DEV_PATH=${1}
	
	echo "[Diag]=============find usb-disk path=$USB_DEV_PATH" > /dev/kmsg
	
	
	if [[ $1/$STARTAT_FILE == `ls $1/$STARTAT_FILE` ]];then
		setprop diag.app.stage smt              

		echo "[Diag] SMT FILE FOUND" > /dev/kmsg
	fi

	if [[ $1/$DIAG_PACKAGE_NAME == `ls $1/$DIAG_PACKAGE_NAME` ]];then
		DIAG_APK_PATH=$1/$DIAG_PACKAGE_NAME
		echo "[Diag] DIAG APK FILE FOUND" > /dev/kmsg
	else
		echo "[Diag] Diag apk not found" > /dev/kmsg
	fi
	if [[ $1/busybox == `ls $1/busybox` ]];then
		BUSY_BOX=$1/busybox
		echo "[Diag] busybox  FOUND" > /dev/kmsg
	else
		echo "[Diag] busybox not found" > /dev/kmsg
	fi



}


prod=`getprop ro.boot.prod`
unlock=`getprop ro.boot.unlocked_kernel`
if [ $prod == "1" && $unlock == "false" ];then
	echo "[Diag] Do not run diag on locked device" > /dev/kmsg
	exit 0
fi

if [ $(($dev_flags & $DEV_FLAGS_ENABLE_FACTORY_TEST)) != "0" ] ; then

	#---------------------------------------------------------
	# "diag.app.stage" for Diag apk to distinguish build stage,
	# and load corresponding factory resources.
	#---------------------------------------------------------
	if [ $(($dev_flags & $DEV_FLAGS_ENABLE_FACTORY_FATP)) != "0" ] ; then
		setprop diag.app.stage fatp
	else
		setprop diag.app.stage smt
	fi
	#---------------------------------------------------------
	# findfile here to speed boot time,
	# since first time USB mount and ls takes long time
	#---------------------------------------------------------
	USB_PATH_REL=$USB_PATH
	echo "[Diag]=====================" > /dev/kmsg
	echo "[Diag]=====================" > /dev/kmsg
	echo "[Diag]=====================" > /dev/kmsg
	echo "[Diag]=====================" > /dev/kmsg
	echo "[Diag]=====================" > /dev/kmsg
	echo "[Diag]USB path $USB_PATH===" > /dev/kmsg
	echo "[Diag]=====================" > /dev/kmsg
	array=(${USB_PATH_REL//\n/ })
	usb_dev_Num=${#array[@]}
	echo "[Diag]====USB device Num: $usb_dev_Num" > /dev/kmsg
	if [[ $usb_dev_Num -gt 0 ]]; then
		echo "[Diag] ========== USB stick detected"> /dev/kmsg
		i=0
		timeout=$OOBE_TIMEOUT
		while [ $i -le $timeout ]
		do
			UUID=`mount | awk '{if($1~/media_rw/) print $1}'`
			if [ -z "$UUID" ];then
				sleep 1
			else
				findfile $UUID
				break
			fi
		done
	fi

	#-----------------------------------------------------------------
	# Wait for OOBE, then Package and activity service ready
	#-----------------------------------------------------------------
	i=0
	timeout=$OOBE_TIMEOUT
	while [ $i -le $timeout ]
	do
		let i++
		sleep 1
		focusWindow=`/system/bin/dumpsys window|grep mCurrentFocus`
		if [[ $focusWindow == *"com.amazon.tv.oobe"* || $focusWindow == *"com.amazon.tv.launcher"* ]]; then
			echo "[Diag]Target window ready: $focusWindow" > /dev/kmsg
		    	break
		fi
	done
	if [ $i -gt $timeout ]; then
		echo "[Diag]Service ready timeout \n" > /dev/kmsg
		exit -1
	fi


	#-----------------------------------------------------------------
	# Upgrade Diag apk if it presents in USB stick
	#-----------------------------------------------------------------
	if [[ -f $DIAG_APK_PATH ]];then
		echo "[Diag]Install Diag apk $DIAG_APK_PATH" > /dev/kmsg
		pm install -r -t -d $DIAG_APK_PATH
		pm clear com.amazon.servicemenu
	fi
	#-----------------------------------------------------------------
	# Start Diag application
	#-----------------------------------------------------------------
	rm -f $DIAG_READY
	echo "[Diag]Start Diag app..." > /dev/kmsg
	startResult=`/system/bin/sh /system/bin/am start -n com.amazon.servicemenu/.MainActivity`
	echo "[Diag] Start Diag app result $startResult" > /dev/kmsg
	#-----------------------------------------------------------------
	# Wait for Diag application Ready
	#-----------------------------------------------------------------
	i=0
	timeout=$DIAG_APK_TIMEOUT
	while [ $i -le $timeout ]
	do
		let i++
		sleep 1
		echo "[Diag]Wait for DIAG_READY $i\n" > /dev/kmsg
		if [ -f $DIAG_READY ]; then
			echo "[Diag]DIAG_READY..."  > /dev/kmsg
			break
		fi
	done

	if [ $i -gt $timeout ]; then
		echo "[Diag]Diag init timeout \n" > /dev/kmsg
		exit -1
	fi

	#-----------------------------------------------------------------
	# Go on diag init
	#-----------------------------------------------------------------
	$DIAG_INIT_SH &
fi

