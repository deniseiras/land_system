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

///@class ProfileScatt
///  This class represents one atmospheric profile for RTTOV-SCATT

#ifndef PROFILESCATT_H_
#define PROFILESCATT_H_
#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <string>
#include <exception>
#include <stdexcept>

#include <Rttov_common.h>
namespace rttov{

class ProfileScatt {
public:
    ProfileScatt(int nlevels);
    virtual ~ProfileScatt();

    void setGasUnits(rttov::gasUnitType gasUnits);
    void setMmrSnowRain(const bool mmrSnowRain);
    void setUseTotalice(const bool useTotalice);

    void setP(const std::vector<double>& p);
    void setPh(const std::vector<double>& ph);
    void setT(const std::vector<double>& t);
    void setQ(const std::vector <double>& q);
    void setCc(const std::vector <double>& cc);
    void setClw(const std::vector <double>& clw);
    void setCiw(const std::vector <double>& ciw);
    void setSp(const std::vector <double>& sp);
    void setRain(const std::vector <double>& rain);
    void setTotalice(const std::vector <double>& totalice);
    void setUserCfrac(const double usercfrac_in);

    void setAngles(const double satzen, const double satazi);
    void setS2m(const double p_2m, const double t_2m, const double q_2m,
        const double u_10m, const double v_10m);
    void setSkin(const double t, const double salinity,
        const double foam_fraction, const double fastem_coef_1,
        const double fastem_coef_2, const double fastem_coef_3,
        const double fastem_coef_4, const double fastem_coef_5);
    void setSurfType(const int surftype_in);
    void setSurfGeom(const double lat, const double lon, const double elevation);
    void setDateTimes(const int yy, const int mm, const int dd, const int hh,
        const int mn, const int ss);
    void setZeeman(const double Be, const double cosbk);


    int getNlevels() const;
    int getGasUnits() const;
    bool isMmrSnowRain() const;
    bool isUseTotalice() const;
    const std::vector<double>& getP() const;
    const std::vector<double>& getPh() const;
    double getUserCfrac() const;
    const std::vector<double>& getT() const;
    const std::vector<double>& getAngles() const;
    const std::vector<double>& getSurfGeom() const;
    int getSurfType() const;
    const std::vector<double>& getS2m() const;
    const std::vector<double>& getSkin() const;
    const std::vector<int>& getDateTimes() const;
    const std::vector<double>& getZeeman() const;
    const std::vector<itemIdType> getItemContents() const;
    const ItemIdPointerMap& getItems() const;

    bool check();

private :
    bool verbose;
    int nlevels;
    int gas_units;
    int mmr_snowrain;
    int use_totalice;
    std::vector <double> P;
    std::vector <double> Ph;
    std::vector <double> T;
    double usercfrac;

    ItemIdPointerMap items;

    // datetimes: yy, mm, dd, hh, mm, ss
    std::vector <int> datetimes;

    // surfgeom: lat, lon, elev
    std::vector <double> surfgeom;

    // angles: satzen, satazi
    std::vector <double> angles;

    // surftype
    int surftype;

    // skin: skin T, salinity, foam_frac, fastem_coefsx5
    std::vector <double> skin;

    // s2m: 2m p, 2m t, 2m q, 10m wind u, v
    std::vector <double> s2m;

    // zeeman: be, cosbk
    std::vector <double> zeeman;
};

} /* namespace rttov */

#endif /* PROFILESCATT_H_ */
