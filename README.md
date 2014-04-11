Navit-Android-Build-Script
==========================
Build script for Ubuntu 12.04 that will get all dependenices and perform an Android build

##Why
If you are trying to build Navit source code for Android with the latest NDK and Toolchains it's a bit of a pain to do manually

This script was writtend to be used on 32 bit Ubuntu 12.04 and run from a users home directory, it probably shouldn't be used to install Navit on anything other than a Virtualbox etx. since it's not all that configurable without tinkering but with a little work in can be used to do the same on other distros. 

### What it does initially 
Installs all dependencies
Downloads Android SDK 22.6.2, Build Tools 19.0.3, and NDK r9d
Downloads all updates for SDK ( but not the NDK ) 
Downlaods all the Navit source
Creates a directory called 'src' just off the directory where all of this goes
Builds all the source and if succesful ( assuming you run it from the home dir ) the android debug bin will be in 
'~/src/navit-svn/android-build/navit/android/bin/...' There are a number of APK's you can use to deploy dependent on use

### What it does when it's re-rune
Updates the SDK
Updates the Navit Source
Cleans out the object/makefile etc (so if you want to save your built source rename android-build directory) 
Rebuilds

It's not perfect, it was done in an hour or two and is not DRY or configurable but if you need to build and tinker with Navit without going and doing a lot of error prone manual stuff it's a good starting point.   
