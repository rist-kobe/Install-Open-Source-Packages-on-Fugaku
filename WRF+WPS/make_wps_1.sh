#!/bin/bash
#
cd ${WRKDIR}
rm -rf netcdf-c-4.7.2
wget https://github.com/Unidata/netcdf-c/archive/v4.7.2.tar.gz
tar zxf v4.7.2.tar.gz
cd netcdf-c-4.7.2
./configure --prefix=${WPSLIBDIR}/netcdf --disable-dap --disable-netcdf-4 --disable-shared --build=arm
make
make install
cd ..
rm -rf netcdf-c-4.7.2
cd ..
#
cd ${WRKDIR}
rm -rf netcdf-fortran-4.5.2
wget https://github.com/Unidata/netcdf-fortran/archive/v4.5.2.tar.gz
tar zxf v4.5.2.tar.gz
cd netcdf-fortran-4.5.2
./configure --prefix=${WPSLIBDIR}/netcdf --disable-dap --disable-netcdf-4 --disable-shared --build=arm
make
make install
cd ..
rm -rf netcdf-fortran-4.5.2
cd ..
#
cd ${WRKDIR}
rm -rf zlib-1.2.11
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/zlib-1.2.11.tar.gz
tar zxf zlib-1.2.11.tar.gz
cd zlib-1.2.11
./configure --prefix=${WPSLIBDIR}/grib2 --static
make install
cd ..
rm -rf zlib-1.2.11
cd ..
#
cd ${WRKDIR}
rm -rf libpng-1.2.50
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/libpng-1.2.50.tar.gz
tar zxf libpng-1.2.50.tar.gz
cd libpng-1.2.50
./configure --prefix=${WPSLIBDIR}/grib2 --build=arm
make
make install
cd ..
rm -rf libpng-1.2.50
cd ..
#
cd ${WRKDIR}
rm -rf jasper-1.900.1
wget https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compile_tutorial/tar_files/jasper-1.900.1.tar.gz
tar zxf jasper-1.900.1.tar.gz
cd jasper-1.900.1
./configure --prefix=${WPSLIBDIR}/grib2 --build=arm
make
make install
cd ..
rm -rf jasper-1.900.1
rm -rf ._jasper-1.900.1
cd ..
#
