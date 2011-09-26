{
******************************************************
  EMI Background Viewer
  Copyright (c) 2004 - 2010 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit frmMain;

interface

uses
  Windows, SysUtils,  Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,  Buttons, pngimage,
  ComCtrls, JvBaseDlg, JvBrowseFolder, Menus, ImgList,
  jclfileutils, jclsysinfo,
  uEMIUtils, uLABManager, uMemReader;

type
  TformMain = class(TForm)
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    PopupMenu1: TPopupMenu;
    menuSave: TMenuItem;
    menuDebug: TMenuItem;
    dlgBrowseFolder: TJvBrowseForFolderDialog;
    panelSide: TPanel;
    panelButtons: TPanel;
    ProgressBar1: TProgressBar;
    panelImage: TPanel;
    Image1: TImage;
    listBoxImages: TListBox;
    ImageList1: TImageList;
    btnOpen: TButton;
    btnDebug: TButton;
    btnSave: TButton;
    btnSaveAll: TButton;
    btnAbout: TButton;
    btnCancel: TButton;
    procedure btnOpenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure SaveDialog1TypeChange(Sender: TObject);
    procedure btnSaveAllClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure menuSaveClick(Sender: TObject);
    procedure menuDebugClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure listBoxImagesClick(Sender: TObject);
    procedure listBoxImagesDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnDebugClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    procedure DoButtons(Value: boolean);
    procedure ViewTile(Width: integer; Height: Integer);
    procedure DecodeTile(OutBmp: Tbitmap; Width: integer; Height: integer; ShowProgress: boolean; Source: TExplorerMemoryStream);
    function GetImageWidth: integer;
    function GetImageHeight: integer;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  formMain: TformMain;
  CancelSaveAll: boolean;
  ShowDebug: boolean;
  fLabReader: TLABManager;

type
  EInvalidTilImage = class(exception);

implementation

uses About;

{$R *.dfm}
//{$R Extra.RES}

function RGBToColor(R, G, B : byte): TColor; inline;
begin
  Result := ((R and $FF) shl 16) +
    ((G and $FF) shl 8) + (B and $FF);
end;

function MyMessageDialog(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; Captions: array of string): Integer;
var 
  aMsgDlg: TForm; 
  i: Integer; 
  dlgButton: TButton; 
  CaptionIndex: Integer; 
begin 
  { Create the Dialog }
  aMsgDlg := CreateMessageDialog(Msg, DlgType, Buttons); 
  captionIndex := 0; 
  { Loop through Objects in Dialog }
  for i := 0 to aMsgDlg.ComponentCount - 1 do
  begin 
   { If the object is of type TButton, then }
    if (aMsgDlg.Components[i] is TButton) then
    begin 
      dlgButton := TButton(aMsgDlg.Components[i]); 
      if CaptionIndex > High(Captions) then Break; 
      { Give a new caption from our Captions array}
      dlgButton.Caption := Captions[CaptionIndex]; 
      Inc(CaptionIndex); 
    end; 
  end;
  Result := aMsgDlg.ShowModal;
  aMsgDlg.Free;// free the dialog
end;

procedure TformMain.DoButtons(Value: boolean);
begin
  btnOpen.Enabled:=value;
  btnSave.Enabled:=value;
  btnSaveAll.Enabled:=value;
  btnAbout.enabled:=value;
  btnDebug.enabled := value;
  listBoxImages.Enabled:=value;
  menuSave.Enabled:=value;
  menuDebug.Enabled:=value;
  PopupMenu1.AutoPopup := value;
end;

procedure TformMain.FormCreate(Sender: TObject);
begin
  OpenDialog1.InitialDir := GetEMIPath;
  SaveDialog1.InitialDir := GetDesktopDirectoryFolder;
  dlgBrowseFolder.RootDirectory:=fdDesktopDirectory;
  dlgBrowseFolder.RootDirectoryPath:=GetDesktopDirectoryFolder;
  ShowDebug := false;
end;

procedure TformMain.FormDestroy(Sender: TObject);
begin
  if fLabReader <> nil then
    fLabReader.Free;
end;

function TformMain.GetImageHeight: integer;
begin
  if ShowDebug = true then
    result := 512
  else
    result := 480;
end;

function TformMain.GetImageWidth: integer;
begin
  if ShowDebug = true then
    result := 766
  else
    result := 640;
end;

procedure TformMain.listBoxImagesClick(Sender: TObject);
begin
  if listBoxImages.Count = 0 then exit;

  Viewtile(GetImageWidth, GetImageHeight);
end;

procedure TformMain.listBoxImagesDblClick(Sender: TObject);
begin
  if listBoxImages.Count = 0 then exit;

  Viewtile(GetImageWidth, GetImageHeight);
end;

procedure TformMain.btnOpenClick(Sender: TObject);
var
  I: Integer;
begin
  if OpenDialog1.Execute = false then exit;

  if fLabReader <> nil then
  begin
    fLabReader.Free;
    listBoxImages.Clear;
    Image1.Picture := nil;
    DoButtons(false);
    btnOpen.Enabled := true;
    btnAbout.Enabled := true;
  end;

  fLabReader := TLABManager.Create(OpenDialog1.FileName);
  fLabReader.ParseFiles;

  for I := 0 to fLabReader.Count - 1 do
  begin
    if ExtractFileExt(  fLabReader.FileName[i] ) = '.til' then
      listBoxImages.Items.AddObject( ExtractFileName( fLabReader.FileName[i] ), TObject(i) );
  end;


  if listBoxImages.Count > 0 then
  begin
    listBoxImages.Selected[0] := true;
    listBoxImages.OnClick(formMain);
    DoButtons( True );
  end;
end;

procedure TformMain.ViewTile(Width: integer; Height: Integer);
var
  tempbmp: tbitmap;
  TempStream: TExplorerMemoryStream;
begin
  if listBoxImages.ItemIndex=-1 then exit;

  tempbmp:=tbitmap.Create;
  try
    TempStream := TExplorerMemoryStream.Create;
    try
      fLabReader.SaveFileToStream( integer( listBoxImages.Items.Objects[listBoxImages.ItemIndex] ), TempStream, true);
      DecodeTile(tempbmp, width, height, true, TempStream);
      image1.Picture.Assign(tempbmp);
    finally
      TempStream.Free;
    end;
  finally
    tempbmp.Free;
  end;

  if listBoxImages.Enabled then
    listBoxImages.SetFocus; //Set the focus back to the listbox so the arrow keys work again
end;

procedure TformMain.btnSaveClick(Sender: TObject);
var
  TempPng: TPngImage;
begin
  if listBoxImages.ItemIndex = -1 then Exit;

  SaveDialog1.FileName:=PathExtractFileNameNoExt( listBoxImages.Items.Strings[listBoxImages.itemindex] );
  if SaveDialog1.Execute = false then Exit;

  if SaveDialog1.FilterIndex = 1 then
  begin
    TempPng := TPngImage.Create;
    try
      TempPng.Assign( Image1.Picture.Graphic );
      TempPng.SaveToFile(SaveDialog1.FileName);
    finally
      TempPng.Free;
    end;
  end
  else
    image1.Picture.SaveToFile(savedialog1.FileName);

end;

procedure TformMain.SaveDialog1TypeChange(Sender: TObject);
begin
  if savedialog1.filterindex=1 then
    savedialog1.defaultext:='.jpg'
  else
  if savedialog1.filterindex=2 then
    savedialog1.defaultext:='.bmp';
end;

procedure TformMain.btnSaveAllClick(Sender: TObject);
var
  I: Integer;
  MyDialog: tmodalresult;
  TempBmp: TBitmap;
  TempPng: TPngImage;
  TempStream :TExplorerMemoryStream;
begin
  if listBoxImages.Count < 1 then exit;
  if dlgbrowsefolder.Execute = false then exit;

  MyDialog := MyMessageDialog( 'Select the format to save as', mtConfirmation, mbYesNoCancel,['Png', 'Bitmap'] );
  if MyDialog = mrCancel then exit;


  TempBmp := TBitmap.Create;
  try
    TempBmp.FreeImage;
    DoButtons(false);
    BtnCancel.Visible:=true;
    ProgressBar1.Max := listBoxImages.Count;
    ProgressBar1.Min:=0;
    CancelSaveAll:=false;

    for I := 0 to listBoxImages.Count - 1 do
    begin
      if CancelSaveAll then Exit;

      ProgressBar1.StepIt;
      Application.ProcessMessages;


      TempStream := TExplorerMemoryStream.Create;
      try
        fLabReader.SaveFileToStream( integer( listBoxImages.Items.Objects[i] ), TempStream, true);
        DecodeTile(TempBmp, GetImageWidth, GetImageHeight, true, TempStream);
      finally
        TempStream.Free;
      end;

      case MyDialog of
        mrYes: //png
              begin
                TempPng := TPngImage.Create;
                try
                  TempPng.Assign( TempBmp );
                  TempPng.SaveToFile( dlgbrowsefolder.Directory + '\' + pathextractfilenamenoext(listBoxImages.Items.Strings[i]) + '.png' );
                finally
                  TempPng.Free;
                end;
              end;

        mrNo:
              begin
                TempBmp.SaveToFile(dlgbrowsefolder.Directory + '\' + pathextractfilenamenoext(listBoxImages.Items.Strings[i]) + '.bmp');
              end;
      end;
    end;

  finally
    TempBmp.Free;
    btnCancel.Visible:=false;
    DoButtons(true);
    ProgressBar1.Position:=0;
  end;
end;

procedure TformMain.btnCancelClick(Sender: TObject);
begin
  CancelSaveAll:=true;
end;

procedure TformMain.btnDebugClick(Sender: TObject);
begin
  ShowDebug := not ShowDebug;
  menudebug.Checked := ShowDebug;
  Viewtile(GetImageWidth, GetImageHeight);

  if ShowDebug then
    btnDebug.Caption := 'Debug On'
  else
    btnDebug.Caption := 'Debug';
end;

procedure TformMain.menuSaveClick(Sender: TObject);
begin
  btnSave.Click;
end;

procedure TformMain.menuDebugClick(Sender: TObject);
begin
  btnDebug.Click;
end;

procedure TformMain.btnAboutClick(Sender: TObject);
begin
  frmAbout.showmodal;
end;


procedure TformMain.DecodeTile(OutBmp: Tbitmap; Width: integer; Height: integer; ShowProgress: boolean; Source: TExplorerMemoryStream);
var
  BMoffset, NoTiles, i, i2, tilesize: integer;
  xpos, ypos, globalxpos, globalypos: integer;
  ID: string;
  totalcolour: tcolor;
  sourcerect, destrect: trect;
  IsPS2: boolean;
  red, green, blue: integer;
begin
  IsPS2 := False;

  Outbmp.Width :=  Width + 128; //strip of extra tile
  Outbmp.Height := Height;

  //Header
  ID := Source.ReadBlockName;
  if ID = 'TIL0' then
  else
  begin
    //Outbmp.LoadFromResourceName(0, 'ErrorMessage');
    raise EInvalidTilImage.Create('Invalid .til image!');
  end;



  //Bitmap Header
  BMOffset := Source.ReadDWord;
  Source.Seek( bmoffset + 16, sofrombeginning );
  NoTiles := Source.ReadDWord;
  Source.Seek( 16, sofromcurrent ); //seek 16 then check if  = 16 or 32
  if Source.ReadDWord =16 then IsPS2 := true;
  Source.Seek (88, sofromcurrent );

  globalxpos:=0;
  globalypos:=0;

  {if ShowProgress=true then
    Progressbar1.Max:=NoTiles;}

  for i:=1 to NoTiles do
  begin
    {if ShowProgress =true then
      ProgressBar1.Position :=i; }

    TileSize := Source.ReadDWord * Source.ReadDWord; //Width * Height

    xpos:=0;
    ypos:=0;

    if IsPS2=true then
    for i2:=1 to tilesize do
    begin
      TotalColour:= Source.ReadDWord;
      red:=(((TotalColour shr 10) and 31) * 255) div 31;
      Green := (((TotalColour shr 5) and 31) * 255) div 31;
      Blue := ((TotalColour and 31) * 255) div 31;
      Outbmp.Canvas.Pixels[xpos + globalxpos, ypos + globalypos]:=rgbtocolor(red, green, blue);
      inc(xpos);
      if xpos=256 then //a line of a tile is fully drawn
      begin
        xpos:=0;
        inc(ypos); //go to next line
      end
    end

    else
    for i2:=1 to tilesize do
    begin
      Source.Read(totalcolour,3);
      Outbmp.Canvas.Pixels[xpos + globalxpos, ypos + globalypos]:=TotalColour;

      Source.Seek(1, sofromcurrent);
      inc(xpos);
      if xpos=256 then //a line of a tile is fully drawn
      begin
        xpos:=0;
        inc(ypos); //go to next line
      end;
    end;

    if globalxpos=512 then //we've drawn 3 tiles
    begin
      globalxpos:=0;
      inc(globalypos, 256); //go to next tile line down
    end
    else
      inc(globalxpos, 256); //tile is 256 wide, so inc it every time a tile is drawn
  end;

  //copy third tile to where it should be
  sourcerect:=Rect(640, 0, 768, 256);
  destrect:=Rect(512, 256, 640, 512);
  Outbmp.Canvas.CopyRect(destrect, Outbmp.Canvas, sourcerect);
  Outbmp.Width:=width;
  {if ShowProgress=true then
    ProgressBar1.Position:=0;}
end;

end.
