pageextension 60410 "PMP17 Package No Info List Ext" extends "Package No. Information List"
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
        addlast(Control1)
        {
            field("PMP17 Measured Weight (Kgs)"; Rec."PMP17 Measured Weight (Kgs)")
            {
                ApplicationArea = All;
                Caption = 'Measure Weight (Kgs)';
                ToolTip = 'Specifies the value of the Measured Weight (Kgs) field, read from weighing device for a box number.';
            }
        }
    }
    #endregion Layout

    #region Actions
    actions { }
    #endregion Actions
}
