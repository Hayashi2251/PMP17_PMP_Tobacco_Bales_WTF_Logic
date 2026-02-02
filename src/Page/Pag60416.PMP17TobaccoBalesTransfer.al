page 60416 "PMP17 Tobacco Bales Transfer"
{
    // VERSION PMP17 

    // VERSION
    // Version List       Name
    // ============================================================================================================
    // PMP17              PMP Tobacco Bales Whse TF (Logic)
    // 
    // PAGE
    // Date        Developer  Version List  Trigger                     Description
    // ============================================================================================================
    // 2025/11/21  SW         PMP17                                     Create Page
    // 
    ApplicationArea = All;
    Caption = 'Tobacco Bales Transfer';
    PageType = NavigatePage;
    UsageCategory = Tasks;

    #region LAYOUT
    layout
    {
        area(Content)
        {
            group(Page01)
            {
                Caption = '';
                Visible = CurrentStep = 1;
                ///<summary><b>Text Caption</b> of the Tobacco Bales Transfer Processing Page</summary>
                field(TobaccoBalesTF_TextCaption; TobaccoBalesTF_TextCaption)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    StyleExpr = TextCaption_StyleExprTxt;
                } // TEXT CAPTION

                field(TransferToBinCode; TransferToBinCode)
                {
                    ApplicationArea = All;
                    Caption = 'Transfer to Bin Code';
                    ToolTip = 'Specifies the Bin Code of the transfer destination for the Tobacco Bales Transfer.';
                    ShowMandatory = true;
                    ExtendedDatatype = Barcode;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BinRec: Record Bin;
                    begin
                        ClearBaleNoCode();

                        BinRec.Reset();
                        BinRec.SetRange("Location Code", UserSetupRec."SME073 Working Location");
                        if Page.RunModal(Page::"Bin List", BinRec) = Action::LookupOK then begin
                            TransferToBinCode := BinRec.Code;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        BinRec: Record Bin;
                    begin
                        ClearBaleNoCode();

                        BinRec.Reset();
                        BinRec.SetRange("Location Code", UserSetupRec."SME073 Working Location");
                        BinRec.SetRange(Code, TransferToBinCode);
                        if BinRec.FindFirst() then begin
                            TransferToBinCode := BinRec.Code;
                        end else
                            Error('The scanned bin code (%1) is not available in current working location code of %2.', TransferToBinCode, UserSetupRec."SME073 Working Location");
                    end;
                }
                field(BaleNoText; BaleNoText)
                {
                    ApplicationArea = All;
                    Caption = 'Bale No.';
                    ToolTip = 'Specifies the bale number of the involved entry or record, according to the specified number series.';
                    ShowMandatory = true;
                    ExtendedDatatype = Barcode;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PkgNoInfoRec: Record "Package No. Information";
                    begin
                        if TransferToBinCode = '' then begin
                            Error('Error: Tobacco Bales Transfer cannot be proceed any further before specifying Transfer to Bin Code');
                        end;

                        ResetTextCaptionValues();
                        ResetItemNVariantFields();

                        PkgNoInfoRec.Reset();
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetFilter(Inventory, '> 0');
                        if Page.RunModal(Page::"Package No. Information List", PkgNoInfoRec) = Action::LookupOK then begin
                            BaleNoText := PkgNoInfoRec."Package No.";
                            BaleNoCode := PkgNoInfoRec."Package No.";
                            ItemNoCode := PkgNoInfoRec."Item No.";
                            VariantNoCode := PkgNoInfoRec."Variant Code";
                            PackageNoInfoRec := PkgNoInfoRec;
                            if TobaccoBalesWhseTFMgmt.PostTobaccoBalesTransferItemReclass(ItemJnlLine, PackageNoInfoRec, UserSetupRec, TransferToBinCode) then begin
                                Message('The Reclassification Journal is successfully posted.');
                                NotifyUserSuccessPosting()
                            end else
                                NotifyUserFailedPosting();
                        end;

                        // POST FUNCTION
                    end;

                    trigger OnValidate()
                    var
                        PkgNoInfoRec: Record "Package No. Information";
                        SplittedData: List of [Text];
                        Delimiter: Text;
                    begin
                        if TransferToBinCode = '' then begin
                            Error('Error: Tobacco Bales Transfer cannot be proceed any further before specifying Transfer to Bin Code');
                        end;

                        ResetTextCaptionValues();
                        ResetItemNVariantFields();
                        Delimiter := ExtCompanySetup."PMP14 Barcode Separator";

                        // Check if input matches Delimiter format
                        if StrPos(BaleNoText, Delimiter) > 0 then begin
                            // Split data
                            SplittedData := BaleNoText.Split(Delimiter);

                            if SplittedData.Count() > 1 then begin
                                BaleNoText := SplittedData.Get(3);
                                BaleNoCode := SplittedData.Get(3);
                            end;
                        end else
                            // No separator --> treat as direct Package No.
                            BaleNoCode := BaleNoText;

                        PkgNoInfoRec.Reset();
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                        PkgNoInfoRec.SetAutoCalcFields(Inventory, "PMP04 Bin Code", "PMP04 Lot No.");
                        PkgNoInfoRec.SetRange("Package No.", BaleNoCode);
                        PkgNoInfoRec.SetFilter(Inventory, '>0');
                        if PkgNoInfoRec.FindFirst() then begin
                            BaleNoText := PkgNoInfoRec."Package No.";
                            BaleNoCode := PkgNoInfoRec."Package No.";
                            ItemNoCode := PkgNoInfoRec."Item No.";
                            VariantNoCode := PkgNoInfoRec."Variant Code";
                            PackageNoInfoRec := PkgNoInfoRec;
                            if TobaccoBalesWhseTFMgmt.PostTobaccoBalesTransferItemReclass(ItemJnlLine, PackageNoInfoRec, UserSetupRec, TransferToBinCode) then begin
                                Clear(TransferToBinCode);
                                ClearBaleNoCode();
                                Message('The Reclassification Journal is successfully posted.');
                                NotifyUserSuccessPosting()
                            end else
                                NotifyUserFailedPosting();
                        end else
                            exit; // Silent exit, no messages
                                  // end;
                    end;
                }
                field(ItemNoCode; ItemNoCode)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    TableRelation = Item."No.";
                }
                field(VariantNoCode; VariantNoCode)
                {
                    ApplicationArea = All;
                    Caption = 'Variant No.';
                    Editable = false;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
            }
            // group(Page02)
            // {
            //     Caption = '';
            //     Visible = CurrentStep = 2;

            //     // 
            // }
        }
    }
    #endregion LAYOUT

    #region ACTIONS
    actions
    {
        area(navigation)
        {
            action(ChangeWorkingLocationCode)
            {
                ApplicationArea = All;
                Caption = 'Change Location';
                Enabled = CurrentStep = 1;
                Visible = CurrentStep = 1;
                InFooterBar = true;
                Image = PreviousRecord;
                trigger OnAction()
                begin
                    ChangeLocationCodeRep.SetUserID(UserSetupRec."User ID");
                    if UserSetupRec."SME073 Working Location" <> '' then begin
                        ChangeLocationCodeRep.SetLocationCode(UserSetupRec."SME073 Working Location");
                    end;
                    ChangeLocationCodeRep.Run();

                    UserSetupRec.Get(UserId);
                    Clear(TransferToBinCode);
                end;
            }
            action(Cancel)
            {
                ApplicationArea = All;
                Caption = 'Cancel';
                Enabled = true;
                InFooterBar = true;
                Image = Reject;
                trigger OnAction()
                begin
                    // ResetControls();
                    Clear(TransferToBinCode);
                    ClearBaleNoCode();
                    CurrPage.Close();
                end;
            }
        }
    }
    #endregion ACTIONS

    var
        ChangeLocationCodeRep: Report "PMP17 Change Working Loc. Code";
        TobaccoBalesWhseTFMgmt: Codeunit "PMP17 Tobacco Bales Whse. Tf.";
        Bin: Record Bin;
        UserSetupRec: Record "User Setup";
        PackageNoInfoRec: Record "Package No. Information";
        ItemJnlLine: Record "Item Journal Line";
        TextCaption_StyleExprTxt, BaleNoText : Text;

    protected var
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        CurrentStep: Integer;
        TransferToBinCode, BaleNoCode : Code[50];
        ItemNoCode: Code[20];
        VariantNoCode: Code[10];
        TobaccoBalesTF_TextCaption: Text;

    trigger OnInit()
    begin
        ExtCompanySetup.Get();
        ResetTextCaptionValues();
        Clear(TransferToBinCode);
        Clear(BaleNoCode);
        Clear(BaleNoText);
        ResetItemNVariantFields();
        UserSetupRec.Get(UserId);
        CurrentStep := 1;
    end;

    local procedure ResetItemNVariantFields()
    begin
        Clear(ItemNoCode);
        Clear(VariantNoCode);
    end;

    local procedure ResetTextCaptionValues()
    begin
        Clear(TobaccoBalesTF_TextCaption);
        Clear(TextCaption_StyleExprTxt);
    end;

    local procedure ClearBaleNoCode()
    begin
        Clear(BaleNoText);
        Clear(BaleNoCode);
        ResetItemNVariantFields();
        ResetTextCaptionValues();
    end;

    local procedure NotifyUserSuccessPosting()
    begin
        TobaccoBalesTF_TextCaption := 'Posting is DONE!';
        TextCaption_StyleExprTxt := 'favorable';
    end;

    local procedure NotifyUserFailedPosting()
    begin
        TobaccoBalesTF_TextCaption := 'Posting is FAILED!';
        TextCaption_StyleExprTxt := 'unfavorable';
    end;
}
