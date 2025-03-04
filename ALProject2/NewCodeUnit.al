codeunit 50113 TutorialAPI
{
    [ServiceEnabled]
    procedure Hello(): Text
    begin
        exit('Hello World!');
    end;
}