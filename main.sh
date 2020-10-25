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

# Prepare directories and files
mkdir $ANALYTICS
sudo apt -y install figlet > $ANALYTICS/MIUI-jasmeme.log 2>&1
figlet MIUI-jasmeme
echo " "
echo "• Updating submodules"
sudo apt -y update > $ANALYTICS/MIUI-jasmeme.log 2>&1
sudo apt -y upgrade > $ANALYTICS/MIUI-jasmeme.log 2>&1
sudo apt -y install cpio brotli simg2img img2simg abootimg git-core gnupg flex bison gperf build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev libgl1-mesa-dev libxml2-utils xsltproc unzip zip screen attr ccache libssl-dev schedtool > $ANALYTICS/MIUI-jasmeme.log 2>&1
git clone https://github.com/xpirt/img2sdat $TOOLS/img2sdat > $ANALYTICS/MIUI-jasmeme.log 2>&1
git clone https://github.com/xpirt/sdat2img $TOOLS/sdat2img > $ANALYTICS/MIUI-jasmeme.log 2>&1
echo "• Beginning port sequence"

# Unzip jasmine_global_images.tgz if needed
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

# Unzip and convert base ROM to disk images
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

# Fix Magisk and cam watermarks
echo "• Creating Magisk addon"
mkdir $PSYSTEM/system/addon.d
setfattr -h -n security.selinux -v u:object_r:system_file:s0 $PSYSTEM/system/addon.d
chmod 755 $PSYSTEM/system/addon.d
echo "• Patching camera watermarks"
cp -af $SVENDOR/etc/MIUI_DualCamera_watermark.png $PVENDOR/etc/MIUI_DualCamera_watermark.png

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

