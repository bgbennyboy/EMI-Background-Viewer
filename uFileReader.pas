unit uFileReader;

interface

uses
	Classes, SysUtils;

type
  TExplorerFileStream = class (TFileStream)

  private
  FXORVal: byte;
    FXORValWORD: word;
    FXORValDWORD: longword;
    procedure SetXORVal(const Value: byte);
  public
    function ReadByte: byte; inline;
    function ReadWord: word; inline;
    function ReadWordBE: word; inline;
    function ReadDWord: longword; inline;
    function ReadDWordBE: longword; inline;
    function ReadBlockName: string; inline;
    function ReadString(Length: integer): string;
    function ReadNullTerminatedString(MaxLength: integer): string;
    function Read(var Buffer; Count: integer): integer; override;
    constructor Create(FileName: string);
    destructor Destroy; override;
    property XORVal: byte read FXORVal write SetXORVal;
end;

implementation

function TExplorerFileStream.Read(var Buffer; Count: Integer): Longint;
var
  n: longint;
  P: PByteArray;
begin
  result:=inherited Read(Buffer,Count);
  P:=@Buffer;

  // The following takes care of XORing all input (unless XORVal is 0)
  if FXORVal=0 then Exit;

  for n:=0 to result-1 do
  begin
    P^[n]:=P^[n] xor FXORVal;
  end;
end;

function TExplorerFileStream.ReadByte: byte;
begin
	Read(result,1);
end;

function TExplorerFileStream.ReadWord: word;
begin
  Read(result,2);
end;

function TExplorerFileStream.ReadWordBE: word;
begin
	result:=ReadByte shl 8
   		    +ReadByte;
end;

procedure TExplorerFileStream.SetXORVal(const Value: byte);
begin
  if FXORVal<>Value then
  begin
    FXORVal := Value;
    FXORValWORD:=(FXORVal shl 8) or FXORVal;
    FXORValDWORD:=(FXORValWORD shl 16) or FXORValWORD;
  end;
end;

function TExplorerFileStream.ReadDWord: longword;
begin
  Read(result,4);
end;

function TExplorerFileStream.ReadDWordBE: longword;
begin
	result:=ReadByte shl 24
          +ReadByte shl 16
   		    +ReadByte shl 8
          +ReadByte;
end;

function TExplorerFileStream.ReadBlockName: string;
begin
   result:=chr(ReadByte)+chr(ReadByte)+chr(ReadByte)+chr(ReadByte);
end;

function TExplorerFileStream.ReadString(Length: integer): string;
var
  n: longword;
begin
  SetLength(result,length);
  for n:=1 to length do
  begin
    result[n]:=Chr(ReadByte);
  end;
end;

function TExplorerFileStream.ReadNullTerminatedString(MaxLength: integer): string;
var
  n: longword;
  RChar: char;
begin
  result:='';
  for n:=1 to MaxLength do
  begin
    RChar:=Chr(ReadByte);
    if RChar=#0 then
      Exit;
    result:=result+RChar;
  end;
end;

constructor TExplorerFileStream.Create(FileName: string);
begin
  inherited Create(Filename, fmopenread);

end;

destructor TExplorerFileStream.Destroy;
begin
  inherited;
end;

end.
