# VERITAS Simulation Pipeline

[![DOI](https://zenodo.org/badge/738007615.svg)](https://zenodo.org/doi/10.5281/zenodo.10541349)
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![build-images](https://github.com/GernotMaier/VTS-SimPipe/actions/workflows/build-images.yml/badge.svg)](https://github.com/GernotMaier/VTS-SimPipe/actions/workflows/build-images.yml)

This repository stores a copy of the simulation model for the atmospheric conditions, telescope structure, and camera and readout of VERITAS. 
A detailed documentation on the derivation of these parameters can be found on the VERITAS internal pages.
 
VERITAS simulation pages:

- [VERITAS Simulations (private wiki page)](https://veritas.sao.arizona.edu/wiki/index.php/Simulation)
- [VERITAS CARE (private wiki page)](https://veritas.sao.arizona.edu/wiki/index.php/CARE)

This work is built on a large effort from many people, especially:

- the [CORSIKA](https://web.ikp.kit.edu/corsika/) team
- Charlie Duke for the [GrOptics](https://github.com/groptics/GrOptics/tree/master) package
- Nepomuk Otte for the [CARE](https://github.com/nepomukotte/CARE) package
- Raul Prado for an initial pipeline implementation for DESY (see [here](https://github.com/RaulRPrado/MC-DESY/tree/master))
- Tony Lin for a Docker implementation of the pipeline (see [here](https://github.com/VERITAS-Observatory/Build_SimDockerImage/tree/master))

## Quick startup

The following is all what you need to know to install and run the simulation pipeline.
No compilation of any of the package is required.

```bash
# clone repository
git clone https://github.com/GernotMaier/VTS-SimPipe.git
cd VTS-SimPipe
# prepare log files and directories
cp env_setup_template.sh env_setup.sh
# edit env_setup.sh to your needs
# pull all container images from the registry
cd scripts && ./pull.sh
# prepare your configuration (e.g. zenith angle, number of events, etc.)
# see example in config/config_ATM61_template.dat
# prepare production
cd scripts
./prepare_all_production_steps.sh \
   ../config/config_ATM61_template.dat
   ../config/CORSIKA/input_template.dat
# on DESY: log into the DAG submission node
./prepare_DAG_jobs.sh ../config/config_ATM61_template.dat
./submit_DAG_jobs.sh <directory with DAG files> submit
# otherwise: submit jobs to HT Condor - for each step (CORSIKA, GROPTICS, CARE)
./submit_jobs_to_htcondor.sh <directory with condor files / submission scripts> submit
# now wait....for jobs to finish
# merge vbf files
./prepare_production.sh ../config/config_ATM61_template.dat
./submit_jobs_to_htcondor.sh <directory with condor files for mergeVBF> submit
# that's it
```

## Software packages

Following software packages are used by the simulation pipeline and installed in the docker images:

- [CORSIKA](https://web.ikp.kit.edu/corsika/) for air shower and Cherenkov photon generation
- [corsikaIOreader](https://github.com/GernotMaier/corsikaIOreader/) for file format conversion and Cherenkov photon absorption and scattering.
- [GrOptics](https://github.com/groptics/GrOptics/tree/master) for the optical ray tracing (uses [ROBAST](https://github.com/ROBAST/ROBAST)).
- [CARE](https://github.com/nepomukotte/CARE) for the camera simulation.
- [VBF](https://github.com/VERITAS-Observatory/VBF) for the VBF file format (internal software of the VERITAS collaboration).
- [ROOT](https://root.cern.ch/) used by GrOptics and CARE.
- [Eventdisplay](https://github.com/VERITAS-Observatory/EventDisplay_v4) to merge several VBF files.

For software versions, see the [docker files](docker/Dockerfile) and the [release notes](https://github.com/GernotMaier/VTS-SimPipe/releases).

## Installation

The simulation pipeline is configured to run in Docker/Apptainer containers.
Images can be downloaded from the package registry of this repository.

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

### GrOptics and corsikaIOreader containers

GrOptics requires C++11 for compilation, therefore the `root:6.24.06-centos7` is used as base image.

```bash
docker build -f ./docker/Dockerfile-groptics -t vts-simpipe-groptics .
docker run --rm -it -v "$(pwd):/workdir/external" vts-simpipe-groptics bash
```

Note that at this point a fork of GrOptics is used, fixing an issue to allow compiling on cent os7 (see [fork here](https://github.com/GernotMaier/GrOptics)).

### CARE containers

The same base image for CARE is used as for GrOptics, including VBF and ROOT.

```bash
docker build -f ./docker/Dockerfile-care -t vts-simpipe-care .
docker run --rm -it -v "$(pwd):/workdir/external" vts-simpipe-care bash
```

### mergeVBF containers

The tiny tool mergeVBF is actual part of the Eventdisplay software.
The same base image for mergeVBF is used as for CARE, including VBF and ROOT.
This container also includes an installation of [zstd](https://github.com/facebook/zstd), which is used to compress the VBF files.

```bash
docker build -f ./docker/Dockerfile-mergevbf -t vts-simpipe-mergevbf .
docker run --rm -it -v "$(pwd):/workdir/external" vts-simpipe-mergevbf bash
```

## Environmental Variables

Environmental variables are used to configure the simulation pipelines, especially output directories and executables.
Copy the file [env_setup_template.sh](env_setup_template.sh) to `env_setup.sh` and modify the variables for your local needs.

Directories:

- `VTSSIMPIPE_LOG_DIR`: directory for log files, run scripts, and job submission files
- `VTSSIMPIPE_DATA_DIR`: directory for simulation output files

## Configuration

### CORSIKA air-shower simulations

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
For using `apptainers`, the tables required by the interaction models are copied in this step also to the `VTSSIMPIPE_CORSIKA_DIR` (as apptainers containers are not writeable and QGSJet requires write access to the tables).

### corsikaIOreader for absorption and scattering

After the CORSIKA simulations, the Cherenkov photons are absorbed and scattered using the `corsikaIOreader` package.
The optical depth as function of altitude and wavelength is stored in files for summer and winter in [config/ATMOSPHERE](config/ATMOSPHERE).
For details on the derivation of these tables, see the [internal VERITAS wiki](https://veritas.sao.arizona.edu/wiki/Atmosphere) (plus pages linked from there).

### GrOptics optical ray tracing

see configuration files in [config/TELESCOPE_MODEL](config/TELESCOPE_MODEL).

### CARE camera simulation

see configuration files in [config/TELESCOPE_MODEL](config/TELESCOPE_MODEL).

## Processing Scripts

Processing scripts are prepared for HT Condor systems.

- prepare run scripts with [scripts/prepare_production.sh](scripts/prepare_production.sh) (see `*.sh` files in the `VTSSIMPIPE_LOG_DIR` directory).
- job submission for the HT Condor system is done with [scripts/submit_jobs_to_htcondor.sh](scripts/submit_jobs_to_htcondor.sh).
- DAG submission is done with [scripts/submit_DAG_jobs.sh](scripts/submit_DAG_jobs.sh).

Note that configuration and output directories are fine tuned for this setup.

## Using Apptainers

[Apptainer](https://apptainer.org/) is a container platform often used on HPC systems (e.g., on the DESY computing cluster).
The simulation scripts are configured to use Apptainers with the correct parameters.

Note:

- recommend to set `$APPTAINER_CACHEDIR` to a reasonable directory with sufficient disk space, as cluster jobs will use this directory to store the container images.

## Submitting jobs

The job submission scripts are written for HT Condor systems (as configured at DESY).
The `prepare_production.sh` product scripts generates the condor files and submission scripts in the `VTSSIMPIPE_LOG_DIR` directory.

To submit jobs, use the `submit_jobs_to_htcondor.sh` script:

```bash
./submit_jobs_to_htcondor.sh <directory with condor files / submission scripts> submit
````

This will submit all jobs in the directory to the HT Condor system.

For efficiency reason, it is recommended to submit jobs using the DAG submission system (see [HTCondor DAGMan](https://htcondor.readthedocs.io/en/latest/automated-workflows/index.html)). This allows to run CORSIKA, followed by GrOptics, CARE, and the merging of the VBF files in a single job submission.

To generate DAG files for the job submission:

```bash
./prepare_DAG_jobs.sh <config file>
```

This will generate the DAG files in the `VTSSIMPIPE_LOG_DIR/DAG` directory.

To submit DAG jobs:

```bash
./submit_DAG_jobs.sh <directory with DAG files> submit
```

Note that on DESY DAG jobs need to be submitted from a special node.
