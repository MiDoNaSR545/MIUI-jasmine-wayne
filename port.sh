CURRENTUSER=$1
echo "• Updating assets"
sudo apt -y install brotli simg2img git-core zip curl unzip img2simg figlet > /dev/null 2>&1
cd tools
git submodule sync > /dev/null 2>&1
git submodule update > /dev/null 2>&1
figlet MIUI-jasmeme
echo " "
echo "• Verifying assets"
if [[ $CURRENTUSER = root ]]
then
echo "Don't run as root!" && exit
fi
read -p "• Enter filename of ROM to be ported" PORTROM
echo "• Running unzip"
sudo ./unzip.sh $PORTROM
echo "• Running main"
sudo ./main.sh
echo "• Running zip"
./zip.sh
echo "• Finished porting!"
