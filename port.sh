CURRENTUSER=$1
sudo apt -y install brotli simg2img git-core zip curl unzip img2simg figlet
cd tools
git clone https://github.com/xpirt/img2sdat img2sdat
git clone https://github.com/xpirt/sdat2img sdat2img
figlet MIUI-jasmeme
echo " "
echo "♦ Verifying assets"
if [[ $CURRENTUSER = root ]]
then
echo "Don't run as root!" && exit
fi
read -p "♦ Enter filename of ROM to be ported" PORTROM
echo "♦ Running unzip"
sudo su -c "unzip.sh $PORTROM $CURRENTUSER"
echo "♦ Running main"
sudo su -c "main.sh $CURRENTUSER"
echo "♦ Running zip"
sudo su -c "zip.sh $CURRENTUSER"
echo "♦ Finished porting!"