SVENDOR=/mnt/vendora2
SSYSTEM=/mnt/systema2
PVENDOR=/mnt/vendorport
PSYSTEM=/mnt/systemport
CURRENTUSER=$1
SCRIPTDIR=$(readlink -f "$0")
CURRENTDIR=$(dirname "$SCRIPTDIR")
FILES=$CURRENTDIR/files
OUTP=$CURRENTDIR/out
TOOLS=$CURRENTDIR/tools
ROMVERSION=$(sudo grep ro.system.build.version.incremental= $PSYSTEM/system/build.prop | sed "s/ro.system.build.version.incremental=//g"; )
sed -i "s%DATE%$(date +%d/%m/%Y)%g
s/ROMVERSION/$ROMVERSION/g" $OUTP/zip/META-INF/com/google/android/updater-script
echo "Unmounting port system"
sudo umount $PSYSTEM
echo "Unmounting port vendor"
sudo umount $PVENDOR
echo "Unmounting source system"
sudo umount $SSYSTEM
echo "Unmounting source vendor"
sudo umount $SVENDOR
echo "Removing mount points"
sudo rmdir $PSYSTEM
sudo rmdir $PVENDOR
sudo rmdir $SSYSTEM
sudo rmdir $SVENDOR
e2fsck -y -f $OUTP/systemport.img
resize2fs $OUTP/systemport.img 786432
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
cp -af /home/sebastian1/MIUI-jasmeme-lavender/files/boot.img /home/sebastian1/MIUI-jasmeme-lavender/out/zip
cp -af /home/sebastian1/MIUI-jasmeme-lavender/files/splash.img /home/sebastian1/MIUI-jasmeme-lavender/out/zip
cd $OUTP/zip
echo "Zipping final ROM"
zip -ry $OUTP/10_MIUI_12_jasmine_sprout_$ROMVERSION.zip *
cd $CURRENTDIR
echo "Removing all unnecessary files"
rm -rf $OUTP/zip
chown -hR $CURRENTUSER:$CURRENTUSER $OUTP
