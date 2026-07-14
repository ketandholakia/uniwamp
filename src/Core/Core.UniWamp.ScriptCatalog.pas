unit Core.UniWamp.ScriptCatalog;

interface

uses
  System.Generics.Collections,
  System.JSON,
  System.SysUtils;

type
  TScriptStep = record
    StepType: string;
    Source: string;
    Destination: string;
    Executable: string;
    Arguments: string;
    WorkingDirectory: string;
    Url: string;
    Content: string;
    TimeoutMs: Cardinal;
  end;

  TScriptCatalogItem = record
    Id: string;
    Name: string;
    Category: string;
    Summary: string;
    Homepage: string;
    License: string;
    Version: string;
    Steps: TArray<TScriptStep>;
  end;

  TScriptCatalog = class
  private
    FItems: TArray<TScriptCatalogItem>;
    class function StringValue(const ObjectValue: TJSONObject;
      const Name: string; const DefaultValue: string = ''): string; static;
    class function IntegerValue(const ObjectValue: TJSONObject;
      const Name: string; const DefaultValue: Integer = 0): Integer; static;
    class function ParseItem(const Value: TJSONValue): TScriptCatalogItem; static;
    class function ParseStep(const Value: TJSONValue): TScriptStep; static;
    procedure SortItems;
  public
    class function LoadFromFile(const FileName: string): TScriptCatalog; static;
    function FindById(const Id: string; out Item: TScriptCatalogItem): Boolean;
    property Items: TArray<TScriptCatalogItem> read FItems;
  end;

implementation

uses
  System.IOUtils;

class function TScriptCatalog.StringValue(const ObjectValue: TJSONObject;
  const Name, DefaultValue: string): string;
var
  Value: TJSONValue;
begin
  Result := DefaultValue;
  if not Assigned(ObjectValue) then
    Exit;
  Value := ObjectValue.GetValue(Name);
  if Assigned(Value) then
    Result := Value.Value;
end;

class function TScriptCatalog.IntegerValue(const ObjectValue: TJSONObject;
  const Name: string; const DefaultValue: Integer): Integer;
begin
  Result := StrToIntDef(StringValue(ObjectValue, Name), DefaultValue);
end;

class function TScriptCatalog.ParseStep(const Value: TJSONValue): TScriptStep;
var
  ObjectValue: TJSONObject;
begin
  Result.StepType := '';
  Result.Source := '';
  Result.Destination := '';
  Result.Executable := '';
  Result.Arguments := '';
  Result.WorkingDirectory := '';
  Result.Url := '';
  Result.Content := '';
  Result.TimeoutMs := 0;
  ObjectValue := Value as TJSONObject;
  if not Assigned(ObjectValue) then
    Exit;
  Result.StepType := LowerCase(StringValue(ObjectValue, 'type'));
  Result.Source := StringValue(ObjectValue, 'source');
  Result.Destination := StringValue(ObjectValue, 'destination');
  Result.Executable := StringValue(ObjectValue, 'executable');
  Result.Arguments := StringValue(ObjectValue, 'arguments');
  Result.WorkingDirectory := StringValue(ObjectValue, 'workingDirectory');
  Result.Url := StringValue(ObjectValue, 'url');
  Result.Content := StringValue(ObjectValue, 'content');
  Result.TimeoutMs := IntegerValue(ObjectValue, 'timeoutMs');
end;

class function TScriptCatalog.ParseItem(const Value: TJSONValue): TScriptCatalogItem;
var
  ObjectValue: TJSONObject;
  StepsValue: TJSONArray;
  I: Integer;
begin
  Result.Id := '';
  Result.Name := '';
  Result.Category := '';
  Result.Summary := '';
  Result.Homepage := '';
  Result.License := '';
  Result.Version := '';
  SetLength(Result.Steps, 0);
  ObjectValue := Value as TJSONObject;
  if not Assigned(ObjectValue) then
    Exit;
  Result.Id := StringValue(ObjectValue, 'id');
  Result.Name := StringValue(ObjectValue, 'name');
  Result.Category := StringValue(ObjectValue, 'category');
  Result.Summary := StringValue(ObjectValue, 'summary');
  Result.Homepage := StringValue(ObjectValue, 'homepage');
  Result.License := StringValue(ObjectValue, 'license');
  Result.Version := StringValue(ObjectValue, 'version');
  StepsValue := ObjectValue.GetValue<TJSONArray>('install');
  if Assigned(StepsValue) then
  begin
    SetLength(Result.Steps, StepsValue.Count);
    for I := 0 to StepsValue.Count - 1 do
      Result.Steps[I] := ParseStep(StepsValue.Items[I]);
  end;
end;

procedure TScriptCatalog.SortItems;
var
  I: Integer;
  J: Integer;
  Temporary: TScriptCatalogItem;
begin
  for I := Low(FItems) to High(FItems) - 1 do
    for J := I + 1 to High(FItems) do
      if CompareText(FItems[I].Name, FItems[J].Name) > 0 then
      begin
        Temporary := FItems[I];
        FItems[I] := FItems[J];
        FItems[J] := Temporary;
      end;
end;

class function TScriptCatalog.LoadFromFile(const FileName: string): TScriptCatalog;
var
  RootValue: TJSONValue;
  RootObject: TJSONObject;
  ItemsValue: TJSONArray;
  I: Integer;
begin
  if not TFile.Exists(FileName) then
    raise EFileNotFoundException.CreateFmt('Script catalog not found: %s', [FileName]);
  RootValue := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
  if not Assigned(RootValue) then
    raise EConvertError.CreateFmt('Invalid JSON in script catalog: %s', [FileName]);
  try
    RootObject := RootValue as TJSONObject;
    if not Assigned(RootObject) then
      raise EConvertError.Create('Script catalog root must be a JSON object.');
    ItemsValue := RootObject.GetValue<TJSONArray>('items');
    if not Assigned(ItemsValue) then
      raise EConvertError.Create('Script catalog must contain an items array.');
    Result := TScriptCatalog.Create;
    SetLength(Result.FItems, ItemsValue.Count);
    for I := 0 to ItemsValue.Count - 1 do
      Result.FItems[I] := ParseItem(ItemsValue.Items[I]);
    Result.SortItems;
  finally
    RootValue.Free;
  end;
end;

function TScriptCatalog.FindById(const Id: string; out Item: TScriptCatalogItem): Boolean;
var
  Candidate: TScriptCatalogItem;
begin
  Result := False;
  for Candidate in FItems do
    if SameText(Candidate.Id, Id) then
    begin
      Item := Candidate;
      Exit(True);
    end;
end;

end.
