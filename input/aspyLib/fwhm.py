import numpy as np
from scipy.optimize import leastsq

def fit_gauss_circular(xy, data):
    """
    ---------------------
    Purpose
    Fitting a star with a 2D circular gaussian PSF.
    ---------------------
    Inputs
    * xy (list) = list with the form [x,y] where x and y are the integer positions in the complete image of the first pixel (the one with x=0 and y=0) of the small subimage that is used for fitting.
    * data (2D Numpy array) = small subimage, obtained from the full FITS image by slicing. It must contain a single object : the star to be fitted, placed approximately at the center.
    ---------------------
    Output (list) = list with 6 elements, in the form [maxi, floor, height, mean_x, mean_y, fwhm]. The list elements are respectively:
    - maxi is the value of the star maximum signal,
    - floor is the level of the sky background (fit result),
    - height is the PSF amplitude (fit result),
    - mean_x and mean_y are the star centroid x and y positions, on the full image (fit results),
    - fwhm is the gaussian PSF full width half maximum (fit result) in pixels
    ---------------------
    """

    #find starting values
    maxi = data.max()
    floor = np.ma.median(data.flatten())
    height = maxi - floor
    if height==0.0:				#if star is saturated it could be that median value is 32767 or 65535 --> height=0
        floor = np.mean(data.flatten())
        height = maxi - floor
    mean_x = (np.shape(data)[0]-1)/2
    mean_y = (np.shape(data)[1]-1)/2
    fwhm = np.sqrt(np.sum((data>floor+height/2.).flatten()))
    #---------------------------------------------------------------------------------
    sig = fwhm / (2.*np.sqrt(2.*np.log(2.)))
    width = 0.5/np.square(sig)
    p0 = floor, height, mean_x, mean_y, width
    #---------------------------------------------------------------------------------
    #fitting gaussian
    def gauss(floor, height, mean_x, mean_y, width):
        return lambda x,y: floor + height*np.exp(-np.abs(width)*((x-mean_x)**2+(y-mean_y)**2))

    def err(p,data):
        return np.ravel(gauss(*p)(*np.indices(data.shape))-data)

    p = leastsq(err, p0, args=(data), maxfev=1000)
    p = p[0]

    #---------------------------------------------------------------------------------
    #formatting results
    floor = p[0]
    height = p[1]

    mean_x = p[2] + xy[0]
    mean_y = p[3] + xy[1]

    sig = np.sqrt(0.5/np.abs(p[4]))
    fwhm = sig * (2.*np.sqrt(2.*np.log(2.)))

    output = [maxi, floor, height, mean_x, mean_y, fwhm]
    return output

