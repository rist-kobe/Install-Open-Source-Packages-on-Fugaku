# GROMACS 2025.3 の「富岳」（A64FX）向けビルド手順

本リポジトリでは、スーパーコンピュータ「富岳」上で GROMACS 2025.3 をビルドした際の手順をまとめています。

GROMACS 2025.3 では SVE SIMD 検出まわりの変更により、Fujitsu コンパイラ環境でそのままビルドすると CMake 構成時にエラーとなる場合があります。

本手順では、外部生成された SIMD カーネルおよび FFT カーネルを利用することで、MPI 版および非 MPI 版の GROMACS 2025.3 のビルドと回帰テストの完了を確認しています。

プリ・ポスト用プログラム(gmx)とmd計算プログラム(gmx_mpi)を別々に作成しインストールします。

プリ・ポスト処理(gmx grompp等)はシリアル処理（MPI非並列）で行い、
md計算(gmx_mpi mdrun)はMPI並列で行うため、ビルドスクリプトを2例掲載しています。

なお、翻訳は計算ノードで行いました。

pjsub --interact --sparam wait-time=600 --rsc-list "elapse=1:0:0,node=1"

最後に公式サイトより提供されているRegression Testsを実行し、 翻訳したモジュールの妥当性を検証します。2ノードを用いた例を示します。

---

# ソフトウエア情報

ソフトウエア名
- GROMACS (GROningen MAchine for Chemical Simulations)

ソフトウエア概要
- 分子動力学シミュレーション

使用バージョン
- 2025.3

言語
- C++, MPI

入手先URL
- 【プログラム】https://ftp.gromacs.org/gromacs/
- 【テストデータ】https://ftp.gromacs.org/regressiontests/

ライセンス
- GNU LESSER GENERAL PUBLIC LICENSE Version 2.1

必要ライブラリ
- FFTW3,BLAS,LAPACK

---

# ファイルの入手方法

プログラム(gromacs-2025.3.tar.gz)
- wget https://ftp.gromacs.org/gromacs/gromacs-2025.3.tar.gz


テストデータ(regressiontests-2025.3.tar.gz)
- wget https://ftp.gromacs.org/regressiontests/regressiontests-2025.3.tar.gz

---

# 事前準備

必要なSpack パッケージをロードします。

```bash
. /vol0004/apps/oss/spack-v1.0.1/share/spack/setup-env.sh      # spack@1.0.1

spack load /gdqoius         # <fujitsu-mpi@4.12.1>
spack load /x3b4ojp         # <rist-fftw@3.3.9-272-g63d6bd70>
spack load /s422acq         # <cmake@3.31.8>
```

Fujitsu Clang モードを有効化します。

```bash
export fcc_ENV=-Nclang
export FCC_ENV=-Nclang
```

---

# 外部 SIMD カーネル

GROMACS 2025.3 では A64FX 環境において SIMD 検出が失敗する場合があります。

そのため、事前生成された SIMD カーネルを利用します。

例:

```text
/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/
```

ディレクトリ内:

- MPI 版

```text
libsimd_2xmm_mpi.a
libsimd_4xm_mpi.a
libsimd_nbnxm_mpi.a
```

- 非 MPI 版

```text
libsimd_2xmm.a
libsimd_4xm.a
libsimd_nbnxm.a
```

---

# 外部 FFT カーネル

FFT ライブラリについても外部生成物を使用します。

例:

```text
/vol0004/share/rist/gromacs/fft-kernel/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/
```

ディレクトリ内:

- MPI 版

```text
libfft_mpi.a
```

- 非 MPI 版

```text
libfft.a
```

---

# MPI 版 GROMACS のビルド

ファイルの展開と作業環境

- 任意のディレクトリで、入手先urlからダウンロードしたファイルを展開します。（ダウンロードするファイル:gromacs-2025.3.tar.gz）

```bash
$ tar xzf gromacs-2025.3.tar.gz
```

- 解凍したファイルはgromacs-2025.3ディレクトリに展開されます。 

```bash
$ cd gromacs-2025.3
```

パッチの適用

- 以下の CMake オプションを使用するため、RIST がチューニングしたパッチファイルを適用してください。
```bash
for patch in sve external-kernels pme_simd pme_spread tune_pme pmswp std_filesystem_equivalent essentialdynamics;
do patch -p1 < /vol0004/apps/oss/spack-v1.0.1/var/spack/fugaku-packages/repos/spack_repo/fugaku/rist/packages/gromacs/$patch-2025.patch;
done
```

## CMake

