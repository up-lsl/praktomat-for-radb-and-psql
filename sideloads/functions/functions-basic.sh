#!/bin/bash


#++----------++
#++----------++
#||  CONFIG  ||
#++----------++
#++----------++

#load global config
function configLoadGlobal {
	internalErrorMessageLine01="Dear student, something seems to be wrong with the current task - which is not your fault but ours!"
	internalErrorMessageLine02="Please send us an e-mail (to praktomat@uni-passau.de) which contains THIS OUTPUT so we can resolve the issue."
	internalErrorMessageExtra01="DEBUG MESSAGE:"
}



#+-----------------------------+
#| DEBUG AND OUTPUT FUNCTIONS  |
#+-----------------------------+

# debug & output
function deb {
	if [[ $debugLevel -ge $1 ]]; then
		echo -e "DEBUG [LINE $( caller ); LEVEL "$1"]:" ${@:2}
		#echo "BASH_SOURCE: ${BASH_SOURCE[*]}"
		#echo "BASH_LINENO: ${BASH_LINENO[*]}"
		#echo "FUNCNAME: ${FUNCNAME[*]}"
	fi
}


function debcatFile {
	logname="$1"
	filename="$2"

	if [[ $debugLevel -ge 5 ]]; then
		echo "DEBUG: ${logname}"
		echo "================="
		cat "${filename}"
	fi

}


function catOutputFile {
	filename="$1"

	echo ""
	echo ""
	echo "INFO: Your output"
	echo "================="
	echo ""
	cat "$filename"
	echo ""
	echo "<<END OF OUTPUT>>"
	echo ""
	echo ""
}




#+------------------+
#| FILE MANAGEMENT  |
#+------------------+



# check if file is present
function isFilePresent()
{
	filename="$1"
	result=0
	
	deb 3 "LS-Result:" $(ls "$1" 2> /dev/null)

	foundFilesCount=$(ls "$1" 2> /dev/null | wc -l)
	deb 2 "foundFilesCount =" $foundFilesCount

	if [[ $foundFilesCount == 0 ]]
	then
		deb 1 "ERROR: File \"$1\" is missing!"
		result=1

	elif [[ $foundFilesCount -gt 1 ]]
	then
		deb 1 "INFO: Multiple files matching \"$filename\" found!"
	fi
	
	return $result
}



#UNUSED
# find uploaded file's name
function findFile()
{
	lsfilter=$1
	result=0
	
	deb 3 "LS-Result:" $(ls "${lsfilter[@]}" 2> /dev/null)

	foundFilesCount=$(ls "${lsfilter[@]}" 2> /dev/null | wc -l)
	deb 2 "foundFilesCount =" $foundFilesCount

	if [[ $foundFilesCount == 0 ]]
	then
		echo "ERROR: Please rename your input file!"
		result=1

	elif [[ $foundFilesCount -gt 1 ]]
	then
		echo "ERROR: Upload one file only!"
		result=1

	elif [[ $foundFilesCount == 1 ]]
	then
		foundFile=$(ls "${lsfilter[@]}" 2> /dev/null)
		deb 2 "foundFile =" $foundFile
	fi
	
	return $result
}


#get current sandbox, i.e. the dir name
function getSandboxName {
	sandboxName=${PWD##*/}
	deb 2 "sandboxName =" $sandboxName
}


#UNUSED
#write lines of a given file to an array
function linesOfFileToArray {
	filename=$1
	i=0
	unset linesArray

	while IFS= read -r line
	do
		linesArray[$i]="$line"
		deb 4 "line "$i":" "${line}"
		((i++))
	  
	done < $filename
	
	deb 3 '${linesArray[@]} =' "${linesArray[@]}"

	#return $linesArray
}

function splitStringToArray {
	stringToSplit="$1"
	toUseseparator="$2"
	
	unset splittedStringArray
	
	#line to array
	OLDIFS=$IFS
	deb 4 '$IFS =' $(echo "$separator" | tr " " ":")
	IFS=$(echo "$separator" | tr " " ":")
	read -ra splittedStringArray <<< "$stringToSplit"
	IFS=$OLDIFS
	
}


#get regex result in file
function getRegexResultFromFile {
	filename="$1"
	regex="$2"
	regexGroup="$3"
	regexResult=""

	deb 3 'pcregrep --only-matching='"$regexGroup"' -M '"$regex"' '"$filename"
	deb 3 'pcregrep output:' $(pcregrep --only-matching="$regexGroup" -M "$regex" "$filename")
	regexResult=$(pcregrep --only-matching="$regexGroup" -M "$regex" "$filename")
}

#get regex result in file
function getRegexResultCountFromFile {
	filename="$1"
	regex="$2"
	regexGroup="$3"
	regexCountResult=-1

	deb 3 'pcregrep --only-matching='"$regexGroup"' -M -c '"$regex"' '"$filename"
	regexCountResult=$(pcregrep --only-matching="$regexGroup" -M -c "$regex" "$filename")
	
	deb 3 '$regexCountResult =' "$regexCountResult" 
	return $regexCountResult
}