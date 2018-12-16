#!/bin/bash

#discover_message = 
#        "M-SEARCH * HTTP/1.1
#        HOST: 239.255.255.250:1982 
#        MAN: \"ssdp:discover\" 
#        ST: wifi_bulb"

#echo $(discover_message) > /dev/udp/239.255.255.250/1982
#And then catch the mono cast response.

DATE=$(eval "date +\"%T\"")
RET_VAL=""
W_TIME_START="07:00"
W_TIME_END="07:30"
Z_ALARM_HOUR="00"
Z_ALARM_MIN="00"

#
## Color control values
#
RGB_STEPS=8
COLOR_CHANGE_TIME_MS=10000
COLOR_CHANGE_TIME_S=10
# Can take up to 10 steps with these settnngs but light is too white in the end.

# Define starting color
RGB_START=(215 55 5)
# Define color increase
RGB_STEP=(3 13 7)

#
## Intensity control values
#
STARTING_INTENSITY=1

#8 loop laps, should take ~9 minutes (560s) -> 70s per loop.
INT_INC_TIME_MS=70000
INT_INC_TIME_S=70


#IP settings
IP_RPi=192.168.1.79

##---------------------------------
# 	Main light loop function
##---------------------------------
main_light_loop() {
	echo "Loop lap 0"
	RGB_COUNTER=0
	let INT_STEP=80/$RGB_STEPS
	let INT=$STARTING_INTENSITY+$INT_STEP

         while [ $RGB_COUNTER -lt $RGB_STEPS ]; do
		let COLOR_R=${RGB_START[0]}+${RGB_STEP[0]}*RGB_COUNTER
		let COLOR_G=${RGB_START[1]}+${RGB_STEP[1]}*RGB_COUNTER
		let COLOR_B=${RGB_START[2]}+${RGB_STEP[2]}*RGB_COUNTER
		let COLOR=$COLOR_R*65536+$COLOR_G*256+$COLOR_B

		RET_VAL=$(echo -ne '{"id":1,"method":"set_rgb","params":['$COLOR',"smooth",'$COLOR_CHANGE_TIME_MS']}\r\n' | nc -w1 $IP_RPi 55443)
		echo "Loop lap: $RGB_COUNTER"
		sleep $COLOR_CHANGE_TIME_S
              	let RGB_COUNTER=RGB_COUNTER+1

		# Increase intensity also, do this stepwise.
                while true; do
			RET_VAL=$(echo -ne '{"id":1,"method":"set_bright","params":['$INT',"smooth",'$INT_INC_TIME_MS']}\r\n' | nc -w1 $IP_RPi 55443)
	                if ( echo "$RET_VAL" | grep -q "bright" )
	                then 
	                	let INT=$INT+$INT_STEP
	                        break
	                else
	                	echo "Failed to set intensity:$RET_VAL"
	               	fi
	               	sleep $INT_INC_TIME_S
	     	done
             	sleep 2
	done
}


##---------------------------------
# 	Start of program
##---------------------------------

# Remove previous log file
rm ~/Desktop/log.txt

echo "Starting up Johan Yeelight clock script, /etc/init.d/mystartup.sh" > ~/Desktop/log.txt

# If day not Firday or Saturday skip all settings and set alarm to 05:45.
if  [ "$(date +%A)" != "fredag" ] && [ "$(date +%A)" != "lördag"  ] && [ "$(date +%H)" -lt "21" ]
then
	Z_ALARM_HOUR="05"
	Z_ALARM_MIN="45"
        echo "Alarm set to: $W_TIME_START_2" >> ~/Desktop/log.txt
        zenity  --timeout 60 --info --text "Alarm automatically set to $Z_ALARM_HOUR:$Z_ALARM_MIN since time now is before 21:00."
