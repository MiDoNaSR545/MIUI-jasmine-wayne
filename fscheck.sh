
echo "Scanning system for errors"
e2fsck -y -f $OUTP/systemport.img
echo "Resizing system"
resize2fs $OUTP/systemport.img 786432
