#!/bin/bash
set -x
#
export HOSTNAME=`hostname`
numactl --hardware
export OMP_NUM_THREADS=${1}
export OMP_WAIT_POLICY=ACTIVE
NUMA_NODE_NUM=$(((${PLE_RANK_ON_NODE}%4)+4))
echo "hostname = " ${HOSTNAME} 
echo "numa_node_num =" ${NUMA_NODE_NUM}
export GMON_OUT_PREFIX=mpigmon-${HOSTNAME}
numactl --cpunodebind=${NUMA_NODE_NUM} --membind=${NUMA_NODE_NUM} ${2}
#
