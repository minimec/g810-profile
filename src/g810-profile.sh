#!/bin/bash
#==============================================================================
#title           : g810-profile
#description     : While loop to apply Logitech G810 LED profiles
#author          : minimec
#date            : 20180302
#version         : 0.9 ('almost complete')
#usage           : g810-profile {start|stop}
#debug           : 'watch "cat /dev/shm/g810-profile/PROFILES_ACTIVE"'
#==============================================================================

## Variables
LOOPSPEED=2					# For application listener (default=2)
MUSIC_PLAYER=Lollypop		# check 'mdbus2 | grep MediaPlayer2'			(example: audacious, GnomeMusic, Lollypop, rhythmbox, spotify)
MUSIC_PROFILE=lollypop 		# Also needed in .g810-profile/PROFILES files	(example: audacious, gnome-music, lollypop, rhythmbox, spotify)
DING=off					# For debug / 'Ding' sound

## Functions
apply(){
# Read arrays
read -a PROFILE_BASE < $HOME/.g810-profile/PROFILE_BASE
read -a PROFILES_PERMANENT < $HOME/.g810-profile/PROFILES_PERMANENT
read -a PROFILES_ACTIVE < /dev/shm/g810-profile/PROFILES_ACTIVE
# load base profile
g810-led -pp < $HOME/.g810-profile/profiles/$PROFILE_BASE
# load permanent profiles
for i in "${PROFILES_PERMANENT[@]}"
	do
	g810-led -pp < $HOME/.g810-profile/profiles/$i
done
# apply profiles from PROFILES_ACTIVE Array
for i in "${PROFILES_ACTIVE[@]}"
	do
	g810-led -pp < $HOME/.g810-profile/profiles/$i
done
# Check mute state / Apply color
if [ "$(pacmd dump | awk '$1 == "set-sink-mute" {m[$2] = $3} $1 == "set-default-sink" {s = $2} END {print m[s]}')"  == "yes" ]; then
	g810-led -k mute ff0000
fi
# Check Play/Pause/Stop status / Apply LED
if [[ "${PROFILES_ACTIVE[@]}" =~ "${MUSIC_PROFILE}" ]]; then
	STATUS=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.$MUSIC_PLAYER \
	/org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' \
	string:'PlaybackStatus'|egrep -A 1 "string"|cut -b 26-|cut -d '"' -f 1|egrep -v ^$`
	if [ "$STATUS" == "Playing" ]; then
		g810-led -pp < $HOME/.g810-profile/profiles/$MUSIC_PROFILE
		g810-led -k play_pause 006400
	elif [ "$STATUS" == "Paused" ]; then
		g810-led -pp < $HOME/.g810-profile/profiles/$MUSIC_PROFILE
		g810-led -k play_pause ff0000
	elif [ "$STATUS" == "Stopped" ]; then
		g810-led -pp < $HOME/.g810-profile/profiles/$MUSIC_PROFILE
		g810-led -k stop ff0000
	fi
fi
unset $STATUS
}

dbus-listener(){
# dbus-listener for media controls
dbus-monitor --session "path=/org/mpris/MediaPlayer2,member=PropertiesChanged" --monitor \
| stdbuf -i0 -oL grep PlaybackStatus \
| stdbuf -i0 -oL xargs -L 1 $HOME/.g810-profile/src/g810-media-control.sh &
# Create / save PID file -> working directory
PID=`ps aux | grep [d]bus-monitor | awk '{ print $2 }' | sort -nr | head -n 1`
echo $PID > /dev/shm/g810-profile/g810-profile-dbus.pid	
}

