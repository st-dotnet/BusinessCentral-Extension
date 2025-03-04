page 50109 addtwo
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;

    // layout
    // {
    //     area(Content)
    //     {
    //         group(GroupName)
    //         {
    //             field(Name; NameSource)
    //             {

    //             }
    //         }
    //     }
    // }

    actions
    {
        area(Processing)
        {
            action(Addition)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Mycode.Run();
                end;
            }
        }
    }

    var
        Mycode: CodeUnit MyNewCodeunit;
}