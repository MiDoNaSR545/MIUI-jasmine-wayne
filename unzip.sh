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
cd ~
#sudo pacman --noconfirm --noedit -Syu trizen cpio brotli abootimg
#trizen --noconfirm --noedit -Syu simg-tools aosp-devel
sudo apt -y install cpio brotli simg2img abootimg git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev libxml2-utils xsltproc unzip zip screen attr ccache libssl-dev imagemagick schedtool
echo "Fail on all errors enabled"
set -e
echo "Removing $OUTP"
rm -rf $OUTP || true
mkdir $OUTP
chown $CURRENTUSER:$CURRENTUSER $OUTP
echo "Copying zip to $OUTP"
cp -Raf $CURRENTDIR/zip $OUTP/
echo "Unzipping $PORTZIP"
unzip -d $OUTP $PORTZIP system.transfer.list vendor.transfer.list system.new.dat.br vendor.new.dat.br
echo "Decompressing port system.new.dat.br"
brotli -j -v -d $OUTP/system.new.dat.br -o $OUTP/system.new.dat
echo "Decompressing port vendor.new.dat.br"
brotli -j -v -d $OUTP/vendor.new.dat.br -o $OUTP/vendor.new.dat
echo "Converting port systm.new.dat to disk image"
$TOOLS/sdat2img/sdat2img.py $OUTP/system.transfer.list $OUTP/system.new.dat $OUTP/systemport.img
echo "Converting port vendor.new.dat to disk image"
$TOOLS/sdat2img/sdat2img.py $OUTP/vendor.transfer.list $OUTP/vendor.new.dat $OUTP/vendorport.img
echo "Cleaning up unnecessary files from $OUTP"
rm $OUTP/vendor.img $OUTP/system.img $OUTP/system.new.dat $OUTP/vendor.new.dat $OUTP/system.transfer.list $OUTP/vendor.transfer.list
echo "Making directories"
mkdir $PSYSTEM || true
mkdir $PVENDOR || true
mkdir $SVENDOR || true
mkdir $SSYSTEM || true
echo "Mounting port system to $PSYSTEM"
sudo mount -o rw,noatime $OUTP/systemport.img $PSYSTEM
echo "Mounting port vendor to $PVENDOR"
sudo mount -o rw,noatime $OUTP/vendorport.img $PVENDOR
echo "Mounting source system to $SSYSTEM"
sudo mount -o rw,noatime /home/sebastian1/systema2.img $SSYSTEM
echo "Mounting source vendor to $SVENDOR"
sudo mount -o rw,noatime /home/sebastian1/vendora2.img $SVENDOR
