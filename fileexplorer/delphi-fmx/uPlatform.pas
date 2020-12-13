unit uPlatform;

interface

uses
  System.Types,
  uTypes;

procedure BulkObtainFiletypes(const Names: TStringDynArray; var FilesData: TFilesData; TmpFilename: string);

implementation

uses
{$IFDEF LINUX}
  FMX.Types,
  Posix.Base,
  Posix.Errno,
  Posix.Fcntl,
{$ENDIF}
  System.IOUtils,
  System.SysUtils;

{$IFDEF LINUX}
type
  TStreamHandle = pointer;

///  <summary>
///    Man Page: http://man7.org/linux/man-pages/man3/popen.3.html
///  </summary>
function popen(const command: MarshaledAString; const _type: MarshaledAString): TStreamHandle; cdecl; external libc name _PU + 'popen';

///  <summary>
///    Man Page: http://man7.org/linux/man-pages/man3/pclose.3p.html
///  </summary>
function pclose(filehandle: TStreamHandle): int32; cdecl; external libc name _PU + 'pclose';

///  <summary>
///    Man Page: http://man7.org/linux/man-pages/man3/fgets.3p.html
///  </summary>
function fgets(buffer: pointer; size: int32; Stream: TStreamHAndle): pointer; cdecl; external libc name _PU + 'fgets';

///  <summary>
///    Utility function to return a buffer of ASCII-Z data as a string.
///  </summary>
function BufferToString(Buffer: Pointer; MaxSize: Uint32 ): string;
var
  cursor: ^uint8;
  EndOfBuffer: nativeuint;
begin
  Result := '';
  if not assigned(Buffer) then begin
    exit;
  end;
  cursor := Buffer;
  EndOfBuffer := NativeUint(cursor) + MaxSize;
  while (NativeUint(cursor)<EndOfBuffer) and (cursor^<>0) do begin
    Result := Result + chr(cursor^);
    cursor := pointer( succ(NativeUInt(cursor)) );
  end;
end;

function GetFileTypes(ListFilename: string): TArray<string>;
var
  Handle: TStreamHandle;
  Data: array[0..511] of uint8;
  Output: string;
begin
  Handle := popen(PAnsiChar('mimetype -d -b -f ' + AnsiString(ListFilename)),'r');
  try
    while fgets(@data[0],Sizeof(Data),Handle)<>nil do begin
      Output := Output + BufferToString(@Data[0],sizeof(Data));
    end;
  finally
    pclose(Handle);
  end;
  Result := Output.Split([sLineBreak]);
  if Result[High(Result)] = '' then
    SetLength(Result, Length(Result) - 1);
end;
{$ENDIF}

procedure BulkObtainFiletypes(const Names: TStringDynArray; var FilesData: TFilesData; TmpFilename: string);
begin
{$IFDEF LINUX}
  TFile.WriteAllLines(TmpFilename, Names);
  var Types := GetFileTypes(TmpFilename);
  Assert(High(FilesData) = High(Types));
  for var i := Low(Types) to High(Types) do
    FilesData[i].Filetype := Types[i];
{$ENDIF}
end;

end.
