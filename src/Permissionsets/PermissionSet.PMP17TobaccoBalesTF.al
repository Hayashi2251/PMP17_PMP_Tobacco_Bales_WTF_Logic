permissionset 60403 PMP17TobaccoBalesTF
{
    Assignable = true;
    Caption = 'Tobacco Bales Whse. Transfer', MaxLength = 30;
    Permissions =
        page "PMP17 Tobacco Bales Transfer" = X,
        page "PMP17 Tbco. Bales Reseq. Sub." = X,
        page "PMP17 Tobacco Regrading" = X,
        page "PMP17 Tobacco Bale Resequence" = X,
        report "PMP17 Change Working Loc. Code" = X,
        codeunit "PMP17 Tobacco Bales Whse. Tf." = X;
}
