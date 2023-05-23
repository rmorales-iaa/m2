#!/bin/bash
#------------------------------------------------------------------------------
set -x  #debug
#------------------------------------------------------------------------------
#user input
OUTPUT_DIR=$1
INPUT_FILE=$2
#------------------------------------------------------------------------------
SOLVER=solve-field
#------------------------------------------------------------------------------
#with big stars, increase this value
DOWN_SAMPLE=2

TWEAK_ORDER=4
MIN_TWEAK_ORDER=2

#cpu limit time in seconds
CPU_LIMIT=60

#one degree
RADIUS=1

MAX_SOURCES=1000

#default FOV
DEFAULT_FOV_ARCMIN_LOW=1
DEFAULT_FOV_ARCMIN_HIGH=180

#no centre
NO_CENTRE_CPU_LIMIT=180
NO_CENTRE_MAX_SOURCES_RA_DEC=1000
NO_CENTRE_DOWN_SAMPLE=2
NO_CENTRE_FOV_ARCMIN_LOW=0.1
NO_CENTRE_FOV_ARCMIN_HIGH=180
#------------------------------------------------------------------------------
RA=""
DEC=""
RECORD_VALUE=""

RA_IN_HOURS=""

FOV_ARCMIN_LOW=$DEFAULT_FOV_ARCMIN_LOW
FOV_ARCMIN_HIGH=$DEFAULT_FOV_ARCMIN_HIGH
#------------------------------------------------------------------------------
IMAGE_NAME=$(basename -- "$INPUT_FILE")
IMAGE_NAME_NO_EXTENSION="${IMAGE_NAME%.*}"
IMAGE_PATH=$INPUT_DIR$IMAGE_NAME
SOLVED_IMAGE_FILENAME=$OUTPUT_DIR/$IMAGE_NAME_NO_EXTENSION".fits"
#------------------------------------------------------------------------------
RESULT=1
#------------------------------------------------------------------------------
function get_record_value() {
  value=${1#*"="}
  value="${value%%*( )}"
  value="${value##*( )}"
  if [[ $value = *"'"* ]]; then
    value="${value:1:-1}"
  fi
  RECORD_VALUE=$(echo $value | xargs)
}
#------------------------------------------------------------------------------
function update_ra() {
  RA_IN_HOURS="${RA_IN_HOURS,,}"  #to lower case
  if [[ "$RA_IN_HOURS" == *hours* ]]
  then
    RA=$(bc -l <<< "$RA * 15")
  fi
}
#------------------------------------------------------------------------------
function get_fov_x_arcmin() {
  RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^OM_FOV_X *=' | cut -d'=' -f 2)
  if [ -z "$RESULT" ]
  then
    FOV_ARCMIN_LOW=$DEFAULT_FOV_ARCMIN_LOW
  else
    get_record_value $RESULT
    FOV_ARCMIN_LOW=$RECORD_VALUE

    #add one arcmin to the calculated FOV
    FOV_ARCMIN_LOW=$(bc -l <<< "$FOV_ARCMIN_LOW - 0.5")
  fi
}
#------------------------------------------------------------------------------
function get_fov_y_arcmin() {
  RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^OM_FOV_Y *=' | cut -d'=' -f 2)
  if [ -z "$RESULT" ]
  then
    FOV_ARCMIN_HIGH=$DEFAULT_FOV_ARCMIN_HIGH
  else
    get_record_value $RESULT
    FOV_ARCMIN_HIGH=$RECORD_VALUE

    #add one arcmin to the calculated FOV
    FOV_ARCMIN_HIGH=$(bc -l <<< "$FOV_ARCMIN_HIGH + 0.5")
  fi
}
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
#------------------------------------------------------------------------------
function solve_fits_with_centre() {
  echo "Image '$INPUT_FILE' solving with centre and scale"
  $SOLVER $INPUT_FILE \
    --new-fits $SOLVED_IMAGE_FILENAME \
    --fits-image \
    --timestamp \
    --no-plots \
    --no-verify \
    --crpix-center \
    --downsample $DOWN_SAMPLE \
    --overwrite \
    --tweak-order $TWEAK_ORDER \
    --cpulimit $CPU_LIMIT \
    --objs $MAX_SOURCES \
    --ra "$RA" \
    --dec "$DEC" \
    --radius $RADIUS \
    --scale-units arcminwidth \
    --scale-low $FOV_ARCMIN_LOW \
    --scale-high $FOV_ARCMIN_HIGH
}
#------------------------------------------------------------------------------
function solve_fits_with_centre_default_scale() {
  echo "Image '$INPUT_FILE' solving with centre and default scale"
  $SOLVER $INPUT_FILE \
    --new-fits $SOLVED_IMAGE_FILENAME \
    --fits-image \
    --timestamp \
    --no-plots \
    --no-verify \
    --crpix-center \
    --downsample $DOWN_SAMPLE \
    --overwrite \
    --tweak-order $TWEAK_ORDER \
    --cpulimit $CPU_LIMIT \
    --objs $MAX_SOURCES \
    --ra "$RA" \
    --dec "$DEC" \
    --radius $RADIUS \
    --scale-units degwidth \
    --scale-low $DEFAULT_FOV_ARCMIN_LOW \
    --scale-high $DEFAULT_FOV_ARCMIN_HIGH
}
#------------------------------------------------------------------------------
function solve_fits_no_centre() {
  echo "Image '$INPUT_FILE' solving with NO centre and wide scale"
  $SOLVER $INPUT_FILE \
    --new-fits $SOLVED_IMAGE_FILENAME \
    --fits-image \
    --timestamp \
    --no-plots \
    --no-verify \
    --crpix-center \
    --downsample $NO_CENTRE_DOWN_SAMPLE \
    --overwrite \
    --tweak-order $TWEAK_ORDER \
    --cpulimit $NO_CENTRE_CPU_LIMIT \
    --objs $NO_CENTRE_MAX_SOURCES_RA_DEC \
    --scale-units degwidth \
    --scale-low $NO_CENTRE_FOV_ARCMIN_LOW \
    --scale-high $NO_CENTRE_FOV_ARCMIN_HIGH
}

#------------------------------------------------------------------------------
function solve_fits_no_centre_down_sample_1() {
  echo "Image '$INPUT_FILE' solving with NO CENTRE, wide scala and downsample 1"
  $SOLVER $INPUT_FILE \
    --new-fits $SOLVED_IMAGE_FILENAME \
    --fits-image \
    --timestamp \
    --no-plots \
    --no-verify \
    --crpix-center \
    --downsample 1 \
    --overwrite \
    --tweak-order $TWEAK_ORDER \
    --cpulimit $NO_CENTRE_CPU_LIMIT \
    --objs $NO_CENTRE_MAX_SOURCES_RA_DEC \
    --scale-units degwidth \
    --scale-low $NO_CENTRE_FOV_ARCMIN_LOW \
    --scale-high $NO_CENTRE_FOV_ARCMIN_HIGH
}
#------------------------------------------------------------------------------
function solve_fits() {

  get_fov_x_arcmin
  get_fov_y_arcmin
  if ! [ -z "$RA" ] && ! [ -z "$DEC" ]
  then
    update_ra
    solve_fits_with_centre
    if ! [ -f "$SOLVED_IMAGE_FILENAME" ]
    then
      echo "Image '$INPUT_FILE' not resolved using centre (ra,dec) ($RA,$DEC) and scale ($FOV_ARCMIN_LOW, $FOV_ARCMIN_HIGH). Trying with default scale"
      solve_fits_with_centre_default_scale
      if ! [ -f "$SOLVED_IMAGE_FILENAME" ]
      then
        echo "Image '$INPUT_FILE' not resolved. Trying with no centre"
        solve_fits_no_centre
        if ! [ -f "$SOLVED_IMAGE_FILENAME" ]
        then
          echo "Image '$INPUT_FILE' not resolved. Trying with no centre and downsample 1"
          solve_fits_no_centre_down_sample_1
        fi
      fi
    fi
  fi
}

#---------------------------------------------------------------------------
function RA_HMS_to_DD(){
  readarray  -d ':' -t TOKEN_SEQ <<<"$RA"
  hour=${TOKEN_SEQ[0]}
  min=${TOKEN_SEQ[1]}
  sec=${TOKEN_SEQ[2]}
  sec=$(echo "$sec" | xargs)
  RA=$(bc -l <<< "($hour * 15.0 ) + ($min / 4.0) + ($sec / 240.0)")
}
#---------------------------------------------------------------------------
function DEC_DMS_to_DD() {
  readarray  -d ':' -t TOKEN_SEQ <<<"$DEC"
  deg=${TOKEN_SEQ[0]}
  min=${TOKEN_SEQ[1]}
  sec=${TOKEN_SEQ[2]}
  sec=$(echo "$sec" | xargs)

  #check and remove sign
  if [[ $deg = -* ]]
  then
    sign=-1
  else
    sign=1
  fi

  if [[ $deg = +* ]]
  then
    deg="${deg#?}"
  fi

  DEC=$(bc -l <<< "$deg + ($sign * ($min / 60.0)) + ($sign * ($sec / 3600.0))")
}
#------------------------------------------------------------------------------
function fix_ra_dec_centre() {

  if ! [ -z "$RA" ] && ! [ -z "$DEC" ]
  then
    get_record_value "$RA"
    RA=$RECORD_VALUE

    get_record_value "$DEC"
    DEC=$RECORD_VALUE
  fi

  #trim RA and DEC
  RA=$(echo "$RA" | xargs)
  DEC=$(echo "$DEC" | xargs)

  #apply conversion to RA in degrees if it is necessary
  if [[ "$RA" == *" "* || "$RA" == *:* ]]
  then
    RA=${RA//" "/":"} #replace space by :
    RA_HMS_to_DD
  fi

  #apply conversion to DEC in degrees if it is necessary
  if [[ "$DEC" == *" "* || "$DEC" == *:* ]]
  then
    DEC=${DEC//" "/":"}  #replace space by :
    DEC_DMS_to_DD
  fi

  RA=$(printf '%.4f\n' $RA)
  DEC=$(printf '%.4f\n' $DEC)
}
#------------------------------------------------------------------------------
function get_ra_dec_centre_from_fits_header() {

  RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^CRVAL1 *=\|^CRVAL2 *=' | cut -d'/' -f 1)
  RA_IN_HOURS=$(astfits --hdu=0  $INPUT_FILE | grep -w '^CRVAL1 *=')

  if [ -z "$RESULT" ]
  then
    RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^RAJ2000 *=\|^DECJ2000 *=' | cut -d'/' -f 1)
    RA_IN_HOURS=$(astfits --hdu=0  $INPUT_FILE | grep -w '^RAJ2000 *=')
    if [ -z "$RESULT" ]
    then
      RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^RA *=\|^DEC *=' | cut -d'/' -f 1)
      RA_IN_HOURS=$(astfits --hdu=0  $INPUT_FILE | grep -w '^RA *=')
      if [ -z "$RESULT" ]
      then
        RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^OBJCTRA *=\|^OBJCTDEC *=' | cut -d'/' -f 1)
        RA_IN_HOURS=$(astfits --hdu=0  $INPUT_FILE | grep -w '^OBJCTRA *=')
        if [ -z "$RESULT" ]
        then
          RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^OBJRA *=\|^OBJDEC *=' | cut -d'/' -f 1)
          RA_IN_HOURS=$(astfits --hdu=0  $INPUT_FILE | grep -w '^OBJRA *=')
          if [ -z "$RESULT" ]
          then
            RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^RA-DEG *=\|^DEC-DEG *=' | cut -d'/' -f 1)
            RA_IN_HOURS=$(astfits --hdu=0  $INPUT_FILE | grep -w '^RA-DEG *=')
            if [ -z "$RESULT" ]
            then
              RESULT=$(astfits --hdu=0  $INPUT_FILE | grep -w '^CAT-RA *=\|^CAT-DEC *=' | cut -d'/' -f 1)
              RA_IN_HOURS=$(astfits --hdu=0  $INPUT_FILE | grep -w '^CAT-RA *=')
            fi
          fi
        fi
      fi
    fi
  fi

  readarray -t TOKEN_SEQ <<<"$RESULT"

  RA=${TOKEN_SEQ[0]}
  DEC=${TOKEN_SEQ[1]}
}

#--------------------------------------------
function check_wcs_is_valid() {
  A_0_0=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^A_0_0   =                    0 / no comment')
  A_0_1=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^A_0_1   =                    0 / no comment')

  B_0_0=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^B_0_0   =                    0 / no comment')
  B_0_1=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^B_0_1   =                    0 / no comment')


  AP_0_0=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^AP_0_0  =                    0 / no comment')
  AP_0_1=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^AP_0_1  =                    0 / no comment')

  BP_0_0=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^BP_0_0  =                    0 / no comment')
  BP_0_1=$(astfits --hdu=0  $SOLVED_IMAGE_FILENAME | grep -w  '^BP_0_1  =                    0 / no comment')

  if [ ! -z "$A_0_0" ] &&  [ ! -z "$A_0_1" ] && \
     [ ! -z "$B_0_0" ] &&  [ ! -z "$B_0_1" ] && \
     [ ! -z "$AP_0_0" ] && [ ! -z "$AP_0_1" ] && \
     [ ! -z "$BP_0_0" ] && [ ! -z "$BP_0_1" ]
  then
    RESULT=0
  else
    RESULT=1
  fi
}

#--------------------------------------------
function check_tweak_order() {
  check_wcs_is_valid

  if [ "${RESULT}" == 0 ]
  then
    echo "Invalid wcs:'$SOLVED_IMAGE_FILENAME'"
    if [ "$TWEAK_ORDER" -gt "$MIN_TWEAK_ORDER" ]
    then
      TWEAK_ORDER=$((TWEAK_ORDER-1))
      echo "Trying to solve with tweak order: $TWEAK_ORDER"
    fi
    RESULT=0
  else
    echo "Valid wcs:'$SOLVED_IMAGE_FILENAME'"
    RESULT=1
  fi
}
#--------------------------------------------
function parse_file() {
  FILE=$1

  echo "---->Processing file:" $IMAGE_NAME

  get_ra_dec_centre_from_fits_header
  fix_ra_dec_centre

  solve_fits

  #if it is solved then update pix scale and fov
  if [ -f "$SOLVED_IMAGE_FILENAME" ]
  then
    update_pix_scale_fov $SOLVED_IMAGE_FILENAME
  fi
}
#--------------------------------------------
parse_file $INPUT_FILE

if [ -f "$SOLVED_IMAGE_FILENAME" ]
 then

  #iterate trying to reduce the tweak order in case of error
  CONTINUE_LOOP=1
  while [ "${CONTINUE_LOOP}" == 1 ]
  do
    check_tweak_order
    if [ "${RESULT}" == 1 ] || [ "$TWEAK_ORDER" -lt "$MIN_TWEAK_ORDER" ]
    then
      CONTINUE_LOOP=0
    else
      parse_file $INPUT_FILE
    fi
  done

fi
#--------------------------------------------
#end of file
