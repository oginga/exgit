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
		
		# echo $label $vendor $idVendor $idProduct
		echo "$count ------> $label($vendor)"
		let "count+=1"

	done
	if [[ $count -eq 0 ]]; then
		echo -e "\t\t No usb device detected.Insert flash and restart the script.\nExiting....!!!"
		exit 1
	fi
	
	

}


add_udev_rule(){

	# change dir to  udev rules.d
	echo -e "\t----$PWD----"
	RULE="SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\""$idVendor"\", ATTRS{idProduct}==\""$idProduct"\", RUN+=\"/home/stewie/PROJECTS/exgit/clock.py\""

	#TO-DO check for existence of entry else create a new file to hold our rules
	echo "$RULE" | sudo tee -a "/etc/udev/rules.d/10-exgit.rules"

}

add_fstab_entry(){
	uid=`id -u`
	gid=`id -g`


	# Prepare mount directory
	`mkdir /media/exgit`
	`chown $uid:$uid /media/exgit`
	`chmod -R 777 /media/exgit`

	ENTRY="UUID=$uuid    /media/exgit/    $file_sys_type uid=$uid,gid=$gid,noauto,exec,umask=000 0 0"

	#TO-DO check for existence of entry else create a new entry
	echo "$ENTRY" | sudo tee -a "/etc/fstab"

}

mount_flashdrive(){
	`udisksctl mount -b /dev/$selected`
}

init_bare_repo(){
	`cd /media/exgit`
	`mkdir /media/exgit/EXGIT`
	`git init --bare /media/exgit/EXGIT/$repo_name`
}

function get_repo_name(){
	# init bare repo on flashd-rive
	echo "Enter name of repository.Repository will be initiated on both the flashdrive and the current DIR!: "
	read repo_name
	
	if [ -z "$repo_name" ]
	then
		get_repo_name 
	else
	    rn=$repo_name
	fi
}

clone_repo(){
	`cd $current_path`
	`git clone /media/exgit/EXGIT/$rn`
}

set_remote(){
	# `cd $PWD`
	`git remote set-url origin file://media/exgit/EXGIT/$rn`
}


main(){
	current_path=$PWD
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
		uuid=`echo "$deviceDetails" | grep  ID_FS_UUID=| cut -f2 -d '=' `
		file_sys_type=`echo "$deviceDetails" | grep  ID_FS_TYPE=| cut -f2 -d '=' `

		echo "$label($vendor)  $idVendor $idProduct $uuid $file_sys_type"
		
		add_udev_rule $idVendor $idProduct
		# Had issues creating symbolic links with udev hence resorted to fstab for predetermined mount dir
		add_fstab_entry $uuid $file_sys	_type
		mount_flashdrive $selected

		# Init repo
		get_repo_name
		init_bare_repo $rn
		clone_repo $rn
		set_remote $rn


	else
		echo -e "\t\tInvalid choice!!!"
		main
	fi

}


main
