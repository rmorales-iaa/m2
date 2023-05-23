#==================================================================================================
#!/bin/bash
#------------------------------------------------------------------------------
#constants
#------------------------------------------------------------------------------
#user input
ROOT_DIR=/home/rafa/Downloads/catalog_complete/
OUTPUT_FILE=$ROOT_DIR"joined_file.csv"
INPUT_FILE_EXTENSION=".csv"
#------------------------------------------------------------------------------
#vars
FILE_COUNT=0
DIR_COUNT=0
TOTAL_LINE_COUNT=0
START_TIME=$(date +'%s')
#------------------------------------------------------------------------------
function process_file {
  
  FULL_FILE=$1
  DIR=$2
  
  FILE_NAME=$(basename -- "$FULL_FILE")
  FILE_PARENT="$(dirname "$FULL_FILE")"/ #add the path divider
  FILE_EXTENSION="${FILE_NAME##*.}"
  FILE_NAME_NO_EXTENSION="${FILE_NAME%.*}"
  
  #get input fits filename
  RAW_FILE_NAME_WITH_PATH=$DIR/$FILE_NAME
  RAW_FILE_NAME="${FILE_NAME%#*}".fits
  
  LINE_COUNT=0
  
  while IFS= read -r line
  do
  
    if [[ ( "$LINE_COUNT" == 0 ) ]]
    then
    
      if [[ ( "$FILE_COUNT" == 0 ) ]];then
        echo $line" file_name" >>  $OUTPUT_FILE
      fi  
        
    else
      echo $line" "$RAW_FILE_NAME >> $OUTPUT_FILE
    fi
    LINE_COUNT=$((LINE_COUNT+1))    
  done < $RAW_FILE_NAME_WITH_PATH
 
  TOTAL_LINE_COUNT=$((TOTAL_LINE_COUNT+LINE_COUNT-1))   
  FILE_COUNT=$((FILE_COUNT+1))
}
#------------------------------------------------------------------------------
function process_dir {
  DIR_COUNT=$((DIR_COUNT+1))
  DIR=$1
  echo "Processing directory: " $DIR
  FILE_LIST="$(find $DIR -type f -name *$INPUT_FILE_EXTENSION)" #add the asterisk
  for FILE in $FILE_LIST; do
	process_file $FILE $DIR
  done
}
#------------------------------------------------------------------------------
function stats {
  echo "Directories processed :" $DIR_COUNT
  echo "Files processed       :" $FILE_COUNT
  echo "Total lines processed :" $TOTAL_LINE_COUNT
  
  echo "Elapsed time $(($(date +'%s') - $START_TIME)) seconds"
}
#------------------------------------------------------------------------------
rm -fr $OUTPUT_FILE
touch $OUTPUT_FILE
DIR_LIST="$(find $ROOT_DIR -maxdepth 1 -mindepth 1  -type d)"
for DIR in $DIR_LIST; do
   process_dir $DIR
done

echo "Generated file        : "$OUTPUT_FILE
#------------------------------------------------------------------------------
stats
#------------------------------------------------------------------------------
#end of file
#==================================================================================================
