#!/usr/bin/env python

from testing_utils import *


nprocs = 4

nmlChanges = {"seaice_model": {"config_run_duration":'24:00:00'}}

streamChanges = [{"streamName":"restart", "attributeName":"output_interval", "newValue":"24:00:00"}, \
                 {"streamName":"output" , "attributeName":"output_interval", "newValue":"none"}]

logfile = open("mylog.log", "w")

run_model(
    "test01",
    "/billevans/projects/E3SM_MODIFIY/E3SM-sicn/src/mpas-source",
    "/billevans/projects/E3SM_MODIFIY/E3SM-sicn/src/mpas-source/testing_and_setup/seaice/testing/testhere/inputdata",
    "domain_QU240km",
    "standard_physics",
    nmlChanges,
    streamChanges,
    nprocs,
    logfile,
)

logfile.close()
