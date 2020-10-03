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
echo "Verifying"
if [[ -z $PORTZIP ]] || [[ $CURRENTUSER = root ]]
then
echo "Do not run as root. Usage:
./port.sh lavender-miui.zip" && exit
fi 
sudo su -c "$CURRENTDIR/unzip.sh $PORTZIP $CURRENTUSER" 
sudo su -c "$CURRENTDIR/main.sh $CURRENTUSER"
sudo su -v "$CURRENTDIR/fscheck.sh $CURRENTUSER"
sudo su -c "$CURRENTDIR/zip.sh $CURRENTUSER"

