unit Core.UniWamp.Types;

interface

type
  TRuntimeActionResult = record
    Success: Boolean;
    Message: string;
  end;

  ILifetimeToken = interface
    ['{7B4C9E2A-3E1F-4C6B-9A2D-8E5F1A2B3C4D}']
    function IsAlive: Boolean;
    procedure Invalidate;
  end;

  TLifetimeToken = class(TInterfacedObject, ILifetimeToken)
  private
    FAlive: Integer;
  public
    constructor Create;
    function IsAlive: Boolean;
    procedure Invalidate;
  end;

implementation

uses
  System.SyncObjs;

constructor TLifetimeToken.Create;
begin
  inherited Create;
  FAlive := 1;
end;

function TLifetimeToken.IsAlive: Boolean;
begin
  Result := TInterlocked.CompareExchange(FAlive, 0, 0) = 1;
end;

procedure TLifetimeToken.Invalidate;
begin
  TInterlocked.Exchange(FAlive, 0);
end;

end.
