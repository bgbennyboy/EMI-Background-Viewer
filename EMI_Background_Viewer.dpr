{
******************************************************
  EMI Background Viewer
  Copyright (c) 2004 - 2010 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

program EMI_Background_Viewer;

uses
  Forms,
  frmMain in 'frmMain.pas' {formMain},
  About in 'About.pas' {frmAbout},
  uLABManager in 'uLABManager.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'EMI Background Viewer';
  Application.CreateForm(TformMain, formMain);
  Application.CreateForm(TfrmAbout, frmAbout);



  //ReportMemoryLeaksOnShutdown := true;

  Application.Run;
end.
