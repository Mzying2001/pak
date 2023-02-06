unit P;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

const
  PAK_HEADER_MAGIC: uint32 = $BAC04AC0;
  PAK_FILEINFO_ENDFLAG: uint8 = $80;

type
  TPakHeader = record
    magic: uint32;
    version: uint32;
  end;

  TFileTime = record
    dwLowDateTime: uint32;
    dwHighDateTime: uint32;
  end;

  TPakFileInfo = class
    fileSize: uint32;
    fileTime: TFileTime;
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

{ 将FILETIME转为时间戳 }
function FileTimeToTimestamp(fileTime: TFileTime): uint64;
var
  p: PInt32;
begin
  p := PInt32(@Result);
  p^ := fileTime.dwLowDateTime;
  Inc(p);
  p^ := fileTime.dwHighDateTime;
  Result := (Result - 116444736000000000) div 10000000;
end;

{ 将时间戳转为FILETIME }
function TimestampToFileTime(timestamp: uint64): TFileTime;
var
  p: Pint32;
begin
  timestamp := (timestamp * 10000000) + 116444736000000000;
  p := PInt32(@timestamp);
  Result.dwLowDateTime := p^;
  Inc(p);
  Result.dwHighDateTime := p^;
end;

{ 文件所在路径不存在时创建路径 }
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

{ 获取文件夹下的所有文件 }
function GetFileList(dir: string): TStringList;
var
  sr: TSearchRec;
  path: string;
begin
  Result := TStringList.Create;
  if FindFirst(dir + '*', faAnyFile, sr) = 0 then
  begin
    repeat
      if (sr.Name = '.') or (sr.Name = '..') then
        continue;
      path := dir + sr.Name;
      if DirectoryExists(path) then
        Result.AddStrings(GetFileList(path + '\'))
      else
        Result.Add(path);
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
end;

{ 获取文件大小 }
function GetFileSize(const filePath: string): int64;
var
  sr: TSearchRec;
begin
  if not FileExists(filePath) then
  begin
    Result := -1;
    Exit;
  end;
  if FindFirst(filePath, faAnyFile, sr) = 0 then
    Result := int64(sr.FindData.nFileSizeHigh) shl 32 +
      int64(sr.FindData.nFileSizeLow)
  else
    Result := -1;
  FindClose(sr);
end;

{ ------------------------------------------------------------ }

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
  fileTime: TFileTime; //文件修改时间
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

      fileTime.dwLowDateTime := 0;
      fileTime.dwHighDateTime := 0;
      fsIn.Read(fileTime, sizeof(TFileTime));
      PakXor(fileTime, sizeof(TFileTime));

      fileInfo.path := string.Create(pathBuf, 0, pathLen);
      fileInfo.fileSize := fileSize;
      fileInfo.fileTime := fileTime;
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
      FreeAndNil(fsOut);
      FileSetDate(pathFull, FileTimeToTimestamp(fileInfo.fileTime));
      fileInfo := fileInfo.next;
    until fileInfo = nil;

    Result := True;
  except
    on e: Exception do
      SetErrorMessage(e.Message);
  end;

  if fsIn <> nil then
    FreeAndNil(fsIn);
end;

{ ------------------------------------------------------------ }

{ 打包pak }
function Pak(inputPath: string; outputPath: string): boolean;
var
  fsIn: TFileStream = nil; //输入流
  fsOut: TFileStream = nil; //输出流
  outBufLen: SizeInt; //输出缓存大小
  fileList: TStringList; //要打包的文件列表
  fileSizeList: array of uint32; //储存fileList中对应文件的大小
  filePath: string; //文件路径迭代变量
  header: TPakHeader; //文件头
  flag: uint8; //读取文件信息结束的标记
  pathLen: uint8; //文件路径长度
  pathLen2: uint8; //同上，写入路径时储存一个副本
  pathBuf: array[0..255] of char; //文件信息中的路径
  fileSize: uint32; //文件大小
  fileTime: TFileTime; //文件修改时间
  restSize: SizeInt; //剩余要写入文件数据的大小
  i: integer; //迭代变量
begin
  Result := False;
  outBufLen := Length(_outputBuffer);

  if not DirectoryExists(inputPath) then
  begin
    SetErrorMessage('要打包的文件夹不存在');
    exit;
  end;

  inputPath := inputPath.Replace('/', '\');
  if not inputPath.EndsWith('\') then
    inputPath := inputPath + '\';

  try
    fsOut := TFileStream.Create(outputPath, fmOutput);
    fileList := GetFileList(inputPath);

    //获取每个文件的大小
    fileSizeList := [];
    SetLength(fileSizeList, fileList.Count);
    for i := 0 to fileList.Count - 1 do
      fileSizeList[i] := GetFileSize(fileList[i]);

    //写文件头
    header.magic := PAK_HEADER_MAGIC;
    header.version := 0;
    PakXor(header, sizeof(TPakHeader));
    fsOut.Write(header, sizeof(TPakHeader));

    //写文件信息
    for i := 0 to fileList.Count - 1 do
    begin
      filePath := fileList[i];

      flag := 0;
      PakXor(flag, 1);
      fsOut.Write(flag, 1);

      pathLen := Length(filePath) - Length(inputPath);
      pathBuf := filePath.Substring(Length(inputPath), pathLen);
      pathLen2 := pathLen;
      PakXor(pathBuf, pathLen);
      PakXor(pathLen, 1);
      fsOut.Write(pathLen, 1);
      fsOut.Write(pathBuf, pathLen2);

      fileSize := fileSizeList[i];
      PakXor(fileSize, 4);
      fsOut.Write(fileSize, 4);

      fileTime := TimestampToFileTime(FileAge(filePath));
      PakXor(fileTime, sizeof(TFileTime));
      fsOut.Write(fileTime, sizeof(TFileTime));
    end;
    flag := PAK_FILEINFO_ENDFLAG;
    PakXor(flag, 1);
    fsOut.Write(flag, 1);

    //写入文件
    for i := 0 to fileList.Count - 1 do
    begin
      filePath := fileList[i];
      restSize := fileSizeList[i];
      fsIn := TFileStream.Create(filePath, fmOpenRead);
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
      FreeAndNil(fsIn);
    end;

    Result := True;
  except
    on e: Exception do
      SetErrorMessage(e.Message);
  end;

  if fsOut <> nil then
    FreeAndNil(fsOut);
end;

end.
