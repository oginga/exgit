

# Exgit

Bash driven git wrapper for linux to make automatic git push of your local git repositories whenever an initialized external flashdrive is inserted.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

What things you need to install the software and how to install them

* Linux OS
* upstart

## Installing

Clone this repo and execute the ```install.sh``` file as illustrated below. **DO NOT RUN AS ROOT** ,the script will ask you for root permissions on-the-fly!

```exgit_sync.conf``` contains a template for creating upstart service.

```
#From the current dir(this repo's root)
$ chmod +ax install.sh 

$ ./install.sh

#You will be prompted for root password
```

The install script would add ``` $HOME/bin``` (where exgit executable lies) to ```$PATH```


## Usage
#### 1. Create a new repo(from scratch)
Root permissions will be requested on-the-fly.**DO NOT RUN AS ROOT**

```
#init -- initialize

$ exgit init

#Root password prompt since it modifies your fstab and adds udev rules

#Repo name prompt

```

#### 2. Local repository to a USB stick

```
#ltof -- localToFlash

$ exgit ltof

#Root password prompt since it modifies your fstab and adds udev rules

```

#### 3. Auto-push called automaticaly on  flash/usb drive insert

```
#upstart calls autopush <drive partition>

$ exgit autopush <drive partition i.e sdb1>

```

## Tests
Test environment: ```uname -a ``` output:
```

Linux .... 4.4.0-119-generic #143~14.04.1-Ubuntu ... UTC 2018 x86_64 x86_64 x86_64 GNU/Linux

```
<hr>
## WATCH OUTS
Exgit :

* modifies ```/etc/fstab```
* adds udev rules under ```/etc/udev/rules.d/10-exgit.rules```
* mountall version

## TO-DO
>
* systemd implementation of upstart 
* Proper logging of autopush background outputs
* Notifications to indicate successfull operations to the user
* Mount/Unmount external drive as non -root



## Resources

* [wiki](https://en.wikibooks.org/wiki/Git/Repository_on_a_USB_stick)
* StackOverflow 
* Linux forums

## License

``` 
Copyright 2018 Oginga Steven.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
```



