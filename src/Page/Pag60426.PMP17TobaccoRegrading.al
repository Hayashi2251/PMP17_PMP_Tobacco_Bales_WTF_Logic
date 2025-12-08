page 60426 "PMP17 Tobacco Regrading"
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
    // 2025/11/23  SW         PMP17         -                           Create Page
    // 

    ApplicationArea = All;
    Caption = 'Tobacco Regrading';
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

                field(ItemNoCode; ItemNoCode)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = '';
                    ShowMandatory = true;
                    ExtendedDatatype = Barcode;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemRec: Record Item;
                    begin
                        ClearBaleNoCode();
                        Clear(ItemDescriptionText);
                        ClearSelectedItemToRegrading();

                        ItemRec.Reset();
                        if Page.RunModal(Page::"Item List", ItemRec) = Action::LookupOK then begin
                            ItemNoCode := ItemRec."No.";
                            ItemDescriptionText := ItemRec.Description;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        ItemRec: Record Item;
                    begin
                        ClearBaleNoCode();
                        Clear(ItemDescriptionText);
                        ClearSelectedItemToRegrading();

                        ItemRec.Reset();
                        ItemRec.SetRange("No.", ItemNoCode);
                        if ItemRec.FindFirst() then begin
                            ItemNoCode := ItemRec."No.";
                            ItemDescriptionText := ItemRec.Description;
                        end;
                    end;
                }
                field(ItemDescriptionText; ItemDescriptionText)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = '';
                    Editable = false;
                }
                field(NewTobaccoStandardCode; NewTobaccoStandardCode)
                {
                    ApplicationArea = All;
                    Caption = 'New Tobacco Standard';
                    ToolTip = '';
                    ShowMandatory = true;
                    ExtendedDatatype = Barcode;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariantRec: Record "Item Variant";
                    begin
                        ClearBaleNoCode();

                        ItemVariantRec.Reset();
                        ItemVariantRec.SetRange("Item No.", ItemNoCode);
                        if Page.RunModal(Page::"Item Variants", ItemVariantRec) = Action::LookupOK then begin
                            NewTobaccoStandardCode := ItemVariantRec.Code;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        ItemVariantRec: Record "Item Variant";
                    begin
                        ClearBaleNoCode();

                        ItemVariantRec.Reset();
                        ItemVariantRec.SetRange("Item No.", ItemNoCode);
                        if ItemVariantRec.FindFirst() then begin
                            NewTobaccoStandardCode := ItemVariantRec.Code;
                        end;
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
                    ShowMandatory = true;
                    ExtendedDatatype = Barcode;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PkgNoInfoListPage: Page "Package No. Information List";
                        PkgNoInfoRec: Record "Package No. Information";
                        SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        RecRef: RecordRef;
                    begin
                        ClearBaleNoCode();
                        PkgNoInfoRec.Reset();
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetRange("Item No.", ItemNoCode);
                        PkgNoInfoRec.SetFilter(Inventory, '> 0');
                        PkgNoInfoListPage.SetTableView(PkgNoInfoRec);
                        PkgNoInfoListPage.LookupMode(true);
                        if PkgNoInfoListPage.RunModal = ACTION::LookupOK then begin
                            PkgNoInfoListPage.SetSelectionFilter(PkgNoInfoRec);
                            RecRef.GetTable(PkgNoInfoRec);
                            BaleNoText := SelectionFilterManagement.GetSelectionFilter(RecRef, PkgNoInfoRec.FieldNo("Package No."));

                            PkgNoInfoRec.SetFilter("Package No.", BaleNoText);
                            if PkgNoInfoRec.FindSet() then
                                repeat
                                    BaleNoText := PkgNoInfoRec."Package No.";
                                    BaleNoCode := PkgNoInfoRec."Package No.";
                                    PackageNoInfoRec := PkgNoInfoRec;
                                    // Add the Package No Info to the Tobacco Bales Resequence Listpart
                                    AddSummaryBaleListPartofPackageNoInfo(PkgNoInfoRec);
                                    CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."PMP17 Working Location Code", PackageNoInfoRec."PMP04 Bin Code");
                                until PkgNoInfoRec.Next() = 0;
                        end;
                    end;
                    // trigger OnLookup(var Text: Text): Boolean
                    // var
                    //     PkgNoInfoRec: Record "Package No. Information";
                    // begin
                    //     PkgNoInfoRec.Reset();
                    //     PkgNoInfoRec.SetAutoCalcFields(Inventory);
                    //     PkgNoInfoRec.SetRange("Item No.", ItemNoCode);
                    //     PkgNoInfoRec.SetFilter(Inventory, '> 0');
                    //     PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."PMP17 Working Location Code");
                    //     if Page.RunModal(Page::"Package No. Information List", PkgNoInfoRec) = Action::LookupOK then begin
                    //         BaleNoText := PkgNoInfoRec."Package No.";
                    //         BaleNoCode := PkgNoInfoRec."Package No.";
                    //         PackageNoInfoRec := PkgNoInfoRec;
                    //         // Add the Package No Info to the Tobacco Bales Resequence Listpart
                    //         AddSummaryBaleListPartofPackageNoInfo(PkgNoInfoRec);
                    //         CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."PMP17 Working Location Code", PackageNoInfoRec."PMP04 Bin Code");
                    //     end;
                    // end;

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
                        PkgNoInfoRec.SetRange("Item No.", ItemNoCode);
                        PkgNoInfoRec.SetRange("Package No.", BaleNoCode);
                        PkgNoInfoRec.SetFilter(Inventory, '> 0');
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."PMP17 Working Location Code");
                        if Page.RunModal(Page::"Package No. Information List", PkgNoInfoRec) = Action::LookupOK then begin
                            BaleNoText := PkgNoInfoRec."Package No.";
                            BaleNoCode := PkgNoInfoRec."Package No.";
                            PackageNoInfoRec := PkgNoInfoRec;
                            // Add the Package No Info to the Tobacco Bales Resequence Listpart
                            AddSummaryBaleListPartofPackageNoInfo(PkgNoInfoRec);
                            CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."PMP17 Working Location Code", PackageNoInfoRec."PMP04 Bin Code");
                        end else
                            exit; // Silent exit, no messages
                    end;
                }
                field(TotalBalesPositionInt; TotalBalesPositionInt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    // StyleExpr = 'strong';
                } // TOTAL BALE POSITION
                field(TotalBalesQtyDec; TotalBalesQtyDec)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    // StyleExpr = 'strong';
                } // TOTAL BALE QUANTITY IN DECIMAL

                part(PkgNo__List; "PMP17 Tbco. Bales Reseq. Sub.")
                {
                    ApplicationArea = All;
                    Caption = 'Tobacco Regrading Lines';
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
                        AssemblyHeaderRec.Reset();
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
                        if ItemNoCode = '' then begin
                            Error('Please fill the current Item No. to regrading, this field should not be empty');
                        end;
                        if NewTobaccoStandardCode = '' then begin
                            Error('Please fill the current New Tobacco Standard to regrading, this field is essential and should not be empty');
                        end;
                        TobaccoBalesTF_TextCaption := StrSubstNo('Tobacco Re-Grading | %1 | %2', ItemNoCode, NewTobaccoStandardCode);
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
                    CurrPage.PkgNo__List.Page.DeleteAllRecord();
                    ResetControls();
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
                        ClearQtyResume();
                        ClearNewBalePosition();
                        CurrPage.PkgNo__List.Page.DeleteAllRecord();
                        AssemblyHeaderRec.Reset();
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
                    // CurrPage.PkgNo__List.Page.GetPackageNoInfo_TobaccoBalesResequenceSubform(LinesPackageNoInfoRec);
                    if (CurrPage.PkgNo__List.Page.CountAllExistingRec() > 0) then
                        repeat
                            LinesPackageNoInfoRec.DeleteAll();
                            CurrPage.PkgNo__List.Page.GetFirstRec(LinesPackageNoInfoRec);
                            LinesPackageNoInfoRec.CalcFields(Inventory);
                            LinesPackageNoInfoRec.CalcFields("PMP04 Bin Code");
                            LinesPackageNoInfoRec.CalcFields("PMP04 Lot No.");
                            TobaccoBalesWhseTFMgmt.PostTobaccoBalesRegrading(AssemblyHeaderRec, LinesPackageNoInfoRec, UserSetupRec, ItemNoCode, NewTobaccoStandardCode);
                            CurrPage.PkgNo__List.Page.DeleteFirstRec();
                        until CurrPage.PkgNo__List.Page.CountAllExistingRec() = 0;

                    CurrPage.Update();
                    Clear(TobaccoBalesWhseTFMgmt);
                    AssemblyHeaderRec.Reset();
                    PackageNoInfoRec.Reset();
                    LinesPackageNoInfoRec.DeleteAll();
                    // Clear(ItemNoCode);
                    ClearSelectedItemToRegrading();
                    ClearBaleNoCode();
                    Clear(TobaccoBalesTF_TextCaption);
                    ClearNewBalePosition();
                    Message('Tobacco Regrading process is done.');
                end;
            }
        }
    }
    #endregion ACTIONS

    var
        ChangeLocationCodeRep: Report "PMP17 Change Working Loc. Code";
        TobaccoBalesWhseTFMgmt: Codeunit "PMP17 Tobacco Bales Whse. Tf.";
        UserSetupRec: Record "User Setup";
        PackageNoInfoRec: Record "Package No. Information";
        LinesPackageNoInfoRec: Record "Package No. Information" temporary;
        AssemblyHeaderRec: Record "Assembly Header";
        BaleNoText, ItemDescriptionText : Text;

    protected var
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        CurrentStep: Integer;
        ItemNoCode: Code[20];
        NewTobaccoStandardCode: Code[10];
        BaleNoCode: Code[50];
        TobaccoBalesTF_TextCaption: Text;
        MaxNavigatePage, NewBalePosition, TotalBalesPositionInt : Integer;
        TotalBalesQtyDec: Decimal;

    trigger OnInit()
    begin
        ExtCompanySetup.Get();
        LinesPackageNoInfoRec.DeleteAll();
        UserSetupRec.Get(UserId);
        CurrentStep := 1;
        MaxNavigatePage := 2;

        ResetControls();
    end;

    local procedure ResetControls()
    begin
        CurrentStep := 1;
        Clear(TobaccoBalesWhseTFMgmt);
        AssemblyHeaderRec.Reset();
        PackageNoInfoRec.Reset();
        LinesPackageNoInfoRec.DeleteAll();
        Clear(ItemNoCode);
        ClearSelectedItemToRegrading();
        ClearBaleNoCode();
        Clear(TobaccoBalesTF_TextCaption);
        ClearNewBalePosition();
    end;

    local procedure ClearBaleNoCode()
    begin
        Clear(BaleNoText);
        Clear(BaleNoCode);
    end;

    local procedure ClearNewBalePosition()
    begin
        Clear(NewBalePosition);
        ClearQtyResume();
        CurrPage.PkgNo__List.Page.SetNewBalePosition(1);
    end;

    local procedure ClearQtyResume()
    begin
        Clear(TotalBalesPositionInt);
        Clear(TotalBalesQtyDec);
    end;

    local procedure ClearSelectedItemToRegrading()
    begin
        Clear(ItemDescriptionText);
        Clear(NewTobaccoStandardCode);
    end;

    local procedure AddSummaryBaleListPartofPackageNoInfo(PkgNoInfoRec: Record "Package No. Information")
    begin
        PkgNoInfoRec.CalcFields(Inventory);
        TotalBalesPositionInt += 1;
        TotalBalesQtyDec += PkgNoInfoRec.Inventory;
    end;
}
