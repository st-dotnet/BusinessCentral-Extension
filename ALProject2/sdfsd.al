// /// <summary>
// /// Main implementation of meta data and data retrieval routines.
// /// </summary>
// codeunit 55509 JDMGetDataImpl
// {

//     // Make sure this codeunit's functionality is only available within our extension
//     Access = Internal;
//     SingleInstance = true;
//     /// <summary>
//     /// Retrieves a chunk of data from a table
//     /// </summary>
//     /// <param name="companyName">company</param>
//     /// <param name="tableName">table</param>
//     /// <param name="filters">(optional) delimited list of filters</param>
//     /// <param name="startRec">starting record index</param>
//     /// <param name="maxRecs">max number of records to return</param>
//     /// <param name="numFields">(out) receives number of fields returned</param>
//     /// <param name="numRecs">(out) receives number of records returned</param>
//     /// <param name="result">(out) receives base64 encoded records</param>
//     [TryFunction]
//     procedure GetTableData(companyName: Text; tableName: Text; fields: Text; filters: Text; isV2: Boolean; startPosn: Text; startRec: Integer; maxRecs: Integer; insightMetricsInt: Dictionary of [Text, Integer]; var result: Text)
//     var
//         compression: Codeunit "Data Compression";
//         recBlob: Codeunit "Temp Blob";
//         compressedRecBlob: Codeunit "Temp Blob";
//         base64Helper: CodeUnit "Base64 Convert";
//         recordRef: RecordRef;
//         fieldRef: FieldRef;
//         tableNo: Integer;
//         fieldIdx: Integer;
//         fieldList: List of [Text];
//         fieldNo: Integer;
//         fieldNos: List of [Integer];
//         fieldTypes: List of [Integer];
//         fieldIsFlowField: List of [Boolean];
//         fieldDelimiter: Char;
//         numFields: Integer;
//         recordDelimiter: Char;
//         numRecs: Integer;
//         fieldTypeString: Text;
//         fieldType: Integer;
//         isEnd: Boolean;
//         myOutStream: OutStream;
//         myInStream: InStream;
//         myCompressedOutStream: OutStream;
//         myCompressedInStream: InStream;
//         startField: Integer;
//         timeStartTotal: DateTime;
//         timeStart: DateTime;
//         timeEnd: DateTime;
//         timeFilters: Duration;
//         timeSkip: Duration;
//         timeProcess: Duration;
//         timeTotal: Duration;
//         fieldBlob: Codeunit "Temp Blob";
//         fieldValueInt: Integer;
//         myFieldInStream: InStream;
//         DateValue: Date;
//         ClosingDateValue: Date;
//         fieldValueString: Text;
//         valueString: TextBuilder;
//     begin
//         timeStartTotal := CurrentDateTime;

//         // create temp streams (uncompressed and compressed)
//         recBlob.CreateOutStream(myOutStream, TextEncoding::UTF8);
//         recBlob.CreateInStream(myInStream, TextEncoding::UTF8);
//         compressedRecBlob.CreateOutStream(myCompressedOutStream, TextEncoding::UTF8);
//         compressedRecBlob.CreateInStream(myCompressedInStream, TextEncoding::UTF8);

//         // special handling for "Table Relations Metadata", as it can't be accessed via recordRef
//         if (tableName = 'Table Relations Metadata') then
//             myOutStream.WriteText(getTableRelationsMetadata(startRec, maxRecs))

//         else begin
//             fieldDelimiter := 0;
//             recordDelimiter := 1;

//             // look up table number
//             tableNo := getTableNo(tableName);
//             if (tableNo < 0) then begin
//                 result := 'ERROR Table ' + tableName + ' not found';
//                 exit;
//             end;

//             // open it (for specified company)
//             if (companyName = '') then
//                 recordRef.Open(tableNo, false)
//             else
//                 recordRef.Open(tableNo, false, companyName);

//             if (fields = '') then begin
//                 // no fields specified, so we'll return them all
//                 numFields := recordRef.FieldCount;
//                 //startField := 0;
//                 startField := 1; // until we get ok from Microsoft about using field 0=timestamp

