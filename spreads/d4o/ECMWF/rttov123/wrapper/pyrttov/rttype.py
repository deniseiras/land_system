'''
:Copyright: 2016, EUMETSAT, All Rights Reserved.

This software was developed within the context of
the EUMETSAT Satellite Application Facility on
Numerical Weather Prediction (NWP SAF), under the
Cooperation Agreement dated 25 November 1998, between
EUMETSAT and the Met Office, UK, by one or more partners
within the NWP SAF. The partners in the NWP SAF are
the Met Office, ECMWF, KNMI and MeteoFrance.

This module defines abstract classes to generate data types.
'''

try:
    from __builtin__ import unicode
    str_types = (str, unicode)
except:
    str_types = (str,)
import numpy as np


# Numpy types expected by the RTTOV f2py wrapper
wrapfloat = np.float64
wrapint = np.int32


class _genericEnum(int):
    '''Type that do something close to a C/C++ enum.'''

    _enum_dict = {}

    def __new__(cls, value):
        if (isinstance(value, (int, np.int16, np.int32, np.int64)) and
                int(value) in cls._enum_dict.values()):
            return int.__new__(cls, value)
        if isinstance(value, str_types) and value in cls._enum_dict:
            return int.__new__(cls, cls._enum_dict[value])
        raise ValueError("Incorect value for a {}: {!s}".format(cls.__name__,
                                                                value))

    @property
    def name(self):
        for key, item in self._enum_dict.items():
            if item == self:
                return key


class gasUnitType(_genericEnum):
    '''Type that represents a gas unit.'''

    _enum_dict = {'unknown': -2, 'ppmv_dry': 0,
                  'kg_per_kg': 1, 'ppmv_wet': 2}

useraer1=101
maxuseraer=30

class itemIdType(_genericEnum):
    '''
    Type that represents a mapping between gas/item name and its internal id.
    '''

    _enum_dict = {'Q': 1, 'O3': 2, 'CO2': 3, 'N2O': 4, 'CO': 5, 'CH4': 6, 'SO2':7,
                  'CLW': 15, 'CFRAC': 20, 'STCO': 21, 'STMA': 22, 'CUCC': 23,
                  'CUCP': 24, 'CUMA': 25, 'CIRR': 30, 'ICEDE': 31, 'CLWDE': 32,
                  'INSO': 41, 'WASO': 42, 'SOOT': 43, 'SSAM': 44, 'SSCM': 45, 'MINM': 46,
                  'MIAM': 47, 'MICM': 48, 'MITR': 49, 'SUSO': 50, 'VOLA': 51, 'VAPO': 52, 'ASDU': 53,
                  'BCAR': 81, 'DUS1': 82, 'DUS2': 83, 'DUS3': 84, 'SULP': 85, 'SSA1': 86,
                  'SSA2': 87, 'SSA3': 88, 'OMAT': 89,
                  'SCATT_CC': 60, 'SCATT_CLW': 61, 'SCATT_CIW': 62,
                  'SCATT_RAIN': 63, 'SCATT_SP': 64, 'SCATT_TOTALICE': 65,
                  'AER1' : 101, 'AER2' : 102, 'AER3' : 103, 'AER4' : 104, 'AER5' : 105,
                  'AER6' : 106, 'AER7' : 107, 'AER8' : 108, 'AER9' : 109, 'AER10' : 110,
                  'AER11' : 111, 'AER12' : 112, 'AER13' : 113, 'AER14' : 114, 'AER15' : 115,
                  'AER16' : 116, 'AER17' : 117, 'AER18' : 118, 'AER19' : 119, 'AER20' : 120,
                  'AER21' : 121, 'AER22' : 122, 'AER23' : 123, 'AER24' : 124, 'AER25' : 125,
                  'AER26' : 126, 'AER27' : 127, 'AER28' : 128, 'AER29' : 129, 'AER30' : 130}
