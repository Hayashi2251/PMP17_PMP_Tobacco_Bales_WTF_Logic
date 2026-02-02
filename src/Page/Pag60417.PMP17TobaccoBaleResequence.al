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
    SourceTable = "PMP17 TbccoBalesWhseTFPkgNo";
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
                        BinRec.SetRange("Location Code", UserSetupRec."SME073 Working Location");
                        if Page.RunModal(Page::"Bin List", BinRec) = Action::LookupOK then begin
                            BinCode := BinRec.Code;
                            CurrentStep += 1;
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
                        BinRec.SetRange("Location Code", UserSetupRec."SME073 Working Location");
                        BinRec.SetRange(Code, BinCode);
                        if BinRec.FindFirst() then begin
                            BinCode := BinRec.Code;
                            CurrentStep += 1;
                        end else
                            Error('The scanned bin code (%1) is not available in current working location code of %2.', BinCode, UserSetupRec."SME073 Working Location");
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
                        PkgNoInfoListPage: Page "Package No. Information List";
                        PkgNoInfoRec: Record "Package No. Information";
                        SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        RecRef: RecordRef;
                    begin
                        PkgNoInfoRec.Reset();
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                        PkgNoInfoRec.CalcFields(Inventory);
                        PkgNoInfoRec.SetFilter(Inventory, '> 0');
                        PkgNoInfoListPage.SetTableView(PkgNoInfoRec);
                        // if Page.RunModal(Page::"Package No. Information List", PkgNoInfoRec) = Action::LookupOK then begin
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

                                    //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
                                    AddRecordPkgNo__List(Rec, PkgNoInfoRec);
                                    ClearBaleNoCode();
                                //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
                                until PkgNoInfoRec.Next() = 0;

                            // Add the Package No Info to the Tobacco Bales Resequence Listpart
                            // CurrPage.PkgNo__List.Page.InsertRecord(PackageNoInfoRec, UserSetupRec."SME073 Working Location", BinCode);
                        end;
                        CurrPage.Update(false);
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
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetRange("Package No.", BaleNoCode);
                        PkgNoInfoRec.SetFilter(Inventory, '>0');
                        if PkgNoInfoRec.FindFirst() then begin
                            BaleNoText := PkgNoInfoRec."Package No.";
                            BaleNoCode := PkgNoInfoRec."Package No.";

                            AddRecordPkgNo__List(Rec, PkgNoInfoRec);
                            ClearBaleNoCode();
                            // Add the Package No Info to the Tobacco Bales Resequence Listpart
                            // CurrPage.PkgNo__List.Page.InsertRecord(PkgNoInfoRec, UserSetupRec."SME073 Working Location", BinCode);
                        end else
                            exit; // Silent exit, no messages

                        CurrPage.Update(false);
                    end;
                }
                repeater(PkgNo__List)
                {
                    Caption = 'Detail';
                    Editable = false;
                    field("PMP07 Bale Position"; Rec."Old Bale Position")
                    {
                        ApplicationArea = All;
                        Caption = 'Bale Position';
                        ToolTip = 'Specifies the new bale position of the scanned bale number.';
                        Editable = false;
                    }
                    field("PMP17 New Bale Position"; Rec."New Bale Position")
                    {
                        ApplicationArea = All;
                        Caption = 'New Sequence';
                        ToolTip = 'Specifies the New Sequence of the scanned bale number.';
                        Editable = false;
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = All;
                        Caption = 'Description';
                        ToolTip = 'Specifies the description associated with this line.';
                        Editable = false;
                    }
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
                    field(CurrentLocationCode; CurrentLocationCode)
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
                    // field(CurrentBinCode; CurrentBinCode)
                    // {
                    //     ApplicationArea = All;
                    //     Caption = 'Current Bin Code';
                    //     ToolTip = 'Specifies the Current Bin Code associated with this line';
                    //     Editable = false;
                    // }
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
                // part(PkgNo__List; "PMP17 Tbco. Bales Reseq. Sub.")
                // {
                //     ApplicationArea = All;
                //     UpdatePropagation = Both;
                //     // Caption = ''
                // }
            }
        }
    }
    #endregion LAYOUT

    #region ACTIONS
    actions
    {
        area(navigation)
        {
            // action(Refresh)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Refresh';
            //     Enabled = CurrentStep > 1;
            //     Visible = CurrentStep > 1;
            //     InFooterBar = true;
            //     Image = PreviousRecord;
            //     trigger OnAction()
            //     begin
            //         CurrPage.Update(false);
            //     end;
            // }
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
                    if UserSetupRec."SME073 Working Location" <> '' then begin
                        ChangeLocationCodeRep.SetLocationCode(UserSetupRec."SME073 Working Location");
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
                        Rec.DeleteAll();
                        // CurrPage.PkgNo__List.Page.DeleteAllRecord();
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
                    // CurrPage.PkgNo__List.Page.GetPackageNoInfo_TobaccoBalesResequenceSubform(LinesPackageNoInfoRec);
                    // if LinesPackageNoInfoRec.Count > 0 then begin

                    Rec.CalcFields("Description", "Sub Merk 1", "Sub Merk 2", "Sub Merk 3", "Sub Merk 4", "Sub Merk 5", "Old Bale Position");
                    Rec.Reset();
                    if Rec.FindSet() then
                        repeat
                            PkgNoInfoRec.Reset();
                            PkgNoInfoRec.SetRange("Item No.", Rec."Item No.");
                            PkgNoInfoRec.SetRange("Variant Code", Rec."Variant Code");
                            PkgNoInfoRec.SetRange("Package No.", Rec."Package No.");
                            if PkgNoInfoRec.FindFirst() then begin
                                if Rec."Bin Code" <> BinCode then begin
                                    PkgNoInfoRec.CalcFields(Inventory);
                                    PkgNoInfoRec.CalcFields("PMP04 Bin Code");
                                    PkgNoInfoRec.CalcFields("PMP04 Lot No.");
                                    TobaccoBalesWhseTFMgmt.PostTobaccoBalesTransferItemReclass(ItemJnlLine, PkgNoInfoRec, UserSetupRec, BinCode);
                                end;
                                PkgNoInfoRec."PMP07 Bale Position" := Rec."New Bale Position";
                                PkgNoInfoRec.Modify();
                            end;
                        until Rec.Next() = 0;

                    CurrPage.Update(false);
                    // end;
                    ClearNewBalePosition();
                    ClearBaleNoCode();
                    Rec.DeleteAll();
                    // CurrPage.PkgNo__List.Page.DeleteAllRecord();
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

    var
        ChangeLocationCodeRep: Report "PMP17 Change Working Loc. Code";
        TobaccoBalesWhseTFMgmt: Codeunit "PMP17 Tobacco Bales Whse. Tf.";
        UserSetupRec: Record "User Setup";
        PackageNoInfoRec: Record "Package No. Information";
        LinesPackageNoInfoRec: Record "Package No. Information" temporary;
        ItemJnlLine: Record "Item Journal Line";
        BaleNoText: Text;
        CurrentLocationCode, BaseUoMCode : Code[10];
        CurrentBinCode: Code[20];

    protected var
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        CurrentStep: Integer;
        BinCode: Code[20];
        BaleNoCode: Code[50];
        TobaccoBalesTF_TextCaption: Text;
        MaxNavigatePage, NewBalePosition : Integer;

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
        // CurrPage.PkgNo__List.Page.SetNewBalePosition(1);
    end;

    procedure AddRecordPkgNo__List(var Rec: Record "PMP17 TbccoBalesWhseTFPkgNo" temporary; PkgNoInfoRec: Record "Package No. Information")
    var
        LastBalePosInt: Integer;
        ItemRec: Record Item;
    begin
        Rec.Reset();
        PkgNoInfoRec.CalcFields(Inventory, "PMP04 Bin Code", "PMP04 Lot No.");
        Rec.SetRange("Package No.", PkgNoInfoRec."Package No.");
        Rec.SetRange("Item No.", PkgNoInfoRec."Item No.");
        Rec.SetRange("Variant Code", PkgNoInfoRec."Variant Code");
        if Rec.FindFirst() then
            Rec.Delete();
        // else
        // NewBalePosition += 1;

        Rec.Reset(); // penting

        Rec.Init();
        Rec."Entry No." := GetLastEntryNo(Rec) + 1;
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
        Clear(LastBalePosInt);
        Rec.SetCurrentKey("Entry No.");
        Rec.SetAscending("Entry No.", true);
        if Rec.FindSet() then
            repeat
                LastBalePosInt += 1;
                Rec."New Bale Position" := LastBalePosInt;
                Rec.Modify();
            until Rec.Next() = 0;
    end;

    local procedure GetLastEntryNo(var Rec: Record "PMP17 TbccoBalesWhseTFPkgNo" temporary): Integer
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Entry No.");

        if Rec.FindLast() then
            exit(Rec."Entry No.")
        else
            exit(0);
    end;

}