else

	# Set up alarm time
	Z_ALARM_HOUR=$(zenity --list --radiolist --width=70 --height=100 --text \
		"Select time for alarm (hours):" \
	        --hide-header --column "Select" --column "Hour" \
		TRUE "$(date +%H)" \
		FALSE "05" \
	        FALSE "06" \
	        FALSE "07" \
	        FALSE "08" \
	        FALSE "09" \
	        FALSE "10" \
	        FALSE "11" \
	        FALSE "12" \
	        FALSE "13" \
	        FALSE "14" \
	        FALSE "15" \
	        FALSE "16" \
	        FALSE "17" \
	        FALSE "18" \
	        FALSE "19" \
	        FALSE "20" \
	        FALSE "21" \
	        FALSE "22" \
	        FALSE "23" \
		FALSE "00" \
		FALSE "01" \
		FALSE "02" \
		FALSE "03" \
		FALSE "04")

	if  [ "$Z_ALARM_HOUR" != "" ]
	then
		Z_ALARM_MIN=$(zenity --list --radiolist --width=70 --height=100 --text \
	        "Select time for alarm (minutes):" \
	        --hide-header --column "Select" --column "Minutes" \
		TRUE "$(date +%M)" \
		FALSE "00" \
		FALSE "05" \
	        FALSE "10" \
		FALSE "15" \
		FALSE "20" \
	        FALSE "25" \
		FALSE "30" \
		FALSE "35" \
		FALSE "40" \
		FALSE "45" \
		FALSE "50" \
		FALSE "55" \
		)

		if [ "$Z_ALARM_MIN" != "" ]
		then
			zenity --info --text "Alarm set to $Z_ALARM_HOUR:$Z_ALARM_MIN."
			W_TIME_START_2=$Z_ALARM_HOUR:$Z_ALARM_MIN
			echo "Alarm set to: $W_TIME_START_2" >> ~/Desktop/log.txt
		else 
			zenity --info --text "Alarm not set. Exiting"
		fi
	else 
		zenity --info --text "Alarm not set. Exiting"
	fi
fi #End of weekday -> Alarm time  = 05:45



##---------------------------------
# 	Main control loop
##---------------------------------
while [[ "$Z_ALARM_HOUR" != ""  && "$Z_ALARM_MIN" != "" ]]; do

	DATE=$(eval "date +\"%T\"")
	echo "Timestamp: " $DATE

	#Start alarm
	if [ $(date +%H) = $Z_ALARM_HOUR ] && [ $(date +%M) = $Z_ALARM_MIN ]
	then
		echo "Alarm got off at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt
		echo "Alarm is triggered: " $(eval "date +\"%T\"")

		# Ramping up bulb
		while true; do
			# Await the correct return value: '{"method":"props","params":{"power":"on"}}'
                        RET_VAL=$(echo -ne '{"id":1,"method":"set_power","params":["on","smooth",80000]}\r\n' | nc -w1 $IP_RPi 55443)
                        echo "RET_VAL=$RET_VAL"

			#if ( echo "$RET_VAL" | grep -q "on" )
			if ( echo "$RET_VAL" | grep -q '{"method":"props","params":{"power":"on"}}' )
			then 
				echo "Turning on bulb"
				break
			else
				echo "Failed turning on bulb, RET_VAL=$RET_VAL"
			fi

			# Wait before trying to turn on bulb again.
			sleep 2
                done

		# Set intensity to minimal 1%.
		while true; do
			RET_VAL=$(echo -ne '{"id":1,"method":"set_bright","params":['$STARTING_INTENSITY',"sudden",0]}\r\n' | nc -w1 $IP_RPi 55443)
			if ( echo "$RET_VAL" | grep -q "bright" )
                        then 
                                #echo "Set intensity: $RET_VAL"
                                break
                        else
                                echo "Failed to set intensity:$RET_VAL"
				# Maybe because the intensity is the same.
				RET_VAL=$(echo -ne '{"id":1,"method":"get_prop","params":["bright"]}\r\n' | nc -w1 $IP_RPi 55443)
				echo "Reading intensity: $RET_VAL"	

				if ( echo "$RET_VAL" | grep -q '"1"')
				then
					echo "Intensity already set to " $STARTING_INTENSITY
					break
				fi
                        fi
                        sleep 1
		done

		# Start the main light loop and kill it at zenity input or timeout
		main_light_loop &
		PID_MLL=$!

                zenity --timeout 900 --info --width 200 --height 200 --text "Alarm sounding for 15 minutes. Press ok to stop."

		echo "Killing $PID_MLL"
		echo "Killing $PID_MLL" >> ~/Desktop/log.txt
		kill $PID_MLL

                #Turn of bulb slowly after at most 15 minutes.
                echo -ne '{"id":1,"method":"set_power","params":["off","smooth",5000]}\r\n' | nc -w1 $IP_RPi 55443

		echo "Alarm loop done at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt
		sleep 1
		exit 0
	else 
		echo "Alarm not going off yet"
	fi

	sleep 20
done

echo "Alarm loop failed at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt



