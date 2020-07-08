program Model1;

uses Horse, Horse.RateLimit;

var
  App: THorse;
begin
  App := THorse.Create(9000);

  App.Use(THorseRateLimit.New().Limit)

  App.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  App.Start;
end.
