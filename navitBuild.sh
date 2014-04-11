#!/bin/bash
red='\e[0;31m'
grn='\e[0;32m'
yel='\e[1;33m'
off='\e[0m' 

alias cls='printf "\033c"'

printf "\033c"
echo "[   SETTING UP NAVIT+ANDROID+UBUNTU BUILD ENVIRONMENT  ]"




# setup var's to perform environment setup and cmake
export START_PATH=~/src
export SOURCE_PATH=$START_PATH"/navit-svn"
export CMAKE_FILE=$SOURCE_PATH"/Toolchain/arm-eabi.cmake"
export BITNESS=$(/bin/uname -m) # i686 for 32 and x86_64 for 64 
export BIT64="x86_64"
export BIT32="i686"

export NDK_SUFFIX="r9d"
export ANDROID_NDK_CDN="http://dl.google.com/android/ndk"
export ANDROID_NDK_FILE="android-ndk-r9d-linux-x86.tar.bz2"
export ANDROID_NDK=$START_PATH"/android-ndk-"$NDK_SUFFIX
export ANDROID_NDK_BIN=$ANDROID_NDK"/toolchains/arm-linux-androideabi-4.8/prebuilt/linux-x86/bin"

export ANDROID_SDK_CDN="https://dl.google.com/android"
export ANDROID_SDK_FILE="android-sdk_r22.6.2-linux.tgz"
export ANDROID_SDK=$START_PATH"/android-sdk-linux"
export ANDROID_SDK_TOOLS=$ANDROID_SDK"/tools"
export ANDROID_SDK_PLATFORM_TOOLS=$ANDROID_SDK"/platform-tools"

export ANDROID_TOOLS_CHECK=$ANDROID_SDK"/tools"

export ANDROID_PLATFORM_TOOLS_CHECK=$ANDROID_SDK"/platform-tools"

export ANDROID_BUILD_TOOLS="19.0.3"
export ANDROID_BUILD_CHECK=$ANDROID_SDK"/build-tools/"$BUILD_TOOLS

export ANDROID_PLATFORM_LATEST="android-19"
export ANDROID_PLATFORM_MIN="android-9"
export ANDROID_PLATFORM_CHECK_MIN=$ANDROID_SDK"/platforms/"$ANDROID_PLATFORM_MIN"/images"
export ANDROID_PLATFORM_CHECK_MAX=$ANDROID_SDK"/platforms/"$ANDROID_PLATFORM_LATEST"/images"

export BUILD_PATH=$SOURCE_PATH"/android-build"
export ANDROID_ENV=$ANDROID_NDK_BIN:$ANDROID_SDK_TOOLS:$ANDROID_SDK_PLATFORM_TOOLS

export SDK_ADD_FILTER="platform-tool,tools,build-tools-19.0.3,extra-android-m2repository,extra-android-support,android-10,sysimg-10,addon-google_apis-google-10,android-9,addon-google_apis-google-9,android-19,sysimg-19,addon-google_apis-google-19"

export SDK_UPD_FILTER="platform-tool,tools,build-tools-19.0.3,extra-android-m2repository,extra-android-support"

# Common exit point that starts a new shell with all of the environment settings etc
function finish {
  
  echo
  echo "This is a New shell with navit environment set! Type ' exit ' to end it"
  echo "before running this script again. You can use this shell to debug this script" 
  echo "or perform other actions against the navit environment. If using eclipse you"
  echo "you might need to export the ANDROID PATH VARIABLES outside this script"
  echo   
 
  cd ~/
  $SHELL
  exit $1
}



# If path already has our environment no need to set it 
if echo "$ANDROID_ENV" | grep -q "$PATH"; then
  echo -e "${grn}" "    Android PATH configuration... ALREADY SET" "${off}" 
  echo
else
  echo -e "${grn}" "    Android PATH configuration... EXPORTED" "${off}" 
  export PATH=$ANDROID_ENV:$PATH
  echo
fi

ubuntuFailed=0
androidFailed=0

