#!/bin/bash
# LGSM install_ts3.sh function
# Author: Daniel Gibbs
# Website: http://gameservermanagers.com

info_distro.sh
# Gets the teamspeak server architecture
echo "Installing TS3"
if [ "${arch}" == "x86_64" ]; then
	ts3arch="amd64"
elif [ "${arch}" == "i386" ]||[ "${arch}" == "i686" ]; then
	ts3arch="x86"
else
	fn_printfailure "${arch} is an unsupported architecture"
	exit 1
fi


fn_download_file() {
	urls="${1}"
	defname="${lgsmdir}/$(basename "${urls}")"
	filename="${2:-$defname}"
	checksum="${3}"
	method="${4:-md5sum}"
	filedir="$(dirname "${filename}")"
	if [ ! -e "${filedir}" ]; then
		mkdir -p "${filedir}"
	fi
	# Add a string at the end so the loop runs one last time to check for the file.
	for url in $urls FAIL; do
		if [ "${checksum}" != "" ] && [ "$(${method} ${filename} 2>/dev/null | awk '{print $1}')" == "${checksum}" ]; then
			echo "${filename} OK (${method} ${checksum})"
			return 0
		fi
		if [ "${checksum}" == "" ] && [ -e "${filename}" ]; then
			echo "${filename} OK"
			return 0
		fi
		if [ "${url}" == "FAIL" ]; then
			echo "FAIL"
			return 1
		fi
		echo "Trying ${url}..."
		wget -N "${url}" -O "${filename}"
	done
}

# Get available download URLs
ts3_download_url="https://www.teamspeak.com/downloads"
unset latest_sha1

for item in $(wget "${ts3_download_url}" -q -O -|egrep -oi "([^\"]*teamspeak3-server_linux_${ts3arch}[^\"]*|SHA1: [a-zA-Z0-9]*)" | sed -e 's/SHA1: //g' | grep -B1 "${ts3arch}"); do
	if [ -z "${latest_sha1}" ]; then
		latest_sha1="${item}"
	else
		if [ -z "${latest_file}" ]; then
			latest_file="$(echo $item | sed -e 's/^.*\///g')"
			latest_version="$(echo $item | sed -e 's/^.*\-//g' -e 's/.tar.*$//g')"
		fi
		server_download_urls="$(echo "${server_download_urls} ${item}")"
	fi
done

# Checks latest_version info is available
if [ -z "${latest_version}" ]; then
	fn_printfail "teamspeak.com: Not returning version info"
	sleep 2
	exit 1
fi

installer_path="${lgsmdir}/${latest_file}"
fn_download_file "${server_download_urls}" "${installer_path}" "${latest_sha1}" "sha1sum"
local status=$?
if [ ${status} -eq 0 ]; then
	echo "File successfully fetched"
else
	echo "FAIL - Exit status ${status}"
	sleep 1
	exit $?
fi

echo -e "extracting ${latest_file}...\c"
tar -xf "${latest_file}" -C "${filesdir}" --strip 1 2> ".${servicename}-tar-error.tmp"

local status=$?
if [ ${status} -eq 0 ]; then
	echo "OK"
else
	echo "FAIL - Exit status ${status}"
	sleep 1
	cat ".${servicename}-tar-error.tmp"
	rm ".${servicename}-tar-error.tmp"
	exit $?
fi

return

echo -e "copying to ${filesdir}...\c"
cp -R "${lgsmdir}/teamspeak3-server_linux-${ts3arch}/"* "${filesdir}" 2> ".${servicename}-cp-error.tmp"

local status=$?
if [ ${status} -eq 0 ]; then
	echo "OK"
else
	echo "FAIL - Exit status ${status}"
	sleep 1
	cat ".${servicename}-cp-error.tmp"
	rm ".${servicename}-cp-error.tmp"
	exit $?
fi

rm -f teamspeak3-server_linux-${ts3arch}-${latest_version}.tar.gz
rm -rf "${lgsmdir}/teamspeak3-server_linux-${ts3arch}"
