SVENDOR=/mnt/vendora2
SSYSTEM=/mnt/systema2
PVENDOR=/mnt/vendorport
PSYSTEM=/mnt/systemport
CURRENTUSER=$2
SCRIPTDIR=$(readlink -f "$0")
CURRENTDIR=$(dirname "$SCRIPTDIR")
FILES=$CURRENTDIR/files
OUTP=$CURRENTDIR/out
TOOLS=$CURRENTDIR/tools
PORTZIP=$1
ANALYTICS=$CURRENTDIR/analytics

# Prepare modules / files / directories
mkdir $ANALYTICS
sudo apt -y install figlet > /dev/null 2>&1
figlet MIUI-jasmeme
echo " "
echo "• Updating submodules"
sudo apt -y update > $ANALYTICS/MIUI-jasmeme.log 2>&1
sudo apt -y upgrade > $ANALYTICS/MIUI-jasmeme.log 2>&1
sudo apt -y install cpio brotli simg2img img2simg abootimg git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev libxml2-utils xsltproc unzip zip screen attr ccache libssl-dev schedtool > $ANALYTICS/MIUI-jasmeme.log 2>&1
git clone https://github.com/xpirt/img2sdat $TOOLS/img2sdat > $ANALYTICS/MIUI-jasmeme.log 2>&1
git clone https://github.com/xpirt/sdat2img $TOOLS/sdat2img > $ANALYTICS/MIUI-jasmeme.log 2>&1
echo "• Beginning port sequence"

# Unzip stock ROM if needed
# Users can place systema2.img and vendora2.img in $CURRENTDIR after running this once, and they can be used unlimited times
# Only select yes if it's your first time using
read -p "• Unzip jasmine_global_images? [Y/N]" JSAM
if [[ "$JSAM" = "Y" ]]; then
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

# Unzip lavender ROM and convert to disk image
echo "• Unzipping $PORTZIP"
unzip -d $OUTP $PORTZIP system.transfer.list vendor.transfer.list system.new.dat.br vendor.new.dat.br > $ANALYTICS/MIUI-jasmeme.log 2>&1
echo "• Decompressing port system.new.dat.br"
brotli -j -v -d $OUTP/system.new.dat.br -o $OUTP/system.new.dat
echo "• Decompressing port vendor.new.dat.br"
brotli -j -v -d $OUTP/vendor.new.dat.br -o $OUTP/vendor.new.dat
echo "• Converting port systm.new.dat to disk image"
$TOOLS/sdat2img/sdat2img.py $OUTP/system.transfer.list $OUTP/system.new.dat $OUTP/systemport.img > $ANALYTICS/MIUI-jasmeme.log 2>&1
echo "• Converting port vendor.new.dat to disk image"
$TOOLS/sdat2img/sdat2img.py $OUTP/vendor.transfer.list $OUTP/vendor.new.dat $OUTP/vendorport.img > $ANALYTICS/MIUI-jasmeme.log 2>&1
echo "• Cleaning up unnecessary files from $OUTP"
rm -rf $OUTP/system.new.dat $OUTP/vendor.new.dat $OUTP/system.transfer.list $OUTP/vendor.transfer.list

# Mount / Unpack the system and vendor files
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

# Patch cache and create Magisk / Boot control files
echo "• Patching cache"
rm -rf $PSYSTEM/cache
cp -af $SSYSTEM/cache $PSYSTEM/
echo "• Creating addon"
mkdir $PSYSTEM/system/addon.d
setfattr -h -n security.selinux -v u:object_r:system_file:s0 $PSYSTEM/system/addon.d
chmod 755 $PSYSTEM/system/addon.d
echo "• Fixing bootctl"
cp -f $FILES/bootctl $PSYSTEM/system/bin/
chmod 755 $PSYSTEM/system/bin/bootctl
setfattr -h -n security.selinux -v u:object_r:system_file:s0 $PSYSTEM/system/bin/bootctl

#Debloat MIUI and Google Trash @clarencejasmeme
echo "• Debloating unnecessary apps"
rm -rf $PSYSTEM/system/priv-app/Updater
rm -rf $PSYSTEM/system/priv-app/WfdService
rm -rf $PSYSTEM/system/priv-app/MiRecycle
rm -rf $PSYSTEM/system/priv-app/MiService
rm -rf $PSYSTEM/system/app/AutoTest
rm -rf $PSYSTEM/system/app/MiuiBugReport
rm -rf $PSYSTEM/system/app/wps_lite
rm -rf $PSYSTEM/system/app/Joyose
rm -rf $PSYSTEM/system/app/Health
rm -rf $PSYSTEM/system/app/Qmmi

