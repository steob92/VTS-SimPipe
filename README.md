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

- [CORSIKA](https://web.ikp.kit.edu/corsika/) (tested with version 7.7500) for air shower and Cherenkov photon generation
- [corsikaIOreader](https://github.com/GernotMaier/corsikaIOreader/) for file format conversion and Cherenkov photon absorption and scattering.
- [GrOptics](https://github.com/groptics/GrOptics/tree/master) (version **NN**) for the optical ray tracing.
- [CARE](https://github.com/nepomukotte/CARE) (version **NN**) for the camera simulation.
- [VBF](https://github.com/VERITAS-Observatory/VBF) (version **NN**) for the VBF file format (internal software of the VERITAS collaboration).
- [ROOT](https://root.cern.ch/) (version **NN**) used by GrOptics and CARE.
- [Eventdisplay](https://github.com/VERITAS-Observatory/EventDisplay_v4) (version **NN**) to merge several VBF files.

## Installation

### CORSIKA containers

Requires the tar package with the CORSIKA tar software to be available in the main directory of `VTSSimPipe`.

To build the CORSIKA container:

```bash
docker build -f ./docker/Dockerfile-corsika -t vts-simpipe-corsika .
```

For testing, run the container with:

```bash
docker run --rm -it -v "$(pwd):/workdir/external" vts-simpipe-corsika bash
```

The CORSIKA configuration is generated "by hand" using the `coconut` tools with the following settings:

```text
options:   VOLUMEDET TIMEAUTO URQMD QGSJETII
selection: BERNLOHRDIR SLANT CERENKOV IACT IACTDIR ATMEXT
```

The file [docker/corsika-config.h](docker/corsika-config.h) contains the configuration file for CORSIKA and is used for the compilation.

## Environmental Variables

Environmental variables are used to configure the simulation pipelines, especially output directories and executables.
Copy the file [env_setup_template.sh](env_setup_template.sh) to `env_setup.sh` and modify the variables for your local needs.

Directories:

- `VTSSIMPIPE_LOG_DIR`: directory for log files, run scripts, and job submission files
- `VTSSIMPIPE_DATA_DIR`: directory for simulation output files

## CORSIKA air-shower simulations

The CORSIKA air-shower simulations require as environmental variables:

- `VTSSIMPIPE_IMAGE` pointing to the Docker image to be used for the simulations
- `VTSSIMPIPE_CORSIKA_EXE` describes the type of container platform (docker or apptainer) or points directly to the CORSIKA executable (in cases no containers are used)

The script to run the CORSIKA simulations is [scripts/run_corsika.sh](scripts/run_corsika.sh), configuration parameters are
defined as in the template [config/CORSIKA/config_template.dat](config/CORSIKA/config_template.dat).
Note that no changes are expected to be necessary for the input steering template [config/CORISKA/input_template.dat](config/CORISKA/input_template.dat).

The configuration script [scripts/config_corsika.sh](scripts/config_corsika.sh) takes into account the zenith-angle dependent changes of energy thresholds and core scatter areas. It is recommended to cross check these values.

Usage of CORSIKA run script:

```bash
./prepare_production_corsika.sh ../config/CORSIKA/config_template.dat ../config/CORSIKA/input_template.dat TRUE
```

The last parameter indicates to pull the container image from the registry.
For using `apptainers`, the tables required by the interaction models are copied in this step also to the `VTSSIMPIPE_CORSIKA_DIR` (as apptainers wrie not writeable and QGSJet requires write access to the tables).

## Simulation Configuration

## Processing Scripts

Processing scripts are prepared for HT Condor systems.

- run scripts like [scripts/run_corsika.sh](scripts/run_corsika.sh) prepare the job submission (see `*.condor` files in the `VTSSIMPIPE_LOG_DIR` directory).
- job submission for the HT Condor system is done with [scripts/submit_jobs_to_htcondor.sh](scripts/submit_jobs_to_htcondor.sh).

## Using Apptainers

[Apptainer](https://apptainer.org/) is a container platform often used on HPC systems (e.g., on the DESY computing cluster).
The simulation scripts are configured to use Apptainers with the correct parameters.

Note:

- recommend to set `$APPTAINER_CACHEDIR` to a reasonable directory with sufficient disk space, as cluster jobs will use this directory to store the container images.
