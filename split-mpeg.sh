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

# finds distance between 2 times, as explained above
# args: start_min start_sec end_min end_sec start_tenth end_tenth
# 	having the tenths last makes them optional
# start must be ahead of end
# output: prints length_min length_sec length_tenth to stdout
function time_span	
{
	read start_min start_sec end_min end_sec start_tenth end_tenth <<< $*

	length_min=$(( end_min - start_min ))

		## find the length of seconds ##
	# the simplest case to find length of partial minute
	# eg start=1:27 end=2:30
	# that makes 3 seconds: ->28->29->30
	# also takes care of when they are equal
	if [ $end_sec -ge $start_sec ]; then
		let "length_sec = end_sec - start_sec"
	else
	# the complicated case...
	# I'm pretty sure this works...
	# eg start=0:58 end=1:2 thats ->59->0->1->2 = 4 seconds
	# 60-58+2=4
		let "length_sec = 60 - start_sec + end_sec"
		let "--length_min"
	fi

		## find length of tenths ##
	if [ $end_tenth -ge $start_tenth ]; then
		let "length_tenth = end_tenth - start_tenth"
	else
		let "length_tenth = 10 - start_tenth + end_tenth"
	fi
	
	echo $length_min $length_sec $length_tenth
}

function ffmpeg_prepare	# prints min and sec with acceptable formating
{
	read min sec tenth <<< $*
	# check out the zero padding - thank you, jonathanwagner.net!
	printf "00:%02d:%02d.%d" $min $sec $tenth
}

function extract	# uses $vid_file
{
# having the tenths last makes them optional
while read start_min start_sec end_min end_sec out_file start_tenth end_tenth; do
		## ffmpeg starts at offset, extracts duration ##
		## but I use start and end so... ##
	read length_min length_sec length_tenth <<< $(time_span \
		$start_min $start_sec $end_min $end_sec $start_tenth $end_tenth)

		## prepare time arguments for ffmpeg ##
	start_arg=$(ffmpeg_prepare $start_min $start_sec $start_tenth)
	length_arg=$(ffmpeg_prepare $length_min $length_sec $length_tenth)

	# the easy part - for me at least 
	# now is when the computer works a bit ;)
	ffmpeg -i $vid_file -ss $start_arg -t $length_arg \
		-vcodec copy -acodec copy $out_folder/$out_file \
		-loglevel error
done
}

cat $cut_file | extract 
