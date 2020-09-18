#!/bin/bash


#++----------++
#++----------++
#||  CONFIG  ||
#++----------++
#++----------++


#load psql config
function configLoadPsql {
	#load default config
	configLoadGlobal

	#db connection
	dbhost=localhost
	dbport=[[INTERNET PORT]]
	dbDefaultSchema="schema"
	
	#db users
	dbpostgresuser=postgres
	dbpostgrespass=[[PASSWORT AUS DOCKER-CONTAINER-ERSTELLUNG]]
	dbadminuser=psqluseradmin
	dbadminpass=[[IRGEND EIN PASSWORT]]
	dbmanageruser=psqlusermanager
	dbmanagerpass=[[IRGEND EIN PASSWORT]]
	dbwriteuser=psqluserwrite
	dbwritepass=[[IRGEND EIN PASSWORT]]
	dbreaduser=psqluserread
	dbreadpass=[[IRGEND EIN PASSWORT]]

	#init scripts
	psqlScriptCreateUsers="createUsers.sql"
	psqlScriptGetUsers="getUsers.sql"
	psqlScriptCustomizeNewDb="customizeNewDb.sql"

	#in/out
	psqldebuglog="debug.txt"
	inputFile="query.q"
	solutionQueryFile="solution.query"
	solutionOutputFile="solution.output"
	outputFile="output.tmp"
	
	#tuples
	tupleSeparator=' \| '
	tupleCountRegex='\((\d*) rows?\)'
	tupleCountRegexGroup=1
	resultSeparationRegex='(.*\n(---*?-?-?\+?)*\n)((.*\n.*)*)(\((\d*) rows?\))'
	resultSeparationRegexGroup=3
	
	#psql errors
	psqlErrorRegex='psql:.*:\d*: ERROR: |psql:.*:\d*: invalid command|psql: could not connect to server|psql: FATAL:  password authentication failed for user'
	psqlPermissionErrorRegex='psql:.*:\d*: ERROR:  permission denied'
	psqlNotAllowedCommandsRegex='\\\!|\\\.|\\\?|\\C|\\H|\\T|\\a|\\c|\\cd|\\connect|\\copy|\\copyright|\\d|\\dC|\\dD|\\dF|\\dFd|\\dFp|\\dFt|\\dT|\\da|\\db|\\dc|\\dd|\\ddp|\\des|\\deu|\\dew|\\df|\\dg|\\di|\\dit|\\dl|\\dn|\\do|\\dp|\\drds|\\ds|\\dt|\\dtvs|\\du|\\dv|\\e|\\echo|\\edit|\\ef|\\encoding|\\f|\\g|\\h|\\help|\\html|\\i|\\include|\\l|\\list|\\lo_export|\\lo_import|\\lo_list|\\lo_unlink|\\o|\\out|\\p|\\password|\\print|\\prompt|\\pset|\\q|\\qecho|\\quit|\\r|\\reset|\\s|\\set|\\t|\\timing|\\unset|\\w|\\write|\\x|\\z'
}


#load radb config
function configLoadRadb {
	#load default config
	configLoadGlobal

	#in/out
	inputFile="query.q"
	solutionFile="solution.output"
	solutionOutputFile="solution.output"
	solutionQueryFile="solution.query"
	outputFile="output.tmp"
	radbLogFile="radb.log"

	#radb config
	rabdIniFile="radb.ini"
	rabdIniContent=" "
	radbErrorRegex='ERROR'
	radbInternalProblemRegex='Traceback \(most recent call last\):'

	#tuples
	tupleSeparator=", "
	tupleCountRegex='(\d*)( tuple(s)? returned)'
	tupleCountRegexGroup=1
	resultSeparationRegex='(----------------------------------------------------------------------\n)((.*\n.*)*)(----------------------------------------------------------------------)'
	resultSeparationRegexGroup=2

}


#+-------------------+
#| ENTRY MANAGEMENT  |
#+-------------------+


#get tuple count from given file
function getTupleCountFromFile {
	filename="$1"
	result=-1
	
	getRegexResultFromFile "$filename" "$tupleCountRegex" "$tupleCountRegexGroup"
	result="$regexResult"
	
	return $result
}



