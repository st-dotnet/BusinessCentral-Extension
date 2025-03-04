codeunit 50114 GetTableData
{
    [ServiceEnabled]
    procedure GetDataByTableName(TableName: Text): Text
    var
        tableNo: Integer;
        recordRef: RecordRef;
        fieldRef: FieldRef;
        fieldIndex: Integer;
        outputText: Text;
        fieldTypeText: Text;
        fieldList: Text;
    begin
        // Get the table number from the table name
        tableNo := getTableNo(TableName);

        // If the table does not exist, return an error message
        if tableNo = -1 then
            exit('{ "error": "Table not found" }');

        recordRef.Open(tableNo); // Open the specified table

        // Get field information (Names & Data Types)
        fieldList := '{ "Fields": [';
        for fieldIndex := 1 to recordRef.FieldCount() do begin
            fieldRef := recordRef.FieldIndex(fieldIndex); // Get field reference

            // Convert field type to readable text
            case fieldRef.Type of
                FieldType::Integer:
                    fieldTypeText := 'Integer';
                FieldType::Decimal:
                    fieldTypeText := 'Decimal';
                FieldType::Code:
                    fieldTypeText := 'Code';
                FieldType::Text:
                    fieldTypeText := 'Text';
                FieldType::Date:
                    fieldTypeText := 'Date';
                FieldType::DateTime:
                    fieldTypeText := 'DateTime';
                FieldType::Boolean:
                    fieldTypeText := 'Boolean';
                else
                    fieldTypeText := 'Other';
            end;

            fieldList += '{ "FieldName": "' + Format(fieldRef.Caption) + '", "DataType": "' + fieldTypeText + '" },';
        end;
        fieldList := DelStr(fieldList, StrLen(fieldList), 1) + '],'; // Remove last comma & close array

        // Get table records
        outputText := fieldList + '"Records": [';
        if recordRef.FindSet() then begin
            repeat
                outputText += '{';
                for fieldIndex := 1 to recordRef.FieldCount() do begin
                    fieldRef := recordRef.FieldIndex(fieldIndex);
                    outputText += '"' + Format(fieldRef.Caption) + '": "' + Format(fieldRef.Value) + '",';
                end;
                outputText := DelStr(outputText, StrLen(outputText), 1) + '},'; // Remove last comma
            until recordRef.Next() = 0;
            outputText := DelStr(outputText, StrLen(outputText), 1); // Remove last comma
        end;

        outputText += ']}'; // Close JSON
        exit(outputText);
    end;

    /// <summary>
    /// Look up a table number from the table name
    /// </summary>
    /// <param name="tableName">table name</param>
    /// <returns>table number</returns>    
    local procedure getTableNo(tableName: Text): Integer
    var
        Object: Record "Table Metadata";
    begin
        Object.SetRange(Name, tableName);
        if Object.FindFirst() then
            exit(Object.ID)
        else
            exit(-1);
    end;
}