//             end else begin
//                 // fields specified, so split the array of field names
//                 startField := 1;
//                 fieldList := fields.Split(';');
//                 numFields := fieldList.Count;

//                 // look up field nos
//                 for fieldIdx := startField to numFields do begin
//                     // waiting for feedback from Microsoft on whether we can use field 0 as timestamp
//                     //if (fieldList.Get(fieldIdx) = 'timestamp') then begin
//                     //    fieldNo := 0;
//                     //end else begin
//                     fieldNo := getFieldNo(tableNo, fieldList.Get(fieldIdx));
//                     //end;
//                     if (fieldNo < 0) then begin
//                         result := 'ERROR Field ' + fieldList.Get(fieldIdx) + ' not found';
//                         exit;
//                     end;
//                     fieldNos.Add(fieldNo);
//                 end;

//                 // process (optional) field filters
//                 timeStart := CurrentDateTime;
//                 if (not setFilters(recordRef, fieldNos, startField, filters, result)) then
//                     exit;
//                 timeEnd := CurrentDateTime;
//                 timeFilters := (timeEnd - timeStart);

//             end;

//             // for initial query, return field names and types
//             if (startRec = 0) then begin
//                 // first line of return text gets field names
//                 for fieldIdx := startField to numFields do begin
//                     if (fields = '') then
//                         // no fields specified, so just access by index
//                         fieldRef := recordRef.FieldIndex(fieldIdx)
//                     else
//                         // fields specified, access by field no
//                         fieldRef := recordRef.Field(fieldNos.Get(fieldIdx));
//                     myOutStream.WriteText(Format(fieldRef.Name) + fieldDelimiter);
//                 end;
//                 myOutStream.WriteText(recordDelimiter);
//                 // second line of return text gets field types
//                 for fieldIdx := startField to numFields do begin
//                     if (fields = '') then
//                         // no fields specified, so just access by index
//                         fieldRef := recordRef.FieldIndex(fieldIdx)
//                     else
//                         // fields specified, access by field no
//                         fieldRef := recordRef.Field(fieldNos.Get(fieldIdx));

//                     fieldTypeString := Format(fieldRef.Type);
//                     if (fieldTypeString = 'Code') or (fieldTypeString = 'Text') or (fieldTypeString = 'OemText') then
//                         fieldTypeString := fieldTypeString + Format(fieldRef.Length);
//                     myOutStream.WriteText(fieldTypeString + fieldDelimiter);
//                 end;
//                 myOutStream.WriteText(recordDelimiter);
//             end;

//             for fieldIdx := startField to numFields do begin
//                 if (fields = '') then
//                     // no fields specified, so just access by index
//                     fieldRef := recordRef.FieldIndex(fieldIdx)
//                 else
//                     // fields specified, access by field no
//                     fieldRef := recordRef.Field(fieldNos.Get(fieldIdx));

//                 // special handling for data types
//                 fieldTypeString := Format(fieldRef.Type);
//                 case fieldTypeString of

//                     'Text':
//                         fieldType := 1;
//                     'Option', 'Boolean':
//                         fieldType := 2;
//                     'Decimal':
//                         fieldType := 3;
//                     'Date':
//                         fieldType := 4;
//                     'DateTime':
//                         fieldType := 5;
//                     'Time':
//                         fieldType := 6;
//                     'BLOB':
//                         fieldType := 7;
//                     'Media':
//                         fieldType := 8;
//                     'MediaSet':
//                         fieldType := 9;
//                     else
//                         fieldType := 10;
//                 end;
//                 fieldTypes.Add(fieldType);

//                 if (Format(fieldRef.Class) = 'FlowField') then
//                     fieldIsFlowField.Add(true)
//                 else
//                     fieldIsFlowField.Add(false);
//             end;

//             // start processing records
//             if recordRef.FindSet(false) then begin
//                 isEnd := false;
//                 if (startRec > 0) then begin
//                     // start record specified, so fast forward to it
//                     timeStart := CurrentDateTime;
//                     if (isV2 and (startPosn <> '')) then begin
//                         recordRef.SetPosition(startPosn);
//                         recordRef.Find('=');
//                     end else
//                         isEnd := (recordRef.Next(startRec) < startRec);
//                     timeEnd := CurrentDateTime;
//                     timeSkip := (timeEnd - timeStart);
//                 end;

