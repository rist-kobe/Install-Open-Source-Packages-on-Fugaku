#!/bin/bash
#PJM -L "node=2:torus"
#PJM -L "rscgrp=small"
#PJM -L "elapse=00:30:00"
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
export EXPNAME=single_domain
export NARCH=fj
export CRRNTDIR=`pwd`
export TMPDIR=${CRRNTDIR}
export WRKDIR=${CRRNTDIR}/WPS+WRF_${NARCH}
export SUBDIR=WRF_multiple_${EXPNAME}
export FORT90L=-Wl,-T
#
llio_transfer ${CRRNTDIR}/matthew_1deg.tar.gz
llio_transfer ${CRRNTDIR}/matthew_sst.tar.gz
llio_transfer ${CRRNTDIR}/namelist_${EXPNAME}.input
llio_transfer ${CRRNTDIR}/numa_bind_exec.sh
#
rm -rf ${WRKDIR}/${SUBDIR}
#
cd ${PJM_SHAREDTMP}
mkdir DATA
cd DATA
tar zxf ${CRRNTDIR}/matthew_1deg.tar.gz
tar zxf ${CRRNTDIR}/matthew_sst.tar.gz
cd ..
rsync -a ${WRKDIR}/LIBRARIES ./
rsync -a ${WRKDIR}/WPS_serial_${EXPNAME} ./
rsync -a ${WRKDIR}/WRF_multiple/ ${SUBDIR}/
#
cd ${SUBDIR}/test/em_real
#
cp ${CRRNTDIR}/namelist_${EXPNAME}.input ./namelist.input
ln -s ../../../WPS_serial_${EXPNAME}/met_em.d0*.2016-10* ./
#
mpiexec -stdout-proc ./stdout.%j/%/1000r/file_stdout -stderr-proc ./stderr.%j/%/1000r/file_stderr -n 8 ${CRRNTDIR}/numa_bind_exec.sh  1 ./real.exe
mpiexec -stdout-proc ./stdout.%j/%/1000r/file_stdout -stderr-proc ./stderr.%j/%/1000r/file_stderr -n 8 ${CRRNTDIR}/numa_bind_exec.sh 12 ./wrf.exe
#
cd ../../..
rsync -a ${SUBDIR} ${WRKDIR}/
cd ..
#
llio_transfer --purge ${CRRNTDIR}/matthew_1deg.tar.gz
llio_transfer --purge ${CRRNTDIR}/matthew_sst.tar.gz
llio_transfer --purge ${CRRNTDIR}/namelist_${EXPNAME}.input
llio_transfer --purge ${CRRNTDIR}/numa_bind_exec.sh
#