# Remove ugly Xiaomi.eu icons and Gboard theme
echo "• Fixing icon pack"
sudo rm -rf $PSYSTEM/system/media/theme/miui_mod_icons
sudo cp -Raf $FILES/miui_mod_icons $PSYSTEM/system/media/theme
sudo chmod 0644 $PSYSTEM/system/media/theme/miui_mod_icons/*
echo "• Removing keyboard theme"
sudo rm -rf $PSYSTEM/system/etc/gboad_theme

# Edit build.prop to Mi 6X specs
echo "• Renaming device features XMLs"
mv $PSYSTEM/system/etc/device_features/lavender.xml $PSYSTEM/system/etc/device_features/wayne.xml
mv $PVENDOR/etc/device_features/lavender.xml $PVENDOR/etc/device_features/wayne.xml
echo "• Editing build prop files"
sed -i "/persist.camera.HAL3.enabled=/c\persist.camera.HAL3.enabled=1
/persist.vendor.camera.HAL3.enabled=/c\persist.vendor.camera.HAL3.enabled=1
/ro.product.model=/c\ro.product.model=MI 6X
/ro.build.id=/c\ro.build.id=10 MIUI 12 by Sebastian
/persist.vendor.camera.exif.model=/c\persist.vendor.camera.exif.model=MI 6X
/ro.product.name=/c\ro.product.name=wayne
/ro.product.device=/c\ro.product.device=wayne
/ro.build.product=/c\ro.build.product=wayne
/ro.product.system.device=/c\ro.product.system.device=wayne
/ro.product.system.model=/c\ro.product.system.model=MI 6X
/ro.product.system.name=/c\ro.product.system.name=wayne
/ro.miui.notch=/c\ro.miui.notch=0
/sys.paper_mode_max_level=/c\sys.paper_mode_max_level=32
\$ i sys.tianma_nt36672_offset=12
\$ i sys.tianma_nt36672_length=46
\$ i sys.jdi_nt36672_offset=9
\$ i sys.jdi_nt36672_length=45
\$ i persist.vendor.imx376_sunny.low.lux=310
\$ i persist.vendor.imx376_sunny.light.lux=280
\$ i persist.vendor.imx376_ofilm.low.lux=310
\$ i persist.vendor.imx376_ofilm.light.lux=280
\$ i persist.vendor.bokeh.switch.lux=290
\$ i persist.vendor.camera.auxswitch.threshold=330
\$ i persist.vendor.camera.mainswitch.threshold=419
\$ i persist.vendor.camera.stats.test=0
\$ i persist.vendor.camera.depth.focus.cb=0
\$ i persist.vendor.camera.isp.clock.optmz=0
\$ i persist.vendor.camera.linkpreview=0
\$ i persist.vendor.camera.auxswitch.threshold=330
\$ i persist.vendor.camera.mainswitch.threshold=419
\$ i persist.vendor.camera.expose.aux=1
/persist.vendor.camera.model=/c\persist.vendor.camera.model=MI 6X" $PSYSTEM/system/build.prop
sed -i "/ro.build.characteristics=/c\ro.build.characteristics=nosdcard" $PSYSTEM/system/product/build.prop
sed -i "/ro.product.vendor.model=/c\ro.product.vendor.model=MI 6X
/ro.product.vendor.name=/c\ro.product.vendor.name=wayne
\$ i persist.vendor.imx376_sunny.low.lux=310
\$ i persist.vendor.imx376_sunny.light.lux=280
\$ i persist.vendor.imx376_ofilm.low.lux=310
\$ i persist.vendor.imx376_ofilm.light.lux=280
\$ i persist.vendor.bokeh.switch.lux=290
\$ i persist.vendor.camera.auxswitch.threshold=330
\$ i persist.vendor.camera.mainswitch.threshold=419
\$ i persist.vendor.camera.stats.test=0
\$ i persist.vendor.camera.depth.focus.cb=0
\$ i persist.vendor.camera.isp.clock.optmz=0
\$ i persist.vendor.camera.linkpreview=0
\$ i persist.vendor.camera.auxswitch.threshold=330
\$ i persist.vendor.camera.mainswitch.threshold=419
\$ i persist.vendor.camera.expose.aux=1
/ro.product.vendor.device=/c\ro.product.vendor.device=wayne" $PVENDOR/build.prop
sed -i "/ro.product.odm.device=/c\ro.product.odm.device=wayne
/ro.product.odm.model=/c\ro.product.odm.model=MI 6X
/ro.product.odm.device=/c\ro.product.odm.device=wayne
/ro.product.model=/c\ro.product.model=MI 6X
/ro.product.odm.name=/c\ro.product.odm.name=wayne" $PVENDOR/odm/etc/build.prop

# Firmware / fstabs
echo "• Patching vendor firmware"
rm -rf $PVENDOR/firmware
cp -Raf $SVENDOR/firmware $PVENDOR/firmware
#VENDOR
echo "• Copying fstabs"
cp -f $FILES/fstab.qcom $PVENDOR/etc/
chmod 644 $PVENDOR/etc/fstab.qcom
setfattr -h -n security.selinux -v u:object_r:vendor_configs_file:s0 $PVENDOR/etc/fstab.qcom
chown -hR root:root $PVENDOR/etc/fstab.qcom
#KEYMASTER
echo "• Keymaster edit"
rm -f $PVENDOR/etc/init/android.hardware.keymaster@4.0-service-qti.rc
cp -af $SVENDOR/etc/init/android.hardware.keymaster@3.0-service-qti.rc $PVENDOR/etc/init/android.hardware.keymaster@3.0-service-qti.rc
sed -i "171 s/        <version>4.0<\/version>/        <version>3.0<\/version>/g
s/4.0::IKeymasterDevice/3.0::IKeymasterDevice/g" $PVENDOR/etc/vintf/manifest.xml

# Add vendor sensors / libs
echo "• Fixing vendor sensors"
rm -rf $PVENDOR/etc/sensors
cp -Raf $SVENDOR/etc/sensors $PVENDOR/etc/sensors
cp -af $SVENDOR/etc/camera/camera_config.xml $PVENDOR/etc/camera/camera_config.xml
cp -af $SVENDOR/etc/camera/csidtg_camera.xml $PVENDOR/etc/camera/csidtg_camera.xml
cp -af $SVENDOR/etc/camera/csidtg_chromatix.xml $PVENDOR/etc/camera/camera_chromatix.xml
echo "• Parsing vendor libs"
cp -af $SVENDOR/lib/libMiWatermark.so $PVENDOR/lib/libMiWatermark.so
cp -af $SVENDOR/lib/libdng_sdk.so $PVENDOR/lib/libdng_sdk.so
cp -af $SVENDOR/lib/libvidhance_gyro.so $PVENDOR/lib/libvidhance_gyro.so
cp -af $SVENDOR/lib/libvidhance.so $PVENDOR/lib/
cp -af $SVENDOR/lib/libmmcamera* $PVENDOR/lib/
cp -af $SVENDOR/lib64/libmmcamera* $PVENDOR/lib64/
cp -f $SVENDOR/lib/hw/camera.sdm660.so $PVENDOR/lib/hw/

# Patch vendor fingerprint files
echo "• Making device fingerprint"
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

# Port system biometrics and keylayout
echo "• Fixing keylayout"
cp -af $SSYSTEM/system/usr/keylayout/uinput-fpc.kl $PSYSTEM/system/usr/keylayout/uinput-fpc.kl
cp -af $SSYSTEM/system/usr/idc/uinput-fpc.idc $PSYSTEM/system/usr/idc/uinput-fpc.idc
cp -af $SSYSTEM/system/usr/keylayout/uinput-fpc.kl $PSYSTEM/system/usr/keylayout/uinput-fpc.kl
cp -af $SSYSTEM/system/usr/idc/uinput-fpc.idc $PSYSTEM/system/usr/idc/uinput-fpc.idc
echo "• Editing goodix biometrics"
sed -i "467 c\        <name>vendor.goodix.hardware.fingerprint</name>" $PVENDOR/etc/vintf/manifest.xml
sed -i "469 c\        <version>1.0</version>
471 c\            <name>IGoodixBiometricsFingerprint</name>
474 c\        <fqname>@1.0::IGoodixBiometricsFingerprint/default</fqname>
475d
476d
477d
478d
479d" $PVENDOR/etc/vintf/manifest.xml

# Add libs / firmware from source 
echo "• Patching system firmware"
rm -rf $PSYSTEM/system/etc/firmware || true
cp -Raf $SSYSTEM/system/etc/firmware/* $PVENDOR/firmware/ || true
echo "• Patching wifi HALs"
cp -f $FILES/libwifi-hal64.so $PVENDOR/lib64/libwifi-hal.so
chmod 644 $PVENDOR/lib64/libwifi-hal.so
chown -hR root:root $PVENDOR/lib64/libwifi-hal.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib64/libwifi-hal.so
cp -f $FILES/libwifi-hal32.so $PVENDOR/lib/libwifi-hal.so
chmod 644 $PVENDOR/lib/libwifi-hal.so
chown -hR root:root $PVENDOR/lib/libwifi-hal.so
setfattr -h -n security.selinux -v u:object_r:vendor_file:s0 $PVENDOR/lib/libwifi-hal.so

# Edit wayne.xml from /system/etc/device_features
echo "• Editing system device features"
#system/etc/device_features
sed -i "/support_dual_sd_card/c\    <bool name=\"support_dual_sd_card\">true<\/bool>
/battery_capacity_typ/c\    <string name=\"battery_capacity_typ\">3010<\/string>
/support_camera_4k_quality/c\    <bool name=\"support_camera_4k_quality\">true<\/bool>
/bool name=\"is_xiaomi\">/c\    <bool name=\"is_xiaomi\">true<\/bool>
/is_hongmi/c\    <bool name=\"is_hongmi\">false<\/bool>
/is_redmi/c\    <bool name=\"is_redmi\">false<\/bool>
/paper_mode_max_level/c\    <float name=\"paper_mode_max_level\">32.0<\/float>
/paper_mode_min_level/c\    <float name=\"paper_mode_min_level\">0.0<\/float>
\$ i <bool name="support_aod">true</bool> 
/is_18x9_ratio_screen/c\    <bool name=\"is_18x9_ratio_screen\">true<\/bool>" $PSYSTEM/system/etc/device_features/wayne.xml
echo "• Editing vendor device features"
#vendor/etc/device_features
sed -i "/support_dual_sd_card/c\    <bool name=\"support_dual_sd_card\">true<\/bool>
/battery_capacity_typ/c\    <string name=\"battery_capacity_typ\">3010<\/string>
/support_camera_4k_quality/c\    <bool name=\"support_camera_4k_quality\">true<\/bool>
/bool name=\"is_xiaomi\">/c\    <bool name=\"is_xiaomi\">true<\/bool>
/is_hongmi/c\    <bool name=\"is_hongmi\">false<\/bool>
/is_redmi/c\    <bool name=\"is_redmi\">false<\/bool>
/paper_mode_max_level/c\    <float name=\"paper_mode_max_level\">32.0<\/float>
/paper_mode_min_level/c\    <float name=\"paper_mode_min_level\">0.0<\/float>
\$ i <bool name="support_aod">true</bool> 
/is_18x9_ratio_screen/c\    <bool name=\"is_18x9_ratio_screen\">true<\/bool>" $PVENDOR/etc/device_features/wayne.xml

#Audio fix
echo "• Fixing audio"
rm -rf $PVENDOR/etc/acdbdata
cp -Raf $SVENDOR/etc/acdbdata $PVENDOR/etc/acdbdata


# Overlays
echo "• Patching overlays and notch"
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

# Make last edits
echo "• Editing wifi firmware"
sed -i "124 i \
124 i \    # Wifi firmware reload path
124 i \    chown wifi wifi /sys/module/wlan/parameters/fwpath
124 i \
124 i \    # DT2W node
124 i \    chmod 0660 /sys/touchpanel/double_tap
124 i \    chown system system /sys/touchpanel/double_tap" $PVENDOR/etc/init/hw/init.target.rc
read -p "• Done editing port [ENTER to continue]"

# Edit updater-script
echo "• Fetching ROM info"
ROMVERSION=$(sudo grep ro.system.build.version.incremental= $PSYSTEM/system/build.prop | sed "s/ro.system.build.version.incremental=//g"; )
echo "• Patching updater-script"
sed -i "s%DATE%$(date +%d/%m/%Y)%g
s/ROMVERSION/$ROMVERSION/g" $OUTP/zip/META-INF/com/google/android/updater-script

# Unmount / cleanup
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

# Zip the final ROM
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
zip -ry $OUTP/10_MIUI_12_wayne_$ROMVERSION.zip * > $ANALYTICS/MIUI-jasmeme.log 2>&1
cd $CURRENTDIR

# Cleanup
echo "• Removing all unnecessary files"
rm -rf $OUTP/zip
chown -hR $CURRENTUSER:$CURRENTUSER $OUTP