//                 if not isEnd then begin
//                     numRecs := 0;
//                     timeStart := CurrentDateTime;
//                     valueString.Clear();
//                     repeat
//                         // loop through fields
//                         for fieldIdx := startField to numFields do begin

//                             if (fields = '') then
//                                 // no fields specified, so just access by index
//                                 fieldRef := recordRef.FieldIndex(fieldIdx)
//                             else
//                                 // fields specified, access by field no
//                                 fieldRef := recordRef.Field(fieldNos.Get(fieldIdx));

//                             // if class if FlowField, need to calc it now
//                             if (fieldIsFlowField.Get(fieldIdx)) then
//                                 fieldRef.CalcField();

//                             // special handling for data types
//                             //fieldTypeString := Format(fieldRef.Type);
//                             case fieldTypes.Get(fieldIdx) of

//                                 //'Text':
//                                 1:
//                                     fieldValueString := fieldRef.Value;

//                                 // for Option, return the integer value rather than the string
//                                 // for Boolean, return as an integer rather than "no" "yes"
//                                 //'Option', 'Boolean':
//                                 2:
//                                     begin
//                                         fieldValueInt := fieldRef.Value;
//                                         fieldValueString := Format(fieldValueInt);
//                                     end;
//                                 // return numbers in 'XML' format (i.e. don't apply regional formatting)
//                                 //'Decimal':
//                                 3:
//                                     fieldValueString := Format(fieldRef.Value, 0, 9);
//                                 // return dates in international format to avoid regional issues
//                                 //'Date':
//                                 4:
//                                     begin
//                                         DateValue := fieldRef.Value;
//                                         if (DateValue <> 0D) then begin //date value is not empty
//                                                                         //Special case: Chek if the field's current value
//                                                                         //is a closing date. By getting the actual field's
//                                                                         //date value and compare with closing date of the same.
//                                             ClosingDateValue := ClosingDate(DateValue);
//                                             If (DateValue = ClosingDateValue) Then begin
//                                                 //This is a closing date, so build the special value of datetime type by append time part as 23:59:59 at end.
//                                                 fieldValueString := Format(DateValue, 0, '<Year4>-<Month>-<Day>') + ' 23:59:59';
//                                             end
//                                             Else
//                                                 fieldValueString := Format(fieldRef.Value, 0, '<Year4>-<Month>-<Day>');
//                                         end
//                                         else //date value is empty
//                                             fieldValueString := Format(fieldRef.Value, 0, '<Year4>-<Month>-<Day>');
//                                     end;
//                                 //'DateTime':
//                                 5:
//                                     fieldValueString := Format(fieldRef.Value, 0, '<Year4>-<Month>-<Day> <Hours24>:<Minutes>:<Seconds><Second dec>');
//                                 //'Time':
//                                 6:
//                                     fieldValueString := Format(fieldRef.Value, 0, '<Hours24>:<Minutes>:<Seconds><Second dec>');
//                                 //'BLOB':
//                                 7:
//                                     begin
//                                         fieldRef.CalcField();
//                                         fieldBlob.FromFieldRef(fieldRef);
//                                         fieldBlob.CreateInStream(myFieldInStream);
//                                         if (fieldBlob.HasValue()) then
//                                             fieldValueString := base64Helper.ToBase64(myFieldInStream)
//                                         else
//                                             fieldValueString := '';
//                                     end;
//                                 //'Media':
//                                 8:
//                                     fieldValueString := getMediaAsBase64(false, fieldRef.Value);
//                                 //'MediaSet':
//                                 9:
//                                     fieldValueString := getMediaAsBase64(true, fieldRef.Value);
//                                 //'TableFilter':
//                                 //Evaluate(fieldValueString, fieldRef.Value);
//                                 else
//                                     fieldValueString := Format(fieldRef.Value);
//                             end;

