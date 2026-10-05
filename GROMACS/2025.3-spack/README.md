# GROMACS 2025.3 のローカルインストール手順（A64FX / Fujitsu Compiler 4.12.2）

## 概要

本手順書では、A64FX 環境において Fujitsu Compiler 4.12.2 を用い、Spack から GROMACS 2025.3 をローカルインストールする方法を示す。本手順でビルドした GROMACS では、MPI 版の実行ファイル `gmx_mpi` だけでなく、前処理や解析で使用する `gmx` もインストールされる。

以下について記載する。

- Spack ローカル設定
- Fujitsu MPI / SSL2 の設定
- GROMACS 2025.3 のビルド方法
- 回帰テストの実施
- 遭遇した問題と回避方法

なお、翻訳は計算ノードで行った。

pjsub --interact --sparam wait-time=600 --rsc-list "elapse=1:0:0,node=1" --mpi "proc=2"

最後に公式サイトより提供されているRegression Testsを実行し、 翻訳したモジュールの妥当性を検証します。2MPIプロセスを用いた例を示す。

記載内容は検証時点の環境に依存しており、 Spack やコンパイラの更新により変更が必要になる場合がある。

---

# 環境

## ソフトウェア

- GROMACS 2025.3
- Spack v1.0.1
- Fujitsu Compiler 4.12.2
- Fujitsu MPI 4.12.2
- Fujitsu SSL2
- RIST FFTW

## ハードウェア

- Fujitsu A64FX

---

# ビルド前の準備

## Spack環境の初期化

以下のコマンドを実行する。

```bash
. /vol0004/apps/oss/spack-v1.0.1/share/spack/setup-env.sh
```

## Spack ローカル設定

本手順ではユーザー設定ディレクトリとして

```bash
export SPACK_USER_CONFIG_PATH=$HOME/.spack.dev
```

を使用した。

設定ファイル構成:

```text
~/.spack.dev/
├── concretizer.yaml
├── config.yaml
├── modules.yaml
└── packages.yaml
```

---

### concretizer.yaml

```yaml
concretizer:
  reuse: false
```

#### 設定理由

既存のインストール済みパッケージを再利用せず、
毎回新たに依存関係を解決させるため。

本作業では Fujitsu MPI 4.12.2 および Fujitsu SSL2 4.12.2 の
external 定義を追加しており、過去の concretization 結果を
引き継がないことが重要であった。

設定確認:

```bash
spack config get concretizer
```

---

### config.yaml

以下は設定例。

```yaml
config:
  install_tree:
    root: /your/install/path/spack
  source_cache: ~/.spack/source_cache
  misc_cache: ~/.spack/cache
```

#### install_tree

```yaml
install_tree:
  root: /your/install/path/spack
```

インストール先を指定する。

今回指定したディレクトリ名

```text
/your/install/path/spack
```

は適宜変更のこと。

#### source_cache

```yaml
source_cache: ~/.spack/source_cache
```

ダウンロード済みソースコードの保存場所。

同一ソースを再利用する際の再ダウンロードを防ぐ。

#### misc_cache

```yaml
misc_cache: ~/.spack/cache
```

Spack が利用するキャッシュ領域。

設定確認:

```bash
spack config get config
```

---

### modules.yaml

```yaml
modules:
  default:
    enable: []
    roots:
      tcl: ~/.spack/modules
```

#### 設定理由

本手順では環境モジュールを利用しなかったため、

```yaml
enable: []
```

としてモジュール生成を無効化した。

また、将来的に Tcl module を生成する場合に備え、

```yaml
roots:
  tcl: ~/.spack/modules
```

を設定した。

#### 確認方法

```bash
spack config get modules
```

#### 備考

モジュールを利用する場合は、環境に応じて以下のように変更する。

```yaml
modules:
  default:
    enable:
    - tcl
```

生成場所の確認:

```bash
spack module tcl refresh
```

```bash
ls ~/.spack/modules
```

---

### packages.yaml

今回使用した設定は以下の通りである。

```yaml
packages:
  node-js:
    require:: []
  all:
    providers:
      blas: [fujitsu-ssl2]
      lapack: [fujitsu-ssl2]

  fujitsu-mpi:
    buildable: false
    externals:
    - spec: fujitsu-mpi@4.12.2 arch=linux-rhel8-a64fx %fj@4.12.2
      prefix: /opt/FJSVxtclanga/tcsds-mpi-1.2.43

  fujitsu-ssl2:
    buildable: false
    externals:
    - spec: fujitsu-ssl2@4.12.2 arch=linux-rhel8-a64fx %fj@4.12.2
      prefix: /opt/FJSVxtclanga/tcsds-ssl2-1.2.43
```

#### 設定理由

##### BLAS/LAPACK provider の固定

```yaml
providers:
  blas: [fujitsu-ssl2]
  lapack: [fujitsu-ssl2]
```