プログラムのインストール先"${PREFIX}"を適宜設定してください。

```bash
mkdir build
cd build

cmake .. \
 -DCMAKE_C_COMPILER=mpifcc \
 -DCMAKE_CXX_COMPILER=mpiFCC \
 -DCMAKE_INSTALL_PREFIX=$PREFIX \
 -DCMAKE_BUILD_TYPE=Release \
 -DGMX_MPI=ON \
 -DGMX_OPENMP=ON \
 -DGMX_HWLOC=ON \
 -DGMX_EXTERNAL_LAPACK=ON \
 -DGMX_LAPACK_USER=/opt/FJSVxtclanga/tcsds-ssl2-latest/lib64/libfjlapackexsve.so \
 -DGMX_EXTERNAL_BLAS=ON \
 -DGMX_BLAS_USER=/opt/FJSVxtclanga/tcsds-ssl2-latest/lib64/libfjlapackexsve.so \
 -DGMX_SIMD=ARM_SVE \
 -DGMX_SIMD_ARM_SVE_LENGTH=512 \
 -DGMX_USE_RDTSCP=OFF \
 -DGMX_CYCLE_SUBCOUNTERS=ON \
 -DGMX_2XMM_USER=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libsimd_2xmm_mpi.a \
 -DGMX_4XM_USER=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libsimd_4xm_mpi.a \
 -DGMX_NBNXM_USER=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libsimd_nbnxm_mpi.a \
 -DGMX_FFT_USER=/vol0004/share/rist/gromacs/fft-kernel/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libfft_mpi.a \
 -DGMX_2XMM_UNROLL_INNER=3 \
 -DGMX_4XM_UNROLL_INNER=3 \
 -DCMAKE_C_FLAGS_RELEASE='-Ofast -DNDEBUG' \
 -DCMAKE_CXX_FLAGS_RELEASE='-Ofast -DNDEBUG' \
 -DFFTWF_LIBRARY=/vol0004/share/rist/fftw/arm-24.10/3.3.9-272-g63d6bd70/lib/libfftw3f.so \
 -DFFTWF_INCLUDE_DIR=/vol0004/share/rist/fftw/arm-24.10/3.3.9-272-g63d6bd70/include
```

## ビルド

```bash
make -j 48
make install
```

インストール後、以下が生成されます。

```bash
gmx_mpi
```

---

# 非 MPI 版 GROMACS のビルド

## CMake

```bash
cd ..
mkdir build-nompi
cd build-nompi

cmake .. \
 -DCMAKE_C_COMPILER=fcc \
 -DCMAKE_CXX_COMPILER=FCC \
 -DCMAKE_INSTALL_PREFIX=$PREFIX \
 -DCMAKE_BUILD_TYPE=Release \
 -DGMX_MPI=OFF \
 -DGMX_OPENMP=ON \
 -DGMX_HWLOC=ON \
 -DGMX_EXTERNAL_LAPACK=ON \
 -DGMX_LAPACK_USER=/opt/FJSVxtclanga/tcsds-ssl2-latest/lib64/libfjlapackexsve.so \
 -DGMX_EXTERNAL_BLAS=ON \
 -DGMX_BLAS_USER=/opt/FJSVxtclanga/tcsds-ssl2-latest/lib64/libfjlapackexsve.so \
 -DGMX_SIMD=ARM_SVE \
 -DGMX_SIMD_ARM_SVE_LENGTH=512 \
 -DGMX_USE_RDTSCP=OFF \
 -DGMX_CYCLE_SUBCOUNTERS=ON \
 -DGMX_2XMM_USER=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libsimd_2xmm.a \
 -DGMX_4XM_USER=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libsimd_4xm.a \
 -DGMX_NBNXM_USER=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libsimd_nbnxm.a \
 -DGMX_FFT_USER=/vol0004/share/rist/gromacs/fft-kernel/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp/libfft.a \
 -DGMX_2XMM_UNROLL_INNER=3 \
 -DGMX_4XM_UNROLL_INNER=3 \
 -DCMAKE_C_FLAGS_RELEASE='-Ofast -DNDEBUG' \
 -DCMAKE_CXX_FLAGS_RELEASE='-Ofast -DNDEBUG' \
 -DFFTWF_LIBRARY=/vol0004/share/rist/fftw/arm-24.10/3.3.9-272-g63d6bd70/lib/libfftw3f.so \
 -DFFTWF_INCLUDE_DIR=/vol0004/share/rist/fftw/arm-24.10/3.3.9-272-g63d6bd70/include
```

## ビルド

