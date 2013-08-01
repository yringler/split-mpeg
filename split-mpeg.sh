#!/bin/bash

vid_file=$1
cut_file=$2 # the file with the info on how to cut the video

function extract	# uses $vid_file
{
declare out_file	# name of the extracted file
declare -i end_min end_sec
declare -i length_min length_sec
declare start_arg length_arg	# for ffmpeg - wants hh:mm:ss

while read start_min start_sec end_min end_sec out_file; do
		## ffmpeg starts at offset, extracts duration ##
		## but I use start and end so... ##
	length_min = $(( end_min - start_min ))

		## find the length of seconds ##
	# the simplest case to find length of partial minute
	# eg start=1:20 end=2:30 INCLUDEING SECOND 30
	# that makes 11 seconds: 30-20+1
	# also if the seconds are the same
	# eg start=1:20 end=2:20
	if [ end_sec -ge start_sec ]; then
		let "length_sec = end_sec - start_sec + 1"
	else
	# the complicated case...
	# I'm pretty sure this works...
	# eg start=0:58 end=1:2 -> thats 58,59,1,2 = 4 seconds
	# 60-58=2 +2=4
		let "length_sec = 60 - start_sec + end_sec"
		let "--length_min"
	fi

		## prepare time arguments for ffmpeg ##
	# check out the zero padding - thank you, jonathanwagner.net!
	printf -v start_arg "00:%02d:%02d" $start_min $start_sec
	printf -v length_arg "00:%02d:%02d" $length_min $length_sec

	# the easy part - for me at least 
	# now is when the computer works a bit ;)
	ffmpeg -i $vid_file -t $start_arg -ss length_arg
		-vcodec copy -acodec $out_file -loglevel warning
done
}

cat $cut_file > extract 