を指定することで、BLAS/LAPACK ライブラリとして
Fujitsu SSL2 を優先的に利用する。

##### Fujitsu MPI 4.12.2 の external 定義

```yaml
fujitsu-mpi@4.12.2
```

を external package として登録することで、
Spack がシステム導入済みの Fujitsu MPI を利用できるようにする。

##### Fujitsu SSL2 4.12.2 の external 定義

```yaml
fujitsu-ssl2@4.12.2
```

を external package として登録することで、
Spack がシステム導入済みの Fujitsu SSL2 を利用できるようにする。

#### 発生した問題

当初、

```bash
spack spec ...
```

を実行すると、

```text
^atlas
```

が BLAS/LAPACK provider として選択されることがあった。

原因は、`packages.yaml` に

```yaml
fujitsu-ssl2@4.12.2
```

の external 定義が存在しなかったためである。

上記設定を追加後、

```bash
spack spec ...
```

から

```text
^atlas
```

が消え、

```text
^fujitsu-ssl2
```

が選択されるようになった。

また、mpi を external 指定した結果、依存関係の解決結果が変化した。

```yaml
fujitsu-mpi@4.12.2
```

MPI の external 指定とBLAS/LAPACK provider の選択は独立した設定である。

設定ファイルの適用：

当リポジトリ配下に格納されたyaml fileをコピーして利用。以下は実施例。

```bash
export REPO_DIR=/path/to/Install-Open-Source-Packages-on-Fugaku       # REPO_DIR: 本リポジトリをクローンしたディレクトリ

mkdir -p $SPACK_USER_CONFIG_PATH
cp $REPO_DIR/GROMACS/2025.3-spack/concretizer.yaml $SPACK_USER_CONFIG_PATH/
cp $REPO_DIR/GROMACS/2025.3-spack/config.yaml $SPACK_USER_CONFIG_PATH/
cp $REPO_DIR/GROMACS/2025.3-spack/modules.yaml $SPACK_USER_CONFIG_PATH/
cp $REPO_DIR/GROMACS/2025.3-spack/packages.yaml $SPACK_USER_CONFIG_PATH/
```
---

指定したディレクトリ名

```text
/path/to/
```

は適宜設定すること。

## Fujitsu Compiler の確認

本手順では Fujitsu Compiler 4.12.2 (`fj@4.12.2`) を使用する。

本検証環境では user-level の compilers.yaml は使用していない。
Fujitsu Compiler は site configuration により Spack から認識されている。

まず、ビルド開始前に、Spack から Fujitsu Compiler が認識されていることを確認すること。

```bash
spack compiler list
```

以下のように fj@4.12.2 が表示されれば利用可能。

```text
==> Available compilers

-- fj rhel8-aarch64 ---------------------------------------------
[e] fj@4.12.2
```

fj@4.12.2 が表示されない場合は、コンパイラを検出する。

```bash
module load fj
spack compiler find
```

再度確認する。

```bash
spack compiler list
```

本資料のビルド手順は、fj@4.12.2 が Spack から利用可能であることを前提としている。

## Spec確認

インストール前に依存関係を確認する。

```bash
spack spec \
gromacs@2025.3+sve+fast+cycle_subcounters \
fft-kernel=/vol0004/share/rist/gromacs/fft-kernel/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp \
simd-kernels=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp \
pmswp=3 \
vl=512 \
%fj@4.12.2 \
^fujitsu-mpi \
^fujitsu-ssl2 \
^rist-fftw
```

確認ポイント:

```text
^atlas
```

が含まれていないこと。

以下が選択されること。

```text
^fujitsu-mpi@4.12.2
^fujitsu-ssl2
^rist-fftw
```

---

# ビルド

## GROMACSソースコードの準備

開発中のソースコードを `spack dev-build` で利用するため、あらかじめソースコードを取得します。

GROMACS 2025.3 をダウンロードします。

```bash
cd ~

wget https://ftp.gromacs.org/gromacs/gromacs-2025.3.tar.gz
```

展開します。

```bash
tar xzf gromacs-2025.3.tar.gz
```

展開後、以下のディレクトリが存在することを確認してください。

```bash
ls ~/gromacs-2025.3
```

以降の `spack dev-build` では、このソースツリーを使用します。

```bash
spack dev-build -d ~/gromacs-2025.3 \
gromacs@2025.3+sve+fast+cycle_subcounters \
fft-kernel=/vol0004/share/rist/gromacs/fft-kernel/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp \
simd-kernels=/vol0004/share/rist/gromacs/simd-kernels/arm-24.04/i7v2hss6t2zolyfqnu7beysdptimh5bp \
pmswp=3 \
vl=512 \
%fj@4.12.2 \
^fujitsu-mpi \
^fujitsu-ssl2 \
^rist-fftw
```
## dev-build を使用する理由

本手順では

```bash
spack install <dev-build と同じ spec>
```

ではなく

```bash
spack dev-build
```

を使用する。

