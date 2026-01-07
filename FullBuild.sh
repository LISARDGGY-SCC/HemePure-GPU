#!/bin/sh

set -e

usage(){
	printf "%s [VARIENT | --help]\n" "$1"
	printf "VARIENT:\n"
	printf "\tPP:\t\tPressure-Pressure BCs\n"
	printf "\tVP:\t\tVelocity-Pressure BCs\n"
	printf "\tany other:\t\tthe default\n"
}

MODULES(){
	if module avail > /dev/null 2> /dev/null
	then
		module purge

		# TWCC
		module load nvhpc-24.11_hpcx-2.20_cuda-12.6

	else
		echo "No modules, skipping loading"
	fi

	export CC=mpicc
	export CXX=mpicxx
}

DEPbuild(){
	echo ""
	echo "Start building dependencies..."
	echo ""

	cmake -B dep/build dep --fresh
	cmake --build dep/build -j
}

SRCbuild(){

	VARIENT="$1"

	echo ""
	printf "Start building src with varient '%s'\n" "$VARIENT"
	echo ""

	case "$VARIENT"
	in
		"PP")
		OPTION="$(cat <<- EOF
			-DHEMELB_USE_VELOCITY_WEIGHTS_FILE=OFF
			-DHEMELB_INLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET
			-DHEMELB_WALL_INLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB
			-DHEMELB_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET
			-DHEMELB_WALL_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB
			EOF
		)"
		;;
		"VP")
		OPTION="$(cat <<- EOF
			-DHEMELB_USE_VELOCITY_WEIGHTS_FILE=ON 
			-DHEMELB_INLET_BOUNDARY=LADDIOLET 
			-DHEMELB_WALL_INLET_BOUNDARY=LADDIOLETSBB 
			-DHEMELB_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET 
			-DHEMELB_WALL_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB 
			EOF
		)"
		;;
		*)
		OPTION=""
		;;
	esac

	cmake -B src/build src \
		--install-prefix="$(pwd)/hemelabgpu${VARIENT:+-$VARIENT}" \
		--fresh \
		-DHEMELB_GPU_BACKEND=CUDA \
		-DCMAKE_CUDA_ARCHITECTURES=70 \
		"$OPTION"
	cmake --build src/build -j
	cmake --install src/build
}

if [ "$1" = "--help" ]
then
	usage "$0"
fi

MODULES
DEPbuild
SRCbuild "$1"
