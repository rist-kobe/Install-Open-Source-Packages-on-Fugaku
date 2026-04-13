# WRF 4.6.1 + WPS 4.6 構築手順

## ソフトウェア情報

ソフトウェア名
- WRF (Weather Research & Forecasting Model)
- WPS (WRF Pre-Processing System)<br>

ソフトウェア概要
- メソスケール気象予測システム<br>

使用バージョン
- WRF: 4.6.1
- WPS: 4.6

言語
- Fortran, C, MPI, OpenMP<br>

入手元URL
- https://www.mmm.ucar.edu/models/wrf<br>

ライセンス
- <a href="https://www2.mmm.ucar.edu/wrf/users/public_domain_notice.html">WRF Public Domain Notice</a><br>

必要ライブラリ
- netcdf-c-4.7.2
- netcdf-fortran-4.5.2
- zlib-1.2.11
- libpng-1.2.50
- jasper-1.9.00.1

##
## 実行環境構築

前提条件
- この手順は、スーパーコンピュータ「富岳」のログインノードにて実行するものとなっております。<br>
- この手順は、ホームディレクトリ配下のファイル「.bashrc」に、ご自身で手を加えられていないことを前提としております。<br>
- この手順は、ホームディレクトリ配下に、次の2つのディレクトリ「bin」「.local」が存在していないか、存在していても空であることを前提としております。空でないものが存在している場合には、そのディレクトリを、名前を一時的に変更するなどの方法により、事前に退避させてください。<br>

手順
1. 必要ファイルの配置

   「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」の配下に、ソースプログラムと動作確認用データの一式が格納されているとします。これらのファイルは、上記入手先URLより辿ることができる場所にて入手することができますので、ユーザー登録を行った上でダウンロードしてください。
   ```
   $ cd ${storage}
   $ ls -1
   WPS-4.6.0.tar.gz # WPS-4.6
   geog_high_res_mandatory.tar.gz  # Geographical Input Data (Mandatory Fields)
   matthew_1deg.tar.gz  # Matthew case study data
   matthew_sst.tar.gz  # SST data
   v4.6.1.tar.gz  # WRF-4.6.1
   ```
   上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」の配下に、以下の9つのファイル（作成者:RIST）を、ここよりダウンロードして配置します。加えて、コマンド「chmod u+x \*」を実行することにより、ファイル（拡張子が「\*.sh」のファイル）について、その所有者に実行権限を与えます。
   - [make_wps_fj.sh](./make_wps_fj.sh)
   - [make_wps_1.sh](./make_wps_1.sh)
   - [make_wps_2.sh](./make_wps_2.sh)
   - [make_wps_3.sh](./make_wps_3.sh)
   - [WPS_configure.defaults_fj_no_omp.patch](./WPS_configure.defaults_fj_no_omp.patch)
   - [WRF_configure.defaults_fj_no_omp.patch](./WRF_configure.defaults_fj_no_omp.patch)
   - [WRF_configure.defaults_fj.patch](./WRF_configure.defaults_fj.patch)
   
2. 実行形式ファイルの作成

   上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」にて、以下のコマンドを実行することによりジョブを投入します。使用するノード数は1ノードで、ジョブの実行時間は11時間程度です。
   ```
   $ pjsub make_wps_fj.sh
   ```
   ジョブが正常に終了すると、フラットMPI並列化されたWRFと、フラットMPI並列化されたWPSと、MPI+OpenMPのハイブリッド並列化されたWRFのそれぞれのロードモジュールファイル群が、以下の通り、3つのディレクトリの配下に作成されています。作成される実行形式ファイル「*.exe」は、合計11個です。
   ```
   $ ls -1 WPS+WRF_fj/WRF_serial/main/*.exe
   WPS+WRF_fj/WRF_serial/main/ndown.exe
   WPS+WRF_fj/WRF_serial/main/real.exe
   WPS+WRF_fj/WRF_serial/main/tc.exe
   WPS+WRF_fj/WRF_serial/main/wrf.exe
   $ ls -1 WPS+WRF_fj/WPS_serial/*.exe
   WPS+WRF_fj/WPS_serial/geogrid.exe
   WPS+WRF_fj/WPS_serial/metgrid.exe
   WPS+WRF_fj/WPS_serial/ungrib.exe
   $ ls -1 WPS+WRF_fj/WRF_multiple/main/*.exeR
   WPS+WRF_fj/WRF_multiple/main/ndown.exe
   WPS+WRF_fj/WRF_multiple/main/real.exe
   WPS+WRF_fj/WRF_multiple/main/tc.exe
   WPS+WRF_fj/WRF_multiple/main/wrf.exe
   ```