# Add libs and watermarks
echo "• Patching libs"
cp -af $SSYSTEM/system/lib/vndk-29/android.hardware.boot@1.0.so $PSYSTEM/system/lib/vndk-29/android.hardware.boot@1.0.so
cp -af $SSYSTEM/system/lib64/vndk-29/android.hardware.boot@1.0.so $PSYSTEM/system/lib64/vndk-29/android.hardware.boot@1.0.so
cp -af $SSYSTEM/system/lib64/android.hardware.boot@1.0.so $PSYSTEM/system/lib64/android.hardware.boot@1.0.so
echo "• Adding watermark"
cp -af $SVENDOR/etc/MIUI_DualCamera_watermark.png $PVENDOR/etc/MIUI_DualCamera_watermark.png

# Patch build prop and device_features 
echo "• Renaming device features xmls"
mv $PSYSTEM/system/etc/device_features/lavender.xml $PSYSTEM/system/etc/device_features/jasmine_sprout.xml
mv $PVENDOR/etc/device_features/lavender.xml $PVENDOR/etc/device_features/jasmine_sprout.xml
echo "• Editing build prop"
sed -i "/persist.camera.HAL3.enabled=/c\persist.camera.HAL3.enabled=1
/persist.vendor.camera.HAL3.enabled=/c\persist.vendor.camera.HAL3.enabled=1
/ro.product.model=/c\ro.product.model=Mi A2
/ro.build.id=/c\ro.build.id=MIUI 12
/persist.vendor.camera.exif.model=/c\persist.vendor.camera.exif.model=Mi A2
/ro.product.name=/c\ro.product.name=jasmine_sprout
/ro.product.device=/c\ro.product.device=jasmine_sprout
/ro.build.product=/c\ro.build.product=jasmine_sprout
/ro.product.system.device=/c\ro.product.system.device=jasmine_sprout
/ro.product.system.model=/c\ro.product.system.model=Mi A2
/ro.product.system.name=/c\ro.product.system.name=jasmine_sprout
/ro.miui.notch=/c\ro.miui.notch=0
/sys.paper_mode_max_level=/c\sys.paper_mode_max_level=32
\$ i sys.tianma_nt36672_offset=12
\$ i sys.tianma_nt36672_length=46
\$ i sys.jdi_nt36672_offset=9
\$ i sys.jdi_nt36672_length=45
/persist.vendor.camera.model=/c\persist.vendor.camera.model=Mi A2" $PSYSTEM/system/build.prop
sed -i "/ro.build.characteristics=/c\ro.build.characteristics=nosdcard" $PSYSTEM/system/product/build.prop
sed -i "/ro.miui.has_cust_partition=/c\ro.miui.has_cust_partition=false" $PSYSTEM/system/etc/prop.default
sed -i "/ro.product.vendor.model=/c\ro.product.vendor.model=Mi A2
/ro.product.vendor.name=/c\ro.product.vendor.name=jasmine_sprout
/ro.product.vendor.device=/c\ro.product.vendor.device=jasmine_sprout" $PVENDOR/build.prop
sed -i "/ro.product.odm.device=/c\ro.product.odm.device=jasmine_sprout
/ro.product.odm.model=/c\ro.product.odm.model=Mi A2
/ro.product.odm.device=/c\ro.product.odm.device=jasmine_sprout
/ro.product.odm.name=/c\ro.product.odm.name=jasmine_sprout" $PVENDOR/odm/etc/build.prop

# Add vendor firmware and FSTAB
echo "• Patching firmware"
rm -rf $PVENDOR/firmware
cp -Raf $SVENDOR/firmware $PVENDOR/firmware > $ANALYTICS/MIUI-jasmeme.log 2>&1
echo "• Fixing fstab"
cp -f $FILES/fstab.qcom $PVENDOR/etc/
chmod 644 $PVENDOR/etc/fstab.qcom
setfattr -h -n security.selinux -v u:object_r:vendor_configs_file:s0 $PVENDOR/etc/fstab.qcom
chown -hR root:root $PVENDOR/etc/fstab.qcom

