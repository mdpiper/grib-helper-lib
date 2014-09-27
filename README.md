# IDL GRIB Helper Library

IDL's [GRIB API](http://www.exelisvis.com/docs/GRIB_Routines.html) is
built on the C version of the
[ECMWF GRIB-API](https://software.ecmwf.int/wiki/display/GRIB/Home).
The IDL routines mirror those of the low-level ECMWF API, so it
requires a bit of programming to get even simple information from a
GRIB file.

The following routines,
built with IDL's GRIB API,
make it easier
to get information from a GRIB file:

* `GRIB_INVENTORY`: Creates an inventory of a GRIB file, returned
  as a string array. This is similar to using
  [wgrib](http://www.cpc.ncep.noaa.gov/products/wesley/wgrib.html) or
  [wgrib2](http://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/) with
  the "-s" option.
* `GRIB_GET_RECORD`: Gets a single record, selected by index, from a
  GRIB file.
* `GRIB_GET_PARAMETERNAMES`: Gets the value of the `parameterName`,
  `name`, `shortName` or `cfName` key from each record in a GRIB
  file.
* `GRIB_GET_PARAMETER`: Uses `GRIB_GET_PARAMETERNAMES` and
  `GRIB_GET_RECORD` to extract all the records in a GRIB file with
  a given parameter name.

The IDL GRIB Helper Library
routines can be called from the IDL command line or used as
library routines in programs.

Although these routines have been tested on a variety of GRIB1 and GRIB2 files
from ECMWF, NCEP, NCAR, NOAA and AFWA,
GRIB is a tricky format,
so there's 
no guarantee that they'll work with every GRIB file.