理由は、利用者がソースコードを直接編集・改造した GROMACS を
ビルドできるようにするためである。

例えば以下のような用途を想定している。

- GROMACS ソースコードへの独自修正
- 性能改善パッチの適用
- 新規機能の試験実装
- CMake オプションの調査
- ベンチマーク評価

本手順ではソースツリー

```text
~/gromacs-2025.3
```

をそのまま利用し、

```bash
spack dev-build -d ~/gromacs-2025.3 ...
```

によってビルドを行う。

このため、利用者は GROMACS ソースコードを変更した状態のまま
Spack を利用してビルドおよび依存関係管理を行うことができる。

改造を行わない場合は、

```bash
spack install <dev-build と同じ spec>
```

を使用してもよい。GROMACSのサイトからソースコードが自動的にダウンロードされる。

---

# ロード

以下のコマンドでインストール済みの GROMACS をロードする。

```bash
spack load /SPEC_HASH
```

SPEC_HASH は実際の Spec Hash に置き換えること。
利用可能な Hash は以下で確認できる。

```bash
spack find -lv gromacs
```

## インストールされる実行ファイル
 
本手順でビルドした GROMACS では、MPI 版の実行ファイル `gmx_mpi` だけでなく、
前処理や解析で使用する `gmx` もインストールされる。

確認:

```bash
which gmx
which gmx_mpi
```

```bash
gmx --version
gmx_mpi --version
```

gmxtest では、mdrun は gmx_mpi を使用し、 それ以外のコマンドは gmx を使用する。

---

# FFTW確認

リンクされている FFTW を確認する。

```bash
ldd $(which gmx_mpi) | grep fftw
```

期待例:

```text
libfftw3f.so.3 => /vol0004/share/rist/fftw/arm-24.10/...
```

---

# 回帰テスト

入手先URL
- 【テストデータ】https://ftp.gromacs.org/regressiontests/

任意のディレクトリで、入手先urlからダウンロードしたファイルを展開する。（ダウンロードするファイル:regressiontests-2025.3.tar.gz）

```bash
$ tar xzf regressiontests-2025.3.tar.gz
```

解凍したファイルはregressiontests-2025.3ディレクトリに展開される。 

```bash
$ cd regressiontests-2025.3
```

パッチの適用：

当リポジトリ配下に格納されたpatch fileをコピーして利用。

```bash
cp $REPO_DIR/GROMACS/2025.3-spack/gmxtest.patch .
patch -p1 < gmxtest.patch
```

パッチの内容は同梱のgmxtest.patchを参照のこと。

実施条件:

```text
Node数                 : 1
MPI Rank数             : 2
OpenMP Thread数/Rank   : 24
総スレッド数            : 48
```

対話実行(Interactive Session)で実施した。

実行例:

```bash
export KMP_AFFINITY=compact,verbose
./gmxtest.pl -np 2 -mpirun mpiexec -nosuffix -relaxed -crosscompile all > log.test
```

結果:

```text
grep All log.test 
All 48 complex tests PASSED
All 0 extra tests PASSED
All 7 essential dynamics tests PASSED
```

を確認する。

---

# インストール確認

インストール済みパッケージ一覧:

```bash
spack find
```

ロード済みパッケージ:

```bash
spack find --loaded
```

インストール場所確認:

```bash
spack location -i /SPEC_HASH
```

SPEC_HASH は実際の Spec Hash に置き換えること。
利用可能な Hash は以下で確認できる。

```bash
spack find -lv
```

Spec確認:

```bash
spack spec /SPEC_HASH
```

SPEC_HASH は実際の Spec Hash に置き換えること。
利用可能な Hash は以下で確認できる。

```bash
spack find -lv
```

---

# トラブルシューティング

## Atlas が混入する

確認:

```bash
spack spec ...
```

に

```text
^atlas
```

が含まれていないか確認する。

含まれている場合は、`fujitsu-ssl2@4.12.2` の external 定義と
`providers.blas` / `providers.lapack` の設定を確認する。

---

## 誤ったバージョンがロードされる

確認:

```bash
which gmx_mpi
```

ロード解除:

```bash
spack unload --all
```

再ロード:

```bash
spack load /SPEC_HASH
```

SPEC_HASH は実際の Spec Hash に置き換えること。
利用可能な Hash は以下で確認できる。

```bash
spack find -lv
```

---

# まとめ

GROMACS 2025.3 を Fujitsu Compiler 4.12.2 でローカルビルドする場合、

- `SPACK_USER_CONFIG_PATH` を利用したローカル設定
- Fujitsu MPI 4.12.2 の external 定義
- Fujitsu SSL2 4.12.2 の external 定義
- `concretizer.reuse: false`

が重要である。

特に `packages.yaml` に Fujitsu MPI / SSL2 の 4.12.2 定義が存在しない場合、
BLAS/LAPACK として Atlas が選択される可能性があるため注意が必要である。