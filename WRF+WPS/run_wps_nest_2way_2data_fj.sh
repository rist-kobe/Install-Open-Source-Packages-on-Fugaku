#!/bin/bash
#PJM -L "node=2:torus"
#PJM -L "rscgrp=small"
#PJM -L "elapse=00:20:00"
#PJM -L "retention_state=0"
#PJM --mpi proc=8
#PJM --mpi max-proc-per-node=4
#PJM --mpi rank-map-bychip
#PJM --mpi rank-map-hostfile=machinefile
#PJM --llio sharedtmp-size=82Gi
#PJM -x PJM_LLIO_GFSCACHE=/vol0004
#PJM -S
#
set -x
#
export EXPNAME=nest_2way_2data
export NARCH=fj
export CRRNTDIR=`pwd`
export TMPDIR=${CRRNTDIR}
export WRKDIR=${CRRNTDIR}/WPS+WRF_${NARCH}
export SUBDIR=WPS_serial_${EXPNAME}
export FORT90L=-Wl,-T
#
llio_transfer ${CRRNTDIR}/geog_high_res_mandatory.tar.gz
llio_transfer ${CRRNTDIR}/matthew_1deg.tar.gz
llio_transfer ${CRRNTDIR}/matthew_sst.tar.gz
llio_transfer ${CRRNTDIR}/namelist_${EXPNAME}.wps
llio_transfer ${CRRNTDIR}/numa_bind_exec.sh
#
cd ${PJM_SHAREDTMP}
tar xzf ${CRRNTDIR}/geog_high_res_mandatory.tar.gz
mkdir DATA
cd DATA
tar zxf ${CRRNTDIR}/matthew_1deg.tar.gz
tar zxf ${CRRNTDIR}/matthew_sst.tar.gz
cd ..
rsync -a ${WRKDIR}/LIBRARIES ./
rm -rf ${SUBDIR}
rsync -a ${WRKDIR}/WPS_serial/ ${SUBDIR}/
#
cd ${SUBDIR}
#
cp ${CRRNTDIR}/namelist_${EXPNAME}.wps ./namelist.wps
ln -sf ./ungrib/Variable_Tables/Vtable.GFS ./Vtable
csh ./link_grib.csh ../DATA/matthew/fnl
./ungrib.exe
#
sed -e "s/prefix = 'FILE'/prefix = 'SST'/g" ${CRRNTDIR}/namelist_${EXPNAME}.wps > ./namelist.wps
ln -sf ./ungrib/Variable_Tables/Vtable.SST ./Vtable
csh ./link_grib.csh ../DATA/matthew_sst/rtg_sst_grb
./ungrib.exe
#

mpiexec -stdout-proc ./stdout.%j/%/1000r/file_stdout -stderr-proc ./stderr.%j/%/1000r/file_stderr -n 8 ${CRRNTDIR}/numa_bind_exec.sh 1 ./geogrid.exe
mpiexec -stdout-proc ./stdout.%j/%/1000r/file_stdout -stderr-proc ./stderr.%j/%/1000r/file_stderr -n 8 ${CRRNTDIR}/numa_bind_exec.sh 1 ./metgrid.exe
#
cd ..
rsync -a ${SUBDIR} ${WRKDIR}/
cd ..
#
llio_transfer --purge ${CRRNTDIR}/geog_high_res_mandatory.tar.gz
llio_transfer --purge ${CRRNTDIR}/matthew_1deg.tar.gz
llio_transfer --purge ${CRRNTDIR}/matthew_sst.tar.gz
llio_transfer --purge ${CRRNTDIR}/namelist_${EXPNAME}.wps
llio_transfer --purge ${CRRNTDIR}/numa_bind_exec.sh
#