//                             // write text encoded field
//                             valueString.Append(fieldValueString + fieldDelimiter);

//                         end;

//                         valueString.Append(recordDelimiter);
//                         numRecs := numRecs + 1;

//                         if (recordRef.Next() = 0) then begin
//                             isEnd := true;
//                         end

//                     // loop until done, or max records reached
//                     until (isEnd) OR (numRecs = maxRecs);
//                     myOutStream.WriteText(valueString.ToText());
//                     timeEnd := CurrentDateTime;
//                     timeProcess := (timeEnd - timeStart);
//                 end;

//                 timeEnd := CurrentDateTime;
//                 timeTotal := (timeEnd - timeStartTotal);
//                 if (isV2) then begin
//                     myOutStream.WriteText('STATISTICS:'
//                         + 'SqlStatementsExecuted=' + Format(SessionInformation.SqlStatementsExecuted)
//                         + ',SqlRowsRead=' + Format(SessionInformation.SqlRowsRead)
//                         + ',timeTotal=' + Format(timeTotal / 1, 0, 1) + 'ms'
//                         + ',timeFilters=' + Format(timeFilters / 1, 0, 1) + 'ms'
//                         + ',timeSkip=' + Format(timeSkip / 1, 0, 1) + 'ms'
//                         + ',timeProcess=' + Format(timeProcess / 1, 0, 1) + 'ms'
//                         + ',recordPosition=' + recordRef.GetPosition(false));
//                     myOutStream.WriteText(recordDelimiter);
//                 end;

//                 // if more data remains, alert caller with a RESUME line
//                 if ((numRecs = maxRecs) and not isEnd) then
//                     myOutStream.WriteText('RESUME:' + Format(startRec + numRecs));

//             end;
//         end;

//         // compress the output, then base64 encode it
//         compression.GZipCompress(myInStream, myCompressedOutStream);
//         result := base64Helper.ToBase64(myCompressedInStream);

//         // add telemetry data to dictionary
//         insightMetricsInt.Add('Fields', numFields);
//         insightMetricsInt.Add('Records', numRecs);
//         insightMetricsInt.Add('StartRec', startRec);
//         insightMetricsInt.Add('FilterTime', timeFilters);
//         insightMetricsInt.Add('SkipTime', timeSkip);
//         insightMetricsInt.Add('ProcessTime', timeProcess);
//     end;

//     /// <summary>
//     /// Returns the delimited list of captions for a given field of type Option
//     /// </summary>
//     /// <param name="fieldRef">field reference</param>
//     /// <returns>Option captions encoded as a delimited string</returns> 
//     /// <param name="tableNo">table number</param>
//     /// <param name="fieldNo">field number</param>
//     [TryFunction]
//     procedure GetOptionCaptions(tableNo: Integer; fieldNo: Integer; var result: Text)
//     var
//         recordRef: RecordRef;
//         fieldRef: FieldRef;
//     begin
//         // open table
//         recordRef.Open(tableNo, false);
//         fieldRef := recordRef.Field(fieldNo);
//         result := fieldRef.OptionCaption();
//     end;

//     /// <summary>
//     /// Sets the filters on a query
//     /// </summary>
//     /// <param name="recordRef">record reference for query</param>
//     /// <param name="fieldNos">list of field numbers being filtered</param>
//     /// <param name="startField">starting field # (0 if including hidden timestamp field)</param>
//     /// <param name="filters">delimited string of filters</param>
//     /// <param name="result">(out) receives an error message, if needed</param>
//     /// <returns>status (true=success or false=failure)</returns>   
//     local procedure setFilters(recordRef: RecordRef; fieldNos: List of [Integer]; startField: Integer; filters: Text; var result: Text) status: Boolean
//     var
//         base64Helper: CodeUnit "Base64 Convert";
//         fieldRef: FieldRef;
//         dataSelectionRules: List of [Text];
//         filterList: List of [Text];
//         fieldIdx: Integer;
//         filterString: Text;
//     begin
//         status := true;
//         if (filters <> '') then begin

