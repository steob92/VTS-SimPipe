# VERITAS Simulation Pipeline

This repository contains the simulation pipeline for [VERITAS](https://veritas.sao.arizona.edu/). This includes build scripts for the required simulation software and processing scripts.

This work is built on a large effort from many people, especially:

- the [CORSIKA](https://web.ikp.kit.edu/corsika/) team
- Charlie Duke for the [GrOptics](https://github.com/groptics/GrOptics/tree/master) package
- Nepomuk Otte for the [CARE](https://github.com/nepomukotte/CARE) package
- Raul Prado for an initial pipeline implementation for DESY (see [here](https://github.com/RaulRPrado/MC-DESY/tree/master))
- Tony Lin for a Docker implementation of the pipeline (see [here](https://github.com/VERITAS-Observatory/Build_SimDockerImage/tree/master))

Repository setup:

- `config`: configuration files for the simulation pipeline
- `docker`: Dockerfile for the simulation pipeline
- `scripts`: run scripts for the simulation pipeline (i.e. HT Condor submission scripts)

Further documentation on VERITAS simulations:

- [VERITAS Simulations (private wiki page)](https://veritas.sao.arizona.edu/wiki/index.php/Simulation)
- [VERITAS CARE (private wiki page)](https://veritas.sao.arizona.edu/wiki/index.php/CARE)

## Required Software

The simulation pipeline requires the following software to be installed:

- [CORSIKA](https://web.ikp.kit.edu/corsika/) (tested with version 7.6400) for air shower and Cherenkov photon generation
- [corsikaIOreader](https://github.com/GernotMaier/corsikaIOreader/) for file format conversion and Cherenkov photon absorption and scattering.
- [GrOptics](https://github.com/groptics/GrOptics/tree/master) (version **NN**) for the optical ray tracing.
- [CARE](https://github.com/nepomukotte/CARE) (version **NN**) for the camera simulation.
- [VBF](https://github.com/VERITAS-Observatory/VBF) (version **NN**) for the VBF file format (internal software of the VERITAS collaboration).
- [ROOT](https://root.cern.ch/) (version **NN**) used by GrOptics and CARE.
- [Eventdisplay](https://github.com/VERITAS-Observatory/EventDisplay_v4) (version **NN**) to merge several VBF files.

## Installation

### Build CORSIKA

Requires the CORSIKA tar package to be available in the `docker` directory.

To build the CORSIKA container:

```bash
cd docker
docker build -f Dockerfile-corsika -t vts-simpipe-corsika .
```

For testing, run the container with:

```bash
docker run --rm -it -v "$(pwd):/workdir/external" vts-simpipe-corsika bash
```

The CORSIKA configuration is generated using the `coconut` tools with the following settings:

```text
options:   VOLUMEDET TIMEAUTO URQMD QGSJETII
selection: BERNLOHRDIR SLANT CERENKOV IACT IACTDIR ATMEXT
```

The file [docker/corsika-config.h](docker/corsika-config.h) contains the configuration file for CORSIKA and is used for the compilation.

## Environmental Variables

Environmental variables are used to configure the simulation pipeline, especially output directories and executables.
Copy the file [env_setup_template.sh](env_setup_template.sh) to `env_setup.sh` and modify the variables as needed.

## CORSIKA air-shower simulations

The CORSIKA air-shower simulations are performed using the `VTSSIMPIPE_CORSIKA_EXE` executable defined in `env_setup.sh`.
The script to run the CORSIKA simulations is [scripts/run_corsika.sh](scripts/run_corsika.sh), configuration parameters are
defined as in the template [config/CORSIKA/config_template.dat](config/CORSIKA/config_template.dat).
Note that no changes are expected to be necessary for the input steering template [config/CORISKA/input_template.dat](config/CORISKA/input_template.dat).

## Simulation Configuration

## Processing Scripts

Processing scripts are prepared for HT Condor systems.

## Using Apptainers

- set $APPTAINER_CACHEDIR
- `apptainer pull --disable-cache --force docker://ghcr.io/gernotmaier/vtsimpipe-corsika:latest`
