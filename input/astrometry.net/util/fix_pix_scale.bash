#!/bin/bash

#----------------------------------------------
ROOT_DIR=$1
#-----------------------------------------------
OM_FOV_X=10.6431
OM_FOV_Y=7.098
USER_TELESCOPE=WHT
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
     astfits --hdu 0 $INPUT_FILE --minmapsize=10000000 --update=OM_FOV_X,$OM_FOV_X
     astfits --hdu 0 $INPUT_FILE --minmapsize=10000000 --update=OM_FOV_Y,$OM_FOV_Y
  fi 
}
#-----------------------------------------------
#FILE_LIST=$(find $ROOT_DIR -name '*.fits')
FILE_LIST=$(find $ROOT_DIR -name '*2394x1597*.fits')

for FILE in $FILE_LIST;do 
 process_file $FILE
done

#--------------------------------------------------
echo "========================================================================="
echo $(date +"%Y-%m-%d:%Hh:%Mm:%Ss") 'End of parsing all files'
echo "========================================================================="
echo "Elapsed time: $(($(date +'%s') - $startTime))s"

