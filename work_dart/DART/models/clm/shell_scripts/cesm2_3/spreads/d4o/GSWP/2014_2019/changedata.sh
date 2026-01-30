#!/bin/bash

BASE_DIR="/work/cmcc/spreads-lnd/work/forcing/EDA"

for i in $(seq 1 30); do
    FILE="${BASE_DIR}/EDA_n${i}/Precip/clmforc.EDA${i}.0.5d.Prec.2015-03.nc"
    TMP_DIR="${BASE_DIR}/EDA_n${i}/Precip"

    echo "🔍 Processando $FILE"

    if [ -f "$FILE" ]; then
        TMP1="${TMP_DIR}/timestep1.nc"
        TMP2="${TMP_DIR}/remaining.nc"
        FIXED="${TMP_DIR}/fixed.nc"

        # Copia o segundo timestep e redefine como primeiro
        cdo seltimestep,2 "$FILE" "$TMP1"

        # Copia os timesteps de 2 até o final (mantém o resto)
        cdo seltimestep,2/248 "$FILE" "$TMP2"

        # Junta o novo primeiro timestep com o restante (timestep 2 em diante)
        cdo mergetime "$TMP1" "$TMP2" "$FIXED"

        # Substitui o original
        mv "$FIXED" "$FILE"
        rm -f "$TMP1" "$TMP2"

        echo "✅ Corrigido: EDA_n${i}"
    else
        echo "⚠️  Arquivo não encontrado: $FILE"
    fi
done





cdo settaxis,2015-03-01,01:30:00,3hour clmforc.EDA10.0.5d.Prec.2015-03.nc fixed.nc
ncks -A -v time clmforc.EDA10.0.5d.Prec.2014-03.nc fixed.nc
ncap2 -O -s 'time@units="days since 2015-03-01 01:30:00"' fixed.nc clmforc.EDA10.0.5d.Prec.2015-03.nc