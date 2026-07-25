unit Core.UniWamp.SyncEngine;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.Masks,
  Core.UniWamp.SyncTransport;

type
  TSyncPlanItemKind = (spiUpload, spiDownload, spiDeleteRemote, spiDeleteLocal, spiCreateRemoteDir);

  TSyncPlanItem = record
    Kind: TSyncPlanItemKind;
    RelativePath: string; // POSIX-style, relative to the sync root
    LocalPath: string;    // full local path (blank for spiDeleteRemote/spiCreateRemoteDir)
    RemotePath: string;   // full remote path (blank for spiDeleteLocal)
    Size: Int64;
  end;

  TSyncPlan = TArray<TSyncPlanItem>;

  TSyncExecutionResult = record
    Success: Boolean;
    Message: string;
    FilesTransferred: Integer;
    FilesDeleted: Integer;
    BytesTransferred: Int64;
  end;

  TSyncEngineLogEvent = reference to procedure(const Text: string);
  // Return False from OnProgress to cancel the run.
  TSyncEngineProgressEvent = reference to function(const RelativePath: string;
    const BytesTransferred, TotalBytes: Int64; const IsUpload: Boolean): Boolean;

  TSyncEngine = class
  private
    class function EnsureContainedLocalPath(const RootPath, RelativePath: string): string; static;
    class function NormalizeRelativePath(const RelativePath: string): string; static;
    class function ValidateRemoteEntryName(const Name, ParentPath: string): string; static;
    class function LocalFileTree(const RootPath: string): TDictionary<string, TPair<Int64, TDateTime>>;
    class function RemoteFileTree(const Transport: ISyncTransport; const RootPath: string): TDictionary<string, TPair<Int64, TDateTime>>;
    class function IsExcluded(const RelativePath: string; const Excludes: TArray<string>): Boolean;
    class function NeedsTransfer(const LocalSize: Int64; const LocalModified: TDateTime;
      const RemoteSize: Int64; const RemoteModified: TDateTime): Boolean;
  public
    // Direction is 'upload' (LocalPath -> RemotePath) or 'download' (RemotePath -> LocalPath).
    class function BuildPlan(const Transport: ISyncTransport; const LocalPath, RemotePath, Direction: string;
      const Excludes: TArray<string>; const DeleteEnabled: Boolean): TSyncPlan;
    class function ExecutePlan(const Transport: ISyncTransport; const Plan: TSyncPlan;
      const DryRun: Boolean; const OnLog: TSyncEngineLogEvent;
      const OnProgress: TSyncEngineProgressEvent): TSyncExecutionResult;
  end;

implementation

uses
  Core.UniWamp.AtomicFile;

type
  TProgressContext = record
    OnProgress: TSyncEngineProgressEvent;
    RelativePath: string;
  end;

var
  GProgressContext: TProgressContext;

function ForwardProgress(const FileName: string; const BytesTransferred, TotalBytes: Int64;
  const IsUpload: Boolean): Boolean;
begin
  if Assigned(GProgressContext.OnProgress) then
    Result := GProgressContext.OnProgress(GProgressContext.RelativePath, BytesTransferred,
      TotalBytes, IsUpload)
  else
    Result := True;
end;

{ TSyncEngine }

