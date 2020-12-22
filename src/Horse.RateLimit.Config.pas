unit Horse.RateLimit.Config;

interface

uses
  Store.Intf, Store.Lib.Memory,
  System.SysUtils, System.SyncObjs;

type
  TRateLimitConfig = record
    Id: string;
    Limit: Integer;
    Timeout: Integer;
    Message: string;
    Headers: Boolean;
    Store: IStore;
    SkipFailedRequest: Boolean;
    SkipSuccessRequest: Boolean;
  end;

  TRateLimitManager = class
  private
    FDictionary: TMemoryDictionary<TRateLimitConfig>;
    FConfig: TRateLimitConfig;

    procedure SetConfig(const AConfig: TRateLimitConfig);

    class var FInstance: TRateLimitManager;
    class var CriticalSection: TCriticalSection;
  public
    constructor Create();
    destructor Destroy; override;

    function GetDictionary: TMemoryDictionary<TRateLimitConfig>;
    procedure Save;

    property Config: TRateLimitConfig read FConfig write FConfig;

    class function New(const AConfig: TRateLimitConfig): TRateLimitManager;
    class destructor UnInitialize;
  end;

implementation

{ TRateLimitManager }

constructor TRateLimitManager.Create();
begin
  if Assigned(FInstance) then
    raise Exception.Create('The RateLimitManager instance has already been created!');

  FDictionary := TMemoryDictionary<TRateLimitConfig>.Create;
end;

destructor TRateLimitManager.Destroy;
begin
  FreeAndNil(FDictionary);
end;

class function TRateLimitManager.New(const AConfig: TRateLimitConfig): TRateLimitManager;
begin
  if not(Assigned(FInstance)) then
    FInstance := TRateLimitManager.Create();

  FInstance.SetConfig(AConfig);

  Result := FInstance;
end;

class destructor TRateLimitManager.UnInitialize;
begin
  if Assigned(FInstance) then
    FreeAndNil(FInstance);
end;

procedure TRateLimitManager.Save;
begin
  CriticalSection.Enter;
  try
    FDictionary.AddOrSetValue(Config.Id, Config);
  finally
    CriticalSection.Leave;
  end;
end;

function TRateLimitManager.GetDictionary: TMemoryDictionary<TRateLimitConfig>;
begin
  Result := FDictionary;
end;

procedure TRateLimitManager.SetConfig(const AConfig: TRateLimitConfig);
var
  LConfig: TRateLimitConfig;
begin
  CriticalSection.Enter;
  try
    if not(FDictionary.TryGetValue(AConfig.Id, LConfig)) then
    begin
      FDictionary.Add(AConfig.Id, AConfig);
      LConfig := AConfig;
    end;
  finally
    CriticalSection.Leave;
  end;

  FConfig := LConfig;
end;

initialization

TRateLimitManager.CriticalSection := TCriticalSection.Create;

finalization

FreeAndNil(TRateLimitManager.CriticalSection);

end.
