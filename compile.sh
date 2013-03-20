#!/usr/bin/env bash

build="exec_$(uname -m)"
mkdir -p $build/solo $build/shared

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
