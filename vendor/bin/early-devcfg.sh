#!/vendor/bin/sh

# set ro.product.region based on idme region
idme_region=`/vendor/bin/cat /proc/idme/region`
/vendor/bin/setprop ro.product.region "$idme_region"

# only do it once after full flash or factory reset
if [[ ! -f /data/vendor/storemode_flag ]]; then
	if [ "$idme_region" == "IN" ] ; then
		/vendor/bin/setprop odm.locale "en-IN"
	fi


	if [ "$idme_region" == "US" ] ; then

		/vendor/bin/setprop odm.locale "en-US"

	fi
fi

