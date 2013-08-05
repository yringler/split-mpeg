#!/bin/bash
# usage: split-mpeg.sh vid_file cut_file
# see README for details
# (...this might be getting a little bit out of hand...)

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


# only prints arg 1 if its an unsigned int
function print_int { echo $1 | sed -n /^[[:digit:]]*$/p) ]; }
# to allow 4 file formats: with and without tenths 
# and continue from where last left off
# and load a new file
function flex_args {
	# config file tells to load new vid file
	if [ $a3 == end || $a4 == end ]
		echo end
	fi

	if [ $a1 == load ]; then
		echo load
		return
	fi

	# if out_file is a number, then using tenths
	if [ $(print_int $out_file ]; then
	# remember, out_file here is a number - only in other form is out_file
		read start_min start_sec start_tenth \
			end_min end_sec end_tenth out_file \
			<<< $a1 $a2 $a3 $a4 $out_file $a6 $a7
	elif [ $a1 == c ]; then
	# if is using continue format, where only puts in second time
	# format: c m s [t] f	( c minute second [tenth-optional] file)
		if [ $(print_int $a4) ]; then
		# if a4 is a num, so three nums:using tenths
			read end_min end_sec end_tenth out_file \
				<<< $a1 $a2 $a3 $a4
		# What if I continue to end?
		# Then extract will ignore all the end times
		# 	so I can leave this as is
		# I hope...
		else
			read end_min end_sec out_file <<< $a1 $a2 $a3
			end_tenth=0
		fi
	else
		# not using tenths
		read start_min start_sec end_min end_sec out_file \
			<<< $a1 $a2 $a3 $a4 $out_file
		start_tenth=
		end_tenth=
	fi

	echo time
}

function extract {
# out_file is out_file if using non-tenth format
while read a1 a2 a3 a4 out_file a6 a7
do
	status=`flex_args`
	if [ $status == load ]; then
		vid_file=$a2
		continue
	fi
	start_sec=$(to_sec $start_min $start_sec)
	if [ $status != end ]; then
		end_sec=$(to_sec  $end_min $end_sec)
			## ffmpeg starts at offset, extracts duration ##
			## but I use start and end so... ##
		length=$(calc_length $start_sec $end_sec \
			$start_tenth $end_tenth)
			# the length arg - if this is blank, goes to end
			# allows "end" in flex_args to work
		length_section="-t $length"
	else
		length_section=
	fi

	ffmpeg -i $vid_file -ss $start_sec.$start_tenth $length_section\
		-vcodec copy -acodec copy $out_folder/$out_file \
		-loglevel error
done
}

cat $cut_file | extract 
