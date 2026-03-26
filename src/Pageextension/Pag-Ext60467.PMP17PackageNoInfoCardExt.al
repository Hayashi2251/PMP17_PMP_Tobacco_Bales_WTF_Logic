pageextension 60467 "PMP17 Package No Info Card Ext" extends "Package No. Information Card"
{
    // VERSION PMP17 

    // VERSION
    // Version List       Name
    // ============================================================================================================
    // PMP17              -
    // 
    // PAGE EXTENSION
    // Date        Developer  Version List  Trigger                     Description
    // ============================================================================================================
    // 2026/03/15  SW         PMP17         -                           Create Page Extension
    // 

    #region Layout
    layout
    {
        addbefore(Standard)
        {
            field("PMP17 Measured Weight (Kgs)"; Rec."PMP17 Measured Weight (Kgs)")
            {
                ApplicationArea = All;
                Caption = 'Measured Weight (Kgs)';
                ToolTip = 'Specifies the value of the Measured Weight (Kgs) field, read from weighing device for a box number.';
            }
        }
        addafter("PMP07 Bale Position")
        {
            field("PMP17 New Bale Position"; Rec."PMP17 New Bale Position")
            {
                ApplicationArea = All;
                Caption = 'New Bale Position';
                ToolTip = 'Specifies the value of the New Bale Position field.';
                Importance = Additional;
            }
        }
    }
    #endregion Layout

    #region Actions
    actions { }
    #endregion Actions
}
