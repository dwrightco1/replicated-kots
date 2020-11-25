#!/bin/bash

basedir=~/replicated-cli
cli_version="0.33.4"
install_dir=/usr/local/bin

usage() {
	echo "Usage: $(basename $0) [-v <cli-version-tag> | -h|--help]"
	exit 1
}

assert() {
	if [ $# -eq 1 ]; then echo "${1}"; fi
	exit 1
}

# process commandline
while [ $# -gt 0 ]; do
	case ${1} in
	-v)
		if [ $# -lt 2 ]; then usage; fi
		cli_version=${2}
		shift ;;
	-h|--help)
		usage ;;
	*)
		usage ;;
	esac
	shift
done

# initialize path to CLI release
cli_pkg="https://github.com/replicatedhq/replicated/releases/download/v${cli_version}/replicated_${cli_version}_linux_amd64.tar.gz"
cli_archive=${basedir}/replicated_${cli_version}_linux_amd64.tar.gz

echo "[Installing Replicated CLI (Version: ${cli_version})]"
echo "--> creating installation directory: ${basedir}"
if [ ! -r ${basedir} ]; then
	mkdir ${basedir}
	if [ $? -ne 0 ]; then assert "ERROR: failed to create directory: ${basedir}"; fi
fi

echo "--> downloading to ${cli_archive}"
curl -s -L -o ${cli_archive} -O ${cli_pkg}

echo "--> extracting archive"
(cd ${basedir} && tar xf ${cli_archive})

echo "--> moving CLI binary to ${install_dir}"
sudo cp -f ${basedir}/replicated ${install_dir}
if [ $? -ne 0 ]; then assert "ERROR: failed to copy binary to ${install_dir}"; fi

# exit cleanly
exit 0
