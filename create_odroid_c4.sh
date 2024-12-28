#!/bin/bash

export PATH=/opt/arm-gnu-toolchain-14.2.rel1-x86_64-aarch64-none-elf/bin:$PATH
export CROSS export CROSS_COMPILE=aarch64-none-elf-
export UBOOTDIR=/home/jan/git/hardkernel/u-boot


make odroid-c4_defconfig
make -j

if [ ! -e fip ]; then
    mkdir fip
fi

if [ ! -e "fip/blx_fix.sh" ]; then
    wget https://github.com/BayLibre/u-boot/releases/download/v2017.11-libretech-cc/blx_fix_g12a.sh -O fip/blx_fix.sh
fi

cp $UBOOTDIR/build/scp_task/bl301.bin fip/
cp $UBOOTDIR/build/board/hardkernel/odroidc4/firmware/acs.bin fip/
cp $UBOOTDIR/fip/g12a/bl2.bin fip/
cp $UBOOTDIR/fip/g12a/bl30.bin fip/
cp $UBOOTDIR/fip/g12a/bl31.img fip/
cp $UBOOTDIR/fip/g12a/ddr3_1d.fw fip/
cp $UBOOTDIR/fip/g12a/ddr4_1d.fw fip/
cp $UBOOTDIR/fip/g12a/ddr4_2d.fw fip/
cp $UBOOTDIR/fip/g12a/diag_lpddr4.fw fip/
cp $UBOOTDIR/fip/g12a/lpddr3_1d.fw fip/
cp $UBOOTDIR/fip/g12a/lpddr4_1d.fw fip/
cp $UBOOTDIR/fip/g12a/lpddr4_2d.fw fip/
cp $UBOOTDIR/fip/g12a/piei.fw fip/
cp $UBOOTDIR/fip/g12a/aml_ddr.fw fip/
cp u-boot.bin fip/bl33.bin

bash fip/blx_fix.sh \
    fip/bl30.bin \
    fip/zero_tmp \
    fip/bl30_zero.bin \
    fip/bl301.bin \
    fip/bl301_zero.bin \
    fip/bl30_new.bin \
    bl30

bash fip/blx_fix.sh \
    fip/bl2.bin \
    fip/zero_tmp \
    fip/bl2_zero.bin \
    fip/acs.bin \
    fip/bl21_zero.bin \
    fip/bl2_new.bin \
    bl2

$UBOOTDIR/fip/g12a/aml_encrypt_g12a --bl30sig --input fip/bl30_new.bin \
                                    --output fip/bl30_new.bin.g12a.enc \
                                    --level v3

$UBOOTDIR/fip/g12a/aml_encrypt_g12a --bl3sig --input fip/bl30_new.bin.g12a.enc \
                                    --output fip/bl30_new.bin.enc \
                                    --level v3 --type bl30

$UBOOTDIR/fip/g12a/aml_encrypt_g12a --bl3sig --input fip/bl31.img \
                                    --output fip/bl31.img.enc \
                                    --level v3 --type bl31

$UBOOTDIR/fip/g12a/aml_encrypt_g12a --bl3sig --input fip/bl33.bin --compress lz4 \
                                    --output fip/bl33.bin.enc \
                                    --level v3 --type bl33 --compress lz4

$UBOOTDIR/fip/g12a/aml_encrypt_g12a --bl2sig --input fip/bl2_new.bin \
                                    --output fip/bl2.n.bin.sig

$UBOOTDIR/fip/g12a/aml_encrypt_g12a --bootmk \
            --output fip/u-boot.bin \
            --bl2 fip/bl2.n.bin.sig \
            --bl30 fip/bl30_new.bin.enc \
            --bl31 fip/bl31.img.enc \
            --bl33 fip/bl33.bin.enc \
            --ddrfw1 fip/ddr4_1d.fw \
            --ddrfw2 fip/ddr4_2d.fw \
            --ddrfw3 fip/ddr3_1d.fw \
            --ddrfw4 fip/piei.fw \
            --ddrfw5 fip/lpddr4_1d.fw \
            --ddrfw6 fip/lpddr4_2d.fw \
            --ddrfw7 fip/diag_lpddr4.fw \
            --ddrfw8 fip/aml_ddr.fw \
            --ddrfw9 fip/lpddr3_1d.fw \
            --level v3


# DEV=/dev/your_sd_device
# dd if=fip/u-boot.bin.sd.bin of=$DEV conv=fsync,notrunc bs=512 skip=1 seek=1
# dd if=fip/u-boot.bin.sd.bin of=$DEV conv=fsync,notrunc bs=1 count=444