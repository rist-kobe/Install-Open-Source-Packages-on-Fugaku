#!/bin/bash
#
set -x
#
for i in 0 1
do
	JID=`pjsub -z jid run_wrf_single_domain_restart_${i}_fj.sh`
	if [ $? -ne 0 ]; then
		exit 1
	fi
	set -- `pjwait $JID`
	if [ $2 != "0" -o $3 != "0" ]; then
		exit 1
	fi
done
#
