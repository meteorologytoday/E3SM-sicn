#!/usr/bin/env python

import os, os.path, sys

#----------------------------------------------------------------

def create_sym_link(sourceDir, sourceFilename, destinationFilename):

    cmd = "ln -s %s/%s %s" %(sourceDir, sourceFilename, destinationFilename)
    #print cmd
    os.system(cmd)

#----------------------------------------------------------------

domainLocation = os.path.dirname(os.path.abspath(__file__))
    
# create directories
if (not os.path.isdir("graphs")):
    os.makedirs("graphs")

if (not os.path.isdir("forcing")):
    os.makedirs("forcing")

# read in manifest
manifestFilename = domainLocation + "/mpas_seaice_domain_manifest"
    
manifestFile = open(manifestFilename,"r")
manifestLines = manifestFile.readlines()
manifestFile.close()

# create sym links
for manifestLine in manifestLines:
        
    inputManifestLine  = manifestLine.split()[0]
    outputManifestLine = manifestLine.split()[1]

    create_sym_link(domainLocation, inputManifestLine, outputManifestLine)
