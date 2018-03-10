#!/bin/bash


declare -a DEVICESARRAY

createMenu(){
	IFS=$'\n'
	echo "SELECT USB USING THE NUMBERS PROVIDED ON THE LEFT:"
	count=0

	for device in `ls -l /dev/disk/by-uuid/ | grep -E 'sdb|sdc'`
	do
		mountPath=`echo $device | tr -s ' '|cut -f11 -d ' '|cut -f3 -d '/'`	
		#Query using udevadmin for :
		#	udev data--> [ATTRS{idVendor} & ATTRS{idProduct}]
		#	display data--> [Label(ID_VENDOR)]
		#	fstab data--> [mount path dev/sd+]
		deviceDetails=`udevadm info --query=all --name "/dev/$mountPath"`
		# display
		label=`echo "$deviceDetails" | grep  ID_FS_LABEL=| cut -f2 -d '=' `
		vendor=`echo "$deviceDetails" | grep  ID_VENDOR=| cut -f2 -d '=' `
		DEVICESARRAY[count]=$mountPath
		
		# udev
		idVendor=`echo "$deviceDetails" | grep  ID_VENDOR_ID=| cut -f2 -d '=' `
		idProduct=`echo "$deviceDetails" | grep  ID_MODEL_ID=| cut -f2 -d '=' `

		# fstab
		path="/dev$mountPath"

		# echo $label $vendor $idVendor $idProduct
		echo "$count ------> $label($vendor)"
		let "count+=1"

	done
	if [[ $count -eq 0 ]]; then
		echo -e "\t\t No usb device detected.Insertt usb device and restart the script.\nExiting....!!!"
		exit 1
	fi
	
	

}


main(){
	createMenu
	read choice
	if [[ $choice -le $count ]]; then
		#statements
		selected=${DEVICESARRAY[$choice]}
		deviceDetails=`udevadm info --query=all --name "/dev/$selected"`
		# display
		label=`echo "$deviceDetails" | grep  ID_FS_LABEL=| cut -f2 -d '=' `
		vendor=`echo "$deviceDetails" | grep  ID_VENDOR=| cut -f2 -d '=' `
		DEVICESARRAY[count]=$mountPath
		
		# udev
		idVendor=`echo "$deviceDetails" | grep  ID_VENDOR_ID=| cut -f2 -d '=' `
		idProduct=`echo "$deviceDetails" | grep  ID_MODEL_ID=| cut -f2 -d '=' `

		# fstab
		path="/dev$mountPath"

		echo "$label($vendor)  $idVendor $idProduct"
	else
		echo -e "\t\tInvalid choice!!!"
		main
	fi

}

main
