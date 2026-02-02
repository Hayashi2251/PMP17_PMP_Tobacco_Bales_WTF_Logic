pageextension 60411 "PMP17 Ext. Company Setup Ext" extends "PMP07 Extended Company Setup"
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
    // 2025/12/08  SW         PMP17         -                           Create Page Extension
    // 

    #region Layout
    layout
    {
        addlast(Warehouse)
        {
            field("PMP17 Int. Tf. Jnl. Tmpt. Name"; Rec."PMP17 Int. Tf. Jnl. Tmpt. Name")
            {
                ApplicationArea = All;
                Caption = 'Internal Transfer Journal Template Name';
                ToolTip = 'Determines the Item Journal Template Name used for internal transfer transactions in this add-on. If the template does not yet exist, the system will create it automatically.';
                trigger OnValidate()
                begin
                    CheckItemJnlBatchforDocumentNos(Rec."PMP17 Int. Tf. Jnl. Tmpt. Name", Rec."PMP17 Int. Tf. Jnl. Batch Name");
                end;
            }
            field("PMP17 Int. Tf. Jnl. Batch Name"; Rec."PMP17 Int. Tf. Jnl. Batch Name")
            {
                ApplicationArea = All;
                Caption = 'Internal Transfer Journal Batch Name';
                ToolTip = 'Determines the Item Journal Batch Name used for internal transfer transactions in this add-on. If the batch does not yet exist, the system will create it automatically. Ensure a No. Series is assigned to auto-generate item reclassification document numbers.';
                trigger OnValidate()
                begin
                    CheckItemJnlBatchforDocumentNos(Rec."PMP17 Int. Tf. Jnl. Tmpt. Name", Rec."PMP17 Int. Tf. Jnl. Batch Name");
                end;
            }
            field("PMP17 Int. Document Tf. Nos."; Rec."PMP17 Int. Document Tf. Nos.")
            {
                ApplicationArea = All;
                Caption = 'Internal Transfer Document No. Series';
                ToolTip = 'Specifies the No. Series used to auto-generate document numbers for internal transfer transactions. If no No. Series is specified, the generated item reclassification journal may causing error in the future.';
            }
            field("PMP17 Tobacco Tf. Reason Code"; Rec."PMP17 Tobacco Tf. Reason Code")
            {
                ApplicationArea = All;
                Caption = 'Tobacco Transfer Reason Code';
                ToolTip = 'Specifies the default internal transfer Reason Code used in this modification.';
            }
            field("PMP17 Tbco Regrade Reason Code"; Rec."PMP17 Tbco Regrade Reason Code")
            {
                ApplicationArea = All;
                Caption = 'Tobacco Re-Grading Reason Code';
                ToolTip = 'Specifies the default Reason Code used for tobacco re-grading transactions.';
            }
            field("PMP17 Tbco Regrade Nos."; Rec."PMP17 Tbco Regrade Nos.")
            {
                ApplicationArea = All;
                Caption = 'Tobacco Re-Grading No Series';
                ToolTip = 'Specifies the default No. Series used when creating assembly orders for tobacco re-grading transactions.';
            }
            field("PMP17 Posted Tbco Regrade Nos."; Rec."PMP17 Posted Tbco Regrade Nos.")
            {
                ApplicationArea = All;
                Caption = 'Posted Tobacco Re-Grading No Series';
                ToolTip = 'Specifies the No. Series used for posted assembly order document numbers in tobacco re-grading transactions.';
            }
        }
    }
    #endregion Layout

    #region Actions
    actions { }
    #endregion Actions

    var
        ItemJnlBatch: Record "Item Journal Batch";

    local procedure CheckItemJnlBatchforDocumentNos(TemplateCode: Code[10]; BatchName: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
        Notif: Notification;
    begin
        if ItemJnlBatch.Get(Rec."PMP17 Int. Tf. Jnl. Tmpt. Name", Rec."PMP17 Int. Tf. Jnl. Batch Name") then begin
            if ItemJnlBatch."No. Series" = '' then begin
                Notif.Message := 'The Item Journal Batch %1 does not have a No. Series assigned. Please assign a No. Series or set the "Internal Document Transfer Nos." to auto-generate document numbers for internal transfer transactions.';
                Notif.Scope := NotificationScope::LocalScope;
                Notif.AddAction('Lihat Detail', Codeunit::"PMP17 Tobacco Bales Whse. Tf.",
        'NotifAction_ExtCompanySetupOpenItemJnlBatchTransfer');
                Notif.Send();
            end;
        end;
    end;
}