function getPackage {

  if dpkg --get-selections | grep -q "^$1[[:space:]]*install$" >/dev/null; then
    echo -e "${grn}"    "    Found           $1" "${off}"
  else
    
    if sudo apt-get -y install $1 > /dev/null; then
       echo -e "${grn}" "    Install Succeed $1" "${off}"
    else
       echo -e "${red}" "    Install Failed  $1" "${off}"
       failedDependencies=$((failedDependencies+1))
    fi	
  fi
}

function getDependencies {
  
  getPackage cmake
  getPackage zlib1g-dev 
  getPackage libpng12-dev 
  getPackage libgtk2.0-dev 
  getPackage librsvg2-bin 
  getPackage g++ 
  getPackage gpsd 
  getPackage gpsd-clients 
  getPackage libgps-dev 
  getPackage libdbus-glib-1-dev 
  getPackage freeglut3-dev 
  getPackage libxft-dev 
  getPackage libglib2.0-dev 
  getPackage libfreeimage-dev 
  getPackage gettext
  getPackage openjdk-6-jdk
  getPackage ant
  getPackage subversion
  getPackage libsaxonb-java
}

echo " [ ] UBUNTU DEPENDENCIES... PLEASE WAIT"
getDependencies
if [[ "$failedDependencies" -gt 0 ]]; then
  echo -e "${red}" "[-] UBUNTU DEPENDENCIES FAILED" "${off}"
  finish 1
else
  echo -e "${grn}" "[X] UBUNTU DEPENDENCIES OK" "${off}" 
fi

echo

echo " [ ] CHECKING NAVIT SOURCE TREE... PLEASE WAIT"
mkdir -p $START_PATH
mkdir -p $SOURCE_PATH
mkdir -p $BUILD_PATH


function checkDir {
  
  if [ ! -d $1 ]; then 
    return 0
  fi
  
  return 1
}

function downLoadNavit {
   cd $START_PATH
   echo -e -n "${yel}" "    Navit is being downloaded ... " "${off}" 
   if svn co -q svn://svn.code.sf.net/p/navit/code/trunk/navit navit-svn  >/dev/null; then {
     echo -e "${grn}" "SUCCESS" "${off}"
   } else
   {
     echo -e "${red}" "FAILED" "${off}"	
     finish 1
   }
   fi
}

export current=""
export newest=""

function svnNewest {
   cd $SOURCE_PATH
   newest=$(svn info -r HEAD | grep -i "Last Changed Rev" 2>&1)
}

function svnCurrent {
   cd $SOURCE_PATH
   current=$(svn info | grep -i "Last Changed Rev" 2>&1)
}

function updateNavit {
   
    for run in {1..5}
    do
      svnNewest
      if [ $? -ne 0 ]; then {
	      sleep 1
	      echo $newest
      } else
        break
      fi
    done

    for run in {1..5}
    do
      svnCurrent
      if [ $? -ne 0 ]; then {
	      sleep 1
	      echo $current
      } else
        break
      fi
    done

   if [ "$newest" == "$current" ]; then {
   	echo -e "${grn}"    "    Navit is up to date" "${off}" 

   } else
   {
        echo $newest 
        echo $current
	echo -e -n "${yel}" "    Navit is being updated" "${off}"

   	if svn up  >/dev/null; then {
     		echo -e "${grn}" "SUCCESS" "${off}"
   	} else {
     		echo -e "${red}" "FAILED" "${off}"	
     		finish 1
   	}
   	fi 
   }
   fi
    
}

checkDir $SOURCE_PATH"/navit"
if [ $? == 0  ]; then {
    downLoadNavit
} 
else {
    updateNavit 
}
fi

echo -e "${grn}" "[X] NAVIT SOURCE TREE OK" "${off}" 
echo


echo " [ ] CREATING ANDROID BUILD ENVIRONMENT ... THIS MIGHT TAKE AWHILE..."

