//
// Table Definition: collocated_imager_information tables
//
// For collocated_imager_information only - these ODB attributes are not used in IFS (table not loaded) but
// can be used to post-process IASI data
//
CREATE TABLE collocated_imager_information AS (
  avhrr_mean_ir pk9real,               // Mean BT on channel Ir in FOV
  avhrr_stddev_ir pk9real,             // Std. Dev. of BT on channel Ir in FOV
  avhrr_stddev_ir2 pk9real,             // Std. Dev. of BT on channel Ir2 in FOV
  avhrr_num_clusters pk9real,           // Number of clusters FOV

  avhrr_mean_vis pk9real,               // Mean visible reflectance in FOV
  avhrr_stddev_vis pk9real,             // Std. Dev. of visible reflectance in FOV
  avhrr_max_cluster pk9real,            // Fractional size of the largest cluster
  avhrr_coldest_cluster_ir pk9real,    // Mean Ir BT for the coldest cluster
  avhrr_warmest_cluster_ir pk9real,    // Mean Ir BT for the warmest cluster
  avhrr_largest_cluster_ir pk9real,    // Mean Ir BT for the largest cluster
// For iasi only (filled in bufr)
  provider_qc pk1int,                    // QC as determined by data provider
  avhrr_frac_cl1 pk9real,               // Fractional size of cluster 1
  avhrr_frac_cl2 pk9real,               // Fractional size of cluster 2
  avhrr_frac_cl3 pk9real,               // Fractional size of cluster 3
  avhrr_frac_cl4 pk9real,               // Fractional size of cluster 4
  avhrr_frac_cl5 pk9real,               // Fractional size of cluster 5
  avhrr_frac_cl6 pk9real,               // Fractional size of cluster 6
  avhrr_frac_cl7 pk9real,               // Fractional size of cluster 7
  avhrr_m_ir1_cl1 pk9real,              // Mean Ir1 BT in cluster 1
  avhrr_m_ir1_cl2 pk9real,              // Mean Ir1 BT in cluster 2
  avhrr_m_ir1_cl3 pk9real,              // Mean Ir1 BT in cluster 3
  avhrr_m_ir1_cl4 pk9real,              // Mean Ir1 BT in cluster 4
  avhrr_m_ir1_cl5 pk9real,              // Mean Ir1 BT in cluster 5
  avhrr_m_ir1_cl6 pk9real,              // Mean Ir1 BT in cluster 6
  avhrr_m_ir1_cl7 pk9real,              // Mean Ir1 BT in cluster 7
  avhrr_m_ir2_cl1 pk9real,              // Mean Ir2 BT in cluster 1
  avhrr_m_ir2_cl2 pk9real,              // Mean Ir2 BT in cluster 2
  avhrr_m_ir2_cl3 pk9real,              // Mean Ir2 BT in cluster 3
  avhrr_m_ir2_cl4 pk9real,              // Mean Ir2 BT in cluster 4
  avhrr_m_ir2_cl5 pk9real,              // Mean Ir2 BT in cluster 5
  avhrr_m_ir2_cl6 pk9real,              // Mean Ir2 BT in cluster 6
  avhrr_m_ir2_cl7 pk9real,              // Mean Ir2 BT in cluster 7
  avhrr_fg_ir1 pk9real,                 // First guess Ir1 BT
  avhrr_fg_ir2 pk9real,                 // First guess Ir2 BT
  avhrr_cloud_flag pk1int,              // AVHRR cloud flag (determined during screening)
);

