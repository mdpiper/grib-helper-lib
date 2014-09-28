; docformat = 'rst'
;+
; Reads the GRIB keys & data from a single record in a GRIB file. The record
; is specified by a one-based index: 1 <= index <= number of records in file.
;
; Use GRIB_GET_PARAMETERNAMES to find the parameters contained in the records
; of a GRIB file (though you will likely need a parameter lookup table to find
; what the parameter values mean).
;
; Compare this with the Python examples 'keys_iterator.py' and
; 'count_messages.py' here::
;  https://software.ecmwf.int/wiki/display/GRIB/Grib+API+examples
;
; :params:
;  grib_file : in, required, type=string
;   The path to a GRIB1/2 file.
;  record_index : in, optional, type=integer, default=1
;   The index of the record to read. This value is capped at the last record.
;
; :keywords:
;  n_records : in, optional, type=long
;   The total number of records in the file. Optionally set this keyword to
;   the upper bound of records to read. Default is to use GRIB_COUNT to find
;   the number of records in the file.
;  structure : in, optional, type=boolean
;   Set this keyword to return the record's data in a structure instead of
;   a hash. Slower, but the advantage is that a structure preserves order.
;  multi_support: in, optional, type=boolean
;   Set this keyword to toggle on multiple field support. Off by default.
;
; :returns:
;  A hash (or a structure) containing all the key-value pairs in the
;  desired record.
;
; :examples:
;  Get the first record from a GRIB file::
;     IDL> f = '/path/to/grib_file.grb'
;     IDL> irec = 1
;     IDL> r = grib_get_record(f, irec, /structure)
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
;   2011-11, MP: Added another failing GRIB2 key, 'Derived forecast'
;   2012-02, MP: Record index must be between 1 and n_records in file
;   2012-03, MP: Failing GRIB1 key 'x' and GRIB2 key 'statistical processing'
;   2012-03, MP: Added MULTI_SUPPORT keyword & error handling
;   2012-04, MP: Workaround for CR 66408
;   2012-08, MP: From Corinne James / Oregon State Univ.: defining h_record 
;            as lon64arr fixes segfault on 64-bit Mac and Linux. Many thanks!
;   2012-12, MP: Failing GRIB2 key 'EPS information'
;   2014-09, MP: GRIB is supported on Windows in IDL 8.3.
;-
function grib_get_record, grib_file, record_index, $
      n_records=n_records, $
      structure=structure, $
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
   
   ; Ensure requested record index doesn't exceed number of records in file.
   if n_records eq !null then n_records = grib_count(grib_file)
   if record_index eq !null then record_index = 1
   if isa(record_index, /array) then record_index = record_index[0]
   if record_index gt n_records || record_index lt 1 then begin
      msg = 'Record index must be between 1 and ' + strtrim(n_records,2) + '.'
      message, msg, /noname
   endif
   
   fid = grib_open(grib_file)
   
   ; Get a handle for each record in the file. Note this array is zero-based.
   h_record = lon64arr(n_records) ; from Corinne James / Oregon State
   for i=0, n_records-1 do h_record[i] = grib_new_from_file(fid)
   
   ; XXX: A list of keys that cause GRIB_GET to throw an error. CR 63538.
   excluded_keys = [ $
      'gribSection0', $
      'template not found', $
      'Parameter information', $
      'grib 2 Section 5 DATA REPRESENTATION SECTION', $
      'grib 2 Section 6 BIT-MAP SECTION', $
      'grib 2 Section 7 data', $
      'Derived forecast', $
      'x', $
      'statistical processing', $
      'EPS information' $
      ]
   ; XXX: GRIB_ITERATOR_NEW not implemented. CR 66408.
   excluded_keys = [excluded_keys, $
      'latLonValues', $
      'latitudes', $
      'longitudes' $
      ]
      
   ; Get all keys from the desired record.
   record = keyword_set(structure) ? {} : hash()
   h = h_record[record_index-1]
   iter = grib_keys_iterator_new(h, /all)
   while grib_keys_iterator_next(iter) do begin
   
      key = grib_keys_iterator_get_name(iter)
      if strcmp(key, '7777') then continue ; end of record
      if total(excluded_keys eq key) ge 1 then continue ; see above
      
      if strcmp(key, 'values') then begin
         val = grib_get_values(h) ; preserves dimensionality
      endif else begin
         val = grib_get_size(h, key) gt 1 ? grib_get_array(h, key) : grib_get(h, key)
      endelse

      if keyword_set(structure) then begin
         if (record ne !null) $
            && total(tag_names(record) eq strupcase(key), /integer) gt 0 then $
               continue
         record = create_struct(record, key, val) ; slow
      endif else $
         record[key] = val
         
   endwhile
   grib_keys_iterator_delete, iter
   
   ; Release all the handles and close the file.
   foreach h, h_record do grib_release, h
   grib_close, fid
   
   return, record
end