#compares the "returned tuples" of output and solution file
function returnedTuplesComparer {
	solutionFile="$1"
	outputFile="$2"
	doExit="$3"
	#result

	getTupleCountFromFile "$outputFile"
	tupleCountOutput=$?
	deb 1 "Output file has" "$tupleCountOutput" "tuple/row(s)"

	getTupleCountFromFile "$solutionFile"
	tupleCountSoultion=$?
	deb 1 "Solution file has" $tupleCountSoultion "tuple/row(s)"

	if [ $tupleCountOutput -eq $tupleCountSoultion ]; then
		deb 2 'Number of "tuple(s) returned"/"(* row(s))" matches solution.';
		result=0
	else
		deb 2 'Number of "tuple(s) returned"/"(* row(s))" does NOT matches solution.';
		result=1
	fi
	
	return $result
}


#loads tuples from given file to tuplesArray
function loadTuplesArrayFromFile {
	filename="$1"
	unset tuplesArray
	
	getRegexResultFromFile "$filename" "$resultSeparationRegex" "$resultSeparationRegexGroup"
	result="$regexResult"
	
	IFS=$'\n' tuplesArray=($result)
	
	deb 3 '$#tuplesArray[@] =' "${#tuplesArray[@]}"
	deb 3 '$tuplesArray[@] =' "${tuplesArray[@]}"
	deb 3 '$tuplesArray[0] =' "${tuplesArray[0]}"
	deb 3 '$tuplesArray[1] =' "${tuplesArray[1]}"
}


#compares the tuples in tuplesArray with given file
function tupleComparer {
	filename=$1
	posneg=$2
	result=0
	#tuplesArray
	
	for line in "${tuplesArray[@]}"; do
		deb 4 "Function Call: createTupleRegex" "$line" "$tupleSeparator"
		deb 4 '$tupleSeparator =' "$tupleSeparator"
		createTupleRegex "$line" "$tupleSeparator"
		#$param
		
		#run grep command and get the numbers of lines in the output file
		#==> logic: The output file must contain the tuple given in the solution file ==> Linecount >= 1
		#grep -Po "^(?=.*Amy)(?=.*female)(?=.*16).+" output.q
		#deb 2 "GREP-OUTPUT:\n"$(grep -Po "$param" "$outputFile")
		matchingLinesInOutut=$(grep -Po "$param" "$filename" | wc -l)
		deb 1 "matchingLinesInOutut = "$matchingLinesInOutut
		
		#evalute response
		if [[ "$posneg" == "pos" ]]; then
			if [[ $matchingLinesInOutut == 0 ]]; then
				deb 1 "Tupel/entry ("$line") is missing!"
				result=1

			elif [[ $matchingLinesInOutut == 1 ]]; then
				#deb "Ein Tupel"
				#deb ${values[*]}
				tmp=1

			elif [[ $matchingLinesInOutut -gt 1 ]]; then
				deb 1 "Tupel/entry ("$line") found "$matchingLinesInOutut" times."
				multi=1
			fi
		else #neg
			if [[ $matchingLinesInOutut == 0 ]]; then
				deb 1 "Tupel/entry ("$line") is not in solution!"
				result=1

			elif [[ $matchingLinesInOutut == 1 ]]; then
				#deb "Ein Tupel"
				#deb ${values[*]}
				tmp=1

			elif [[ $matchingLinesInOutut -gt 1 ]]; then
				deb 1 "Tupel/entry ("$line") found in solution "$matchingLinesInOutut" times."
				multi=1
			fi
		fi
	done
	
	#output
	if [[ "$posneg" == "pos" ]]; then
		if [[ $multi == 1 ]]; then
			echo "INFO: One or multiple tuples have been found more than once."
		fi
	else #neg
		if [[ $multi == 1 ]]; then
			echo "INFO: One or multiple tuples have been found more than once in solution."
		fi
	fi
	
	return $result
}

