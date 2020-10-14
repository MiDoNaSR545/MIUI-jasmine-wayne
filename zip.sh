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
echo "♦ Unmounting port system"
sudo umount $PSYSTEM
echo "♦ Unmounting port vendor"
sudo umount $PVENDOR
echo "♦ Unmounting source system"
sudo umount $SSYSTEM
echo "♦ Unmounting source vendor"
sudo umount $SVENDOR
echo "♦ Removing mount points"
sudo rmdir $PSYSTEM
sudo rmdir $PVENDOR
sudo rmdir $SSYSTEM
sudo rmdir $SVENDOR
e2fsck -y -f $OUTP/systemport.img
resize2fs $OUTP/systemport.img 786432
echo "♦ Converting port system to sparse image"
img2simg $OUTP/systemport.img $OUTP/sparsesystem.img
rm $OUTP/systemport.img
echo "♦ Generating DAT files for system"
$TOOLS/img2sdat/img2sdat.py -v 4 -o $OUTP/zip -p system $OUTP/sparsesystem.img
rm $OUTP/sparsesystem.img
echo "♦ Converting port vendor to sparse image"
img2simg $OUTP/vendorport.img $OUTP/sparsevendor.img
rm $OUTP/vendorport.img
echo "♦ Generating DAT files for vendor"
$TOOLS/img2sdat/img2sdat.py -v 4 -o $OUTP/zip -p vendor $OUTP/sparsevendor.img
rm $OUTP/sparsevendor.img
echo "♦ Compressing system.new.dat"
brotli -j -v -q 6 $OUTP/zip/system.new.dat
echo "♦ Compressing vendor.new.dat"
brotli -j -v -q 6 $OUTP/zip/vendor.new.dat
cp -af $FILES/boot.img $OUTP/zip
cd $OUTP/zip

#SPLASH
echo "♦ Choose splash style (Designed by pavwel32)"
echo "1. Mi A2 Stock splash (light)"
echo "2. Mi A2 Stock splash (dark)"
echo "3. Mi 6X Stock splash (light)"
echo "4. Mi 6X Stock splash (dark)"
echo "5. Modded Mi A2 stock splash (light)"
echo "6. Modded Mi A2 stock splash (dark)"
echo "7. Mi orange AndroidOne splash (light)"
echo "8. Mi orange AndroidOne splash (dark)"
echo "9. Team Neon splash screen"
echo "10. Custom Mi A2 splash (light)"
echo "11. Custom Mi A2 splash (dark)"
echo "12. Custom Mi 6X splash (light)"
echo "13. Custom Mi 6X splash (dark)"
echo "14. None / I dont want a custom splash"
read -p "Enter your chosen style" SSTYLE
if [[ $SSTYLE == 1 ]]
then
wget -q https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_A2_Stock_Splash_Screen.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 2 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_A2_Stock_Splash_Screen_Dark.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 3 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_6X_Stcok_Splash_Screen_Light.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 4 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_6X_Stock_Splash_Screen.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 5 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_A2_Stock_Splash_Screen_Modified.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 6 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_A2_Stock_Splash_Screen_Dark_Modified.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 7 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_Android_One_Orange_Splash_Screen_Light.img/download
sudo mv -f download splash.img 
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 8 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Mi_Android_One_Orange_Splash_Screen_Dark.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 9 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Team_Neon_Splash_Screen.img/download
sudo mv -f download splash.img 
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 10 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Custom_Xiaomi_Mi_A2_Android_One_Splash_Screen_Light.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 11 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Custom_Xiaomi_Mi_A2_Android_One_Splash_Screen_Dark.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 12 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Custom_Xiaomi_Mi_6X_Splash_Screen_Light.img/download
sudo mv -f download splash.img 
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 13 ]]
then
wget https://sourceforge.net/projects/teamneon-ports/files/Splash-Screens/IMG/Custom_Xiaomi_Mi_6X_Splash_Screen_Dark.img/download
sudo mv -f download splash.img
sed -i "27i package_extract_file(\"splash.img\", \"/dev/block/bootdevice/by-name/splash\");" META-INF/com/google/android/updater-script
elif [[ $SSTYLE == 14 ]]
then 
echo "♦ Okay!"
fi

#ZIP
echo "♦ Zipping final ROM"
zip -ry $OUTP/10_MIUI_12_jasmine_sprout_$ROMVERSION.zip *
cd $CURRENTDIR
echo "♦ Removing all unnecessary files"
rm -rf $OUTP/zip
chown -hR $CURRENTUSER:$CURRENTUSER $OUTP
