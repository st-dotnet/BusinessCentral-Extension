page 50102 "Test Page"
{
    PageType = List;
    SourceTable = 50102;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Field1; Rec."emp name") { }
                field(Field2; Rec."salary") { }
                field(Field3; Rec."DOJ") { }
            }
        }
    }
}