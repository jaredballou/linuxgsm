#!/bin/bash
# LGSM game_settings.sh function
# Author: Jared Ballou
# Website: http://gameservermanagers.com

function_selfname="$(basename $(readlink -f "${BASH_SOURCE[0]}"))"
local modulename="Settings"

# Config files
cfg_file_default="${scriptcfgdir}/_default.cfg"
cfg_file_common="${scriptcfgdir}/_common.cfg"
cfg_file_instance="${scriptcfgdir}/${servicename}.cfg"

# Config file headers
cfg_header_all="# Your settings for all servers go in _common.cfg\n# Server-specific settings go into \$SERVER.cfg"
cfg_header_default="# Default config - Changes will be overwritten by updates.\n${cfg_header_all}"
cfg_header_common="# Common config - Will not be overwritten by script.\n${cfg_header_all}"
cfg_header_instance="# Instance Config for ${servicename} - Will not be overwritten by script.\n${cfg_header_all}"

# Settings file created from gamedata
settings_file="${settingsdir}/settings"

# Get the MD5 hash of a file
fn_get_md5sum() {
	md5sum "${1}" 2>/dev/null| awk '{print $1}'
}

# Load a gamedata file, and read the, all to find the hierarchy of includes. Print those with their checksums
fn_get_import_tree() {
	for incfile in $(sed -e 's/#.*//' -e 's/[ ^I]*$//' -e '/^$/ d' "${gamedatadir}/${1}" | grep '^[ \t]*fn_import_game_settings' | awk '{print $2}'); do
		echo "$incfile:$(md5sum "${gamedatadir}/${1}" | awk '{print $1}')"
		fn_get_import_tree $incfile
	done
}

# Merge files together in hierarchial order. Skips all lines that aren't key/value pairs
fn_merge_config_files() {
	gawk -F'=' 'NF>1{if (!a[$1]){seen[length(seen)+1]=$1;} a[$1] = $0}END{for (i=1;i<=length(seen);i++) {print a[seen[i]]}}' $@
}

# Create merged config for this instance
fn_create_merged_config() {
	merged_cfg="${settingsdir}/${servicename}.config"
	fn_merge_config_files "${cfg_file_default}" "${cfg_file_common}" "${cfg_file_instance}" > "${merged_cfg}"
	source "${merged_cfg}"
}

# If default config does not exist, create it. This should come from Git, and will be overwritten by updates.
# Rather than try to wget it from Github or other fancy ways to get it, the simplest way to ensure it works is to simply create it here.
fn_update_config()
{
	key=$1
	val=$2
	cfg_file=${3:-$cfg_file_default}
	comment=${4:-""}

	# Get current key/value pair from file
	exists=$(grep "^${key}=" $cfg_file 2>/dev/null)
	exists_comment=$(echo $(echo $exists | cut -d'#' -f2-))
	case "${val}" in
		""|"--UNSET--")
			if [ "${exists}" != "" ]; then
				echo "Removing ${key} from ${cfg_file}"
				sed "/${key}=.*/d" -i $cfg_file
			fi
			return
			;;
		"--EMPTY--")
			val=""
			;;
	esac
	# Put " # " at beginning of comment if not empty
	if [ "${comment}" != "" ]
	then
		comment=" # ${comment}"
	else
		if [ "${exists_comment}" != "" ]; then
			comment=" # ${exists_comment}"
		fi
	fi

	# Line to be put in
	data="${key}=\"${val}\"${comment}"

	# Check if key exists in config
	if [ "${exists}" != "" ]; then
		# If the line isn't the same as the parsed data line, replace it
		if [ "${exists}" != "${data}" ]; then
			sed -e "s%^${key}=.*\$%${data}%g" -i $cfg_file
		fi
	else
		# If value does not exist, append to file
		#echo "Adding ${data} to ${cfg_file}"
		echo -ne "${data}\n" >> $cfg_file
	fi
}

