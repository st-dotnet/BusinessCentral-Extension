table 50102 Employe
{
    Caption = 'Employee Table';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "emp code"; Code[10])
        {
            DataClassification = ToBeClassified;

        }

        field(10; "emp name"; Text[15])
        {
            DataClassification = ToBeClassified;

        }

        field(20; salary; Decimal)
        {
            DataClassification = ToBeClassified;

        }

        field(30; DOJ; Date)
        {
            DataClassification = ToBeClassified;

        }

        field(40; City; Option)
        {
            OptionMembers = A,B,C,D;
            DataClassification = ToBeClassified;

        }

        field(50; gender; Option)
        {
            OptionMembers = M,F,Other;
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(key1; "emp code")
        {
            Clustered = true;
        }

        key(sk; City)
        {

        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    trigger OnInsert()
    begin
        Message('Data Inserted');
    end;

    trigger OnModify()
    begin
        Message('Data Modified');
    end;

    trigger OnDelete()
    begin
        Message('Data Deleted');
    end;

    trigger OnRename()
    begin
        Message('Renamed');
    end;

}