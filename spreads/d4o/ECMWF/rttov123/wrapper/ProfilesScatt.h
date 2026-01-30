/*
! Copyright:
!    This software was developed within the context of
!    the EUMETSAT Satellite Application Facility on
!    Numerical Weather Prediction (NWP SAF), under the
!    Cooperation Agreement dated 25 November 1998, between
!    EUMETSAT and the Met Office, UK, by one or more partners
!    within the NWP SAF. The partners in the NWP SAF are
!    the Met Office, ECMWF, KNMI and MeteoFrance.
!
!    Copyright 2015, EUMETSAT, All Rights Reserved.
*/

///@class ProfilesScatt
///  This class represents multiple atmospheric profiles for RTTOV-SCATT

#ifndef PROFILESSCATT_H_
#define PROFILESSCATT_H_


#include <rttov_cc_interface.h>
#include <stdio.h>

#include <iostream>

#include <cstdlib>

#include <exception>
#include <stdexcept>
#include <Rttov_common.h>

namespace rttov {

typedef std::map<rttov::itemIdType,double *> GasIdPointerMap;

class ProfilesScatt {
public:
    ProfilesScatt(int nbprofiles, const int nblevels, int nbgases);
    ProfilesScatt(int nbprofiles, const int nblevels);
    ProfilesScatt();
    virtual ~ProfilesScatt();

//     void setNprofiles(int nprofiles);
//     void setNlevels(int nlevels);
//     void setNgases(int ngases);

    void setGasUnits(int gasUnits);
    void setMmrSnowRain(bool mmrSnowRain);
    void setUseTotalice(bool useTotalice);

    void setP(double* p);
    void setPh(double* ph);
    void setT(double* t);
    void setQ(double* q);
    void setCc(double* cc);
    void setClw(double* clw);
    void setCiw(double* ciw);
    void setSp(double* sp);
    void setRain(double* rain);
    void setTotalice(double* totalice);
    void setUserCfrac(double* usercfrac);

    void setAngles(double* angles);
    void setS2m(double* s2m);
    void setSkin(double* skin);
    void setSurfType(int* surftype);
    void setSurfGeom(double* surfgeom);
    void setDateTimes(int* datetimes);
    void setZeeman(double* zeeman);
    void setGasItem(double* gasItem, rttov::itemIdType item_id);

    void setGasId(int* gasId);
    void setGases(double* gases);
    ItemIdIndexMap gas_index;

    int getNprofiles() const;
    int getNlevels() const;
    int getGasUnits() const;
    bool isMmrSnowRain() const;
    bool isUseTotalice() const;

    double* getP() const;
    double* getPh() const;
    double* getT() const;
    double* getUserCfrac() const;

    double* getQ();
    double* getCc();
    double* getClw();
    double* getCiw();
    double* getSp();
    double* getRain();
    double* getTotalice();

    double* getAngles() const;
    double* getS2m() const;
    double* getSkin() const;
    int* getSurfType() const;
    double* getSurfGeom() const;
    int* getDateTimes() const;
    double* getZeeman() const;

    int getNgases() const;
    int* getGasId() const;
    double* getGases() const;

    bool check();

private :

    int nprofiles;
    int nlevels;
    int ngases;
    int gas_units;
    int mmr_snowrain;
    int use_totalice;
    double * p;//[nprofiles][nlevels];                  // Input pressure profiles
    double * ph;//[nprofiles][nlevels+1];               // Input pressure half-level profiles
    double * t;//[nprofiles][nlevels];                  // Input temperature profiles
    double * gases;//[ngases][nprofiles][nlevels];      // Input gas profiles
    double * usercfrac;
    bool allocatedGases;

    int * gas_id;// { Q=1, SCATT_CC=60, SCATT_CLW, SCATT_CIW, SCATT_RAIN, SCATT_SP, SCATT_TOTALICE}

    // datetimes: yy, mm, dd, hh, mm, ss
    int * datetimes; //[nprofiles][6]

    // angles: satzen, satazi
    double * angles;//[nprofiles][2]

    // surftype: surftype
    int * surftype;//[nprofiles]

    // surfgeom: lat, lon, elev
    double * surfgeom ;//[nprofiles][3]

    // s2m: 2m p, 2m t, 2m q, 10m wind u, v
    double * s2m;//[nprofiles][5]

    // skin: skin T, salinity, foam_frac, fastem_coefsx5
    double * skin; //[nprofiles][8]

    // zeeman: be, cosbk
    double * zeeman;//[nprofiles][2]

    rttov::StrBoolMap allocatedPointers;
    void initialisePointers();
    bool buildGasesArray();
    GasIdPointerMap myGases;
};
} /* namespace rttov */
#endif /* PROFILESSCATT_H_ */
