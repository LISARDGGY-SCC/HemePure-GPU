#!/bin/sh

set -e

PREPARE(){
	if [ -z "$1" ]
	then
		INSTALL_PATH="$(pwd)"/toolchain
	else
		INSTALL_PATH="$1"
	fi

	if [ -z "$2" ]
	then
		VERSION="3.29.9"
	else
		VERSION="$2"
	fi

	if [ -z "$3" ]
	then
		SYSTEM="linux-x86_64"
	else
		SYSTEM="$3"
	fi

	if [ ! -d "${INSTALL_PATH}/cmake-${VERSION}-${SYSTEM}" ]
	then

		if [ ! -f /tmp/cmake.sh ]
		then
			curl -o /tmp/cmake.sh "https://cmake.org/files/v3.29/cmake-${VERSION}-${SYSTEM}.sh"
		fi

		sh /tmp/cmake.sh --prefix="$INSTALL_PATH" --include-subdir --skip-license
	fi

	PATH="${INSTALL_PATH}/cmake-${VERSION}-${SYSTEM}/bin"${PATH:+:"$PATH"}

	echo '#!/bin/sh' > env.sh

	cat >> env.sh <<- EOF
	PATH="${INSTALL_PATH}/cmake-${VERSION}-${SYSTEM}/bin"\${PATH:+:"\$PATH"}
	export PATH
	EOF

	export PATH
}

PREPARE $@