##
## 動作確認

[WRF-ARW Online Tutorial](https://www2.mmm.ucar.edu/wrf/OnLineTutorial/)

1. Single Domain Case
   
   「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」の配下に、以下の6つのファイル（作成者:RIST）を、ここよりダウンロードして配置します。加えて、コマンド「chmod u+x \*.sh」を実行することにより、シェルスクリプトファイル（拡張子が「\*.sh」のファイル）について、その所有者に実行権限を与えます。
   - [namelist_single_domain.wps](./namelist_single_domain.wps)
   - [run_wps_single_domain_fj.sh](./run_wps_single_domain_fj.sh)
   - [namelist_single_domain.input](./namelist_single_domain.input)
   - [run_wrf_single_domain_fj.sh](./run_wrf_single_domain_fj.sh)
   - [numa_bind_exec.sh](./numa_bind_exec.sh)
   - [machinefile](./machinefile)

   上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」にて、以下のコマンドを実行することにより、ジョブを投入します。2ノード8プロセスのフラットMPI並列での実行の場合、ジョブの実行時間は15分程度です。
   ```
   $ pjsub run_wps_single_domain_fj.sh
   ```
   上記のジョブの実行が正常終了したら、以下のコマンドを実行することにより、ジョブを投入します。2ノード8プロセス、1プロセス当たり12スレッドのMPI+OpenMPハイブリッド並列での実行の場合、ジョブの実行時間は25分程度です。
   ```
   $ pjsub run_wrf_single_domain_fj.sh
   ```
   ロードモジュールファイル「wrf.exe」を実行した際の0番ランクからの出力が、上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}/WPS+WRF_fj/WRF_multiple_single_domain/test/em_real」内のファイル「rsl.out.0000」に格納されているので、その最終行が「wrf: SUCCESS COMPLETE WRF」となっていることを確認してください。また、同ディレクトリ内に、ファイル「wrfout_d01_2016-10-08_00:00:00」及び「wrfrst_d01_2016-10-08_00:00:00」が作成されていることを確認してください。
   ```
   $ tail rsl.out.0000
   Timing for main: time 2016-10-07_23:45:00 on domain   1:    0.06600 elapsed seconds
   Timing for main: time 2016-10-07_23:47:30 on domain   1:    0.06318 elapsed seconds
   Timing for main: time 2016-10-07_23:50:00 on domain   1:    0.06634 elapsed seconds
   Timing for main: time 2016-10-07_23:52:30 on domain   1:    0.06322 elapsed seconds
   Timing for main: time 2016-10-07_23:55:00 on domain   1:    0.06599 elapsed seconds
   Timing for main: time 2016-10-07_23:57:30 on domain   1:    0.06313 elapsed seconds
   Timing for main: time 2016-10-08_00:00:00 on domain   1:    0.06608 elapsed seconds
   Timing for Writing wrfout_d01_2016-10-08_00:00:00 for domain        1:    0.50977 elapsed seconds
   Timing for Writing restart for domain        1:    2.55260 elapsed seconds
   wrf: SUCCESS COMPLETE WRF
   $ ls wrf*10-08_*
   wrfout_d01_2016-10-08_00:00:00  wrfrst_d01_2016-10-08_00:00:00
   $
   ```
