

# Exgit

Exgit(external git) is a Bash driven git wrapper for linux to make **automatic git push** of your commits on initialized local git repositories whenever an exgit-initialized external flashdrive is inserted. **Repository_on_a_USB_stick**

**Instead of having to resort to a hosting company to store your central repository, or to rely on a central server or internet connection to contribute changes to a project, it's quite possible to use REMOVABLE STORAGE to exchange and update  local repositories.** [Repository_on_a_USB_stick](https://en.wikibooks.org/wiki/Git/Repository_on_a_USB_stick)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See __installing__ for notes on how to install it on your system.

### Prerequisites

What things you need to install the software and how to install them

* Linux OS
* upstart

## Installing

Clone this repo and execute the ```install.sh``` file as illustrated below. **DO NOT RUN AS ROOT** ,the script will ask you for root permissions on-the-fly!

```exgit_sync.conf and exgit@.service``` contains template for creating upstart and systemd service respectively.
```
#From the current dir(this repo's root)
$ chmod a+x install.sh 

$ ./install.sh

#You will be prompted for root password
```

The install script would add ``` $HOME/bin``` (where exgit executable and files lie) to ```$PATH```


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
#Change Dir into the repo --> cd  /Projects/<repo-dir>

$ exgit ltof

#Root password prompt since it modifies your fstab and adds udev rules

```

#### 3. Auto-push called automaticaly on  flash/usb drive insert

```
#udev calls exgit's sync fnc which calls systemd/upstart which calls exgit's autopush fnc with <drive partition>

$ exgit autopush <drive partition i.e sdb1>

```

## Tests
Test environment: ```uname -a ``` output:
```
Linux .....4.15.0-66-generic #75-Ubuntu SMP ...UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
```
<hr>

## WATCH OUTS

Exgit :

* modifies ```/etc/fstab```
* adds udev rules under ```/etc/udev/rules.d/10-exgit.rules```
* mountall version



## Resources

* [Repository_on_a_USB_stick](https://en.wikibooks.org/wiki/Git/Repository_on_a_USB_stick)
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



