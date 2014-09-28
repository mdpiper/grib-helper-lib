; docformat = 'rst'
;+
; Gets the name associated with each record in a GRIB1/2 file. By default,
; it uses the value of the key 'parameterName', but the value of the keys
; 'name', 'shortName' or 'cfName' may be used instead. The name may be an
; index. Match this value with the parameter table given by the originating
; data center for the file; e.g., for data from NCEP, see::
;  http://www.nco.ncep.noaa.gov/pmb/docs/on388/table2.html
;
; Examples of a few parameter values, abbreviations & names::
;
;  index    abbreviation   parameter name
;  -----    ------------   --------------
;  157      CAPE           convective available potential energy
;  193      POP            probability of precipitation
;  121      LHTFL          latent heat net flux
;  71       TCDC           total cloud cover
;
; Use GRIB_GET_RECORD to read the data for a particular record (by index)
; in a GRIB file.
;
; :params:
;  grib_file: in, required, type=string
;   The path to a GRIB1/2 file.
;
; :keywords:
;  use_name: in, optional, type=boolean
;   Set this keyword to use the 'name' key instead of 'parameterName'.
;  use_shortname: in, optional, type=boolean
;   Set this keyword to use the 'shortName' key instead of 'parameterName'.
;  use_cfname: in, optional, type=boolean
;   Set this keyword to use the 'cfName' key instead of 'parameterName'.
;  multi_support: in, optional, type=boolean
;   Set this keyword to toggle on multiple field support. Off by default.
;
; :returns:
;  An array of parameter names, as strings, in the order in which the
;  record is positioned in the GRIB file.
;
; :examples:
;  Get all the parameter names/indices from a GRIB file::
;     IDL> f = '/path/to/grib_file.grb'
;     IDL> p = grib_get_parameternames(f)
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
;   2012-03, MP: Added USE_NAME, USE_SHORTNAME and USE_CFNAME keywords.
;   2012-03, MP: Added MULTI_SUPPORT keyword & error handling.
;   2014-09, MP: GRIB is supported on Windows in IDL 8.3.
;-
function grib_get_parameternames, grib_file, $
      use_name=use_name, $
      use_shortname=use_shortname, $
      use_cfname=use_cfname, $
      multi_support=multi, $
      debug=debug
   compile_opt idl2
   
   if keyword_set(debug) then error = 0 else catch, error
   if error ne 0 then begin
      catch, /cancel
      message, !error_state.msg, /informational
      return, !null
   endif
   
   ; Check IDL version.
   cond1 = !version.release lt 8.1
   cond2 = !version.release lt 8.3 && !version.os_family eq 'Windows'
   if cond1 || cond2 then begin
      msg = 'IDL GRIB library requires 8.1 or greater on Mac OS X or Linux' $
            + ' and 8.3 or greater on Windows.'
      message, msg, /noname
   endif
   
   if grib_file eq !null then return, !null

   ; Enable/disable allowing multiple fields/record.
   grib_multi_support, keyword_set(multi)
   
   ; Choose which GRIB key to use for the 'name' of the parameter.
   case 1 of
      keyword_set(use_name): the_name = 'name'
      keyword_set(use_shortname): the_name = 'shortName'
      keyword_set(use_cfname): the_name = 'cfName'
      else: the_name = 'parameterName'
   endcase
   
   file_id = grib_open(grib_file)
   n_records = grib_count(grib_file)
   i_record = 0
   parameter_index = list()
   
   ; Loop over records in file.
   while (i_record lt n_records) do begin
   
      h = grib_new_from_file(file_id)
      iter = grib_keys_iterator_new(h, /all)
      
      ; Loop over keys in record, looking for the parameter key.
      while grib_keys_iterator_next(iter) do begin
         key = grib_keys_iterator_get_name(iter)
         if strlowcase(key) eq strlowcase(the_name) then begin
            parameter_index.add, grib_get(h, key)
            break
         endif
      endwhile ; loop over keys in record
      grib_keys_iterator_delete, iter
      
      grib_release, h
      i_record++
      
   endwhile ; loop over records in file
   
   grib_close, file_id
   
   return, parameter_index.toarray()
end

