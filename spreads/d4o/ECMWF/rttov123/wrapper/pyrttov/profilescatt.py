'''
:Copyright: 2016, EUMETSAT, All Rights Reserved.

This software was developed within the context of
the EUMETSAT Satellite Application Facility on
Numerical Weather Prediction (NWP SAF), under the
Cooperation Agreement dated 25 November 1998, between
EUMETSAT and the Met Office, UK, by one or more partners
within the NWP SAF. The partners in the NWP SAF are
the Met Office, ECMWF, KNMI and MeteoFrance.
'''

from __future__ import absolute_import, print_function
import numpy as np

from pyrttov.rttype import wrapint, wrapfloat
from pyrttov.decorator import add_descriptors_gases2D
from pyrttov.descriptor import TypedDescriptorRW
from pyrttov.descriptor import ArbitraryProfilesRW, ArbitraryProfilesRWD
from pyrttov.descriptor import VerticalProfilesRW
from pyrttov.profile import _ProfilesCommon

# Gives the mapping between gas_id / (descriptor name, full description)
ItemDescriptorNamingScatt = {'Q': ('Q', 'Water Vapor (q)'),
                             'SCATT_CC': ('Cc', 'Cloud fraction'),
                             'SCATT_CLW': ('Clw', 'Cloud Liquid Water'),
                             'SCATT_CIW': ('Ciw', 'Cloud Ice Water'),
                             'SCATT_RAIN': ('Rain', 'Rain'),
                             'SCATT_SP': ('Sp', 'Solid Precip (snow)'),
                             'SCATT_TOTALICE': ('Totalice', 'Totalice')}


@add_descriptors_gases2D(ItemDescriptorNamingScatt)
class ProfilesScatt(_ProfilesCommon):
    '''The ProfilesScatt class holds a batch of RTTOV-SCATT profiles.

    Two mechanisms are offered to initialise the gases array:
      * All the gases are initialised at once using the :data:`Gases`
        attribute. Then, the gas Id list have to be provided to the
        :data:`GasId` attribute.
      * Each gas/hydrometeor can be provided independently using the appropriate attribute
        (:data:`Q`, :data:`CLW`, ...). Accordingly, the :data:`Gases` and
        :data:`GasId` attributes will be automatically generated.

    Whenever the :data:`Gases` attribute is set manually, it takes precedence
    over individual gas attributes that may already be defined.

    The :data:`Zeeman` attribute has default values.

    '''

    _GASES_DESCRIPTION = ItemDescriptorNamingScatt
    _PROFILES_PRINT_LIST = ('DateTimes', 'Angles', 'SurfGeom', 'SurfType',
                            'Skin', 'S2m', 'Zeeman', 'UserCfrac')

    def __init__(self, nprofiles, nlevels):
        """
        :param int nlevels: number of vertical levels of the profiles
        :param int nprofiles: number of profiles in this batch
        """
        super(ProfilesScatt, self).__init__(nprofiles, nlevels)
        self._conf['mmr_snowrain'] = True

    Angles = ArbitraryProfilesRW('internals', 'angles', leadingdim=2,
                                 doc="Satellite and Sun angles.")
    SurfType = ArbitraryProfilesRW('internals', 'surftype', dtype=wrapint,
                                   doc="Description of the surface type.")
    S2m = ArbitraryProfilesRW('internals', 's2m', leadingdim=5,
                              doc="Meteorological parameters at 2m height.")
    Skin = ArbitraryProfilesRW('internals', 'skin', leadingdim=8,
                               doc="Surface skin parameters.")
    MmrSnowRain = TypedDescriptorRW('conf', 'mmr_snowrain', bool,
                                    doc='Unit used in the snow/rain arrays.')
    UseTotalIce = TypedDescriptorRW('conf', 'use_totalice', bool,
                                    doc='Flag to use totalice instead of separate snow and CIW.')
    UserCfrac = ArbitraryProfilesRWD('profiles', 'UserCfrac',
                                     doc="User-specified cloud fraction per profile if luser_cfrac is true.")
    P = VerticalProfilesRW('profiles', 'P', doc="Pressure vertical profiles.")
    Ph = VerticalProfilesRW('profiles', 'Ph', deltaNlevels=1,
                            doc="Pressure half-level vertical profiles.")

    def _actual_check(self):
        return (super(ProfilesScatt, self)._actual_check() and
                self.P is not None and
                self.Ph is not None)

    def _optional_fields_init(self):
        super(ProfilesScatt, self)._optional_fields_init()
        if self.UserCfrac is None:
            self.UserCfrac = np.zeros((self.Nprofiles,), dtype=wrapfloat)
