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
function calc_length {	# args:sec_a sec_b tenth_a tenth_b
	diff_sec=$(( $2 - $1 ))
	if [[ $4 && $3 ]]; then
		if [ $4 -ge $a ]; then 
			diff_tenth=$(( $4-$3 ))
		else 
			# eg 0.9->1.2 = ->1.0->1.1->1.2	= 0.3 = 1-0.9+0.2
			diff_tenth=$(( 1-$3+$4 ))
			let --diff_sec	# borrows from the seconds place
		fi
	elif [[ $4 || $3 ]]; then
		diff_tenth=${4:-$3}
	else
		diff_tenth=0
	fi

	echo ${diff_sec}.${diff_tenth}
}
function extract {
# having the tenths last makes them optional
while read start_min start_sec end_min end_sec out_file start_tenth end_tenth
do
	start_sec=$(to_sec $start_min $start_sec)
	end_sec=$(to_sec  $end_min $end_sec)
		## ffmpeg starts at offset, extracts duration ##
		## but I use start and end so... ##
	length=$(calc_length $start_sec $end_sec $start_tenth $end_tenth)

	ffmpeg -i $vid_file -ss $start_sec.$start_tenth -t $length \
		-vcodec copy -acodec copy $out_folder/$out_file \
		-loglevel error
done
}

cat $cut_file | extract 
