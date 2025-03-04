query 50110 "List of Customers"
{
    Caption = 'List of Customers';
    QueryType = Normal;
    QueryCategory = 'Customer List';

    elements
    {
        dataitem(Customer; Customer)
        {
            column(Address; Address)
            {
            }
            column(Balance; Balance)
            {
            }
            column(Amount; Amount)
            {
            }
            column(City; City)
            {
            }
            column(EMail; "E-Mail")
            {
            }
            column(Image; Image)
            {
            }
            column(Name; Name)
            {
            }
            column(PartnerType; "Partner Type")
            {
            }
            column(Comment; Comment)
            {
            }
        }
    }

    trigger OnBeforeOpen()
    begin

    end;
}
