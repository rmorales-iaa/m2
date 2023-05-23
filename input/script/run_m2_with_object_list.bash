#!/bin/bash
#------------------------------------------------------------------------------
set -x #debug on
#------------------------------------------------------------------------------
#constants
DEFAULT_VR=0.5
#------------------------------------------------------------------------------
#global variables
OBJECT_TYPE=""
OBJECT_NAME=""
V_R=""
SCRIPT_FILE=""
FILE_COUNT=0
REMOTE_HOST=nakbe
#------------------------------------------------------------------------------
M2_WCS_FITTING=1
M2_ABSOLUTE_PHOTOMETRY=2
M2_DIFFERENTIAL_PHOTOMETRY=4
M2_MERGE_SEASSONS=8
M2_ALL_STEPS=255
#------------------------------------------------------------------------------
function call_m2_for_all_script_steps() {
  echo "executing m2 script: '$SCRIPT_FILE' with all steps"  
  $SCRIPT_FILE $M2_ALL_STEPS
}

#------------------------------------------------------------------------------
function call_m2_for_generate_scripts() {

  echo "generating m2 script for object '$OBJECT_NAME'"
  if [[ "$OBJECT_TYPE" == "mpo" ]]
    then            
      java -jar m2.jar --query $OBJECT_NAME --vr $V_R --remote-host $REMOTE_HOST
    else       
      java -jar m2.jar --query $OBJECT_NAME --vr $V_R --remote-host $REMOTE_HOST --star
  fi  
}

#------------------------------------------------------------------------------
function call_m2_for_wcs_fitting() {
  if [[ "$OBJECT_TYPE" == "mpo" ]]
    then        
      echo "executing m2 script: '$SCRIPT_FILE' and calculating wcs fitting with argument:'$M2_WCS_FITTING'"
      $SCRIPT_FILE $M2_WCS_FITTING 
    else 
      echo ""
  fi  
}
#------------------------------------------------------------------------------
function call_m2_for_absolute_photometry() {
  if [[ "$OBJECT_TYPE" == "mpo" ]]
    then  
      echo "executing m2 script: '$SCRIPT_FILE' and calculating absolute photometry with argument:'$M2_ABSOLUTE_PHOTOMETRY'"
      $SCRIPT_FILE $M2_ABSOLUTE_PHOTOMETRY 
    else 
      echo ""
  fi  
}

#------------------------------------------------------------------------------
function call_m2_for_differential_photometry() {
  if [[ "$OBJECT_TYPE" == "mpo" ]]
    then  
      echo "executing m2 script: '$SCRIPT_FILE' and calculating differential photometry with argument:'$M2_DIFFERENTIAL_PHOTOMETRY'"
      $SCRIPT_FILE $M2_DIFFERENTIAL_PHOTOMETRY 
    else 
      echo ""
  fi  
}
#------------------------------------------------------------------------------
function call_m2_for_merge_seasons() {
  if [[ "$OBJECT_TYPE" == "mpo" ]]
    then  
      echo "executing m2 script: '$SCRIPT_FILE' and merge seasons with argument:'$M2_MERGE_SEASSONS'"
      $SCRIPT_FILE $M2_MERGE_SEASSONS 
    else 
      echo ""
  fi  
}

out2var() {
  SCRIPT_FILE=$("$@")
  printf '%s\n'$SCRIPT_FILE
}
#------------------------------------------------------------------------------
function find_script_name() {
  SCRIPT_FILE=$(find . -maxdepth 1 -iname "*$OBJECT_NAME*" -exec echo {} \;)
  echo "    Found m2 script: '$SCRIPT_FILE'" 
}
#------------------------------------------------------------------------------
#check input file
if [ $# -eq 0 ];then
    echo "Please, provide a file with the list of objects to be procesed by m2."
    exit
fi

INPUT_FILE=$1
startTime=$(date +'%s')

echo "Processing the list of objects:"
while read LINE; do

   #avoid command and blank lines
   [[ "$LINE" =~ ^[[:space:]]*# ]] && continue
   [ -z "$LINE" ] && continue
  
   FILE_COUNT=$((FILE_COUNT+1))
   
   #avoid header
   if [[ "$FILE_COUNT" == 1 ]]; then continue
   fi
   
   #split the line and get the info
   IFS=';' read -ra SPLIT_SEQ <<< "$LINE"
   unset IFS
  
   OBJECT_TYPE=${SPLIT_SEQ[0]}  
   OBJECT_NAME=${SPLIT_SEQ[1]}  
   V_R=${SPLIT_SEQ[2]}  
   
   #check default values
   if [ -z "$V_R" ];then
     V_R=$DEFAULT_VR
   fi
   
   #show user's input
   if [[ "$OBJECT_TYPE" == "mpo" ]]
     then
       echo "    Processing mpo: '$OBJECT_NAME'"
     else  
       echo "    Processing star: '$OBJECT_NAME'"
   fi  
  
   #------------------------------------------
   #actions to be executed
   
   
   #------------------------------------------
   #call_m2_for_generate_scripts
   #------------------------------------------
    find_script_name  #always first action
     
     
     #call_m2_for_wcs_fitting
     #call_m2_for_absolute_photometry
     #call_m2_for_differential_photometry
     #call_m2_for_merge_seasons   
     call_m2_for_all_script_steps
   #------------------------------------------
   
done < $INPUT_FILE

echo "---------->Elapsed time: $(($(date +'%s') - $startTime))s"
#------------------------------------------------------------------------------
#end of script
