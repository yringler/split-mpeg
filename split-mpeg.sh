#!/bin/bash
# usage: split-mpeg.sh vid_file cut_file
# see README for details

# amount of time between two times INCLUDES START AND END SECOND
# eg from sec 20 -> sec 25 is *20*,21,22,23,24,*25* = 6 seconds

vid_file=$1
cut_file=$2 # the file with the info on how to cut the video

# finds amount of time between two times
# args: start_min start_sec end_min end_sec 
# output: prints length_min length_sec to stdout
function time_span	
{
	# garbage is to catch any extra arguments
	echo $* | read start_min start_sec end_min end_sec garbage

	length_min=$(( end_min - start_min ))

		## find the length of seconds ##
	# the simplest case to find length of partial minute
	# eg start=1:20 end=2:30
	# that makes 11 seconds: 30-20+1
	# also if the seconds are the same
	# eg start=1:20 end=2:20
	if [ $end_sec -ge $start_sec ]; then
		let "length_sec = end_sec - start_sec + 1"
	else
	# the complicated case...
	# I'm pretty sure this works...
	# eg start=0:58 end=1:2 -> thats 58,59,1,2 = 4 seconds
	# 60-58=2 +2=4
		let "length_sec = 60 - start_sec + end_sec"
		let "--length_min"
	fi
	
	echo $length_min $length_sec
}

function ffmpeg_prepare	# prints min and sec with acceptable formating
{
	echo $* | read min sec
	# check out the zero padding - thank you, jonathanwagner.net!
	printf "00:%02d:%02d" $min $sec
}

function extract	# uses $vid_file
{
while read start_min start_sec end_min end_sec out_file; do
		## ffmpeg starts at offset, extracts duration ##
		## but I use start and end so... ##
	time_span $start_min $start_sec $end_min $end_sec | read \
		length_min length_sec

		# ffmpeg with -ss before and after -i goes fast to first
		# then slow and acurate to second
	time_span 0 15 $start_min $start_sec | read skip_min skip_sec

		## prepare time arguments for ffmpeg ##
	skip_arg=$(ffmpeg_prepare $skip_min $skip_sec)
	start_arg=$(ffmpeg_prepare $start_min $start_sec)
	length_arg=$(ffmpeg_prepare $length_min $length_sec)

	# the easy part - for me at least 
	# now is when the computer works a bit ;)
	ffmpeg -ss $skip_arg -i $vid_file -t $start_arg -ss $length_arg \
		-vcodec copy -acodec $out_file -loglevel warning
done
}

cat $cut_file | extract 
