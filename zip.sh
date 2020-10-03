
SVENDOR=/mnt/vendora2
SSYSTEM=/mnt/systema2
PVENDOR=/mnt/vendorport
PSYSTEM=/mnt/systemport
CURRENTUSER=$3
SCRIPTDIR=$(readlink -f "$0")
CURRENTDIR=$(dirname "$SCRIPTDIR")
FILES=$CURRENTDIR/files
PORTZIP=$1
STOCKTAR=$2
OUTP=$CURRENTDIR/out
TOOLS=$CURRENTDIR/tools

echo "Fail on all errors enabled"
set -e
echo "Unmounting port system"
umount $PSYSTEM
echo "Unmounting port vendor"
umount $PVENDOR
echo "Unmounting source system"
umount $SSYSTEM
echo "Unmounting source vendor"
umount $SVENDOR
echo "Removing mount points"
rmdir $PSYSTEM
rmdir $PVENDOR
rmdir $SSYSTEM
rmdir $SVENDOR

echo "Converting port system to sparse image"
img2simg $OUTP/systemport.img $OUTP/sparsesystem.img
rm $OUTP/systemport.img
echo "Generating DAT files for system"
$TOOLS/img2sdat/img2sdat.py -v 4 -o $OUTP/zip -p system $OUTP/sparsesystem.img
rm $OUTP/sparsesystem.img
echo "Converting port vendor to sparse image"
img2simg $OUTP/vendorport.img $OUTP/sparsevendor.img
rm $OUTP/vendorport.img
echo "Generating DAT files for vendor"
$TOOLS/img2sdat/img2sdat.py -v 4 -o $OUTP/zip -p vendor $OUTP/sparsevendor.img
rm $OUTP/sparsevendor.img
echo "Compressing system.new.dat"
brotli -j -v -q 6 $OUTP/zip/system.new.dat
echo "Compressing vendor.new.dat"
brotli -j -v -q 6 $OUTP/zip/vendor.new.dat

cd $OUTP/zip
echo "Zipping final ROM"
zip -ry $OUTP/10_MIUI_12_jasmine_sprout_$ROMVERSION.zip *
cd $CURRENTDIR
echo "Removing all unnecessary files"
rm -rf $OUTP/zip
chown -hR $CURRENTUSER:$CURRENTUSER $OUTP
