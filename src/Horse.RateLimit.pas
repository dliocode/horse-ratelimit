unit Horse.RateLimit;

interface

uses
  Horse, Horse.Commons, Horse.Utils.ClientIP,
  Store.Intf, Store.Memory, Store.Config,
  System.StrUtils, System.SysUtils, System.DateUtils, System.Math, System.SyncObjs,
  Web.HTTPApp;

const
  DEFAULT_LIMIT = 60;
  DEFAULT_TIMEOUT = 60;

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

  THorseRateLimit = class
  private
    class var CriticalSection: TCriticalSection;
  public
    class function New(const AConfig: TRateLimitConfig): THorseCallback; overload;
    class function New(const AId: string = ''; const ALimit: Integer = DEFAULT_LIMIT; const ATimeout: Integer = DEFAULT_TIMEOUT; const AMessage: string = ''; const AStore: IStore = nil): THorseCallback; overload;
  end;

implementation

{ THorseRateLimit }

class function THorseRateLimit.New(const AConfig: TRateLimitConfig): THorseCallback;
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
  LStoreConfig: TStoreConfig<TRateLimitConfig>;
  LConfig: TRateLimitConfig;
begin
  CriticalSection.Enter;
  try
    LStoreConfig := TStoreConfig<TRateLimitConfig>.New(AConfig.Id, AConfig);
  finally
    CriticalSection.Leave;
  end;

  if not(Assigned(LStoreConfig.Config.Store)) then
  begin
    LConfig := LStoreConfig.Config;
    LConfig.Store := TMemoryStore.New();

    LStoreConfig.Config := LConfig;
  end;

  LStoreConfig.Config.Store.SetTimeout(LStoreConfig.Config.Timeout);
  LStoreConfig.Save(LStoreConfig.Config.Id);

  Result :=
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LManagerConfig: TStoreConfig<TRateLimitConfig>;
      LWebResponse: TWebResponse;
      LStoreCallback: TStoreCallback;
      LKey: string;
      LMessage: string;
      FOptions: TRateLimitOptions;
    begin
      CriticalSection.Enter;
      try
        LManagerConfig := TStoreConfig<TRateLimitConfig>.New(AConfig.Id, AConfig);
      finally
        CriticalSection.Leave;
      end;

      LKey := 'RL:' + LManagerConfig.Config.Id + ':' + ClientIP(Req);

      LStoreCallback := LManagerConfig.Config.Store.Incr(LKey);

      FOptions.Limit := LManagerConfig.Config.Limit;
      FOptions.Timeout := LManagerConfig.Config.Timeout;
      FOptions.Message := LManagerConfig.Config.Message;
      FOptions.Headers := LManagerConfig.Config.Headers;
      FOptions.Current := LStoreCallback.Current;
      FOptions.Remaining := Ifthen(LManagerConfig.Config.Limit < LStoreCallback.Current, 0, LManagerConfig.Config.Limit - LStoreCallback.Current);
      FOptions.ResetTime := LStoreCallback.ResetTime;
      FOptions.SkipFailedRequest := LManagerConfig.Config.SkipFailedRequest;
      FOptions.SkipSuccessRequest := LManagerConfig.Config.SkipSuccessRequest;

      if (FOptions.Headers) then
      begin
        LWebResponse := THorseHackResponse(Res).GetWebResponse;
        LWebResponse.SetCustomHeader('X-RateLimit-Limit', FOptions.Limit.ToString);
        LWebResponse.SetCustomHeader('X-RateLimit-Remaining', FOptions.Remaining.ToString);
        LWebResponse.SetCustomHeader('X-RateLimit-Reset', IntToStr(MillisecondOfTheDay(FOptions.ResetTime)));
      end;

      if (FOptions.Current > FOptions.Limit) then
      begin
        THorseHackResponse(Res).GetWebResponse.SetCustomHeader('Retry-After', IntToStr(FOptions.Timeout * 1000));

        LMessage := 'Too many requests, please try again later.';
        LMessage := Ifthen(FOptions.Message.Trim.IsEmpty, LMessage, FOptions.Message);

        Res.Send(LMessage).Status(THTTPStatus.TooManyRequests);

        raise EHorseCallbackInterrupted.Create;
      end;

      try
        try
          Next;
        except
          if FOptions.SkipFailedRequest then
            LManagerConfig.Config.Store.Decrement(LKey);
          raise;
        end;

        if (FOptions.SkipFailedRequest) and (THorseHackResponse(Req).GetWebResponse.StatusCode >= 400) then
          LManagerConfig.Config.Store.Decrement(LKey);

        if (FOptions.SkipSuccessRequest) and (THorseHackResponse(Req).GetWebResponse.StatusCode < 400) then
          LManagerConfig.Config.Store.Decrement(LKey);
      finally
        LManagerConfig.Save(LManagerConfig.Config.Id);
      end;
    end;
end;

class function THorseRateLimit.New(const AId: string = ''; const ALimit: Integer = DEFAULT_LIMIT; const ATimeout: Integer = DEFAULT_TIMEOUT; const AMessage: string = ''; const AStore: IStore = nil): THorseCallback;
var
  LConfig: TRateLimitConfig;
begin
  LConfig.Id := AId;
  LConfig.Limit := ALimit;
  LConfig.Timeout := ATimeout;
  LConfig.Message := AMessage;
  LConfig.Headers := True;
  LConfig.Store := AStore;
  LConfig.SkipFailedRequest := False;
  LConfig.SkipSuccessRequest := False;

  Result := New(LConfig);
end;

initialization

THorseRateLimit.CriticalSection := TCriticalSection.Create;

finalization

FreeAndNil(THorseRateLimit.CriticalSection);

end.
