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

echo "Removing $OUTP"

rm -rf $OUTP || true

mkdir $OUTP

chown $CURRENTUSER:$CURRENTUSER $OUTP

echo "Copying zip to $OUTP"

cp -Raf $CURRENTDIR/zip $OUTP/

echo "Unzipping $PORTZIP"

unzip -d $OUTP $PORTZIP system.transfer.list vendor.transfer.list system.new.dat.br vendor.new.dat.br

echo "Unzipping jasmine_global_images"

tar --wildcards -xf $STOCKTAR */images/vendor.img */images/system.img

echo "Moving system to $OUTP"

mv jasmine_global_images*/images/vendor.img $OUTP/vendor.img

echo "Moving vendor to $OUTP"

mv jasmine_global_images*/images/system.img $OUTP/system.img

 

echo "Converting sparse source system image to raw image"

simg2img $OUTP/system.img $OUTP/systema2.img

echo "Converting sparse source vendor image to raw image"

simg2img $OUTP/vendor.img $OUTP/vendora2.img

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

