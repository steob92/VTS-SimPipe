# VERITAS Simulation Pipeline

This repository contains the simulation pipeline for [VERITAS](https://veritas.sao.arizona.edu/). This includes build scripts for the required simulation software and processing scripts.

This work is built on a large effort from many people, especially:

- the [CORSIKA](https://web.ikp.kit.edu/corsika/) team
- Charly Duke for the [GrOptics](https://github.com/groptics/GrOptics/tree/master) package
- Nepomuk Otte for the [CARE](https://github.com/nepomukotte/CARE) package
- Raul Prado for an initial pipeline implementation for DESY (see [here](https://github.com/RaulRPrado/MC-DESY/tree/master))
- Tony Line for a Docker implementation of the pipeline (see [here](https://github.com/VERITAS-Observatory/Build_SimDockerImage/tree/master))

Further documentation:

- [VERITAS Simulations (private wiki page)](https://veritas.sao.arizona.edu/wiki/index.php/Simulation)
- [VERITAS CARE (private wiki page)](https://veritas.sao.arizona.edu/wiki/index.php/CARE)

## Required Software

The simulation pipeline requires the following software to be installed:

- [CORSIKA](https://web.ikp.kit.edu/corsika/) (tested with version 7.6400) for air shower and Cherenkov photon generation
- [corsikaIOreader](https://github.com/GernotMaier/corsikaIOreader/) for file format conversion and Cherenkov photon absorption and scattering.
- [GrOptics](https://github.com/groptics/GrOptics/tree/master) (version **NN**) for the optical ray tracing
- [CARE](https://github.com/nepomukotte/CARE) (version **NN**) for the camera simulation
- [VBF](https://github.com/VERITAS-Observatory/VBF) (version **NN**) for the VBF file format (internal software of the VERITAS collaboration)
- [ROOT](https://root.cern.ch/) (version **NN**) used by GrOptics and CARE

## Installation

## Simulation Configuration

## Processing Scripts

Processing scripts are prepared for HT Condor systems.