//             // split the || delimited list of Data Selection Rules
//             dataSelectionRules := filters.Split('||');

//             foreach filters in dataSelectionRules do begin
//                 // split the ; delimited list of filters
//                 filterList := filters.Split(';');

//                 if (filterList.Count <> fieldNos.Count) then begin
//                     result := 'ERROR ' + Format(filterList.Count) + ' filters found, expected ' + Format(fieldNos.Count);
//                     status := false;
//                     exit;
//                 end;

//                 // loop through each field, setting up filters
//                 for fieldIdx := startField to fieldNos.Count do begin
//                     fieldRef := recordRef.Field(fieldNos.Get(fieldIdx));
//                     filterString := base64Helper.FromBase64(filterList.Get(fieldIdx));
//                     fieldRef.SetFilter(filterString);
//                 end;

//                 // if multiple selection rules specified, use record marking
//                 // technique -- but if only a single rule, just use the
//                 // filters (better performance)
//                 if (dataSelectionRules.Count > 1) then begin
//                     // mark records covered by filters
//                     markRecords(recordRef);

//                     // remove filters
//                     for fieldIdx := startField to fieldNos.Count do begin
//                         fieldRef := recordRef.Field(fieldNos.Get(fieldIdx));
//                         fieldRef.SetFilter('');
//                     end;
//                 end;

//             end;
//             if (dataSelectionRules.Count > 1) then
//                 recordRef.MarkedOnly(true); //filtering only marked records
//         end;
//     end;

//     /// <summary>
//     /// mark records in recordref based on the other recordref
//     /// </summary>
//     /// <param name="recordRef">recordRef</param>
//     /// <returns></returns>   
//     local procedure markRecords(var recordRef: RecordRef)
//     begin
//         if recordRef.FindSet() then
//             repeat
//                 recordRef.Mark(true);
//             until recordRef.Next() = 0;
//     end;

