unit Horse.RateLimit.Store.Intf;

interface

type
  TRateLimitStoreCallback = record
    Current: Integer;
    ResetTime: TDateTime;
  end;

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

  IRateLimitStore = interface;

  TRateLimitConfig = record
    Id: string;
    Limit: Integer;
    Timeout: Integer;
    Message: string;
    Headers: Boolean;
    Store: IRateLimitStore;
    SkipFailedRequest: Boolean;
    SkipSuccessRequest: Boolean;

    constructor Create(ALimit, ATimeout: Integer);
  end;

  IRateLimitStore = interface
    ['{75A8E917-85D7-40D2-874A-70E86D3D5EF3}']
    function Incr(AKey: string): TRateLimitStoreCallback;
    procedure Decrement(AKey: string);
    procedure ResetAll();
  end;

implementation

{ TRateLimitOptions }

constructor TRateLimitConfig.Create(ALimit, ATimeout: Integer);
begin
  Id := '';
  Limit := ALimit;
  Timeout := ATimeout;
  Message := '';
  Headers := True;;
  Store := nil;
  SkipFailedRequest := False;
  SkipSuccessRequest := False;
end;

end.
