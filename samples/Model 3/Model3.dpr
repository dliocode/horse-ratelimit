program Model3;

uses Horse, Horse.RateLimit;

var
  Config: TRateLimitConfig;
begin
  Config.Id := 'ping';                // Identification
  Config.Limit := 5;                  // Limit Request
  Config.Timeout := 30;               // Timeout in seconds
  Config.Message := '';               // Message return
  Config.Headers := True;             // Show in Header X-RateLimit-*
  Config.Store := nil;                // Default TMemoryStore
  Config.SkipFailedRequest := False;  // Undo if the response request was failed
  Config.SkipSuccessRequest := False; // Undo if the response request was successful

  THorse
  .Get('/ping', THorseRateLimit.New(Config),
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  // Max of 30 Request in 5 minutes with return custom message
  Config.Id := 'Test';
  Config.Limit := 30;
  Config.Timeout := 5 * 60;
  Config.Message := 'My Custom Message';
  Config.Headers := True;

  THorse.Get('/test', THorseRateLimit.New(Config),
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('ok');
    end);

  THorse.Listen(9000);
end.
