//******************************
//**EMI Background Viewer 1.1***
//**By Ben Gorman (Bgbennyboy)**
//**Http://quick.mixnmojo.com/**
//******************************

unit About;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, jpeg, ExtCtrls, StdCtrls, jclshell;

type
  TfrmAbout = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure Label4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAbout: TfrmAbout;

implementation

{$R *.dfm}

procedure TfrmAbout.Label4Click(Sender: TObject);
begin
  shellexec(0, 'open', 'Http://quick.mixnmojo.com/','', '', SW_SHOWNORMAL);
end;

end.
