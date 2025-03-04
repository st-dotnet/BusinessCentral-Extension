page 50115 "Employee Page"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = Employe;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(empcode; Rec."emp code")
                {
                    ApplicationArea = All;
                }
                field("emp name"; Rec."emp name")
                {
                    ApplicationArea = All;
                }
                field(salary; Rec.salary)
                {
                    ApplicationArea = All;
                }

            }

            group(Other)
            {
                field(DOJ; Rec.DOJ)
                {
                    ApplicationArea = All;
                }

                field(city; Rec.City)
                {
                    ApplicationArea = All;
                }

                field(gender; Rec.gender)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin
                    Message('Data Saved in the Table');
                end;
            }
        }
    }

    var
        myInt: Integer;
}