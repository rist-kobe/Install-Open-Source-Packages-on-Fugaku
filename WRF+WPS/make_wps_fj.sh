#!/bin/bash
#PJM -L "node=1:torus"
#PJM -L "rscgrp=small"
#PJM -L "elapse=15:00:00"
#PJM -L "retention_state=1"
#PJM -x PJM_LLIO_GFSCACHE=/vol0004
#PJM -S
#
set -x
#
export NARCH=fj
export CRRNTDIR=`pwd`
export TMPDIR=${CRRNTDIR}
export WRKDIR=${CRRNTDIR}/WPS+WRF_${NARCH}
export WPSLIBDIR=${WRKDIR}/LIBRARIES
export CC="fcc -Nclang -ffj-lst=t"
export CXX="FCC -Nclang -ffj-lst=t"
export FC="frt -Free"
export F77="frt -Fixed"
export JASPERLIB=${WPSLIBDIR}/grib2/lib
export JASPERINC=${WPSLIBDIR}/grib2/include
export LDFLAGS="-L${WPSLIBDIR}/netcdf/lib -L${WPSLIBDIR}/grib2/lib"
export CPPFLAGS="-I${WPSLIBDIR}/netcdf/include -I${WPSLIBDIR}/grib2/include"
export NETCDF=${WPSLIBDIR}/netcdf
export PATH=${WPSLIBDIR}/netcdf/bin:${PATH}
#
rm -rf ${WRKDIR}
mkdir -p ${WPSLIBDIR}
#
./make_wps_1.sh
#
export NARCH=fj_no_omp
./make_wps_2.sh
#
export NARCH=fj
./make_wps_3.sh
#
