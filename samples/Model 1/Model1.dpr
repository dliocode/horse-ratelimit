program Model1;

uses Horse, Horse.RateLimit;

begin
  THorse
  .Use(THorseRateLimit.New().Limit)
  .Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