# Patch hardware boot and boot control
echo "• Patching hardware boot"
cp -af $SVENDOR/bin/hw/android.hardware.boot@1.0-service $PVENDOR/bin/hw/android.hardware.boot@1.0-service
cp -af $SVENDOR/etc/init/android.hardware.boot@1.0-service.rc $PVENDOR/etc/init/android.hardware.boot@1.0-service.rc
cp -af $SVENDOR/lib/hw/bootctrl.sdm660.so $PVENDOR/lib/hw/bootctrl.sdm660.so
cp -af $SVENDOR/lib/hw/android.hardware.boot@1.0-impl.so $PVENDOR/lib/hw/android.hardware.boot@1.0-impl.so
cp -af $SVENDOR/lib64/hw/bootctrl.sdm660.so $PVENDOR/lib64/hw/bootctrl.sdm660.so
cp -af $SVENDOR/lib64/hw/android.hardware.boot@1.0-impl.so $PVENDOR/lib64/hw/android.hardware.boot@1.0-impl.so
echo "• Editing HAL formatting"
sed -i "58 i \    <hal format=\"hidl\">
58 i \        <name>android.hardware.boot</name>
58 i \        <transport>hwbinder</transport>
58 i \        <version>1.0</version>
58 i \        <interface>
58 i \            <name>IBootControl</name>
58 i \            <instance>default</instance>
58 i \        </interface>
58 i \        <fqname>@1.0::IBootControl/default</fqname>
58 i \    </hal>" $PVENDOR/etc/vintf/manifest.xml

# Fix and patch sensors in vendor 
echo "• Keymaster"
rm -f $PVENDOR/etc/init/android.hardware.keymaster@4.0-service-qti.rc
cp -af $SVENDOR/etc/init/android.hardware.keymaster@3.0-service-qti.rc $PVENDOR/etc/init/android.hardware.keymaster@3.0-service-qti.rc
sed -i "181 s/        <version>4.0<\/version>/        <version>3.0<\/version>/g
s/4.0::IKeymasterDevice/3.0::IKeymasterDevice/g" $PVENDOR/etc/vintf/manifest.xml
echo "• Adding sensors"
rm -rf $PVENDOR/etc/sensors
cp -Raf $SVENDOR/etc/sensors $PVENDOR/etc/sensors
cp -af $SVENDOR/etc/camera/camera_config.xml $PVENDOR/etc/camera/camera_config.xml
cp -af $SVENDOR/etc/camera/csidtg_camera.xml $PVENDOR/etc/camera/csidtg_camera.xml
cp -af $SVENDOR/etc/camera/csidtg_chromatix.xml $PVENDOR/etc/camera/camera_chromatix.xml

# Add watermarks to vendor
echo "• Patching watermark from vendor"
cp -af $SVENDOR/lib/libMiWatermark.so $PVENDOR/lib/libMiWatermark.so
cp -af $SVENDOR/lib/libdng_sdk.so $PVENDOR/lib/libdng_sdk.so
cp -af $SVENDOR/lib/libvidhance_gyro.so $PVENDOR/lib/libvidhance_gyro.so
cp -af $SVENDOR/lib/libvidhance.so $PVENDOR/lib/
cp -af $SVENDOR/lib/libmmcamera* $PVENDOR/lib/
cp -af $SVENDOR/lib64/libmmcamera* $PVENDOR/lib64/
cp -f $SVENDOR/lib/hw/camera.sdm660.so $PVENDOR/lib/hw/
echo "• Skipping bootanimation removal"

