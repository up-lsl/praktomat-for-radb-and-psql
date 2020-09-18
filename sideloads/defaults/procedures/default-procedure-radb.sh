#!/bin/bash

#+----------+
#|  CONFIG  |
#+----------+

#load default config
configLoadRadb


#+-------------------+
#|  NORMAL INCLUDES  |
#+-------------------+

sideloadDefault "other/$rabdIniFile" 0 0
sideloadOwn "$dbFile" 0 0
sideloadOwn "$solutionOutputFile" 0 0


#+----------+
#|  SCRIPT  |
#+----------+


#checking files
isFilePresentChecker "$rabdIniFile" 0
isFilePresentChecker "$dbFile" 0
if [[ $createSolutionFileInsteadOfTesting != 1 ]]; then
	isFilePresentChecker "$inputFile" 1
fi


#check if solution output is present or needs to be created
isFilePresent "$solutionOutputFile"
solutionOutputFilePresent=$?
if [[ $solutionOutputFilePresent != 0 || $createSolutionFileInsteadOfTesting == 1 ]]; then
	sideloadOwn "$solutionQueryFile" 0 0
	runRadb "$solutionQueryFile" "$dbFile" "$solutionOutputFile" "$rabdIniFile"
	rm "$solutionQueryFile"
fi
isFilePresentChecker "$solutionOutputFile" 0


#stop here if solution creation
if [[ $createSolutionFileInsteadOfTesting == 1 ]]; then
	echo "Solution file \"""$solutionOutputFile""\" created:"
	catOutputFile "$solutionOutputFile"
	return
fi

#execute student file
runRadbChecker "$inputFile" "$dbFile" "$outputFile" "$rabdIniFile" 1


#checking
returnedTuplesCheckerV2 "$solutionOutputFile" "$outputFile" "tuple(s) returned" 0
matchingTuplesChecker "$solutionOutputFile" "$outputFile"


#exit with 0 if everything was ok!
#echo "Everything seems ok! :)"
exit 0



