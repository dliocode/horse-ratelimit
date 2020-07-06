unit Horse.RateLimit.Store.Memory;

interface

uses
  Horse.RateLimit.Store.Intf, Horse.RateLimit.Memory,
  System.Generics.Collections, System.SysUtils,
  System.DateUtils;

type
  TMemory = record
    Count: Integer;
    DateTime: TDateTime;
  end;

  TMemoryStore = class(TInterfacedObject, IRateLimitStore)
  private
    FTimeout: Integer;
    FList: TMemoryDictionary<TMemory>;
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

{ TMemoryStore }

constructor TMemoryStore.Create(ATimeout: Integer);
begin
  FList := TMemoryDictionary<TMemory>.Create;
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
  if not(FList.TryGetValue(AKey, LMemory)) then
  begin
    LMemory.Count := 0;
    LMemory.DateTime := IncSecond(Now(), FTimeout);

    FList.Add(AKey, LMemory);
  end;

  if not(ResetKey(LMemory.DateTime)) then
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

  if not(ResetKey(LMemory.DateTime)) then
  begin
    Dec(LMemory.Count);

    if (LMemory.Count < 0) then
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
  FTimeout := ATimeout;
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
    if ResetKey(LList.Value.DateTime) then
      FList.Remove(LList.Key);
end;

end.
