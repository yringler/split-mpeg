#!/bin/bash
# usage: split-mpeg.sh cut_file [out_folder]
# see README for details

# Time is written in this program as when it would be displayed in a video 
# player, ie 0:0:0 until 0:0:2 means from when 0 is displayed
# until when 1 is displayed until when 2 is displayed
# or more concisely ->1->2
# which is 2 complete seconds

# the file with the info on how to cut the video
readonly cut_file=${1:?error:info_file missing} 

readonly out_folder=${2:-cut}	# the folder where the pieces are put
if ! [ -d $out_folder ]; then mkdir $out_folder; fi

function to_sec { echo $(( 60*${1?}+${2?} )); }	# args:minute,second

function calc_length {	# args:sec_a tenth_a sec_b tenth_b
	sec_a=${1?err:sec_a missing}
	tenth_a=${2?err:tenth_a missing}
	sec_b=${3?err:sec_b missing}
	tenth_b=${4?err:tenth missing}

	diff_sec=$(( $sec_b - $sec_a ))

	if [ $tenth_b -ge $tenth_a ]; then 
		diff_tenth=$(( tenth_b-tenth_a ))
	else 
		# eg 0.9->1.2 = ->1.0->1.1->1.2	= 0.3 = 1- 0.9 + 0.2
		# has to be ten, b/c "tenth" is int
		diff_tenth=$(( 10-$tenth_a+$tenth_b ))
		let --diff_sec	# borrows from the seconds place
	fi

	echo ${diff_sec}.${diff_tenth}
}

function use_file {
	if ! [ "$1" ]; then  echo asdf && return; fi

	if [ $1 == load ]; then
			vid_file=${2?err: no vid file}
			return
	elif [ $1 == c ]; then
		start_sec=${end_sec?err: end_sec not set}
		start_tenth=${end_tenth?err:end_tenth not set}
		shift
	else
		# combine minutes and seconds
		start_sec=$(to_sec ${1?} ${2?})
		start_tenth=${3?}
		shift 3
	fi

	if [ $1 == end ]; then
		to_end=true
		shift
	else
		to_end=

		end_sec=$(to_sec ${1?} ${2?})
		end_tenth=${3?}
		shift 3
	fi

	out_file=${1?}
	if [ -e $out_folder/$out_file ]; then 
		echo $out_file:exists
		return
	fi

	if [ ! $to_end ]; then
			## ffmpeg starts at offset, extracts duration	##
			## but I use start and end so... 		##
		length=$(calc_length $start_sec $start_tenth \
			$end_sec $end_tenth)
		length_section="-t ${length?}"
	else
		# so seeks to start, goes to end
		length_section=
	fi

	ffmpeg -i $vid_file -ss $start_sec.$start_tenth $length_section\
		-vcodec copy -acodec copy $out_folder/$out_file \
		-loglevel error < /dev/null
}

while read line ; do
	echo To process:$line:
	use_file $line
done < $cut_file
