#!/bin/bash

# Check for upstart
# Check for mountall
MYUID=`id -u`
MYGID=`id -g`

function housekeep(){
	CWD=$PWD
	
	# Check fstab dir
	if [[ -f /etc/fstab ]]; then
		# Check udev dir
		if [[ -d /etc/udev/rules.d/ ]]; then
			# Check $HOME/bin dir
			if [[ -d /etc/init/ ]]; then
				# check if initctl exists
				if ! [ -x "$(command -v initctl)" ]; then
				  echo 'Error: initctl is not installed.'
				  exit 1
				else
					# Check init dir
					`mkdir -p $HOME/bin/`
					`mkdir -p $HOME/.config/`
					`sudo mkdir -p /opt/exgit/`

					echo "All required DIRS available"
					# export PATH="$HOME/bin:$PATH"
					`mkdir -p $HOME/.config/exgit`
					`sudo chown $MYUID:$MYGID $HOME/.config/exgit`

					# # Create source file and source it
					# echo "export PATH=$HOME/bin:$PATH" > $CWD/sourcefile
					# `source sourcefile`
					
					# Create /opt/exgit/exgit.txt file
					# Used to store relationship bwtween a specific drive to its repos and their git remite names
					`touch $HOME/.config/exgit/exgit.txt`
					echo "Created storage file $HOME/.config/exgit/exgit.txt"
					# Create /opt/exgit/exgit.log file
					#  Used for lgging operation progress
					`touch $HOME/.config/exgit/exgit.log`
					`sudo chown $MYUID:$MYGID $HOME/.config/exgit/exgit.txt`

					# Storinng the path to home directory since initctl service wont be able to access $HOME variable
					echo "home=$HOME" |  tee -a "$HOME/.config/exgit/exgit.txt"
					`sudo chown $MYUID:$MYGID $HOME/.config/exgit/exgit.log`

					# store $HOME path in a file to be sourced later since initctl service wont be able to access $HOME variable
					#hence it is placed in a path easily accessible and omnipresent
					`sudo touch /opt/exgit/exgit.txt`
					`sudo chown $MYUID:$MYGID /opt/exgit/exgit.txt`
					echo "export HOMEPATH=/home/stewie" |sudo  tee -a "/opt/exgit/exgit.txt"


					LOG_FILE="$HOME/.config/exgit/exgit.log"
					exec 3>&1 1>>${LOG_FILE} 2>&1

					echo "Created DIR $HOME/bin and exported PATH" | tee /dev/fd/3
					echo "Created log file at $HOME/.config/exgit/exgit.log"  | tee /dev/fd/3
					echo "Creating exgit upstart conf  file at /etc/init/"  | tee /dev/fd/3
					# nohup /path/to/your/script.sh > /dev/null 2>&1

					# Create service entry on exgit_sync.conf for upstart to execute the script
					#Check if entry exists
					EXECLINE="exec $HOME/bin/exgit autopush \$P"

					if grep -Fq "$EXECLINE" $CWD/exgit_sync.conf
						then
						echo "exec entry exists.Ignoring" | tee /dev/fd/3
					else
						echo "Adding exec entry......" | tee /dev/fd/3	

						#Creating the exgit_sync.conf from the current install DIR					
						echo "$EXECLINE" |  tee -a "$CWD/exgit_sync.conf"
					fi
					
					# Instaling/Copying neccessary files to their respective directories and giving them exec permissions
					`sudo install $CWD/exgit_sync.conf  /etc/init/`
					echo "exgit_sync file created successfully" | tee /dev/fd/3
					`sudo install $CWD/exgit  $HOME/bin/`
					`sudo chmod +777 $HOME/bin/exgit`

					# Activating the newly aded .conf file
					echo "Reloading initctl configuration..." | tee /dev/fd/3
					`sudo initctl reload-configuration`

					# Exporting the path to HOME/Bin to enable exgit be executed from bash commandline
					echo export "PATH=$PATH:$HOME/bin" >> "$HOME/.bashrc"
					source "$HOME/.bashrc"

					echo "Exgit installed successfully." | tee /dev/fd/3
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