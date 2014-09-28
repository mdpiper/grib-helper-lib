; docformat = 'rst'
;+
; Creates a list of all the variables in a GRIB1/2 file. Modeled on
; the indispensible "wgrib/wgrib2" with the "-s" option.
;
; :params:
;  grib_file: in, required, type=string
;   The path to a GRIB1/2 file.
;   
; :keywords:
;  multi_support: in, optional, type=boolean
;   Set this keyword to toggle on multiple field support. Off by default.
;
; :returns:
;  A string array with info about the contents of the GRIB file.
;
; :examples:
;  The output from this routine can handliy be viewed with PM or with
;  XDISPLAYFILE::
;     IDL> f = '/path/to/grib_file.grb'
;     IDL> s = grib_inventory(f)
;     IDL> pm, s
;     IDL> xdisplayfile, text=s
;
; :requires:
;  IDL 8.1
;
; :pre:
;  GRIB is supported on Mac & Linux for IDL >= 8.1 and on Windows for 
;  IDL >= 8.3.
;
; :todo:
;  Add option to write to a text file. Clean up XXX blocks.
;  
; :author:
;  Mark Piper, 2012
;
; :history:
;  Minor updates::
;   2012-08, MP: From Corinne James / Oregon State Univ.: defining h_record 
;            as lon64arr fixes segfault on 64-bit Mac and Linux. Many thanks!
;   2014-09, MP: GRIB is supported on Windows in IDL 8.3.
;-
function grib_inventory, grib_file, multi_support=multi, debug=debug
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
   fid = grib_open(grib_file)
   
   ; Enable/disable allowing multiple fields/record.
   grib_multi_support, keyword_set(multi)
   
   ; Get a handle for each record in the file. Note this array is zero-based.
   n_records = grib_count(grib_file)
   h_record = lon64arr(n_records) ; from Corinne James / Oregon State
   for i=0, n_records-1 do h_record[i] = grib_new_from_file(fid)
   
   inventory = strarr(n_records)
   i_record = 0
   while (i_record lt n_records) do begin
   
      info = hash()
      h = h_record[i_record]
      iter = grib_keys_iterator_new(h, /all)
      while grib_keys_iterator_next(iter) do begin
         key = grib_keys_iterator_get_name(iter)
         
         ; XXX: There must be a better way.
         switch 1 of
            strcmp(key, 'GRIBEditionNumber', /fold_case):
            strcmp(key, 'centre', /fold_case):
            strcmp(key, 'name', /fold_case):
            strcmp(key, 'shortName', /fold_case):
            strcmp(key, 'parameterName', /fold_case):
            strcmp(key, 'units', /fold_case):
            strcmp(key, 'typeOfLevel', /fold_case):
            strcmp(key, 'pressureUnits', /fold_case):
            strcmp(key, 'level', /fold_case):
            strcmp(key, 'levels', /fold_case):
            strcmp(key, 'unitsOfFirstFixedSurface', /fold_case): begin
               info[key] = grib_get(h, key)
               break
            end
            else:
         endswitch
         
      endwhile ; loop over keys in record
      
      ; Check for desired keys missing from the info hash. 
      ; XXX: Not robust.
      missing = 'n/a'
      if grib_is_missing(h, 'unitsOfFirstFixedSurface') then $
         info['unitsOfFirstFixedSurface'] = missing
      if grib_is_missing(h, 'units') then $
         info['units'] = missing
      if grib_is_missing(h, 'shortName') then $
         info['shortName'] = missing
      if ~info.haskey('level') then $
         info['level'] = info.haskey('levels') ? info['levels'] : missing
      if ~info.haskey('name') || info['name'] eq 'unknown' then $
         info['name'] = info['parameterName']
         
      ; Make a string from the info gleaned from the current record.
      fmt1 = '(i4," : ",a6," : ")'
      str1 = string(i_record+1, info['shortName'], format=fmt1)
      fmt2 = '(a50," : ")'
      str2 = string(info['name'] + ' (' + info['units'] + ')', format=fmt2)
      fmt3 = '(a20," : ")'
      str3 = string(strtrim(info['level'],2) + ' (' $
         + info['unitsOfFirstFixedSurface'] + ')', format=fmt3)
      fmt4 = '(a)'
      str4 = info['typeOfLevel']
      inventory[i_record] = str1 + str2 + str3 + str4
      
      grib_keys_iterator_delete, iter
      i_record++
      
   endwhile ; loop over records in file
   
   ; Release all the handles and close the file.
   foreach h, h_record do grib_release, h
   grib_close, fid
   
   header = [ $
      'File: ' + grib_file, $
      'GRIB' + strtrim(info['GRIBEditionNumber'],2), $
      'Originating centre: ' + info['centre'], $
      'Records: ' + strtrim(n_records, 2) $
      ]
      
   return, [header, inventory]
end
