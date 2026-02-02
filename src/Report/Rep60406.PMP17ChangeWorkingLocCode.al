report 60406 "PMP17 Change Working Loc. Code"
{
    // version PMP17 

    // List Modification
    // Version List       Name
    // =============================================================================================================
    // PMP17              PMP Tobacco Bales Whse TF (Logic)

    // REPORT
    // Date        Developer  Version List  Trigger            Description
    // =============================================================================================================
    // 2025/11/21  SW         PMP17         -                  Create Report

    ApplicationArea = All;
    Caption = 'Change Working Location Code';
    UsageCategory = Tasks;
    ProcessingOnly = true;
    dataset
    {
        dataitem(UserSetup; "User Setup")
        {
            DataItemTableView = sorting("User ID");

            trigger OnPreDataItem()
            begin
                if ReqUserID = '' then
                    Error('The related User ID is required. Please complete the field before continuing.');
                if ReqLocationCode = '' then
                    Error('The related Location Code is required. Please complete the field before continuing.');

                UserSetup.SetRange("User ID", ReqUserID); // Filter the record
                ValidateUserIDWorkingLocationCode(true);
            end;

            trigger OnAfterGetRecord()
            begin
                UserSetup."SME073 Working Location" := ReqLocationCode;
                UserSetup.Modify();
                Message('The working location code of user ID: %1, have successfully changed to %2', ReqUserID, ReqLocationCode);
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group("Change Working Loc. Code")
                {
                    Caption = 'Change Working Location Code';
                    field(ReqUserID; ReqUserID)
                    {
                        ApplicationArea = All;
                        Caption = 'User ID';
                        ToolTip = 'Displays current user name used to login.';
                        Editable = ReqUserID_Visibility;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            UserRec: Record User;
                            UserSetupRec: Record "User Setup";
                            UserSelection: Codeunit "User Selection";
                            ErrInfo: ErrorInfo;
                        begin
                            //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - START >>>>>>>>>>>>>>>>>>>>>>>>>>}
                            UserRec.Reset();
                            if Page.RunModal(Page::Users, UserRec) = Action::LookupOK then begin
                                if (UserSetupRec.Get(UserRec."User Name")) then begin
                                    ReqUserID := UserRec."User Name";
                                    ReqLocationCode := UserSetupRec."SME073 Working Location";
                                end else begin
                                    ErrInfo.DataClassification(DataClassification::SystemMetadata);
                                    ErrInfo.ErrorType(ErrorType::Client);
                                    ErrInfo.Verbosity(Verbosity::Error);
                                    ErrInfo.Title := 'User Setup not found';
                                    ErrInfo.Message := StrSubstNo('The User does not have any Setup yet. Please provide the user setup for the Username: %1, before setting the working location code.', UserRec."User Name");
                                    ErrInfo.PageNo(Page::"User Setup");
                                    ErrInfo.AddNavigationAction('Open User Setup');
                                    Error(ErrInfo);
                                    Clear(ErrInfo);
                                end;
                            end;
                            //{<<<<<<<<<<<<<<<<<<<<<<<<<< PMP17 - SW - 2026/01/07 - FINISH >>>>>>>>>>>>>>>>>>>>>>>>>>}
                        end;
                    }
                    field(ReqLocationCode; ReqLocationCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Location Code';
                        ToolTip = 'Used to record Location Code. This filter is mandatory and shall not be empty.';
                        ExtendedDatatype = Barcode;
                        ShowMandatory = true;
                        trigger OnLookup(var Text: Text): Boolean
                        var
                            WhseEmployeeRec: Record "Warehouse Employee";
                        begin
                            WhseEmployeeRec.Reset();
                            WhseEmployeeRec.SetRange("User ID", ReqUserID);
                            if Page.RunModal(Page::"Warehouse Employee List", WhseEmployeeRec) = Action::LookupOK then
                                ReqLocationCode := WhseEmployeeRec."Location Code";
                        end;

                        trigger OnValidate()
                        var
                            WhseEmployeeRec: Record "Warehouse Employee";
                        begin
                            WhseEmployeeRec.Reset();
                            if ReqUserID = '' then
                                Error('The related User ID is required. Please complete the field before continuing.');

                            ValidateUserIDWorkingLocationCode(false);
                        end;
                    }
                }
            }
        }
        actions
        {
            area(Processing)
            {
            }
        }
        trigger OnOpenPage()
        var
            UserRec: Record "User Setup";
        begin
            if ReqUserID = '' then begin
                UserRec.Get(UserId);
                ReqUserID := UserRec."User ID";
                ReqLocationCode := UserRec."SME073 Working Location";
                ReqUserID_Visibility := true;
            end;
        end;
    }
    trigger OnInitReport()
    begin
        Clear(ReqUserID_Visibility);
        Clear(ReqUserID);
        Clear(ReqLocationCode);
    end;

    var
        ReqUserID_Visibility: Boolean;

    protected var
        ReqUserID: Code[50];
        ReqLocationCode: Code[10];


    procedure SetUserID(UserNameCode: Code[50])
    begin
        ReqUserID := UserNameCode;
    end;

    procedure SetLocationCode(LocationCode: Code[10])
    begin
        ReqLocationCode := LocationCode;
    end;

    procedure SetReqUserIDVisibility(ReqUserID_Vis: Boolean)
    begin
        ReqUserID_Visibility := ReqUserID_Vis;
    end;

    local procedure ValidateUserIDWorkingLocationCode(IsErrorAvailable: Boolean)
    var
        WhseEmployeeRec: Record "Warehouse Employee";
    begin
        WhseEmployeeRec.SetRange("User ID", ReqUserID);
        WhseEmployeeRec.SetRange("Location Code", ReqLocationCode);
        if WhseEmployeeRec.FindFirst() then
            ReqLocationCode := WhseEmployeeRec."Location Code"
        else begin
            if IsErrorAvailable then
                Message('You are not allowed to work at %1', ReqLocationCode)
            else
                Error('You are not allowed to work at %1', ReqLocationCode);
            ReqLocationCode := '';
        end;
    end;
}
