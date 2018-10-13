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

#Ask for input ugin zenity
Z_ALARM_HOUR=$(zenity --list --radiolist --width=70 --height=500 --text \
	"<b>Please</b> select time for alarm (hours):" \
        --hide-header --column "Select" --column "Hour" \
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
	FALSE "$(date +%M)" \
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
#		echo $W_TIME_START_2
		echo "Alarm set to: $W_TIME_START_2" >> ~/Desktop/log.txt
	else 
		zenity --info --text "Alarm not set. Exiting"
	fi
else 
	zenity --info --text "Alarm not set. Exiting"
fi

while [[ "$Z_ALARM_HOUR" != ""  && "$Z_ALARM_MIN" != "" ]]; do
	DATE=$(eval "date +\"%T\"")

	echo "Timestamp: " $DATE >> ~/Desktop/log.txt

	#Start alarm
	echo $(date +%H) " " $Z_ALARM_HOUR " " $(date +%M) " " $Z_ALARM_MIN
        echo $(date +%H) " " $Z_ALARM_HOUR " " $(date +%M) " " $Z_ALARM_MIN >> ~/Desktop/log.txt

	if [ $(date +%H) = $Z_ALARM_HOUR ] && [ $(date +%M) = $Z_ALARM_MIN ]
	then 
		echo "Alarm got off at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt
                zenity --timeout 5 --info --text "Alarm is sounding in 5s"

		# Ramping up bulb over 2 minutes
		#COMP_VAL='{"id":1, "result":["ok"]}'


		while true; do
			#Await the correct return value of OK: '{"method":"props","params":{"power":"on"}}'
			if ( echo "$RET_VAL" | grep -q "on" )
			then 
				echo "yes,  RET_VAL=$RET_VAL"
				 break
			else
				echo "no, RET_VAL=$RET_VAL"
			fi
			echo "RET_VAL=$RET_VAL" >> ~/Desktop/log.txt
			echo "RET_VAL=$RET_VAL" 
			RET_VAL=$(echo -ne '{"id":1,"method":"set_power","params":["on","smooth",120000]}\r\n' | nc -w1 192.168.1.150 55443)
			sleep 5
                done

		#i=0
		#while [i -lt 3]; do
		#	echo "$RET_VAL" >> ~/Desktop/log.txt
       	      	#	RET_VAL=$(echo -ne '{"id":1,"method":"set_power","params":["on","smooth",120000]}\r\n' | nc -w1 192.168.1.150 55443)
		#	sleep 2;
		#done

		zenity --timeout 900 --info --text "Alarm sounding press ok within 15minutes to turn off light"
                #Turn of bulb slowly after at most 15 minutes.
                echo -ne '{"id":1,"method":"set_power","params":["off","smooth",5000]}\r\n' | nc -w1 192.168.1.150 55443

		echo "Alarm loop done at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt
		sleep 1
		exit 0
	else 
		echo "no"
	fi

	sleep 50
done

echo "Alarm loop failed at: " $(eval "date +\"%T\"") >> ~/Desktop/log.txt