2. Restart Run

   「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」の配下に、以下の6つのファイル（作成者:RIST）を、ここよりダウンロードして配置します。加えて、コマンド「chmod u+x \*.sh」を実行することにより、シェルスクリプトファイル（拡張子が「\*.sh」のファイル）について、その所有者に実行権限を与えます。<br>
   - [namelist_single_domain.wps](./namelist_single_domain.wps) （1. Single Domain Case を実行するためのファイルと同じファイルなので、1. を実行済みの場合は省略可）<br>
   - [run_wps_single_domain_fj.sh](./run_wps_single_domain_fj.sh) （1. Single Domain Case を実行するためのファイルと同じファイルなので、1. を実行済みの場合は省略可）<br>
   - [namelist_single_domain_restart_0.input](./namelist_single_domain_restart_0.input)<br>
   - [namelist_single_domain_restart_1.input](./namelist_single_domain_restart_1.input)<br>
   - [run_wrf_single_domain_restart_0_fj.sh](./run_wrf_single_domain_restart_0_fj.sh)<br>
   - [run_wrf_single_domain_restart_1_fj.sh](./run_wrf_single_domain_restart_1_fj.sh)<br>
   - [run_wrf_single_domain_restart_fj.sh](./run_wrf_single_domain_restart_fj.sh)<br>
   - [numa_bind_exec.sh](./numa_bind_exec.sh) （1. Single Domain Case を実行するためのファイルと同じファイルなので、1. を実行済みの場合は省略可）<br>
   - [machinefile](./machinefile) （1. Single Domain Case を実行するためのファイルと同じファイルなので、1. を実行済みの場合は省略可）

   上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」にて、以下のコマンドを実行することにより、ジョブを投入します。2ノード8プロセスのフラットMPI並列での実行の場合、ジョブの実行時間は15分程度です。このコマンドの実行（ジョブ投入）は、1. Single Domain Case にて実行するものと同じであるため、1. を次実行済みの場合は省略可能です。
   ```
   $ pjsub run_wps_single_domain_fj.sh
   ```
   上記のジョブの実行が正常終了したら、以下のコマンドを実行することにより、ジョブを2つ投入します。2ノード8プロセス、1プロセス当たり12スレッドのMPI+OpenMPハイブリッド並列での実行の場合、それぞれのジョブの実行時間は15分程度です。
   ```
   ./run_wrf_single_domain_restart_fj.sh >& run_wrf_single_domain_restart_fj.txt &
   ```
   ロードモジュールファイル「wrf.exe」を実行した際の0番ランクからの出力が、上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}/WPS+WRF_fj/WRF_multiple_single_domain_restart/test/em_real」内のファイル「rsl.out.0000」に格納されているので、その最終行が「wrf: SUCCESS COMPLETE WRF」となっていることを確認してください。また、同ディレクトリ内に、ファイル「wrfout_d01_2016-10-08_00:00:00」及び「wrfrst_d01_2016-10-08_00:00:00」が作成されていることを確認してください。
   ```
   $ tail rsl.out.0000
   Timing for main: time 2016-10-07_23:45:00 on domain   1:    0.06652 elapsed seconds
   Timing for main: time 2016-10-07_23:47:30 on domain   1:    0.06337 elapsed seconds
   Timing for main: time 2016-10-07_23:50:00 on domain   1:    0.06680 elapsed seconds
   Timing for main: time 2016-10-07_23:52:30 on domain   1:    0.06340 elapsed seconds
   Timing for main: time 2016-10-07_23:55:00 on domain   1:    0.06677 elapsed seconds
   Timing for main: time 2016-10-07_23:57:30 on domain   1:    0.06338 elapsed seconds
   Timing for main: time 2016-10-08_00:00:00 on domain   1:    0.06673 elapsed seconds
   Timing for Writing wrfout_d01_2016-10-08_00:00:00 for domain        1:    0.51389 elapsed seconds
   Timing for Writing restart for domain        1:    2.52123 elapsed seconds
   wrf: SUCCESS COMPLETE WRF
   $ ls wrf*10-08_*
   wrfout_d01_2016-10-08_00:00:00  wrfrst_d01_2016-10-08_00:00:00
   $
   ```   
