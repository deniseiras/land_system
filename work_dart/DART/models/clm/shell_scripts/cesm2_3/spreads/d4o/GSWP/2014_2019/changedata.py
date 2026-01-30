import xarray as xr
import numpy as np
import os

# === Caminho base ===
base_dir = "/work/cmcc/spreads-lnd/work/forcing/EDA"
filename_template = "clmforc.EDA{n}.0.5d.Prec.2015-03.nc"

# === Loop pelos 30 membros ===
for n in range(1, 31):
    folder = f"EDA_n{n}"
    filename = filename_template.format(n=n)
    file_path = os.path.join(base_dir, folder, "Precip", filename)

    if not os.path.exists(file_path):
        print(f"[EDA_n{n}] Arquivo não encontrado: {file_path}")
        continue

    try:
        with xr.open_dataset(file_path, mode='r+') as ds:
            if 'PRECTmms' not in ds:
                print(f"[EDA_n{n}] Variável 'PRECTmms' não encontrada no arquivo.")
                continue

            prect = ds['PRECTmms']
            first_timestep = prect.isel(time=0)

            if np.isnan(first_timestep).any():
                print(f"[EDA_n{n}] Encontrado NaN no primeiro timestep. Corrigindo com dados do timestep 1.")
                ds['PRECTmms'].values[0] = prect.isel(time=1).values
                ds.to_netcdf(file_path, mode='a')  # sobrescreve
                print(f"[EDA_n{n}] Correção salva com sucesso.")
            else:
                print(f"[EDA_n{n}] Primeiro timestep está válido. Nenhuma alteração feita.")

    except Exception as e:
        print(f"[EDA_n{n}] Erro ao processar o arquivo: {e}")
