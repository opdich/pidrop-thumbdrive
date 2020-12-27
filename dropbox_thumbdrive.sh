
#!/bin/bash

function setWifi
{
	file=/etc/wpa_supplicant/wpa_supplicant.conf

	#Get the users SSID and pass
	echo -ne "Wifi SSID: "
	read -r WIFI_SSID
	echo -ne "Wifi Password: "
	read -r WIFI_PASS

	# Set it in the file
	echo "country=US" | sudo tee -a $file >/dev/null
	echo "network={" | sudo tee -a $file >/dev/null
	echo '	ssid="'$WIFI_SSID'"' | sudo tee -a $file >/dev/null
	echo '	psk="'$WIFI_PASS'"' | sudo tee -a $file >/dev/null
	echo "}" | sudo tee -a $file >/dev/null
}
setWifi
