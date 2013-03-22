#!/usr/bin/env bash

module purge
module load intel-cc/13.2.146
module load intel-fc/13.2.146
module load intel-mkl/13.2.146
module load netcdf/4.2.1.1
module load openmpi/1.6.3

build="exec_$(uname -m)"
mkdir -p $build/solo $build/shared

cd bin
icc -O2 -lnetcdf -o mppnccombine mppnccombine.c
cd ..

cd $build/shared
rm -rf path_names path_names.html
../../bin/list_paths ../../shared
mv path_names pt_orig
egrep -v "atmos_ocean_fluxes|coupler_types|coupler_util" pt_orig > path_names
../../bin/mkmf -t ../../templates/mkmf.template.vayu -p libfms.a \
    -c "-Duse_libMPI -Duse_netCDF" path_names
make -j libfms.a
cd ../..

cd $build/solo
ln -sf ../shared/*.{o,mod} .
rm -rf path_names path_names.html
../../bin/list_paths \
    ../../{config_src/{dynamic,solo_driver},src} \
    ../../shared
../../bin/mkmf -t ../../templates/mkmf.template.vayu -p GOLD \
    -c "-Duse_libMPI -Duse_netCDF" path_names
make -j
cd ../..
