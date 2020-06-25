unit Horse.RateLimit;

interface

uses
  Horse, Horse.Commons,
  Horse.RateLimit.Store.Intf, Horse.RateLimit.Store.Memory, Horse.RateLimit.Utils,
  System.StrUtils, System.SysUtils, System.DateUtils, System.Math,
  Web.HTTPApp;

type
  TRateLimitConfig = Horse.RateLimit.Store.Intf.TRateLimitConfig;

  THorseRateLimit = class
  private
    FOptions: TRateLimitOptions;
    FConfig: TRateLimitConfig;
    procedure LimiterHeader(AResponse: THorseResponse);
  public
    constructor Create(AConfig: TRateLimitConfig); overload;
    constructor Create(ALimit, ATimeout: Integer); overload;
    constructor Create(); overload;

    procedure Limit(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ THorseRateLimit }

const
  DEFAULT_LIMIT  = 60;
  DEFAULT_TIMEOUT = 60;

constructor THorseRateLimit.Create(AConfig: TRateLimitConfig);
begin
  FConfig := AConfig;

  if not(Assigned(FConfig.Store))then
    FConfig.Store := TMemoryStore.Create(FConfig.Timeout);
end;

constructor THorseRateLimit.Create(ALimit, ATimeout: Integer);
begin
  Create(TRateLimitConfig.Create(ALimit, ATimeout));
end;

constructor THorseRateLimit.Create;
begin
  Create(DEFAULT_LIMIT, DEFAULT_TIMEOUT);
end;

procedure THorseRateLimit.Limit(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LStoreCallback: TRateLimitStoreCallback;
  LKey: string;
  LMessage: string;
begin
  LKey := ClientIP(Req);

  LStoreCallback:= FConfig.Store.Incr(FConfig.Id+LKey);

  FOptions.Limit := FConfig.Limit;
  FOptions.Timeout := FConfig.Timeout;
  FOptions.Message := FConfig.Message;
  FOptions.Headers := FConfig.Headers;
  FOptions.Current := LStoreCallback.Current;
  FOptions.Remaining := Ifthen(FConfig.Limit < LStoreCallback.Current, 0, FConfig.Limit - LStoreCallback.Current);
  FOptions.ResetTime := LStoreCallback.ResetTime;
  FOptions.SkipFailedRequest := FConfig.SkipFailedRequest;
  FOptions.SkipSuccessRequest := FConfig.SkipSuccessRequest;

  if(FOptions.Headers)then
    LimiterHeader(Res);

  if(FOptions.Current > FOptions.Limit)then
  begin
    THorseHackResponse(Res).GetWebResponse.SetCustomHeader('Retry-After', IntToStr(FOptions.Timeout * 1000));

    LMessage := 'Too many requests, please try again later.';
    LMessage := IfThen(FConfig.Message.Trim.IsEmpty, LMessage, FConfig.Message);

    Res.Send(LMessage).Status(THTTPStatus.TooManyRequests);

    raise EHorseCallbackInterrupted.Create;
  end;

  try
    Next;
  except
    if not(FOptions.SkipFailedRequest)then
      FConfig.Store.Decrement(LKey);
    exit;
  end;

  if(FOptions.SkipFailedRequest) and (THorseHackResponse(Req).GetWebResponse.StatusCode >= 400)then
    FConfig.Store.Decrement(LKey);

  if(FOptions.SkipSuccessRequest) and (THorseHackResponse(Req).GetWebResponse.StatusCode < 400)then
    FConfig.Store.Decrement(LKey);
end;

procedure THorseRateLimit.LimiterHeader(AResponse: THorseResponse);
var
  LWebResponse: TWebResponse;
begin
  LWebResponse := THorseHackResponse(AResponse).GetWebResponse;
  LWebResponse.SetCustomHeader('X-Rate-Limit-Limit', FOptions.Limit.ToString);
  LWebResponse.SetCustomHeader('X-Rate-Limit-Remaining', FOptions.Remaining.toString);
  LWebResponse.SetCustomHeader('X-Rate-Limit-Reset', IntToStr(MillisecondOfTheDay(FOptions.ResetTime)));
end;

end.
