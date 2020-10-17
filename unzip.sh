SVENDOR=/mnt/vendora2
SSYSTEM=/mnt/systema2
PVENDOR=/mnt/vendorport
PSYSTEM=/mnt/systemport
CURRENTUSER=$2
SCRIPTDIR=$(readlink -f "$0")
CURRENTDIR=$(dirname "$SCRIPTDIR")
FILES=$CURRENTDIR/files
PORTZIP=$1
OUTP=$CURRENTDIR/out
TOOLS=$CURRENTDIR/tools
echo "• Fail on all errors enabled"
set -e
echo "• Removing $OUTP"
sudo rm -rf $OUTP || true
mkdir $OUTP
sudo chown $CURRENTUSER:$CURRENTUSER $OUTP
echo "• Copying zip to $OUTP"
cp -Raf $CURRENTDIR/zip $OUTP/
cd $CURRENTDIR
read -p "• Do you want to unzip jasmine_global_images? Y/N" JANS 
if [[ $JANS == Y ]]
then
read -p "• Enter your jasmine_global_images filename: " STOCKTAR
echo "• Unzipping jasmine_global_images"
tar --wildcards -xf $STOCKTAR */images/vendor.img */images/system.img
mv jasmine_global_images*/images/vendor.img $OUTP/vendor.img
mv jasmine_global_images*/images/system.img $OUTP/system.img
rm -rf jasmine_global_images*
echo "• Converting system image to EXT4 image"
simg2img $OUTP/system.img $CURRENTDIR/systema2.img
echo "• Converting vendor image to EXT4 image"
simg2img $OUTP/vendor.img $CURRENTDIR/vendora2.img
fi
echo "• Unzipping $PORTZIP"
unzip -d $OUTP $PORTZIP system.transfer.list vendor.transfer.list system.new.dat.br vendor.new.dat.br > /dev/null 2>&1
echo "• Decompressing port system.new.dat.br"
brotli -j -v -d $OUTP/system.new.dat.br -o $OUTP/system.new.dat
echo "• Decompressing port vendor.new.dat.br"
brotli -j -v -d $OUTP/vendor.new.dat.br -o $OUTP/vendor.new.dat
echo "• Converting port systm.new.dat to disk image"
$TOOLS/sdat2img/sdat2img.py $OUTP/system.transfer.list $OUTP/system.new.dat $OUTP/systemport.img > /dev/null 2>&1
echo "• Converting port vendor.new.dat to disk image"
$TOOLS/sdat2img/sdat2img.py $OUTP/vendor.transfer.list $OUTP/vendor.new.dat $OUTP/vendorport.img > /dev/null 2>&1
echo "• Cleaning up unnecessary files from $OUTP"
rm -rf $OUTP/system.new.dat $OUTP/vendor.new.dat $OUTP/system.transfer.list $OUTP/vendor.transfer.list
echo "• Making directories"
sudo mkdir $PSYSTEM || true
sudo mkdir $PVENDOR || true
sudo mkdir $SVENDOR || true
sudo mkdir $SSYSTEM || true
echo "• Mounting port system to $PSYSTEM"
sudo mount -o rw,noatime $OUTP/systemport.img $PSYSTEM
echo "• Mounting port vendor to $PVENDOR"
sudo mount -o rw,noatime $OUTP/vendorport.img $PVENDOR
echo "• Mounting source system to $SSYSTEM"
sudo mount -o rw,noatime systema2.img $SSYSTEM
echo "•Mounting source vendor to $SVENDOR"
sudo mount -o rw,noatime vendora2.img $SVENDOR
