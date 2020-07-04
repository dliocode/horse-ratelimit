unit Horse.RateLimit;

interface

uses
  Horse, Horse.Commons,
  Horse.RateLimit.Config, Horse.RateLimit.Store.Intf, Horse.RateLimit.Store.Memory, Horse.RateLimit.Utils,
  System.StrUtils, System.SysUtils, System.DateUtils, System.Math,
  Web.HTTPApp;

const
  DEFAULT_LIMIT  = 60;
  DEFAULT_TIMEOUT = 60;

type
  TRateLimitConfig = Horse.RateLimit.Config.TRateLimitConfig;

  THorseRateLimit = class
  strict private
    FConfig: TRateLimitManager;
    class var FInstance: THorseRateLimit;
  public
    constructor Create(const AConfig: TRateLimitConfig); overload;
    constructor Create(const AId: string; const ALimit, ATimeout: Integer; const AMessage: string); overload;
    destructor Destroy; override;
    procedure Limit(Req: THorseRequest; Res: THorseResponse; Next: TProc);

    property Manager: TRateLimitManager read FConfig write FConfig;

    class function New(const AConfig: TRateLimitConfig): THorseRateLimit; overload;
    class function New(const AId: string; const ALimit: Integer = DEFAULT_LIMIT; const ATimeout: Integer = DEFAULT_TIMEOUT; const AMessage: string = ''): THorseRateLimit; overload;
    class function New(const ALimit, ATimeout: Integer): THorseRateLimit; overload;
    class function New(): THorseRateLimit; overload;
    class procedure FinalizeInstance;
  end;

implementation

{ THorseRateLimit }

constructor THorseRateLimit.Create(const AConfig: TRateLimitConfig);
begin
  FConfig := TRateLimitManager.New(AConfig);
end;

constructor THorseRateLimit.Create(const AId: string; const ALimit, ATimeout: Integer; const AMessage: string);
begin
  FConfig := TRateLimitManager.New(AId, ALimit, ATimeout, AMessage);
end;

destructor THorseRateLimit.Destroy;
begin
  FConfig.Free;
  inherited;
end;

class function THorseRateLimit.New(const AConfig: TRateLimitConfig): THorseRateLimit;
var
  LConfig: TRateLimitConfig;
begin
  if not(Assigned(FInstance))then
    FInstance := THorseRateLimit.Create(AConfig);

  FInstance.Manager := TRateLimitManager.New(AConfig);

  if not(Assigned(FInstance.Manager.Config.Store))then
  begin
    LConfig := FInstance.Manager.Config;
    LConfig.Store := TMemoryStore.Create(FInstance.Manager.Config.Timeout);
    FInstance.Manager.Config := LConfig;
  end;

  Result := FInstance;
end;

class function THorseRateLimit.New(const AId: string; const ALimit: Integer = DEFAULT_LIMIT; const ATimeout: Integer = DEFAULT_TIMEOUT; const AMessage: string = ''): THorseRateLimit;
var
  LConfig: TRateLimitConfig;
begin
  if not(Assigned(FInstance))then
    FInstance := THorseRateLimit.Create(AId, ALimit, ATimeout, AMessage)
  else
    FInstance.Manager := TRateLimitManager.New(AId, ALimit, ATimeout, AMessage);

  if not(Assigned(FInstance.Manager.Config.Store))then
  begin
    LConfig := FInstance.Manager.Config;
    LConfig.Store := TMemoryStore.Create(FInstance.Manager.Config.Timeout);
    FInstance.Manager.Config := LConfig;
  end;

  Result := FInstance;
end;

class function THorseRateLimit.New(const ALimit, ATimeout: Integer): THorseRateLimit;
begin
  Result := New('', ALimit, ATimeout, '');
end;

class function THorseRateLimit.New(): THorseRateLimit;
begin
  Result := New('');
end;

class procedure THorseRateLimit.FinalizeInstance;
begin
  if Assigned(FInstance) then
    FInstance.Free;
end;

procedure THorseRateLimit.Limit(Req: THorseRequest; Res: THorseResponse; Next: TProc);
type
  TRateLimitOptions = record
    Limit: Integer;
    Timeout: Integer;
    Message: string;
    Headers: Boolean;
    Current: Integer;
    Remaining: Integer;
    ResetTime: TDateTime;
    SkipFailedRequest: Boolean;
    SkipSuccessRequest: Boolean;
  end;

var
  LWebResponse: TWebResponse;
  LStoreCallback: TRateLimitStoreCallback;
  LKey: string;
  LMessage: string;
  FOptions: TRateLimitOptions;
begin
  LKey := 'RL'+Manager.Config.Id+ClientIP(Req);

  LStoreCallback:= Manager.Config.Store.Incr(LKey);

  FOptions.Limit := Manager.Config.Limit;
  FOptions.Timeout := Manager.Config.Timeout;
  FOptions.Message := Manager.Config.Message;
  FOptions.Headers := Manager.Config.Headers;
  FOptions.Current := LStoreCallback.Current;
  FOptions.Remaining := Ifthen(Manager.Config.Limit < LStoreCallback.Current, 0, Manager.Config.Limit - LStoreCallback.Current);
  FOptions.ResetTime := LStoreCallback.ResetTime;
  FOptions.SkipFailedRequest := Manager.Config.SkipFailedRequest;
  FOptions.SkipSuccessRequest := Manager.Config.SkipSuccessRequest;

  if(FOptions.Headers)then
  begin
    LWebResponse := THorseHackResponse(Res).GetWebResponse;
    LWebResponse.SetCustomHeader('X-RateLimit-Limit', FOptions.Limit.ToString);
    LWebResponse.SetCustomHeader('X-RateLimit-Remaining', FOptions.Remaining.toString);
    LWebResponse.SetCustomHeader('X-RateLimit-Reset', IntToStr(MillisecondOfTheDay(FOptions.ResetTime)));
  end;

  if(FOptions.Current > FOptions.Limit)then
  begin
    THorseHackResponse(Res).GetWebResponse.SetCustomHeader('Retry-After', IntToStr(FOptions.Timeout * 1000));

    LMessage := 'Too many requests, please try again later.';
    LMessage := IfThen(FOptions.Message.Trim.IsEmpty, LMessage, FOptions.Message);

    Res.Send(LMessage).Status(THTTPStatus.TooManyRequests);

    raise EHorseCallbackInterrupted.Create;
  end;

  try
    Next;
  except
    if not(FOptions.SkipFailedRequest)then
      Manager.Config.Store.Decrement(LKey);
    exit;
  end;

  if(FOptions.SkipFailedRequest) and (THorseHackResponse(Req).GetWebResponse.StatusCode >= 400)then
    Manager.Config.Store.Decrement(LKey);

  if(FOptions.SkipSuccessRequest) and (THorseHackResponse(Req).GetWebResponse.StatusCode < 400)then
    Manager.Config.Store.Decrement(LKey);

  Manager.Save;
end;

initialization

finalization

THorseRateLimit.FinalizeInstance;

end.
