#!/bin/bash

# Check for upstart
# Check for mountall
MYUID=`id -u`
MYGID=`id -g`




function install(){
	# Check init dir
	`mkdir -p $HOME/bin/` # Path storing the executble file
	`mkdir -p $HOME/.config/`
	`sudo mkdir -p /opt/exgit/`

	echo "All required DIRS available"
	# export PATH="$HOME/bin:$PATH"
	`mkdir -p $HOME/.config/exgit`
	`sudo chown $MYUID:$MYGID $HOME/.config/exgit`

	# # Create source file and source itf
	# echo "export PATH=$HOME/bin:$PATH" > $CWD/sourcefile
	# `source sourcefile`	

					# ----LOG ----
	# Create /opt/exgit/exgit.log file - Used for logging exgit operations
	if [[ ! -e $HOME/.config/exgit/exgit.log ]]; then
	    `touch $HOME/.config/exgit/exgit.log`
	fi
	
	`sudo chown $MYUID:$MYGID $HOME/.config/exgit/exgit.log`
	
	LOG_FILE="$HOME/.config/exgit/exgit.log"
	exec 3>&1 1>>${LOG_FILE} 2>&1
	echo "Created log file at $HOME/.config/exgit/exgit.log"  | tee /dev/fd/3
	

	# Create /opt/exgit/exgit.txt file
	# Used to store relationship bwtween a specific drive to its repos and their git remote names
	if [[ ! -e $HOME/.config/exgit/exgit.txt ]]; then
	    `touch $HOME/.config/exgit/exgit.txt`
	fi

	`sudo chown $MYUID:$MYGID $HOME/.config/exgit/exgit.txt`
	echo "Created storage file $HOME/.config/exgit/exgit.txt"

	if grep -Fq "home=$HOME" $CWD/exgit_sync.conf
			then
			echo "home=$HOME" |  tee -a "$HOME/.config/exgit/exgit.txt" # Storinng the path to home directory since initctl/SYSTEMD service may not be able to access $HOME variable as daemon
	fi
	# store $HOME path in a file to be sourced later since initctl service wont be able to access $HOME variable
	#hence it is placed in a path easily accessible and omnipresent
	
	# `sudo touch /opt/exgit/exgit.txt`
	# `sudo chown $MYUID:$MYGID /opt/exgit/exgit.txt`
	# echo "export HOMEPATH=/home/stewie" |sudo  tee "/opt/exgit/exgit.txt"
	

	echo "Created DIR $HOME/bin and exported PATH" | tee /dev/fd/3
	
	echo "Creating exgit service  file...."  | tee /dev/fd/3
	# nohup /path/to/your/script.sh > /dev/null 2>&1

	# Create Service file entry 

	#Checking the init sytem used by OS
	if [ $INITSYS == "initctl" ];then
		# ----UPSTART---
		# Creating exgit_sync.conf for upstart to execute the script
		EXECLINE="exec $HOME/bin/exgit autopush \$P"

		# Check if entry exists
		if grep -Fq "$EXECLINE" $CWD/exgit_sync.conf
			then
			echo "exec entry exists.Ignoring" | tee /dev/fd/3
		else
			echo "Adding exec entry......" | tee /dev/fd/3	

			#Adding the execline to exgit_sync.conf in current repo DIR					
			echo "$EXECLINE" |  tee -a "$CWD/exgit_sync.conf"
		fi

		# Copying exgit_sync.conf file to upstarts init dir /etc/init
		`sudo install $CWD/exgit_sync.conf  /etc/init/`
		echo "exgit_sync upstart service created successfully" | tee /dev/fd/3

		# Activating the newly added exgit_sync.conf file
		echo "Reloading initctl configuration..." | tee /dev/fd/3
		`sudo initctl reload-configuration`

	elif [ $INITSYS == "systemd" ]; then
		# --- SYSTEMD---
		EXECLINE="ExecStart=/home/stewie/bin/exgit autopush \$MOUNTPATH"

		if grep -Fq "$EXECLINE" $CWD/exgit@.service
			then
			echo "ExecStart entry exists.Ignoring" | tee /dev/fd/3
		else
			echo "Adding ExecStart entry......" | tee /dev/fd/3	

			#Adding the execline to exgit_sync.conf in current repo DIR						
			echo "$EXECLINE" |  tee -a "$CWD/exgit@.service"
		fi
		# Copying exgit@.service file to systemd init dir /etc/systemd/user
		`sudo install $CWD/exgit@.service  /etc/systemd/user/`
		echo "Exgit@ systemd service created successfully" | tee /dev/fd/3

		# ///////////////////////////////////////////////////////////////////
		# Reload systemctl

	fi
	
	# Instaling/Copying 'exgit' exec file to their exec dir ($HOME/bin/) and giving them exec permissions
	echo "Instaling exgit to $HOME/bin/" | tee /dev/fd/3	
	`sudo install $CWD/exgit  $HOME/bin/`
	`sudo chmod +777 $HOME/bin/exgit`
	echo "Exgit installed in $HOME/bin/" | tee /dev/fd/3


	# Exporting the path to HOME/Bin to enable exgit be executed from bash commandline
	if grep -Fq ":$HOME/bin" $HOME/.bashrc
		then
			echo "$HOME/bin path exists" | tee /dev/fd/3						
	else
		echo export "PATH=$PATH:$HOME/bin" >> "$HOME/.bashrc"
		echo "Adding $HOME/bin to PATH on .bashrc" | tee /dev/fd/3
	fi
	source "$HOME/.bashrc"

	echo "Exgit installed successfully." | tee /dev/fd/3

}


function housekeep(){
	CWD=$PWD
	
	# Check fstab dir
	if [[ -f /etc/fstab ]]; then
		# Check udev dir
		if [[ -d /etc/udev/rules.d/ ]]; then
			# Check $HOME/bin dir
			if [[ -d /etc/init/ ]]; then
				# check if initctl exists
				if [ -x "$(command -v initctl)" ]; then
				  echo 'initctl installed.'
				  INITSYS="initctl"
				  install 
				elif [[ `systemctl` =~ -\.mount ]]; then 
					echo 'systemd installed'
					INITSYS="systemd"
					install
				else
					echo "Initctl or systemd not detected"
					exit 1
				fi
				
			else
				echo "/etc/init DIR not found."
				exit 0

			fi
		else
			echo "/etc/udev/rules.d/ DIR not found."
			exit 0 
		fi
	else
		echo "/etc/fstab file not found."
		exit 0 
	fi

}

housekeep


