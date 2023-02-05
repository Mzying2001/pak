unit P;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

type
  TPakHeader = record
    magic: uint32;
    version: uint32;
  end;

  TPakFileInfo = class
    fileSize: uint32;
    timeStamp: uint64;
    path: string;
    next: TPakFileInfo;
  end;

function Pak(inputPath: string; outputPath: string): boolean;
function Unpak(inputPath: string; outputPath: string): boolean;
procedure ShowErrorMessage;

implementation

var
  _errorMessage: string = '';

procedure SetErrorMessage(Value: string);
begin
  _errorMessage := Value;
end;

procedure ShowErrorMessage;
begin
  MessageDlg('错误', _errorMessage, mtError, [mbOK], '');
end;

function Unpak(inputPath: string; outputPath: string): boolean;
begin
  Result := False;
  if not FileExists(inputPath) then
  begin
    SetErrorMessage('要解包的pak文件不存在');
    exit;
  end;
  //TODO: unpak
  Result := True;
end;

function Pak(inputPath: string; outputPath: string): boolean;
begin
  Result := False;
  //TODO: pak
  Result := True;
end;

end.