```bash
make -j 48
make install
```

インストール後、

```bash
gmx
```

が利用可能になります。

---

# 回帰テスト

任意のディレクトリで、入手先urlからダウンロードしたファイルを展開します。（ダウンロードするファイル:regressiontests-2025.3.tar.gz）

```bash
$ tar xzf regressiontests-2025.3.tar.gz
```

解凍したファイルはregressiontests-2025.3ディレクトリに展開されます。 

```bash
$ cd regressiontests-2025.3
```

パッチの適用

- 当リポジトリ配下に格納されたpatch fileをコピーして利用可能です。

```bash
cp <repository>/GROMACS/2025.3/gmxtest.patch .
patch -p0 < gmxtest.patch
```

- 具体的な修正内容は以下の通りです。

```text
$ diff -ru gmxtest.pl.org gmxtest.pl
--- gmxtest.pl.org      2024-04-17 17:29:00.000000000 +0900
+++ gmxtest.pl  2024-04-19 18:28:25.000000000 +0900
@@ -68,6 +68,7 @@
 my $mpirun    = 'mpirun';
 my $parse_cmd = '';
 my $gmx_cmd   = "gmx";
+my $gmx_cmd2  = "gmx_mpi";
 my %progs = ( 'grompp'   => '',
               'mdrun'    => '',
               'pdb2gmx'  => '',
@@ -169,14 +170,20 @@
            $mdprefix = sub { "$mpirun -n $_[0]" };
        } else {
            # edit the next line if you need to customize the call to mpirun
-           $mdprefix = sub { "$mpirun -np $_[0] -wdir " . getcwd() };
+           $mdprefix = sub { "$mpirun -np $_[0]" };
        }
     }
     if ($autosuffix && ( $double > 0)) {
         $gmx_cmd .= "_d";
     }
     foreach my $prog ( keys %progs ) {
-        $progs{$prog} = "$gmx_cmd$suffix $prog";
+       #        $progs{$prog} = "$gmx_cmd$suffix $prog";
+       if ( $prog eq "mdrun" )
+       {
+           $progs{$prog} = "$gmx_cmd2$suffix $prog";
+       } else {
+           $progs{$prog} = "$gmx_cmd$suffix $prog";
+        }          
     }
     $ref = 'reference_' . ($double > 0 ? 'd' : 's');
```

GROMACS の環境設定を読み込みます。

```bash
. $PREFIX/bin/GMXRC
```

確認:

```bash
which gmx
gmx --version
```


その後、公式の regression test 手順に従ってテストを実行します。

```bash
./gmxtest.pl -np 2 -mpirun mpiexec -nosuffix -relaxed -crosscompile all > log.test
gmx --version
```

本手順では以下の出力が得られることを確認しました。

```text
$ grep All log.test 
All 48 complex tests PASSED
All 0 extra tests PASSED
All 7 essential dynamics tests PASSED
```

---

# トラブルシューティング

## CMake が SVE SIMD を検出できない

以下のようなエラーが発生する場合があります。

```text
Cannot find ARM (AArch64) SVE SIMD instructions
```

事前生成された外部 SIMD カーネルを指定することで回避できます。

```bash
-DGMX_2XMM_USER=<libsimd_2xmm.a>
-DGMX_4XM_USER=<libsimd_4xm.a>
```

---

## FFTW が見つからない

```text
Package 'fftw3f' not found
```

のようなエラーが発生した場合は、

```bash
-DFFTWF_INCLUDE_DIR=<include>
-DFFTWF_LIBRARY=<libfftw3f>
```

を明示的に指定します。

---

## Regression Test が gmx を見つけられない

```text
ERROR: Can not find executable gmx
```

非 MPI 版 GROMACS を別途ビルドして `gmx` を生成してください。

---

# 参考

本手順は「富岳」環境上での GROMACS 2025.3 のビルド成功例です。

実際のパスやハッシュ値は環境によって異なるため、適宜読み替えてください。

---

# 謝辞

GROMACS 開発者の皆様、および A64FX 向けビルド方法について情報を共有してくださった皆様に感謝いたします。

---

## 同梱ファイル

本ディレクトリには、ビルド手順書に加えて、ビルドおよびテストに必要な関連ファイルが含まれています。

| ファイル名 | 説明 |
|------------|------|
| README.md | 富岳上での GROMACS 2025.3 ビルド手順書 |
| gmxtest.patch | 回帰テスト実行時に必要なパッチ |
| LICENSE | ビルド手順と回帰テスト用パッチファイル のライセンス文書 |
