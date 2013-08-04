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
	read sec_a sec_b tenth_a tenth_b <<< $(echo $*)
	diff_sec=$(( $sec_b - $sec_b ))
	if [[ $tenth_b && $tenth_a ]]; then
		if [ $tenth_b -ge $tenth_a ]; then 
			diff_tenth=$(( $tenth_b-$tenth_a ))
		else 
			# eg 0.9->1.2 = ->1.0->1.1->1.2	= 0.3 = 1-0.9+0.2
			diff_tenth=$(( 1-$tenth_a+$tenth_b ))
			let --diff_sec	# borrows from the seconds place
		fi
	elif [[ $tenth_b || $tenth_a ]]; then
		diff_tenth=${tenth_b:-$tenth_a}
	else
		diff_tenth=0
	fi

	echo ${diff_sec}.${diff_tenth}
}

# to allow two file formats, with and without tenths
# where m=minute s=second t=tenth
function flex_args {
	# if out_file is a number, then using tenths
	if [ $(echo $out_file | sed -n /^[[:digit:]]*$/p) ]; then
	# remember, out_file here is a number - only in other form is out_file
		read start_min start_sec start_tenth \
			end_min end_sec end_tenth out_file \
			<<< $a1 $a2 $a3 $a4 $out_file $a6 $a7
	else
		# not using tenths
		read start_min start_sec end_min end_sec out_file \
			<<< $a1 $a2 $a3 $a4 $out_file
	fi
}

function extract {
# out_file is out_file if using non-tenth format
while read a1 a2 a3 a4 out_file a6 a7
do
	flex_args
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
