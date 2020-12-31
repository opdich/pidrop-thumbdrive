
#!/bin/bash

#Setup global vars
PIDROP_BIN=/pidrop.bin
PIDROP_DIR=/mnt/pi_drop

#Define files
WPA=/etc/wpa_supplicant/wpa_supplicant.conf
CONFIG=/boot/config.txt
CMDLINE=/boot/cmdline.txt
MODULES=/etc/modules
RC=/etc/rc.local

function setupWifi
{
	echo "Checking for internet access..."
	#ref: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md
	
	#Check to see if connected to internet
	#ref: https://stackoverflow.com/questions/17291233/how-to-check-internet-access-using-bash-script-in-linux
	wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
	if [[ $? -eq 0 ]]; then
		echo "Connected"
	else
		echo "Connect to a wifi network..."

		#Get the users wifi info
		echo "Country code: "
		read -r COUNTRY_CODE
		echo "Wifi SSID: "
		read -r WIFI_SSID
		echo "Wifi Password: "
		read -r WIFI_PASS

		# Set it in the file
		echo 'country="'$COUNTRY_CODE'"' | sudo tee -a $WPA >/dev/null
		echo "network={" | sudo tee -a $WPA >/dev/null
		echo '	ssid="'$WIFI_SSID'"' | sudo tee -a $WPA >/dev/null
		echo '	psk="'$WIFI_PASS'"' | sudo tee -a $WPA >/dev/null
		echo "}" | sudo tee -a $WPA >/dev/null

		#Reconfigure the network interface to connect to wifi
		wpa_cli -i wlan0 reconfigure

		#Check internet again
		wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
		if [[ $? -eq 0 ]]; then
			echo "New wifi connected"
		else
			echo "Please check your wifi settings and try again"
			exit 0
		fi
	fi
}

function downloadLibs 
{
	echo "Installing necessary libraries..."
	#ref: https://www.waveshare.com/wiki/2.13inch_e-Paper_HAT
	#ref: https://github.com/andreafabrizi/Dropbox-Uploader
	
	#Via apt
	sudo apt install curl git python3-pip python3-pil python3-numpy
	#Via pip
	sudo pip3 install RPi.GPIO
	sudo pip3 install spidev
	#Via git
	sudo git clone https://github.com/andreafabrizi/Dropbox-Uploader.git
	sudo git clone https://github.com/waveshare/e-Paper

	echo "Libraries installed"
}

function setupSharedDir
{
	echo "Setup the thumbdrive..."
	#ref: https://magpi.raspberrypi.org/articles/pi-zero-w-smart-usb-flash-drive

	#Get thumbdrive size
	####TO DO: Display maximum size
	echo "How big should the thumbdrive be (in bytes): "
	read -r TD_SIZE
	echo "Setting up the new partition. This will take a bit..."

	#Create the directory
	sudo dd bs=1M if=/dev/zero of=$PIDROP_BIN count=$TD_SIZE
	sudo mkdosfs $PIDROP_BIN -F 32 -I
	sudo mkdir $PIDROP_DIR
	
	echo "PiDrop partition configured"
}

function configureFiles
{
	echo "Configuring files..."
	#ref: https://stackoverflow.com/questions/44053344/g-multi-mode-mass-storage-ethernet-not-working-on-raspberry-pi-zero-w
	#ref: https://gist.github.com/gbaman/50b6cca61dd1c3f88f41#gistcomment-1822387
	#ref: https://gist.github.com/gbaman/50b6cca61dd1c3f88f41#gistcomment-2850936
	#ref: https://raspberrypi.stackexchange.com/questions/79699/g-mass-storage-on-rpi-zerow-is-readonly-use-as-usb-stick

	#Activate SPI
	lsmod | grep -q spi_
	if [[ $? -eq 0 ]]; then
		echo "SPI is already active"
	else
		echo "dtparam=spi=on" | sudo tee -a $CONFIG >/dev/null
		echo "SPI activated"
	fi

	#Modify cmdline.txt
	#Remove any module declaration (if it exists)
	###TODO: remove all preceeding spaces
	sudo sed -i 's/[[:blank:]]modules-load[[:alnum:]=,_]*//g' $CMDLINE

	#Set the modules-load to only dwc2
	sudo sed -i '/rootwait/s/$/ modules-load=dwc2/g' $CMDLINE

	#Configure /etc/modules
	sudo touch $MODULES
	echo "dwc2" | sudo tee -a $MODULES >/dev/null
	echo "g_multi" | sudo tee -a $MODULES >/dev/null

	#Setup rc.local
	sudo sed -i '/exit 0/s/^/sleep 5\n/g' $RC
	sudo sed -i '/exit 0/s,^,sudo modprobe g_multi file='"$PIDROP_BIN"' stall=0 removable=1 ro=0\n,g' $RC
	
	echo "g_multi module configured"
}


setupWifi
downloadLibs
setupSharedDir
configureFiles