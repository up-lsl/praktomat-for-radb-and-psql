#!/bin/bash


#++----------++
#++----------++
#||  CONFIG  ||
#++----------++
#++----------++




#++---------------------++
#++---------------------++
#||  HELPING FUNCTIONS  ||
#++---------------------++
#++---------------------++


#+------------------+
#| FILE MANAGEMENT  |
#+------------------+






#++----------------------++
#++----------------------++
#||  CHECKING FUNCTIONS  ||
#++----------------------++
#++----------------------++


#checks if given file is present
function isFilePresentChecker {
	filename="$1"
	isStudentFile="$2"
	
	deb 4 '$isStudentFile =' $isStudentFile
	
	isFilePresent $filename
	
	if [[ "$?" -ne 0 ]]; then
		if [[ $isStudentFile == 1 ]]; then
			echo "ERROR: File \"$1\" is missing!"
			echo "-> You have most likely named your file incorrectly. Please try to rename your uploaded file to \"$1\" and try again :)"
		else
			echo "$internalErrorMessageLine01"
			echo "$internalErrorMessageLine02"
			echo "$internalErrorMessageExtra01" "Important file(s) were not be loaded!"
		fi
		exit 1
	fi
}