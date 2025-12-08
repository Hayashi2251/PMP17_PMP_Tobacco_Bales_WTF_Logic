page 60425 "PMP17 Tbco. Bales Reseq. Sub."
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
    Caption = 'Tobacco Bales Resequence Subform';
    PageType = ListPart;
    DelayedInsert = true;
    SourceTable = "Package No. Information";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("PMP04 Bale Position"; Rec."PMP04 Bale Position")
                {
                    ApplicationArea = All;
                    Caption = 'New Bale Position';
                    ToolTip = 'Specifies the new bale position of the scanned bale number.';
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
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = '';
                    ToolTip = 'Specifies the description associated with this line.';
                    Editable = false;
                }
                field("PMP04 Sub Merk 1"; Rec."PMP04 Sub Merk 1")
                {
                    ApplicationArea = All;
                    Caption = 'Sub Merk 1';
                    ToolTip = 'Specifies the submerk 1 associated with this line';
                    Editable = false;
                }
                field("PMP04 Sub Merk 2"; Rec."PMP04 Sub Merk 2")
                {
                    ApplicationArea = All;
                    Caption = 'Sub Merk 2';
                    ToolTip = 'Specifies the submerk 2 associated with this line';
                    Editable = false;
                }
                field("PMP04 Sub Merk 3"; Rec."PMP04 Sub Merk 3")
                {
                    ApplicationArea = All;
                    Caption = 'Sub Merk 3';
                    ToolTip = 'Specifies the submerk 3 associated with this line';
                    Editable = false;
                }
                field("PMP04 Sub Merk 4"; Rec."PMP04 Sub Merk 4")
                {
                    ApplicationArea = All;
                    Caption = 'Sub Merk 4';
                    ToolTip = 'Specifies the submerk 4 associated with this line';
                    Editable = false;
                }
                field("PMP04 Sub Merk 5"; Rec."PMP04 Sub Merk 5")
                {
                    ApplicationArea = All;
                    Caption = 'Sub Merk 5';
                    ToolTip = 'Specifies the submerk 5 associated with this line';
                    Editable = false;
                }
                field("PMP04 Lot No."; Rec."PMP04 Lot No.")
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
                field("PMP04 Bin Code"; Rec."PMP04 Bin Code")
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
        }
    }

    var
        NewBalePosition: Integer;

    protected var
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        CurrentLocationCode: Code[10];
        CurrentBinCode: Code[20];
        BaseUoMCode: Code[10];

    procedure SetCurrentLocationCode(CurrLocationCode: Code[10])
    begin
        CurrentLocationCode := CurrLocationCode;
    end;

    procedure SetCurrentBinCode(CurrBinCode: Code[20])
    begin
        CurrentBinCode := CurrBinCode;
    end;

    procedure SetBaseUoMCode(BaseUoMCodeparam: Code[10])
    begin
        BaseUoMCode := BaseUoMCodeparam;
    end;

    procedure SetNewBalePosition(BalePosInt: Integer)
    begin
        NewBalePosition := BalePosInt;
    end;

    /// <summary> Deletes all existing data in PMP17 TbccoBalesWhseTFPkgNo, allowing it to be repopulated from the Parent Page by performing a rescan.</summary>
    /// <remarks> This procedure is used exclusively to clear all data. </remarks>
    procedure DeleteAllRecord()
    begin
        Rec.DeleteAll();
    end;

    procedure InsertRecord(var SourcePkgNoInfoRec: Record "Package No. Information"; CurrLocCode: Code[10]; CurrBinCode: Code[20])
    var
        ExtCompanySetup: Record "PMP07 Extended Company Setup";
        BinContent: Record "Bin Content"; // LA TEMPORAIRE
        ItemRec: Record Item;
    begin
        ExtCompanySetup.Get();
        BinContent.Reset(); // LA 
        BinContent.SetAutoCalcFields(Quantity); // LA TEMPORAIRE
        // ====================================================
        SourcePkgNoInfoRec.CalcFields(Inventory);
        SourcePkgNoInfoRec.CalcFields("PMP04 Bin Code");
        SourcePkgNoInfoRec.CalcFields("PMP04 Lot No.");
        // ====================================================
        Rec.Init();
        ItemRec.Get(SourcePkgNoInfoRec."Item No.");
        Rec := SourcePkgNoInfoRec;
        ItemRec.TestField("Base Unit of Measure");
        SetBaseUoMCode(ItemRec."Base Unit of Measure");
        Rec."PMP04 Bale Position" := NewBalePosition;

        // LA TEMPORAIRE
        // "Item No." = field("Item No."),
        // "Variant Code" = field("Variant Code"),
        // Quantity = filter(<> 0),
        // "Package No. Filter" = field("Package No.")
        BinContent.SetCurrentKey(Quantity);
        BinContent.SetRange("Item No.", SourcePkgNoInfoRec."Item No.");
        BinContent.SetRange("Variant Code", SourcePkgNoInfoRec."Variant Code");
        BinContent.SetFilter("Package No. Filter", SourcePkgNoInfoRec."Package No.");
        BinContent.SetFilter(Quantity, '> 0');
        BinContent.Ascending(false);
        if BinContent.FindFirst() then begin
            CurrentLocationCode := BinContent."Location Code";
        end;
        // SetCurrentLocationCode(CurrLocCode); // LA TEMPORAIRE
        // SetCurrentBinCode(CurrBinCode); // LA TEMPORAIRE
        // ========// LA TEMPORAIRE     
        Rec.Insert();

        NewBalePosition += 1;
        CurrPage.Update();
    end;

    procedure GetPackageNoInfo_TobaccoBalesResequenceSubform(var TargetPkgNoInfoRec: Record "Package No. Information" temporary)
    begin
        if Rec.IsEmpty() then
            exit;

        if Rec.FindSet() then
            repeat
                TargetPkgNoInfoRec.Init();
                TargetPkgNoInfoRec := Rec;
                TargetPkgNoInfoRec.Insert();
            until Rec.Next() = 0;
    end;

    procedure GetFirstRec(var TargetPkgNoInfoRec: Record "Package No. Information" temporary)
    begin
        if Rec.IsEmpty() then
            exit;

        Rec.FindFirst();
        TargetPkgNoInfoRec.Init();
        TargetPkgNoInfoRec := Rec;
        TargetPkgNoInfoRec.Insert();
    end;

    procedure DeleteFirstRec()
    begin
        if Rec.IsEmpty() then
            exit;

        Rec.FindFirst();
        Rec.Delete();
    end;

    procedure CountAllExistingRec(): Integer
    begin
        exit(Rec.Count);
    end;

}
