#!/bin/bash

# TODO: Use your own directory where the patches are located
PATCH_DIR="${HOME}/ichpc-build-additional"

################################################################################
### THIS SHOULD BE IN EVERY PBS SCRIPT
################################################################################
# TODO: Use your own directory where fluidity is located
FLUIDITY_DIR="${HOME}/fluidity"

# TODO: Remember to set FI_PROVIDER=tcp otherwise Intel MPI complains
export FI_PROVIDER=tcp
# TODO: Remember to add this to your PYTHONPATH for testharness to work
export PYTHONPATH="${FLUIDITY_DIR}/python":${PYTHONPATH}

export PATH="${FLUIDITY_DIR}/bin":${PATH}

# Load modules for build
module load ese-software
module load ese-fluidity-dev # ese-fluidity-dev/20200227-python3-cmake317
################################################################################

FLUIDITY_GIT_URL=https://github.com/fluidityproject/fluidity.git
FLUIDITY_VERSION="VTK9-fixes"

# Clone fluidity from GitHub if not already present
if [ ! -d ${FLUIDITY_DIR} ]; then
  git clone ${FLUIDITY_GIT_URL} ${FLUIDITY_DIR}
fi

# Checkout the branch with the VTK9 fixes
pushd ${FLUIDITY_DIR}
git pull
git checkout ${FLUIDITY_VERSION}
git reset --hard ${FLUIDITY_VERSION}

#### CHANGE THE PATCH LOCATION TO YOUR PATCH DIRECTORY
# Local changes against Fluidity master at VTK9-fixes
patch -p0 <${PATCH_DIR}/vtk9-meshio.patch
patch -p0 <${PATCH_DIR}/use-local-netcdf.patch
patch -p0 <${PATCH_DIR}/vtk-add-libs.patch
patch -p0 <${PATCH_DIR}/vtk-add-tools-libs.patch
patch -p0 <${PATCH_DIR}/vtk-add-fldecomp-libs.patch

# Regenerate configure after local changes
autoconf
pushd libadaptivity
autoconf
popd

# A bit of prep
libtoolize

# Configure
export LIBS="${LIBS} -L${PETSC_DIR}/lib -lblas -llapack"

${FLUIDITY_DIR}/configure --enable-2d-adaptivity

# Build
make all -j 8
popd