class function TSyncEngine.NormalizeRelativePath(const RelativePath: string): string;
begin
  Result := Trim(StringReplace(RelativePath, '\', '/', [rfReplaceAll]));
  while Result.StartsWith('/') do
    Delete(Result, 1, 1);
  while Result.EndsWith('/') do
    Delete(Result, Length(Result), 1);
end;

class function TSyncEngine.ValidateRemoteEntryName(const Name, ParentPath: string): string;
begin
  Result := Trim(Name);
  if (Result = '') or (Result = '.') or (Result = '..') then
    raise ESyncTransportError.CreateFmt('Remote listing returned an invalid entry name under "%s".',
      [ParentPath]);
  if (Pos('/', Result) > 0) or (Pos('\', Result) > 0) or (Pos(':', Result) > 0) then
    raise ESyncTransportError.CreateFmt(
      'Remote listing returned an unsafe entry name "%s" under "%s".', [Name, ParentPath]);
end;

class function TSyncEngine.EnsureContainedLocalPath(const RootPath, RelativePath: string): string;
var
  ExpandedRoot: string;
  ExpandedPath: string;
begin
  ExpandedRoot := IncludeTrailingPathDelimiter(ExpandFileName(RootPath));
  ExpandedPath := ExpandFileName(TPath.Combine(ExpandedRoot, RelativePath.Replace('/', PathDelim)));
  if not SameText(Copy(ExpandedPath, 1, Length(ExpandedRoot)), ExpandedRoot) then
    raise ESyncTransportError.CreateFmt(
      'Sync path "%s" resolves outside the local root "%s".', [RelativePath, RootPath]);
  Result := ExpandedPath;
end;

class function TSyncEngine.IsExcluded(const RelativePath: string; const Excludes: TArray<string>): Boolean;
var
  Pattern: string;
  FileName: string;
begin
  Result := False;
  if Length(Excludes) = 0 then
    Exit;
  FileName := ExtractFileName(RelativePath);
  for Pattern in Excludes do
  begin
    if Trim(Pattern) = '' then
      Continue;
    if MatchesMask(RelativePath, Pattern) or MatchesMask(FileName, Pattern) then
      Exit(True);
  end;
end;

class function TSyncEngine.NeedsTransfer(const LocalSize: Int64; const LocalModified: TDateTime;
  const RemoteSize: Int64; const RemoteModified: TDateTime): Boolean;
const
  // FTP/SFTP timestamp resolution is commonly 1-2 seconds; give a small margin.
  ToleranceSeconds = 2 / SecsPerDay;
begin
  if LocalSize <> RemoteSize then
    Exit(True);
  if (RemoteModified = 0) or (LocalModified = 0) then
    Exit(False); // can't compare reliably; size match is the best signal we have
  Result := (LocalModified - RemoteModified) > ToleranceSeconds;
end;

class function TSyncEngine.LocalFileTree(const RootPath: string): TDictionary<string, TPair<Int64, TDateTime>>;
var
  Files: TArray<string>;
  FileName: string;
  RelativePath: string;
  Info: TPair<Int64, TDateTime>;
  Stream: TFileStream;
begin
  Result := TDictionary<string, TPair<Int64, TDateTime>>.Create;
  if not TDirectory.Exists(RootPath) then
    Exit;
  Files := TDirectory.GetFiles(RootPath, '*', TSearchOption.soAllDirectories);
  for FileName in Files do
  begin
    RelativePath := StringReplace(FileName.Substring(Length(IncludeTrailingPathDelimiter(RootPath))),
      '\', '/', [rfReplaceAll]);
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      Info.Key := Stream.Size;
    finally
      Stream.Free;
    end;
    Info.Value := TFile.GetLastWriteTimeUtc(FileName);
    Result.AddOrSetValue(RelativePath, Info);
  end;
end;

class function TSyncEngine.RemoteFileTree(const Transport: ISyncTransport;
  const RootPath: string): TDictionary<string, TPair<Int64, TDateTime>>;

  procedure Walk(const RemoteDir, RelativePrefix: string);
  var
    Entries: TRemoteEntries;
    Entry: TRemoteEntry;
    Info: TPair<Int64, TDateTime>;
    ChildRelative: string;
    EntryName: string;
  begin
    Entries := Transport.ListDirectory(RemoteDir);
    for Entry in Entries do
    begin
      EntryName := ValidateRemoteEntryName(Entry.Name, RemoteDir);
      if RelativePrefix = '' then
        ChildRelative := EntryName
      else
        ChildRelative := RelativePrefix + '/' + EntryName;
      ChildRelative := NormalizeRelativePath(ChildRelative);
      if Entry.IsDirectory then
        Walk(RemoteDir + '/' + EntryName, ChildRelative)
      else
      begin
        Info.Key := Entry.Size;
        Info.Value := Entry.ModifiedUtc;
        Result.AddOrSetValue(ChildRelative, Info);
      end;
    end;
  end;

begin
  Result := TDictionary<string, TPair<Int64, TDateTime>>.Create;
  if Transport.RemoteDirectoryExists(RootPath) then
    Walk(RootPath, '');
end;

class function TSyncEngine.BuildPlan(const Transport: ISyncTransport; const LocalPath, RemotePath,
  Direction: string; const Excludes: TArray<string>; const DeleteEnabled: Boolean): TSyncPlan;
var
  LocalTree, RemoteTree: TDictionary<string, TPair<Int64, TDateTime>>;
  Plan: TList<TSyncPlanItem>;
  Item: TSyncPlanItem;
  RelativePath: string;
  SafeRelativePath: string;
  LocalInfo, RemoteInfo: TPair<Int64, TDateTime>;
  CreatedDirs: TDictionary<string, Boolean>;

  procedure EnsureRemoteDirsFor(const RelPath: string);
  var
    Dir: string;
  begin
    Dir := ExtractFilePath(RelPath).TrimRight(['/']);
    if (Dir = '') or CreatedDirs.ContainsKey(Dir) then
      Exit;
    CreatedDirs.Add(Dir, True);
    Item.Kind := spiCreateRemoteDir;
    Item.RelativePath := Dir;
    Item.LocalPath := '';
    Item.RemotePath := RemotePath + '/' + Dir;
    Item.Size := 0;
    Plan.Add(Item);
  end;

begin
  Plan := TList<TSyncPlanItem>.Create;
  CreatedDirs := TDictionary<string, Boolean>.Create;
  try
    LocalTree := LocalFileTree(LocalPath);
    try
      RemoteTree := RemoteFileTree(Transport, RemotePath);
      try
        if SameText(Direction, 'upload') then
        begin
          for RelativePath in LocalTree.Keys do
          begin
            SafeRelativePath := NormalizeRelativePath(RelativePath);
            if IsExcluded(SafeRelativePath, Excludes) then
              Continue;
            LocalInfo := LocalTree[RelativePath];
            if RemoteTree.TryGetValue(SafeRelativePath, RemoteInfo) and
              not NeedsTransfer(LocalInfo.Key, LocalInfo.Value, RemoteInfo.Key, RemoteInfo.Value) then
              Continue;
            EnsureRemoteDirsFor(SafeRelativePath);
            Item.Kind := spiUpload;
            Item.RelativePath := SafeRelativePath;
            Item.LocalPath := EnsureContainedLocalPath(LocalPath, SafeRelativePath);
            Item.RemotePath := RemotePath + '/' + SafeRelativePath;
            Item.Size := LocalInfo.Key;
            Plan.Add(Item);
          end;
          if DeleteEnabled then
            for RelativePath in RemoteTree.Keys do
              if not LocalTree.ContainsKey(RelativePath) and not IsExcluded(RelativePath, Excludes) then
              begin
                Item.Kind := spiDeleteRemote;
                Item.RelativePath := RelativePath;
                Item.LocalPath := '';
                Item.RemotePath := RemotePath + '/' + RelativePath;
                Item.Size := 0;
                Plan.Add(Item);
              end;
        end
        else // download
        begin
          for RelativePath in RemoteTree.Keys do
          begin
            if IsExcluded(RelativePath, Excludes) then
              Continue;
            RemoteInfo := RemoteTree[RelativePath];
            if LocalTree.TryGetValue(RelativePath, LocalInfo) and
              not NeedsTransfer(RemoteInfo.Key, RemoteInfo.Value, LocalInfo.Key, LocalInfo.Value) then
              Continue;
            Item.Kind := spiDownload;
            Item.RelativePath := RelativePath;
            Item.LocalPath := EnsureContainedLocalPath(LocalPath, RelativePath);
            Item.RemotePath := RemotePath + '/' + RelativePath;
            Item.Size := RemoteInfo.Key;
            Plan.Add(Item);
          end;
          if DeleteEnabled then
            for RelativePath in LocalTree.Keys do
              if not RemoteTree.ContainsKey(RelativePath) and not IsExcluded(RelativePath, Excludes) then
              begin
                Item.Kind := spiDeleteLocal;
                Item.RelativePath := RelativePath;
                Item.LocalPath := EnsureContainedLocalPath(LocalPath, RelativePath);
                Item.RemotePath := '';
                Item.Size := 0;
                Plan.Add(Item);
              end;
        end;
      finally
        RemoteTree.Free;
      end;
    finally
      LocalTree.Free;
    end;
    Result := Plan.ToArray;
  finally
    CreatedDirs.Free;
    Plan.Free;
  end;
end;

class function TSyncEngine.ExecutePlan(const Transport: ISyncTransport; const Plan: TSyncPlan;
  const DryRun: Boolean; const OnLog: TSyncEngineLogEvent;
  const OnProgress: TSyncEngineProgressEvent): TSyncExecutionResult;
var
  Item: TSyncPlanItem;
  TempLocalPath: string;

  procedure Log(const Text: string);
  begin
    if Assigned(OnLog) then
      OnLog(Text);
  end;

begin
  Result.Success := True;
  Result.Message := '';
  Result.FilesTransferred := 0;
  Result.FilesDeleted := 0;
  Result.BytesTransferred := 0;
  try
    for Item in Plan do
    begin
      case Item.Kind of
        spiCreateRemoteDir:
          begin
            Log('mkdir  ' + Item.RemotePath);
            if not DryRun then
              Transport.EnsureRemoteDirectory(Item.RemotePath);
          end;
        spiUpload:
          begin
            Log('upload ' + Item.RelativePath + Format(' (%d bytes)', [Item.Size]));
            if not DryRun then
            begin
              GProgressContext.OnProgress := OnProgress;
              GProgressContext.RelativePath := Item.RelativePath;
              Transport.UploadFile(Item.LocalPath, Item.RemotePath, ForwardProgress);
              Inc(Result.FilesTransferred);
              Inc(Result.BytesTransferred, Item.Size);
            end;
          end;
        spiDownload:
          begin
            Log('download ' + Item.RelativePath + Format(' (%d bytes)', [Item.Size]));
            if not DryRun then
            begin
              TempLocalPath := Item.LocalPath + '.' + GUIDToString(TGUID.NewGuid) + '.part';
              TDirectory.CreateDirectory(ExtractFilePath(Item.LocalPath));
              try
                GProgressContext.OnProgress := OnProgress;
                GProgressContext.RelativePath := Item.RelativePath;
                Transport.DownloadFile(Item.RemotePath, TempLocalPath, ForwardProgress);
                AtomicReplaceFile(TempLocalPath, Item.LocalPath);
                Inc(Result.FilesTransferred);
                Inc(Result.BytesTransferred, Item.Size);
              finally
                if FileExists(TempLocalPath) then
                  TFile.Delete(TempLocalPath);
              end;
            end;
          end;
        spiDeleteRemote:
          begin
            Log('delete remote ' + Item.RelativePath);
            if not DryRun then
            begin
              Transport.DeleteRemoteFile(Item.RemotePath);
              Inc(Result.FilesDeleted);
            end;
          end;
        spiDeleteLocal:
          begin
            Log('delete local ' + Item.RelativePath);
            if not DryRun then
            begin
              TFile.Delete(Item.LocalPath);
              Inc(Result.FilesDeleted);
            end;
          end;
      end;
    end;
    if DryRun then
      Result.Message := Format('Dry run: %d item(s) would be processed.', [Length(Plan)])
    else
      Result.Message := Format('Sync completed: %d file(s) transferred (%d bytes), %d deleted.',
        [Result.FilesTransferred, Result.BytesTransferred, Result.FilesDeleted]);
  except
    on E: Exception do
    begin
      Result.Success := False;
      Result.Message := E.Message;
    end;
  end;
end;

end.