//     /// <summary>
//     /// look up a table number
//     /// </summary>
//     /// <param name="tableName">table name</param>
//     /// <returns>table number</returns>    
//     local procedure getTableNo(tableName: Text) tableNo: Integer
//     var
//         Object: Record "Table Metadata";
//     begin
//         tableNo := -1;
//         Object.SetRange(Name, tableName);
//         if Object.FindFirst() then
//             tableNo := Object.ID;
//         exit(tableNo);
//     end;
//     /// <summary>
//     /// look up a field number
//     /// </summary>
//     /// <param name="tableID">table number</param>
//     /// <param name="fieldName">field name</param>
//     /// <returns>field number</returns>  
//     local procedure getFieldNo(tableID: Integer; fieldName: Text) fieldNo: Integer
//     var
//         recField: Record "Field";
//     begin
//         fieldNo := -1;
//         recField.SetRange(TableNo, tableID);
//         recField.SetFilter(FieldName, '%1', fieldName);
//         if (recField.FindFirst()) then
//             fieldNo := recField."No.";
//         exit(fieldNo);
//     end;
//     /// <summary>
//     /// query the "Table Relations Metadata" table
//     /// (for some reason, this table can't be accessed via recordRef, so requires this special function)
//     /// </summary>
//     /// <param name="startRec">starting record index</param>
//     /// <param name="maxRecs">maximum number of records</param>
//     /// <returns>encoded records</returns>
//     local procedure getTableRelationsMetadata(startRec: Integer; maxRecs: Integer): Text
//     var
//         rec: Record "Table Relations Metadata";
//         dataTextBuilder: TextBuilder;
//         fieldDelimiter: Char;
//         recordDelimiter: Char;
//         recNum: Integer;
//         isEnd: Boolean;
//     begin
//         fieldDelimiter := 0;
//         recordDelimiter := 1;
//         if rec.FindSet(false) then begin
//             isEnd := false;
//             if (startRec > 0) then
//                 // start record specified, so fast forward to it
//                 isEnd := (rec.Next(startRec) < startRec)
//             else begin
//                 // first line of return text gets field names
//                 dataTextBuilder.Append('Table ID' + fieldDelimiter);
//                 dataTextBuilder.Append('Field No.' + fieldDelimiter);
//                 dataTextBuilder.Append('Relation No.' + fieldDelimiter);
//                 dataTextBuilder.Append('Condition No.' + fieldDelimiter);
//                 dataTextBuilder.Append('Related Table ID' + fieldDelimiter);
//                 dataTextBuilder.Append('Related Field No.' + fieldDelimiter);
//                 dataTextBuilder.Append('Condition Type' + fieldDelimiter);
//                 dataTextBuilder.Append('Condition Field No.' + fieldDelimiter);
//                 dataTextBuilder.Append('Condition Value' + fieldDelimiter);
//                 dataTextBuilder.Append(recordDelimiter);
//                 // second line of return text gets field types
//                 dataTextBuilder.Append('Integer' + fieldDelimiter);
//                 dataTextBuilder.Append('Integer' + fieldDelimiter);
//                 dataTextBuilder.Append('Integer' + fieldDelimiter);
//                 dataTextBuilder.Append('Integer' + fieldDelimiter);
//                 dataTextBuilder.Append('Integer' + fieldDelimiter);
//                 dataTextBuilder.Append('Integer' + fieldDelimiter);
//                 dataTextBuilder.Append('Text' + fieldDelimiter);    // on purpose, instead of Option (otherwise client expects int)
//                 dataTextBuilder.Append('Integer' + fieldDelimiter);
//                 dataTextBuilder.Append('Text30' + fieldDelimiter);
//                 dataTextBuilder.Append(recordDelimiter);
//             end;
//             if not isEnd then begin
//                 recNum := 0;
//                 repeat
//                     dataTextBuilder.Append(Format(rec."Table ID") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Field No.") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Relation No.") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Condition No.") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Related Table ID") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Related Field No.") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Condition Type") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Condition Field No.") + fieldDelimiter);
//                     dataTextBuilder.Append(Format(rec."Condition Value") + fieldDelimiter);
//                     dataTextBuilder.Append(recordDelimiter);
//                     recNum := recNum + 1;
//                 // loop until done, or max records reached
//                 until (rec.Next() = 0) OR (recNum = maxRecs);
//             end;
//             if ((recNum = maxRecs) and not isEnd) then
//                 dataTextBuilder.Append('RESUME:' + Format(startRec + recNum))
//         end;
//         exit(dataTextBuilder.ToText());
//     end;

//     /// <summary>
//     /// retrieve binary media
//     /// </summary>
//     /// <param name="isMediaSet">flag (true/false) indicating whether this is a media set</param>
//     /// <param name="mediaGUID">GUID of media item</param>
//     /// <returns>binary media encoded as base64</returns>  
//     local procedure getMediaAsBase64(isMediaSet: Boolean; mediaGUID: Guid) mediaAsBase64: Text
//     var
//         tenantMedia: Record "Tenant Media";
//         tenantMediaSet: Record "Tenant Media Set";
//         base64Helper: CodeUnit "Base64 Convert";
//         myInStream: InStream;
//     begin
//         mediaAsBase64 := '';
//         // if media set, then just get the GUID of the first item in the list
//         // (can only support returning one media item for now)
//         if (isMediaSet) then begin
//             tenantMediaSet.SetRange(ID, mediaGUID);
//             if (tenantMediaSet.FindFirst()) then
//                 mediaGUID := tenantMediaSet."Media ID".MediaId;
//         end;
//         tenantMedia.SetRange(ID, mediaGUID);
//         if (tenantMedia.FindFirst()) then begin
//             tenantMedia.CalcFields(Content);
//             tenantMedia.Content.CreateInStream(myInStream);
//             mediaAsBase64 := base64Helper.ToBase64(myInStream);
//         end;
//         exit(mediaAsBase64);
//     end;

