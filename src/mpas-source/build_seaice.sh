#!/bin/bash


ml load mpi/openmpi-x86_64 e3sm

make USE_PIO2=true CORE=seaice gfortran
