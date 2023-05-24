# gets the R data type to save files with

get_data_type <- function(path) {
  
  path_hdr <- gsub(x = path, pattern = "\\.dat$", replacement = ".hdr") # only replace the file extension 
  
  data_type_envi = read_lines(path_hdr)[9:10] %>%
    str_subset("data type") %>%
    str_split(" = ") %>%
    .[[1]] %>%
    .[2]
  
  data.codes <- tibble(envi.code = c("1","2","4","12"),
                           r.code = c("INT1U", "INT2S", "FLT4S", "INT2U"))
  
  data_code_r <- data.codes %>%
    filter(envi.code == data_type_envi) %>%
    pull(r.code)
  
  return(data_code_r)
}

# Data frame used to match terra data types to gdal data types

data_types <- tibble(terra = c("LOG1s", 
                               "INT1S", "INT1U", 
                               "INT2S", "INT2U", 
                               "INT4S", "INT4U", 
                               "FLT4S", "FLT8S"), 
                     gdal = c(NA, 
                              NA, "Byte",
                              "Int16", "UInt16", 
                              "Int32", "UInt32", 
                              "Float32", "Float64"))