def fit_gauss_elliptical(xy, data):
    """
    ---------------------
    Purpose
    Fitting a star with a 2D elliptical gaussian PSF.
    ---------------------
    Inputs
    * xy (list) = list with the form [x,y] where x and y are the integer positions in the complete image of the first pixel (the one with x=0 and y=0) of the small subimage that is used for fitting.
    * data (2D Numpy array) = small subimage, obtained from the full FITS image by slicing. It must contain a single object : the star to be fitted, placed approximately at the center.
    ---------------------
    Output (list) = list with 8 elements, in the form [maxi, floor, height, mean_x, mean_y, fwhm_small, fwhm_large, angle]. The list elements are respectively:
    - maxi is the value of the star maximum signal,
    - floor is the level of the sky background (fit result),
    - height is the PSF amplitude (fit result),
    - mean_x and mean_y are the star centroid x and y positions, on the full image (fit results),
    - fwhm_small is the smallest full width half maximum of the elliptical gaussian PSF (fit result) in pixels
    - fwhm_large is the largest full width half maximum of the elliptical gaussian PSF (fit result) in pixels
    - angle is the angular direction of the largest fwhm, measured clockwise starting from the vertical direction (fit result) and expressed in degrees. The direction of the smallest fwhm is obtained by adding 90 deg to angle.
    ---------------------
    """

    #find starting values
    maxi = data.max()
    floor = np.ma.median(data.flatten())
    height = maxi - floor
    if height==0.0:				#if star is saturated it could be that median value is 32767 or 65535 --> height=0
        floor = np.mean(data.flatten())
        height = maxi - floor

    mean_x = (np.shape(data)[0]-1)/2
    mean_y = (np.shape(data)[1]-1)/2

    fwhm = np.sqrt(np.sum((data>floor+height/2.).flatten()))
    fwhm_1 = fwhm
    fwhm_2 = fwhm
    sig_1 = fwhm_1 / (2.*np.sqrt(2.*np.log(2.)))
    sig_2 = fwhm_2 / (2.*np.sqrt(2.*np.log(2.)))

    angle = 0.

    p0 = floor, height, mean_x, mean_y, sig_1, sig_2, angle

    #---------------------------------------------------------------------------------
    #fitting gaussian
    def gauss(floor, height, mean_x, mean_y, sig_1, sig_2, angle):

        A = (np.cos(angle)/sig_1)**2. + (np.sin(angle)/sig_2)**2.
        B = (np.sin(angle)/sig_1)**2. + (np.cos(angle)/sig_2)**2.
        C = 2.0*np.sin(angle)*np.cos(angle)*(1./(sig_1**2.)-1./(sig_2**2.))

        #do not forget factor 0.5 in exp(-0.5*r**2./sig**2.)
        return lambda x,y: floor + height*np.exp(-0.5*(A*((x-mean_x)**2)+B*((y-mean_y)**2)+C*(x-mean_x)*(y-mean_y)))

    def err(p,data):
        return np.ravel(gauss(*p)(*np.indices(data.shape))-data)

    p = leastsq(err, p0, args=(data), maxfev=1000)
    p = p[0]

    #---------------------------------------------------------------------------------
    #formatting results
    floor = p[0]
    height = p[1]
    mean_x = p[2] + xy[0]
    mean_y = p[3] + xy[1]

    #angle gives the direction of the p[4]=sig_1 axis, starting from x (vertical) axis, clockwise in direction of y (horizontal) axis
    if np.abs(p[4])>np.abs(p[5]):

        fwhm_large = np.abs(p[4]) * (2.*np.sqrt(2.*np.log(2.)))
        fwhm_small = np.abs(p[5]) * (2.*np.sqrt(2.*np.log(2.)))
        angle = np.arctan(np.tan(p[6]))

    else:	#then sig_1 is the smallest : we want angle to point to sig_y, the largest

        fwhm_large = np.abs(p[5]) * (2.*np.sqrt(2.*np.log(2.)))
        fwhm_small = np.abs(p[4]) * (2.*np.sqrt(2.*np.log(2.)))
        angle = np.arctan(np.tan(p[6]+np.pi/2.))

    output = [maxi, floor, height, mean_x, mean_y, fwhm_small, fwhm_large, angle]
    return output

def fit_moffat_circular(xy, data):
    """
    ---------------------
    Purpose
    Fitting a star with a 2D circular moffat PSF.
    ---------------------
    Inputs
    * xy (list) = list with the form [x,y] where x and y are the integer positions in the complete image of the first pixel (the one with x=0 and y=0) of the small subimage that is used for fitting.
    * data (2D Numpy array) = small subimage, obtained from the full FITS image by slicing. It must contain a single object : the star to be fitted, placed approximately at the center.
    ---------------------
    Output (list) = list with 7 elements, in the form [maxi, floor, height, mean_x, mean_y, fwhm, beta]. The list elements are respectively:
    - maxi is the value of the star maximum signal,
    - floor is the level of the sky background (fit result),
    - height is the PSF amplitude (fit result),
    - mean_x and mean_y are the star centroid x and y positions, on the full image (fit results),
    - fwhm is the gaussian PSF full width half maximum (fit result) in pixels
    - beta is the "beta" parameter of the moffat function
    ---------------------
    """

    #---------------------------------------------------------------------------------
    #find starting values
    maxi = data.max()
    floor = np.ma.median(data.flatten())
    height = maxi - floor
    if height==0.0:				#if star is saturated it could be that median value is 32767 or 65535 --> height=0
        floor = np.mean(data.flatten())
        height = maxi - floor

    mean_x = (np.shape(data)[0]-1)/2
    mean_y = (np.shape(data)[1]-1)/2

    fwhm = np.sqrt(np.sum((data>floor+height/2.).flatten()))

    beta = 4

    p0 = floor, height, mean_x, mean_y, fwhm, beta

    #---------------------------------------------------------------------------------
    #fitting gaussian
    def moffat(floor, height, mean_x, mean_y, fwhm, beta):
        alpha = 0.5*fwhm/np.sqrt(2.**(1./beta)-1.)
        return lambda x,y: floor + height/((1.+(((x-mean_x)**2+(y-mean_y)**2)/alpha**2.))**beta)

    def err(p,data):
        return np.ravel(moffat(*p)(*np.indices(data.shape))-data)

    p = leastsq(err, p0, args=(data), maxfev=1000)
    p = p[0]

    #---------------------------------------------------------------------------------
    #formatting results
    floor = p[0]
    height = p[1]
    mean_x = p[2] + xy[0]
    mean_y = p[3] + xy[1]
    fwhm = np.abs(p[4])
    beta = p[5]

    output = [maxi, floor, height, mean_x, mean_y, fwhm, beta]
    return output

