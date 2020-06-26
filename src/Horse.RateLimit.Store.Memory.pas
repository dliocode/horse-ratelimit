unit Horse.RateLimit.Store.Memory;

interface

uses
  Horse.RateLimit.Store.Intf,
  System.StrUtils, System.Generics.Collections, System.SysUtils,
  System.DateUtils;

type
  TMemory = record
    Count: Integer;
    DateTime: TDateTime;
  end;

  TMemoryDictionary = class
  private
    FRW: TMultiReadExclusiveWriteSynchronizer;
    FDictionary: TDictionary<string, TMemory>;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure Remove(AKey: string);
    procedure Add(const AName: string; const AValue: TMemory);
    procedure AddOrSetValue(const AName: string; const AValue: TMemory);
    function TryGetValue(const AName: string; out AValue: TMemory): Boolean;
    function Count: Integer;
    function Get:TDictionary<string, TMemory>;
  end;

  TMemoryStore = class(TInterfacedObject, IRateLimitStore)
  private
    FTimeout: Integer;
    FList: TMemoryDictionary;
    function ResetKey(ADateTime: TDateTime): Boolean;
    procedure CleanMemory;
  public
    constructor Create(ATimeout: Integer);
    destructor Destroy; override;

    function Incr(AKey: string): TRateLimitStoreCallback;
    procedure Decrement(AKey: string);
    procedure ResetAll();
    procedure SetTimeOut(ATimeout: Integer);
  end;

implementation

{ TMemoryDictionary }

constructor TMemoryDictionary.Create;
begin
  FRW:= TMultiReadExclusiveWriteSynchronizer.Create;
  FDictionary := TDictionary<string, TMemory>.Create;
end;

destructor TMemoryDictionary.Destroy;
begin
  FDictionary.Free;
  FRW.Free;
  inherited;
end;

procedure TMemoryDictionary.Clear;
begin
  FRW.BeginWrite;
  try
    FDictionary.Clear;
  finally
    FRW.EndWrite;
  end;
end;

procedure TMemoryDictionary.Remove(AKey: string);
begin
  FRW.BeginWrite;
  try
    FDictionary.Remove(AKey);
  finally
    FRW.EndWrite;
  end;
end;

procedure TMemoryDictionary.Add(const AName: string; const AValue: TMemory);
begin
  FRW.BeginWrite;
  try
    if not FDictionary.ContainsKey(AName) then
      FDictionary.Add(AName, AValue);
  finally
    FRW.EndWrite;
  end;
end;

procedure TMemoryDictionary.AddOrSetValue(const AName: string; const AValue: TMemory);
begin
  FRW.BeginWrite;
  try
    FDictionary.AddOrSetValue(AName, AValue);
  finally
    FRW.EndWrite;
  end;
end;

function TMemoryDictionary.TryGetValue(const AName: string; out AValue: TMemory): Boolean;
begin
  FRW.BeginRead;
  try
    Result := FDictionary.TryGetValue(AName, AValue);
  finally
    FRW.EndRead;
  end;
end;

function TMemoryDictionary.Count: Integer;
begin
  FRW.BeginRead;
  try
    Result := FDictionary.Count;
  finally
    FRW.EndRead;
  end;
end;

function TMemoryDictionary.Get: TDictionary<string, TMemory>;
begin
  Result:= FDictionary;
end;

{ TMemoryStore }

constructor TMemoryStore.Create(ATimeout: Integer);
begin
  FList := TMemoryDictionary.Create;
  FTimeout := ATimeout;
end;

destructor TMemoryStore.Destroy;
begin
  FList.Free;
end;

function TMemoryStore.Incr(AKey: string): TRateLimitStoreCallback;
var
  LMemory: TMemory;
begin
  if not(FList.TryGetValue(AKey, LMemory))then
  begin
    LMemory.Count := 0;
    LMemory.DateTime := IncSecond(Now(), FTimeout);

    FList.Add(AKey, LMemory);
  end;

  if not(ResetKey(LMemory.DateTime))then
  begin
    Inc(LMemory.Count);
    FList.Remove(AKey);
    FList.Add(AKey, LMemory);
    Result.Current := LMemory.Count;
    Result.ResetTime := LMemory.DateTime - Now();
  end
  else
  begin
    FList.Remove(AKey);
    Result := Incr(AKey);
    CleanMemory;
  end;
end;

procedure TMemoryStore.Decrement(AKey: string);
var
  LMemory: TMemory;
begin
  LMemory.Count := 1;
  LMemory.DateTime := IncSecond(Now(), FTimeout);

  FList.AddOrSetValue(AKey, LMemory);

  if not(ResetKey(LMemory.DateTime))then
  begin
    Dec(LMemory.Count);

    if(LMemory.Count < 0)then
      LMemory.Count := 0;

    FList.Remove(AKey);
    FList.Add(AKey, LMemory);
  end
  else
  begin
    FList.Remove(AKey);
    Decrement(AKey);
    CleanMemory;
  end;
end;

procedure TMemoryStore.ResetAll();
begin
  FList.Clear
end;

procedure TMemoryStore.SetTimeOut(ATimeout: Integer);
begin
  FTimeout:= ATimeout;
end;

function TMemoryStore.ResetKey(ADateTime: TDateTime): Boolean;
begin
  Result := Now() > ADateTime;
end;

procedure TMemoryStore.CleanMemory;
var
  LList: TPair<string, TMemory>;
begin
  for LList in FList.Get do
    if ResetKey(LList.Value.DateTime)then
      FList.Remove(LList.Key);
end;

end.
