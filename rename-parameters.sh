#!/bin/bash -ex

get-and-rename-parameters () {

  # jq wants env. variables to be exported
  export SOURCEPATH="${1:-/}"
  export DESTINATIONPATH="${2:-/}"
  export TYPE="${3:-String}"
  export KEYID="${4:-""}"
  export OUTPUTFILE="get-parameters-by-path-output.json"
  export RENAMEDFILE="put-parameters-list.txt"
  export DESCRIPTION=""
  export OVERWRITE="true"
  export ALLOWEDPATTERN=""

  echo "Get parameters from SSM Parameter Store path ${SOURCEPATH} and store them to ${OUTPUTFILE}"
  
  aws ssm get-parameters-by-path \
    --with-decryption \
    --recursive \
    --path ${SOURCEPATH} > ${OUTPUTFILE}

  echo "Mangle the parameters to put-parameters format"
  
  jq -c -r '.Parameters[] | {Name: .Name, Description: env.DESCRIPTION, Value: .Value, Type: env.TYPE, KeyId: env.KEYID, Overwrite: env.OVERWRITE, AllowedPattern: env.ALLOWEDPATTERN}' ${OUTPUTFILE} \
    | sed -e "s|${SOURCEPATH}|${DESTINATIONPATH}|g" > ${RENAMEDFILE}

  echo "List of modified parameter objects are stored into ${RENAMEDFILE}"

  # unset all exported variables for sanity
  unset OUTPUTFILE
  unset RENAMEDFILE
  unset SOURCEPATH
  unset DESTINATIONPATH
  unset DESCRIPTION
  unset TYPE
  unset KEYID
  unset OVERWRITE
  unset ALLOWEDPATTERN
}

put-parameters () {
  local INPUTFILE="${1:-put-parameters-list.txt}"

  for i in $(cat ${INPUTFILE}); do 
    aws ssm put-parameter --cli-input-json $i; 
  done
}
