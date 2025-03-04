page 50103 MyCustomerApiPage
{
    PageType = API;
    APIPublisher = 'MyCompany';
    APIGroup = 'custom';
    APIVersion = 'v2.0';
    EntityName = 'customCustomer';
    EntitySetName = 'customCustomers';
    SourceTable = Customer;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(CustomerName; Rec.Name) { }
                field(SearchName; Rec.SearchName) { }
                field(MyField; Rec.MyField) { }
            }
        }
    }
}