3. Nested Model Run: 2-way with 2 Input Files

   「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」の配下に、以下の6つのファイル（作成者:RIST）を、ここよりダウンロードして配置します。加えて、コマンド「chmod u+x \*.sh」を実行することにより、シェルスクリプトファイル（拡張子が「\*.sh」のファイル）について、その所有者に実行権限を与えます。<br>
   - [namelist_nest_2way_2data.wps](./namelist_nest_2way_2data.wps)<br>
   - [run_wps_nest_2way_2data_fj.sh](./run_wps_nest_2way_2data_fj.sh)<br>
   - [namelist_nest_2way_2data.input](./namelist_nest_2way_2data.input)<br>
   - [run_wrf_nest_2way_2data_fj.sh](./run_wrf_nest_2way_2data_fj.sh)<br>
   - [numa_bind_exec.sh](./numa_bind_exec.sh) （1. Single Domain Case を実行するためのファイルと同じファイルなので、1. を実行済みの場合は省略可）<br>
   - [machinefile](./machinefile) （1. Single Domain Case を実行するためのファイルと同じファイルなので、1. を実行済みの場合は省略可）

   上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}」にて、以下のコマンドを実行することにより、ジョブを投入します。2ノード8プロセスのフラットMPI並列での実行の場合、ジョブの実行時間は15分程度です。
   ```
   $ pjsub run_wps_nest_2way_2data_fj.sh
   ```
   上記のジョブの実行が正常終了したら、以下のコマンドを実行することにより、ジョブを投入します。2ノード8プロセス、1プロセス当たり12スレッドのMPI+OpenMPハイブリッド並列での実行の場合、ジョブの実行時間は25分程度です。
   ```
   $ pjsub run_wrf_nest_2way_2data_fj.sh
   ```
   ロードモジュールファイル「wrf.exe」を実行した際の0番ランクからの出力が、上記のディレクトリ、つまり「富岳」のユーザーデータディレクトリ内のディレクトリ「${storage}/WPS+WRF_fj/WRF_multiple_nest_2way_2data/test/em_real」内のファイル「rsl.out.0000」に格納されているので、その最終行が「wrf: SUCCESS COMPLETE WRF」となっていることを確認してください。また、同ディレクトリ内に、ファイル「wrfout_d01_2016-10-06_00:00:00」及び「wrfout_d02_2016-10-06_00:00:00」が作成されていることを確認してください。
   ```
   $ tail rsl.out.0000
   Timing for main: time 2016-10-07_23:56:40 on domain   2:    0.04880 elapsed seconds
   Timing for main: time 2016-10-07_23:57:30 on domain   2:    0.04888 elapsed seconds
   Timing for main: time 2016-10-07_23:57:30 on domain   1:    0.27610 elapsed seconds
   Timing for main: time 2016-10-07_23:58:20 on domain   2:    0.04908 elapsed seconds
   Timing for main: time 2016-10-07_23:59:10 on domain   2:    0.04889 elapsed seconds
   Timing for main: time 2016-10-08_00:00:00 on domain   2:    0.05669 elapsed seconds
   Timing for Writing wrfout_d02_2016-10-08_00:00:00 for domain        2:    0.05031 elapsed seconds
   Timing for main: time 2016-10-08_00:00:00 on domain   1:    0.33755 elapsed seconds
   Timing for Writing wrfout_d01_2016-10-08_00:00:00 for domain        1:    0.09863 elapsed seconds
   wrf: SUCCESS COMPLETE WRF
   $ ls wrfout_*
   wrfout_d01_2016-10-06_00:00:00  wrfout_d02_2016-10-06_00:00:00
   $
   ```

以上
