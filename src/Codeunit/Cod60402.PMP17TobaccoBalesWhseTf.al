codeunit 60402 "PMP17 Tobacco Bales Whse. Tf."
{
    // version PMP17 

    // List Modification
    // Version List       Name
    // ==================================================================================================
    // PMP17              ID Localization

    // Codeunit
    // Date        Developer  Version List  Trigger              Description
    // ==================================================================================================
    // 2025/11/21  SW         PMP17         -                    Create codeunit

    var
        PMPAppLogic: Codeunit "PMP02 App Logic Management";
        NoSeriesMgt: Codeunit "No. Series";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        // ItemJnlPostLineMgmt: Codeunit "Item Jnl.-Post Line";
        ItemJnlPostBatchMgmt: Codeunit "Item Jnl.-Post Batch";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        ReleaseAssemblyDocMgmt: Codeunit "Release Assembly Document";
        AssemblyPostMgmt: Codeunit "Assembly-Post";
        ItemTrackingLine: Page "Item Tracking Lines";
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        TempGlobalReservEntry: Record "Reservation Entry" temporary;
        TempGlobalEntrySummary: Record "Entry Summary" temporary;
        ItemTrackingCode: Record "Item Tracking Code";
        CurrItemTrackingCode: Record "Item Tracking Code";
        LastSummaryEntryNo, LastTrackingSpecEntryNo : Integer;
        CurrBinCode: Code[20];
        FullGlobalDataSetExists: Boolean;
        SkipLot: Boolean;
        DirectTransfer: Boolean;
        HideValidationDialog: Boolean;

    #region TOBACCO BALES TRANSFER
    ///<summary>Updates the bin content quantity in the entry summary based on related warehouse entries.</summary>
    local procedure UpdateBinContent(var TempEntrySummary: Record "Entry Summary" temporary)
    var
        WarehouseEntry: Record "Warehouse Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        if CurrBinCode = '' then
            exit;

        CurrItemTrackingCode.TestField(Code);

        WarehouseEntry.Reset();
        WarehouseEntry.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Variant Code",
          "Unit of Measure Code", "Lot No.", "Serial No.", "Package No.");
        WarehouseEntry.SetRange("Item No.", TempGlobalReservEntry."Item No.");
        WarehouseEntry.SetRange("Bin Code", CurrBinCode);
        WarehouseEntry.SetRange("Location Code", TempGlobalReservEntry."Location Code");
        WarehouseEntry.SetRange("Variant Code", TempGlobalReservEntry."Variant Code");
        WhseItemTrackingSetup.CopyTrackingFromItemTrackingCodeWarehouseTracking(CurrItemTrackingCode);
        WhseItemTrackingSetup.CopyTrackingFromEntrySummary(TempEntrySummary);
        WarehouseEntry.SetTrackingFilterFromItemTrackingSetupIfRequiredIfNotBlank(WhseItemTrackingSetup);

        WarehouseEntry.CalcSums("Qty. (Base)");

        TempEntrySummary."Bin Content" := WarehouseEntry."Qty. (Base)";
    end;

    ///<summary>Builds or aggregates entry summary data for serial or non-serial tracked items derived from reservation entry details.</summary>
    local procedure CreateEntrySummary2(TempTrackingSpecification: Record "Tracking Specification" temporary; TempReservEntry: Record "Reservation Entry" temporary; SerialNoLookup: Boolean)
    var
        LateBindingManagement: Codeunit "Late Binding Management";
        DoInsert: Boolean;
    begin
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetTrackingKey();

        if SerialNoLookup then begin
            if TempReservEntry."Serial No." = '' then
                exit;

            TempGlobalEntrySummary.SetTrackingFilterFromReservEntry(TempReservEntry);
        end else begin
            if not TempReservEntry.NonSerialTrackingExists() then
                exit;

            TempGlobalEntrySummary.SetRange("Serial No.", '');
            TempGlobalEntrySummary.SetNonSerialTrackingFilterFromReservEntry(TempReservEntry);
            if TempReservEntry."Serial No." <> '' then
                TempGlobalEntrySummary.SetRange("Table ID", 0)
            else
                TempGlobalEntrySummary.SetFilter("Table ID", '<>%1', 0);
        end;

        // If no summary exists, create new record
        if not TempGlobalEntrySummary.FindFirst() then begin
            TempGlobalEntrySummary.Init();
            TempGlobalEntrySummary."Entry No." := LastSummaryEntryNo + 1;
            LastSummaryEntryNo := TempGlobalEntrySummary."Entry No.";

            if not SerialNoLookup and (TempReservEntry."Serial No." <> '') then
                TempGlobalEntrySummary."Table ID" := 0 // Mark as summation
            else
                TempGlobalEntrySummary."Table ID" := TempReservEntry."Source Type";
            if SerialNoLookup then
                TempGlobalEntrySummary."Serial No." := TempReservEntry."Serial No."
            else
                TempGlobalEntrySummary."Serial No." := '';
            TempGlobalEntrySummary."Lot No." := TempReservEntry."Lot No.";
            TempGlobalEntrySummary."Package No." := TempReservEntry."Package No.";
            TempGlobalEntrySummary."Non Serial Tracking" := TempGlobalEntrySummary.HasNonSerialTracking();
            TempGlobalEntrySummary."Bin Active" := CurrBinCode <> '';
            UpdateBinContent(TempGlobalEntrySummary);

            DoInsert := true;
        end;

        // Sum up values
        if TempReservEntry.Positive then begin
            TempGlobalEntrySummary."Warranty Date" := TempReservEntry."Warranty Date";
            TempGlobalEntrySummary."Expiration Date" := TempReservEntry."Expiration Date";
            if TempReservEntry."Entry No." < 0 then begin // The record represents an Item ledger entry
                TempGlobalEntrySummary."Non-specific Reserved Qty." +=
                  LateBindingManagement.NonSpecificReservedQtyExceptForSource(-TempReservEntry."Entry No.", TempTrackingSpecification);
                TempGlobalEntrySummary."Total Quantity" += TempReservEntry."Quantity (Base)";
            end;
            if TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Reservation then
                TempGlobalEntrySummary."Total Reserved Quantity" += TempReservEntry."Quantity (Base)";
        end else begin
            TempGlobalEntrySummary."Total Requested Quantity" -= TempReservEntry."Quantity (Base)";
            if TempReservEntry.HasSamePointerWithSpec(TempTrackingSpecification) then begin
                if TempReservEntry."Reservation Status" = TempReservEntry."Reservation Status"::Reservation then
                    TempGlobalEntrySummary."Current Reserved Quantity" -= TempReservEntry."Quantity (Base)";
                if TempReservEntry."Entry No." > 0 then // The record represents a reservation entry
                    TempGlobalEntrySummary."Current Requested Quantity" -= TempReservEntry."Quantity (Base)";
            end;
        end;

        // Update available quantity on the record
        TempGlobalEntrySummary.UpdateAvailable();
        if DoInsert then
            TempGlobalEntrySummary.Insert()
        else
            TempGlobalEntrySummary.Modify();
    end;

    /// <summary>Transfers item ledger tracking information into a temporary tracking specification record.</summary>
    /// <remarks>This procedure processes Item Ledger Entries containing tracking data and creates temporary reservation entries along with an entry summary for further tracking handling.</remarks>
    /// <param name="ItemLedgEntry">The Item Ledger Entry record to be evaluated and transferred.</param>
    /// <param name="TrackingSpecification">The temporary Tracking Specification record used to store processed tracking details.</param>
    procedure TransferItemLedgToTempRec(var ItemLedgEntry: Record "Item Ledger Entry"; var TrackingSpecification: Record "Tracking Specification" temporary)
    var
        IsHandled: Boolean;
    begin
        ItemLedgEntry.SetLoadFields(
          "Entry No.", "Item No.", "Variant Code", Positive, "Location Code", "Serial No.", "Lot No.", "Package No.",
          "Remaining Quantity", "Warranty Date", "Expiration Date");

        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry.TrackingExists() and
                   not TempGlobalReservEntry.Get(-ItemLedgEntry."Entry No.", ItemLedgEntry.Positive)
                then begin
                    TempGlobalReservEntry.Init();
                    TempGlobalReservEntry."Entry No." := -ItemLedgEntry."Entry No.";
                    TempGlobalReservEntry."Reservation Status" := TempGlobalReservEntry."Reservation Status"::Surplus;
                    TempGlobalReservEntry.Positive := ItemLedgEntry.Positive;
                    TempGlobalReservEntry."Item No." := ItemLedgEntry."Item No.";
                    TempGlobalReservEntry."Variant Code" := ItemLedgEntry."Variant Code";
                    TempGlobalReservEntry."Location Code" := ItemLedgEntry."Location Code";
                    TempGlobalReservEntry."Quantity (Base)" := ItemLedgEntry."Remaining Quantity";
                    TempGlobalReservEntry."Source Type" := Database::"Item Ledger Entry";
                    TempGlobalReservEntry."Source Ref. No." := ItemLedgEntry."Entry No.";
                    TempGlobalEntrySummary."Package No." := ItemLedgEntry."Package No.";
                    TempGlobalReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgEntry);
                    if TempGlobalReservEntry.Positive then begin
                        TempGlobalReservEntry."Warranty Date" := ItemLedgEntry."Warranty Date";
                        TempGlobalReservEntry."Expiration Date" := ItemLedgEntry."Expiration Date";
                        TempGlobalReservEntry."Expected Receipt Date" := 0D
                    end else
                        TempGlobalReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);

                    IsHandled := false;
                    if not IsHandled then begin
                        TempGlobalReservEntry.Insert();
                        CreateEntrySummary(TrackingSpecification, TempGlobalReservEntry);
                    end;
                end;
            until ItemLedgEntry.Next() = 0;
    end;

    ///<summary>Creates or updates entry summary records based on the provided tracking specification and reservation entry.</summary>
    local procedure CreateEntrySummary(TrackingSpecification: Record "Tracking Specification" temporary; TempReservEntry: Record "Reservation Entry" temporary)
    begin
        CreateEntrySummary2(TrackingSpecification, TempReservEntry, true);
        CreateEntrySummary2(TrackingSpecification, TempReservEntry, false);
    end;

    ///<summary>Collects tracking source data from item ledger and reservation entries to initialize temporary tracking structures.</summary>
    local procedure RetrieveLookupData(var TempTrackingSpecification: Record "Tracking Specification" temporary; FullDataSet: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
        LotNo, PackageNo : Code[50];
    begin
        // Reset Item Tracking Line Generator
        LastSummaryEntryNo := 0;
        // LastReservEntryNo := 2147483647;
        TempTrackingSpecification2 := TempTrackingSpecification;
        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.DeleteAll();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.DeleteAll();

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Entry No.");
        ItemLedgEntry.SetRange("Item No.", TempTrackingSpecification."Item No.");
        ItemLedgEntry.SetRange("Variant Code", TempTrackingSpecification."Variant Code");
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange("Location Code", TempTrackingSpecification."Location Code");

        LotNo := '';
        PackageNo := '';
        TransferItemLedgToTempRec(ItemLedgEntry, TempTrackingSpecification);

        TempGlobalEntrySummary.Reset();
        TempTrackingSpecification := TempTrackingSpecification2;
    end;

    /// <summary> <b>Creates</b> and inserts a temporary <b>Item Journal Line</b> for an internal transfer based on Package No. Information, user working location, and configured internal transfer journal setup. </summary>
    /// <remarks> This procedure prepares a transfer-type Item Journal Line in a temporary buffer by determining the next available line number, initializing journal template and batch settings from Extended Company Setup, assigning document and posting dates, resolving item and unit of measure, and populating quantity, bin transfer, reason code, and custom sub-merk fields before inserting the record. </remarks>
    /// <param name="tempItemJnlLine"> <b>Temporary Item Journal</b> Line record that will be initialized and inserted. </param>
    /// <param name="PackageNoInfoRec"> <b>Package No. Information</b> record providing item, variant, bin, lot, inventory quantity, and sub-merk details. </param>
    /// <param name="UserSetupRec"> <b>User Setup</b> record used to determine the working location for the transfer. </param>
    /// <param name="TransferToBinCode"> <b>Destination bin code</b> for the item transfer. </param>
    /// <returns> Returns true if the Item Journal Line is successfully inserted; otherwise, false. </returns>
    procedure Test_InsertItemJnlLine(var tempItemJnlLine: Record "Item Journal Line" temporary; PackageNoInfoRec: Record "Package No. Information"; UserSetupRec: Record "User Setup"; TransferToBinCode: Code[50]): Boolean
    var
        Item: Record Item;
        IJL: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        LastLineNo: Integer;
    begin
        PackageNoInfoRec.CalcFields(Inventory, "PMP04 Bin Code", "PMP04 Lot No.");
        Item.Reset();
        IJL.Reset();
        ItemJnlTemplate.Reset();
        ItemJnlBatch.Reset();
        ExtCompanySetup.Get();

        IJL.SetRange("Journal Template Name", ExtCompanySetup."PMP17 Int. Tf. Jnl. Tmpt. Name");
        IJL.SetRange("Journal Batch Name", ExtCompanySetup."PMP17 Int. Tf. Jnl. Batch Name");
        if IJL.FindLast() then
            LastLineNo := IJL."Line No.";

        if LastLineNo mod 10000 > 0 then begin
            LastLineNo += LastLineNo mod 10000;
        end else begin
            LastLineNo += 10000;
        end;

        ItemJnlTemplate.Get(ExtCompanySetup."PMP17 Int. Tf. Jnl. Tmpt. Name");
        ItemJnlBatch.Get(ExtCompanySetup."PMP17 Int. Tf. Jnl. Tmpt. Name", ExtCompanySetup."PMP17 Int. Tf. Jnl. Batch Name");

        tempItemJnlLine.Init();
        tempItemJnlLine."Journal Template Name" := ItemJnlTemplate.Name;
        tempItemJnlLine."Journal Batch Name" := ItemJnlBatch.Name;
        tempItemJnlLine."Line No." := LastLineNo;
        tempItemJnlLine."Source Code" := ItemJnlTemplate."Source Code";
        tempItemJnlLine.Validate("Entry Type", tempItemJnlLine."Entry Type"::Transfer);
        // tempItemJnlLine.SetUpNewLine(IJL);

        tempItemJnlLine.Validate("Document Date", Today);
        tempItemJnlLine.Validate("Posting Date", Today);

        if ItemJnlBatch."No. Series" <> '' then begin
            Clear(NoSeriesMgt);
            tempItemJnlLine."Document No." := NoSeriesMgt.PeekNextNo(ItemJnlBatch."No. Series", tempItemJnlLine."Posting Date");
        end;

        tempItemJnlLine.Validate("Item No.", PackageNoInfoRec."Item No.");
        tempItemJnlLine.Validate("Variant Code", PackageNoInfoRec."Variant Code");
        tempItemJnlLine.Validate("Location Code", UserSetupRec."SME073 Working Location");
        tempItemJnlLine.Validate("New Location Code", UserSetupRec."SME073 Working Location");
        Item.Get(TempItemJnlLine."Item No.");
        tempItemJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        tempItemJnlLine.Validate(Quantity, PackageNoInfoRec.Inventory);
        tempItemJnlLine.Validate("Bin Code", PackageNoInfoRec."PMP04 Bin Code");
        tempItemJnlLine.Validate("New Bin Code", TransferToBinCode);
        // tempItemJnlLine."Package No." := PackageNoInfoRec."Package No.";
        // tempItemJnlLine."Lot No." := PackageNoInfoRec."PMP04 Lot No.";
        tempItemJnlLine.Validate("Reason Code", ExtCompanySetup."PMP17 Tobacco Tf. Reason Code");
        tempItemJnlLine."PMP15 Sub Merk 1" := PackageNoInfoRec."PMP04 Sub Merk 1";
        tempItemJnlLine."PMP15 Sub Merk 2" := PackageNoInfoRec."PMP04 Sub Merk 2";
        tempItemJnlLine."PMP15 Sub Merk 3" := PackageNoInfoRec."PMP04 Sub Merk 3";
        tempItemJnlLine."PMP15 Sub Merk 4" := PackageNoInfoRec."PMP04 Sub Merk 4";
        tempItemJnlLine."PMP15 Sub Merk 5" := PackageNoInfoRec."PMP04 Sub Merk 5";
        if tempItemJnlLine.Insert() then
            exit(true)
        else
            exit(false);
    end;

    /// <summary> Generates <b>reservation entries</b> for an <b>Item Journal Line</b> reclassification based on <b>item tracking</b>, <b>package information</b>, and <b>destination bin</b> configuration. </summary>
    /// <remarks> This procedure first validates that <b>no existing reservation or tracking entries</b> exist for the provided Item Journal Line. It then ensures that the related <b>Item is configured with an Item Tracking Code</b>. A temporary <b>Tracking Specification</b> is initialized from the Item Journal Line and used to retrieve tracking data. Reservation entries are generated either from <b>temporary lookup results</b> or from <b>Package No. Information</b> records with <b>zero inventory</b>, depending on availability. This logic guarantees <b>item tracking integrity</b> during <b>internal transfer</b> or <b>reclassification</b> processes. </remarks>
    /// <param name="RecItemJnlLine"> The <b>Item Journal Line</b> for which reservation entries will be generated. </param>
    /// <param name="PackageNoInfoRec"> The <b>Package No. Information</b> record that provides <b>package, lot, and inventory</b> context. </param>
    /// <param name="UserSetupRec"> The <b>User Setup</b> record used to resolve <b>user-specific configuration</b>, such as working location. </param>
    /// <param name="TransferToBinCode"> The <b>destination bin code</b> where the item will be transferred. </param>
    /// <param name="TempTrackingSpecification"> A <b>temporary Tracking Specification</b> used to initialize and process <b>item tracking details</b>. </param>
    procedure GenerateRecReserveEntryItemJnlLine(var RecItemJnlLine: Record "Item Journal Line"; PackageNoInfoRec: Record "Package No. Information"; UserSetupRec: Record "User Setup"; TransferToBinCode: Code[50]; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        Item: Record Item;
        RecReservEntry: Record "Reservation Entry";
        TrackingSpecification: Record "Tracking Specification";
        PackageNoInfo: Record "Package No. Information";
    begin
        // Clear(SerLotPkgArr);

        if RecItemJnlLine.ReservEntryExist() then
            Error('Item tracking information already exists for this reclassification journal line. Please remove the existing tracking before proceeding.');

        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(RecItemJnlLine."Item No.") then
            Error('The specified Item No. "%1" could not be found. Please verify that the item exists in the system.', RecItemJnlLine."Item No.");

        if Item."Item Tracking Code" = '' then
            Error('The Item "%1" does not have an assigned Item Tracking Code. Please configure the Item Tracking Code in the Item Card before continuing.', RecItemJnlLine."Item No.");

        if ItemJnlLineReserve.ReservEntryExist(RecItemJnlLine) then
            Error('Reservation entries already exist for Item "%1" in this reclassification journal line. Please cancel or delete the existing reservations before performing this action.', RecItemJnlLine."Item No.");

        ItemJnlLineReserve.InitFromItemJnlLine(TempTrackingSpecification, RecItemJnlLine);
        TempTrackingSpecification.Insert();

        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/09 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
        RetrieveLookupData(TempTrackingSpecification, true);
        TempTrackingSpecification.Delete();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetFilter("Lot No.", RecItemJnlLine."Lot No.");
        TempGlobalEntrySummary.SetFilter("Package No.", PackageNoInfoRec."Package No.");
        if TempGlobalEntrySummary.FindSet() then begin
            // SerLotPkgArr[1] := TempGlobalEntrySummary."Serial No.";
            // SerLotPkgArr[2] := TempGlobalEntrySummary."Lot No.";
            // SerLotPkgArr[3] := TempGlobalEntrySummary."Package No.";
            InsertReservEntryRecfromTempTrackSpecIJL(RecReservEntry, TempTrackingSpecification, RecItemJnlLine, UserSetupRec, TransferToBinCode, TempGlobalEntrySummary);
        end else begin
            PackageNoInfo.SetAutoCalcFields();
            PackageNoInfo.SetRange("Item No.", RecItemJnlLine."Item No.");
            PackageNoInfo.SetFilter("Variant Code", RecItemJnlLine."Variant Code");
            PackageNoInfo.SetFilter("Package No.", PackageNoInfoRec."Package No.");
            PackageNoInfo.SetFilter("PMP04 Lot No.", PackageNoInfoRec."PMP04 Lot No.");
            PackageNoInfo.SetRange(Inventory, 0);
            if PackageNoInfo.FindFirst() then begin
                // SerLotPkgArr[1] := '';
                // SerLotPkgArr[2] := PackageNoInfo."PMP04 Lot No.";
                // SerLotPkgArr[3] := PackageNoInfo."Package No.";
                InsertReservEntryRecfromTempTrackSpecIJL(RecReservEntry, TempTrackingSpecification, RecItemJnlLine, UserSetupRec, TransferToBinCode, PackageNoInfo);
            end;
        end;
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/09 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
    end;

    //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/09 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
    ///<summary>Creates and inserts a Reservation Entry from temporary tracking and journal line data based on sortation and tracking specifications</summary>
    local procedure InsertReservEntryRecfromTempTrackSpecIJL(var RecReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var RecItemJnlLine: Record "Item Journal Line"; UserSetupRec: Record "User Setup"; TransferToBinCode: Code[50]; TempEntrySummary: Record "Entry Summary" temporary)
    var
        TypeHelper: Codeunit "Type Helper";
        SourceTrackingSpecification: Record "Tracking Specification";
        Item: Record Item;
        RecRef: RecordRef;
        RunMode: Enum "Item Tracking Run Mode";
        ChangeType: Option Insert,Modify,FullDelete,PartDelete,ModifyAll;
    begin
        Item.Get(RecItemJnlLine."Item No.");
        RecRef.GetTable(Item);
        if Item."Item Tracking Code" = '' then
            PMPAppLogic.ErrorRecordRefwithAction(RecRef, Item.FieldNo("Item Tracking Code"), Page::"Item Card", 'Empty Field', StrSubstNo('The Item "%1" does not have an assigned Item Tracking Code. Please configure the Item Tracking Code in the Item Card before continuing.', Item."No."));

        ItemJnlLineReserve.InitFromItemJnlLine(SourceTrackingSpecification, RecItemJnlLine);
        ItemTrackingLine.SetSourceSpec(SourceTrackingSpecification, 0D);
        if RecItemJnlLine."Entry Type" = RecItemJnlLine."Entry Type"::Transfer then begin
            ItemTrackingLine.SetRunMode(RunMode::Reclass);
        end;

        TempTrackingSpecification.Init;
        TempTrackingSpecification."Entry No." := NextTrackingSpecEntryNo(); // set entry no.
        TempTrackingSpecification.TransferFields(SourceTrackingSpecification);
        TempTrackingSpecification.SetItemData(SourceTrackingSpecification."Item No.", SourceTrackingSpecification.Description, SourceTrackingSpecification."Location Code", SourceTrackingSpecification."Variant Code", SourceTrackingSpecification."Bin Code", SourceTrackingSpecification."Qty. per Unit of Measure");
        TempTrackingSpecification.Validate("Item No.", SourceTrackingSpecification."Item No.");
        TempTrackingSpecification.Validate("Location Code", SourceTrackingSpecification."Location Code");
        // TempTrackingSpecification.Validate("Creation Date", Today);
        TempTrackingSpecification.Validate("Creation Date", DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone()));
        TempTrackingSpecification.Validate("Source Type", SourceTrackingSpecification."Source Type");
        TempTrackingSpecification.Validate("Source Subtype", SourceTrackingSpecification."Source Subtype");
        TempTrackingSpecification.Validate("Source ID", SourceTrackingSpecification."Source ID");
        TempTrackingSpecification.Validate("Source Batch Name", SourceTrackingSpecification."Source Batch Name");
        TempTrackingSpecification.Validate("Source Prod. Order Line", SourceTrackingSpecification."Source Prod. Order Line");
        TempTrackingSpecification.Validate("Source Ref. No.", SourceTrackingSpecification."Source Ref. No.");

        TempTrackingSpecification.Validate("Bin Code", RecItemJnlLine."Bin Code");
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
        // TempTrackingSpecification.Validate("Lot No.", RecItemJnlLine."Lot No.");
        // TempTrackingSpecification."Lot No." := RecItemJnlLine."Lot No.";

        // if SerLotPkgArr[1] <> '' then
        //     TempTrackingSpecification.Validate("Serial No.", SerLotPkgArr[1]);
        // if SerLotPkgArr[2] <> '' then
        //     TempTrackingSpecification.Validate("Lot No.", SerLotPkgArr[2]);
        // if SerLotPkgArr[3] <> '' then
        //     TempTrackingSpecification.Validate("Package No.", SerLotPkgArr[3]);

        // TempTrackingSpecification.Validate("Bin Code", TransferToBinCode);

        TempTrackingSpecification.Validate("Serial No.", TempEntrySummary."Serial No.");
        TempTrackingSpecification.Validate("Lot No.", TempEntrySummary."Lot No.");
        TempTrackingSpecification.Validate("Package No.", TempEntrySummary."Package No.");
        TempTrackingSpecification.Positive := true;

        // TempTrackingSpecification.Validate("Quantity (Base)", RecItemJnlLine."Quantity (Base)");
        // TempTrackingSpecification.Validate("Qty. to Handle (Base)", RecItemJnlLine."Quantity (Base)");
        // TempTrackingSpecification.Validate("Qty. to Invoice (Base)", RecItemJnlLine."Quantity (Base)");

        TempTrackingSpecification.Validate("Quantity (Base)", TempEntrySummary."Total Quantity");
        TempTrackingSpecification.Validate("Qty. to Handle (Base)", TempEntrySummary."Total Quantity");
        TempTrackingSpecification.Validate("Qty. to Invoice (Base)", TempEntrySummary."Total Quantity");
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
        ItemTrackingLine.RegisterChange(TempTrackingSpecification, TempTrackingSpecification, ChangeType::Insert, false);
        ItemTrackingLine.GetTrackingSpec(TempTrackingSpecification);
    end;

    #region REMOVED InsertReservEntryRecfromTempTrackSpecIJL() 
    // local procedure InsertReservEntryRecfromTempTrackSpecIJL(var RecReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var RecItemJnlLine: Record "Item Journal Line"; PackageNoInfoRec: Record "Package No. Information"; UserSetupRec: Record "User Setup"; TransferToBinCode: Code[50]; SerLotPkgArr: array[3] of Code[50])
    // var
    //     TypeHelper: Codeunit "Type Helper";
    //     SourceTrackingSpecification: Record "Tracking Specification";
    //     Item: Record Item;
    //     RecRef: RecordRef;
    //     RunMode: Enum "Item Tracking Run Mode";
    //     ChangeType: Option Insert,Modify,FullDelete,PartDelete,ModifyAll;
    // begin
    //     Item.Get(RecItemJnlLine."Item No.");
    //     RecRef.GetTable(Item);
    //     if Item."Item Tracking Code" = '' then
    //         PMPAppLogic.ErrorRecordRefwithAction(RecRef, Item.FieldNo("Item Tracking Code"), Page::"Item Card", 'Empty Field', StrSubstNo('The Item "%1" does not have an assigned Item Tracking Code. Please configure the Item Tracking Code in the Item Card before continuing.', Item."No."));

    //     ItemJnlLineReserve.InitFromItemJnlLine(SourceTrackingSpecification, RecItemJnlLine);
    //     ItemTrackingLine.SetSourceSpec(SourceTrackingSpecification, 0D);
    //     if RecItemJnlLine."Entry Type" = RecItemJnlLine."Entry Type"::Transfer then begin
    //         ItemTrackingLine.SetRunMode(RunMode::Reclass);
    //     end;

    //     TempTrackingSpecification.Init;
    //     TempTrackingSpecification."Entry No." := NextTrackingSpecEntryNo(); // set entry no.
    //     TempTrackingSpecification.TransferFields(SourceTrackingSpecification);
    //     TempTrackingSpecification.SetItemData(SourceTrackingSpecification."Item No.", SourceTrackingSpecification.Description, SourceTrackingSpecification."Location Code", SourceTrackingSpecification."Variant Code", SourceTrackingSpecification."Bin Code", SourceTrackingSpecification."Qty. per Unit of Measure");
    //     TempTrackingSpecification.Validate("Item No.", SourceTrackingSpecification."Item No.");
    //     TempTrackingSpecification.Validate("Location Code", SourceTrackingSpecification."Location Code");
    //     // TempTrackingSpecification.Validate("Creation Date", Today);
    //     TempTrackingSpecification.Validate("Creation Date", DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone()));
    //     TempTrackingSpecification.Validate("Source Type", SourceTrackingSpecification."Source Type");
    //     TempTrackingSpecification.Validate("Source Subtype", SourceTrackingSpecification."Source Subtype");
    //     TempTrackingSpecification.Validate("Source ID", SourceTrackingSpecification."Source ID");
    //     TempTrackingSpecification.Validate("Source Batch Name", SourceTrackingSpecification."Source Batch Name");
    //     TempTrackingSpecification.Validate("Source Prod. Order Line", SourceTrackingSpecification."Source Prod. Order Line");
    //     TempTrackingSpecification.Validate("Source Ref. No.", SourceTrackingSpecification."Source Ref. No.");

    //     TempTrackingSpecification.Validate("Bin Code", RecItemJnlLine."Bin Code");
    //     // TempTrackingSpecification.Validate("Lot No.", RecItemJnlLine."Lot No.");
    //     // TempTrackingSpecification."Lot No." := RecItemJnlLine."Lot No.";
    //     if SerLotPkgArr[1] <> '' then
    //         TempTrackingSpecification.Validate("Serial No.", SerLotPkgArr[1]);
    //     if SerLotPkgArr[2] <> '' then
    //         TempTrackingSpecification.Validate("Lot No.", SerLotPkgArr[2]);
    //     if SerLotPkgArr[3] <> '' then
    //         TempTrackingSpecification.Validate("Package No.", SerLotPkgArr[3]);
    //     //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
    //     // TempTrackingSpecification.Validate("Bin Code", TransferToBinCode);
    //     //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
    //     TempTrackingSpecification.Positive := true;

    //     TempTrackingSpecification.Validate("Quantity (Base)", RecItemJnlLine."Quantity (Base)");
    //     TempTrackingSpecification.Validate("Qty. to Handle (Base)", RecItemJnlLine."Quantity (Base)");
    //     TempTrackingSpecification.Validate("Qty. to Invoice (Base)", RecItemJnlLine."Quantity (Base)");
    //     ItemTrackingLine.RegisterChange(TempTrackingSpecification, TempTrackingSpecification, ChangeType::Insert, false);
    //     ItemTrackingLine.GetTrackingSpec(TempTrackingSpecification);
    // end;
    #endregion REMOVED InsertReservEntryRecfromTempTrackSpecIJL() 
    //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/09 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}

    //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
    ///<summary>Creates and inserts a Reservation Entry from temporary tracking and journal line data based on sortation and tracking specifications</summary>
    local procedure InsertReservEntryRecfromTempTrackSpecIJL(var RecReservEntry: Record "Reservation Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var RecItemJnlLine: Record "Item Journal Line"; UserSetupRec: Record "User Setup"; TransferToBinCode: Code[50]; PackageNoInfoRec: Record "Package No. Information")
    var
        TypeHelper: Codeunit "Type Helper";
        SourceTrackingSpecification: Record "Tracking Specification";
        Item: Record Item;
        RecRef: RecordRef;
        RunMode: Enum "Item Tracking Run Mode";
        ChangeType: Option Insert,Modify,FullDelete,PartDelete,ModifyAll;
    begin
        PackageNoInfoRec.CalcFields(Inventory);
        Item.Get(RecItemJnlLine."Item No.");
        RecRef.GetTable(Item);
        if Item."Item Tracking Code" = '' then
            PMPAppLogic.ErrorRecordRefwithAction(RecRef, Item.FieldNo("Item Tracking Code"), Page::"Item Card", 'Empty Field', StrSubstNo('The Item "%1" does not have an assigned Item Tracking Code. Please configure the Item Tracking Code in the Item Card before continuing.', Item."No."));

        ItemJnlLineReserve.InitFromItemJnlLine(SourceTrackingSpecification, RecItemJnlLine);
        ItemTrackingLine.SetSourceSpec(SourceTrackingSpecification, 0D);
        if RecItemJnlLine."Entry Type" = RecItemJnlLine."Entry Type"::Transfer then begin
            ItemTrackingLine.SetRunMode(RunMode::Reclass);
        end;

        TempTrackingSpecification.Init;
        TempTrackingSpecification."Entry No." := NextTrackingSpecEntryNo(); // set entry no.
        TempTrackingSpecification.TransferFields(SourceTrackingSpecification);
        TempTrackingSpecification.SetItemData(SourceTrackingSpecification."Item No.", SourceTrackingSpecification.Description, SourceTrackingSpecification."Location Code", SourceTrackingSpecification."Variant Code", SourceTrackingSpecification."Bin Code", SourceTrackingSpecification."Qty. per Unit of Measure");
        TempTrackingSpecification.Validate("Item No.", SourceTrackingSpecification."Item No.");
        TempTrackingSpecification.Validate("Location Code", SourceTrackingSpecification."Location Code");
        // TempTrackingSpecification.Validate("Creation Date", Today);
        TempTrackingSpecification.Validate("Creation Date", DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone()));
        TempTrackingSpecification.Validate("Source Type", SourceTrackingSpecification."Source Type");
        TempTrackingSpecification.Validate("Source Subtype", SourceTrackingSpecification."Source Subtype");
        TempTrackingSpecification.Validate("Source ID", SourceTrackingSpecification."Source ID");
        TempTrackingSpecification.Validate("Source Batch Name", SourceTrackingSpecification."Source Batch Name");
        TempTrackingSpecification.Validate("Source Prod. Order Line", SourceTrackingSpecification."Source Prod. Order Line");
        TempTrackingSpecification.Validate("Source Ref. No.", SourceTrackingSpecification."Source Ref. No.");

        TempTrackingSpecification.Validate("Bin Code", RecItemJnlLine."Bin Code");

        TempTrackingSpecification.Validate("Lot No.", PackageNoInfoRec."PMP04 Lot No.");
        TempTrackingSpecification.Validate("Package No.", PackageNoInfoRec."Package No.");
        TempTrackingSpecification.Positive := true;

        TempTrackingSpecification.Validate("Quantity (Base)", PackageNoInfoRec.Inventory);
        TempTrackingSpecification.Validate("Qty. to Handle (Base)", PackageNoInfoRec.Inventory);
        TempTrackingSpecification.Validate("Qty. to Invoice (Base)", PackageNoInfoRec.Inventory);
        ItemTrackingLine.RegisterChange(TempTrackingSpecification, TempTrackingSpecification, ChangeType::Insert, false);
        ItemTrackingLine.GetTrackingSpec(TempTrackingSpecification);
    end;
    //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}

    procedure InsertItemJnlLinefromTemp(var ItemJnlLine: Record "Item Journal Line"; var tempItemJnlLine: Record "Item Journal Line" temporary)
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ExtCompanySetup.Get();

        ItemJnlLine := tempItemJnlLine;
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07- START >>>>>>>>>>>>>>>>>>>>>>>>>>}
        if ItemJnlBatch.Get(ExtCompanySetup."PMP17 Int. Tf. Jnl. Tmpt. Name", ExtCompanySetup."PMP17 Int. Tf. Jnl. Batch Name") then begin
            if ItemJnlBatch."No. Series" <> '' then begin
                ItemJnlLine."Document No." := NoSeriesMgt.GetNextNo(ItemJnlBatch."No. Series", WorkDate());
            end else begin
                ItemJnlLine."Document No." := NoSeriesMgt.GetNextNo(ExtCompanySetup."PMP17 Int. Document Tf. Nos.", WorkDate());
            end;
        end;
        ItemJnlLine.Insert();
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07- FINISH>>>>>>>>>>>>>>>>>>>>>>>>>>}
    end;

    /// <summary> Executes a complete <b>tobacco bale transfer reclassification</b> by creating, tracking, and posting an <b>Item Reclassification Journal</b>. </summary>
    /// <remarks> This procedure orchestrates the full transfer flow starting from validating <b>Extended Company Setup</b> configuration, creating a <b>temporary Item Journal Line</b>, generating <b>reservation and tracking entries</b>, and finally posting the <b>Item Reclassification Journal</b>. The process ensures that <b>inventory, bin, lot, and package tracking</b> are handled consistently and safely before committing the transaction. </remarks>
    /// <param name="ItemJnlLine"> The resulting <b>Item Journal Line</b> that will be posted after transfer processing. </param>
    /// <param name="PackageNoInfoRec"> The <b>Package No. Information</b> record containing inventory, bin, and lot details of the tobacco bale to be transferred. </param>
    /// <param name="UserSetupRec"> The <b>User Setup</b> record used to resolve user-specific settings such as <b>working location</b>. </param>
    /// <param name="TransferToBinCode"> The <b>destination bin code</b> where the tobacco bale will be transferred. </param>
    /// <returns> Returns <b>true</b> if the item reclassification journal is successfully posted; otherwise returns <b>false</b>. </returns>
    procedure PostTobaccoBalesTransferItemReclass(var ItemJnlLine: Record "Item Journal Line"; PackageNoInfoRec: Record "Package No. Information"; UserSetupRec: Record "User Setup"; TransferToBinCode: Code[50]): Boolean
    var
        tempItemJnlLine: Record "Item Journal Line" temporary;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        PackageNoInfoRec.SetAutoCalcFields(Inventory, "PMP04 Bin Code", "PMP04 Lot No.");
        tempItemJnlLine.DeleteAll();
        TempTrackingSpecification.DeleteAll();
        ItemJnlTemplate.Reset();
        ItemJnlBatch.Reset();
        ExtCompanySetup.Get();
        Clear(ItemTrackingLine);

        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Int. Tf. Jnl. Tmpt. Name"));
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Int. Tf. Jnl. Batch Name"));
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Tobacco Tf. Reason Code"));

        if Test_InsertItemJnlLine(tempItemJnlLine, PackageNoInfoRec, UserSetupRec, TransferToBinCode) then begin
            InsertItemJnlLinefromTemp(ItemJnlLine, tempItemJnlLine);
            GenerateRecReserveEntryItemJnlLine(ItemJnlLine, PackageNoInfoRec, UserSetupRec, TransferToBinCode, TempTrackingSpecification);
            // Commit();
            if PostItemReclassJnl(ItemJnlLine, TempTrackingSpecification) then
                exit(true)
            else
                exit(false);
            exit(true);
        end else
            exit(false);
    end;

    /// <summary> Posts an <b>Item Reclassification Journal Line</b> together with its associated <b>item tracking and reservation entries</b>. </summary>
    /// <remarks> This procedure prepares the <b>tracking specification</b> from the provided Item Journal Line, initializes the <b>Item Tracking Line context</b>, and executes the posting logic using the standard <b>Item Journal posting engine</b>. It ensures that <b>quantity, base quantity, inbound/outbound direction</b>, and <b>warehouse tracking</b> are correctly applied during posting. </remarks>
    /// <param name="ItemJnlLine"> The <b>Item Journal Line</b> to be posted as a reclassification entry. </param>
    /// <param name="TempTrackingSpecification"> A <b>temporary Tracking Specification</b> record containing the resolved lot, serial, or package tracking data required for posting. </param> 
    /// <returns> Returns <b>true</b> after the item reclassification journal line and its tracking information are successfully posted. </returns>
    procedure PostItemReclassJnl(var ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        TempTrackSpec: Record "Tracking Specification" temporary;
        ReservationMgmt: Codeunit "Reservation Management";
        ItemJnlPostLineMgmt: Codeunit "Item Jnl.-Post Line";
    begin
        ItemJnlLineReserve.InitFromItemJnlLine(TempTrackSpec, ItemJnlLine);
        ItemTrackingLine.SetSourceSpec(TempTrackSpec, ItemJnlLine."Posting Date");
        ItemTrackingLine.SetInbound(ItemJnlLine.IsInbound());
        ItemTrackingLine.GetTrackingSpec(TempTrackSpec);

        ItemJnlPostLineMgmt.Run(ItemJnlLine);
        ItemJnlPostBatchMgmt.PostWhseJnlLine(ItemJnlLine, ItemJnlLine.Quantity, ItemJnlLine."Quantity (Base)", TempTrackSpec);
        exit(true);
    end;
    #endregion TOBACCO BALES TRANSFER

    #region TOBACCO BALE RE-SEQUENCE
    // Utilizes TOBACCO BALES TRANSFER logics in iteration
    #endregion TOBACCO BALE RE-SEQUENCE

    #region TOBACCO BALE RE-GRADING
    //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
    /// <summary>Sets the <b>Reason Code</b> on the Item Journal Line from the Assembly Line before <b>item consumption posting</b>.</summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", OnBeforePostItemConsumption, '', false, false)]
    local procedure PMP17SetILE_OnBeforePostItemConsumption(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine."Reason Code" := AssemblyLine."PMP18 Reason Code";
    end;

    /// <summary>Copies the <b>Reason Code</b> from the Assembly Line to the Item Journal Line after it is <b>created during assembly posting</b>.</summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", OnAfterCreateItemJnlLineFromAssemblyLine, '', false, false)]
    local procedure PMP17SetILE_OnAfterCreateItemJnlLineFromAssemblyLine(var ItemJournalLine: Record "Item Journal Line"; AssemblyLine: Record "Assembly Line")
    begin
        ItemJournalLine."Reason Code" := AssemblyLine."PMP18 Reason Code";
    end;

    /// <summary>Applies the <b>Reason Code</b> from the Assembly Header to the Item Journal Line after it is <b>generated from the header</b>.</summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", OnAfterCreateItemJnlLineFromAssemblyHeader, '', false, false)]
    local procedure PMP17SetILE_OnAfterCreateItemJnlLineFromAssemblyHeader(var ItemJournalLine: Record "Item Journal Line"; AssemblyHeader: Record "Assembly Header")
    begin
        ItemJournalLine."Reason Code" := AssemblyHeader."PMP18 Reason Code";
    end;
    //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}

    /// <summary> Creates an <b>Assembly Order</b> for <b>Tobacco Regrading</b> using package inventory and the user's working location. </summary>
    /// <remarks> Validates all required <b>Extended Company Setup</b> fields, generates document and posting numbers, initializes the assembly header, assigns <b>item</b>, <b>variant (new tobacco standard)</b>, <b>location</b>, <b>bin</b>, and <b>quantities</b> from the package information, applies the configured <b>Tobacco Regrading Reason Code</b>, and assigns the current user before inserting the record. </remarks>
    /// <param name="AssemblyHeader">Assembly Header record that will be initialized and inserted.</param>
    /// <param name="PkgNoInfoRec">Package information providing inventory quantity and bin code.</param>
    /// <param name="UserSetupRec">User setup used to determine the working location.</param>
    /// <param name="ItemNoCode">Item number of the tobacco to be regraded.</param>
    /// <param name="NewTobaccoStandardCode">Variant code representing the new tobacco standard.</param>
    procedure CreateAssemblyHeadTobaccoRegrading(var AssemblyHeader: Record "Assembly Header"; PkgNoInfoRec: Record "Package No. Information"; UserSetupRec: Record "User Setup"; ItemNoCode: Code[20]; NewTobaccoStandardCode: Code[10])
    var
        ItemRec: Record Item;
    begin
        PkgNoInfoRec.CalcFields(Inventory, "PMP04 Bin Code");
        ItemRec.Reset();
        ExtCompanySetup.Get();
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Tbco Regrade Nos."));
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Tbco Regrade Reason Code"));
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Posted Tbco Regrade Nos."));
        // 
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader."No." := NoSeriesMgt.GetNextNo(ExtCompanySetup."PMP17 Tbco Regrade Nos.", WorkDate());
        AssemblyHeader.Validate("No. Series", ExtCompanySetup."PMP17 Tbco Regrade Nos.");
        AssemblyHeader.Validate("Posting No. Series", ExtCompanySetup."PMP17 Posted Tbco Regrade Nos.");
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
        AssemblyHeader.InitRecord();

        // AssemblyHeader."Posting Date" := WorkDate();
        // AssemblyHeader.Validate("Due Date", WorkDate());
        // AssemblyHeader.Validate("Starting Date", WorkDate());
        // AssemblyHeader.Validate("Ending Date", WorkDate());
        // AssemblyHeader."Last Date Modified" := WorkDate();
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}

        ItemRec.Get(ItemNoCode);
        AssemblyHeader.Validate("Item No.", ItemNoCode);
        AssemblyHeader.Validate("Variant Code", NewTobaccoStandardCode);
        AssemblyHeader.Validate("Location Code", UserSetupRec."SME073 Working Location");
        AssemblyHeader.Validate("Bin Code", PkgNoInfoRec."PMP04 Bin Code");
        AssemblyHeader.Quantity := PkgNoInfoRec.Inventory;
        AssemblyHeader.Validate("Remaining Quantity", PkgNoInfoRec.Inventory);
        AssemblyHeader.Validate("Assembled Quantity", 0);
        AssemblyHeader.Validate("Quantity to Assemble", PkgNoInfoRec.Inventory);
        AssemblyHeader.Validate("Unit of Measure Code", ItemRec."Base Unit of Measure");
        AssemblyHeader."Assigned User ID" := UserId;
        AssemblyHeader."PMP18 Reason Code" := ExtCompanySetup."PMP17 Tbco Regrade Reason Code";
        AssemblyHeader.Insert();
    end;

    /// <summary> Creates a new Lot No. Information record for a tobacco regrading process based on an existing lot. </summary>
    /// <remarks> This procedure retrieves the existing Lot No. Information associated with the provided item, variant, and package lot number, then copies its data to create a new Lot No. Information record. The new record is created using the specified new tobacco standard (variant code) while preserving the original lot number, ensuring continuity of lot tracking during the regrading process.
    /// </remarks>
    /// <param name="NewLotNoInfoRec">A reference to the Lot No. Information record that will be initialized and inserted as the new regraded lot. </param>
    /// <param name="PkgNoInfoRec">The Package No. Information record that provides the source lot number, inventory context, and variant details. </param>
    /// <param name="ItemNoCode">The item number for which the new Lot No. Information record is created. </param>
    /// <param name="NewTobaccoStandardCode">The new tobacco standard represented as the target variant code for the regraded lot. </param>
    procedure CreateLotNoInfoTobaccoRegrading(var NewLotNoInfoRec: Record "Lot No. Information"; PkgNoInfoRec: Record "Package No. Information"; ItemNoCode: Code[20]; NewTobaccoStandardCode: Code[10])
    var
        OldLotNoInfoRec: Record "Lot No. Information";
    begin
        PkgNoInfoRec.CalcFields(Inventory);
        PkgNoInfoRec.CalcFields("PMP04 Bin Code");
        PkgNoInfoRec.CalcFields("PMP04 Lot No.");

        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
        OldLotNoInfoRec.Reset();
        OldLotNoInfoRec.SetRange("Item No.", ItemNoCode);
        OldLotNoInfoRec.SetRange("Variant Code", PkgNoInfoRec."Variant Code");
        OldLotNoInfoRec.SetRange("Lot No.", PkgNoInfoRec."PMP04 Lot No.");
        OldLotNoInfoRec.FindFirst();

        NewLotNoInfoRec.Init();
        NewLotNoInfoRec := OldLotNoInfoRec;
        NewLotNoInfoRec.Validate("Item No.", ItemNoCode);
        NewLotNoInfoRec.Validate("Variant Code", NewTobaccoStandardCode);
        NewLotNoInfoRec.Validate("Lot No.", PkgNoInfoRec."PMP04 Lot No.");
        NewLotNoInfoRec.Insert(true);
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
    end;

    /// <summary> Creates a new Package No. Information record for a tobacco regrading process by copying an existing package. </summary>
    /// <remarks> This procedure duplicates the provided Package No. Information record and creates a new entry for the specified item and new tobacco standard. The original package number and relevant tracking data are preserved, allowing the package to continue being traced correctly after the tobacco regrading while reflecting the updated item and variant context.
    /// </remarks>
    /// <param name="NewPackageNoInfo"> A reference to the Package No. Information record that will be initialized and inserted as the new regraded package. </param>
    /// <param name="PkgNoInfoRec"> The source Package No. Information record that provides inventory, bin, lot, and package details. </param>
    /// <param name="ItemNoCode"> The item number to be assigned to the new Package No. Information record. </param>
    /// <param name="NewTobaccoStandardCode"> The new tobacco standard represented as the target variant code for the regraded package. </param>
    procedure CreatePackageNoInfoTobaccoRegrading(var NewPackageNoInfo: Record "Package No. Information"; PkgNoInfoRec: Record "Package No. Information"; ItemNoCode: Code[20]; NewTobaccoStandardCode: Code[10])
    var
        OldPackageNoInfo: Record "Package No. Information";
    begin
        PkgNoInfoRec.CalcFields(Inventory);
        PkgNoInfoRec.CalcFields("PMP04 Bin Code");
        PkgNoInfoRec.CalcFields("PMP04 Lot No.");

        OldPackageNoInfo := PkgNoInfoRec;
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
        NewPackageNoInfo.Init();
        NewPackageNoInfo := OldPackageNoInfo;
        NewPackageNoInfo."Item No." := ItemNoCode;
        NewPackageNoInfo."Variant Code" := NewTobaccoStandardCode;
        NewPackageNoInfo.Validate("Package No.", PkgNoInfoRec."Package No.");
        NewPackageNoInfo.Insert();
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/08 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
    end;

    /// <summary> Creates an Assembly Line for a <b>tobacco regrading</b> process based on the specified Assembly Header and Package No. Information. </summary>
    /// <remarks> This procedure generates a new Assembly Line by consuming the full available <b>package inventory</b> and assigns it to the given Assembly Header. It determines the next valid <b>line number</b>, resolves the correct <b>location</b> from bin content with positive quantity, and applies the appropriate <b>item, variant, bin, and unit of measure</b>. The line is initialized to fully consume the package quantity and inherits the <b>reason code</b> from the Assembly Header to ensure traceability of the tobacco regrading process. </remarks>
    /// <param name="AssemblyLineRec"> A reference to the Assembly Line record that will be initialized and inserted. </param>
    /// <param name="AssemblyHeaderRec"> The Assembly Header that the new Assembly Line will be linked to. </param>
    /// <param name="PackageNoInfoRec"> The Package No. Information record providing <b>item, variant, bin, and inventory</b> details to be consumed. </param>
    /// <param name="UserSetupRec"> The User Setup record containing user-specific configuration relevant to the regrading process. </param>
    /// <param name="ItemNoCode"> The item number involved in the tobacco regrading operation. </param>
    /// <param name="NewTobaccoStandardCode"> The target tobacco standard represented as the new variant code. </param>
    procedure CreateAssemblyLineTobaccoRegrading(var AssemblyLineRec: Record "Assembly Line"; AssemblyHeaderRec: Record "Assembly Header"; PackageNoInfoRec: Record "Package No. Information"; UserSetupRec: Record "User Setup"; ItemNoCode: Code[20]; NewTobaccoStandardCode: Code[10])
    var
        ItemRec: Record Item;
        AsmbLineRec: Record "Assembly Line";
        BinContentRec: Record "Bin Content";
        LastLineNoInt: Integer;
        LocationCode: Code[10];
    begin
        ItemRec.Reset();
        AsmbLineRec.Reset();
        BinContentRec.Reset();
        PackageNoInfoRec.CalcFields(Inventory);

        AsmbLineRec.SetRange("Document No.", AssemblyHeaderRec."No.");
        if AsmbLineRec.FindLast() then begin
            LastLineNoInt := AsmbLineRec."Line No.";
        end;

        if LastLineNoInt mod 10000 > 0 then begin
            LastLineNoInt += LastLineNoInt mod 10000;
        end else begin
            LastLineNoInt += 10000;
        end;

        ItemRec.Get(PackageNoInfoRec."Item No.");

        BinContentRec.SetCurrentKey(Quantity);
        BinContentRec.SetRange("Item No.", PackageNoInfoRec."Item No.");
        BinContentRec.SetRange("Variant Code", PackageNoInfoRec."Variant Code");
        BinContentRec.SetRange("Package No. Filter", PackageNoInfoRec."Package No.");
        BinContentRec.SetAutoCalcFields(Quantity);
        BinContentRec.SetFilter(Quantity, '> 0');
        BinContentRec.Ascending(false);
        if BinContentRec.FindFirst() then begin
            LocationCode := BinContentRec."Location Code";
        end;

        AssemblyLineRec.Init();
        AssemblyLineRec.Validate("Document Type", AssemblyHeaderRec."Document Type");
        AssemblyLineRec.Validate("Document No.", AssemblyHeaderRec."No.");
        AssemblyLineRec.Validate("Line No.", LastLineNoInt);
        AssemblyLineRec.Validate(Type, AssemblyLineRec.Type::Item);
        AssemblyLineRec.Validate("No.", PackageNoInfoRec."Item No.");
        AssemblyLineRec.Validate("Variant Code", PackageNoInfoRec."Variant Code");
        AssemblyLineRec.Validate("Location Code", LocationCode);
        AssemblyLineRec.Validate("Bin Code", PackageNoInfoRec."PMP04 Bin Code");
        AssemblyLineRec.Validate(Quantity, PackageNoInfoRec.Inventory);
        AssemblyLineRec.Validate("Remaining Quantity", PackageNoInfoRec.Inventory);
        AssemblyLineRec.Validate("Consumed Quantity", 0);
        AssemblyLineRec.Validate("Quantity to Consume", PackageNoInfoRec.Inventory);
        AssemblyLineRec.Validate("Quantity per", 1);
        AssemblyLineRec.Validate("Unit of Measure Code", ItemRec."Base Unit of Measure");
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/10 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
        AssemblyLineRec.Validate("PMP18 Reason Code", AssemblyHeaderRec."PMP18 Reason Code");
        //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/10 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
        AssemblyLineRec.Insert();
    end;

    /// <summary> Generates <b>reservation entries</b> for an Assembly Header to support the <b>tobacco regrading</b> process with item tracking. </summary>
    /// <remarks> This procedure validates that no existing reservation entries are present for the Assembly Order, ensures the related <b>Item Tracking Code</b> is properly configured, and initializes a temporary <b>Tracking Specification</b> from the Assembly Header. It then retrieves tracking lookup data and creates reservation entries using either existing <b>lot and package</b> information from inventory summary data or fallback values from newly created Lot and Package records, ensuring accurate <b>traceability</b> throughout the regrading process. </remarks>
    /// <param name="AssemblyHeaderRec"> The Assembly Header record for which reservation entries will be generated. </param>
    /// <param name="PkgNoInfoRec"> The source Package No. Information providing existing <b>lot and package</b> references. </param>
    /// <param name="NewLotNoInfoRec"> The newly created Lot No. Information used when no existing tracking summary is found. </param>
    /// <param name="NewPackageNoInfo"> The newly created Package No. Information used as a fallback for reservation creation. </param>
    /// <param name="UserSetupRec"> The User Setup record containing user-specific context for the operation.</param>
    /// <param name="ItemNoCode"> The item number associated with the Assembly Order.</param>
    /// <param name="NewTobaccoStandardCode"> The target tobacco standard represented by the new variant code.</param>
    procedure GenerateItemReservEntryAssemblyHeader(var AssemblyHeaderRec: Record "Assembly Header"; PkgNoInfoRec: Record "Package No. Information"; NewLotNoInfoRec: Record "Lot No. Information"; NewPackageNoInfo: Record "Package No. Information"; UserSetupRec: Record "User Setup"; ItemNoCode: Code[20]; NewTobaccoStandardCode: Code[10])
    var
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CreateReserveMgmt: Codeunit "Create Reserv. Entry";
        RecRef: RecordRef;
    begin
        if AssemblyHeaderRec.ReservEntryExist() then
            Error('Item tracking information already exists for this Assembly Order (%1). Please remove the existing tracking before proceeding.', AssemblyHeaderRec."No.");

        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(AssemblyHeaderRec."Item No.") then
            Error('The specified Item No. "%1" could not be found. Please verify that the item exists in the system.', AssemblyHeaderRec."Item No.");

        RecRef.GetTable(Item);
        if Item."Item Tracking Code" = '' then
            PMPAppLogic.ErrorRecordRefwithAction(RecRef, Item.FieldNo(Description), Page::"Item Card", 'Empty Field', StrSubstNo('The Item "%1" does not have an assigned Item Tracking Code. Please configure the Item Tracking Code in the Item Card before continuing.', AssemblyHeaderRec."Item No."));

        AssemblyHeaderReserve.InitFromAsmHeader(TempTrackingSpecification, AssemblyHeaderRec);
        TempTrackingSpecification.Insert();

        RetrieveLookupData(TempTrackingSpecification, true);
        TempTrackingSpecification.Delete();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetFilter("Lot No.", PkgNoInfoRec."PMP04 Lot No.");
        TempGlobalEntrySummary.SetRange("Package No.", PkgNoInfoRec."Package No.");
        if TempGlobalEntrySummary.FindSet() then begin
            InsertReservEntryRecfromTempTrackSpecASMHEADER(AssemblyHeaderRec, PkgNoInfoRec, TempTrackingSpecification, TempGlobalEntrySummary."Lot No.", TempGlobalEntrySummary."Package No.");
        end else begin
            InsertReservEntryRecfromTempTrackSpecASMHEADER(AssemblyHeaderRec, PkgNoInfoRec, TempTrackingSpecification, NewLotNoInfoRec."Lot No.", NewPackageNoInfo."Package No."); // LA TEMPORAIRE
        end;
    end;

    local procedure InsertReservEntryRecfromTempTrackSpecASMHEADER(var AssemblyHeaderRec: Record "Assembly Header"; PkgNoInfoRec: Record "Package No. Information"; TempTrackingSpecification: Record "Tracking Specification" temporary; LotNo: Code[50]; PackageNo: Code[50])
    var
        TypeHelper: Codeunit "Type Helper";
        SourceTrackingSpecification: Record "Tracking Specification";
        ItemTrackingLine: Page "Item Tracking Lines";
        RecRef: RecordRef;
        ChangeType: Option Insert,Modify,FullDelete,PartDelete,ModifyAll;
    begin
        AssemblyHeaderReserve.InitFromAsmHeader(SourceTrackingSpecification, AssemblyHeaderRec);
        ItemTrackingLine.SetSourceSpec(SourceTrackingSpecification, 0D);

        TempTrackingSpecification.Init;
        TempTrackingSpecification.TransferFields(SourceTrackingSpecification);
        TempTrackingSpecification."Entry No." := NextTrackingSpecEntryNo();
        TempTrackingSpecification.SetItemData(SourceTrackingSpecification."Item No.", SourceTrackingSpecification.Description, SourceTrackingSpecification."Location Code", SourceTrackingSpecification."Variant Code", SourceTrackingSpecification."Bin Code", SourceTrackingSpecification."Qty. per Unit of Measure");
        TempTrackingSpecification.Validate("Item No.", SourceTrackingSpecification."Item No.");
        TempTrackingSpecification.Validate("Location Code", SourceTrackingSpecification."Location Code");
        // TempTrackingSpecification.Validate("Creation Date", Today);
        TempTrackingSpecification.Validate("Creation Date", DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone()));
        TempTrackingSpecification.Validate("Source Type", SourceTrackingSpecification."Source Type");
        TempTrackingSpecification.Validate("Source Subtype", SourceTrackingSpecification."Source Subtype");
        TempTrackingSpecification.Validate("Source ID", SourceTrackingSpecification."Source ID");
        TempTrackingSpecification.Validate("Source Batch Name", SourceTrackingSpecification."Source Batch Name");
        TempTrackingSpecification.Validate("Source Prod. Order Line", SourceTrackingSpecification."Source Prod. Order Line");
        TempTrackingSpecification.Validate("Source Ref. No.", SourceTrackingSpecification."Source Ref. No.");

        if LotNo <> '' then
            TempTrackingSpecification.Validate("Lot No.", LotNo);
        if PackageNo <> '' then
            TempTrackingSpecification.Validate("Package No.", PackageNo);

        TempTrackingSpecification.Validate("Quantity (Base)", AssemblyHeaderRec."Quantity (Base)");
        TempTrackingSpecification.Validate("Qty. to Handle (Base)", AssemblyHeaderRec."Quantity (Base)");
        TempTrackingSpecification.Validate("Qty. to Invoice (Base)", AssemblyHeaderRec."Quantity (Base)");
        ItemTrackingLine.RegisterChange(TempTrackingSpecification, TempTrackingSpecification, ChangeType::Insert, false);
    end;

    /// <summary> Inserts a <b>reservation entry</b> for an Assembly Header by creating and registering a Tracking Specification based on <b>lot</b> and <b>package</b> information. </summary>
    procedure GenerateItemReservEntryAssemblyLine(var AssemblyLineRec: Record "Assembly Line"; PkgNoInfoRec: Record "Package No. Information"; NewLotNoInfoRec: Record "Lot No. Information"; NewPackageNoInfo: Record "Package No. Information"; UserSetupRec: Record "User Setup"; ItemNoCode: Code[20]; NewTobaccoStandardCode: Code[10])
    var
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CreateReserveMgmt: Codeunit "Create Reserv. Entry";
        RecRef: RecordRef;
    begin
        if AssemblyLineRec.ReservEntryExist() then
            Error('Item tracking information already exists for this Assembly Order (%1). Please remove the existing tracking before proceeding.', AssemblyLineRec."No.");

        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(AssemblyLineRec."No.") then
            Error('The specified Item No. "%1" could not be found. Please verify that the item exists in the system.', AssemblyLineRec."No.");

        RecRef.GetTable(Item);
        if Item."Item Tracking Code" = '' then
            PMPAppLogic.ErrorRecordRefwithAction(RecRef, Item.FieldNo(Description), Page::"Item Card", 'Empty Field', StrSubstNo('The Item "%1" does not have an assigned Item Tracking Code. Please configure the Item Tracking Code in the Item Card before continuing.', AssemblyLineRec."No."));

        AssemblyLineReserve.InitFromAsmLine(TempTrackingSpecification, AssemblyLineRec);
        TempTrackingSpecification.Insert();

        RetrieveLookupData(TempTrackingSpecification, true);
        TempTrackingSpecification.Delete();
        TempGlobalEntrySummary.Reset();
        TempGlobalEntrySummary.SetFilter("Lot No.", PkgNoInfoRec."PMP04 Lot No.");
        TempGlobalEntrySummary.SetRange("Package No.", PkgNoInfoRec."Package No.");
        if TempGlobalEntrySummary.FindSet() then begin
            InsertReservEntryRecfromTempTrackSpecASMLINE(AssemblyLineRec, PkgNoInfoRec, TempTrackingSpecification, TempGlobalEntrySummary."Lot No.", TempGlobalEntrySummary."Package No.");
        end else begin
            InsertReservEntryRecfromTempTrackSpecASMLINE(AssemblyLineRec, PkgNoInfoRec, TempTrackingSpecification, NewLotNoInfoRec."Lot No.", NewPackageNoInfo."Package No."); // LA TEMPORAIRE
        end;
    end;

    /// <summary> Inserts a <b>reservation entry</b> for an Assembly Line by creating and registering a Tracking Specification using the provided <b>lot</b> and <b>package</b> information. </summary>
    local procedure InsertReservEntryRecfromTempTrackSpecASMLINE(var AssemblyLine: Record "Assembly Line"; PkgNoInfoRec: Record "Package No. Information"; TempTrackingSpecification: Record "Tracking Specification" temporary; LotNo: Code[50]; PackageNo: Code[50])
    var
        TypeHelper: Codeunit "Type Helper";
        SourceTrackingSpecification: Record "Tracking Specification";
        ItemTrackingLine: Page "Item Tracking Lines";
        RecRef: RecordRef;
        ChangeType: Option Insert,Modify,FullDelete,PartDelete,ModifyAll;
    begin
        AssemblyLineReserve.InitFromAsmLine(SourceTrackingSpecification, AssemblyLine);
        ItemTrackingLine.SetSourceSpec(SourceTrackingSpecification, 0D);

        TempTrackingSpecification.Init;
        TempTrackingSpecification.TransferFields(SourceTrackingSpecification);
        TempTrackingSpecification."Entry No." := NextTrackingSpecEntryNo();
        TempTrackingSpecification.SetItemData(SourceTrackingSpecification."Item No.", SourceTrackingSpecification.Description, SourceTrackingSpecification."Location Code", SourceTrackingSpecification."Variant Code", SourceTrackingSpecification."Bin Code", SourceTrackingSpecification."Qty. per Unit of Measure");
        TempTrackingSpecification.Validate("Item No.", SourceTrackingSpecification."Item No.");
        TempTrackingSpecification.Validate("Location Code", SourceTrackingSpecification."Location Code");
        // TempTrackingSpecification.Validate("Creation Date", Today);
        TempTrackingSpecification.Validate("Creation Date", DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone()));
        TempTrackingSpecification.Validate("Source Type", SourceTrackingSpecification."Source Type");
        TempTrackingSpecification.Validate("Source Subtype", SourceTrackingSpecification."Source Subtype");
        TempTrackingSpecification.Validate("Source ID", SourceTrackingSpecification."Source ID");
        TempTrackingSpecification.Validate("Source Batch Name", SourceTrackingSpecification."Source Batch Name");
        TempTrackingSpecification.Validate("Source Prod. Order Line", SourceTrackingSpecification."Source Prod. Order Line");
        TempTrackingSpecification.Validate("Source Ref. No.", SourceTrackingSpecification."Source Ref. No.");

        if LotNo <> '' then
            TempTrackingSpecification.Validate("Lot No.", LotNo);
        if PackageNo <> '' then
            TempTrackingSpecification.Validate("Package No.", PackageNo);

        TempTrackingSpecification.Validate("Quantity (Base)", AssemblyLine."Quantity (Base)");
        TempTrackingSpecification.Validate("Qty. to Handle (Base)", AssemblyLine."Quantity (Base)");
        TempTrackingSpecification.Validate("Qty. to Invoice (Base)", AssemblyLine."Quantity (Base)");
        ItemTrackingLine.RegisterChange(TempTrackingSpecification, TempTrackingSpecification, ChangeType::Insert, false);
    end;

    /// <summary> Executes the complete <b>Tobacco Bales Regrading</b> posting process by creating, reserving, releasing, and posting an Assembly Order for regraded tobacco. </summary>
    /// <remarks> This procedure orchestrates the <b>end-to-end regrading workflow</b>. It validates mandatory Extended Company Setup configuration, creates a new <b>Assembly Header</b> and corresponding <b>Assembly Line</b>, ensures the existence of target <b>Lot No.</b> and <b>Package No.</b> records for the new tobacco standard, generates required <b>item tracking and reservation entries</b> for both header and line, then releases and posts the Assembly Order. The process guarantees that inventory is fully reclassified from the original tobacco standard to the <b>new tobacco standard</b> with complete tracking integrity. </remarks>
    /// <param name="AssemblyHeaderRec"> The Assembly Header record that will be initialized and posted for the regrading process. </param>
    /// <param name="PackageNoInfoRec"> The source Package No. Information representing the existing tobacco bale to be regraded. </param>
    /// <param name="UserSetupRec"> The User Setup record used to resolve operational context such as <b>working location</b>. </param>
    /// <param name="ItemNoCode"> The Item Number representing the target tobacco item for regrading. </param>
    /// <param name="NewTobaccoStandardCode"> The Variant Code defining the <b>new tobacco standard</b> after regrading. </param>
    /// <returns> Returns <b>true</b> when the Assembly Order is successfully created, released, and posted. </returns>
    procedure PostTobaccoBalesRegrading(var AssemblyHeaderRec: Record "Assembly Header"; PackageNoInfoRec: Record "Package No. Information"; UserSetupRec: Record "User Setup"; ItemNoCode: Code[20]; NewTobaccoStandardCode: Code[10]): Boolean
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        NewLotNoInfoRec: Record "Lot No. Information";
        NewPackageNoInfoRec: Record "Package No. Information";
        AssemblyLineRec: Record "Assembly Line";
    begin
        NewLotNoInfoRec.Reset();
        NewPackageNoInfoRec.Reset();
        AssemblyLineRec.Reset();
        NewPackageNoInfoRec.Reset();
        ExtCompanySetup.Get();
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Tbco Regrade Nos."));
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Tbco Regrade Reason Code"));
        PMPAppLogic.ValidateExtendedCompanySetupwithAction(ExtCompanySetup.FieldNo("PMP17 Posted Tbco Regrade Nos."));

        CreateAssemblyHeadTobaccoRegrading(AssemblyHeaderRec, PackageNoInfoRec, UserSetupRec, ItemNoCode, NewTobaccoStandardCode);
        NewLotNoInfoRec.SetRange("Item No.", ItemNoCode);
        NewLotNoInfoRec.SetRange("Variant Code", NewTobaccoStandardCode);
        NewLotNoInfoRec.SetRange("Lot No.", PackageNoInfoRec."PMP04 Lot No.");
        if not NewLotNoInfoRec.FindFirst() then begin
            CreateLotNoInfoTobaccoRegrading(NewLotNoInfoRec, PackageNoInfoRec, ItemNoCode, NewTobaccoStandardCode);
        end;
        NewPackageNoInfoRec.SetRange("Item No.", ItemNoCode);
        NewPackageNoInfoRec.SetRange("Variant Code", NewTobaccoStandardCode);
        NewPackageNoInfoRec.SetRange("Package No.", PackageNoInfoRec."Package No.");
        if not NewPackageNoInfoRec.FindFirst() then begin
            CreatePackageNoInfoTobaccoRegrading(NewPackageNoInfoRec, PackageNoInfoRec, ItemNoCode, NewTobaccoStandardCode);
        end;

        CreateAssemblyLineTobaccoRegrading(AssemblyLineRec, AssemblyHeaderRec, PackageNoInfoRec, UserSetupRec, ItemNoCode, NewTobaccoStandardCode);

        GenerateItemReservEntryAssemblyHeader(AssemblyHeaderRec, PackageNoInfoRec, NewLotNoInfoRec, NewPackageNoInfoRec, UserSetupRec, ItemNoCode, NewTobaccoStandardCode);
        GenerateItemReservEntryAssemblyLine(AssemblyLineRec, PackageNoInfoRec, NewLotNoInfoRec, NewPackageNoInfoRec, UserSetupRec, ItemNoCode, NewTobaccoStandardCode);
        // Commit();
        ReleaseAssemblyDocMgmt.Run(AssemblyHeaderRec);

        AssemblyPostMgmt.Run(AssemblyHeaderRec);
        exit(true);
    end;
    #endregion TOBACCO BALE RE-GRADING

    #region HELPER
    /// <summary>Generates the next available entry number for the Tracking Specification table.</summary>
    /// <remarks>This procedure retrieves the latest Tracking Specification entry number if not initialized, increments it by one, and returns the new value.</remarks>
    /// <returns>The newly generated tracking specification entry number.</returns>
    procedure NextTrackingSpecEntryNo(): Integer
    var
        TrackSpec: Record "Tracking Specification";
    begin
        TrackSpec.Reset();
        if LastTrackingSpecEntryNo = 0 then
            if TrackSpec.FindLast() then
                LastTrackingSpecEntryNo := TrackSpec."Entry No.";
        LastTrackingSpecEntryNo += 1;
        exit(LastTrackingSpecEntryNo);
    end;

    /// <summary> Handles a notification action by opening the configured <b>Internal Transfer Item Journal Batch</b> from Extended Company Setup. </summary>
    /// <remarks> This procedure responds to a <b>notification action</b> by retrieving the Internal Transfer Item Journal Template defined in <b>Extended Company Setup</b>, filtering the Item Journal Batches accordingly, and launching the <b>Item Journal Batches</b> page. It provides users with quick access to the correct journal batch required for <b>internal transfer</b> processing without manual navigation. </remarks>
    /// <param name="Notification"> The notification instance that triggers this action. </param>
    procedure NotifAction_ExtCompanySetupOpenItemJnlBatchTransfer(Notification: Notification)
    var
        ItemJnlBatchPage: Page "Item Journal Batches";
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ExtCompanySetup.Get();
        ItemJnlBatch.SetRange("Journal Template Name", ExtCompanySetup."PMP17 Int. Tf. Jnl. Tmpt. Name");
        ItemJnlBatchPage.SetRecord(ItemJnlBatch);
        ItemJnlBatchPage.Run();
    end;
    #endregion HELPER
}
