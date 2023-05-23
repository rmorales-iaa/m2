#!/bin/bash
#-----------------------------------------------
#set -x   #debug
#-----------------------------------------------
INPUT_DIR=$1
#-----------------------------------------------
OUPUT_FILENAME=all.csv
FILE_EXTENSION=*.tar.xz
FILE_TO_DECOMPRESS=output/light_curve/ms4_307261/all/all.csv
#-----------------------------------------------
patttern='(.*)-2022'
#-----------------------------------------------
startTime=$(date +'%s')
echo "========================================================================="
echo $(date +"%Y-%m-%d:%Hh:%Mm:%Ss") 'Parsing all files'
echo "========================================================================="
#-----------------------------------------------
function process_file() {
  F=$1
  echo "Processing file: '$F'"
  tar -xvf $F $FILE_TO_DECOMPRESS 
  
  NAME=$(basename $F)
  
  [[ "$NAME" =~ $patttern ]]
  PREFIX="${BASH_REMATCH[1]}"
  
  cp $FILE_TO_DECOMPRESS ./$PREFIX.csv
  rm -fr $FILE_TO_DECOMPRESS 
}
#-----------------------------------------------

#decompress
FILE_LIST=$(find $INPUT_DIR -name '*.xz')
for FILE in $FILE_LIST;do 
 process_file $FILE
done

#prepare output file
if [ -f $OUPUT_FILENAME ]
then
  rm $OUPUT_FILENAME
fi

set -x   #debug
#merge all csv's
IS_FIRST_FILE=true
FILE_LIST=$(find $PWD -name '*.csv' -maxdepth 1 -mindepth 1 | sort)
for FILE in $FILE_LIST;do 
  if [ "$IS_FIRST_FILE" = true ]
  then    
    cp $FILE $OUPUT_FILENAME
    IS_FIRST_FILE=false    
  else
    awk '(NR != 1)' $FILE >> $OUPUT_FILENAME   
  fi   
done
#-----------------------------------------------
echo "========================================================================="
echo $(date +"%Y-%m-%d:%Hh:%Mm:%Ss") 'End of parsing all files'
echo "========================================================================="
echo "Elapsed time: $(($(date +'%s') - $startTime))s"

