#!/bin/bash

find_files() {
# $1: file_ext
# $2: directory path
# $3: mode
	if [ "$3" == "bzip2" ]; then
		file_ext="${1}"
	else
		file_ext="${1}.bz2"
	fi
	find "$2" -type f -name "*.${file_ext}"
}

count_files() {
# $1 = file list to count
	if [ "$1" == "" ]; then
		echo "0"
	else
		echo "$1" | wc -l
	fi
}

new_loc() {
# $1 = file path
# $2 = mode
# $3 = dest tier
	if [[ $mode == compress* ]]; then
		echo "$1".bz2 | sed "s|^/\w*|/$3|"
	else
		echo "$1" | sed "s|^/\w*|/$3|" | sed 's|\.bz2$||'
	fi
}

generate_qsubs() {
# $1: file paths
# $2: mode
	count=1
	while IFS= read -r file; do
		if [[ $2 == bzip* ]]; then
			mode="compress"
		else
			mode="uncompress"
		fi
		cat <<-EOF > qsub_${mode}.${count}
		qsub -N $mode ${archive}${gpu} -b y -o /dev/null -j y '$2 "$file"'
		EOF
		((count++))
	done <<< "$1"
}

generate_qsubs_reloc() {
# $1: file paths
# $2: mode
# $3: moveto
	count=1
	while IFS= read -r file; do
		if [[ $2 == bzip* ]]; then
			mode="compress_relocate"
		else
			mode="uncompress_relocate"
		fi
		cat <<-EOF > qsub_${mode}.${count}
		qsub -N $mode ${archive}${gpu} -b y -o /dev/null -j y '$2 "$file"' > "$(new_loc "$tif" "$mode" "$3")"
		EOF
		((count++))
	done <<< "$1"
}

generate_qsub_batches() {
# $1: file paths
# $2: mode
# $3: batch_size
	while IFS= read -r file; do
		if [[ $2 == bzip* ]]; then
			mode="compress"
		else
			mode="uncompress"
		fi
		cat <<-EOF >> qsub_${mode}
		qsub -N $mode ${archive}${gpu} -b y -o /dev/null -j y '$2 "$file"'
		EOF
	done <<< "$1"
	split -l $3 -a 5 -d qsub_${mode} qsub_${mode}.
	unlink qsub_${mode}
}

generate_qsub_batches_reloc() {
# $1: file paths
# $2: mode
# $3: batch_size
# $4: moveto
	while IFS= read -r file; do
		if [[ $2 == bzip* ]]; then
			mode="compress_relocate"
		else
			mode="uncompress_relocate"
		fi
		cat <<-EOF >> qsub_${mode}
		qsub -N $mode ${archive}${gpu} -b y -o /dev/null -j y '$2 "$file" > "$(new_loc "$file" "$mode" "$4")"'
		EOF
	done <<< "$1"
	split -l $3 -a 5 -d qsub_${mode} qsub_${mode}.
	unlink qsub_${mode}
}

if [ "$#" -ge "2" ]; then
	path="${*: -1}" #path is the last argument
	archive=""
	gpu=""
	file_ext="tif"
	moveto=""
	batch_size=1
	file_list=""
	while getopts "agcde:m:n:f" opt; do
		case $opt in
			a)
				if [ -z "$gpu" ]; then
					archive="-l archive=true"
				else
					echo "Option -$OPTARG cannot be used together with -g."
					exit 1
				fi
				;;
			g)
				if [ -z "$archive" ]; then
					gpu="-l gpu=true"
				else
					echo "Option -$OPTARG cannot be used together with -a."
					exit 1
				fi
				;;
			c)	
				command="bzip2"
				;;
			d)
				command="bunzip2"
				;;
			e)
				file_ext=$OPTARG
				if [ "$file_ext" == "" ]; then
					echo "Option -$OPTARG requires a file extension." >&2
					exit 1
				fi
				;;
			m)
				moveto=$OPTARG
				if [ "$moveto" == "" ]; then
					echo "Option -$OPTARG requires a tier name (e.g. 'tier2')." >&2
					exit 1
				fi
				if [ "$command" == "bzip2" ]; then
					command="bzip2 -kc"
				elif [ "$command" == "bunzip2" ]; then
					command="bunzip2 -kc"
				fi
				;;
			n)
				batch_size=$OPTARG
				if [ "$batch_size" == "" ]; then
					echo "Option -$OPTARG requires a number." >&2
					exit 1
				fi
				;;
			f)
				file_list="${*: -1}"
				;;
		esac
	done
fi

### MAIN ###
if [ -z "$file_list" ]; then
	if [[ "$command" == bzip2* ]]; then
		echo -n "Looking for '$file_ext' files to compress..." 
	else
		echo -n "Looking for '$file_ext' files to decompress..."
	fi
	found_files=$(find_files "$file_ext" "$path" "$command")
	files_count=$(count_files "$found_files")
	echo ". $files_count files found."
else
	if [[ "$command" == bzip2* ]]; then
		echo -n "Using supplied list for compression..." 
	else
		echo -n "Using supplied list for decompression..."
	fi
	found_files=$(cat "$file_list")
	files_count=$(wc -l "$file_list" | awk '{print $1}')
	echo ". $files_count files found."
fi
if [ "$files_count" -gt "0" ]; then
	if [ -z $moveto ]; then
		if [ "$batch_size" -gt "1" ]; then
			echo -n "Generating qsub files in batches of $batch_size..."
			generate_qsub_batches "$found_files" "$command" "$batch_size"
		else
			echo -n "Generating qsub files..."
			generate_qsubs "$found_files" "$command"
		fi
	else
		if [ "$batch_size" -gt "1" ]; then
			echo -n "Generating qsub files in batches of $batch_size..."
			generate_qsub_batches_reloc "$found_files" "$command" "$batch_size" "$moveto"
		else
			echo -n "Generating qsub files..."
			generate_qsubs_reloc "$found_files" "$command" "$moveto"
		fi
	fi
	echo ". Done."
else
	echo "Exiting."
fi

