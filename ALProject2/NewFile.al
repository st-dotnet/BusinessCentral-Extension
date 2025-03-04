pageextension 50100 ExtendWorkflowCustomers extends 6408 // Page 6408
{
    layout
    {
        addlast(Content)
        {
            field(MyCustomField; Rec.MyField)
            {
                ApplicationArea = All;
                //Caption = 'My Custom Field';
            }
        }
    }
}
