#!/vendor/bin/sh

CONF_INI=`idme print model_name`

PQ_COMPRESS_PATH=`grep PQINI_COMPRESS_PATH $CONF_INI|awk -F '=' '{print $2}'`

if [ -n "$PQ_COMPRESS_PATH" ] && [ -f $PQ_COMPRESS_PATH ]; then

	PQ_PATH=`grep PQINI_PATH $CONF_INI|awk -F '=' '{print $2}'`
	PQ_DIR=$(dirname $PQ_PATH)
	PQ_COMPRESS_NAME=$(basename $PQ_COMPRESS_PATH)

	DEST_PQ_COMPRESS_PATH=$PQ_DIR"/"$PQ_COMPRESS_NAME

        if [ ! -d $PQ_DIR ]; then
		mkdir $PQ_DIR
		chmod 771 $PQ_DIR
	fi

	if [ -f $DEST_PQ_COMPRESS_PATH ]; then
		DEST_COMPRESS_MD5=`md5sum $DEST_PQ_COMPRESS_PATH|awk -F ' ' '{print $1}'`
		SRC_COMPRESS_MD5=`md5sum $PQ_COMPRESS_PATH|awk -F ' ' '{print $1}'`
	fi

	if [ ! -f $PQ_DIR"/""pq_ready" ] || [ ! -f $PQ_PATH ] || [ ! -f $DEST_PQ_COMPRESS_PATH ] || [ "$SRC_COMPRESS_MD5" != "$DEST_COMPRESS_MD5" ]; then
		cp $PQ_COMPRESS_PATH $PQ_DIR
		gzip -dfk $PQ_DIR"/"$PQ_COMPRESS_NAME
		sync
		touch $PQ_DIR"/""pq_ready"
	fi
else
	echo "not define pq compress"
fi

/vendor/bin/setprop vendor.pq.db.ready 1
