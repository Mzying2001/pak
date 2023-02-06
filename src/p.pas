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
  fsIn: TFileStream = nil; //输入流
  fsOut: TFileStream = nil; //输出流
  outBufLen: SizeInt; //输出缓存大小
  header: TPakHeader; //文件头
  flag: uint8 = 0; //读取文件信息结束的标记
  pathLen: uint8 = 0; //文件路径长度
  pathBuf: array[0..255] of char = ''; //储存文件路径
  fileSize: uint32 = 0; //文件大小
  timeStamp: uint64 = 0; //文件时间戳
  firstFile: TPakFileInfo = nil; //第一个文件
  fileInfo: TPakFileInfo = nil; //用于向链表添加数据和迭代变量
  pathFull: string; //输出文件的完整路径
  restSize: SizeInt; //储存输出文件时剩余的大小
begin
  Result := False;
  outBufLen := Length(_outputBuffer);

  if not FileExists(inputPath) then
  begin
    SetErrorMessage('要解包的pak文件不存在');
    exit;
  end;

  outputPath := outputPath.Replace('/', '\');
  if not outputPath.EndsWith('\') then
     outputPath := outputPath + '\';

  try
    fsIn := TFileStream.Create(inputPath, fmOpenRead);

    //读文件头
    header.magic := 0;
    header.version := 0;
    fsIn.Read(header, sizeof(TPakHeader));
    PakXor(header, sizeof(TPakHeader));
    if header.magic <> PAK_HEADER_MAGIC then
       raise Exception.Create('输入的pak文件格式不正确');

    //读文件信息
    while True do
    begin
      fsIn.Read(flag, 1);
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

      fsIn.Read(pathLen, 1);
      PakXor(pathLen, 1);

      fsIn.Read(pathBuf, pathLen);
      PakXor(pathBuf, pathLen);

      fsIn.Read(fileSize, 4);
      PakXor(fileSize, 4);

      fsIn.Read(timeStamp, 8);
      PakXor(timeStamp, 8);

      fileInfo.path := string.Create(pathBuf, 0, pathLen);
      fileInfo.fileSize := fileSize;
      fileInfo.timeStamp := timeStamp;
      fileInfo.next := nil;
    end;

    //导出文件
    fileInfo := firstFile;
    repeat
      restSize := fileInfo.fileSize;
      pathFull := outputPath + fileInfo.path;
      CreateDirOfFile(pathFull);
      fsOut := TFileStream.Create(pathFull, fmOutput);
      while restSize >= outBufLen do
      begin
        fsIn.Read(_outputBuffer, outBufLen);
        PakXor(_outputBuffer, outBufLen);
        fsOut.Write(_outputBuffer, outBufLen);
        restSize := restSize - outBufLen;
      end;
      if restSize <> 0 then
      begin
        fsIn.Read(_outputBuffer, restSize);
        PakXor(_outputBuffer, restSize);
        fsOut.Write(_outputBuffer, restSize);
      end;
      fileInfo := fileInfo.next;
      FreeAndNil(fsOut);
    until fileInfo = nil;

    Result := True;
  except
    on e: Exception do
      SetErrorMessage(e.Message);
  end;

  if fsIn <> nil then
     FreeAndNil(fsIn);
end;

{ 打包pak }
function Pak(inputPath: string; outputPath: string): boolean;
var
  fsIn: TFileStream = nil; //输入流
  fsOut: TFileStream = nil; //输出流
  outBufLen: SizeInt; //输出缓存大小
begin
  Result := False;
  outBufLen := Length(_outputBuffer);

  if not DirectoryExists(inputPath) then
  begin
    SetErrorMessage('要打包的文件夹不存在');
    exit;
  end;

  try
    fsOut := TFileStream.Create(outputPath, fmOutput);

    //TODO

    Result := True;
  except
    on e: Exception do
      SetErrorMessage(e.Message);
  end;

  if fsOut <> nil then
    FreeAndNil(fsOut);
end;

end.
