#!/bin/bash 
##
##	makeiso.sh is a script to prep releng from archiso,   
##	to create a duplicate installable .iso of the users Arch Linux install.
##			
##	makeiso.sh must be run as su within /home/<username>/makeiso/releng/
##
##	This alpha testing version does not have the installer placed into releng yet.
##      Dependancy handling has not been implemented yet. You must do it manually.
##
##	makeiso dependencies: sudo archiso pacaur 
##
##	makeiso.2014-10-8
##
#################################################################################################

#-------------------------------------------------------------------------------------------------
# Set "${L}" as pwd  "${L}"= /home/"${USER}"/makeiso/releng (L = location of script in filesystem)
#-------------------------------------------------------------------------------------------------
	L=$(pwd)


#---------------------------------------------------------------
# Tee all terminal output to log
#---------------------------------------------------------------
	exec >  >(tee -a ${L}/makeiso.log)
	exec 2> >(tee -a ${L}/makeiso.log >&2)


#------------------------
# Print message to user
#------------------------
	echo ""
	echo " Checking if archiso, pacaur, sudo are installed and running as root"


#-------------------------------
# Check if archsio is installed
#-------------------------------
	AI=$(pacman -Q archiso)
	if [[ "$AI" != archiso* ]]; then
	    echo " ERROR: archiso needs to be installed before running makeiso" 1>&2
	    exit 1
	fi


#--------------------------------
# Check that pacaur is installed
#--------------------------------
	PI=$(pacman -Q pacaur)
	if [[ "$PI" != pacaur* ]]; then
	    echo " ERROR: pacaur needs to be installed before running makeiso" 1>&2
	    exit 1
	fi


#------------------------------
# Check that sudo is installed
#------------------------------
	SI=$(pacman -Q sudo)
	if [[ "$SI" != sudo* ]]; then
	    echo " ERROR: sudo needs to be installed before running makeiso" 1>&2
	    exit 1
	fi 


#---------------------------------------------------------------------------------
# Check if running as root and user su'd to root rather than open a root terminal
#---------------------------------------------------------------------------------

	if [[ $EUID -ne 0 ]]; then
	    echo " ERROR: This script must be run as root" 1>&2
	    exit 1
	fi

	if [[ $USER = root ]];then
	    echo ' ERROR: Running as root, but echo $USER also = root. Need to su to root from a user terminal so echo $USER = your username' 1>&2
	    exit 1 
	fi 


#--------------------------------------------------------
# Create directories and file for the following command
#--------------------------------------------------------
	mkdir -p "${L}"/airootfs/makeiso/packages ; touch "${L}"/airootfs/makeiso/packages/packages


#------------------------
# Print message to user
#------------------------
	echo ""
	echo " Script is running as $(whoami) and passed dependency checks"
	echo ""
	echo " Querying pacman to make a list of std repo packages to install"

#-------------------------------------------------------------------------------------------------------------
# Query pacman for explicitly installed std repo packages - output to "${L}"/airootfs/makeiso/packages/packages
#-------------------------------------------------------------------------------------------------------------
	pacman -Qenq >"${L}"/airootfs/makeiso/packages/packages


#--------------------------------------------------------
# create directories and file for the following command
#--------------------------------------------------------
	mkdir /tmp/makeiso ; touch /tmp/makeiso/pacman-Qmq


#------------------------
# Print message to user
#------------------------
	echo ""	
	echo " Working... to make a list of buildable AUR installed packages"
	echo ""

#----------------------------------------------------------------------------------
# query pacman for installed foreign packages - output to /tmp/makeiso/pacman-Qmq
#----------------------------------------------------------------------------------
	pacman -Qmq >/tmp/makeiso/pacman-Qmq 


#----------------------------------------------------------------------
# create from pacman-Qmq LIST of packages not available in AUR
# set -x and cancel +x here to show something going on while waiting
# echo for space
#----------------------------------------------------------------------
	set -x

	for pkg in $(pacman -Qmq); do
	  cower -sq "$pkg" &>>/tmp/makeiso/null || printf '%s\n' "$pkg" >>/tmp/makeiso/noaur 
	done

	set +x
	echo ""

#-----------------------------------------------------------------------
# create a good list of AUR packages to build - pacman-Qmq minus noaur
#-----------------------------------------------------------------------
	comm -3 /tmp/makeiso/pacman-Qmq /tmp/makeiso/noaur >/tmp/makeiso/aur


#------------------------------------------------------------------------
# Create directory in /tmp/makeiso/ and releng for prebuilt AUR packages
#------------------------------------------------------------------------
	mkdir /tmp/makeiso/AUR 


#---------------------------------------------------------------------------      
# Set permission so non root user can place packages into /tmp/makeiso/AUR	
#---------------------------------------------------------------------------
	chmod -R 777 /tmp/makeiso

#-------------------------------------------------------
# Copy filtered AUR packages list to iso for later use 
#-------------------------------------------------------
cp /tmp/makeiso/aur "${L}"/airootfs/makeiso/packages/aur


#------------------------
# Print message to user and echo for space
#------------------------
	echo " Below is a list of official repo packages that will be installed later"
	echo ""
#--------------------------------------------
# Print to screen list of std repo packages and echo for space
#--------------------------------------------
	cat "${L}"/airootfs/makeiso/packages/packages


