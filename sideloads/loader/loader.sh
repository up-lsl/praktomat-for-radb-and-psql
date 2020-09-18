#!/bin/bash

#++-----------------++
#++-----------------++
#||  LOADER CONFIG  ||
#++-----------------++
#++-----------------++

debugLevel=-1
sideloadsHttpRoot="https://localhost:[[INTERNER PORT]]/"
tasksDlDir="tasks"
defaultsDlDir="defaults"
functionsDlDir="functions"
taskdefaultsh="checker.sh"
#doSideloadDefaultSh
basicFunctionsShPath="functions/functions-basic.sh"



#++--------------------++
#++--------------------++
#||  LOADER FUNCTIONS  ||
#++--------------------++
#++--------------------++

#sideload something
function sideload {
	reldlPath="$1"
	doreplace="$2"
	dosource="$3"
	
	replace="n"
	quiet="s"
	
	filename="${reldlPath##*/}"
	
	
	if [[ $debugLevel -ge 4 ]]; then
		if [[ $reldlPath == "$basicFunctionsShPath" ]]; then	
			echo "[DEBUG NOT YET LOADED...] -> downloading file \"${sideloadsHttpRoot}${reldlPath}\""
			echo "[DEBUG NOT YET LOADED...] -> curl output:"
		else
			deb 3 "downloading file \"${sideloadsHttpRoot}${reldlPath}\""
			deb 4 "curl output:"
		fi
		
		quiet=""
	fi
	
	
	if [[ $doreplace == 1 ]]; then
		replace=""
	fi
	
	#check HTTP-Code 200
	httpReturnCode=$(curl -k -s -o /dev/null -I -w "%{http_code}" "${sideloadsHttpRoot}${reldlPath}")
	
	if [[ $httpReturnCode == 200 ]]; then
		# actuall download
		curl -${quiet}kO${replace} "${sideloadsHttpRoot}${reldlPath}"
	else
		#http error!
		deb 2 "ERROR: HTTP-Code $httpReturnCode for ${sideloadsHttpRoot}${reldlPath}"
	fi
	
	
	#source file (i.e. load it)
	if [[ $dosource == 1 ]]; then
		
		if [[ $debugLevel -ge 3 ]]; then
			if [[ $reldlPath == "$basicFunctionsShPath" ]]; then
				echo "[DEBUG NOT YET LOADED...] -> sourcing file \"./${filename}\""
			else
				deb 3 "sourcing file \"./${filename}\""
			fi
		fi
		
		source "./$filename"
	fi
	
}

#load something from own taskid dir
function sideloadOwn {
	reldlPathInTaskIdDir="$1"
	doreplace="$2"
	dosource="$3"

	sideload "${tasksDlDir}/${taskid}/${reldlPathInTaskIdDir}" $doreplace $dosource
}


#load something from defaults
function sideloadDefault {
	reldlPathInDefaultsDir="$1"
	doreplace="$2"
	dosource="$3"

	sideload "${defaultsDlDir}/${reldlPathInDefaultsDir}" $doreplace $dosource
}


#load something from functions
function sideloadFunction {
	reldlPathInFunctionsDir="$1"
	doreplace="$2"
	dosource="$3"

	sideload "${functionsDlDir}/${reldlPathInFunctionsDir}" $doreplace $dosource
}



#++------------++
#++------------++
#||  INCLUDES  ||
#++------------++
#++------------++

sideload "$basicFunctionsShPath" 1 1
configLoadGlobal

deb 2 "==================="
deb 2 '$taskid =' "$taskid"
deb 2 "==================="


if [[ -z "$doSideloadDefaultSh" || $doSideloadDefaultSh == 1 ]]; then
	sideloadOwn "${taskdefaultsh}" 0 1
fi
