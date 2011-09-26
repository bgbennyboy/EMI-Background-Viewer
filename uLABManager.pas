{
******************************************************
  EMI Background Viewer
  Copyright (c) 2004 - 2010 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit uLABManager;

interface

uses
  classes, sysutils, Contnrs, forms,
  uFileReader, ZLibExGz;

type
    EInvalidFile = class(exception);
    TDebugEvent = procedure(DebugText: string) of object;
    TProgressEvent = procedure(ProgressMax: integer; ProgressPos: integer) of object;
    TOnDoneLoading = procedure(FileNamesCount: integer) of object;
    TLABType = (Grim, EMI);
    TLABChildFile = class
      FileName: string;
      Size: integer;
      Offset: integer;
  end;

type
  TLABManager = class
  protected
    fBundle: TExplorerFileStream;
    fBundleFileName: string;
    fLabType: TLABType;
    fonDoneLoading: TOnDoneLoading;
    fonProgress: TProgressEvent;
    fonDebug: TDebugEvent;
    function DetectBundle: boolean;
    function GetFilesCount: integer;
    function GetFileName(Index: integer): string;
    function GetFileSize(Index: integer): integer;
    function GetFileOffset(Index: integer): integer;
    function IsZipped: boolean;
    procedure Log(Text: string);
  public
    BundleFiles: TObjectList;
    constructor Create(ResourceFile: string);
    destructor Destroy; override;
    procedure ParseFiles;
    procedure SaveFile(FileNo: integer; DestDir, FileName: string);
    procedure SaveFileToStream(FileNo: integer; DestStream: TStream; Unzip: boolean = false);
    procedure SaveFiles(DestDir: string);
    property Count: integer read GetFilesCount;
    property FileName[Index: integer]: string read GetFileName;
    property FileSize[Index: integer]: integer read GetFileSize;
    property FileOffset[Index: integer]: integer read GetFileOffset;
    property LABType: TLABType read fLabType;
  end;

const
  strErrInvalidFile: string = 'Not a valid LAB File';
  strErrFileSize: string = 'File size  <=0! Save cancelled.';
  strErrFileNo: string = 'Invalid file number! Save cancelled.';
  strSavingFile: string = 'Saving file ';

implementation

constructor TLABManager.Create(ResourceFile: string);
begin
  try
    fBundle := TExplorerFileStream.Create(ResourceFile);
  except
    on E: EInvalidFile do
      raise ;
  end;

  fBundleFileName := ExtractFileName(ResourceFile);
  BundleFiles := TObjectList.Create(true);

  if DetectBundle = false then
    raise EInvalidFile.Create(strErrInvalidFile);
end;

destructor TLABManager.Destroy;
begin
  if BundleFiles <> nil then
  begin
    BundleFiles.Free;
    BundleFiles := nil;
  end;

  if fBundle <> nil then
    fBundle.Free;

  inherited;
end;

function TLABManager.DetectBundle: boolean;
var
  BlockName: string;
begin
  Result := false;
  BlockName := fBundle.ReadBlockName;

  if BlockName = 'LABN' then
  begin
    Result := true;
    fBundle.Seek(16, soFromBeginning);
    if fBundle.ReadDWord = 0 then
      fLabType := Grim
    else
      fLabType := EMI;
  end;
end;

function TLABManager.GetFileName(Index: integer): string;
begin
  if (not assigned(BundleFiles)) or (index < 0) or (index > GetFilesCount) then
    Result := ''
  else
    Result := TLABChildFile(BundleFiles.Items[Index]).FileName;
end;

function TLABManager.GetFileOffset(Index: integer): integer;
begin
  if (not assigned(BundleFiles)) or (index < 0) or (index > GetFilesCount) then
    Result := -1
  else
    Result := TLABChildFile(BundleFiles.Items[Index]).Offset;
end;

function TLABManager.GetFilesCount: integer;
begin
  if BundleFiles <> nil then
    Result := BundleFiles.Count
  else
    Result := 0;
end;

function TLABManager.GetFileSize(Index: integer): integer;
begin
  if (not assigned(BundleFiles)) or (index < 0) or (index > GetFilesCount) then
    Result := -1
  else
    Result := TLABChildFile(BundleFiles.Items[Index]).Size;
end;

function TLABManager.IsZipped: boolean;
begin
  if fBundle.ReadDWord = 559903 then
    result:=true
  else result:=false;

  fBundle.Seek(-4, soFromCurrent);
end;

procedure TLABManager.Log(Text: string);
begin
  if assigned(fonDebug) then
    fonDebug(Text);
end;

procedure TLABManager.ParseFiles;
var
  numFiles, NameDirSize, NameDirOffset, i, CurrFile: integer;
  FileObject: TLABChildFile;
  TempByte: byte;
  TempFilename: string;
begin
  fBundle.Seek(8, soFromBeginning);
  numFiles := fBundle.ReadDWord; // Number of files in LAB
  NameDirSize := fBundle.ReadDWord; // Size of Name Directory
  if fLabType = EMI then
    NameDirOffset := fBundle.ReadDWord - 81167
  else
    NameDirOffset := 16 + (16 * numFiles);

  // Parse files
  for i := 0 to numFiles - 1 do
  begin
    FileObject := TLABChildFile.Create;
    fBundle.Seek(4, sofromcurrent); // Offset in Name Directory
    FileObject.Offset := fBundle.ReadDWord;
    FileObject.Size := fBundle.ReadDWord;
    fBundle.Seek(4, sofromcurrent); // 4 zero bytes

    BundleFiles.Add(FileObject);
  end;

  // Add names
  fBundle.Seek(NameDirOffset, soFromBeginning);

  //Parse namedir and extract the null terminated filenames
  CurrFile := 0;
  for i := 0 to NameDirSize - 1 do
  begin
    TempByte:=fBundle.readbyte;
    if TempByte=0 then //Because the filenames are null terminated
    begin
       TLABChildFile(BundleFiles[CurrFile]).Filename := TempFilename;
       TempFilename:='';
       inc(CurrFile);
    end
    else
      TempFilename:=TempFilename + chr(TempByte xor $96); //do the xoring here - if we do it in filereader then tempbyte doesnt =0 because its already xor'ed
  end;


  if (assigned(fonDoneLoading)) then
    fonDoneLoading(numFiles);
end;

procedure TLABManager.SaveFile(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: TFileStream;
begin
  if TLABChildFile(BundleFiles.Items[FileNo]).Size <= 0 then
  begin
    Log(strErrFileSize);
    exit;
  end;

  if (FileNo < 0) or (FileNo > BundleFiles.Count) then
  begin
    Log(strErrFileNo);
    exit;
  end;

  Log(strSavingFile + FileName);

  SaveFile := TFileStream.Create(IncludeTrailingPathDelimiter(DestDir)
      + FileName, fmOpenWrite or fmCreate);
  try
    SaveFileToStream(FileNo, SaveFile);
  finally
    SaveFile.Free;
  end;

end;

procedure TLABManager.SaveFiles(DestDir: string);
var
  i: integer;
  SaveFile: TFileStream;
begin
  for i := 0 to BundleFiles.Count - 1 do
  begin
    ForceDirectories(extractfilepath(IncludeTrailingPathDelimiter(DestDir)
                          + TLABChildFile(BundleFiles.Items[i]).FileName));
    SaveFile := TFileStream.Create(IncludeTrailingPathDelimiter(DestDir)
                          + TLABChildFile(BundleFiles.Items[i]).FileName,
                            fmOpenWrite or fmCreate);
    try
      SaveFileToStream(i, SaveFile);
    finally
      SaveFile.Free;
      if assigned(fonProgress) then
        fonProgress(GetFilesCount - 1, i);
      Application.Processmessages;
    end;
  end;

end;

procedure TLABManager.SaveFileToStream(FileNo: integer; DestStream: TStream; Unzip: boolean = false);
var
  Ext: string;
  TempStream: TMemoryStream;
begin
  if TLABChildFile(BundleFiles.Items[FileNo]).Size <= 0 then
  begin
    Log(strErrFileSize);
    exit;
  end;

  if (FileNo < 0) or (FileNo > BundleFiles.Count) then
  begin
    Log(strErrFileNo);
    exit;
  end;

  Ext := Uppercase(ExtractFileExt(TLABChildFile(BundleFiles.Items[FileNo]).FileName));

  fBundle.Seek(TLABChildFile(BundleFiles.Items[FileNo]).Offset, soFromBeginning);

  if (Unzip) and (IsZipped) then
  begin
    TempStream := TMemoryStream.Create;
    try
      TempStream.CopyFrom(fBundle, TLABChildFile(BundleFiles.Items[FileNo]).Size);
      TempStream.Position := 0;
      GZDecompressStream(TempStream, DestStream);
    finally
      TempStream.Free;
    end;
  end
  else
    DestStream.CopyFrom(fBundle, TLABChildFile(BundleFiles.Items[FileNo]).Size);

  DestStream.Position := 0;
end;

end.
