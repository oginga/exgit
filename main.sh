#!/bin/bash


declare -a DEVICESARRAY
ACTION=$1
REPONAME=$2
THIS_USER=$USER

function createMenu(){
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


function add_udev_rule(){

	# change dir to  udev rules.d
	echo -e "\t----$PWD----"
	RULE="ACTION==\"add\", SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\""$idVendor"\", ATTRS{idProduct}==\""$idProduct"\", RUN+=\"/home/stewie/PROJECTS/exgit/main.sh autopush\""

	#TO-DO check for existence of entry else create a new file to hold our rules
	if [[ ! -f /etc/udev/rules.d/10-exgit.rules ]]; then
		echo "Adding exgit udev rule......"
		echo "$RULE" | sudo tee -a "/etc/udev/rules.d/10-exgit.rules" >> /dev/null 2>&1
		
	else
		if sudo grep -Fq "$RULE" /etc/udev/rules.d/10-exgit.rules
			then
			echo
		else
			echo "Adding exgit udev rule......"
			echo "$RULE" | sudo tee -a "/etc/udev/rules.d/10-exgit.rules" >> /dev/null 2>&1
			
		fi	

	fi
	
}

function add_fstab_entry(){
	uid=`id -u`
	gid=`id -g`


	# Prepare mount directory
	if [[ ! -d /media/exgit/ ]]; then
		`sudo mkdir /media/exgit`
		`sudo chown $MYUID:$MYGID /media/exgit`
		`sudo chmod -R 777 /media/exgit`
	fi

	

	ENTRY="UUID=$uuid    /media/exgit/    $file_sys_type uid=$uid,gid=$gid,noauto,exec,umask=000 0 0"

	#TO-DO check for existence of entry else create a new entry
	if sudo grep -Fq "$RULE" /etc/fstab
		then
		echo 
	else
		echo "Adding fstab entry......"
		echo "$ENTRY" | sudo tee -a "/etc/fstab" >> /dev/null 2>&1
		
	fi
	

}

function mount_flashdrive(){
	# Ignore error raised
	# echo `udisksctl mount -b /dev/$selected` | sudo tee -a "/home/stewie/PROJECTS/exgit/logging.txt"
	echo "<----mounting" | sudo tee -a "/home/stewie/PROJECTS/exgit/logging.txt"
	`udisksctl mount -b /dev/$selected >> /dev/null 2>&1`
}

function init_bare_repo(){
	`cd /media/exgit`
	if [[ ! -d /media/exgit/EXGIT/ ]]; then
		`sudo mkdir /media/exgit/EXGIT`
		`sudo chown $MYUID:$MYGID /media/exgit/EXGIT`
	fi
	
	`git init --bare /media/exgit/EXGIT/$repo_name `
	`sudo chown $MYUID:$MYGID /media/exgit/EXGIT/$repo_name`
}

function get_repo_name(){
	# init bare repo on flashd-rive
	echo "Enter name of repository.Repository will be initiated on both the flashdrive and the current DIR!: "
	read repo_name

	# validade repo name for dir name regex
	
	if [ -z "$repo_name" ]
	then
		get_repo_name 
	else
	    rn=$repo_name
	fi
}

function clone_repo(){
	`cd $current_path`
	`git clone /media/exgit/EXGIT/$rn`
	`sudo chown $MYUID:$MYGID /media/exgit/EXGIT/$rn`
}

function set_remote(){
	# `cd $PWD`
	`git remote set-url origin file://media/exgit/EXGIT/$rn`

}

function init_configs(){
	current_path=$PWD
	MYUID=`id -u`
	MYGID=`id -g`
}

function init_flash(){
	init_configs
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

		# echo "$label($vendor)  $idVendor $idProduct $uuid $file_sys_type"
		
		add_udev_rule $idVendor $idProduct
		# Had issues creating symbolic links with udev hence resorted to fstab for predetermined mount dir
		add_fstab_entry $uuid $file_sys	_type
		mount_flashdrive $selected
	else
		echo -e "\t\tInvalid choice!!!"
		main
	fi

}


function init_new_repo(){
		init_flash

		# Init repo
		get_repo_name
		init_bare_repo $rn
		clone_repo $rn
		set_remote $rn
		remote="origin"
		slash="/"
		pathtorepo=$current_path$slash$rn

		store_repo_details $rn $remote $pathtorepo

}


function local_to_flash(){
	init_flash

	# Breakdown the $PWD to get repo name
	repo_name=$(basename $current_path)

	# Change dir to flashdrive
	cd /media/exgit/EXGIT

	# Clone as bare existing repo
	`git clone --bare $current_path $repo_name`

	# Change ownership to user 
	`sudo chown $MYUID:$MYGID /media/exgit/EXGIT/$repo_name`

	cd $current_path

	# Set remote
	`git remote add usb /media/exgit/EXGIT/$repo_name/`

	remote="usb"
	slash="/"
	pathtorepo=$current_path$slash$rn

	store_repo_details $rn $remote $pathtorepo

	`notify-send  -u NORMAL EXGIT "$repo_name initiated successfully"`

}


function store_repo_details(){
	# check if dir and file exists
	echo "Storing data"
	delimmiter=","
	# str concat
	ROW=$repo_name$delimmiter$remote$delimmiter$pathtorepo

	if [[ ! -d /opt/exgit/ ]]; then
		# echo "DOes not exist"
		#create folder and file
		`sudo mkdir /opt/exgit`
		`sudo touch exgit.txt`
		echo "$ROW" | sudo tee -a "/opt/exgit/exgit.txt" >> /dev/null 2>&1
	else
		# check if file exists
		if [[ ! -f /opt/exgit/exgit.txt ]]; then
			#create file
			`sudo touch exgit.txt`
			echo "$ROW" | sudo tee -a "/opt/exgit/exgit.txt" >> /dev/null 2>&1
		else
			# check if entry exists
			# exists= $( echo `grep "$repo_name" "/opt/exgit/exgit.txt"`)
			echo $exists
			if grep -Fq "$repo_name" /opt/exgit/exgit.txt
				then
					echo "Entry exists"	
			else
				# echo "Entry does not exist"
				echo "$ROW" | sudo tee -a "/opt/exgit/exgit.txt" >> /dev/null 2>&1
				
			fi

		fi
	fi
	
}

function sync_repos(){
	echo "<--Syncing repos-->" | sudo tee -a "/home/stewie/PROJECTS/exgit/logging.txt"
	for DIR in $(find /media/exgit/EXGIT -maxdepth 1);
		do 
			if $(test -d ${DIR}); then 
				# echo $(basename ${DIR}); 
				repo_name=$(basename ${DIR})
				# echo $repo_name
				# check if we have this repo localy
				if grep -Fq "$repo_name" /opt/exgit/exgit.txt
					then
						echo "Entry exists"
						entry=$( echo `grep "$repo_name" "/opt/exgit/exgit.txt"`)
						
						remote=`echo "$entry" | cut -f2 -d ',' `
						path=`echo "$entry" | cut -f3 -d ',' `

						# 
						if $(test -d ${path}); then
							echo "Pushing...."
							`git push "$remote" master`

							`notify-send  -u NORMAL EXGIT "$repo_name pushed successfully"`
						fi

				fi
				


			fi; 
	done
	#



}

function peform_checks(){


	if [[ ! -f /opt/exgit/exgit.txt ]]; then
			#notify unable
			echo "Error: /opt/exgit/exgit.txt unavailable"
			`notify-send  -u NORMAL EXGIT "Error: /opt/exgit/exgit.txt unavailable"`
			exit 0
	fi

	if [[ ! -d /media/exgit/EXGIT ]]; then
			echo "EXGIT folder missing on drive OR drive not mounted/inserted"
			`notify-send  -u NORMAL EXGIT "EXGIT folder missing on drive OR drive not mounted/inserted"`
			exit 0

	fi
	echo "<---Checks passed--->" | sudo tee -a "/home/stewie/PROJECTS/exgit/logging.txt"


}

auto_push(){
	echo "starting--->" > /home/stewie/PROJECTS/exgit/logging.txt
	selected="sdb1"
	mount_flashdrive $selected
	peform_checks
	sync_repos
	echo "<----ending" | sudo tee -a "/home/stewie/PROJECTS/exgit/logging.txt"
}




# CDIR= # command for current dir
# LOCAL=
# REMOTE=

case $ACTION in
	"init" )
			init_new_repo "$REPONAME"
		;;
	"ltof" )
			local_to_flash "$REPONAME" 
		;;
	"ftol" )
			FlashToLocal "$REPONAME"
		;;
		# push to flash autoated
	"autopush" ) 
			auto_push
		;;

esac

