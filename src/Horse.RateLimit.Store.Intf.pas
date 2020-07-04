unit Horse.RateLimit.Store.Intf;

interface

type
  TRateLimitStoreCallback = record
    Current: Integer;
    ResetTime: TDateTime;
  end;

  IRateLimitStore = interface
    ['{75A8E917-85D7-40D2-874A-70E86D3D5EF3}']
    function Incr(AKey: string): TRateLimitStoreCallback;
    procedure Decrement(AKey: string);
    procedure ResetAll();
  end;

implementation

end.
