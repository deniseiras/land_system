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

#ifndef RTTOV_COMMON_H_
#define RTTOV_COMMON_H_
#include <string>
#include <map>
#include <vector>

namespace rttov {
bool is_readable(const std::string & file);

enum gasUnitType {unknown=-1, ppmv_dry=0, kg_per_kg=1, ppmv_wet=2};

const int USERAER1=101;
const int MAXUSERAER=30;

enum itemIdType {Q=1, O3, CO2, N2O, CO, CH4, SO2, CLW=15, CFRAC=20, STCO, STMA, CUCC, CUCP, CUMA, CIRR=30, ICEDE, CLWDE,
    INSO=41, WASO, SOOT, SSAM, SSCM, MINM, MIAM, MICM, MITR, SUSO, VOLA, VAPO, ASDU, SCATT_CC=60, SCATT_CLW,
    SCATT_CIW, SCATT_RAIN, SCATT_SP, SCATT_TOTALICE,
    BCAR=81, DUS1, DUS2, DUS3, SULP, SSA1, SSA2, SSA3, OMAT,
    AER1=USERAER1, AER2, AER3, AER4, AER5, AER6, AER7, AER8, AER9, AER10,
    AER11, AER12, AER13, AER14, AER15, AER16, AER17, AER18, AER19, AER20,
    AER21, AER22, AER23, AER24, AER25, AER26, AER27, AER28, AER29, AER30};

typedef std::vector <enum itemIdType> itemIdVector;
typedef std::map<itemIdType, std::vector <double>> ItemIdPointerMap;
typedef std::map<itemIdType, int> ItemIdIndexMap;
typedef std::map<std::string, bool> StrBoolMap;

const itemIdVector itemIds {Q, O3, CO2, N2O, CO, CH4, SO2, CLW, CFRAC, STCO, STMA, CUCC, CUCP, CUMA, CIRR, ICEDE, CLWDE,
    INSO, WASO, SOOT, SSAM, SSCM, MINM, MIAM, MICM, MITR, SUSO, VOLA, VAPO, ASDU,
    BCAR, DUS1, DUS2, DUS3, SULP, SSA1, SSA2, SSA3, OMAT,
    AER1, AER2, AER3, AER4, AER5, AER6, AER7, AER8, AER9, AER10,
    AER11, AER12, AER13, AER14, AER15, AER16, AER17, AER18, AER19, AER20,
    AER21, AER22, AER23, AER24, AER25, AER26, AER27, AER28, AER29, AER30};

const itemIdVector itemIdsScatt {Q, SCATT_CC, SCATT_CLW, SCATT_CIW, SCATT_RAIN, SCATT_SP, SCATT_TOTALICE};
}

#endif /* RTTOV_COMMON_H_ */