daemon(){
# Application 'listener'
while true; do
	# Read Arrays (Info!!! 'mapfile' for bash output / 'read' for file)
	mapfile -t APPS_ACTIVE < <( ps o comm -C $(cat /dev/shm/g810-profile/PROFILES) | tail -n +2 | sed '/<defunct>/d') # "sed/<defunct>" workaround thunderbird
	read -a PROFILES_ACTIVE < /dev/shm/g810-profile/PROFILES_ACTIVE
    # Compare Arrays (Array Length) / in case != apply new app list
	if [ ${#APPS_ACTIVE[@]} != ${#PROFILES_ACTIVE[@]} ]; then
		# Apply new running app list
		echo "${APPS_ACTIVE[@]}" > /dev/shm/g810-profile/PROFILES_ACTIVE
		# Apply changes
		apply &
		# FOR DEBUG / 'Ding' sound
		if [ "$DING" == "on" ]; then paplay $HOME/.g810-profile/Ding.wav; fi
		# LOOP all X seconds
		sleep $LOOPSPEED
	else
		# LOOP all X seconds
		sleep $LOOPSPEED
	fi
done
}

google-keyboard(){
# Disable 'Google Keyboard'
if [ "$(cat /dev/shm/g810-profile/GOOGLE_TOGGLE)"  == "on" ]; then
	echo "off" > /dev/shm/g810-profile/GOOGLE_TOGGLE
	echo $(cat $HOME/.g810-profile/PROFILES) > /dev/shm/g810-profile/PROFILES
# Enable 'Google Keyboard'
else
	echo "on" > /dev/shm/g810-profile/GOOGLE_TOGGLE
	echo $(cat $HOME/.g810-profile/GOOGLE_KEYBOARD)","$(cat $HOME/.g810-profile/PROFILES) > /dev/shm/g810-profile/PROFILES
fi
}

join-the-club(){
g810-led -pp < $HOME/.g810-profile/profiles/join_the_club
sleep 3
# Apply default profile
read -a PROFILE_BASE < $HOME/.g810-profile/PROFILE_BASE
g810-led -pp < $HOME/.g810-profile/profiles/$PROFILE_BASE
}

media-control(){
# Get player status
STATUS=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.$MUSIC_PLAYER \
/org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' \
string:'PlaybackStatus'|egrep -A 1 "string"|cut -b 26-|cut -d '"' -f 1|egrep -v ^$`
# Appy color profile
if [ "$STATUS" == "Playing" ]; then
	g810-led -pp < $HOME/.g810-profile/profiles/$MUSIC_PROFILE
	g810-led -k play_pause 006400
elif [ "$STATUS" == "Paused" ]; then
	g810-led -pp < $HOME/.g810-profile/profiles/$MUSIC_PROFILE
	g810-led -k play_pause ff0000
elif [ "$STATUS" == "Stopped" ]; then
	g810-led -pp < $HOME/.g810-profile/profiles/$MUSIC_PROFILE
	g810-led -k stop ff0000
fi
unset $STATUS
}

mute(){
# Mute device
amixer -D pulse set Master 1+ toggle
# Check mute state / Apply color
if [ "$(pacmd dump | awk '$1 == "set-sink-mute" {m[$2] = $3} $1 == "set-default-sink" {s = $2} END {print m[s]}')"  == "yes" ]; then
	g810-led -k mute ff0000
else
	apply
fi
}

start(){
# Init (In case there is no /dev/shm/g810-profile working directory, create it)
if [ ! -d /dev/shm/g810-profile ]; then
    mkdir /dev/shm/g810-profile
fi
# Create files needed by the script in working directory
touch /dev/shm/g810-profile/PROFILES_ACTIVE
touch /dev/shm/g810-profile/GOOGLE_TOGGLE
echo $(cat $HOME/.g810-profile/PROFILES) > /dev/shm/g810-profile/PROFILES
# Apply default profile
read -a PROFILE_BASE < $HOME/.g810-profile/PROFILE_BASE
g810-led -pp < $HOME/.g810-profile/profiles/$PROFILE_BASE
# Enable 'Google Keyboard'
# google-keyboard	# disabled '#' by default
# Start the listeners
dbus-listener &
daemon &
}

stop(){
# Load default grofile of g810-led
g810-led -pp < /etc/g810-led/profile
# clean g810-profile working directory
rm /dev/shm/g810-profile/PROFILES_ACTIVE
rm /dev/shm/g810-profile/GOOGLE_TOGGLE
# Kill dbus-listener pid
kill -9 $(cat /dev/shm/g810-profile/g810-profile-dbus.pid)
# clean g810-profile working directory
rm /dev/shm/g810-profile/g810-profile-dbus.pid
# Kill all processes of g810-profile
killall g810-profile
}

## MAIN
if [[ $# -eq 1 && $1 == "--google" ]]; then
	google-keyboard
elif [[ $# -eq 1 && $1 == "--join" ]]; then
	join-the-club
elif [[ $# -eq 1 && $1 == "--media" ]]; then
	media-control
elif [[ $# -eq 1 && $1 == "--mute" ]]; then
	mute
elif [[ $# -eq 1 && $1 == "start" ]]; then
	start
elif [[ $# -eq 1 && $1 == "stop" ]]; then
	stop
else
    echo "Usage: g810-profile {start|stop}"
fi
