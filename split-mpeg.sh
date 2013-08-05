#!/bin/bash
# usage: split-mpeg.sh vid_file cut_file
# see README for details

# Time is written in this program as when it would be displayed in a video 
# player, ie 0:0:0 until 0:0:2 means from when 0 is displayed
# until when 1 is displayed until when 2 is displayed
# or more concisely ->1->2
# which is 2 complete seconds

vid_file=$1
cut_file=$2 # the file with the info on how to cut the video

readonly out_folder=${3:-cut}	# the folder where the pieces are put
if ! [ -d $out_folder ]; then mkdir $out_folder; fi

function to_sec { echo $(( 60*$1+$2 )); }	# args:minute,second
function calc_length {	# args:sec_a tenth_a sec_b tenth_b
	read sec_a tenth_a sec_b tenth_b <<< $(echo $*)
	diff_sec=$(( $sec_b - $sec_a ))
	if [ $tenth_b -ge $tenth_a ]; then 
		diff_tenth=$(( $tenth_b-$tenth_a ))
	else 
		# eg 0.9->1.2 = ->1.0->1.1->1.2	= 0.3 = 1- 0.9 + 0.2
		diff_tenth=$(( 1-$tenth_a+$tenth_b ))
		let --diff_sec	# borrows from the seconds place
	fi

	echo ${diff_sec}.${diff_tenth}
}

function use_file {
	if [ $status == load ]; then
		vid_file=$a2
		return
	fi
		# shift so $1 is first end arg #
	if [ $1 == c ]; then
		shift
	else
		start_sec=$(to_sec $1 $2)
		start_tenth=$3
		shift 3
	fi

	if [ $1 == end ]; then
		to_end=true
	else
		to_end=

		end_sec=$(to_sec $1 $2)
		end_tenth=$3
	fi

	if [ ! $to_end ]; then
			## ffmpeg starts at offset, extracts duration	##
			## but I use start and end so... 		##
		length=$(calc_length $start_sec $start_tenth
			$end_tenth $end_tenth)
		length_section="-t $length"
	else
		length_section=
	fi

	ffmpeg -i $vid_file -ss $start_sec.$start_tenth $length_section\
		-vcodec copy -acodec copy $out_folder/$out_file \
		-loglevel error
done
}

while read line; do
	use_file $line
done
