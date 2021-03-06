#' Compile tree water content.
#' 
#' @description Compile a stack with different tree water content information:
#' mean, standard deviation, mean plus error estimate of biomass, mean minus
#' error estimate of biomass, mean per mean annual rainfall, mean plus error
#' per annual rainfall and mean minus error per annual rainfall.
#'
#' @param bl baseline dataset for tree water computation
#' @param twc_lut path to the tree water content look up table
#' @param output_path path where the individual datasets will be stored
#' 
#' @return global tree water content
#' 
#' @author Thomas Nauss
#' @contributer Pierre L. Ibisch, Jeanette S. Blumröder, Tobias Cremer, 
#' Katharina Lüdicke, Peter R. Hobson, Douglas Sheil
#'

compileTreeWaterContent = function(bl, twc_lut){
  
  # Helper function ------------------------------------------------------------
  # MODIS land cover type 1 IDs: 
  # 1 Evergreen Needleleaf Forests
  # 2 Evergreen Broadleaf Forests 
  # 3	Deciduous Needleleaf Forests
  # 4	Deciduous Broadleaf Forests 
  # 5	Mixed Forests
  calcTWC = function(data, gee_mlc_type1_forest, twc, output_path){
    # data = mask(data, gee_mlc_type1_forest)
    data[gee_mlc_type1_forest == 1 | gee_mlc_type1_forest == 3] = 
      data[gee_mlc_type1_forest == 1 | gee_mlc_type1_forest == 3] * twc[2]/100
    data[gee_mlc_type1_forest == 2 | gee_mlc_type1_forest == 4] = 
      data[gee_mlc_type1_forest == 2 | gee_mlc_type1_forest == 4] * twc[1]/100
    data[gee_mlc_type1_forest == 5] = 
      data[gee_mlc_type1_forest == 5] * mean(twc)/100
    return(data)
  }
  

  # Read tree water content ----------------------------------------------------
  twc = read.table(twc_lut, header = TRUE, sep = ",", dec = ".")
  
  # Calculate water content and errors -----------------------------------------
  tree_water_mean = calcTWC(bl[["gsv_wm_na"]], 
                            bl[["gee_mlc_type1_forest"]], twc$Mean)
  
  tree_water_sd = calcTWC(bl[["gsv_wm_na"]], 
                          bl[["gee_mlc_type1_forest"]], twc$SDev)
  
  tree_water_mean_error = calcTWC(bl[["gsv_err_wm_na"]], 
                                  bl[["gee_mlc_type1_forest"]], twc$Mean)
  
  tree_water_mean_plus_error = tree_water_mean + tree_water_mean_error
  
  tree_water_mean_minus_error = tree_water_mean - tree_water_mean_error
  
  tree_water_mean_per_precipitation = 
    tree_water_mean / bl[["gee_rainf_f_tavg_m3ha"]]
  
  tree_water_mean_plus_error_per_precipitation = 
    tree_water_mean_plus_error / bl[["gee_rainf_f_tavg_m3ha"]]
  
  tree_water_mean_minus_error_per_precipitation = 
    tree_water_mean_minus_error / bl[["gee_rainf_f_tavg_m3ha"]]
  
  tw = stack(tree_water_mean, 
             tree_water_sd, 
             tree_water_mean_error,
             tree_water_mean_plus_error,
             tree_water_mean_minus_error,
             tree_water_mean_per_precipitation, 
             tree_water_mean_plus_error_per_precipitation, 
             tree_water_mean_minus_error_per_precipitation)
  
  names(tw) = c("twc_mean", "twc_sd", "twc_error", 
                "twc_plus_error", "twc_minus_error",
                "twc_mean_precip", 
                "twc_plus_error_precip", "twc_minus_error_precip")
  
  writeRaster(tw, file.path(output_path, "tw.tif"), format="GTiff")

  saveRDS(tw, file.path(envrmt$path_rds_data, "tw.rds"))
  
  return(tw)
}
