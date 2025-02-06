#!/bin/bash
#
# Script Compiler Kernel Arm64
#
# Copyright (C) 2024-2025 DemonSly <196890566+DenomSly@users.noreply.github.com>
#
#set -e

if [ ! -d "clang" ]; then
    mkdir clang && curl  https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz -RLO && tar -C clang/ -xf clang-*.tar.gz
else
	echo "Local clang dir found, will not download clang and using that instead"
fi

# Exprort Variabel 
DEFCONFIG="vendor/sdmteppe-perf_defconfig"
CONFIG="vendor/sweet.config
export PATH="${PWD}/clang/bin/:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_USER=Building 
export KBUILD_BUILD_HOST=DenomSly
export KBUILD_COMPILER_STRING="${PWD}/clang"

# Speed up build process
MAKE="./makeparallel"

blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$blue***********************************************"
echo -e "      SELECTED BUILD TYPE                          "
echo -e "***********************************************$nocol"
echo "1. MIUI"
echo "2. AOSP"
read -p "Enter the number of your choice: " build_choice
# Modify dtsi file if MIUI build is selected
if [ "$build_choice" = "1" ]; then
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <69>;$/qcom,mdss-pan-physical-width-dimension = <695>;/' arch/arm64/boot/dts/qcom/xiaomi/sweet/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <154>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/' arch/arm64/boot/dts/qcom/xiaomi/sweet/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    DISPLAY="MIUI"
elif [ "$build_choice" = "2" ]; then
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <695>;$/qcom,mdss-pan-physical-width-dimension = <69>;/' arch/arm64/boot/dts/qcom/xiaomi/sweet/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <1546>;$/qcom,mdss-pan-physical-height-dimension = <154>;/' arch/arm64/boot/dts/qcom/xiaomi/sweet/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    DISPLAY="AOSP"
    else
    echo "Invalid choice. Exiting..."
    exit 1
fi


echo -e "$blue***********************************************"
echo "          BUILDING KERNEL $DISPLAY                  "
echo -e "***********************************************$nocol"
make $DEFCONFIG O=out 
make $CONFIG O=out 
make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi 2>&1 | tee -a build.log

IMAGE="out/arch/arm64/boot/Image.gz"
DTBO="out/arch/arm64/boot/dtbo.img"
DTB="out/arch/arm64/boot/dtb.img"

if [ ! -f "$IMAGE" ] || [ ! -f "$DTBO" ] || [ ! -f "$DTB" ]; then
	echo -e "\nCompilation failed!"
	exit 1
fi

echo -e "\nKernel compiled successfully! Zipping up...\n"


git clone --depth=1 https://github.com/basamaryan/AnyKernel3 -b master AnyKernel3


# Modify anykernel.sh to replace device names
sed -i "s/device\.name1=.*/device.name1=sweet/" AnyKernel3/anykernel.sh
sed -i "s/device\.name2=.*/device.name2=sweetin/" AnyKernel3/anykernel.sh

cp $IMAGE AnyKernel3
cp $DTBO AnyKernel3
cp $DTB AnyKernel3
cd AnyKernel3
zip -r9 "../sweet--${DISPLAY}-$(date '+%Y%m%d-%H%M').zip" * -x .git
cd ..
rm -rf AnyKernel3/Image.gz
rm -rf AnyKernel3/dtbo.img
rm -rf AnyKernel3/dtb.img
echo -e "$blue***********************************************"
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo -e "***********************************************$nocol"
