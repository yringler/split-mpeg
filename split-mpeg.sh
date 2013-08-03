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

function to_sec { echo $(( 60*$1+$2 )).${3:-0}; }
function extract {
# having the tenths last makes them optional
while read start_min start_sec end_min end_sec out_file start_tenth end_tenth
do
	start=$(to_sec $start_min $start_sec $start_tenth)
	end=$(to_sec  $end_min $end_sec $end_tenth)
		## ffmpeg starts at offset, extracts duration ##
		## but I use start and end so... ##
	length=$(( end - start ))

	ffmpeg -i $vid_file -ss $start -t $length \
		-vcodec copy -acodec copy $out_folder/$out_file \
		-loglevel error
done
}

cat $cut_file | extract 
