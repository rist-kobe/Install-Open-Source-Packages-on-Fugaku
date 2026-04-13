#!/bin/bash
set -x
#
cd ${WRKDIR}
rm -rf WRF_multiple
rm -rf WRFV4.6.1
tar xzvf ../v4.6.1.tar.gz
mv WRFV4.6.1 WRF_multiple
cd WRF_multiple
patch arch/configure.defaults < ../../WRF_configure.defaults_${NARCH}.patch
./clean
./configure <<EOF
4
1
EOF
./compile em_real >& log.compile
cd ..
#
