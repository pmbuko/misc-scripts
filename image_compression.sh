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
	find "$2" -name *.$file_ext
}

count_files() {
	if [ "$1" == "" ]; then
		echo 0
	else
		echo "$1" | wc -l
	fi
}

generate_qsubs() {
	# $1: file paths
# $2: mode
	count=1
	while IFS= read -r tif; do
		if [ "$2" == "bzip2" ]; then
			mode="compress"
		else
			mode="uncompress"
		fi
		cat <<-EOF > qsub_$mode.$count
		qsub -N $2 -l archive=true -b y -o /dev/null -j y '$2 "$tif"'
		EOF
		((count++))
	done <<< "$1"
}

generate_qsub_batches() {
# $1: path to tif
# $2: mode
# $3: batch_size
	while IFS= read -r tif; do
		if [ "$2" == "bzip2" ]; then
			mode="compress"
		else
			mode="uncompress"
		fi
		cat <<-EOF >> qsub_$mode
		qsub -N $2 -l archive=true -b y -o /dev/null -j y '$2 "$tif"'
		EOF
	done <<< "$1"
	split -l $3 -a 5 -d qsub_$mode qsub_$mode.
	unlink qsub_$mode
}

if [ "$#" -ge "2" ]; then
	path="${@: -1}" #path is the last argument
	batch_size=1
	file_ext="tif"
	while getopts "cde:n:" opt; do
		case $opt in
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
			n)
				batch_size=$OPTARG
				if [ "$batch_size" == "" ]; then
					echo "Option -$OPTARG requires a number." >&2
					exit 1
				fi
				;;
		esac
	done
fi

### MAIN ###
if [[ "$command" = "bzip2" ]]; then
	echo -n "Looking for '$file_ext' files to compress..." 
else
	echo -n "Looking for '$file_ext' files to decompress..."
fi
found_files=$(find_files $file_ext $path $command)
files_count=$(count_files "$found_files")
echo ". $files_count found."

if [ "$files_count" -gt "0" ]; then
	if [ "$batch_size" -gt "1" ]; then
		echo -n "Generating qsub files in batches of $batch_size..."
		generate_qsub_batches "$found_files" $command $batch_size
	else
		echo -n "Generating qsub files..."
		generate_qsubs "$found_files" $command
	fi
	echo ". Done."
else
	echo "Exiting."
fi

