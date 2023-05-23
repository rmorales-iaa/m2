#!/bin/bash

#----------------------------------------------
ROOT_DIR=$1
#-----------------------------------------------
CRVAL1=276.294978493
CRVAL2=-7.96692185087
USER_TELESCOPE=ESO_MPI_2_2
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
     astfits --hdu 0 $INPUT_FILE --minmapsize=10000000 --update=CRVAL1,$CRVAL1
     astfits --hdu 0 $INPUT_FILE --minmapsize=10000000 --update=CRVAL2,$CRVAL2
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

