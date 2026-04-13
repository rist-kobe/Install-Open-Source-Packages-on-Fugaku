#!/bin/bash
set -x
#
cd ${WRKDIR}
rm -rf WRF_serial
rm -rf WRFV4.6.1
tar xzvf ../v4.6.1.tar.gz
mv WRFV4.6.1 WRF_serial
cd WRF_serial
patch arch/configure.defaults < ../../WRF_configure.defaults_${NARCH}.patch
./clean
./configure <<EOF
3
1
EOF
./compile em_real >& log.compile
cd ..
#
export WRF_DIR=${WRKDIR}/WRF_serial
cd ${WRKDIR}
rm -rf WPS_serial
rm -rf WPS-4.6.0
unzip ../WPS-4.6.0.zip
mv WPS-4.6.0 WPS_serial
cd WPS_serial
patch arch/configure.defaults < ../../WPS_configure.defaults_${NARCH}.patch
./clean
./configure <<EOF
3
EOF
./compile >& log.compile
cd ..
#
