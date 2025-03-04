codeunit 50115 FetchRecords
{
    [ServiceEnabled]
    procedure FetchDatabaseRecords(): Text
    var
        allObj: Record AllObjWithCaption;
        tablesArray: JsonArray;
        tableObject: JsonObject;
        jsonText: Text;
    begin
        // Filter only tables
        allObj.SetFilter("Object Type", 'Table');

        if allObj.FindSet() then
            repeat
                // Create JSON Object for each table
                tableObject.Add('TableID', allObj."Object ID");
                tableObject.Add('TableName', allObj."Object Caption");

                // Add to JSON Array
                tablesArray.Add(tableObject);

                // Clear JSON object for next record
                Clear(tableObject);
            until allObj.Next() = 0;

        // Convert JSON Array to Text
        tablesArray.WriteTo(jsonText);

        exit(jsonText);
    end;
}