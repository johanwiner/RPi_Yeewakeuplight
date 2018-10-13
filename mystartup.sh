#!/bin/bash

#discover_message = 
#        "M-SEARCH * HTTP/1.1
#        HOST: 239.255.255.250:1982 
#        MAN: \"ssdp:discover\" 
#        ST: wifi_bulb"

#echo $(discover_message) > /dev/udp/239.255.255.250/1982
#And then catch the mono cast response.

# Remove previous log file
rm ~/Desktop/log.txt

echo "Starting up Johan Yeelight clock script, /etc/init.d/mystartup.sh" > ~/Desktop/log.txt

DATE=$(eval "date +\"%T\"")
RET_VAL=""
W_TIME_START="07:00"
W_TIME_END="07:30"
Z_ALARM_HOUR="00"
Z_ALARM_MIN="00"

RGB_STEPS=8
# Can take up to 10 steps with these settnngs but light is too white in the end.
RGB_START=(215 55 5)
RGB_STEP=(3 13 7)

# RGB Curve 1
#RGB_CURVE_SIZE=18
#RGB_CURVE=(245 24 5\
#	252 38 11 \
#	245 62 9 \
#	242 88 13 \
#	243 124 2\
#	239 141 11)

# RGB Curve 2
#RGB_CURVE_SIZE=27
#RGB_CURVE=(255 187 123\
#	255 190 127 \
#	255 198 144 \
#	255 215 174 \
#	255 235 209 \
#	255 241 223 \
#	255 244 232 \
#	255 245 236 \
#	255 249 249)

STARTING_INTENSITY=1
INT_INC_TIME=3000

#Ask for input ugin zenity
Z_ALARM_HOUR=$(zenity --list --radiolist --width=70 --height=400 --text \
	"<b>Please</b> select time for alarm (hours):" \
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
        FALSE "23")

if  [ "$Z_ALARM_HOUR" != "" ]
then
	Z_ALARM_MIN=$(zenity --list --radiolist --width=70 --height=400 --text \
        "<b>Please</b> select time for alarm (minutes):" \
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


while [[ "$Z_ALARM_HOUR" != ""  && "$Z_ALARM_MIN" != "" ]]; do

	DATE=$(eval "date +\"%T\"")
	echo "Timestamp: " $DATE

	#Start alarm
	if [ $(date +%H) = $Z_ALARM_HOUR ] && [ $(date +%M) = $Z_ALARM_MIN ]
	then 
		echo "Alarm got off at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt

		# Ramping up bulb
		while true; do
			# Await the correct return value of OK: '{"method":"props","params":{"power":"on"}}'
                        RET_VAL=$(echo -ne '{"id":1,"method":"set_power","params":["on","smooth",80000]}\r\n' | nc -w1 192.168.1.150 55443)

                        echo "RET_VAL=$RET_VAL" >> ~/Desktop/log.txt

			if ( echo "$RET_VAL" | grep -q "on" )
			then 
				echo "yes, RET_VAL=$RET_VAL"
				 break
			else
				echo "no, RET_VAL=$RET_VAL"
			fi
			sleep 3
                done

		# Set intensity to minimal 1%.
		while true; do
			RET_VAL=$(echo -ne '{"id":1,"method":"set_bright","params":['$STARTING_INTENSITY',"sudden",0]}\r\n' | nc -w1 192.168.1.150 55443)
			if ( echo "$RET_VAL" | grep -q "bright" )
                        then 
                                echo "Set intensity: $RET_VAL"
                                break
                        else
                                echo "Failed to set intensity:$RET_VAL"
				# Maybe because the intensity is the same.
				RET_VAL=$(echo -ne '{"id":1,"method":"get_prop","params":["bright"]}\r\n' | nc -w1 192.168.1.150 55443)
				echo "Reading intensity: $RET_VAL"	

				if ( echo "$RET_VAL" | grep -q '"1"')
				then
					echo "Intensity already set to " $STARTING_INTENSITY
					break
				fi
                        fi
                        sleep 1
		done

                # Set starting color of bulb.
                #let COLOR=${RGB_START[0]}*65536+${RGB_START[1]}*256+${RGB_START[2]}
                #echo -ne '{"id":1,"method":"set_rgb","params":['$COLOR',"sudden",0]}\r\n' | nc -w1 192.168.1.150 55443
		# Loop over RGB_CURVE
		#RGB_COUNTER=0
		#while [ $RGB_COUNTER -lt $RGB_CURVE_SIZE ]; do
		#	let COLOR=${RGB_CURVE[$RGB_COUNTER]}*65536+${RGB_CURVE[$RGB_COUNTER+1]}*256+${RGB_CURVE[$RGB_COUNTER+2]}
		#	RET_VAL=$(echo -ne '{"id":1,"method":"set_rgb","params":['$COLOR',"sudden",0]}\r\n' | nc -w1 192.168.1.150 55443)
	        #       echo "RET_VAL=$RET_VAL"
		#	echo "RGB=$COLOR"
		#	echo "Counter=$RGB_COUNTER"
		#	let RGB_COUNTER=RGB_COUNTER+3
		#	sleep 3
		#done

		RGB_COUNTER=0
		let INT_STEP=80/$RGB_STEPS
		let INT=$STARTING_INTENSITY+$INT_STEP

                while [ $RGB_COUNTER -lt $RGB_STEPS ]; do
                       	let COLOR_R=${RGB_START[0]}+${RGB_STEP[0]}*RGB_COUNTER
			let COLOR_G=${RGB_START[1]}+${RGB_STEP[1]}*RGB_COUNTER
			let COLOR_B=${RGB_START[2]}+${RGB_STEP[2]}*RGB_COUNTER
			let COLOR=$COLOR_R*65536+$COLOR_G*256+$COLOR_B

                       	RET_VAL=$(echo -ne '{"id":1,"method":"set_rgb","params":['$COLOR',"sudden",0]}\r\n' | nc -w1 192.168.1.150 55443)
                       	let RGB_COUNTER=RGB_COUNTER+1

			# Increase intensity also, do this stepwise.
	                while true; do
	                        RET_VAL=$(echo -ne '{"id":1,"method":"set_bright","params":['$INT',"smooth",'$INT_INC_TIME']}\r\n' | nc -w1 192.168.1.150 55443)
	                        if ( echo "$RET_VAL" | grep -q "bright" )
	                        then 
	                                echo "Set intensity: $RET_VAL"
					let INT=$INT+$INT_STEP
	                                break
	                        else
	                                echo "Failed to set intensity:$RET_VAL"
	                        fi
	                        sleep 1
	                done

                       	sleep 3
                done

                zenity --timeout 900 --info --width 200 --height 200 --text "Alarm sounding for 15 minutes. Press ok to stop."

                #Turn of bulb slowly after at most 15 minutes.
                echo -ne '{"id":1,"method":"set_power","params":["off","smooth",5000]}\r\n' | nc -w1 192.168.1.150 55443

		echo "Alarm loop done at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt
		sleep 1
		exit 0
	else 
		echo "Alarm not going off yet"
	fi

	sleep 20
done

echo "Alarm loop failed at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt

