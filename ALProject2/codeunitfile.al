codeunit 50109 MyNewCodeunit
{
    trigger OnRun()
    begin
        num1 := 12;
        num2 := 14;
        add(num1, num2);
    end;

    procedure add(num1: Integer; num2: Integer)
    var
        tot: Integer;
    begin
        tot := num1 + num2;
        Message('Sum of two numbers is %1, %2 is %3', num1, num2, tot);
    end;

    var
        num1: Integer;
        num2: Integer;
}