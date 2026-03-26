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
    // 2026/03/22  SW         PMP17                                     Revise whole page
    // 
    ApplicationArea = All;
    Caption = 'Tobacco Bales Transfer';
    PageType = NavigatePage;
    UsageCategory = Tasks;
    SourceTable = "PMP17 Tbcco Bales Transfer";
    SourceTableView = sorting("Entry No.");

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
                field(IsGetWeighingScale; IsGetWeighingScale)
                {
                    ApplicationArea = All;
                    Caption = 'Get Weighing Scale';
                    ToolTip = 'Specifies the Get Weighing Scale indicator for the Tobacco Bales Transfer';
                }
            }
            group(Page02)
            {
                Caption = '';
                Visible = CurrentStep = 2;

                field(TransferToBinCode_TextCaption; StrSubstNo('Transfer to Bin Code: %1', TransferToBinCode))
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    StyleExpr = 'Strong';
                }
                field(TobaccoBalesTF_TextCaption; TobaccoBalesTF_TextCaption)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    StyleExpr = TextCaption_StyleExprTxt;
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
                        PkgNoInfoListPage: Page "Package No. Information List";
                        SelectionFilterManagement: Codeunit SelectionFilterManagement;
                        RecRef: RecordRef;
                    begin
                        if TransferToBinCode = '' then begin
                            Error('Error: Tobacco Bales Transfer cannot be proceed any further before specifying Transfer to Bin Code');
                        end;

                        ResetTextCaptionValues();
                        ResetItemNVariantFields();

                        PackageNoInfoRec.Reset();
                        PkgNoInfoRec.Reset();
                        PkgNoInfoRec.SetRange("Location Filter", UserSetupRec."SME073 Working Location");
                        PkgNoInfoRec.SetAutoCalcFields(Inventory);
                        PkgNoInfoRec.SetFilter(Inventory, '> 0');
                        if PkgNoInfoListPage.RunModal = ACTION::LookupOK then begin
                            PkgNoInfoListPage.SetSelectionFilter(PkgNoInfoRec);
                            RecRef.GetTable(PkgNoInfoRec);
                            BaleNoText := SelectionFilterManagement.GetSelectionFilter(RecRef, PkgNoInfoRec.FieldNo("Package No."));

                            PkgNoInfoRec.SetFilter("Package No.", BaleNoText);
                            if PkgNoInfoRec.FindSet() then
                                repeat
                                    BaleNoText := PkgNoInfoRec."Package No.";
                                    BaleNoCode := PkgNoInfoRec."Package No.";
                                    ItemNoCode := PkgNoInfoRec."Item No.";
                                    VariantNoCode := PkgNoInfoRec."Variant Code";
                                    PackageNoInfoRec := PkgNoInfoRec;

                                    AddRecordPkgNo__List(Rec, PackageNoInfoRec);
                                until PkgNoInfoRec.Next() = 0;

                        end;
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

                        PackageNoInfoRec.Reset();
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

                            AddRecordPkgNo__List(Rec, PackageNoInfoRec);
                        end else
                            exit; // Silent exit, no messages
                    end;
                }
                field(WeighingQuantity; WeighingQuantity)
                {
                    ApplicationArea = All;
                    Caption = 'Weight (Kgs)';
                    ToolTip = 'Specifies the value of the Weight (Kgs) field';
                    Editable = false;
                }
                field(WeighingDeviceID; WeighingDeviceID)
                {
                    ApplicationArea = All;
                    Caption = 'Weighing Scale ID';
                    ToolTip = 'Specifies the value of the Weighing Scale ID field';
                    Editable = false;
                    trigger OnAssistEdit()
                    var
                        SelectWeighingID: Page "PMP19 Select Weighing ID";
                    begin
                        if IsGetWeighingScale then begin
                            if SelectWeighingID.RunModal() = Action::OK then begin
                                SelectWeighingID.GetWeighingData(WeighingDeviceID, WeighingQuantity, WeighingUoM, WeighingDate);
                            end;
                        end;
                    end;
                }
                repeater(PkgNo__List)
                {
                    Caption = 'Selected Box Number';
                    Editable = false;
                    field("Package No."; Rec."Package No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Package No. / Box No.';
                        ToolTip = 'Specifies the value of package / box no. number field.';
                        Editable = false;
                    }
                    field("Item No."; Rec."Item No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Item No.';
                        ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                        Editable = false;
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = All;
                        Caption = 'Description';
                        ToolTip = 'Specifies the description associated with this line.';
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
                    field("Lot No."; Rec."Lot No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Lot No.';
                        ToolTip = 'Specifies the lot no. associated with this line';
                        Editable = false;
                    }
                    field("Curr. Location Code"; Rec."Curr. Location Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Current Location Code';
                        ToolTip = 'Specifies the Current Location Code associated with this line';
                        Editable = false;
                    }
                    field("Curr. Bin Code"; Rec."Curr. Bin Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Current Bin Code';
                        ToolTip = 'Specifies the Current Bin Code associated with this line';
                        Editable = false;
                    }
                    field("Bin Code"; Rec."Bin Code")
                    {
                        ApplicationArea = All;
                        Caption = 'New Bin Code';
                        ToolTip = 'Specifies the New Bin Code associated with this line';
                        Editable = false;
                        Visible = false;
                    }
                    field(Inventory; Rec.Inventory)
                    {
                        ApplicationArea = All;
                        Caption = 'Inventory';
                        ToolTip = 'Specifies the quantity on inventory with this line.';
                        Editable = false;
                    }
                    field("Measured Weight (Kgs)"; Rec."Measured Weight (Kgs)")
                    {
                        ApplicationArea = All;
                        Caption = 'Measured Weight (Kgs)';
                        ToolTip = 'Specifies the value of Measured Weight (Kgs) with this line that comes from the weighing scale ID.';
                        Editable = false;
                    }
                    field("Base Unit of Measure"; Rec."Base Unit of Measure")
                    {
                        ApplicationArea = All;
                        Caption = 'Base Unit of Measure';
                        ToolTip = 'Specifies the value of the Base Unit of Measure field.', Comment = '%';
                        Editable = false;
                    }
                    field("Old Bale Position"; Rec."Old Bale Position")
                    {
                        ApplicationArea = All;
                        Caption = 'Old Bale Position';
                        ToolTip = 'Specifies the value of the Old Bale Position field.', Comment = '%';
                        Editable = false;
                        Visible = false;
                    }
                    field("New Bale Position"; Rec."New Bale Position")
                    {
                        ApplicationArea = All;
                        Caption = 'New Bale Position';
                        ToolTip = 'Specifies the value of the New Bale Position field.', Comment = '%';
                        Editable = false;
                        Visible = false;
                    }
                    field("User ID"; Rec."User ID")
                    {
                        ApplicationArea = All;
                        Caption = 'User ID';
                        ToolTip = 'Specifies the value of the User ID field.', Comment = '%';
                        Editable = false;
                        Visible = false;
                    }
                    field(Saved; Rec.Saved)
                    {
                        ApplicationArea = All;
                        Caption = 'Saved';
                        ToolTip = 'Specifies the value of the Saved field.', Comment = '%';
                        Editable = false;
                        Visible = false;
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
                        DeleteAllUnnecessaryLine(Rec);
                        ClearBaleNoCode();
                        ItemJnlLine.Reset();
                    end;
                end;
            }
            #region CURRENT STEP 1
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
            #endregion CURRENT STEP 1
            #region CURRENT STEP 2
            action(Rescan)
            {
                ApplicationArea = All;
                Caption = 'Re-Scan';
                InFooterBar = true;
                Enabled = CurrentStep = 2;
                Visible = CurrentStep = 2;
                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.SetRange("Bin Code", TransferToBinCode);
                    Rec.SetRange("User ID", UserId());
                    Rec.DeleteAll();
                    Commit();

                    ClearBaleNoCode();
                    ResetItemNVariantFields();
                    ResetTextCaptionValues();
                end;
            }
            action(Save)
            {
                ApplicationArea = All;
                Caption = 'Save';
                InFooterBar = true;
                Image = Save;
                Enabled = CurrentStep = 2;
                Visible = CurrentStep = 2;
                trigger OnAction()
                begin
                    ClearBaleNoCode();
                    ResetItemNVariantFields();
                    ResetTextCaptionValues();

                    Rec.Reset();
                    Rec.SetRange("Bin Code", TransferToBinCode);
                    Rec.SetRange("User ID", UserId());
                    Rec.ModifyAll(Saved, true);
                    // Commit();
                end;
            }
            action(GetWeighingID)
            {
                ApplicationArea = All;
                Caption = 'Get Weight';
                Image = GetSourceDoc;
                InFooterBar = true;
                Enabled = IsGetWeighingScale AND (CurrentStep = 2);
                Visible = IsGetWeighingScale AND (CurrentStep = 2);
                trigger OnAction()
                var
                    SelectWeighingID: Page "PMP19 Select Weighing ID";
                begin
                    WeighingScaleMgmt.GetWeighingData(WeighingDeviceID, WeighingQuantity, WeighingUoM, WeighingDate);
                end;
            }
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Image = Post;
                InFooterBar = true;
                Enabled = CurrentStep = 2;
                Visible = CurrentStep = 2;
                trigger OnAction()
                var
                    PkgNoInfoRec: Record "Package No. Information";
                begin
                    Rec.Reset();
                    Rec.SetRange("Bin Code", TransferToBinCode);
                    Rec.SetRange("User ID", UserId());
                    if Rec.FindSet() then
                        repeat
                            if Rec."Curr. Bin Code" = TransferToBinCode then begin
                                continue;
                            end;

                            if TobaccoBalesWhseTFMgmt.PostTobaccoBalesTransferItemReclass(ItemJnlLine, Rec, UserSetupRec, TransferToBinCode) then begin
                                PkgNoInfoRec.Reset();
                                PkgNoInfoRec.SetRange("Item No.", Rec."Item No.");
                                PkgNoInfoRec.SetRange("Variant Code", Rec."Variant Code");
                                PkgNoInfoRec.SetRange("Package No.", Rec."Package No.");
                                if PkgNoInfoRec.FindFirst() then begin
                                    PkgNoInfoRec."PMP17 Measured Weight (Kgs)" := Rec."Measured Weight (Kgs)";
                                    PkgNoInfoRec.Modify();
                                end;
                                Rec.Delete();
                                Commit();
                            end else
                                NotifyUserFailedPosting();
                        until Rec.Next() = 0;

                    // Clear(TransferToBinCode);
                    ClearBaleNoCode();
                    Message('The Reclassification Journal is successfully posted.');
                    NotifyUserSuccessPosting();
                end;
            }
            #endregion CURRENT STEP 2
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
                    DeleteAllUnnecessaryLine(Rec);
                    Clear(TransferToBinCode);
                    ClearBaleNoCode();
                    CurrPage.Close();
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
                        if TransferToBinCode = '' then
                            Error('Please fill the destination Bin Code to transfer, this field should not be empty');
                        TobaccoBalesTF_TextCaption := StrSubstNo('Tobacco Bale Transfer | %1', TransferToBinCode);

                        DeleteAllUnnecessaryLine(Rec);

                        Rec.Reset();
                        Rec.SetRange("Bin Code", TransferToBinCode);
                        Rec.SetRange("User ID", UserId());

                        if (UserSetupRec."PMP19 Def. Weighing Device ID" <> '') OR (UserSetupRec."PMP19 Def. Weighing Device ID" <> ' ') then begin
                            WeighingDeviceID := UserSetupRec."PMP19 Def. Weighing Device ID";
                            if not WeighingScaleRec.Get(WeighingDeviceID) then begin
                                Error('The Weighing Scale ID configured in your User Setup (%1) was not found in the Weighing Scale List. Please review the Weighing Scale ID assigned to user %2.', WeighingDeviceID, UserId);
                            end
                        end;
                    end;

                    CurrentStep += 1;
                end;
            }
        }
    }
    #endregion ACTIONS

    trigger OnInit()
    begin
        ExtCompanySetup.Get();
        ResetTextCaptionValues();
        Clear(TransferToBinCode);
        Clear(BaleNoCode);
        Clear(BaleNoText);
        Clear(IsGetWeighingScale);
        Clear(WeighingScaleMgmt);
        Clear(WeighingDeviceID);
        Clear(WeighingQuantity);
        Clear(WeighingDate);
        ResetItemNVariantFields();
        UserSetupRec.Get(UserId);
        WeighingScaleRec.Reset();

        CurrentStep := 1;
        MaxNavigatePage := 2;
    end;

    trigger OnClosePage()
    begin
        if (TransferToBinCode <> '') OR (TransferToBinCode <> ' ') then begin
            DeleteAllUnnecessaryLine(Rec);
        end;
    end;

    var
        ChangeLocationCodeRep: Report "PMP17 Change Working Loc. Code";
        TobaccoBalesWhseTFMgmt: Codeunit "PMP17 Tobacco Bales Whse. Tf.";
        Bin: Record Bin;
        UserSetupRec: Record "User Setup";
        PackageNoInfoRec: Record "Package No. Information";
        ItemJnlLine: Record "Item Journal Line";
        TextCaption_StyleExprTxt, BaleNoText : Text;

    protected var
        WeighingScaleMgmt: Codeunit "PMP19 Weighing Scale Mgt.";
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        WeighingScaleRec: Record "PMP19 Weighing Scales";
        IsGetWeighingScale: Boolean;
        MaxNavigatePage, CurrentStep : Integer;
        WeighingQuantity: Decimal;
        WeighingDate: DateTime;
        TransferToBinCode, BaleNoCode : Code[50];
        ItemNoCode, WeighingDeviceID : Code[20];
        VariantNoCode, WeighingUoM : Code[10];
        TobaccoBalesTF_TextCaption: Text;

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

    local procedure DeleteAllUnnecessaryLine(var Rec: Record "PMP17 Tbcco Bales Transfer")
    begin
        Rec.Reset();
        Rec.SetRange("Bin Code", TransferToBinCode);
        Rec.SetRange("User ID", UserId());
        Rec.SetRange(Saved, false);
        Rec.DeleteAll();
        Commit();
    end;

    procedure AddRecordPkgNo__List(var Rec: Record "PMP17 Tbcco Bales Transfer"; var PkgNoInfoRec: Record "Package No. Information")
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

        Rec.Reset(); // important

        Rec.Init();
        Rec."Entry No." := GetLastEntryNo(Rec) + 1;
        Rec."Package No." := PkgNoInfoRec."Package No.";
        Rec."Item No." := PkgNoInfoRec."Item No.";
        Rec."Variant Code" := PkgNoInfoRec."Variant Code";
        Rec.CalcFields("Description", "Sub Merk 1", "Sub Merk 2", "Sub Merk 3", "Sub Merk 4", "Sub Merk 5", "Old Bale Position");
        Rec."Lot No." := PkgNoInfoRec."PMP04 Lot No.";
        Rec."Curr. Location Code" := UserSetupRec."SME073 Working Location";
        Rec."Curr. Bin Code" := PkgNoInfoRec."PMP04 Bin Code";
        Rec."Bin Code" := TransferToBinCode;
        Rec.Inventory := PkgNoInfoRec.Inventory;
        Rec."Measured Weight (Kgs)" := WeighingQuantity;
        ItemRec.Get(Rec."Item No.");
        Rec."Base Unit of Measure" := ItemRec."Base Unit of Measure";
        Rec."User ID" := UserId();
        Rec.Insert();

        Rec.Reset();
        Clear(LastBalePosInt);
        Rec.SetRange("Bin Code", TransferToBinCode);
        Rec.SetRange("User ID", UserId());
        Rec.SetCurrentKey("Entry No.");
        Rec.SetAscending("Entry No.", true);
        if Rec.FindSet() then
            repeat
                LastBalePosInt += 1;
                Rec."New Bale Position" := LastBalePosInt;
                Rec.Modify();
            until Rec.Next() = 0;

        Rec.Reset();
        Rec.SetRange("Bin Code", TransferToBinCode);
        Rec.SetRange("User ID", UserId());
    end;

    local procedure GetLastEntryNo(var Rec: Record "PMP17 Tbcco Bales Transfer") LastEntryNo: Integer
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Entry No.");

        if Rec.FindLast() then begin
            LastEntryNo := Rec."Entry No.";
        end else begin
            LastEntryNo := 0;
        end;

        Rec.Reset();
        Rec.SetRange("Bin Code", TransferToBinCode);
        Rec.SetRange("User ID", UserId());
        exit(LastEntryNo);
    end;
}
