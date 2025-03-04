// tableextension 50100 CustomerExtension extends Customer
// {
//     fields
//     {
//         field(50100; MyField; Text[100])
//         {
//             DataClassification = ToBeClassified;
//         }
//     }
// }

// pageextension 50101 CustomerCardExt extends "Customer Card"
// {
//     layout
//     {
//         addlast(Content)
//         {
//             field(MyField; Rec.MyField)
//             {
//                 ApplicationArea = All;
//             }
//         }
//     }

// }

tableextension 50100 CustomerExtension extends Customer
{
    fields
    {
        field(50100; MyField; Text[100])
        {
            DataClassification = ToBeClassified;
        }

        field(50101; SearchName; Text[100])
        {
            DataClassification = ToBeClassified;
        }
    }
}