# Patch the vendor fingerprint
echo "• Parsing device fingerprint"
cp -af $FILES/fingerprint/app/FingerprintExtensionService/FingerprintExtensionService.apk $PVENDOR/app/FingerprintExtensionService/FingerprintExtensionService.apk
setfattr -h -n security.selinux -v u:object_r:vendor_app_file:s0 $PVENDOR/app/FingerprintExtensionService/FingerprintExtensionService.apk
chmod 644 $PVENDOR/app/FingerprintExtensionService/FingerprintExtensionService.apk
chown -hR root:root $PVENDOR/app/FingerprintExtensionService/FingerprintExtensionService.apk
cp -af $FILES/fingerprint/framework/com.fingerprints.extension.jar $PVENDOR/framework/com.fingerprints.extension.jar
setfattr -h -n security.selinux -v u:object_r:vendor_framework_file:s0 $PVENDOR/framework/com.fingerprints.extension.jar
chmod 644 $PVENDOR/framework/com.fingerprints.extension.jar
chown -hR root:root $PVENDOR/framework/com.fingerprints.extension.jar
cp -af $FILES/fingerprint/lib64/hw/fingerprint.fpc.default.so $PVENDOR/lib64/hw/fingerprint.fpc.default.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/hw/fingerprint.fpc.default.so
chmod 644 $PVENDOR/lib64/hw/fingerprint.fpc.default.so
chown -hR root:root $PVENDOR/lib64/hw/fingerprint.fpc.default.so
cp -af $FILES/fingerprint/lib64/hw/fingerprint.goodix.default.so $PVENDOR/lib64/hw/fingerprint.goodix.default.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/hw/fingerprint.goodix.default.so
chmod 644 $PVENDOR/lib64/hw/fingerprint.goodix.default.so
chown -hR root:root $PVENDOR/lib64/hw/fingerprint.goodix.default.so
cp -af $FILES/fingerprint/lib64/vendor.qti.hardware.fingerprint@1.0.so $PVENDOR/lib64/vendor.qti.hardware.fingerprint@1.0.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/vendor.qti.hardware.fingerprint@1.0.so
chmod 644 $PVENDOR/lib64/vendor.qti.hardware.fingerprint@1.0.so
chown -hR root:root $PVENDOR/lib64/vendor.qti.hardware.fingerprint@1.0.so
cp -af $FILES/fingerprint/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so
chmod 644 $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so
chown -hR root:root $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0-service.so
cp -af $FILES/fingerprint/lib64/libvendor.goodix.hardware.fingerprint@1.0.so $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0.so
chmod 644 $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0.so
chown -hR root:root $PVENDOR/lib64/libvendor.goodix.hardware.fingerprint@1.0.so
cp -af $FILES/fingerprint/lib64/com.fingerprints.extension@1.0.so $PVENDOR/lib64/com.fingerprints.extension@1.0.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/com.fingerprints.extension@1.0.so
chmod 644 $PVENDOR/lib64/com.fingerprints.extension@1.0.so
chown -hR root:root $PVENDOR/lib64/com.fingerprints.extension@1.0.so
cp -af $FILES/fingerprint/lib64/libgf_ca.so $PVENDOR/lib64/libgf_ca.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/libgf_ca.so
chmod 644 $PVENDOR/lib64/libgf_ca.so
chown -hR root:root $PVENDOR/lib64/libgf_ca.so
cp -af $FILES/fingerprint/lib64/libgf_hal.so $PVENDOR/lib64/libgf_hal.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/libgf_hal.so
chmod 644 $PVENDOR/lib64/libgf_hal.so
chown -hR root:root $PVENDOR/lib64/libgf_hal.so
cp -af $SSYSTEM/system/usr/keylayout/uinput-fpc.kl $PSYSTEM/system/usr/keylayout/uinput-fpc.kl
cp -af $SSYSTEM/system/usr/idc/uinput-fpc.idc $PSYSTEM/system/usr/idc/uinput-fpc.idc
cp -af $SSYSTEM/system/usr/keylayout/uinput-fpc.kl $PSYSTEM/system/usr/keylayout/uinput-fpc.kl
cp -af $SSYSTEM/system/usr/idc/uinput-fpc.idc $PSYSTEM/system/usr/idc/uinput-fpc.idc

# Patch biometrics and firmware in system
echo "• Recognizing goodixbiometrics"
sed -i "477 c\        <name>vendor.goodix.hardware.fingerprint</name>" $PVENDOR/etc/vintf/manifest.xml
sed -i "479 c\        <version>1.0</version>
481 c\            <name>IGoodixBiometricsFingerprint</name>
484 c\        <fqname>@1.0::IGoodixBiometricsFingerprint/default</fqname>
485d
486d
487d
488d
489d" $PVENDOR/etc/vintf/manifest.xml
echo "• Adding firmware"
rm -rf $PSYSTEM/system/etc/firmware || true

# Add wifi libs
echo "• Adding libwifi [hal64]"
cp -f $FILES/libwifi-hal64.so $PVENDOR/lib64/libwifi-hal.so
chmod 644 $PVENDOR/lib64/libwifi-hal.so
chown -hR root:root $PVENDOR/lib64/libwifi-hal.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/libwifi-hal.so
echo "• Adding ibwifi [hal32]"
cp -f $FILES/libwifi-hal32.so $PVENDOR/lib/libwifi-hal.so
chmod 644 $PVENDOR/lib/libwifi-hal.so
chown -hR root:root $PVENDOR/lib/libwifi-hal.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib/libwifi-hal.so

