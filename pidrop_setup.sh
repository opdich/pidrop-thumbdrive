
#!/bin/bash

# Setup global vars
PIDROP_BIN=/pidrop.bin
PIDROP_DIR=/mnt/pi_drop

# Define files
WPA=/etc/wpa_supplicant/wpa_supplicant.conf
CONFIG=/boot/config.txt
CMDLINE=/boot/cmdline.txt
MODULES=/etc/modules
RC=/etc/rc.local

function setupWifi
{
	echo -ne "Checking for internet access...\n"
	#ref: https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md
	
	# Check to see if connected to internet
	#ref: https://stackoverflow.com/questions/17291233/how-to-check-internet-access-using-bash-script-in-linux
	wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
	if [[ $? -eq 0 ]]; then
		echo -ne "Connected\n\n"
	else
		echo -ne "Connect to a wifi network...\n"

		# Get the users wifi info
		echo -ne "Country code: \n"
		read -r COUNTRY_CODE
		echo -ne "Wifi SSID: \n"
		read -r WIFI_SSID
		echo -ne "Wifi Password: \n"
		read -r WIFI_PASS

		# Set it in the file
		echo -ne 'country="'$COUNTRY_CODE'"\n' | sudo tee -a $WPA >/dev/null
		echo -ne "network={\n" | sudo tee -a $WPA >/dev/null
		echo -ne '	ssid="'$WIFI_SSID'"\n' | sudo tee -a $WPA >/dev/null
		echo -ne '	psk="'$WIFI_PASS'"\n' | sudo tee -a $WPA >/dev/null
		echo -ne "}\n" | sudo tee -a $WPA >/dev/null

		# Reconfigure the network interface to connect to wifi
		wpa_cli -i wlan0 reconfigure

		# Check internet again
		wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
		if [[ $? -eq 0 ]]; then
			echo -ne "New wifi connected\n\n"
		else
			echo -ne "Please check your wifi settings and try again\n\n"
			exit 0
		fi
	fi
}

function downloadLibs 
{
	echo -ne "Installing necessary libraries...\n"
	#ref: https://www.waveshare.com/wiki/2.13inch_e-Paper_HAT
	#ref: https://github.com/andreafabrizi/Dropbox-Uploader
	
	# Via apt
	sudo apt install curl git python3-pip python3-pil python3-numpy
	# Via pip
	sudo pip3 install RPi.GPIO spidev RxPy3
	# Via git
	sudo git clone https://github.com/andreafabrizi/Dropbox-Uploader.git

	echo -ne "Libraries installed\n\n"
}

function setupSharedDir
{
	echo -ne "Setup the thumbdrive...\n"
	#ref: https://magpi.raspberrypi.org/articles/pi-zero-w-smart-usb-flash-drive

	# Get thumbdrive size
	####TO DO: Display maximum size
	echo -ne "How big should the thumbdrive be (in bytes): \n"
	read -r TD_SIZE
	echo -ne "Setting up the new partition. This will take a bit...\n"

	# Create the directory
	sudo dd bs=1M if=/dev/zero of=$PIDROP_BIN count=$TD_SIZE
	sudo mkdosfs $PIDROP_BIN -F 32 -I
	sudo mkdir $PIDROP_DIR
	
	echo -ne "PiDrop partition configured\n\n"
}

function configureFiles
{
	echo -ne "Configuring files...\n"
	#ref: https://stackoverflow.com/questions/44053344/g-multi-mode-mass-storage-ethernet-not-working-on-raspberry-pi-zero-w
	#ref: https://gist.github.com/gbaman/50b6cca61dd1c3f88f41#gistcomment-1822387
	#ref: https://gist.github.com/gbaman/50b6cca61dd1c3f88f41#gistcomment-2850936
	#ref: https://raspberrypi.stackexchange.com/questions/79699/g-mass-storage-on-rpi-zerow-is-readonly-use-as-usb-stick

	# Activate SPI
	lsmod | grep -q spi_
	if [[ $? -eq 0 ]]; then
		echo -ne "SPI is already active\n"
	else
		echo -ne "\ndtparam=spi=on\n" | sudo tee -a $CONFIG >/dev/null
		echo -ne "SPI activated\n"
	fi

	# Modify cmdline.txt
	# Remove any module declaration (if it exists)
	sudo sed -i 's/[[:blank:]]*modules-load[[:alnum:]=,_]*//g' $CMDLINE

	# Set the modules-load to only dwc2
	sudo sed -i '/rootwait/s/$/ modules-load=dwc2/g' $CMDLINE

	# Configure /etc/modules
	sudo touch $MODULES
	echo -ne "dwc2\n" | sudo tee -a $MODULES >/dev/null
	echo -ne "g_mass_storage\n" | sudo tee -a $MODULES >/dev/null

	# Setup rc.local
	sudo sed -i '/exit 0/s/^/sleep 5\n/g' $RC
	sudo sed -i '/exit 0/s,^,sudo modprobe g_mass_storage  file='"$PIDROP_BIN"' stall=0 removable=1 ro=0\n,g' $RC
	
	echo -ne "g_mass_storage module configured\n\n"
}


setupWifi
downloadLibs
setupSharedDir
configureFiles