#compares the tuples in tuplesArray with given file
function tupleComparerV2 {
	filename=$1
	posneg=$2
	cconsiderEntryOrder=$3
	cconsiderAttributeOrder=$4
	result=0
	multi=0
	#tuplesArray
	
	tuplesArrayLength=${#tuplesArray[@]}
	
	for (( linenumber=0; linenumber<$tuplesArrayLength; linenumber++ )); do

		if [[ $linenumber == 0 ]]; then
			linebefore=-1
		else 
			linebefore="${tuplesArray[$linenumber-1]}"
		fi
		
		line="${tuplesArray[$linenumber]}"
		
		if [[ $linenumber == $(($tuplesArrayLength-1)) ]]; then
			lineafter=-1
		else 
			lineafter="${tuplesArray[$linenumber+1]}"
		fi
		
		
		deb 4 '$linebefore =' "$linebefore"
		deb 4 '$line =' "$line"
		deb 4 '$lineafter =' "$lineafter"
		
		deb 4 "Function Call: createTupleRegexV2" "$linebefore" "$line" "$lineafter" "$tupleSeparator" $cconsiderEntryOrder $cconsiderAttributeOrder
		deb 4 '$tupleSeparator =' "$tupleSeparator"
		createTupleRegexV2 "$linebefore" "$line" "$lineafter" "$tupleSeparator" $cconsiderEntryOrder $cconsiderAttributeOrder
		#$param
		
		#run grep command and get the numbers of lines in the output file
		#==> logic: The output file must contain the tuple given in the solution file ==> Linecount >= 1
		#grep -Po "^(?=.*Amy)(?=.*female)(?=.*16).+" output.q
		
		getRegexResultCountFromFile "$filename" "$param" 0
		matchingLinesInOutut=$?
		
		deb 1 "matchingLinesInOutut = "$matchingLinesInOutut
		
		#evalute response
		if [[ "$posneg" == "pos" ]]; then
			if [[ $matchingLinesInOutut == 0 ]]; then
				deb 1 "Tupel/entry ("$line") is missing!"
				result=1

			elif [[ $matchingLinesInOutut == 1 ]]; then
				#deb "Ein Tupel"
				#deb ${values[*]}
				tmp=1

			elif [[ $matchingLinesInOutut -gt 1 ]]; then
				deb 1 "Tupel/entry ("$line") found "$matchingLinesInOutut" times."
				multi=1
			fi
		else #neg
			if [[ $matchingLinesInOutut == 0 ]]; then
				deb 1 "Tupel/entry ("$line") is not in solution!"
				result=1

			elif [[ $matchingLinesInOutut == 1 ]]; then
				#deb "Ein Tupel"
				#deb ${values[*]}
				tmp=1

			elif [[ $matchingLinesInOutut -gt 1 ]]; then
				deb 1 "Tupel/entry ("$line") found in solution "$matchingLinesInOutut" times."
				multi=1
			fi
		fi
	done
	
	#output
	if [[ "$posneg" == "pos" ]]; then
		if [[ $multi == 1 ]]; then
			echo "INFO: One or multiple tuples have been found more than once."
		fi
	else #neg
		if [[ $multi == 1 ]]; then
			echo "INFO: One or multiple tuples have been found more than once in solution."
		fi
	fi
	
	return $result
}

#creates the regex for output-solution-comparison
function createTupleRegex {
	line=$1
	separator="$2"
	param=""

	#line to array
	OLDIFS=$IFS
	IFS="$separator"
	read -ra values <<< "$line"
	IFS=$OLDIFS
	
	#create grep param for current line
	#^(?=.*Amy)(?=.*16)(?=.*female)(?!((.*,.*){3})).*$
	param=('^')
	for value in "${values[@]}"; do
		param=$param"(?=.*"$value")"
		deb 4 '$value =' "$value"
	done
	param=$param'(?!((.*'"$separator"'.*){'${#values[@]}'})).*$'
	deb 3 '$param=' "$param"
}



#creates the regex for output-solution-comparison
function createTupleRegexV2 {
	linebefore="$1"
	line="$2"
	lineafter="$3"
	separator="$4"
	cconsiderEntryOrder=$5
	cconsiderAttributeOrder=$6
	
	param='^'
	
	if [[ $cconsiderEntryOrder == 1 && $linebefore != -1 ]]; then
		createTupleRegexHelper "$linebefore" $cconsiderAttributeOrder
		#-> $paramPart
		param="$param""$paramPart"'(.*\n)*'
	fi
	
	createTupleRegexHelper "$line" $cconsiderAttributeOrder
	#-> $paramPart
	param="$param""$paramPart"
	
	if [[ $cconsiderEntryOrder == 1 && $lineafter != -1 ]]; then
		createTupleRegexHelper "$lineafter" $cconsiderAttributeOrder
		#-> $paramPart
		param="$param"'.*\n.*'"$paramPart"
	fi
	
	param="$param"'$'
	deb 3 '$param=' "$param"
}


function createTupleRegexHelper {
	anyline="$1"
	cconsiderAttributeOrder=$2
	paramPart=""
	
	splitStringToArray "$anyline" "$separator"
	#-> splittedStringArray
	
	#create grep param for current line
	#(?=.*Amy)(?=.*16)(?=.*female)(?!((.*,.*){3})).*
	for value in "${splittedStringArray[@]}"; do
		#handle leading and trailing spaces
		deb 4 "Command:" "echo" "$value" "|" "sed -E" 's/^[ \t]+|[ \t]+$//g'
		value=$(echo "$value" | sed -E 's/^[ \t]+|[ \t]+$//g')	
		deb 4 '$value =' "$value"
		
		#concat
		if [[ $cconsiderAttributeOrder == 1 ]]; then
			paramPart="$paramPart"".*"$value
		else
			paramPart="$paramPart""(?=.*"$value")"
		fi
		
		
	done
	paramPart="$paramPart"'(?!((.*'"$separator"'.*){'${#splittedStringArray[@]}'})).*'

	deb 3 '$paramPart=' "$paramPart"
}


#+---------------------+
#| CHECKING FUNCTIONS  |
#+---------------------+

#compares the "returned tuples" of output and solution file
function returnedTuplesChecker {
	solutionFile=$1
	outputFile=$2
	doExit=$3
	
	returnedTuplesComparer $solutionFile $outputFile $doExit
	if [[ $? -ne 0 ]]; then
		if [[ $doExit == 1 ]]; then
			echo 'ERROR: Number of "tuple(s) returned" does not match the expected solution!';
			exit 1
		else
			echo 'INFO: Number of "tuple(s) returned" does not match the expected solution.';
		fi
		
	fi
}

#compares the "returned tuples" of output and solution file
function returnedTuplesCheckerV2 {
	solutionFile="$1"
	outputFile="$2"
	textInQuotes="$3"
	doExit=$3
	
	returnedTuplesComparer "$solutionFile" "$outputFile" "$doExit"
	if [[ $? -ne 0 ]]; then
		if [[ $doExit == 1 ]]; then
			echo "ERROR: Number of \"""$textInQuotes""\" does not match the expected solution!";
			exit 1
		else
			echo "INFO: Number of \"""$textInQuotes""\" does not match the expected solution.";
		fi
		
	fi
}

#checks if the tuples in the solution file do also exist in the output file
function matchingTuplesChecker {
	solutionFile=$1
	outputFile=$2
	
	#load solution
	loadTuplesArrayFromFile "$solutionFile"
	tuplesSolution=("${tuplesArray[@]}")
	
	#load output
	loadTuplesArrayFromFile "$outputFile"
	tuplesOutput=("${tuplesArray[@]}")
	

	# compare files
	unset tuplesArray
	tuplesArray=("${tuplesSolution[@]}")
	tupleComparer "$outputFile" "pos"
	if [[ "$?" -ne 0 ]]; then
		echo "ERROR: At least one tuple is missing completely or misses at least one required attribute!"
		exit 1
	fi
	
	
	unset tuplesArray
	tuplesArray=("${tuplesOutput[@]}")
	tupleComparer "$solutionFile" "neg"
	if [[ "$?" -ne 0 ]]; then
		echo "ERROR: At least one of your tuples is not in the solution or contains at least one attribute which was not demanded!"
		exit 1
	fi
	
	
}


#checks if the tuples in the solution file do also exist in the output file
function matchingTuplesCheckerV2 {
	solutionFile="$1"
	outputFile="$2"
	textpartInMessage="$3"
	
	#load solution
	loadTuplesArrayFromFile "$solutionFile"
	tuplesSolution=("${tuplesArray[@]}")
	
	#load output
	loadTuplesArrayFromFile "$outputFile"
	tuplesOutput=("${tuplesArray[@]}")
	
	
	#check existence only
	unset tuplesArray
	tuplesArray=("${tuplesSolution[@]}")
	tupleComparerV2 "$outputFile" "pos" 0 0
	if [[ "$?" -ne 0 ]]; then
		echo "ERROR: At least one of your $textpartInMessage is missing completely or misses at least one required attribute!"
		exit 1
	fi
		
	unset tuplesArray
	tuplesArray=("${tuplesOutput[@]}")
	tupleComparerV2 "$solutionFile" "neg" 0 0
	if [[ "$?" -ne 0 ]]; then
		echo "ERROR: At least one of your $textpartInMessage is not in the solution or contains at least one attribute which was not demanded!"
		exit 1
	fi
	
	
	#check odering of attributes
	if [[ $considerAttributeOrder == 1 ]]; then
		unset tuplesArray
		tuplesArray=("${tuplesSolution[@]}")
		tupleComparerV2 "$outputFile" "pos" 0 1
		if [[ "$?" -ne 0 ]]; then
			echo "ERROR: Attributes in least one of your $textpartInMessage are ordered incorrectly!"
			exit 1
		fi
			
		unset tuplesArray
		tuplesArray=("${tuplesOutput[@]}")
		tupleComparerV2 "$solutionFile" "neg" 0 1
		if [[ "$?" -ne 0 ]]; then
			echo "ERROR: Attributes in least one of your $textpartInMessage are ordered incorrectly!"
			exit 1
		fi
	fi


	#check odering of entries too
	if [[ $considerEntryOrder == 1 ]]; then
		unset tuplesArray
		tuplesArray=("${tuplesSolution[@]}")
		tupleComparerV2 "$outputFile" "pos" 1 $considerAttributeOrder
		if [[ "$?" -ne 0 ]]; then
			echo "ERROR: At least one of your $textpartInMessage is ordered incorrectly!"
			exit 1
		fi
			
		unset tuplesArray
		tuplesArray=("${tuplesOutput[@]}")
		tupleComparerV2 "$solutionFile" "neg" 1 $considerAttributeOrder
		if [[ "$?" -ne 0 ]]; then
			echo "ERROR: At least one of your $textpartInMessage is ordered incorrectly!"
			exit 1
		fi
	fi
	
}




#++-----------------------++
#++-----------------------++
#||  RADB-SPECIFIC STUFF  ||
#++-----------------------++
#++-----------------------++


#+-----------------+
#| FILE FUNCTIONS  |
#+-----------------+

#UNUSED!!!
#writes the radb.ini file
function writeRadbIni()
{
	filename="$1"
	filecontent="$2"
	
	echo "$filecontent" > "$filename"
}


#+----------------+
#| RUN FUNCTIONS  |
#+----------------+

#runs radb with provided input file
function runRadb {
	cinputFile="$1"
	cdbFile="$2"
	coutputFile="$3"
	ciniFile="$4"
	result=0
	
	deb 1 "Using input file:" $inputFile
	deb 2 'Command: radb -c' "$ciniFile" '-i' "$cinputFile" "$cdbFile" '-o' "$coutputFile"
	
	radb -c "$ciniFile" -i "$cinputFile" "$cdbFile" -o "$coutputFile" &> "$radbLogFile"
	debcatFile "$radbLogFile" "$radbLogFile"
	
	radbErrorRegexCount=$(grep -Po "$radbErrorRegex" "$radbLogFile" | wc -l)
	deb 1 '$radbErrorRegexCount =' $radbErrorRegexCount
	
	radbInternalProblemCount=$(grep -Po "$radbInternalProblemRegex" "$radbLogFile" | wc -l)
	deb 1 '$radbInternalProblemCount =' $radbInternalProblemCount
	
	if [[ $radbErrorRegexCount -gt 0 ]]; then
		result=1
	fi
	
	if [[ $radbInternalProblemCount -gt 0 ]]; then
		result=2
	fi
	
	return $result
}



#+---------------------+
#| CHECKING FUNCTIONS  |
#+---------------------+
#usually these are called by the execute scripts

#runs radb and exits if errors occured
function runRadbChecker {
	cinputFile="$1"
	cdbFile="$2"
	coutputFile="$3"
	ciniFile="$4"
	cisStudentFile="$5"

	runRadb "$cinputFile" "$cdbFile" "$coutputFile" "$ciniFile"
	radbResult=$?
	
	if [[ $cisStudentFile == 1 ]]; then
		catOutputFile "$outputFile"
	fi
	
	if [[ "$radbResult" -ne 0 ]]; then
		if [[ $cisStudentFile == 1 && $radbResult != 2 ]]; then
			echo "ERROR: It seems there is an error in input file \"$inputFile\"."
		else
			echo "$internalErrorMessageLine01"
			echo "$internalErrorMessageLine02"
			echo "$internalErrorMessageExtra01" "RADB command failed"
		fi
		exit 1
	fi
}












#++-----------------------++
#++-----------------------++
#||  PSQL-SPECIFIC STUFF  ||
#++-----------------------++
#++-----------------------++


#+----------------+
#| DB MANAGEMENT  |
#+----------------+


#returns all availabe db users
function getDbUsers {
	executeSqlCommand "postgres" "$tmpSchemaName" "$dbpostgresuser" "$dbpostgrespass" "SELECT u.usename FROM pg_catalog.pg_user u;" "-t" "$psqldebuglog"
}

#returns all availabe databases
function getDbs {
	executeSqlCommand "postgres" "$tmpSchemaName" "$dbadminuser" "$dbadminpass" "SELECT datname FROM pg_database;" "-t" "$psqldebuglog"
}



#create temporary database
function createDb {
	tmpDbName="$1"
	tmpSchemaName="$2"
	
	deb 2 "creating database \"""$tmpDbName""\""
	executeSqlCommandWithPermission "postgres" "$tmpSchemaName" "admin" "CREATE DATABASE ${tmpDbName} OWNER ${dbadminuser};" "" "$psqldebuglog"
	
	#sideload config for new dbs
	sideloadDefault "psqlqueries/$psqlScriptCustomizeNewDb" 0 0
	
		
	deb 2 "changing schema and setting permissions"
	dbName="$tmpDbName" schemaName="$tmpSchemaName" envsubst < "$psqlScriptCustomizeNewDb" > "$psqlScriptCustomizeNewDb.replaced"
	
	executeSqlFileWithPermission "$tmpDbName" "$tmpSchemaName" "admin" "$psqlScriptCustomizeNewDb.replaced" "" "$psqldebuglog"
	
	if [[ $? -gt 0 ]]; then
		echo "$internalErrorMessageLine01"
		echo "$internalErrorMessageLine02"
		echo "$internalErrorMessageExtra01" "Creating database failed."
		exit 1
	fi
	
	
	#deleting temporary script
	rm "$psqlScriptCustomizeNewDb"
	rm "$psqlScriptCustomizeNewDb.replaced"
}


#loads data into database
function fillDb {
	tmpDbName="$1"
	tmpSchemaName="$2"
	filename="$3"
	
	executeSqlFileWithPermission "$tmpDbName" "$tmpSchemaName" "manager" "$filename" "" "$psqldebuglog"
	
	if [[ $? -gt 0 ]]; then
		echo "$internalErrorMessageLine01"
		echo "$internalErrorMessageLine02"
		echo "$internalErrorMessageExtra01" "Unable to fill database."
		exit 1
	fi
}



	
function createDefaultDbUsers {
	deb 2 "(re)creating default users..."
	
	sideloadDefault "psqlqueries/$psqlScriptCreateUsers" 0 0
	
	dbpostgresuser="$dbpostgresuser" dbpostgrespass="$dbpostgrespass" dbadminuser="$dbadminuser" dbadminpass="$dbadminpass" dbmanageruser="$dbmanageruser" dbmanagerpass="$dbmanagerpass" dbwriteuser="$dbwriteuser" dbwritepass="$dbwritepass" dbreaduser="$dbreaduser" dbreadpass="$dbreadpass" envsubst < "$psqlScriptCreateUsers" > "$psqlScriptCreateUsers.replaced"
	executeSqlFile "$tmpDbName" "$tmpSchemaName" "$dbpostgresuser" "$dbpostgrespass" "$psqlScriptCreateUsers.replaced" "" "$psqldebuglog"
	
	if [[ $? -gt 0 ]]; then
		echo "$internalErrorMessageLine01"
		echo "$internalErrorMessageLine02"
		echo "$internalErrorMessageExtra01" "Error with db users."
		exit 1
	fi
	
	#deleting temporary script
	rm "$psqlScriptCreateUsers"
	rm "$psqlScriptCreateUsers.replaced"
}


#drop temporary database
function dropDb {
	tmpDbName=$1
	
	deb 2 "deleting temporary database" $tmpDbName
	executeSqlCommandWithPermission "postgres" "$tmpSchemaName" "admin" "DROP DATABASE ${tmpDbName};" "" "$psqldebuglog"
	
	if [[ $? -gt 0 ]]; then
		echo "$internalErrorMessageLine01"
		echo "$internalErrorMessageLine02"
		echo "$internalErrorMessageExtra01" "Removing temporary database failed."
		exit 1
	fi
}


#sets the vars dbuser and dbpass depending on given permission
function getCredentialsFromPermission {
	dbpermission="$1"
	
	if [[ "$dbpermission" == "admin" ]]; then
		dbuser="$dbadminuser"
		dbpass="$dbadminpass"
	elif [[ "$dbpermission" == "manager" ]]; then
		dbuser="$dbmanageruser"
		dbpass="$dbmanagerpass"
	elif [[ "$dbpermission" == "write" ]]; then
		dbuser="$dbwriteuser"
		dbpass="$dbwritepass"
	elif [[ "$dbpermission" == "read" ]]; then
		dbuser="$dbreaduser"
		dbpass="$dbreadpass"
	fi 
}


#loads data into database
function executeSqlFileWithPermission {
	tmp2DbName="$1"
	tmp2SchemaName="$2"
	dbpermission="$3"
	filename="$4"
	extraArgs="$5"
	output="$6"
	
	getCredentialsFromPermission "$dbpermission"
	#-> dbuser, dbpass
	
	deb 2 "Executing file \"""$filename""\" with permission \"""$dbpermission""\" (-> i.e. with user \"""$dbuser""\") on db \"""$tmp2DbName""\", schema \"""$tmp2SchemaName""\"."
	
	executeSqlFile "$tmp2DbName" "$tmp2SchemaName" "$dbuser" "$dbpass" "$filename" "$extraArgs" "$output"
	return $?
}


#loads data into database
function executeSqlFile {
	tmp3DbName="$1"
	tmp3SchemaName="$2"
	dbuser="$3"
	dbpass="$4"
	filename="$5"
	extraArgs="$6"
	output="$7"
	result=0

	if [[ -z "$extraArgs" ]]; then
		PGPASSWORD="${dbpass}" psql -U "${dbuser}" -h "${dbhost}" -p "${dbport}" "${tmp3DbName}" "--pset=null=NULL" -f "${filename}" &> "${output}"
	else
		PGPASSWORD="${dbpass}" psql -U "${dbuser}" -h "${dbhost}" -p "${dbport}" "${tmp3DbName}" "--pset=null=NULL" -f "${filename}" "$extraArgs" &> "${output}"
	fi
		
	debcatFile "executeSqlFile" "$output"
	
	getRegexResultCountFromFile "$filename" "$psqlErrorRegex" 0
	psqlErrorCount=$?
	deb 4 '$psqlErrorCount =' $psqlErrorCount
	
	if [[ $psqlErrorCount -gt 0 ]]; then
		result=1
	fi
	
	getRegexResultCountFromFile "$filename" "$psqlPermissionErrorRegex" 0
	psqlErrorCount=$?
	deb 4 '$psqlErrorCount =' $psqlErrorCount
	
	if [[ $psqlErrorCount -gt 0 ]]; then
		result=2
	fi
	
	
	return $result
}


#execute an sql command with given permission
function executeSqlCommandWithPermission {
	tmp4DbName="$1"
	tmp5SchemaName="$2"
	dbpermission="$3"
	sqlcommand="$4"
	extraArgs="$5"
	output="$6"
	
	getCredentialsFromPermission "$dbpermission"
	#-> dbuser, dbpass
	
	deb 2 "Executing command \"""$sqlcommand""\" with permission \"""$dbpermission""\" (-> i.e. with user \"""$dbuser""\") on db \"""$tmp4DbName""\", schema \"""$tmp5SchemaName""\"."
	
	executeSqlCommand "$tmp4DbName" "$tmp5SchemaName" "$dbuser" "$dbpass" "$sqlcommand" "$extraArgs" "$output"
	return $?
}



#execute an sql command
function executeSqlCommand {
	tmp6DbName="$1"
	tmp6SchemaName="$2"
	dbuser="$3"
	dbpass="$4"
	sqlcommand="$5"
	extraArgs="$6"
	output="$7"
	result=0
	
	
	if [[ -z "$extraArgs" ]]; then
		PGPASSWORD="${dbpass}" psql -U "${dbuser}" -h "${dbhost}" -p "${dbport}" "${tmp6DbName}" "--pset=null=NULL" -c "${sqlcommand}" &> "${output}"
	else 
		PGPASSWORD="${dbpass}" psql -U "${dbuser}" -h "${dbhost}" -p "${dbport}" "${tmp6DbName}" "--pset=null=NULL" -c "${sqlcommand}" "$extraArgs" &> "${output}"
	fi
	
	debcatFile "executeSqlCommand" "$output"
	
	getRegexResultCountFromFile "$filename" "$psqlErrorRegex" 0
	psqlErrorCount=$?
	deb 4 '$psqlErrorCount =' $psqlErrorCount
	
	if [[ $psqlErrorCount -gt 0 ]]; then
		result=1
	fi
	
	getRegexResultCountFromFile "$filename" "$psqlPermissionErrorRegex" 0
	psqlErrorCount=$?
	deb 4 '$psqlErrorCount =' $psqlErrorCount
	
	if [[ $psqlErrorCount -gt 0 ]]; then
		result=2
	fi
	
	return $result
}


#+---------------------+
#| CHECKING FUNCTIONS  |
#+---------------------+


function precheckStudentsPsqlFile {
	filename="$1"
	result=0
	
	getRegexResultCountFromFile "$filename" "$psqlNotAllowedCommandsRegex" 0
	unallowedCommandsCount=$?
	
	deb 4 '$unallowedCommandsCount =' $unallowedCommandsCount
	
	if [[ $unallowedCommandsCount -gt 0 ]]; then
		result=2
	fi
	
	return $result
}


function checkDefaultDbUsersExist {
	defaultDbUsersExistResult=1;
	defaultUsers=( "$dbadminuser" "$dbmanageruser" "$dbwriteuser" "$dbreaduser" )
	for currentDefaultUser in "${defaultUsers[@]}"
	do
	   checkDbUserExists "$currentDefaultUser"
	   currentDefaultUserExists=$?
	   
	   if [[ $currentDefaultUserExists != 1 ]]; then
			defaultDbUsersExistResult=0;
			break
	   fi
	done
	
	deb 4 '$defaultDbUsersExistResult = ' $defaultDbUsersExistResult
	
	return $defaultDbUsersExistResult
}

function checkDbUserExists {
	userThatShouldExist="$1"
	
	deb 3 "checking if user \"""$userThatShouldExist""\" exists."
	getDbUsers
	#-> writes file $psqldebuglog
	
	deb 5 "Command: grep ""$userThatShouldExist" "$psqldebuglog"
	userExistsResult=$(grep "$userThatShouldExist" "$psqldebuglog" | wc -l)
	
	deb 4 '$userExistsResult = ' $userExistsResult
	
	return $userExistsResult
	
}

function checkDbExists {
	dbThatShouldExist="$1"
	
	deb 3 "checking if databases \"""$dbThatShouldExist""\" exists."
	getDbs
	#-> writes file $psqldebuglog
		
	deb 5 "Command: grep ""$dbThatShouldExist" "$psqldebuglog"
	dbExistsResult=$(grep "$dbThatShouldExist" "$psqldebuglog" | wc -l)
	
	deb 4 '$dbExistsResult = ' $dbExistsResult
	
	return $dbExistsResult
}