# Edit device_features XMLs
echo "• Patching system device features"
sed -i "/support_dual_sd_card/c\    <bool name=\"support_dual_sd_card\">true<\/bool>
/battery_capacity_typ/c\    <string name=\"battery_capacity_typ\">3010<\/string>
/support_camera_4k_quality/c\    <bool name=\"support_camera_4k_quality\">true<\/bool>
/bool name=\"is_xiaomi\">/c\    <bool name=\"is_xiaomi\">true<\/bool>
/is_hongmi/c\    <bool name=\"is_hongmi\">false<\/bool>
/is_redmi/c\    <bool name=\"is_redmi\">false<\/bool>
/paper_mode_max_level/c\    <float name=\"paper_mode_max_level\">32.0<\/float>
/paper_mode_min_level/c\    <float name=\"paper_mode_min_level\">0.0<\/float>
/is_18x9_ratio_screen/c\    <bool name=\"is_18x9_ratio_screen\">true<\/bool>" $PSYSTEM/system/etc/device_features/jasmine_sprout.xml
echo "• Patching vendor device features"
sed -i "/support_dual_sd_card/c\    <bool name=\"support_dual_sd_card\">true<\/bool>
/battery_capacity_typ/c\    <string name=\"battery_capacity_typ\">3010<\/string>
/support_camera_4k_quality/c\    <bool name=\"support_camera_4k_quality\">true<\/bool>
/bool name=\"is_xiaomi\">/c\    <bool name=\"is_xiaomi\">true<\/bool>
/is_hongmi/c\    <bool name=\"is_hongmi\">false<\/bool>
/is_redmi/c\    <bool name=\"is_redmi\">false<\/bool>
/paper_mode_max_level/c\    <float name=\"paper_mode_max_level\">32.0<\/float>
/paper_mode_min_level/c\    <float name=\"paper_mode_min_level\">0.0<\/float>
/is_18x9_ratio_screen/c\    <bool name=\"is_18x9_ratio_screen\">true<\/bool>" $PVENDOR/etc/device_features/jasmine_sprout.xml

# Fix audio and overlays
echo "• Fixing audio"
#AUDIO
rm -rf $PVENDOR/etc/acdbdata
cp -Raf $SVENDOR/etc/acdbdata $PVENDOR/etc/acdbdata
echo "• Adding overlays"
#statusbar/corner
rm -rf $PVENDOR/app/NotchOverlay
cp -f $FILES/overlay/DevicesOverlay.apk $PVENDOR/overlay/DevicesOverlay.apk
cp -f $FILES/overlay/DevicesAndroidOverlay.apk $PVENDOR/overlay/DevicesAndroidOverlay.apk
chmod 644 $PVENDOR/overlay/DevicesOverlay.apk
chmod 644 $PVENDOR/overlay/DevicesAndroidOverlay.apk
chown -hR root:root $PVENDOR/overlay/DevicesOverlay.apk
chown -hR root:root $PVENDOR/overlay/DevicesAndroidOverlay.apk
setfattr -h -n security.selinux -v u:object_r:vendor_overlay_file:s0 $PVENDOR/overlay/DevicesOverlay.apk
setfattr -h -n security.selinux -v u:object_r:vendor_overlay_file:s0 $PVENDOR/overlay/DevicesAndroidOverlay.apk

# Reading mode
echo "• Fixing reading mode"
cp -f $FILES/readingmode/qdcm_calib_data_jdi_nt36672_fhd_video_mode_dsi_panel.xml $PVENDOR/etc/qdcm_calib_data_jdi_nt36672_fhd_video_mode_dsi_panel.xml
cp -f $FILES/readingmode/qdcm_calib_data_tianma_nt36672_fhd_video_mode_dsi_panel.xml $PVENDOR/etc/qdcm_calib_data_tianma_nt36672_fhd_video_mode_dsi_panel.xml
chmod 644 $PVENDOR/etc/qdcm_calib_data_jdi_nt36672_fhd_video_mode_dsi_panel.xml
chmod 644 $PVENDOR/etc/qdcm_calib_data_tianma_nt36672_fhd_video_mode_dsi_panel.xml
chown -hR root:root $PVENDOR/etc/qdcm_calib_data_jdi_nt36672_fhd_video_mode_dsi_panel.xml
chown -hR root:root $PVENDOR/etc/qdcm_calib_data_tianma_nt36672_fhd_video_mode_dsi_panel.xml
setfattr -h -n security.selinux -v u:object_r:vendor_configs_file:s0 $PVENDOR/etc/qdcm_calib_data_jdi_nt36672_fhd_video_mode_dsi_panel.xml
setfattr -h -n security.selinux -v u:object_r:vendor_configs_file:s0 $PVENDOR/etc/qdcm_calib_data_tianma_nt36672_fhd_video_mode_dsi_panel.xml

