unit Horse.RateLimit.Config;

interface

uses
  Store.Intf, Store.Lib.Memory,
  System.SysUtils;

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
  strict private
    FDictionary: TMemoryDictionary<TRateLimitConfig>;
    FConfig: TRateLimitConfig;
    class var FInstance: TRateLimitManager;
  public
    constructor Create();
    destructor Destroy; override;

    function GetDictionary: TMemoryDictionary<TRateLimitConfig>;
    procedure Save;

    property Config: TRateLimitConfig read FConfig write FConfig;

    class function New(const AConfig: TRateLimitConfig): TRateLimitManager; overload;
    class function New(const AId: String; const ALimit, ATimeout: Integer; const AMessage: String; const AStore: IStore): TRateLimitManager; overload;
    class procedure FinalizeInstance;
  end;

implementation

{ TRateLimitManager }

constructor TRateLimitManager.Create();
begin
  FDictionary := TMemoryDictionary<TRateLimitConfig>.Create;
end;

destructor TRateLimitManager.Destroy;
begin
  FDictionary.Free;
end;

class function TRateLimitManager.New(const AConfig: TRateLimitConfig): TRateLimitManager;
var
  LConfig: TRateLimitConfig;
begin
  if not(Assigned(FInstance)) then
    FInstance := TRateLimitManager.Create();

  if not(FInstance.GetDictionary.TryGetValue(AConfig.Id, LConfig)) then
  begin
    FInstance.GetDictionary.Add(AConfig.Id, AConfig);
    LConfig := AConfig;
  end;

  FInstance.Config := LConfig;

  Result := FInstance;
end;

class function TRateLimitManager.New(const AId: String; const ALimit, ATimeout: Integer; const AMessage: String; const AStore: IStore): TRateLimitManager;
var
  LConfig: TRateLimitConfig;
begin
  if not(Assigned(FInstance)) then
    FInstance := TRateLimitManager.Create();

  if not(FInstance.GetDictionary.TryGetValue(AId, LConfig)) then
  begin
    LConfig.Id := AId;
    LConfig.Limit := ALimit;
    LConfig.Timeout := ATimeout;
    LConfig.Message := AMessage;
    LConfig.Headers := True;
    LConfig.Store := AStore;
    LConfig.SkipFailedRequest := False;
    LConfig.SkipSuccessRequest := False;

    FInstance.GetDictionary.Add(AId, LConfig);
  end;

  FInstance.Config := LConfig;

  Result := FInstance;
end;

procedure TRateLimitManager.Save;
begin
  GetDictionary.Remove(Config.Id);
  GetDictionary.Add(Config.Id, Config);
end;

class procedure TRateLimitManager.FinalizeInstance;
begin
  if Assigned(FInstance) then
    FInstance.Free;
end;

function TRateLimitManager.GetDictionary: TMemoryDictionary<TRateLimitConfig>;
begin
  Result := FDictionary;
end;

end.
