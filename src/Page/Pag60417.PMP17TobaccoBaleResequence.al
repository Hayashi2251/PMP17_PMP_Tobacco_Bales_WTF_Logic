page 60417 "PMP17 Tobacco Bale Resequence"
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
    // 2025/11/22  SW         PMP17                                     Create Page
    // 

    ApplicationArea = All;
    Caption = 'Tobacco Bale Resequence';
    PageType = NavigatePage;
    UsageCategory = Tasks;

    #region LAYOUT  
    layout
    {
        area(Content)
        {
            // ==============================================
            // GROUP: PAGE1
            // DESCRIPTION: FIRST STAGE 
            // ==============================================
            group(Page01)
            {
                Caption = '';
                Visible = CurrentStep = 1;

                field(BinCode; BinCode)
                {
                    ApplicationArea = All;
                    Caption = 'Bin Code';
                    ToolTip = '';
                    ShowMandatory = true;
                    ExtendedDatatype = Barcode;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BinRec: Record Bin;
                    begin
                        ClearBaleNoCode();

                        BinRec.Reset();
                        BinRec.SetRange("Location Code", UserSetupRec."PMP17 Working Location Code");
                        if Page.RunModal(Page::"Bin List", BinRec) = Action::LookupOK then begin
                            BinCode := BinRec.Code;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        BinRec: Record Bin;
                    begin
                        ClearBaleNoCode();
                        ItemJnlLine.Reset();
                        PackageNoInfoRec.Reset();

                        BinRec.Reset();
                        BinRec.SetRange("Location Code", UserSetupRec."PMP17 Working Location Code");
                        BinRec.SetRange(Code, BinCode);
                        if BinRec.FindFirst() then begin
                            BinCode := BinRec.Code;
                        end else
                            Error('The scanned bin code (%1) is not available in current working location code of %2.', BinCode, UserSetupRec."PMP17 Working Location Code");
                    end;
                }
            }
            // ==============================================
            // GROUP: PAGE2
            // DESCRIPTION: CURRENTLY LAST STAGE |  SECOND PAGE
            // ==============================================
            group(Page02)
            {
                Caption = '';
                Visible = CurrentStep = 2;

                ///<summary><b>Text Caption</b> of the Tobacco Bales Resequencing Processing Page</summary>
                field(TobaccoBalesTF_TextCaption; TobaccoBalesTF_TextCaption)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    StyleExpr = 'strong';
                } // TEXT CAPTION
                field(BaleNoText; BaleNoText)
                {
                    ApplicationArea = All;
                    Caption = 'Bale No.';
                    ToolTip = '';
                    ExtendedDatatype = Barcode;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PkgNoInfoRec: Record "Package No. Information";
                    begin
                        PkgNoInfoRec.Reset();
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetFilter(Inventory, '> 0');
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."PMP17 Working Location Code");
                        if Page.RunModal(Page::"Package No. Information List", PkgNoInfoRec) = Action::LookupOK then begin
                            BaleNoText := PkgNoInfoRec."Package No.";
                            BaleNoCode := PkgNoInfoRec."Package No.";
                            PackageNoInfoRec := PkgNoInfoRec;
                            // Add the Package No Info to the Tobacco Bales Resequence Listpart
                            CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."PMP17 Working Location Code", BinCode);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        PkgNoInfoRec: Record "Package No. Information";
                        SplittedData: List of [Text];
                        Delimiter: Text;
                    begin
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
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetRange("Package No.", BaleNoCode);
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."PMP17 Working Location Code");
                        PkgNoInfoRec.SetFilter(Inventory, '>0');
                        if PkgNoInfoRec.FindFirst() then begin
                            BaleNoText := PkgNoInfoRec."Package No.";
                            BaleNoCode := PkgNoInfoRec."Package No.";
                            PackageNoInfoRec := PkgNoInfoRec;

                            // Add the Package No Info to the Tobacco Bales Resequence Listpart
                            CurrPage.PkgNo__List.Page.InsertRecord(PkgNoInfoRec, UserSetupRec."PMP17 Working Location Code", BinCode);
                        end else
                            exit; // Silent exit, no messages
                    end;
                }
                part(PkgNo__List; "PMP17 Tbco. Bales Reseq. Sub.")
                {
                    ApplicationArea = All;
                    UpdatePropagation = Both;
                }
            }
        }
    }
    #endregion LAYOUT

    #region ACTIONS
    actions
    {
        area(navigation)
        {
            action(Back)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = CurrentStep > 1;
                Visible = CurrentStep > 1;
                InFooterBar = true;
                Image = PreviousRecord;
                trigger OnAction()
                begin
                    CurrentStep -= 1;
                    if CurrentStep = 2 then begin
                        ClearBaleNoCode();
                        ItemJnlLine.Reset();
                    end;
                end;
            }
            action(Next)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = CurrentStep < MaxNavigatePage;
                Visible = CurrentStep < MaxNavigatePage;
                InFooterBar = true;
                Image = NextRecord;
                trigger OnAction()
                begin
                    if CurrentStep = 1 then begin
                        if BinCode = '' then begin
                            Error('Please fill the current Bin Code to resequence, this field should not be empty');
                        end;
                        TobaccoBalesTF_TextCaption := StrSubstNo('Tobacco Bale Resequence | %1', BinCode);
                    end;

                    CurrentStep += 1;
                end;
            }
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
                    if UserSetupRec."PMP17 Working Location Code" <> '' then begin
                        ChangeLocationCodeRep.SetLocationCode(UserSetupRec."PMP17 Working Location Code");
                    end;
                    ChangeLocationCodeRep.Run();

                    UserSetupRec.Get(UserId);
                    Clear(BinCode);
                end;
            }
            action(Rescan)
            {
                ApplicationArea = All;
                Caption = 'Rescan';
                Enabled = CurrentStep = MaxNavigatePage;
                Visible = CurrentStep = MaxNavigatePage;
                Ellipsis = true;
                InFooterBar = true;
                Image = Camera;
                trigger OnAction()
                begin
                    ClearBaleNoCode();
                    if Confirm('Do you want to rescan again? If Yes, then all the data in the table will be deleted.', false) then begin
                        ClearNewBalePosition();
                        CurrPage.PkgNo__List.Page.DeleteAllRecord();
                        ItemJnlLine.Reset();
                    end;
                    CurrPage.Update();
                end;
            }
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Enabled = CurrentStep = MaxNavigatePage;
                Visible = CurrentStep = MaxNavigatePage;
                InFooterBar = true;
                Image = Approve;
                trigger OnAction()
                var
                    CountLastIRJ: Integer;
                    PkgNoInfoRec: Record "Package No. Information";
                begin
                    CurrPage.PkgNo__List.Page.GetPackageNoInfo_TobaccoBalesResequenceSubform(LinesPackageNoInfoRec);
                    if LinesPackageNoInfoRec.Count > 0 then begin
                        if LinesPackageNoInfoRec.FindSet() then
                            repeat
                                PkgNoInfoRec.Reset();
                                if LinesPackageNoInfoRec."PMP04 Bin Code" <> BinCode then begin
                                    LinesPackageNoInfoRec.CalcFields(Inventory);
                                    LinesPackageNoInfoRec.CalcFields("PMP04 Bin Code");
                                    LinesPackageNoInfoRec.CalcFields("PMP04 Lot No.");
                                    TobaccoBalesWhseTFMgmt.PostTobaccoBalesTransferItemReclass(ItemJnlLine, LinesPackageNoInfoRec, UserSetupRec, BinCode);
                                end;
                                PkgNoInfoRec.SetRange("Item No.", LinesPackageNoInfoRec."Item No.");
                                PkgNoInfoRec.SetRange("Variant Code", LinesPackageNoInfoRec."Variant Code");
                                PkgNoInfoRec.SetRange("Package No.", LinesPackageNoInfoRec."Package No.");
                                if PkgNoInfoRec.FindFirst() then begin
                                    PkgNoInfoRec."PMP04 Bale Position" := LinesPackageNoInfoRec."PMP04 Bale Position";
                                    PkgNoInfoRec.Modify();
                                end;
                            until LinesPackageNoInfoRec.Next() = 0;

                        CurrPage.Update();
                    end;
                    ClearNewBalePosition();
                    ClearBaleNoCode();
                    CurrPage.PkgNo__List.Page.DeleteAllRecord();
                    Message('Resequencing process is done.');
                end;
            }
            // action(Cancel)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Cancel';
            //     Enabled = true;
            //     InFooterBar = true;
            //     Image = Reject;
            //     trigger OnAction()
            //     begin
            //         ResetControls();
            //         Clear(UserSetupRec);
            //         Clear(TobaccoBalesWhseTFMgmt);
            //         CurrPage.Close();
            //     end;
            // }
        }
    }
    #endregion ACTIONS

    var
        ChangeLocationCodeRep: Report "PMP17 Change Working Loc. Code";
        TobaccoBalesWhseTFMgmt: Codeunit "PMP17 Tobacco Bales Whse. Tf.";
        UserSetupRec: Record "User Setup";
        PackageNoInfoRec: Record "Package No. Information";
        LinesPackageNoInfoRec: Record "Package No. Information" temporary;
        ItemJnlLine: Record "Item Journal Line";
        BaleNoText: Text;

    protected var
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        CurrentStep: Integer;
        BinCode: Code[20];
        BaleNoCode: Code[50];
        TobaccoBalesTF_TextCaption: Text;
        MaxNavigatePage, NewBalePosition : Integer;

    trigger OnInit()
    begin
        ExtCompanySetup.Get();
        LinesPackageNoInfoRec.DeleteAll();
        ResetControls();
        ClearNewBalePosition();
        UserSetupRec.Get(UserId);
        CurrentStep := 1;
        MaxNavigatePage := 2;
    end;

    local procedure ResetControls()
    begin
        Clear(CurrentStep);
        Clear(BinCode);
        ClearBaleNoCode();
        // Clear all the listpart Data
    end;

    local procedure ClearBaleNoCode()
    begin
        Clear(BaleNoText);
        Clear(BaleNoCode);
    end;

    local procedure ClearNewBalePosition()
    begin
        Clear(NewBalePosition);
        CurrPage.PkgNo__List.Page.SetNewBalePosition(1);
    end;
}