# Finish up and edit init
echo "• Patching init"
#add this to line 452 at $PVENDOR/etc/init/hw/init.qcom.rc
#    exec_background u:object_r:system_file:s0 -- /system/bin/bootctl mark-boot-successful
sed -i "452 i \    exec_background u:object_r:system_file:s0 -- /system/bin/bootctl mark-boot-successful" $PVENDOR/etc/init/hw/init.qcom.rc
sed -i "124 i \
124 i \    # Wifi firmware reload path
124 i \    chown wifi wifi /sys/module/wlan/parameters/fwpath
124 i \
124 i \    # DT2W node
124 i \    chmod 0660 /sys/touchpanel/double_tap
124 i \    chown system system /sys/touchpanel/double_tap" $PVENDOR/etc/init/hw/init.target.c
read -p "• Done editing port [ENTER to continue]"

# Grep variables and edit updater-script
echo "• Fetching ROM info"
ROMVERSION=$(sudo grep ro.system.build.version.incremental= $PSYSTEM/system/build.prop | sed "s/ro.system.build.version.incremental=//g"; )
echo "• Patching updater-script"
sed -i "s%DATE%$(date +%d/%m/%Y)%g
s/ROMVERSION/$ROMVERSION/g" $OUTP/zip/META-INF/com/google/android/updater-script

# Unmount and repack
echo "• Unmounting port system"
sudo umount $PSYSTEM
echo "• Unmounting port vendor"
sudo umount $PVENDOR
echo "• Unmounting source system"
sudo umount $SSYSTEM
echo "• Unmounting source vendor"
sudo umount $SVENDOR
echo "• Removing mount points"
sudo rmdir $PSYSTEM
sudo rmdir $PVENDOR
sudo rmdir $SSYSTEM
sudo rmdir $SVENDOR

# Check and resize system
echo "• Checking filesystems"
e2fsck -y -f $OUTP/systemport.img > $ANALYTICS/MIUI-jasmeme.log 2>&1
echo "• Resizing system to 3.0 G"
resize2fs $OUTP/systemport.img 786432 > $ANALYTICS/MIUI-jasmeme.log 2>&1

# Completely repack and zip final ROM
echo "• Converting port system to sparse image"
img2simg $OUTP/systemport.img $OUTP/sparsesystem.img
rm $OUTP/systemport.img
echo "• Generating DAT files for system"
$TOOLS/img2sdat/img2sdat.py -v 4 -o $OUTP/zip -p system $OUTP/sparsesystem.img > $ANALYTICS/MIUI-jasmeme.log 2>&1
rm $OUTP/sparsesystem.img
echo "• Converting port vendor to sparse image"
img2simg $OUTP/vendorport.img $OUTP/sparsevendor.img
rm $OUTP/vendorport.img
echo "• Generating DAT files for vendor"
$TOOLS/img2sdat/img2sdat.py -v 4 -o $OUTP/zip -p vendor $OUTP/sparsevendor.img > $ANALYTICS/MIUI-jasmeme.log 2>&1
rm $OUTP/sparsevendor.img
echo "• Compressing system.new.dat"
brotli -j -v -q 6 $OUTP/zip/system.new.dat
echo "• Compressing vendor.new.dat"
brotli -j -v -q 6 $OUTP/zip/vendor.new.dat
cp -af $FILES/boot.img $OUTP/zip
cd $OUTP/zip
echo "• Zipping final ROM"
zip -ry $OUTP/10_MIUI_12_jasmine_sprout_$ROMVERSION.zip * > $ANALYTICS/MIUI-jasmeme.log 2>&1
cd $CURRENTDIR

# Cleanup
echo "• Removing all unnecessary files"
rm -rf $OUTP/zip
chown -hR $CURRENTUSER:$CURRENTUSER $OUTP

