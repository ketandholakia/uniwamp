unit Core.UniWamp.ServiceLocator;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections;

type
  TServiceLocator = class
  private
    FServices: TDictionary<string, IInterface>;
    class var FInstance: TServiceLocator;
    class function GetInstance: TServiceLocator; static;
  public
    constructor Create;
    destructor Destroy; override;

    class property Instance: TServiceLocator read GetInstance;

    procedure RegisterService<I: IInterface>(const Service: I);
    function GetService<I: IInterface>: I;
  end;

implementation

{ TServiceLocator }

constructor TServiceLocator.Create;
begin
  inherited Create;
  FServices := TDictionary<string, IInterface>.Create;
end;

destructor TServiceLocator.Destroy;
begin
  FServices.Free;
  inherited Destroy;
end;

class function TServiceLocator.GetInstance: TServiceLocator;
begin
  if FInstance = nil then
    FInstance := TServiceLocator.Create;
  Result := FInstance;
end;

procedure TServiceLocator.RegisterService<I>(const Service: I);
var
  Context: TRttiContext;
  Typ: TRttiType;
begin
  Context := TRttiContext.Create;
  Typ := Context.GetType(TypeInfo(I));
  FServices.AddOrSetValue(Typ.QualifiedName, Service);
end;

function TServiceLocator.GetService<I>: I;
var
  Context: TRttiContext;
  Typ: TRttiType;
  Intf: IInterface;
begin
  Context := TRttiContext.Create;
  Typ := Context.GetType(TypeInfo(I));
  if FServices.TryGetValue(Typ.QualifiedName, Intf) then
  begin
    if not Supports(Intf, GetTypeData(TypeInfo(I))^.Guid, Result) then
      raise Exception.CreateFmt('Service registered for %s does not support the interface', [Typ.QualifiedName]);
  end
  else
    raise Exception.CreateFmt('Service not registered for %s', [Typ.QualifiedName]);
end;

initialization

finalization
  if Assigned(TServiceLocator.FInstance) then
    TServiceLocator.FInstance.Free;

end.
