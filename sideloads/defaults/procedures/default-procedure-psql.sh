#!/bin/bash

#+----------+
#|  CONFIG  |
#+----------+

#load default config
configLoadPsql


#+-------------------+
#|  NORMAL INCLUDES  |
#+-------------------+

sideloadOwn "$solutionOutputFile" 0 0


#+---------+
#| SCRIPT  |
#+---------+

#set dbExists to 0
dbExists=0
errorInStudentFile=0

#checking files
#isFilePresentChecker "$solutionQueryFile" 0
if [[ $createSolutionFileInsteadOfTesting != 1 ]]; then
	isFilePresentChecker "$inputFile" 1
fi


checkDefaultDbUsersExist
defaultDbUsersExists=$?

if [[ $defaultDbUsersExists == 0 ]]; then
	createDefaultDbUsers
fi

if [[ "$executePermission" == "read" ]]; then
	tmpDbFilename=$(basename -- "$dbFile")
	DbFilenameWithoutExtension="${tmpDbFilename%.*}"
	
	#use name of databasesFile for database name
	toUseDbName="$DbFilenameWithoutExtension"
	
	checkDbExists "$toUseDbName"
	dbExists=$?
else
	#get sandbox name for temporary database name
	getSandboxName
	#->$sandboxName
	toUseDbName="$sandboxName"
	
	dbExists=0
fi



if [[ $dbExists == 0 ]]; then
	#create and fill db
	createDb "$toUseDbName" "schema"
	sideloadDefault "databases/$dbFile" 0 0
	fillDb "$toUseDbName" "schema" "$dbFile"
	rm "$dbFile"
fi



#check if solution output is present or needs to be created
isFilePresent "$solutionOutputFile"
solutionOutputFilePresent=$?
if [[ $solutionOutputFilePresent != 0 || $createSolutionFileInsteadOfTesting == 1 ]]; then
	sideloadOwn "$solutionQueryFile" 0 0
	executeSqlFileWithPermission "$toUseDbName" "$dbDefaultSchema" "$executePermission" "$solutionQueryFile" "" "$solutionOutputFile"
	rm "$solutionQueryFile"
fi
isFilePresentChecker "$solutionOutputFile" 0


#stop here if solution creation
if [[ $createSolutionFileInsteadOfTesting == 1 ]]; then
	echo "Solution file \"""$solutionOutputFile""\" created:"
	catOutputFile "$solutionOutputFile"
	return
fi


#process student file -> check for not allowed commands in uploaded file
precheckStudentsPsqlFile "$inputFile"
errorInStudentFile=$?

#check for not allowed commands in uploaded file
if [[ $errorInStudentFile != 2 ]]; then
	executeSqlFileWithPermission "$toUseDbName" "$dbDefaultSchema" "$executePermission" "$inputFile" "" "$outputFile"
	errorInStudentFile=$?
	
	#display output
	catOutputFile "$outputFile"
fi


#check for execution errors in uploaded file
if [[ $errorInStudentFile == 2 ]]; then
	echo "ERROR: It seems that you tried to execute a higher-privilege command in input file \"$inputFile\" which is not required to solve this task. Revise your input file accordingly."
elif [[ $errorInStudentFile == 1 ]]; then
	echo "ERROR: It seems there is an error in input file \"$inputFile\"."
else
	#check it
	returnedTuplesCheckerV2 "$solutionOutputFile" "$outputFile" "(* row(s))" 0
	matchingTuplesCheckerV2 "$solutionOutputFile" "$outputFile" "entries" $considerEntryOrder $considerAttributeOrder
fi

#drop db?
if [[ "$executePermission" != "read" ]]; then
	dropDb "$toUseDbName"
fi

#exit accordingly
if [[ $errorInStudentFile -gt 0 ]]; then
	exit 1
else
	#echo "Everything seems ok! :)"
	exit 0
fi