#------------------------
# Print message to user
#------------------------
	echo ""
	echo " Below is a list of AUR packages that will be built and installed." 
	echo ""
#---------------------------------------
# Print to screen list of AUR packages
#---------------------------------------
	cat /tmp/makeiso/aur


#------------------------------------------
# Print message to user and echo for space
#------------------------------------------
	echo ""
	echo ""
	echo " Completed with gathering installed packages information"


#---------------------------------------------------------
# Create destination directory for the following command
#---------------------------------------------------------
	mkdir -p "${L}"/airootfs/makeiso/configs/home/"${USER}" 

#-----------------------
# Print message to user
#----------------------
	echo ""
	echo " Copying user configuration files and directories"
	echo "" 


#################### COPY USER CONFIG FILES ######################
#--------------------------------------------------------------------
# Copy /home/$USER configuration .dot files and directories 
#--------------------------------------------------------------------

	cp /home/"${USER}"/.[a-zA-Z0-9]* "${L}"/airootfs/makeiso/configs/home/"${USER}" 

	cp -R /home/"${USER}"/.config/ "${L}"/airootfs/makeiso/configs/home/"${USER}"/.config/ 


#----------------------------------------
# Create directory for following command
#----------------------------------------
	mkdir -p /tmp/makeiso/


#----------------------------------------
# Create a list of modified config files
#----------------------------------------
	pacman -Qii | awk '/^MODIFIED/ {print $2}' > /tmp/makeiso/rtmodconfig.list


#-----------------------
# Print message to user
#-----------------------
	echo ""
	echo " Copying system configuration files that have been modified"
	echo ""
	cat /tmp/makeiso/rtmodconfig.list

#--------------------------------------------------------
# Create destination directory for the following command
#--------------------------------------------------------
	mkdir -p "${L}"/airootfs/makeiso/configs/rootconfigs


#----------------------------------------------------
# Copy rtmodconfig.list file to releng for later use
#----------------------------------------------------
	cp /tmp/makeiso/rtmodconfig.list "${L}"/airootfs/makeiso/configs/rtmodconfig.list


#-------------------------------------------------------------------------------------
# Read the rtmodconfig.list and copy the modified config files listed in it to releng
#-------------------------------------------------------------------------------------
	xargs -a /tmp/makeiso/rtmodconfig.list cp -t "${L}"/airootfs/makeiso/configs/rootconfigs/


#-----------------------
# Print message to user
#-----------------------
	echo ""
	echo " Preparing to pre-build AUR packages"

#------------------------------------------------------------
# Set makepkg variable to define makepkg package destination
#------------------------------------------------------------ 
	export PKGDEST=/tmp/makeiso/AUR
	source /home/"$USER"/.bashrc


#------------------------------------------------------------- 
# Switch from root to user to build packages and set Here Tag
#-------------------------------------------------------------
	sudo -u "${USER}" bash << HereTag


#-------------------------------------------------------------------
# Build AUR packages from list, /tmp/makepkg/aur
# Set makepkg variable to define makepkg package destination
#-------------------------------------------------------------------
	export PKGDEST=/tmp/makeiso/AUR 
	source /home/$USER/.bashrc	

	echo ""
	echo " Script is now running as "${USER}" to build AUR packages"
	echo " AUR package destination ${PKGDEST}"	
	echo ""
	pacaur --noconfirm --noedit -m "$(< /tmp/makeiso/aur)"

#---------------------------------------------------
# End Here Tag (Cannot be a preceding tab or space)
#---------------------------------------------------

HereTag


#----------------------------------------------------------------------------------------
# Switched back to root to move /tmp/makeiso/AUR to "${L}"/airootfs/makeiso/packages/AUR
#----------------------------------------------------------------------------------------
	L=$(pwd)


#------------------------------------------
# Copy the prebuilt AUR packages to releng
#------------------------------------------
  	cp -R /tmp/makeiso/AUR "${L}"/airootfs/makeiso/packages/AUR

	echo ""
	echo " Script back to running as $(whoami) to copy AUR packages to releng"
	echo " AUR package destination ${L}/airootfs/makeiso/packages/AUR"
	echo ""
	echo " Successfully completed running the Makeiso script"
	echo ""
	echo ""
	echo ""
	echo " The makeiso.sh script has finished running. Everything that was printed to this terminal resides within ${L}/makeiso.log for review."
	echo " All the necessary info, files, directories and AUR packages created by the script now reside within ${L}/airootfs/makeiso/."
	echo " Some other stuff resides within /tmp/makeiso/."
	echo " If you want to check, change or modify the contents of ${L}/airootfs/makeiso before building the .iso you should do it now."  	
	echo " Leave this terminal open and come back to create the iso when you are ready, or continue."
	echo ""
	echo ""
	echo ""


#----------------------------------------------------------
# Unset all script set variables prior to running build.sh
#----------------------------------------------------------
	unset L
	unset AI
	unset PI
	unset SI
	unset pkg


#---------------------------------------------
# Message to user requiring input to continue
#---------------------------------------------
	echo " Enter y to proceed or n to exit script."
	echo ""
	while true; do
    		read -p " Are you are ready to run build.sh, which will create an iso.? " yn
    		case $yn in
        	[Yy]* ) ./build.sh -v; break;;
        	[Nn]* )  clear ; exit;;
        	* ) echo "Enter yes to proceed or no to exit script.";;
    	esac
done


### End 4now ###

