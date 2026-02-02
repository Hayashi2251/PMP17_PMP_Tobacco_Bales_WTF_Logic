pageextension 60410 "PMP17 User Setup Ext" extends "User Setup"
{
    // VERSION PMP17 

    // VERSION
    // Version List       Name
    // ============================================================================================================
    // PMP17              PMP Tobacco Bales Whse TF (Logic)
    // 
    // PAGE EXTENSION
    // Date        Developer  Version List  Trigger                     Description
    // ============================================================================================================
    // 2025/11/20  SW         PMP17         -                           Create Page Extension
    // 

    #region Layout
    layout
    {
        addlast(Control1)
        {
            // LA TEMPORAIRE
            field("SME073 Working Location"; Rec."SME073 Working Location")
            {
                ApplicationArea = All;
                Caption = 'Working Location';
                ToolTip = 'Specifies and stores the user''s last working location code.';
                Editable = false;
            }
        }
    }
    #endregion Layout

    #region Actions
    actions
    {
        addlast(Processing)
        {
            action("Change Working Location Code")
            {
                ApplicationArea = All;
                Caption = 'Change Location';
                Image = ChangeLog;
                trigger OnAction()
                var
                    ChangeLocationRep: Report "PMP17 Change Working Loc. Code";
                begin
                    ChangeLocationRep.SetUserID(Rec."User ID");
                    if Rec."SME073 Working Location" <> '' then begin
                        ChangeLocationRep.SetLocationCode(Rec."SME073 Working Location"); // As default
                    end;
                    ChangeLocationRep.Run();
                end;
            }
        }
    }
    #endregion Actions
}
