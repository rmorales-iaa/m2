import sys
import numpy
from fwhm import fit_gauss_circular,fit_gauss_elliptical,fit_moffat_circular,fit_moffat_elliptical
#----------------------------------------------------
try :    
    user_input = sys.argv[1].split(":")

    #get fit method
    user_fit_method = user_input[0][0:]
    user_x_axis_size = int(user_input[1][0:])

    #get position sequence
    user_pos_seq = []
    pos_seq_it = iter(user_input[2][0:].split(","))
    for x, y in zip(pos_seq_it, pos_seq_it):
        pos = [int(x), int(y)]
        user_pos_seq.append(pos)
    
    #get data sequence
    user_data = user_input[3][0:].split(',')
    user_data_seq = []
    for x in range(0, len(user_data), user_x_axis_size):
        row = user_data[x:x + user_x_axis_size]
        row_data = []
        for v in row:
            row_data.append(int(v))
        user_data_seq.append(row_data)
        
     #real work
    if(user_fit_method  == 'fit_gauss_circular'):
        print(fit_gauss_circular(user_pos_seq, numpy.array(user_data_seq)))
    elif (user_fit_method == 'fit_gauss_elliptical'):
        print(fit_gauss_elliptical(user_pos_seq, numpy.array(user_data_seq)))
    elif (user_fit_method == 'fit_moffat_circular'):
        print(fit_moffat_circular(user_pos_seq, numpy.array(user_data_seq)))
    elif (user_fit_method == 'fit_moffat_elliptical'):
        print(fit_moffat_elliptical(user_pos_seq, numpy.array(user_data_seq)))
    else:
        print("Unknown fit method:", user_fit_method)

except Exception as e:
    print("Exception" , str(e))
#----------------------------------------------------
