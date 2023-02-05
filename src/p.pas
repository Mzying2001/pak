unit P;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

const
  PAK_HEADER_MAGIC: uint32 = $BAC04AC0;

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
  _outputBuffer: array[0..65535] of byte;

procedure SetErrorMessage(Value: string);
begin
  _errorMessage := Value;
end;

procedure ShowErrorMessage;
begin
  MessageDlg('错误', _errorMessage, mtError, [mbOK], '');
end;

procedure PakXor(var buf; size: SizeInt);
var
  p: PByte;
begin
  p := PByte(@buf);
  while size > 0 do
  begin
    p^ := p^ xor $F7;
    Inc(p);
    size := size - 1;
  end;
end;

procedure CreateDirOfFile(filePath: string);
var
  i: integer;
  dir: string;
begin
  for i := 0 to Length(filePath) - 1 do
    if filePath[i] = '\' then
    begin
      dir := filePath.Substring(0, i);
      if not DirectoryExists(dir) then
        CreateDir(dir);
    end;
end;

{ 解包pak }
function Unpak(inputPath: string; outputPath: string): boolean;
var
  fs: TFileStream = nil; //输入流
  fsout: TFileStream = nil; //输出流
  header: TPakHeader; //文件头
  flag: uint8 = 0; //读取文件信息结束的标记
  pathLen: uint8 = 0; //文件路径长度
  pathBuf: array[0..255] of char; //储存文件路径
  fileSize: uint32 = 0; //文件大小
  timeStamp: uint64 = 0; //文件时间戳
  firstFile: TPakFileInfo = nil; //第一个文件
  fileInfo: TPakFileInfo = nil; //用于向链表添加数据和迭代变量
  pathTmp: string; //用于拼接输出文件的路径
begin
  Result := False;
  if not FileExists(inputPath) then
  begin
    SetErrorMessage('要解包的pak文件不存在');
    exit;
  end;

  outputPath := outputPath.Replace('/', '\');
  if not outputPath.EndsWith('\') then
     outputPath := outputPath + '\';

  try
    fs := TFileStream.Create(inputPath, fmOpenRead);

    //读文件头
    fs.Read(header, sizeof(TPakHeader));
    PakXor(header, sizeof(TPakHeader));
    if header.magic <> PAK_HEADER_MAGIC then
       raise Exception.Create('输入的pak文件格式不正确');

    //读文件信息
    while True do
    begin
      fs.Read(flag, 1);
      PakXor(flag, 1);
      if flag <> 0 then
         break;

      if fileInfo = nil then
      begin
        firstFile := TPakFileInfo.Create;
        fileInfo := firstFile;
      end
      else
      begin
        fileInfo.next := TPakFileInfo.Create;
        fileInfo := fileInfo.next;
      end;

      fs.Read(pathLen, 1);
      PakXor(pathLen, 1);

      fs.Read(pathBuf, pathLen);
      PakXor(pathBuf, pathLen);

      fs.Read(fileSize, 4);
      PakXor(fileSize, 4);

      fs.Read(timeStamp, 8);
      PakXor(timeStamp, 8);

      fileInfo.path := string.Create(pathBuf, 0, pathLen);
      fileInfo.fileSize := fileSize;
      fileInfo.timeStamp := timeStamp;
      fileInfo.next := nil;
    end;

    //导出文件
    fileInfo := firstFile;
    repeat
      fileSize := fileInfo.fileSize;
      pathTmp := outputPath + fileInfo.path;
      CreateDirOfFile(pathTmp);
      fsout := TFileStream.Create(pathTmp, fmOutput);
      while fileSize >= Length(_outputBuffer) do
      begin
        fs.Read(_outputBuffer, Length(_outputBuffer));
        PakXor(_outputBuffer, Length(_outputBuffer));
        fsout.Write(_outputBuffer, Length(_outputBuffer));
        fileSize := fileSize - Length(_outputBuffer);
      end;
      if fileSize <> 0 then
      begin
        fs.Read(_outputBuffer, fileSize);
        PakXor(_outputBuffer, fileSize);
        fsout.Write(_outputBuffer, fileSize);
      end;
      fileInfo := fileInfo.next;
      FreeAndNil(fsout);
    until fileInfo = nil;

    Result := True;
  except
    on e: Exception do
      SetErrorMessage(e.Message);
  end;

  if fs <> nil then
     FreeAndNil(fs);
end;

{ 打包pak }
function Pak(inputPath: string; outputPath: string): boolean;
begin
  Result := False;
  if not DirectoryExists(inputPath) then
  begin
    SetErrorMessage('要打包的文件夹不存在');
    exit;
  end;
  //TODO: pak
  Result := True;
end;

end.
