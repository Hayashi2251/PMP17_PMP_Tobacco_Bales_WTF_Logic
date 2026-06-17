page 50036 "PMP17 Internal Transfer"
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
    // 2026/04/22  SW         PMP17         -                           Create Page
    // 

    ApplicationArea = All;
    Caption = 'Internal Transfer';
    PageType = NavigatePage;
    UsageCategory = Tasks;
    SourceTable = "PMP17 Tbco Internal Tansfer";
    SourceTableTemporary = true;
    SourceTableView = sorting("Entry No.");
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            #region PAGE 01
            group(Page01)
            {
                Caption = '';
                Visible = CurrentStep_g = 1;
                field(TransferToBinCode; TransferToBinCode_g)
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
                        // ClearBaleNoCode();

                        BinRec.Reset();
                        BinRec.SetRange("Location Code", UserSetupRec."SME073 Working Location");
                        if Page.RunModal(Page::"Bin List", BinRec) = Action::LookupOK then begin
                            TransferToBinCode_g := BinRec.Code;
                            CurrentStep_g += 1;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        BinRec: Record Bin;
                    begin
                        // ClearBaleNoCode();

                        BinRec.Reset();
                        BinRec.SetRange("Location Code", UserSetupRec."SME073 Working Location");
                        BinRec.SetRange(Code, TransferToBinCode_g);
                        if BinRec.FindFirst() then begin
                            TransferToBinCode_g := BinRec.Code;
                            CurrentStep_g += 1;
                        end else
                            Error('The scanned bin code (%1) is not available in current working location code of %2.', TransferToBinCode_g, UserSetupRec."SME073 Working Location");
                    end;
                }
                field(CurrLocationCode_g; CurrLocationCode_g)
                {
                    ApplicationArea = All;
                    Caption = 'Current Location';
                    ToolTip = 'Specifies the current working location for the Tobacco Internal Transfer.';
                    Editable = false;
                }
            }
            #endregion PAGE 01
            #region PAGE 02
            group(page02)
            {
                Caption = '';
                Visible = CurrentStep_g = 2;

                field(TobaccoBalesTF_TextCaption; TobaccoBalesTF_TextCaption)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Editable = false;
                    StyleExpr = TextCaption_StyleExprTxt;
                } // TEXT CAPTION
                field(ItemNoCode_g; ItemNoCode_g)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the value of the Item No. field';
                    ExtendedDatatype = Barcode;
                    trigger OnValidate()
                    var
                        ItemRecLocal: Record Item;
                    begin
                        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/05/26 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
                        Clear(ItemDescription_g);
                        Clear(VariantCode_g);
                        Clear(LotNoCode_g);
                        Clear(BaleNoCode_g);
                        Clear(InventoryQty_g);
                        Clear(FromBinCode_g);

                        ItemNoCode_g := ScanBarcode(ItemNoCode_g, 1);
                        if ItemRecLocal.Get(ItemNoCode_g) then begin
                            ItemDescription_g := ItemRecLocal.Description;
                            UnitofMeasureCode_g := ItemRecLocal."Base Unit of Measure";
                        end;
                        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/05/26 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
                    end;

                    trigger OnDrillDown()
                    var
                        ItemRecLocal: Record Item;
                    begin
                        Clear(ItemRecLocal);
                        ItemRecLocal.SetRange(Blocked, false);
                        ItemRecLocal.SetRange(Type, ItemRecLocal.Type::Inventory);
                        if Page.RunModal(Page::"Item List", ItemRecLocal) = Action::LookupOK then begin
                            ItemNoCode_g := ItemRecLocal."No.";
                            ItemDescription_g := ItemRecLocal.Description;
                            UnitofMeasureCode_g := ItemRecLocal."Base Unit of Measure";
                            Clear(VariantCode_g);
                            Clear(LotNoCode_g);
                            Clear(BaleNoCode_g);
                            Clear(InventoryQty_g);
                            Clear(FromBinCode_g);
                        end;
                    end;
                }
                field(VariantCode_g; VariantCode_g)
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                    ToolTip = 'Specifies the value of the Variant Code field';
                    ExtendedDatatype = Barcode;
                    trigger OnValidate()
                    begin
                        Clear(LotNoCode_g);
                        Clear(BaleNoCode_g);
                        Clear(InventoryQty_g);
                        Clear(FromBinCode_g);
                        VariantCode_g := ScanBarcode(VariantCode_g, 2);
                    end;

                    trigger OnDrillDown()
                    var
                        ItemVariantRecLocal: Record "Item Variant";
                    begin
                        ItemVariantRecLocal.Reset();
                        Clear(ItemVariantRecLocal);

                        ItemVariantRecLocal.SetRange(Blocked, false);
                        ItemVariantRecLocal.SetRange("Item No.", ItemNoCode_g);
                        if Page.RunModal(Page::"Item Variants", ItemVariantRecLocal) = Action::LookupOK then begin
                            VariantCode_g := ItemVariantRecLocal.Code;
                            Clear(LotNoCode_g);
                            Clear(BaleNoCode_g);
                            Clear(InventoryQty_g);
                            Clear(FromBinCode_g);
                        end;
                    end;
                }
                field(ItemDescription_g; ItemDescription_g)
                {
                    ApplicationArea = All;
                    Caption = 'Item Description';
                    ToolTip = 'Specifies the value of the Item Description field';
                    Editable = false;
                }
                field(LotNoCode_g; LotNoCode_g)
                {
                    ApplicationArea = All;
                    Caption = 'Lot No.';
                    ToolTip = 'Specifies the value of the Lot No. field';
                    ExtendedDatatype = Barcode;
                    trigger OnValidate()
                    begin
                        Clear(InventoryQty_g);
                        Clear(FromBinCode_g);
                        LotNoCode_g := ScanBarcode(LotNoCode_g, 3);
                    end;

                    trigger OnDrillDown()
                    var
                        LotNoInfoRecLocal: Record "Lot No. Information";
                    begin
                        LotNoInfoRecLocal.Reset();
                        Clear(LotNoInfoRecLocal);

                        LotNoInfoRecLocal.SetRange(Blocked, false);
                        LotNoInfoRecLocal.SetRange("Item No.", ItemNoCode_g);
                        LotNoInfoRecLocal.SetRange("Variant Code", VariantCode_g);
                        LotNoInfoRecLocal.SetRange("Location Filter", CurrLocationCode_g);
                        if Page.RunModal(Page::"Lot No. Information List", LotNoInfoRecLocal) = Action::LookupOK then begin
                            LotNoCode_g := LotNoInfoRecLocal."Lot No.";
                            Clear(InventoryQty_g);
                            Clear(FromBinCode_g);
                        end;
                    end;
                }
                field(BaleNoCode_g; BaleNoCode_g)
                {
                    ApplicationArea = All;
                    Caption = 'Package No.';
                    ToolTip = 'Specifies the value of the Package No. field';
                    ExtendedDatatype = Barcode;
                    trigger OnValidate()
                    var
                        PackageNoInfoRecLocal: Record "Package No. Information";
                        BinContentRecLocal: Record "Bin Content";
                    begin
                        BaleNoCode_g := ScanBarcode(BaleNoCode_g, 4);

                        PackageNoInfoRecLocal.Reset();
                        PackageNoInfoRecLocal.SetRange(Blocked, false);
                        PackageNoInfoRecLocal.SetRange("Item No.", ItemNoCode_g);
                        PackageNoInfoRecLocal.SetRange("Variant Code", VariantCode_g);
                        PackageNoInfoRecLocal.SetRange("Package No.", BaleNoCode_g);
                        PackageNoInfoRecLocal.SetRange("Location Filter", CurrLocationCode_g);
                        PackageNoInfoRecLocal.SetAutoCalcFields(Inventory, "PMP04 Bin Code");
                        PackageNoInfoRecLocal.SetFilter(Inventory, '> 0');
                        if PackageNoInfoRecLocal.FindFirst() then begin
                            PackageNoInfoRecLocal.CalcFields(Inventory);

                            BinContentRecLocal.Reset();
                            BinContentRecLocal.SetRange("Location Code", CurrLocationCode_g);
                            BinContentRecLocal.SetRange("Item No.", ItemNoCode_g);
                            BinContentRecLocal.SetRange("Variant Code", VariantCode_g);
                            BinContentRecLocal.SetRange("Unit of Measure Code", UnitofMeasureCode_g);
                            BinContentRecLocal.SetRange("Lot No. Filter", LotNoCode_g);
                            BinContentRecLocal.SetRange("Package No. Filter", BaleNoCode_g);
                            BinContentRecLocal.SetAutoCalcFields(Quantity, "Quantity (Base)");
                            BinContentRecLocal.SetFilter(Quantity, '> 0');
                            if BinContentRecLocal.Count = 1 then begin
                                BinContentRecLocal.FindFirst();
                                BinContentRecLocal.CalcFields(Quantity, "Quantity (Base)");
                                FromBinCode_g := BinContentRecLocal."Bin Code";
                                InventoryQty_g := BinContentRecLocal.Quantity;
                            end else
                                Clear(FromBinCode_g);
                        end;
                    end;

                    trigger OnDrillDown()
                    var
                        PackageNoInfoRecLocal: Record "Package No. Information";
                        BinContentRecLocal: Record "Bin Content";
                    begin
                        PackageNoInfoRecLocal.Reset();
                        Clear(BaleNoCode_g);

                        PackageNoInfoRecLocal.SetRange(Blocked, false);
                        PackageNoInfoRecLocal.SetRange("Item No.", ItemNoCode_g);
                        PackageNoInfoRecLocal.SetRange("Variant Code", VariantCode_g);
                        PackageNoInfoRecLocal.SetRange("Location Filter", CurrLocationCode_g);
                        PackageNoInfoRecLocal.SetAutoCalcFields(Inventory, "PMP04 Bin Code");
                        PackageNoInfoRecLocal.SetFilter(Inventory, '> 0');
                        if Page.RunModal(Page::"Package No. Information List", PackageNoInfoRecLocal) = Action::LookupOK then begin
                            PackageNoInfoRecLocal.CalcFields(Inventory);
                            BaleNoCode_g := PackageNoInfoRecLocal."Package No.";

                            BinContentRecLocal.Reset();
                            BinContentRecLocal.SetRange("Location Code", CurrLocationCode_g);
                            BinContentRecLocal.SetRange("Item No.", ItemNoCode_g);
                            BinContentRecLocal.SetRange("Variant Code", VariantCode_g);
                            BinContentRecLocal.SetRange("Unit of Measure Code", UnitofMeasureCode_g);
                            BinContentRecLocal.SetRange("Lot No. Filter", LotNoCode_g);
                            BinContentRecLocal.SetRange("Package No. Filter", BaleNoCode_g);
                            BinContentRecLocal.SetAutoCalcFields(Quantity, "Quantity (Base)");
                            BinContentRecLocal.SetFilter(Quantity, '> 0');
                            if BinContentRecLocal.Count = 1 then begin
                                BinContentRecLocal.FindFirst();
                                BinContentRecLocal.CalcFields(Quantity, "Quantity (Base)");
                                FromBinCode_g := BinContentRecLocal."Bin Code";
                                InventoryQty_g := BinContentRecLocal.Quantity;
                            end else
                                Clear(FromBinCode_g);
                        end;
                    end;
                }
                field(FromBinCode_g; FromBinCode_g)
                {
                    ApplicationArea = All;
                    Caption = 'From Bin Code';
                    ToolTip = 'Specifies the value of the From Bin Code field';
                    trigger OnValidate()
                    var
                        BinContentRecLocal: Record "Bin Content";
                    begin
                        BinContentRecLocal.Reset();
                        BinContentRecLocal.SetRange("Location Code", CurrLocationCode_g);
                        BinContentRecLocal.SetRange("Bin Code", FromBinCode_g);
                        BinContentRecLocal.SetRange("Item No.", ItemNoCode_g);
                        BinContentRecLocal.SetRange("Variant Code", VariantCode_g);
                        BinContentRecLocal.SetRange("Unit of Measure Code", UnitofMeasureCode_g);
                        BinContentRecLocal.SetRange("Lot No. Filter", LotNoCode_g);
                        BinContentRecLocal.SetRange("Package No. Filter", BaleNoCode_g);
                        BinContentRecLocal.SetAutoCalcFields(Quantity, "Quantity (Base)");
                        BinContentRecLocal.SetFilter(Quantity, '> 0');
                        if BinContentRecLocal.FindFirst() then begin
                            BinContentRecLocal.CalcFields(Quantity, "Quantity (Base)");
                            FromBinCode_g := BinContentRecLocal."Bin Code";
                            InventoryQty_g := BinContentRecLocal.Quantity;
                        end else
                            Error('No available quantity found for the selected Item in Bin %1, with the specified criteria of Item %2, Variant %3, Lot %4, Package %5 at Location of %6', FromBinCode_g, ItemNoCode_g, VariantCode_g, LotNoCode_g, BaleNoCode_g, CurrLocationCode_g);
                    end;

                    trigger OnDrillDown()
                    var
                        BinContentRecLocal: Record "Bin Content";
                    begin
                        BinContentRecLocal.Reset();
                        Clear(BinContentRecLocal);

                        BinContentRecLocal.SetRange("Location Code", CurrLocationCode_g);
                        BinContentRecLocal.SetRange("Item No.", ItemNoCode_g);
                        BinContentRecLocal.SetRange("Variant Code", VariantCode_g);
                        BinContentRecLocal.SetRange("Unit of Measure Code", UnitofMeasureCode_g);
                        BinContentRecLocal.SetRange("Lot No. Filter", LotNoCode_g);
                        BinContentRecLocal.SetRange("Package No. Filter", BaleNoCode_g);
                        BinContentRecLocal.SetAutoCalcFields(Quantity, "Quantity (Base)");
                        BinContentRecLocal.SetFilter(Quantity, '> 0');
                        if BinContentRecLocal.FindFirst() then begin
                            if Page.RunModal(Page::"Bin Content", BinContentRecLocal) = Action::LookupOK then begin
                                BinContentRecLocal.CalcFields(Quantity, "Quantity (Base)");
                                FromBinCode_g := BinContentRecLocal."Bin Code";
                                InventoryQty_g := BinContentRecLocal.Quantity;
                            end
                        end else
                            Error('No available quantity found for the selected Item with the specified criteria of Item %1, Variant %2, Lot %3, Package %4 at Location of %5', ItemNoCode_g, VariantCode_g, LotNoCode_g, BaleNoCode_g, CurrLocationCode_g);
                    end;
                }
                field(InventoryQty_g; InventoryQty_g)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the value of the Quantity field';
                }
                field(UnitofMeasureCode_g; UnitofMeasureCode_g)
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure';
                    ToolTip = 'Specifies the value of the Unit of Measure field';
                    ExtendedDatatype = Barcode;
                    trigger OnValidate()
                    begin
                        UnitofMeasureCode_g := ScanBarcode(UnitofMeasureCode_g, 5);
                    end;

                    trigger OnDrillDown()
                    var
                        UoMRecLocal: Record "Item Unit of Measure";
                    begin
                        UoMRecLocal.Reset();
                        Clear(UoMRecLocal);

                        UoMRecLocal.SetRange("Item No.", ItemNoCode_g);
                        if Page.RunModal(Page::"Item Units of Measure", UoMRecLocal) = Action::LookupOK then begin
                            UnitofMeasureCode_g := UoMRecLocal.Code;
                        end;
                    end;
                }
                repeater(PkgNo__List)
                {
                    Caption = 'Details';
                    Editable = false;
                    field("User ID"; Rec."User ID")
                    {
                        ApplicationArea = All;
                        Caption = 'User ID';
                        ToolTip = 'Specifies the value of the User ID field.', Comment = '%';
                        Visible = false;
                    }
                    field("Entry No."; Rec."Entry No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Entry No.';
                        ToolTip = 'Specifies the value of the Entry No. field.', Comment = '%';
                        Visible = false;
                    }
                    field("Item No."; Rec."Item No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Item No.';
                        ToolTip = 'Specifies the value of the Item No. field.', Comment = '%';
                    }
                    field("Variant Code"; Rec."Variant Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Variant Code';
                        ToolTip = 'Specifies the value of the Variant Code field.', Comment = '%';
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = All;
                        Caption = 'Description';
                        ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                    }
                    field("Lot No."; Rec."Lot No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Lot No.';
                        ToolTip = 'Specifies the value of the Lot No. field.', Comment = '%';
                    }
                    field("Package No."; Rec."Package No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Package No.';
                        ToolTip = 'Specifies the value of the Package No. field.', Comment = '%';
                    }
                    field("Curr. Location Code"; Rec."Curr. Location Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Curr. Location Code""';
                        ToolTip = 'Specifies the value of the Curr. Location Code" field.', Comment = '%';
                        Visible = false;
                    }
                    field("Curr. Bin Code"; Rec."Curr. Bin Code")
                    {
                        ApplicationArea = All;
                        Caption = 'Curr. Bin Code';
                        ToolTip = 'Specifies the value of the Curr. Bin Code field.', Comment = '%';
                        Visible = false;
                    }
                    field("Dest. Bin Code"; Rec."Dest. Bin Code")
                    {
                        ApplicationArea = All;
                        Caption = 'To Bin Code';
                        ToolTip = 'Specifies the value of the To Bin Code field.', Comment = '%';
                    }
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = All;
                        Caption = 'Quantity';
                        ToolTip = 'Specifies the value of the Quantity field.', Comment = '%';
                    }
                    field("Base Unit of Measure"; Rec."Base Unit of Measure")
                    {
                        ApplicationArea = All;
                        Caption = 'Base Unit of Measure';
                        ToolTip = 'Specifies the value of the Base Unit of Measure field.', Comment = '%';
                    }
                    field("Unit of Measure"; Rec."Unit of Measure")
                    {
                        ApplicationArea = All;
                        Caption = 'Unit of Measure';
                        ToolTip = 'Specifies the value of the Unit of Measure field.', Comment = '%';
                        Visible = false;
                    }
                    field("Sub Merk 1"; Rec."Sub Merk 1")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 1';
                        ToolTip = 'Specifies the value of the Sub Merk 1 field.', Comment = '%';
                        Visible = false;
                    }
                    field("Sub Merk 2"; Rec."Sub Merk 2")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 2';
                        ToolTip = 'Specifies the value of the Sub Merk 2 field.', Comment = '%';
                        Visible = false;
                    }
                    field("Sub Merk 3"; Rec."Sub Merk 3")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 3';
                        ToolTip = 'Specifies the value of the Sub Merk 3 field.', Comment = '%';
                        Visible = false;
                    }
                    field("Sub Merk 4"; Rec."Sub Merk 4")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 4';
                        ToolTip = 'Specifies the value of the Sub Merk 4 field.', Comment = '%';
                        Visible = false;
                    }
                    field("Sub Merk 5"; Rec."Sub Merk 5")
                    {
                        ApplicationArea = All;
                        Caption = 'Sub Merk 5';
                        ToolTip = 'Specifies the value of the Sub Merk 5 field.', Comment = '%';
                        Visible = false;
                    }
                    field(Saved; Rec.Saved)
                    {
                        ApplicationArea = All;
                        Caption = 'Saved';
                        ToolTip = 'Specifies the value of the Saved field.', Comment = '%';
                        Visible = false;
                    }
                }
            }
            #endregion PAGE 02
        }
    }
    actions
    {
        area(navigation)
        {
            action(Back)
            {
                ApplicationArea = All;
                Caption = 'Back';
                Enabled = CurrentStep_g > 1;
                Visible = CurrentStep_g > 1;
                InFooterBar = true;
                Image = PreviousRecord;
                trigger OnAction()
                begin
                    if CurrentStep_g = 2 then begin
                        Clear(FromBinCode_g);
                        Clear(TobaccoBalesTF_TextCaption);
                        Clear(TextCaption_StyleExprTxt);
                        Clear(ItemNoCode_g);
                        Clear(ItemDescription_g);
                        Clear(VariantCode_g);
                        Clear(LotNoCode_g);
                        Clear(UnitofMeasureCode_g);
                        Clear(BaleNoCode_g);
                        Clear(InventoryQty_g);

                        DeleteAllUnnecessaryLine(Rec);
                    end;
                    CurrentStep_g -= 1;
                end;
            }
            #region CURRENT STEP 1
            action(ChangeWorkingLocationCode)
            {
                ApplicationArea = All;
                Caption = 'Change Location';
                Enabled = CurrentStep_g = 1;
                Visible = CurrentStep_g = 1;
                InFooterBar = true;
                trigger OnAction()
                begin
                    ChangeLocationCodeRep.SetUserID(UserSetupRec."User ID");
                    if UserSetupRec."SME073 Working Location" <> '' then begin
                        ChangeLocationCodeRep.SetLocationCode(UserSetupRec."SME073 Working Location");
                    end;
                    ChangeLocationCodeRep.Run();

                    UserSetupRec.Get(UserId);
                    CurrLocationCode_g := UserSetupRec."SME073 Working Location";
                    Clear(TransferToBinCode_g);
                end;
            }
            #endregion CURRENT STEP 1
            #region CURRENT STEP 2
            action(Rescan)
            {
                ApplicationArea = All;
                Caption = 'Re-Scan';
                InFooterBar = true;
                Enabled = CurrentStep_g = 2;
                Visible = CurrentStep_g = 2;
                trigger OnAction()
                begin
                    if Confirm('All scanned data will be deleted. Continue?', true) then begin
                        DeleteAllUnnecessaryLine(Rec);
                        ResetAllInternalTransferControl();
                    end;
                end;
            }
            action(Save)
            {
                ApplicationArea = All;
                Caption = 'Save';
                InFooterBar = true;
                Image = Save;
                Enabled = CurrentStep_g = 2;
                Visible = CurrentStep_g = 2;
                trigger OnAction()
                var
                    PkgNoInfoRec: Record "Package No. Information";
                begin
                    PkgNoInfoRec.Reset();
                    PkgNoInfoRec.SetRange("Item No.", ItemNoCode_g);
                    PkgNoInfoRec.SetRange("Variant Code", VariantCode_g);
                    PkgNoInfoRec.SetRange("Package No.", BaleNoCode_g);
                    PkgNoInfoRec.SetRange("Location Filter", CurrLocationCode_g);
                    PkgNoInfoRec.SetAutoCalcFields("PMP04 Bin Code");
                    // PkgNoInfoRec.SetRange("PMP04 Bin Code", FromBinCode_g);
                    if PkgNoInfoRec.FindFirst() then begin
                        AddRecordPkgNo__List(Rec, PkgNoInfoRec);
                    end;

                    ResetAllInternalTransferControl();
                end;
            }
            action(Post)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Image = Post;
                InFooterBar = true;
                Enabled = CurrentStep_g = 2;
                Visible = CurrentStep_g = 2;
                trigger OnAction()
                var
                    PkgNoInfoRec: Record "Package No. Information";
                begin
                    Rec.Reset();
                    Rec.SetRange("Dest. Bin Code", TransferToBinCode_g);
                    Rec.SetRange("User ID", UserId());
                    if Rec.FindSet() then begin
                        repeat
                            if Rec."Curr. Bin Code" = TransferToBinCode_g then begin
                                continue;
                            end;

                            if TobaccoBalesWhseTFMgmt.PostInternalTransferItemReclass(ItemJnlLine, Rec, UserSetupRec, TransferToBinCode_g) then begin
                                Rec.Delete();
                                Commit();
                            end else
                                NotifyUserFailedPosting();
                        until Rec.Next() = 0;

                        ResetAllInternalTransferControl();
                        Message('The Reclassification Journal is successfully posted.');
                        NotifyUserSuccessPosting();
                    end;
                end;
            }
            #endregion CURRENT STEP 2
            action(Next)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = CurrentStep_g < MaxNavigatePage_g;
                Visible = CurrentStep_g < MaxNavigatePage_g;
                InFooterBar = true;
                Image = NextRecord;
                trigger OnAction()
                begin
                    if CurrentStep_g = 1 then begin
                        if TransferToBinCode_g = '' then
                            Error('Please fill the destination Bin Code to transfer, this field should not be empty');
                        TobaccoBalesTF_TextCaption := StrSubstNo('Internal Transfer | %1', TransferToBinCode_g);
                        TextCaption_StyleExprTxt := 'strong';

                        DeleteAllUnnecessaryLine(Rec);

                        Rec.Reset();
                        Rec.SetRange("Dest. Bin Code", TransferToBinCode_g);
                        Rec.SetRange("User ID", UserId());
                    end;

                    CurrentStep_g += 1;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Clear(PMPAppLogicMgmt);
        ExtCompanySetup.Get();
        PMPAppLogicMgmt.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Gen. Int. Tf. Jnl. Tmpt"));
        PMPAppLogicMgmt.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Gen. Int. Tf. Jnl. Batch"));
        // PMPAppLogicMgmt.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Internal Transfer RC"));
        UserSetupRec.Get(UserId);
        CurrLocationCode_g := UserSetupRec."SME073 Working Location";
        Clear(TransferToBinCode_g);
        Clear(FromBinCode_g);
        Clear(TobaccoBalesTF_TextCaption);
        Clear(TextCaption_StyleExprTxt);
        Clear(ItemNoCode_g);
        Clear(ItemDescription_g);
        Clear(VariantCode_g);
        Clear(LotNoCode_g);
        Clear(BaleNoCode_g);
        Clear(UnitofMeasureCode_g);
        Clear(InventoryQty_g);

        CurrentStep_g := 1;
        MaxNavigatePage_g := 2;
    end;

    #region GLOBAL VARIABLE
    var
        ChangeLocationCodeRep: Report "PMP17 Change Working Loc. Code";
        TobaccoBalesWhseTFMgmt: Codeunit "PMP17 Tobacco Bales Whse. Tf.";
        UserSetupRec: Record "User Setup";
        PackageNoInfoRec: Record "Package No. Information";
        ItemJnlLine: Record "Item Journal Line";
        TextCaption_StyleExprTxt: Text;

    protected var
        PMPAppLogicMgmt: Codeunit "PMP02 App Logic Management";
        WeighingScaleMgmt: Codeunit "PMP19 Weighing Scale Mgt.";
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        InventoryQty_g: Decimal;
        MaxNavigatePage_g, CurrentStep_g : Integer;
        TobaccoBalesTF_TextCaption: Text;
        ItemNoCode_g, VariantCode_g, ItemDescription_g, LotNoCode_g, BaleNoCode_g, UnitofMeasureCode_g : Text;
        // BaleNoCode_g, LotNoCode_g : Code[50];
        TransferToBinCode_g, FromBinCode_g, CurrLocationCode_g : Code[20]; // ItemNoCode_g
                                                                           // VariantCode_g, UnitofMeasureCode_g : Code[10];
    #endregion GLOBAL VARIABLE

    #region GETTER
    local procedure GetLastEntryNo(var Rec: Record "PMP17 Tbco Internal Tansfer") LastEntryNo: Integer
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Entry No.");
        Rec.SetRange("User ID", UserId());
        Rec.SetAscending("Entry No.", true);

        if Rec.FindLast() then begin
            LastEntryNo := Rec."Entry No.";
        end else begin
            LastEntryNo := 0;
        end;

        exit(LastEntryNo);
    end;
    #endregion GETTER

    #region SETTER
    // 
    #endregion SETTER


    #region HELPER
    local procedure ResetAllInternalTransferControl()
    begin
        ItemJnlLine.Reset();
        Clear(ItemNoCode_g);
        Clear(ItemDescription_g);
        Clear(VariantCode_g);
        Clear(LotNoCode_g);
        Clear(BaleNoCode_g);
        Clear(InventoryQty_g);
        Clear(UnitofMeasureCode_g);
        Clear(FromBinCode_g);
    end;

    local procedure DeleteAllUnnecessaryLine(var Rec: Record "PMP17 Tbco Internal Tansfer")
    begin
        Rec.Reset();
        Rec.SetRange("Dest. Bin Code", TransferToBinCode_g);
        Rec.SetRange("User ID", UserId());
        Rec.SetRange(Saved, false);
        Rec.DeleteAll();
        Commit();
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

    procedure ScanBarcode(BarcodeInput: Text; FieldReturn: Integer): Text
    var
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        PackageNoInfoRecLocal: Record "Package No. Information";
        DictOfBarcodeResult: Dictionary of [Text, Text];
        IsBarcodeSeparatorExist: Boolean;
    begin
        PackageNoInfoRecLocal.Reset();

        TobaccoBalesTF_TextCaption := StrSubstNo('Internal Transfer | %1', TransferToBinCode_g);
        TextCaption_StyleExprTxt := 'strong';

        if BarcodeInput <> '' then begin
            ExtCompanySetup.Get();
            ExtCompanySetup.TestField("PMP14 Barcode Separator");

            if BarcodeInput.Contains(ExtCompanySetup."PMP14 Barcode Separator") then begin
                IsBarcodeSeparatorExist := true;
                SplitBarcodeInput(BarcodeInput, ExtCompanySetup."PMP14 Barcode Separator", DictOfBarcodeResult);
                case FieldReturn of
                    1:
                        exit(ItemNoCode_g);
                    2:
                        exit(VariantCode_g);
                    3:
                        exit(LotNoCode_g);
                    4:
                        exit(BaleNoCode_g);
                    5:
                        exit(UnitofMeasureCode_g);
                end;
            end else begin
                IsBarcodeSeparatorExist := false;
                if not GetPackageNoInfo_ByPackNo(BarcodeInput) then begin
                    PackageNoInfoRecLocal.SetRange("Item No.", ItemNoCode_g);
                    PackageNoInfoRecLocal.SetRange("Variant Code", VariantCode_g);
                    PackageNoInfoRecLocal.SetRange("Package No.", BarcodeInput);
                    PackageNoInfoRecLocal.SetRange("Location Filter", CurrLocationCode_g);
                    if PackageNoInfoRecLocal.FindFirst() then begin
                        PackageNoInfoRecLocal.CalcFields(Inventory, "PMP04 Lot No.");
                        LotNoCode_g := PackageNoInfoRecLocal."PMP04 Lot No.";
                        InventoryQty_g := PackageNoInfoRecLocal.Inventory;
                    end;
                end;
                //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/05/26 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
                case FieldReturn of
                    1:
                        exit(ItemNoCode_g);
                    2:
                        exit(VariantCode_g);
                    3:
                        exit(LotNoCode_g);
                    4:
                        exit(BaleNoCode_g);
                    5:
                        exit(UnitofMeasureCode_g);
                end;
                // exit(BarcodeInput);
                //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/05/26 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
            end;
        end;
    end;

    local procedure SplitBarcodeInput(BarcodeInput: Text; Separator: Text; var DictOfBarcodeResult: Dictionary of [Text, Text])
    var
        BarcodeInputSplitList: List of [Text];
        ItemRecLocal: Record Item;
        PackageNoInfoRecLocal: Record "Package No. Information";
        BinContentRecLocal: Record "Bin Content";
    begin
        ItemRecLocal.Reset();
        PackageNoInfoRecLocal.Reset();
        Clear(BarcodeInputSplitList);

        BarcodeInputSplitList := BarcodeInput.Split(Separator);

        ItemNoCode_g := BarcodeInputSplitList.Get(1);
        if ItemRecLocal.Get(ItemNoCode_g) then begin
            ItemDescription_g := ItemRecLocal.Description;
        end;
        VariantCode_g := BarcodeInputSplitList.Get(2);
        LotNoCode_g := BarcodeInputSplitList.Get(3);
        BaleNoCode_g := BarcodeInputSplitList.Get(4);
        UnitofMeasureCode_g := BarcodeInputSplitList.Get(5);

        PackageNoInfoRecLocal.SetRange("Item No.", ItemNoCode_g);
        PackageNoInfoRecLocal.SetRange("Variant Code", VariantCode_g);
        PackageNoInfoRecLocal.SetRange("Package No.", BaleNoCode_g);
        PackageNoInfoRecLocal.SetRange("Location Filter", CurrLocationCode_g);
        PackageNoInfoRecLocal.SetAutoCalcFields(Inventory);
        PackageNoInfoRecLocal.SetFilter(Inventory, '>0');
        if PackageNoInfoRecLocal.FindFirst() then begin
            PackageNoInfoRecLocal.CalcFields(Inventory);
            InventoryQty_g := PackageNoInfoRecLocal.Inventory;

            BinContentRecLocal.Reset();
            BinContentRecLocal.SetRange("Location Code", CurrLocationCode_g);
            BinContentRecLocal.SetRange("Item No.", ItemNoCode_g);
            BinContentRecLocal.SetRange("Variant Code", VariantCode_g);
            BinContentRecLocal.SetRange("Unit of Measure Code", UnitofMeasureCode_g);
            BinContentRecLocal.SetRange("Lot No. Filter", LotNoCode_g);
            BinContentRecLocal.SetRange("Package No. Filter", BaleNoCode_g);
            BinContentRecLocal.SetAutoCalcFields(Quantity, "Quantity (Base)");
            BinContentRecLocal.SetFilter(Quantity, '> 0');
            if BinContentRecLocal.Count = 1 then begin
                BinContentRecLocal.FindFirst();
                FromBinCode_g := BinContentRecLocal."Bin Code";
            end else
                Clear(FromBinCode_g);
        end;
    end;

    /// <summary> Retrieves the Package No. Information record for the specified parameters. </summary>
    /// <param name="PackageNo">The Package No. to filter by.</param>
    /// <param name="PackageNoInformation">The record passed by reference to store the retrieved line.</param>
    local procedure GetPackageNoInfo_ByPackNo(PackageNo: Code[50]): Boolean
    var
        PackageNoInfoRecLocal: Record "Package No. Information";
        ItemRecLocal: Record Item;
    begin
        ItemRecLocal.Reset();
        PackageNoInfoRecLocal.SetRange("Package No.", PackageNo);
        PackageNoInfoRecLocal.SetFilter(Inventory, '>%1', 0);
        if PackageNoInfoRecLocal.FindFirst() then begin
            PackageNoInfoRecLocal.CalcFields("PMP04 Lot No.");
            ItemNoCode_g := PackageNoInfoRecLocal."Item No.";
            if ItemRecLocal.Get(ItemNoCode_g) then begin
                ItemDescription_g := ItemRecLocal.Description;
                UnitofMeasureCode_g := ItemRecLocal."Base Unit of Measure";
            end;
            VariantCode_g := PackageNoInfoRecLocal."Variant Code";
            LotNoCode_g := PackageNoInfoRecLocal."PMP04 Lot No.";
            BaleNoCode_g := PackageNoInfoRecLocal."Package No.";
            InventoryQty_g := PackageNoInfoRecLocal.Inventory;
            exit(true);
        end;
        exit(false);
    end;

    procedure AddRecordPkgNo__List(var Rec: Record "PMP17 Tbco Internal Tansfer" temporary; var PkgNoInfoRec: Record "Package No. Information")
    var
        ItemRec: Record Item;
        LastEntryNo: Integer;
    begin
        Clear(LastEntryNo);
        ItemRec.Reset();
        PkgNoInfoRec.CalcFields(Inventory, "PMP04 Bin Code", "PMP04 Lot No.");

        Rec.Reset();
        Rec.SetRange("Package No.", PkgNoInfoRec."Package No.");
        Rec.SetRange("Item No.", PkgNoInfoRec."Item No.");
        Rec.SetRange("Variant Code", PkgNoInfoRec."Variant Code");
        Rec.SetRange("Curr. Location Code", CurrLocationCode_g);
        Rec.SetRange("Curr. Bin Code", FromBinCode_g);
        Rec.SetRange("Dest. Bin Code", TransferToBinCode_g);
        Rec.SetRange("Lot No.", LotNoCode_g);
        Rec.SetRange("Unit of Measure", UnitofMeasureCode_g);
        if Rec.FindFirst() then begin
            Rec.Delete();
            Commit();
        end;

        Rec.Reset(); // penting
        LastEntryNo := GetLastEntryNo(Rec);
        Rec.Init();
        Rec."Entry No." := LastEntryNo + 1;
        Rec."User ID" := UserId();
        Rec."Package No." := PkgNoInfoRec."Package No.";
        Rec."Item No." := PkgNoInfoRec."Item No.";
        Rec."Variant Code" := PkgNoInfoRec."Variant Code";
        Rec.CalcFields("Description", "Sub Merk 1", "Sub Merk 2", "Sub Merk 3", "Sub Merk 4", "Sub Merk 5");
        Rec."Lot No." := LotNoCode_g;
        Rec."Curr. Location Code" := CurrLocationCode_g;
        Rec."Curr. Bin Code" := FromBinCode_g;
        Rec."Dest. Bin Code" := TransferToBinCode_g;
        Rec.Quantity := InventoryQty_g;
        ItemRec.Get(Rec."Item No.");
        Rec."Base Unit of Measure" := ItemRec."Base Unit of Measure";
        Rec."Unit of Measure" := UnitofMeasureCode_g;
        Rec.Insert();
        Commit();
    end;
    #endregion HELPER

}
