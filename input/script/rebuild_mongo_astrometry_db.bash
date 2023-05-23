#!/bin/bash
#-----------------------------------------------
#rebuild the database where the solved images are: ROOT_DIR
ROOT_DIR=/home/rafa/om-cal/
#-----------------------------------------------
#set -x	  #enable debug
#-----------------------------------------------
for YEAR in {2000..2050}
do
  dir=$ROOT_DIR/$YEAR/wcs/
  if [ -d $dir ]
   then
     echo "Parsing directory: '$dir'"
     java -jar m2.jar --astrometry-catalog $dir
  fi
done
#-----------------------------------------------
java -jar m2.jar --astrometry-catalog /home/rafa/om-cal/external
#-----------------------------------------------