# Create config file
fn_create_config(){
	cfg_type="$(basename "${1:-default}" .cfg | sed -e 's/^_//g')"
	cfg_force=$2
	# Look up file and header for cfg_type
	cfg_file="cfg_file_${cfg_type}"
	cfg_header="cfg_header_${cfg_type}"

	cfg_dir=$(dirname ${!cfg_file})
	#If config directory does not exist, create it
	if [ ! -e $cfg_dir ]; then mkdir -p $cfg_dir; fi

	# Create file header if needed
	if [ ! -e ${!cfg_file} ] || [ "${cfg_force}" != "" ]; then
		echo "Creating ${cfg_type} config at ${!cfg_file}"
		echo -ne "${!cfg_header}\n\n" > ${!cfg_file}
		# Dump in defaults for this game
		if [ "${cfg_type}" == "default" ]; then
			cat ${settingsdir}/settings >> ${!cfg_file}
		fi
	fi
}

# Delete all output files from the settings parser
fn_flush_game_settings(){
	if [ -e $settingsdir ]; then
		rm -rf $settingsdir > /dev/null
	fi
	mkdir -p $settingsdir
}

# Pull in another gamedata file
fn_import_game_settings(){
	import="${gamedatadir}/${1}"
	importdir=$(echo "${gamedatadir}" | sed -e "s|${lgsmdir}/||g")
	#echo $importdir
	if [ ! -e $import ]; then
		fn_check_github_files "${lgsmdir}" "${lgsmdir}/gamedata/${1}"
		fn_getgithubfile "${importdir}/${1}" run "gamedata/${1}"
	fi
	source $import
}

# Set variable in setting file
fn_set_game_setting(){
	if [ "${parse_gamedata}" == "0" ]; then return; fi
	setting_set=$1
	setting_name=$2
	setting_value=$3
	setting_comment=$4
	fn_update_config "${setting_name}" "${setting_value}" "${settingsdir}/${setting_set}" "${setting_comment}"
}

# Set parameter and make sure there is a config setting tied to it
fn_set_game_parm(){
	if [ "${parse_gamedata}" == "0" ]; then return; fi
	setting_set=$1
	setting_name=$2
	setting_value=$3
	setting_comment=$4
	fn_update_config "${setting_name}" "${setting_value}" "${settingsdir}/settings" "${setting_comment}"
	fn_update_config "${setting_name}" "\${${setting_name}}" "${settingsdir}/${setting_set}" ""
}

# Get value from settings file
fn_get_game_setting(){
	setting_set=$1
	setting_name=$2
	setting_default=$3
}

# Fix dependency files for game
fn_fix_game_dependencies() {
	depfile="${settingsdir}/dependencies"
	# If no dependency list, skip out
	if [ ! -e "${depfile}" ]; then
		return
	fi

	# If the directory doesn't yet exist, exit the function.
	# This is so that we wait until the game is installed before putting these files in place
	if [ ! -e "${dependency_path}" ]; then
		return
	fi

	while read -r line; do
		filename=$(echo $line | cut -d'=' -f1)
		md5sum=$(echo $line | cut -d'"' -f2)
		remote_path="dependencies/${filename}.${md5sum}"
		local_path="${dependency_path}/${filename}"
		local_md5="$(fn_get_md5sum "${local_path}")"
		echo "Checking ${filename} for ${md5sum}"
		if [ "${local_md5}" != "${md5sum}" ]; then
			fn_getgithubfile "${local_path}" 0 "${remote_path}" 1
		fi
	done < $depfile
}


# Get the checksum of the current settings file to compare after loading gamedata
settings_file_md5="$(fn_get_md5sum "${settings_file}")"



gamedata_source_files="$(echo $(fn_get_import_tree "${selfname}"))"
if [ -e "${settings_file}" ]; then
	settings_source_files=$(grep '^gamedata_source_files=' "${settings_file}" | cut -d'"' -f2)
	if [ "${settings_source_files}" != "${gamedata_source_files}" ]; then
		parse_gamedata=1
	else
		parse_gamedata=0
	fi
else
	parse_gamedata=1
fi

# Import this game's settings
fn_import_game_settings $selfname
if [ "${parse_gamedata}" == "1" ]; then
	fn_set_game_setting settings "gamedata_source_files" "${gamedata_source_files}"
	fn_create_config default 1
fi
if [ ! -f $cfg_file_common ]; then fn_create_config common; fi
if [ ! -f $cfg_file_instance ]; then fn_create_config instance; fi

fn_create_merged_config

# Import mod
if [ "${game_mod}" != "" ]; then
	modfile="mods/${selfname}/${game_mod}"
	fn_import_game_settings "${modfile}"
fi
