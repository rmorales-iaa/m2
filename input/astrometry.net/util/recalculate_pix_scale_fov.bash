#!/bin/bash
#------------------------------------------------------------------------------
#user input
INPUT_DIR=$1
#------------------------------------------------------------------------------
shopt -s extglob
#set -x  #debug
#------------------------------------------------------------------------------
FILE_EXTENSION='*.fits'
#------------------------------------------------------------------------------
ASTFITS_MIN_MAP_SIZE=5000000 
#------------------------------------------------------------------------------
function update_pix_scale_fov() {
  FITS_FILE_NAME=$1
  RESULT=$(astfits --hdu=0 $FITS_FILE_NAME --pixelscale --quiet)
  if [ -n "$RESULT" ]
  then
    #calculate pixscale using astfits    
    IFS=' ' read -r -a array <<< "$RESULT"
    PIX_SCALE_X="${array[0]}"
    PIX_SCALE_Y="${array[1]}"
    
    #astfits return the pixel scale in degrees/pix and including the binning, so convert it to arcosec/pix
    #asumming same binnig in both axes
    PIX_SCALE_X=$(awk -v a=$PIX_SCALE_X 'BEGIN { print a * 3600 }')
    PIX_SCALE_Y=$(awk -v a=$PIX_SCALE_Y 'BEGIN { print a * 3600 }')
    PIX_SCALE_X=$(printf '%.4f\n' $PIX_SCALE_X)
    PIX_SCALE_Y=$(printf '%.4f\n' $PIX_SCALE_Y)

    #update pixel scale
    astfits --hdu 0 $FITS_FILE_NAME --update=OM_PIXSX,$PIX_SCALE_X,"arcosec/pixel"
    astfits --hdu 0 $FITS_FILE_NAME --update=OM_PIXSY,$PIX_SCALE_Y,"arcosec/pixel"

    #calculate FOV (field of view) in arcminutes    
    XPIX=$(astfits --hdu=0  $FITS_FILE_NAME | grep -w 'NAXIS1 *=' | cut -d'/' -f 1 |cut -d'=' -f 2)
    YPIX=$(astfits --hdu=0  $FITS_FILE_NAME | grep -w 'NAXIS2 *=' | cut -d'/' -f 1 |cut -d'=' -f 2)
    XPIX=$(echo "$XPIX" | xargs)
    YPIX=$(echo "$YPIX" | xargs)

    FOV_X=$(awk -v a=$PIX_SCALE_X -v b=$XPIX 'BEGIN { print (a * b) / 60 }')
    FOV_Y=$(awk -v a=$PIX_SCALE_Y -v b=$YPIX 'BEGIN { print (a * b) / 60 }')
    FOV_X=$(printf '%.4f\n' $FOV_X)
    FOV_Y=$(printf '%.4f\n' $FOV_Y)

    #update FOV (field of view)
    astfits --hdu 0 $FITS_FILE_NAME --update=OM_FOV_X,$FOV_X,"arcomin"
    astfits --hdu 0 $FITS_FILE_NAME --update=OM_FOV_Y,$FOV_Y,"arcomin"

  fi
}
#--------------------------------------------
FILE_LIST=$(find $INPUT_DIR -name $FILE_EXTENSION)
for FILE in $FILE_LIST;do 
  echo "Processing file: '$FILE'"
  update_pix_scale_fov $FILE
done
#-------------------