def fit_moffat_elliptical(xy, data):
    """
    ---------------------
    Purpose
    Fitting a star with a 2D elliptical moffat PSF.
    ---------------------
    Inputs
    * xy (list) = list with the form [x,y] where x and y are the integer positions in the complete image of the first pixel (the one with x=0 and y=0) of the small subimage that is used for fitting.
    * data (2D Numpy array) = small subimage, obtained from the full FITS image by slicing. It must contain a single object : the star to be fitted, placed approximately at the center.
    ---------------------
    Output (list) = list with 9 elements, in the form [maxi, floor, height, mean_x, mean_y, fwhm_small, fwhm_large, angle, beta]. The list elements are respectively:
    - maxi is the value of the star maximum signal,
    - floor is the level of the sky background (fit result),
    - height is the PSF amplitude (fit result),
    - mean_x and mean_y are the star centroid x and y positions, on the full image (fit results),
    - fwhm_small is the smallest full width half maximum of the elliptical gaussian PSF (fit result) in pixels
    - fwhm_large is the largest full width half maximum of the elliptical gaussian PSF (fit result) in pixels
    - angle is the angular direction of the largest fwhm, measured clockwise starting from the vertical direction (fit result) and expressed in degrees. The direction of the smallest fwhm is obtained by adding 90 deg to angle.
    - beta is the "beta" parameter of the moffat function
    ---------------------
    """

    #---------------------------------------------------------------------------------
    #find starting values
    maxi = data.max()
    floor = np.ma.median(data.flatten())
    height = maxi - floor
    if height==0.0:				#if star is saturated it could be that median value is 32767 or 65535 --> height=0
        floor = np.mean(data.flatten())
        height = maxi - floor

    mean_x = (np.shape(data)[0]-1)/2
    mean_y = (np.shape(data)[1]-1)/2

    fwhm = np.sqrt(np.sum((data>floor+height/2.).flatten()))
    fwhm_1 = fwhm
    fwhm_2 = fwhm

    angle = 0.
    beta = 4

    p0 = floor, height, mean_x, mean_y, fwhm_1, fwhm_2, angle, beta

    #---------------------------------------------------------------------------------
    #fitting gaussian
    def moffat(floor, height, mean_x, mean_y, fwhm_1, fwhm_2, angle, beta):

        alpha_1 = 0.5*fwhm_1/np.sqrt(2.**(1./beta)-1.)
        alpha_2 = 0.5*fwhm_2/np.sqrt(2.**(1./beta)-1.)

        A = (np.cos(angle)/alpha_1)**2. + (np.sin(angle)/alpha_2)**2.
        B = (np.sin(angle)/alpha_1)**2. + (np.cos(angle)/alpha_2)**2.
        C = 2.0*np.sin(angle)*np.cos(angle)*(1./alpha_1**2. - 1./alpha_2**2.)

        return lambda x,y: floor + height/((1.+ A*((x-mean_x)**2) + B*((y-mean_y)**2) + C*(x-mean_x)*(y-mean_y))**beta)

    def err(p,data):
        return np.ravel(moffat(*p)(*np.indices(data.shape))-data)

    p = leastsq(err, p0, args=(data), maxfev=1000)
    p = p[0]

    #---------------------------------------------------------------------------------
    #formatting results
    floor = p[0]
    height = p[1]
    mean_x = p[2] + xy[0]
    mean_y = p[3] + xy[1]
    beta = p[7]

    #angle gives the direction of the p[4]=fwhm_1 axis, starting from x (vertical) axis, clockwise in direction of y (horizontal) axis
    if np.abs(p[4])>np.abs(p[5]):

        fwhm_large = np.abs(p[4])
        fwhm_small = np.abs(p[5])
        angle = np.arctan(np.tan(p[6]))

    else:	#then fwhm_1 is the smallest : we want angle to point to sig_y, the largest

        fwhm_large = np.abs(p[5])
        fwhm_small = np.abs(p[4])
        angle = np.arctan(np.tan(p[6]+np.pi/2.))

    output = [maxi, floor, height, mean_x, mean_y, fwhm_small, fwhm_large, angle, beta]
    return output