//     /// <summary>
//     /// Sends application telemetry somewhere (currently MS Application Insights)
//     /// </summary>
//     /// <param name="source">source of request/action</param>
//     /// <param name="name">name of operation being measured</param>
//     /// <param name="elapsed">elapsed time</param>
//     /// <param name="success">status of request/action</param>
//     /// <param name="properties">dictionary of properties associated with request/action</param>
//     /// <param name="metricsInt">dictionary of metrics measured</param>
//     [TryFunction]
//     procedure SendTelemetry(source: Text; name: Text; elapsed: Duration; success: Boolean; properties: Dictionary of [Text, Text]; metricsInt: Dictionary of [Text, Integer]; metricsDec: Dictionary of [Text, Decimal])
//     var
//         JSON: JsonObject;
//         JSONData: JsonObject;
//         JSONEventData: JsonObject;
//         JSONProperties: JsonObject;
//         JSONMeasurements: JsonObject;
//         Client: HttpClient;
//         Content: HttpContent;
//         Headers: HttpHeaders;
//         Response: HttpResponseMessage;
//         PropName: Text;
//         PropValue: Text;
//         MetricName: Text;
//         MetricValueInt: Integer;
//         MetricValueDec: Decimal;
//         Result: Text;
//         bigint: BigInteger;
//         intHours: Integer;
//         intMin: Integer;
//         intSec: Integer;
//         intMSec: Integer;
//     begin
//         // build a JSON object containing the necessary parameters for an Application Insights telemetry post
//         JSON.Add('name', 'JDMExtension.Request');
//         JSON.Add('time', Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2><Second dec.>'));

//         // specify the API key here - currently the insightsoftware/SWPros Azure key
//         JSON.Add('iKey', '4fe0db09-a1f9-473a-8512-b92e7973eff9');
//         JSONData.Add('baseType', 'RequestData');
//         JSONEventData.Add('ver', 2);
//         JSONEventData.Add('id', '0');

//         // elapsed time needs to be encoded into duration field
//         bigInt := elapsed;
//         intHours := bigInt DIV (60 * 60 * 1000);
//         bigInt := bigint - (intHours * 60 * 60 * 1000);
//         intMin := bigInt DIV (60 * 1000);
//         bigInt := bigInt - (intMin * 60 * 1000);
//         intSec := bigInt DIV 1000;
//         bigInt := bigInt - (intSec * 1000);
//         intMSec := bigInt;
//         JSONEventData.Add('duration', Format(intHours, 0, '<Integer,2><Filler,0>') + ':' + Format(intMin, 0, '<Integer,2><Filler,0>') + ':' + Format(intSec, 0, '<Integer,2><Filler,0>') + '.' + Format(intMSec, 0, '<Integer,3><Filler,0>'));
//         // add the rest of the parameters/properties/measurements
//         JSONEventData.Add('responseCode', 'N/A');
//         JSONEventData.Add('success', Format(success, 0, 9));
//         JSONEventData.Add('source', source);
//         JSONEventData.Add('name', name);
//         JSONEventData.Add('url', '');
//         if (properties.Count > 0) then
//             foreach PropName in properties.Keys() do begin
//                 properties.Get(PropName, PropValue);
//                 JSONProperties.Add(PropName, PropValue);
//             end;

//         if (metricsInt.Count > 0) then
//             foreach MetricName in metricsInt.Keys() do begin
//                 metricsInt.Get(MetricName, MetricValueInt);
//                 JSONMeasurements.Add(MetricName, MetricValueInt);
//             end;

//         if (metricsDec.Count > 0) then
//             foreach MetricName in metricsDec.Keys() do begin
//                 metricsDec.Get(MetricName, MetricValueDec);
//                 JSONMeasurements.Add(MetricName, MetricValueDec);
//             end;

//         JSONEventData.Add('properties', JSONProperties);
//         JSONEventData.Add('measurements', JSONMeasurements);
//         JSONData.Add('baseData', JSONEventData);
//         JSON.Add('data', JSONData);
//         // construct the http request
//         Content.Clear();
//         Content.WriteFrom(Format(JSON));
//         Content.GetHeaders(Headers);
//         Headers.Remove('Content-Type');
//         Headers.Add('Content-Type', 'application/json');

//         // post telemtry to the MS Application Insights system
//         Client.Post('https://dc.services.visualstudio.com/v2/track', Content, Response);
//         Response.Content().ReadAs(Result);
//     end;
// }