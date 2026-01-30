#!/usr/bin/env python3
import os
import argparse

def generate_dynamic_datafiles(stream: str, member: int, init_date: int, end_date: int) -> str:
    """
    Generate a multi-line, comma-separated list of forcing file paths for a given stream
    over the simulation period. The very first file appears inline immediately after the
    'datafiles=' keyword, and all subsequent file paths are printed on new, indented lines
    with a trailing comma and a backslash on every line except the last.
    
    For each year from init_date to end_date (inclusive) and for each month (1–12),
    a file name is created based on the stream type:
    
      - Solar: subfolder "Solar" with pattern
          clmforc.{file_code}.0.5d.Solr.{year}-{month:02d}.nc
      - Precip: subfolder "Precip" with pattern
          clmforc.{file_code}.0.5d.Prec.{year}-{month:02d}.nc
      - TPQW:   subfolder "TPHWL" with pattern
          clmforc.{file_code}.0.5d.TPQWL.{year}-{month:02d}.nc
    
    The base directory is:
        /ec/res4/scratch/ita5542/land/datain/forcing/EDA/
    
    All ensemble members use the following naming conventions:
      - Folder: "EDA_n" concatenated with the member number.
      - File-code: "EDA" concatenated with the member number.
    
    Returns:
      A string with the first file inline and each subsequent file on a new indented line,
      with all lines except the last ending with a comma and a backslash.
    """
    base_forcing = "/ec/res4/scratch/ita5542/land/datain/forcing/EDA/"
    folder = f"EDA_n{member}"
    file_code = f"EDA{member}"
    
    if stream == "Solar":
        subfolder = "Solar"
        pattern = "clmforc.{file_code}.0.5d.Solr.{year}-{month:02d}.nc"
    elif stream == "Precip":
        subfolder = "Precip"
        pattern = "clmforc.{file_code}.0.5d.Prec.{year}-{month:02d}.nc"
    elif stream == "TPQW":
        subfolder = "TPHWL"
        pattern = "clmforc.{file_code}.0.5d.TPQWL.{year}-{month:02d}.nc"
    else:
        return ""
    
    file_paths = []
    for year in range(init_date, end_date + 1):
        for month in range(1, 13):
            filename = pattern.format(file_code=file_code, year=year, month=month)
            full_path = os.path.join(base_forcing, folder, subfolder, filename)
            file_paths.append(full_path)
    
    lines = []
    for i, path in enumerate(file_paths):
        if i == 0:
            lines.append(f"{path}, \\")
        elif i < len(file_paths) - 1:
            lines.append(f"    {path}, \\")
        else:
            lines.append(f"    {path}")
    return "\n".join(lines)

