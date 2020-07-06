unit Horse.RateLimit.Memory;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TMemoryDictionary<T> = class
  private
    FRW: TMultiReadExclusiveWriteSynchronizer;
    FDictionary: TDictionary<string, T>;
    class var FInstance: TMemoryDictionary<T>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Remove(AKey: string);
    procedure Add(const AName: string; const AValue: T);
    procedure AddOrSetValue(const AName: string; const AValue: T);
    function TryGetValue(const AName: string; out AValue: T): Boolean;
    function Get: TDictionary<string, T>;
    function Count: Integer;

    class function New(): TMemoryDictionary<T>;
  end;

implementation

{ TMemoryDictionary<T> }

constructor TMemoryDictionary<T>.Create;
begin
  FRW := TMultiReadExclusiveWriteSynchronizer.Create;
  FDictionary := TDictionary<string, T>.Create;
end;

destructor TMemoryDictionary<T>.Destroy;
begin
  FDictionary.Free;
  FRW.Free;
  inherited;
end;

class function TMemoryDictionary<T>.New: TMemoryDictionary<T>;
begin
  if not(Assigned(FInstance)) then
    FInstance := TMemoryDictionary<T>.Create;

  Result := FInstance;
end;

procedure TMemoryDictionary<T>.Clear;
begin
  FRW.BeginWrite;
  try
    FDictionary.Clear;
  finally
    FRW.EndWrite;
  end;
end;

procedure TMemoryDictionary<T>.Remove(AKey: string);
begin
  FRW.BeginWrite;
  try
    FDictionary.Remove(AKey);
  finally
    FRW.EndWrite;
  end;
end;

procedure TMemoryDictionary<T>.Add(const AName: string; const AValue: T);
begin
  FRW.BeginWrite;
  try
    if not FDictionary.ContainsKey(AName) then
      FDictionary.Add(AName, AValue);
  finally
    FRW.EndWrite;
  end;
end;

procedure TMemoryDictionary<T>.AddOrSetValue(const AName: string; const AValue: T);
begin
  FRW.BeginWrite;
  try
    FDictionary.AddOrSetValue(AName, AValue);
  finally
    FRW.EndWrite;
  end;
end;

function TMemoryDictionary<T>.TryGetValue(const AName: string; out AValue: T): Boolean;
begin
  FRW.BeginRead;
  try
    Result := FDictionary.TryGetValue(AName, AValue);
  finally
    FRW.EndRead;
  end;
end;

function TMemoryDictionary<T>.Get: TDictionary<string, T>;
begin
  FRW.BeginRead;
  try
    Result := FDictionary
  finally
    FRW.EndRead;
  end;
end;

function TMemoryDictionary<T>.Count: Integer;
begin
  FRW.BeginRead;
  try
    Result := FDictionary.Count;
  finally
    FRW.EndRead;
  end;
end;

end.
