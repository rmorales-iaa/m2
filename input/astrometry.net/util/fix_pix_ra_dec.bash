#!/bin/bash

#----------------------------------------------
ROOT_DIR=$1
#-----------------------------------------------
RA=279.2958
DEC=-6.830556
USER_TELESCOPE=SOAR
#-----------------------------------------------
startTime=$(date +'%s')
echo "========================================================================="
echo $(date +"%Y-%m-%d:%Hh:%Mm:%Ss") 'Parsing all files'
echo "========================================================================="
#-----------------------------------------------
#set -x   #debug
#-----------------------------------------------
function process_file() {
  INPUT_FILE=$1
  TELESCOPE=$(astfits --hdu=0  $INPUT_FILE --minmapsize=10000000 | grep -w '^OM_TELES *=' | cut -d'=' -f 2)
  if [[ "$TELESCOPE" == *"$USER_TELESCOPE"* ]]
  then  
     echo "Updated file: '$INPUT_FILE'"
     astfits --hdu 0 $INPUT_FILE --minmapsize=10000000 --update=RA,$RA
     astfits --hdu 0 $INPUT_FILE --minmapsize=10000000 --update=DEC,$DEC
  fi 
}
#-----------------------------------------------
FILE_LIST=$(find $ROOT_DIR -name '*.fits')
for FILE in $FILE_LIST;do 
 process_file $FILE
done

#--------------------------------------------------
echo "========================================================================="
echo $(date +"%Y-%m-%d:%Hh:%Mm:%Ss") 'End of parsing all files'
echo "========================================================================="
echo "Elapsed time: $(($(date +'%s') - $startTime))s"