def generate_file_content(member: int, init_date: int, end_date: int) -> str:
    """
    Generate the full content for a datm_streams file for a given ensemble member.
    
    This content comprises several stream blocks. For each block the year entries 
    (year_first, year_last, year_align) are updated to reflect the simulation period.
    
    For streams with dynamic file lists (Solar, Precip, TPQW), the datafiles entry is 
    constructed with the first file inline (immediately following 'datafiles=') and the 
    subsequent files on new, indented lines. Static stream blocks have fixed file paths 
    and are updated only with the simulation period.
    
    The forcing paths and other file locations remain specific to the ATOS system.
    """
    presaero_hist = (
        "presaero.hist:datafiles=/ec/res4/scratch/ita4441/inputs/CESM/inputdata/atm/cam/chem/trop_mozart_aero/aero/"
        "aerosoldep_WACCM.ensmean_monthly_hist_1849-2015_0.9x1.25_CMIP6_c180926.nc\n"
        "presaero.hist:taxmode=cycle\n"
        "presaero.hist:tintalgo=linear\n"
        "presaero.hist:readmode=single\n"
        "presaero.hist:mapalgo=bilinear\n"
        "presaero.hist:dtlimit=1.5\n"
        f"presaero.hist:year_first={init_date}\n"
        f"presaero.hist:year_last={end_date}\n"
        f"presaero.hist:year_align={init_date}\n"
        "presaero.hist:vectors=null\n"
        "presaero.hist:lev_dimname=null\n"
        "presaero.hist:meshfile=/ec/res4/scratch/ita5542/land/datain/inputdata/fv0.9x1.25_141008_polemod_ESMFmesh.nc\n"
        "presaero.hist:datavars=  BCDEPWET   Faxa_bcphiwet,\\\n"
        "      BCPHODRY   Faxa_bcphodry,\\\n"
        "      BCPHIDRY   Faxa_bcphidry,\\\n"
        "      OCDEPWET   Faxa_ocphiwet,\\\n"
        "      OCPHIDRY   Faxa_ocphidry,\\\n"
        "      OCPHODRY   Faxa_ocphodry,\\\n"
        "      DSTX01WD   Faxa_dstwet1,\\\n"
        "      DSTX01DD   Faxa_dstdry1,\\\n"
        "      DSTX02WD   Faxa_dstwet2,\\\n"
        "      DSTX02DD   Faxa_dstdry2,\\\n"
        "      DSTX03WD   Faxa_dstwet3,\\\n"
        "      DSTX03DD   Faxa_dstdry3,\\\n"
        "      DSTX04WD   Faxa_dstwet4,\\\n"
        "      DSTX04DD   Faxa_dstdry4\n"
        "presaero.hist:offset=0\n"
    )
    
    clmgswp3v1_solar = (
        "CLMGSWP3v1.Solar:taxmode=cycle\n"
        "CLMGSWP3v1.Solar:tintalgo=coszen\n"
        "CLMGSWP3v1.Solar:readmode=single\n"
        "CLMGSWP3v1.Solar:mapalgo=bilinear\n"
        "CLMGSWP3v1.Solar:dtlimit=1.5\n"
        f"CLMGSWP3v1.Solar:year_first={init_date}\n"
        f"CLMGSWP3v1.Solar:year_last={end_date}\n"
        f"CLMGSWP3v1.Solar:year_align={init_date}\n"
        "CLMGSWP3v1.Solar:vectors=null\n"
        "CLMGSWP3v1.Solar:lev_dimname=null\n"
        "CLMGSWP3v1.Solar:meshfile=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc\n"
        "CLMGSWP3v1.Solar:datafiles=" + generate_dynamic_datafiles("Solar", member, init_date, end_date) + "\n"
        "CLMGSWP3v1.Solar:datavars=FSDS     Faxa_swdn\n"
        "CLMGSWP3v1.Solar:offset=0\n"
    )
    
    clmgswp3v1_precip = (
        "CLMGSWP3v1.Precip:taxmode=cycle\n"
        "CLMGSWP3v1.Precip:tintalgo=nearest\n"
        "CLMGSWP3v1.Precip:readmode=single\n"
        "CLMGSWP3v1.Precip:mapalgo=bilinear\n"
        "CLMGSWP3v1.Precip:dtlimit=1.5\n"
        f"CLMGSWP3v1.Precip:year_first={init_date}\n"
        f"CLMGSWP3v1.Precip:year_last={end_date}\n"
        f"CLMGSWP3v1.Precip:year_align={init_date}\n"
        "CLMGSWP3v1.Precip:vectors=null\n"
        "CLMGSWP3v1.Precip:lev_dimname=null\n"
        "CLMGSWP3v1.Precip:meshfile=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc\n"
        "CLMGSWP3v1.Precip:datafiles=" + generate_dynamic_datafiles("Precip", member, init_date, end_date) + "\n"
        "CLMGSWP3v1.Precip:datavars=PRECTmms Faxa_precn\n"
        "CLMGSWP3v1.Precip:offset=0\n"
    )
    
    clmgswp3v1_tpqw = (
        "CLMGSWP3v1.TPQW:taxmode=cycle\n"
        "CLMGSWP3v1.TPQW:tintalgo=linear\n"
        "CLMGSWP3v1.TPQW:readmode=single\n"
        "CLMGSWP3v1.TPQW:mapalgo=bilinear\n"
        "CLMGSWP3v1.TPQW:dtlimit=1.5\n"
        f"CLMGSWP3v1.TPQW:year_first={init_date}\n"
        f"CLMGSWP3v1.TPQW:year_last={end_date}\n"
        f"CLMGSWP3v1.TPQW:year_align={init_date}\n"
        "CLMGSWP3v1.TPQW:vectors=null\n"
        "CLMGSWP3v1.TPQW:lev_dimname=null\n"
        "CLMGSWP3v1.TPQW:meshfile=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "clmforc.GSWP3.c2011.0.5x0.5.TPQWL.SCRIP.210520_ESMFmesh.nc\n"
        "CLMGSWP3v1.TPQW:datafiles=" + generate_dynamic_datafiles("TPQW", member, init_date, end_date) + "\n"
        "CLMGSWP3v1.TPQW:datavars=TBOT     Sa_tbot,\\\n"
        "      WIND     Sa_wind,\\\n"
        "      QBOT     Sa_shum,\\\n"
        "      PSRF     Sa_pbot\n"
        "CLMGSWP3v1.TPQW:offset=0\n"
    )
    
    presndep_hist = (
        "presndep.hist:datafiles=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "fndep_clm_hist_b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.ensmean_1849-2015_monthly_0.9x1.25_c180926.nc\n"
        "presndep.hist:taxmode=cycle\n"
        "presndep.hist:tintalgo=linear\n"
        "presndep.hist:readmode=single\n"
        "presndep.hist:mapalgo=bilinear\n"
        "presndep.hist:dtlimit=1.5\n"
        f"presndep.hist:year_first={init_date}\n"
        f"presndep.hist:year_last={end_date}\n"
        f"presndep.hist:year_align={init_date}\n"
        "presndep.hist:vectors=null\n"
        "presndep.hist:lev_dimname=null\n"
        "presndep.hist:meshfile=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "fv0.9x1.25_141008_polemod_ESMFmesh.nc\n"
        "presndep.hist:datavars=NDEP_NHx_month    Faxa_ndep_nhx,\\\n"
        "          NDEP_NOy_month    Faxa_ndep_noy\n"
        "presndep.hist:offset=0\n"
    )
    
    preso3_hist = (
        "preso3.hist:datafiles=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "O3_surface.f09_g17.CMIP6-historical-WACCM.001.monthly.185001-201412.nc\n"
        "preso3.hist:taxmode=cycle\n"
        "preso3.hist:tintalgo=linear\n"
        "preso3.hist:readmode=single\n"
        "preso3.hist:mapalgo=bilinear\n"
        "preso3.hist:dtlimit=1.5\n"
        f"preso3.hist:year_first={init_date}\n"
        f"preso3.hist:year_last={end_date}\n"
        f"preso3.hist:year_align={init_date}\n"
        "preso3.hist:vectors=null\n"
        "preso3.hist:lev_dimname=null\n"
        "preso3.hist:meshfile=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "fv0.9x1.25_141008_polemod_ESMFmesh.nc\n"
        "preso3.hist:datavars= O3  Sa_o3\n"
        "preso3.hist:offset=0\n"
    )
    
    co2tseries = (
        "co2tseries.20tr:datafiles=/ec/res4/scratch/ita5542/land/datain/inputdata/"
        "fco2_datm_global_simyr_1750-2014_CMIP6_c180929.nc\n"
        "co2tseries.20tr:taxmode=extend\n"
        "co2tseries.20tr:tintalgo=linear\n"
        "co2tseries.20tr:readmode=single\n"
        "co2tseries.20tr:mapalgo=none\n"
        "co2tseries.20tr:dtlimit=1.e30\n"
        f"co2tseries.20tr:year_first={init_date}\n"
        f"co2tseries.20tr:year_last={end_date}\n"
        f"co2tseries.20tr:year_align={init_date}\n"
        "co2tseries.20tr:vectors=null\n"
        "co2tseries.20tr:lev_dimname=null\n"
        "co2tseries.20tr:meshfile=none\n"
        "co2tseries.20tr:datavars=CO2   Sa_co2diag\n"
        "co2tseries.20tr:offset=0\n"
    )
    
    header = (
        "!------------------------------------------------------------------------\n"
        "! This file is used to modify datm.streams.xml generated in $RUNDIR\n"
        f"! Ensemble member: {member}\n"
        f"! Generated for simulation period: {init_date} to {end_date}\n"
        "!------------------------------------------------------------------------\n"
    )
    
    content = "\n".join([
        header,
        presaero_hist,
        clmgswp3v1_solar,
        clmgswp3v1_precip,
        clmgswp3v1_tpqw,
        presndep_hist,
        preso3_hist,
        co2tseries
    ])
    
    return content

