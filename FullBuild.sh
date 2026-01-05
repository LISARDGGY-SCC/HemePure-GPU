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

	cmake -B dep/build dep
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
		OPTION="\
			-DHEMELB_USE_VELOCITY_WEIGHTS_FILE=OFF \
			-DHEMELB_INLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET \
			-DHEMELB_WALL_INLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB \
			-DHEMELB_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET \
			-DHEMELB_WALL_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB \
		"
		;;
		"VP")
		OPTION="\
			-DHEMELB_USE_VELOCITY_WEIGHTS_FILE=ON \
			-DHEMELB_INLET_BOUNDARY=LADDIOLET \
			-DHEMELB_WALL_INLET_BOUNDARY=LADDIOLETSBB \
			-DHEMELB_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET \
			-DHEMELB_WALL_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB \
		"
		;;
		*)
		OPTION=""
		;;
	esac

	cmake -B src/build src \
		-DHEMELB_GPU_BACKEND=CUDA \
		"$OPTION"
	cmake --build src/build -j
}

if [ "$1" = "--help" ]
then
	usage "$0"
fi

MODULES
DEPbuild
SRCbuild "$1"
