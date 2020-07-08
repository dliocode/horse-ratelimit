program Model4;

uses Horse, Horse.RateLimit, Store.Redis;  // Add uses Store.Redis

var
  App: THorse;
begin
  App := THorse.Create(9000);

  App.Use(THorseRateLimit.New(10,60, TRedisStore.New()).Limit); // Add TRedisStore.New()

  App.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  App.Start;
end.