def create_datm_streams_files(members: int, init_date: int, end_date: int, output_dir: str = ".") -> None:
    """
    Generate a datm_streams file for each ensemble member.
    
    Each file is named using a zero-padded four-digit index (e.g. user_nl_datm_streams_0001) and includes:
      - Updated year entries (year_first, year_last, year_align)
      - Dynamic, multi-line datafiles lists for the Solar, Precip, and TPQW streams, with the first file inline.
      - Static stream blocks with fixed file paths, updated to the specified simulation period.
    
    The file paths follow the ATOS system conventions.
    """
    os.makedirs(output_dir, exist_ok=True)
    for member in range(1, members + 1):
        content = generate_file_content(member, init_date, end_date)
        filename = f"user_nl_datm_streams_{member:04d}"
        filepath = os.path.join(output_dir, filename)
        with open(filepath, "w") as f:
            f.write(content)
        print(f"Created file: {filepath}")

def main():
    parser = argparse.ArgumentParser(
        description="Generate datm_streams files for ensemble members with dynamic, multi-line datafiles lists."
    )
    parser.add_argument("--members", type=int, required=True,
                        help="Number of ensemble member files to create (e.g. 30).")
    parser.add_argument("--init_date", type=int, required=True,
                        help="Initial year for the simulation (e.g. 2000).")
    parser.add_argument("--end_date", type=int, required=True,
                        help="Final year for the simulation (e.g. 2003).")
    parser.add_argument("--output_dir", type=str, default=".",
                        help="Output directory for generated files (default: current directory).")
    args = parser.parse_args()
    create_datm_streams_files(args.members, args.init_date, args.end_date, args.output_dir)

if __name__ == "__main__":
    main()
