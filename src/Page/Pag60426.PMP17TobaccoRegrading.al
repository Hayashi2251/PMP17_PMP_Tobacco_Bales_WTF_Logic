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
    SourceTable = "PMP17 Bale No Regrading Line";
    SourceTableTemporary = true;
    SourceTableView = sorting("Entry No.");

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
                    Caption = 'Item Description';
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
                        ItemVariantRec.SetRange(Code, NewTobaccoStandardCode);
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
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetRange("Item No.", ItemNoCode);
                        PkgNoInfoRec.SetFilter("Variant Code", '<> %1', NewTobaccoStandardCode);
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
                                    // PackageNoInfoRec := PkgNoInfoRec;
                                    // Add the Package No Info to the Tobacco Bales Resequence Listpart
                                    AddRecordPkgNo__List(Rec, PkgNoInfoRec);
                                    AddSummaryBaleListPartofPackageNoInfo(Rec);
                                    CurrPage.Update(false);
                                // CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."SME073 Working Location", PackageNoInfoRec."PMP04 Bin Code");
                                until PkgNoInfoRec.Next() = 0;
                        end;
                    end;
                    #region REMOVED ONLOOKUP V1
                    // trigger OnLookup(var Text: Text): Boolean
                    // var
                    //     PkgNoInfoRec: Record "Package No. Information";
                    // begin
                    //     PkgNoInfoRec.Reset();
                    //     PkgNoInfoRec.SetAutoCalcFields(Inventory);
                    //     PkgNoInfoRec.SetRange("Item No.", ItemNoCode);
                    //     PkgNoInfoRec.SetFilter(Inventory, '> 0');
                    //     PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                    //     if Page.RunModal(Page::"Package No. Information List", PkgNoInfoRec) = Action::LookupOK then begin
                    //         BaleNoText := PkgNoInfoRec."Package No.";
                    //         BaleNoCode := PkgNoInfoRec."Package No.";
                    //         PackageNoInfoRec := PkgNoInfoRec;
                    //         // Add the Package No Info to the Tobacco Bales Resequence Listpart
                    //         AddSummaryBaleListPartofPackageNoInfo(PkgNoInfoRec);
                    //         CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."SME073 Working Location", PackageNoInfoRec."PMP04 Bin Code");
                    //     end;
                    // end;                    
                    #endregion REMOVED ONLOOKUP V1

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
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetRange("Item No.", ItemNoCode);
                        PkgNoInfoRec.SetRange("Package No.", BaleNoCode);
                        PkgNoInfoRec.SetFilter(Inventory, '> 0');
                        if PkgNoInfoRec.FindFirst() then begin
                            BaleNoText := PkgNoInfoRec."Package No.";
                            BaleNoCode := PkgNoInfoRec."Package No.";
                            PackageNoInfoRec := PkgNoInfoRec;
                            // Add the Package No Info to the Tobacco Bales Resequence Listpart
                            AddRecordPkgNo__List(Rec, PkgNoInfoRec);
                            AddSummaryBaleListPartofPackageNoInfo(Rec);
                            CurrPage.Update(false);
                            // CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."SME073 Working Location", PackageNoInfoRec."PMP04 Bin Code");
                        end else
                            exit; // Silent exit, no messages
                    end;
                }
                // field(TotalBalesPositionInt; TotalBalesPositionInt)
                field(TotalBalesPositionInt; TotalBalesPositionInt)
                {
                    ApplicationArea = All;
                    // ShowCaption = false;
                    Caption = 'Total Bales';
                    Editable = false;
                    // StyleExpr = 'strong';
                } // TOTAL BALE POSITION
                // field(TotalBalesQtyDec; TotalBalesQtyDec)
                field(TotalBalesQtyDec; TotalBalesQtyDec)
                {
                    ApplicationArea = All;
                    Caption = 'Total Quantity';
                    // ShowCaption = false;
                    Editable = false;
                    // StyleExpr = 'strong';
                } // TOTAL BALE QUANTITY IN DECIMAL

                // part(PkgNo__List; "PMP17 Tbco. Bales Reseq. Sub.")
                // {
                //     ApplicationArea = All;
                //     Caption = 'Tobacco Regrading Lines';
                //     UpdatePropagation = Both;
                // }
                repeater(PkgNo__List)
                {
                    Caption = 'Detail';
                    Editable = false;
                    field("Package No."; Rec."Package No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Package No. / Bale No.';
                        ToolTip = 'Specifies the customs declaration number.';
                        Editable = false;
                    }
                    field("Item No."; Rec."Item No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Item No.';
                        ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                        Editable = false;
                    }
                    field("Variant Code"; Rec."Variant Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Variant Code';
                        ToolTip = 'Specifies the variant of the item on the line.';
                        Editable = false;
                    }
                    field(Description; Rec."Description")
                    {
                        ApplicationArea = All;
                        Caption = 'Description';
                        ToolTip = 'Specifies the description associated with this line.';
                        Editable = false;
                    }
                    field("PMP04 Sub Merk 1"; Rec."Sub Merk 1")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 1';
                        ToolTip = 'Specifies the submerk 1 associated with this line';
                        Editable = false;
                    }
                    field("PMP04 Sub Merk 2"; Rec."Sub Merk 2")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 2';
                        ToolTip = 'Specifies the submerk 2 associated with this line';
                        Editable = false;
                    }
                    field("PMP04 Sub Merk 3"; Rec."Sub Merk 3")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 3';
                        ToolTip = 'Specifies the submerk 3 associated with this line';
                        Editable = false;
                    }
                    field("PMP04 Sub Merk 4"; Rec."Sub Merk 4")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 4';
                        ToolTip = 'Specifies the submerk 4 associated with this line';
                        Editable = false;
                    }
                    field("PMP04 Sub Merk 5"; Rec."Sub Merk 5")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 5';
                        ToolTip = 'Specifies the submerk 5 associated with this line';
                        Editable = false;
                    }
                    field("PMP04 Lot No."; Rec."Lot No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Lot No.';
                        ToolTip = 'Specifies the lot no. associated with this line';
                        Editable = false;
                    }
                    field("PMP07 Bale Position"; Rec."Old Bale Position")
                    {
                        ApplicationArea = All;
                        Caption = 'Bale Position';
                        ToolTip = 'Specifies the new bale position of the scanned bale number.';
                        Editable = false;
                    }
                    field(CurrentLocationCode; UserSetupRec."SME073 Working Location")
                    {
                        ApplicationArea = All;
                        Caption = 'Current Location Code';
                        ToolTip = 'Specifies the Current Location Code associated with this line';
                        Editable = false;
                    }
                    field("PMP04 Bin Code"; Rec."Bin Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Current Bin Code';
                        ToolTip = 'Specifies the Current Bin Code associated with this line';
                        Editable = false;
                    }
                    // LA TEMPORAIRE
                    field(CurrentBinCode; Rec."Curr. Bin Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Current Bin Code';
                        ToolTip = 'Specifies the Current Bin Code associated with this line';
                        Editable = false;
                    }
                    field(Inventory; Rec.Inventory)
                    {
                        ApplicationArea = All;
                        Caption = 'Inventory';
                        ToolTip = 'Specifies the quantity on inventory with this line.';
                        Editable = false;
                    }
                    field(BaseUoMCode; BaseUoMCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Base Unit of Measure';
                        ToolTip = 'Specifies the value of the Base Unit of Measure field.', Comment = '%';
                        Editable = false;
                    }
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
                    if UserSetupRec."SME073 Working Location" <> '' then begin
                        ChangeLocationCodeRep.SetLocationCode(UserSetupRec."SME073 Working Location");
                    end;
                    ChangeLocationCodeRep.Run();

                    UserSetupRec.Get(UserId);
                    Rec.DeleteAll();
                    // CurrPage.PkgNo__List.Page.DeleteAllRecord();
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
                        Rec.DeleteAll();
                        // CurrPage.PkgNo__List.Page.DeleteAllRecord();
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
                    // if (CurrPage.PkgNo__List.Page.CountAllExistingRec() > 0) then
                    Rec.Reset();
                    if Rec.FindSet() then
                        repeat
                            PkgNoInfoRec.Reset();
                            Rec.CalcFields("Description", "Sub Merk 1", "Sub Merk 2", "Sub Merk 3", "Sub Merk 4", "Sub Merk 5", "Old Bale Position");

                            PkgNoInfoRec.SetRange("Item No.", Rec."Item No.");
                            PkgNoInfoRec.SetRange("Variant Code", Rec."Variant Code");
                            PkgNoInfoRec.SetRange("Package No.", Rec."Package No.");
                            if PkgNoInfoRec.FindFirst() then begin
                                PkgNoInfoRec.CalcFields(Inventory);
                                PkgNoInfoRec.CalcFields("PMP04 Bin Code");
                                PkgNoInfoRec.CalcFields("PMP04 Lot No.");
                                TobaccoBalesWhseTFMgmt.PostTobaccoBalesRegrading(AssemblyHeaderRec, PkgNoInfoRec, UserSetupRec, ItemNoCode, NewTobaccoStandardCode);
                            end;

                        // CurrPage.PkgNo__List.Page.GetFirstRec(Rec);
                        // CurrPage.PkgNo__List.Page.DeleteFirstRec();
                        until Rec.Next() = 0;

                    CurrPage.Update(false);
                    Clear(TobaccoBalesWhseTFMgmt);
                    AssemblyHeaderRec.Reset();
                    PackageNoInfoRec.Reset();
                    LinesPackageNoInfoRec.DeleteAll();
                    Rec.DeleteAll();
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

    trigger OnInit()
    begin
        ExtCompanySetup.Get();
        LinesPackageNoInfoRec.DeleteAll();
        UserSetupRec.Get(UserId);
        CurrentStep := 1;
        MaxNavigatePage := 2;

        ResetControls();
    end;

    trigger OnAfterGetCurrRecord()
    var
        ItemRec: Record Item;
    begin
        ItemRec.Get(Rec."Item No.");
        BaseUoMCode := ItemRec."Base Unit of Measure";
    end;

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
        BaseUoMCode: Code[10];
        TobaccoBalesTF_TextCaption: Text;
        MaxNavigatePage, NewBalePosition, TotalBalesPositionInt : Integer;
        TotalBalesQtyDec: Decimal;

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
        // CurrPage.PkgNo__List.Page.SetNewBalePosition(1);
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

    local procedure AddSummaryBaleListPartofPackageNoInfo(var Rec: Record "PMP17 Bale No Regrading Line" temporary)
    begin
        ClearQtyResume();
        if Rec.FindSet() then
            repeat
                TotalBalesPositionInt += 1;
                TotalBalesQtyDec += Rec.Inventory;
            until Rec.Next() = 0;
    end;

    procedure AddRecordPkgNo__List(var Rec: Record "PMP17 Bale No Regrading Line" temporary; PkgNoInfoRec: Record "Package No. Information")
    var
        // LastBalePosInt: Integer;
        ItemRec: Record Item;
    begin
        Clear(NewBalePosition);

        PkgNoInfoRec.CalcFields(Inventory, "PMP04 Bin Code", "PMP04 Lot No.");
        ItemRec.Reset();
        Rec.Reset();
        Rec.SetRange("Package No.", PkgNoInfoRec."Package No.");
        Rec.SetRange("Item No.", PkgNoInfoRec."Item No.");
        Rec.SetRange("Variant Code", PkgNoInfoRec."Variant Code");
        if Rec.FindFirst() then
            Rec.Delete();
        // else
        // LastBalePosInt += 1;

        Rec.Reset(); // penting

        Rec.Init();
        Rec."Entry No." := GetLastEntryNo() + 1;
        Rec."Package No." := PkgNoInfoRec."Package No.";
        Rec."Item No." := PkgNoInfoRec."Item No.";
        Rec."Variant Code" := PkgNoInfoRec."Variant Code";
        Rec.CalcFields("Description", "Sub Merk 1", "Sub Merk 2", "Sub Merk 3", "Sub Merk 4", "Sub Merk 5", "Old Bale Position");
        Rec."Lot No." := PkgNoInfoRec."PMP04 Lot No.";
        Rec."Curr. Location Code" := UserSetupRec."SME073 Working Location";
        Rec."Curr. Bin Code" := PkgNoInfoRec."PMP04 Bin Code";
        Rec.Inventory := PkgNoInfoRec.Inventory;
        ItemRec.Get(Rec."Item No.");
        Rec."Base Unit of Measure" := ItemRec."Base Unit of Measure";
        Rec.Insert();

        Rec.Reset();
        // Clear(LastBalePosInt);
        Rec.SetCurrentKey("Entry No.");
        Rec.SetAscending("Entry No.", true);
        if Rec.FindSet() then
            repeat
                NewBalePosition += 1;
                Rec."New Bale Position" := NewBalePosition;
                Rec.Modify();
            until Rec.Next() = 0;
    end;

    #region HELPER
    local procedure GetLastEntryNo(): Integer
    var
        BaleNoRegradingLine: Record "PMP17 Bale No Regrading Line";
    begin
        BaleNoRegradingLine.Reset();
        BaleNoRegradingLine.SetCurrentKey("Entry No.");

        if BaleNoRegradingLine.FindLast() then
            exit(BaleNoRegradingLine."Entry No.")
        else
            exit(0);
    end;

    #endregion HELPER
}
