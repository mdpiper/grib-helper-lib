; docformat = 'rst'
;+
; Reads the keys & data from the records of a GRIB1/2 file that (exactly)
; match a specified parameter name.
;
; :returns:
;  A hash (or a structure) containing all the key-value pairs in the
;  desired record. If more than one record matches the input parameter name,
;  a list is returned containing a hash (or a structure) for each record.
;
; :uses:
;  GRIB_GET_PARAMETERNAMES, GRIB_GET_RECORD
;
; :params:
;  grib_file : in, required, type=string
;   The path to a GRIB1/2 file.
;  parameter_name : in, optional, type=string
;   The name of the parameter to read. Usually a number cast as a string. Needs
;   to be exact, especially if it's a string with characters (e.g., 'Relative
;   humidity') instead of a string with numbers (e.g., '52'). Examine the
;   output from GRIB_GET_PARAMETERNAMES to check the parameters in a file.
;
; :keywords:
;  _extra : in, optional
;   Keyword inheritance. See keywords for GRIB_GET_RECORD.
;
; :examples:
;  Get the record(s) containing the data for the parameter 'soil moisture
;  content' from a GRIB file::
;     IDL> f = '/path/to/grib_file.grb'
;     IDL> pn = '86' ; soil moisture content
;     IDL> r = grib_get_parameter(f, pn, /structure)
;
; :requires:
;  IDL 8.1
;
; :pre:
;  GRIB is supported on Mac & Linux for IDL >= 8.1 and on Windows for 
;  IDL >= 8.3.
;
; :author:
;  Mark Piper, 2011
;
; :history:
;  Minor updates::
;   2012-03, MP: Added error handling.
;   2014-09, MP: GRIB is supported on Windows in IDL 8.3.
;-
function grib_get_parameter, grib_file, parameter_name, debug=debug, _extra=e
   compile_opt idl2
   
   if keyword_set(debug) then error = 0 else catch, error
   if error ne 0 then begin
      catch, /cancel
      message, !error_state.msg, /informational
      return, !null
   endif
   
   switch 1 of
      n_params() ne 2 :
      grib_file eq !null :
      ~isa(parameter_name, 'string') : begin
         msg = 'Please pass file name and GRIB parameter as scalar strings.'
         message, msg, /noname
      end
      !version.release lt 8.1 :
      !version.release lt 8.3 && !version.os_family eq 'Windows' : begin
         msg = 'IDL GRIB library requires 8.1 or greater on Mac OS X or Linux' $
            + ' and 8.3 or greater on Windows.'
         message, msg, /noname
      end
   endswitch
   
   ; Get all the parameter names from the GRIB file & determine if there's
   ; a match (or matches) to the input parameter name.
   pn = grib_get_parameternames(grib_file, _extra=e)
   irec = where(parameter_name eq pn, nrecsfound)
   if nrecsfound eq 0 then begin
      msg = 'Parameter "' + parameter_name + '" not found. Returning.'
      message, msg, /informational
      return, !null
   endif
   
   irec++ ; GRIB uses 1-based record number
   
   ; Read all the records with the same parameter name and accumulate them
   ; in a list.
   records = list()
   foreach id, irec do $
      records.add, grib_get_record(grib_file, id, _extra=e)
      
   return, records.count() eq 1 ? r : records
end