function downloadSDK {
	cd $START_PATH
	if wget -N -q $ANDROID_SDK_CDN/$ANDROID_SDK_FILE >/dev/null; then {
		echo -e "${grn}" "SUCCEEDED" "${off}" 
	} else {
		echo -e "${red}" "FAILED" "${off}" 
		finish 1;
	}
	fi
}

function downloadNDK {
	cd $START_PATH
	if wget -N -q $ANDROID_NDK_CDN/$ANDROID_NDK_FILE >/dev/null; then {
		echo -e "${grn}" "SUCCEEDED" "${off}" 
	} else {
		echo -e "${red}" "FAILED" "${off}" 
		finish 1;
	}
	fi
}

function extractSDK {
   echo -e -n "${yel}" "    Unpacking Android SDK...   " 
   
   cd $START_PATH
	
   $(tar -xf $ANDROID_SDK_FILE -C $START_PATH)

   if [ $? -eq 0  ]; then { 
   	echo -e "${grn}" "SUCCEEDED" "${off}" 
   }
   else
   {
	echo -e "${red}" "FAILED" "${off}"
        finish 1	
   }
   fi
	 
}

function extractNDK {
   echo -e -n "${yel}" "    Unpacking Android NDK...   " 
   
   cd $START_PATH
	
   $(tar -xf $ANDROID_NDK_FILE -C $START_PATH)

   if [ $? -eq 0  ]; then { 
   	echo -e "${grn}" "SUCCEEDED" "${off}" 
   }
   else
   {
	echo -e "${red}" "FAILED" "${off}"
        finish 1	
   }
   fi 
}


if [ ! -d $ANDROID_SDK ]; then {
  echo -e -n "${yel}" "    Android SDK downloading... " 
  downloadSDK
  extractSDK
}
else {
  echo -e "${grn}" "    Android SDK Found " "${off}"	
}
fi

if [ ! -d $ANDROID_NDK_BIN ]; then {
  echo -e -n "${yel}" "    Android NDK downloading... " 
  downloadNDK
  extractNDK
}
else {
  echo -e "${grn}" "    Android NDK Found " "${off}"	
}
fi

function addSDK {

 export ADD_SDK="android update sdk --no-ui --all --filter $SDK_ADD_FILTER"

 $ADD_SDK

}

function updateSDK {
  export UPD_SDK="android update sdk --no-ui --filter $SDK_UPD_FILTER"

  $UPD_SDK	
} 

if [ ! -d $ANDROID_PLATFORM_CHECK_MIN ]; then {
  echo -e -n "${yel}" "    Android SDK Platform ... MISSING, downloading may take a very long time... " 
  
  	addSDK

  echo -e "${grn}" "SUCCEEDED" "${off}"
}
else {
  echo -e -n "${grn}" "    Android SDK Platform ..." "${off}"

	updateSDK

  echo -e "${grn}" "VERIFIED" "${off}"	
}
fi

echo -e "${grn}" "[X] ANDROID BUILD ENVIRONMENT ... OK" "${off}"


echo " [ ] CREATING ANDROID CMAKE ENVIRONMENT ... THIS MIGHT TAKE AWHILE..."

//rm -Rf $BUILD_PATH
mkdir -p $BUILD_PATH
cd $BUILD_PATH

export CMAKE_CMD="cmake -DCMAKE_TOOLCHAIN_FILE=$CMAKE_FILE -DCACHE_SIZE='(20*1024*1024)' -DAVOID_FLOAT=1 -DANDROID_PERMISSIONS='CAMERA' -DANDROID_API_VERSION=9 $SOURCE_PATH"

echo -e "${grn}" "[X] ANDROID CMAKE ENVIRONMENT ... OK" "${off}"

$CMAKE_CMD

echo " [ ] CREATING ANDROID BUILD PACKAGE ... THIS MIGHT TAKE AWHILE..."

cd $BUILD_PATH
make
make apkg

echo -e "${grn}" "[X] ANDROID BUILD PACKAGE FINISHED ... OK" "${off}"

finish 0






